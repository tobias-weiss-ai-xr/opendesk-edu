<!--
SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-License-Identifier: Apache-2.0
-->
<h1>Debugging</h1>

* [Disclaimer](#disclaimer)
* [Enable debugging](#enable-debugging)
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
component's loglevel to debug and it get some features like:
- The `/admin` console is routed for Keycloak.
- An ingress for `http://minio-console.<your_domain>` is configured.
and set the loglevel for components to "Debug".

**Note:** All containers should write their log output to STDOUT, if you find (valuable) logs inside a container, please let us know!

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
