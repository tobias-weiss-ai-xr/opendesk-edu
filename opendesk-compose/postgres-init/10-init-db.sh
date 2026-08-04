#!/bin/bash
# Create databases and users for each service
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres <<EOSQL
    -- Create Keycloak database and user
    CREATE USER keycloak_user WITH PASSWORD 'changeme';
    CREATE DATABASE keycloak_db OWNER keycloak_user ENCODING 'UTF8';
    GRANT ALL PRIVILEGES ON DATABASE keycloak_db TO keycloak_user;

    -- Create Synapse database and user
    CREATE USER synapse_user WITH PASSWORD 'changeme';
    CREATE DATABASE synapse_db OWNER synapse_user ENCODING 'UTF8';
    GRANT ALL PRIVILEGES ON DATABASE synapse_db TO synapse_user;

    -- Create OpenCloud database and user
    CREATE USER opencloud_user WITH PASSWORD 'changeme';
    CREATE DATABASE opencloud_db OWNER opencloud_user ENCODING 'UTF8';
    GRANT ALL PRIVILEGES ON DATABASE opencloud_db TO opencloud_user;

    -- Create Notes database and user
    CREATE USER notes_user WITH PASSWORD 'changeme';
    CREATE DATABASE notes_db OWNER notes_user ENCODING 'UTF8';
    GRANT ALL PRIVILEGES ON DATABASE notes_db TO notes_user;

    -- Create MOX database and user
    CREATE USER mox_user WITH PASSWORD 'changeme';
    CREATE DATABASE mox_db OWNER mox_user ENCODING 'UTF8';
    GRANT ALL PRIVILEGES ON DATABASE mox_db TO mox_user;

    -- Create SOGo database and user
    CREATE USER sogo_user WITH PASSWORD 'changeme';
    CREATE DATABASE sogo_db OWNER sogo_user ENCODING 'UTF8';
    GRANT ALL PRIVILEGES ON DATABASE sogo_db TO sogo_user;
EOSQL

echo "Database initialization completed successfully"
