<!--
SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-License-Identifier: Apache-2.0
-->

# Debugging

<!-- TOC -->
* [Debugging](#debugging)
  * [Disclaimer](#disclaimer)
  * [Enable debugging](#enable-debugging)
  * [Adding containers to a pod for debugging purposes](#adding-containers-to-a-pod-for-debugging-purposes)
  * [Adding a container to a pod/deployment - Dev/Test only](#adding-a-container-to-a-poddeployment---devtest-only)
    * [Temporary/ephemeral containers](#temporaryephemeral-containers)
  * [Components](#components)
    * [Helmfile](#helmfile)
    * [MariaDB](#mariadb)
    * [Nextcloud](#nextcloud)
    * [OpenProject](#openproject)
    * [PostgreSQL](#postgresql)
    * [Open-Xchange](#open-xchange)
      * [OX App Suite](#ox-app-suite)
        * [Applying global config changes for debugging](#applying-global-config-changes-for-debugging)
        * [Using config cascade](#using-config-cascade)
      * [OX Dovecot](#ox-dovecot)
    * [Nubus](#nubus)
      * [Provisioning](#provisioning)
      * [Keycloak](#keycloak)
        * [Setting the log level](#setting-the-log-level)
        * [Accessing the Keycloak admin console](#accessing-the-keycloak-admin-console)
<!-- TOC -->

## Disclaimer

This document collects information on how to go about debugging an openDesk deployment.

It will be extended over time as we deal with debugging cases.

We for sure do not want to reinvent the wheel, so we might link to external sources that contain helpful
information where available.

> [!warning]
> You should never enable the debug option in production environments! By looking up `debug.enabled` in the
> deployment, you will find the various places changes are applied when enabling debugging. So, outside of
> development and test environments, you should use them thoughtfully and carefully if needed.

## Enable debugging

Check the openDesk [`debug.yaml.gotmpl`](../helmfile/environments/default/debug.yaml.gotmpl) and configure it for your deployment
```
debug:
  enabled: true
```

This will result in:
- setting most component's log level to debug
- making the Keycloak admin console available by default at `https://id.<your_domain>/admin/`
- ingress for `http://minio-console.<your_domain>` being configured

> [!note]
> When enabling debug mode and updating your deployment, you must manually delete all jobs before updating. In
> debug mode, we keep the jobs, and some job fields are immutable, leading to a deployment failure.

> [!note]
> All containers should write their log output to STDOUT; if you find (valuable) logs inside a container which
> were not in STDOUT, please let us know!

## Adding containers to a pod for debugging purposes

During testing or development, you may need to execute tools, browse, or even change things in the filesystem of another container.

This can be a challenge the more security-hardened the container images are because there are no debugging tools available, and sometimes, there is not even a shell.

Adding a container to a Pod can ease the pain.

Below are some brief notes on debugging openDesk by adding debug containers. Of course, there are many more detailed resources out there.

## Adding a container to a pod/deployment - Dev/Test only

You can add a container by editing and updating an existing deployment, which is quite comfortable with tools like [Lens](https://k8slens.dev/).

- Select the container you want to use as a debugging container; in the example below, it is `registry.opencode.de/bmi/opendesk/components/platform-development/images/opendesk-debugging-image:latest`.
- Ensure the `shareProcessNamespace` option is enabled for the Pod.
- Reference the selected container within the `containers` array of the deployment.
- If you want to access another container's filesystem, ensure both containers' user/group settings match.
- Save & update the deployment.

The following example can be used to debug the `openDesk-Nextcloud-PHP` container; if you want to modify files, remember to set `readOnlyRootFilesystem` to `true` on the PHP container.

```yaml
      shareProcessNamespace: true
      containers:
        - name: debugging
          image: registry.opencode.de/bmi/opendesk/components/platform-development/images/opendesk-debugging-image:latest
          command: ["/bin/bash", "-c", "while true; do echo 'This is a temporary container for debugging'; sleep 5 ; done"]
          securityContext:
            capabilities:
              drop:
                - ALL
            privileged: false
            runAsUser: 65532
            runAsGroup: 65532
            runAsNonRoot: true
            readOnlyRootFilesystem: false
            allowPrivilegeEscalation: false
            seccompProfile:
              type: RuntimeDefault
```

- After the deployment has been reloaded, open the shell of the debugging container.
- When you've succeeded, you will see the processes of both/all containers in the Pod when executing `ps aux`.
- To access other containers' filesystems, select the PID of a process from the other container and do a `cd /proc/<selected_process_id>/root`.

### Temporary/ephemeral containers

An interesting read from which we picked most of the details below from: https://iximiuz.com/en/posts/kubernetes-ephemeral-containers/

Sometimes, you do not want to add a container permanently to your existing deployment. In that case, you could use [ephemeral containers](https://kubernetes.io/docs/concepts/workloads/pods/ephemeral-containers/).

For the commands further down this section, we need to set some environment variables first:
- `NAMESPACE`: The namespace in which the Pod you want to inspect is running.
- `DEPLOYMENT_NAME`: The deployment's name responsible for spawning the Pod you want to inspect within the aforementioned namespace.
- `POD_NAME`: The name of the Pod you want to inspect within the aforementioned namespace.
- `EPH_CONTAINER_NAME`: The name of your debugging container, "debugging" seems obvious.
- `DEBUG_IMAGE`: The image you want to use for debugging purposes.

e.g.

```shell
export NAMESPACE=my_test_deployment
export DEPLOYMENT_NAME=opendesk-nextcloud-php
export POD_NAME=opendesk-nextcloud-php-6686d47cfb-7642f
export EPH_CONTAINER_NAME=debugging
export DEBUG_IMAGE=registry.opencode.de/bmi/opendesk/components/platform-development/images/opendesk-debugging-image:latest
```

You still need to ensure that your deployment supports process namespace sharing:

```shell
kubectl -n ${NAMESPACE} patch deployment ${DEPLOYMENT_NAME} --patch '
spec:
  template:
    spec:
      shareProcessNamespace: true'
```

Now, you can add the ephemeral container with:
```shell
kubectl -n ${NAMESPACE} debug -it --attach=false -c ${EPH_CONTAINER_NAME} --image={DEBUG_IMAGE} ${POD_NAME}
```
and open its interactive terminal with
```shell
kubectl -n ${NAMESPACE} attach -it -c ${EPH_CONTAINER_NAME} ${POD_NAME}
```

## Components

### Helmfile

When refactoring the Helmfile structure, you want to ensure that there are no unintended edits by executing e.g. `diff` and
comparing the output of Helmfile from before and after the change by calling:

```shell
helmfile template -e dev >output_to_compare.yaml
```

### MariaDB

When using the openDesk bundled MariaDB, you can explore the database(s) using the MariaDB interactive terminal from the Pod's command line: `mariadb -u root -p`. On the password prompt, provide the value for `MARIADB_ROOT_PASSWORD` which can be found in the Pod's environment.

While you will find all the details for the CLI tool in the [MariaDB documentation](https://mariadb.com/kb/en/mariadb-command-line-client/), some commonly used commands are:

- `help`: Get help on the psql command set
- `show databases`: Lists all databases
- `use <databasename>`: Connect to `<databasename>`
- `show tables`: Lists tables within the currently connected database
- `quit`: Quit the client

### Nextcloud

`occ` is the CLI for Nextcloud; all the details can be found in the [upstream documentation](https://docs.nextcloud.com/server/stable/admin_manual/occ_command.html).

You can run occ commands in the `opendesk-nextcloud-aio` pod like this: `php /var/www/html/occ config:list`

### OpenProject

OpenProject is a Ruby on Rails application. Therefore, you can make use of the Rails console from the Pod's command line `bundle exec rails console`
and run debug code like this:

```
uri = URI('https://nextcloud.url/apps/integration_openproject/check-config')
Net::HTTP.start(uri.host, uri.port,
 :use_ssl => uri.scheme == 'https') do |http|
 request = Net::HTTP::Get.new uri
 response = http.request request # Net::HTTPResponse object
end
```

### PostgreSQL

Using the openDesk bundled PostgreSQL, you can explore database(s) using the PostgreSQL interactive terminal from the Pod's command line: `psql -U postgres`.

While you will find all details about the cli tool `psql` in the [PostgreSQL documentation](https://www.postgresql.org/docs/current/app-psql.html), some commonly used commands are:

- `\?`: Get help on the psql command set
- `\l`: Lists all databases
- `\c <databasename>`: Connect to `<databasename>`
- `\dt`: List (describe) tables within the currently connected database
- `\q`: Quit the client

### Open-Xchange

#### OX App Suite

##### Applying global config changes for debugging

You have two ways of applying config changes e.g. to enable debug relevant settings. In the examples below we will enable [`com.openexchange.imap.debugLog.enabled`](https://documentation.open-xchange.com/components/middleware/config/8/#mode=search&term=com.openexchange.imap.debugLog.enabled) assuming the given property is not set anywhere else yet.

1. Especially in environments where the core-mw Pods are scaled it is recommended to use customizatzions (see `customizations.yaml.gotmpl` for reference) and to redeploy the OX App Suite component. Due to the rolling upgrade feature this should not cause downtime for users.

```yaml
core-mw:
  properties:
    com.openexchange.imap.debugLog.enabled: "true"
```

2. When just dealing with a single core-mw Pod:

```shell
echo com.openexchange.imap.debugLog.enabled=true >> /opt/open-xchange/etc/additional.properties
/opt/open-xchange/sbin/reloadconfiguration
```

##### Using config cascade

OX App Suite allows some settings that can set globally also to be defined using a finer granularity down to the user level using the so call config cascade.

> [!note]
> The example below requires the related setting to be available on the global level e.g. with value `"false"` to
> be able to set in on a "lower" level, like the user.
> Find more details in the [upstream documentation](https://documentation.open-xchange.com/8/middleware/miscellaneous/config_cascade.html).

Using the same setting from the previous section but now setting it just for a specific user:

```shell
/opt/open-xchange/sbin/changeuser -A $MASTER_ADMIN_USER -P $MASTER_ADMIN_PW -c <contextId> -i <userId> --config/com.openexchange.imap.debugLog.enabled=true
```

For deactivation on the given user run:

```shell
/opt/open-xchange/sbin/changeuser -A $MASTER_ADMIN_USER -P $MASTER_ADMIN_PW -c <contextId> -i <userId> --remove-config/com.openexchange.imap.debugLog.enabled
```

#### OX Dovecot

When it comes to debugging Dovecot some commands come in handy:

- Get the configuration in a standard (comparable) format and secrets removed: `doveconf -n`
- Get the log output with focus on errors only: `doveadm log errors`
- Looking into specific user mailbox activities: `doveadm dump /var/lib/dovecot/<UUID_2CHARS>/<UUID>/mdbox/dovecot.mailbox.log`
  - When running openDesk CE the use `/srv/mail/` instead of `/var/lib/dovecot`
- Listing a users mailbox: `doveadm mailbox list -u <EMAIL_ADDRESS>`

Example for getting log output for specific events:

```shell
event_exporter log {
  format = json
  format_args = time-rfc3339
  transport = log
}

metric imap_command_unsubscribe {
  exporter = log
  filter = event=imap_command_finished AND cmd_name=UNSUBSCRIBE
}
```

### Nubus

#### Provisioning

This section should provide an overview on the Nubus Provisioning API in addition to the [available upstream documentation](https://docs.software-univention.de/nubus-customization/1.x/en/api/provisioning.html).

As of openDesk 1.13 the provisioning is used for Nubus internal use cases e.g. the self-service except for OX App Suite provisioning of objects like users and groups.

A core element of Nubus Provisioning is the messagaging system [NATS](https://nats.io/).

Below is a [simplified](https://docs.software-univention.de/nubus-kubernetes-architecture/1.x/en/components/provisioning-service.html#component-provisioning-service) representation of the end-to-end flow for an data object starting from the creation of using the UDM REST API until the object is getting persisted in the OX App Suite.

1. *HTTP Client*: Send UDM API Request.
2. [`udm-rest-api-*`](https://docs.software-univention.de/nubus-kubernetes-architecture/1.x/en/components/directory-manager.html#directory-manager): Processes the request writing the resulting object into the LDAP.
3. [`ldap-server-primary-0`](https://docs.software-univention.de/nubus-kubernetes-architecture/1.x/en/components/identity-store.html): LDAP as the actual identity data store.
4. [`ldap-notifier-0`](https://docs.software-univention.de/nubus-kubernetes-architecture/1.x/en/components/identity-store.html#notify-about-changes-to-directory-objects): Monitors changes to LDAP objects and makes them available to other components that implement a so-called listener.
5. [`provisioning-udm-listener-0`](https://docs.software-univention.de/nubus-kubernetes-architecture/1.x/en/components/provisioning-service.html#udm-listener): Receives the events from the notifier and generates NATS stream entries containting directory objects.
   - `provisioning-nats-0`: `stream:ldap-producer`
6. [`provisioning-udm-transformer-*`](https://docs.software-univention.de/nubus-kubernetes-architecture/1.x/en/components/provisioning-service.html#udm-transformer): Processes the directory objects and transforms them into UDM objects.
   - `provisioning-nats-0`: `stream:incoming`
7. [`provisioning-dispatcher-*`](https://docs.software-univention.de/nubus-kubernetes-architecture/1.x/en/components/provisioning-service.html#dispatcher): Dispatches all objects into all registered consumer streams. The consumer filters for its relevant events.
   - `provisioning-nats-0`: `stream:ox-connector`
8. [`provisioning-api-*`](https://docs.software-univention.de/nubus-kubernetes-architecture/1.x/en/components/provisioning-service.html#consumer-messages-http-rest-api): The service for consumers to retrieve their stream messages through.
9. [`ox-connector-0`](https://docs.software-univention.de/ox-connector-app/latest/index.html): The consumer retrieves the objects from its own stream through the Provisioning API, filters for the relevant ones and sends API requests to OX App Suite SOAP API.
10. [`open-xchange-core-mw-groupware-*`](https://documentation.open-xchange.com/components/middleware/http/8/index.html): OX App Suite Pod receiving the API calls. When `technical.oxAppSuite.provisioning.dedicatedCoreMwPod` is set to `true` the Pod name is `open-xchange-core-mw-admin-*`.
11. *OX App Suite MariaDB schema(s)*: Persistent storage for all received objects.

The Pod [`provisioning-prefill-*`](https://docs.software-univention.de/nubus-kubernetes-architecture/1.x/en/components/provisioning-service.html#prefill-service): Provides the consumer with information about directory objects that already exist in the directory at the time of registration.

For interaction with NATS it is convenient to have the NATS Box container available in the `provisioning-nats` Pod to execute `nats` CLI commands.
Check `technical.yaml.gotmpl` for details of the following setting:

```yaml
technical:
  nubus:
    provisioning:
      nats:
        natsBox:
          enabled: true
```

At good start is to check the NATS stream status using the following command, followed by more detailed looks at the key-value store:
```shell
nats stream ls --user=admin --password=${NATS_PASSWORD}
nats kv ls --user=admin --password=${NATS_PASSWORD}
nats kv ls --user=admin --password=${NATS_PASSWORD} SUBSCRIPTIONS
nats kv get --user=admin --password=${NATS_PASSWORD} SUBSCRIPTIONS ox-connector
```

#### Keycloak

##### Setting the log level

Keycloak is the gateway to integrate other authentication management systems or applications. It is undesirable to enable debug mode for the whole platform if you just need to look into Keycloak.

Enabling debugging mode for Keycloak can easily be achieved in two steps:

1. Updating the value for `KC_LOG_LEVEL` in the related configmap `ums-keycloak`.
```shell
export NAMESPACE=<your_namespace>
export CONFIGMAP_NAME=ums-keycloak
kubectl patch -n ${NAMESPACE} configmap ${CONFIGMAP_NAME} --type merge -p '{"data":{"KC_LOG_LEVEL":"DEBUG"}}'
```

2. Restart the Keycloak Pod(s).

> [!note]
> Because the `ums-keycloak-extensions-handler` is sending frequent requests (one per second) to Keycloak for
> retrieval of the Keycloak event history, you might want to stop/remove the deployment while
> debugging/analysing Keycloak to not get your debug output spammed by these requests.

> [!note]
> While you can set the standard log levels like `INFO`, `DEBUG`, `TRACE` etc. you can also set class specific
> logs by comma separating the details in the `KC_LOG_LEVEL` environment variable like
> e.g. `INFO,org.keycloak.protocol.oidc.endpoints:TRACE`. The example sets the overall loglevel to `INFO` but
> provides trace logs for `org.keycloak.protocol.oidc.endpoints`.

##### Accessing the Keycloak admin console

Deployments set to `debug.enable: true` expose the Keycloak admin console at `http://id.<your_opendesk_domain>/admin/`. This can also be achieved by updating the Ingress `ums-keycloak-extensions-proxy` with an additional path that allows access to `/admin/`.

The admin console login is using the default Keycloak admin account `kcadmin` and the password from the secret `ums-opendesk-keycloak-credentials`.
