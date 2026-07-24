# ADR-002: Intercom-service Chart as a Univention Fork

**Date:** 2026-07  
**Status:** Accepted  

## Context

The intercom-service chart provides the ICS (Inter Component Service) API gateway
used by openDesk apps for cross-service API calls from the user's browser.

Univention publishes an official chart at
`oci://artifacts.software-univention.de/nubus/charts`.

Options considered:
- **Use upstream chart directly**: Pull from Univention OCI registry at deploy time.
  Risk: registry unavailability blocks edu deployment.
- **Fork and vendor**: Copy the chart into the repo, make edu-specific changes.
  Risk: manual sync effort on upstream releases.
- **Rewrite from scratch**: Build a minimal edu-specific ICS chart.
  Risk: duplication of effort; ICS is a mature component.

## Decision

**Fork the Univention intercom-service chart and vendor it in-tree.**

- Chart copied from Univention's upstream (version 2.23.11)
- External OCI dependency (`nubus-common`) removed — chart is self-contained
  with vendored copy in `charts/` directory
- Image registry changed to `codeberg.org/opendesk-edu/intercom-service`
- Edu-specific configuration in values and templates

## Consequences

- **Positive:** Deployment does not depend on Univention's OCI registry.
- **Positive:** Full control over chart behavior for edu requirements.
- **Negative:** Manual effort to sync upstream bugfixes (see `UPSTREAM.md`).
- **Negative:** Chart diverges from upstream over time.
