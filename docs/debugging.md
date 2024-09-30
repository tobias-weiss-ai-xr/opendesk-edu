<!--
SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-License-Identifier: Apache-2.0
-->
<h1>Debugging</h1>

* [Disclaimer](#disclaimer)
* [Enable debugging](#enable-debugging)
* [Adding containers to a pod for debugging purposes](#adding-containers-to-a-pod-for-debugging-purposes)
  * [Adding a container to a pod/deployment - Dev/Test only](#adding-a-container-to-a-poddeployment---devtest-only)
  * [Temporary/ephemeral containers](#temporaryephemeral-containers)
* [Components](#components)
  * [MariaDB](#mariadb)
  * [Nextcloud](#nextcloud)
  * [OpenProject](#openproject)
  * [PostgreSQL](#postgresql)

# Disclaimer

This document collects information how to deal with debugging an openDesk deployment.

It will be extended over time as we have to deal with debugging cases.

We for sure do not want to reinvent the wheel, so we might link to external sources that contain helpful
information where available.

**Note:** You should never enable debug in production environments! By looking up `debug.enable` in the deployment you
will find the various places changes are applied when enabling debugging. So outside of development and test
environments you may want to make use of them in a very thoughtful and selective manner if needed.

# Enable debugging

Set `debug.enable` to `true` in [`debug.yaml`](../helmfile/environments/default/debug.yaml) to set the
component's log level to debug and it get some features like:
- The `/admin` console is routed for Keycloak.
- An ingress for `http://minio-console.<your_domain>` is configured.
and set the log level for components to "Debug".

**Note**: When enabling debug and running upgrades you must manually delete all jobs before the upgrade. As with debug
we keep the jobs and some job fields are immutable it could otherwise lead into an upgrade failure.

**Note:** All containers should write their log output to STDOUT, if you find (valuable) logs inside a container, please let us know!

# Adding containers to a pod for debugging purposes

During test or development you come across the need to execute tools, browse or even change things in the filesystem of another container.

This can be a challenge the more security hardened container images are, because there are no debugging tools available and sometimes not even a shell.

Adding a container to a Pod can ease the pain.

Below you will find some wrap-up notes when it comes to debugging openDesk by adding debug containers. Of course there are a lot of more detailed resources out in the wild.

## Adding a container to a pod/deployment - Dev/Test only

You can add a container by editing and updating an existing deployment, which is quite comfortable with tools like [Lens](https://k8slens.dev/).

- Select the container you want to make use of as debugging container, in the example below it is `registry.opencode.de/bmi/opendesk/components/platform-development/images/opendesk-debugging-image:latest`.
- Ensure the `shareProcessNamespace` option is enabled for the Pod.
- Reference the selected container within the `containers` array of the deployment.
- In case you want to access another containers filesystem, ensure the user/group settings of both containers match.
- Save & update the deployment.

The following example can e.g. be used to debug the `openDesk-Nextcloud-PHP` container, in case you want to modify files, don't forget to set `readOnlyRootFilesystem` to `true` on the PHP container.

```
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

- After the deployment was reloaded open the shell of the debugging container.
- When you've been successful you will see the processes of both/all containers in the pod when doing a `ps aux`.
- To access another containers filesystem just select the PID of a process from the other container an do a `cd /proc/<selected_process_id>/root`

## Temporary/ephemeral containers

Interesting read we picked most of the details below from: https://iximiuz.com/en/posts/kubernetes-ephemeral-containers/

Sometimes you do not want to add a container permanently to your existing deployment. In that case you could use [ephemeral containers](https://kubernetes.io/docs/concepts/workloads/pods/ephemeral-containers/).

For the commands further down this section we set some environment variables first:
- `NAMESPACE`: The namespace the Pod you want to inspects is running in.
- `DEPLOYMENT_NAME`: The name of the deployment responsible for spawning the Pod you want to inspect within the pre-mentioned namespace.
- `POD_NAME`: The name of the Pod you want to inspect within the pre-mentioned namespace.
- `EPH_CONTAINER_NAME`: Chose the name for the container, "debugging" seem obvious.
- `DEBUG_IMAGE`: The image you want to make use of for debugging purposes.

e.g.

```
export EPH_CONTAINER_NAME=debugging
export NAMESPACE=my_test_deployment
export DEPLOYMENT_NAME=opendesk-nextcloud-php
export POD_NAME=opendesk-nextcloud-php-6686d47cfb-7642f
export DEBUG_IMAGE=registry.opencode.de/bmi/opendesk/components/platform-development/images/opendesk-debugging-image:1.0.0
```

You still need to ensure that your deployment supports process namespace sharing:

```
kubectl -n ${NAMESPACE} patch deployment ${DEPLOYMENT_NAME} --patch '
spec:
  template:
    spec:
      shareProcessNamespace: true'
```

Now you can add the ephemeral container with:
```
kubectl -n ${NAMESPACE} debug -it --attach=false -c ${EPH_CONTAINER_NAME} --image={DEBUG_IMAGE} ${POD_NAME}
```
and open its interactive terminal with
```
kubectl -n ${NAMESPACE} attach -it -c ${EPH_CONTAINER_NAME} ${POD_NAME}
```

# Components

## MariaDB

When using the openDesk bundled MariaDB you can explore database(s) using the MariaDB interactive terminal from the pod's command line: `mariadb -u root -p`. As password provide the value for `MARIADB_ROOT_PASSWORD` set in the pod's environment.

While you will find all details for the CLI tool in [the online documentation](https://mariadb.com/kb/en/mariadb-command-line-client/), some quick commands are:

- `help`: Get help on the psql command set
- `show databases`: Lists all databases
- `use <databasename>`: Connect to `<databasename>`
- `show tables`: Lists tables within the currently connected database
- `quit`: Quit the client

## Nextcloud

`occ` is the CLI for Nextcloud, all the details can be found in the [upstream documentation](https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/occ_command.html).

You can run occ commands in the `opendesk-nextcloud-php` pod like this: `php /var/www/html/occ config:list`

## OpenProject

OpenProject is a Ruby on Rails application. Therefore you can make use of the Rails console from the pod's command line `bundle exec rails console`

and run debug code like this:

```
uri = URI('https://nextcloud.url/index.php/apps/integration_openproject/check-config')
Net::HTTP.start(uri.host, uri.port,
  :use_ssl => uri.scheme == 'https') do |http|
  request = Net::HTTP::Get.new uri
  response = http.request request # Net::HTTPResponse object
end
```

## PostgreSQL

When using the openDesk bundled PostgreSQL you can explore database(s) using the PostgreSQL interactive terminal from the pod's command line: `psql -U postgres`.

While you will find all details in the [psql subsection](https://www.postgresql.org/docs/current/app-psql.html)) of the PostgreSQL documentation, some quick commands are:

- `\?`: Get help on the psql command set
- `\l`: Lists all databases
- `\c <databasename>`: Connect to `<databasename>`
- `\dt`: List (describe) tables within the currently connected database
- `\q`: Quit the client
