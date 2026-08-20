#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-License-Identifier: Apache-2.0

##
## Copies an externally maintained object identifier out of `univentionObjectIdentifier` into the
## attribute openDesk reserves for it, `reservedLegacyExternalIamIdentifier`.
##
## This is step 3 of `docs/migrations-instructions/1.18.0-preserve-external-iam-identifier.md` and
## only concerns deployments that provision their users and groups from an external IAM and write
## that IAM's identifier into the `univentionObjectIdentifier`. openDesk takes that attribute into
## its own use with 1.18.0 and overwrites it for every object, so an identifier that is to survive
## the upgrade has to be somewhere else before it.
##
## The objects are written through the UDM REST API - the same interface every other change to the
## IAM goes through - and not into the LDAP directly, so that the change reaches the provisioning
## like any other and UDM validates the value against the syntax of the extended attribute.
##
## Idempotent: an object whose target attribute already carries the identifier is left alone, which
## is what makes a repeated run work out what is left to do from the state it finds. An object that
## carries a *different* value in the target attribute is reported as a conflict and left alone -
## the attribute is defined as not changeable, and a value someone else put there is not this
## script's to overwrite.
##
## Requires nothing but Python 3. Reach the API through a port forwarding:
##   kubectl -n "$NAMESPACE" port-forward service/ums-udm-rest-api 9979:9979
##
## Usage:
##   export UDM_PASSWORD="$(kubectl -n "$NAMESPACE" get secret ums-ldap-server-admin \
##     -o jsonpath='{.data.password}' | base64 -d)"
##   python3 1.18.0-external-iam-identifier.py --dry-run   # report only
##   python3 1.18.0-external-iam-identifier.py --limit 1   # write one object and check it
##   python3 1.18.0-external-iam-identifier.py             # copy everything
##

import argparse
import base64
import json
import logging
import os
import re
import sys
import time
import urllib.error
import urllib.request
from urllib.parse import quote, urlencode

# openDesk's in-cluster endpoint, reached through the port forwarding of the instructions.
DEFAULT_UDM_URL = 'http://localhost:9979/univention/udm/'
# The LDAP admin. It is the account the IAM's own components use for their UDM calls; an account of
# the group "IAM API - Full Access" works as well.
DEFAULT_UDM_USERNAME = 'cn=admin'

# The attribute openDesk takes over with 1.18.0 ...
SOURCE_PROPERTY = 'univentionObjectIdentifier'
# ... and the one it reserves for the identifier of an external IAM (LDAP: univentionFreeAttribute2).
TARGET_PROPERTY = 'reservedLegacyExternalIamIdentifier'

# The modules the extended attribute is defined for.
DEFAULT_MODULES = ['users/user', 'groups/group']

# Transient failures (the API restarting behind the service, a rolling update finishing up) are
# retried, anything else is a hard error this script stops on.
RETRY_STATUS_CODES = (429, 500, 502, 503, 504)

# The extended attribute uses the UDM syntax `UUID`. Values that do not look like one are reported
# before anything is written, because UDM rejects them and a run would otherwise fail object by
# object.
UUID_VALUE = re.compile(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
                        r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')


class UdmError(RuntimeError):
    """Raised when the UDM REST API returns an unexpected response."""


class UdmClient:
    """The few UDM REST API calls this script needs: search, read, write.

    A search answers with shallow objects, so the properties are read per object, and a write sends
    back the full representation the API handed out - guarded by its ETag - so that nothing this
    script does not know about is dropped from the object."""

    def __init__(self, base_url, username, password, timeout=30, retries=3, retry_wait_seconds=5):
        self.base_url = base_url.rstrip('/') + '/'
        self.username = username
        credentials = f"{username}:{password}".encode('utf-8')
        self.authorization = 'Basic ' + base64.b64encode(credentials).decode('ascii')
        self.timeout = timeout
        self.retries = retries
        self.retry_wait_seconds = retry_wait_seconds

    def _request(self, method, path, payload=None, etag=None):
        url = self.base_url + path.lstrip('/')
        body = json.dumps(payload).encode('utf-8') if payload is not None else None
        headers = {'Authorization': self.authorization, 'Accept': 'application/json'}
        if body is not None:
            headers['Content-Type'] = 'application/json'
        if etag:
            # Guards against writing over a change someone else made in between.
            headers['If-Match'] = etag

        last_error = None
        for attempt in range(1, self.retries + 1):
            request = urllib.request.Request(url, data=body, headers=headers, method=method)
            try:
                with urllib.request.urlopen(request, timeout=self.timeout) as response:
                    content = response.read().decode('utf-8')
                    return (json.loads(content) if content.strip() else None, response.headers)
            except urllib.error.HTTPError as e:
                if e.code == 404:
                    return (None, None)
                # The response body carries UDM's error message, down to the property that was
                # rejected, which is what makes a failure diagnosable.
                detail = e.read().decode('utf-8', errors='replace')
                last_error = UdmError(f"UDM REST API error during {method} {path}: "
                                      f"HTTP {e.code} {detail}")
                if e.code not in RETRY_STATUS_CODES:
                    raise last_error from e
            except (urllib.error.URLError, TimeoutError) as e:
                last_error = UdmError(f"UDM REST API unreachable during {method} {path}: {e}")
            if attempt < self.retries:
                logging.warning(f"{last_error} - retrying in {self.retry_wait_seconds}s "
                                f"({attempt}/{self.retries - 1}).")
                time.sleep(self.retry_wait_seconds)
        raise last_error

    @staticmethod
    def _object_path(module, dn):
        # The DN is a path segment, so every reserved character in it has to be encoded.
        return f"{module}/{quote(dn, safe='')}"

    def search(self, module, search_filter):
        """The DNs of all objects of a module matching an LDAP filter.

        Fails when the API reports more results than it handed out: a silently truncated result
        would make this script skip objects and report a success for a copy that did not happen."""
        query = urlencode({'scope': 'sub', 'filter': search_filter})
        body, _ = self._request('GET', f"{module}/?{query}")
        if body is None:
            raise UdmError(f"The UDM REST API does not know the module '{module}'. Either the "
                           f"credentials of '{self.username}' are not accepted or this IAM does "
                           "not provide the module.")
        objects = (body.get('_embedded') or {}).get('udm:object') or []
        dns = [entry['dn'] for entry in objects if entry.get('dn')]
        if len(dns) != len(objects):
            raise UdmError(f"The UDM REST API returned an object without a DN for '{module}'.")
        results = body.get('results')
        if isinstance(results, int) and results > len(dns):
            raise UdmError(f"The UDM REST API reports {results} object(s) for '{module}' but "
                           f"returned {len(dns)}. Refusing to work on a partial result.")
        return dns

    def get(self, module, dn):
        """The object with all its properties and its ETag, or `(None, None)`."""
        body, headers = self._request('GET', self._object_path(module, dn))
        if body is None:
            return (None, None)
        return (body, headers.get('ETag') if headers else None)

    def put(self, module, representation, etag):
        """Write back an object whose properties were changed."""
        self._request('PUT', self._object_path(module, representation['dn']), representation,
                      etag=etag)


def copy_module(udm, module, dry_run, limit):
    """Copy the identifier for one module and return the counts of what was found.

    Every object is planned before it is written, so that the report of a dry run covers the whole
    module and a conflict is seen while nothing has been changed."""
    dns = udm.search(module, f"({SOURCE_PROPERTY}=*)")
    logging.info(f"{module}: {len(dns)} object(s) carry a {SOURCE_PROPERTY}.")

    to_copy, done, without_identifier, conflicts, not_uuid = [], 0, 0, [], 0
    for dn in dns:
        representation, etag = udm.get(module, dn)
        if representation is None:
            # Gone between the search and the read. Nothing to copy, and a synchronization that is
            # stopped as instructed does not produce this.
            logging.warning(f"{module}: {dn} disappeared while it was read, skipping it.")
            continue
        properties = representation.get('properties') or {}
        if TARGET_PROPERTY not in properties:
            raise UdmError(
                f"The module '{module}' has no property '{TARGET_PROPERTY}'. Create the extended "
                "attribute first, see step 2 of the migration instructions.")
        source = properties.get(SOURCE_PROPERTY)
        target = properties.get(TARGET_PROPERTY)
        if not source:
            without_identifier += 1
        elif target == source:
            done += 1
        elif target:
            conflicts.append((dn, target, source))
        else:
            if not UUID_VALUE.match(str(source)):
                not_uuid += 1
            to_copy.append((dn, representation, etag, source))

    for dn, target, source in conflicts:
        logging.error(f"{module}: {dn} already carries {target!r} in {TARGET_PROPERTY}, which is "
                      f"not its {SOURCE_PROPERTY} ({source!r}). Not touching it.")
    if not_uuid:
        logging.warning(
            f"{module}: {not_uuid} identifier(s) are not UUIDs, and the extended attribute is "
            "defined with the UDM syntax 'UUID'. UDM will reject them - see the note in step 2 of "
            "the migration instructions.")

    if limit is not None and len(to_copy) > limit:
        logging.info(f"{module}: limited to the first {limit} of {len(to_copy)} object(s).")
        to_copy = to_copy[:limit]

    copied = 0
    for dn, representation, etag, source in to_copy:
        if dry_run:
            logging.info(f"{module}: DRY RUN - would copy {source} to {TARGET_PROPERTY} of {dn}")
            continue
        representation['properties'][TARGET_PROPERTY] = source
        udm.put(module, representation, etag)
        # Verified rather than assumed: a value the API accepts and does not store would leave the
        # identifier nowhere once the upgrade has overwritten the source attribute.
        stored, _ = udm.get(module, dn)
        written = ((stored or {}).get('properties') or {}).get(TARGET_PROPERTY)
        if written != source:
            raise UdmError(f"{module}: {dn} carries {written!r} in {TARGET_PROPERTY} after it was "
                           f"written with {source!r}. Stopping here.")
        logging.info(f"{module}: copied {source} to {TARGET_PROPERTY} of {dn}")
        copied += 1

    return {'to_copy': len(to_copy), 'copied': copied, 'done': done,
            'without_identifier': without_identifier, 'conflicts': len(conflicts)}


def parse_arguments(argv):
    parser = argparse.ArgumentParser(
        description=f"Copy {SOURCE_PROPERTY} to {TARGET_PROPERTY} through the UDM REST API.")
    parser.add_argument('--url', default=os.environ.get('UDM_URL', DEFAULT_UDM_URL),
                        help=f"UDM REST API base URL (default: {DEFAULT_UDM_URL}, env UDM_URL).")
    parser.add_argument('--username', default=os.environ.get('UDM_USERNAME',
                                                             DEFAULT_UDM_USERNAME),
                        help=f"UDM user (default: {DEFAULT_UDM_USERNAME}, env UDM_USERNAME).")
    parser.add_argument('--password', default=os.environ.get('UDM_PASSWORD'),
                        help="Password of that user (env UDM_PASSWORD).")
    parser.add_argument('--password-file',
                        help="File holding that password, used instead of --password.")
    parser.add_argument('--modules', default=','.join(DEFAULT_MODULES),
                        help=f"Comma separated UDM modules (default: {','.join(DEFAULT_MODULES)}).")
    parser.add_argument('--dry-run', action='store_true',
                        help="Report what would be copied and change nothing.")
    parser.add_argument('--limit', type=int,
                        help="Copy at most this many objects per module, to try the copy on a "
                             "single object first.")
    arguments = parser.parse_args(argv)

    if arguments.password_file:
        with open(arguments.password_file, 'r', encoding='utf-8') as password_file:
            arguments.password = password_file.read().strip()
    if not arguments.password:
        parser.error("No password given, use --password, --password-file or UDM_PASSWORD.")
    if arguments.limit is not None and arguments.limit < 1:
        parser.error("--limit must be at least 1.")
    return arguments


def main(argv=None):
    logging.basicConfig(level=logging.INFO, format='%(levelname)-8s %(message)s')
    arguments = parse_arguments(argv)

    udm = UdmClient(arguments.url, arguments.username, arguments.password)
    modules = [module.strip() for module in arguments.modules.split(',') if module.strip()]

    if arguments.dry_run:
        logging.info("DRY RUN - nothing is written.")

    summary = {}
    for module in modules:
        summary[module] = copy_module(udm, module, arguments.dry_run, arguments.limit)

    conflicts = 0
    for module, counts in summary.items():
        verb = 'to copy' if arguments.dry_run else 'copied'
        logging.info(f"{module}: {counts['to_copy'] if arguments.dry_run else counts['copied']} "
                     f"object(s) {verb}, {counts['done']} already copied, "
                     f"{counts['without_identifier']} without an identifier, "
                     f"{counts['conflicts']} conflict(s).")
        conflicts += counts['conflicts']

    if conflicts:
        logging.error(f"{conflicts} object(s) carry a value in {TARGET_PROPERTY} that is not their "
                      f"{SOURCE_PROPERTY} and were not touched. Resolve them before you upgrade.")
        return 1
    if arguments.dry_run:
        logging.info("DRY RUN - no object was changed. Run without --dry-run to copy.")
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (UdmError, OSError) as error:
        logging.error(error)
        sys.exit(1)
