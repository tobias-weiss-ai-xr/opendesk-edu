#!/bin/sh
set -e

# Create databases for each service
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres <<-EOSQL
    -- Create Keycloak database
    CREATE DATABASE keycloak_db OWNER keycloak_user ENCODING 'UTF8' LC_COLLATE='C';
    
    -- Create Synapse database
    CREATE DATABASE synapse_db OWNER synapse_user ENCODING 'UTF8' LC_COLLATE='C';
    
    -- Create OpenCloud database  
    CREATE DATABASE opencloud_db OWNER opencloud_user ENCODING 'UTF8';
    
    -- Create Notes database
    CREATE DATABASE notes_db OWNER notes_user ENCODING 'UTF8';
    
    -- Create MOX database
    CREATE DATABASE mox_db OWNER mox_user ENCODING 'UTF8';
    
    -- Create SOGo database
    CREATE DATABASE sogo_db OWNER sogo_user ENCODING 'UTF8';
    
    -- Create users for each database
    -- Keycloak
    CREATE USER keycloak_user WITH PASSWORD '${KEYCLOAK_DB_PASSWORD:-changeme}';
    GRANT ALL PRIVILEGES ON DATABASE keycloak_db TO keycloak_user;
    
    -- Synapse
    CREATE USER synapse_user WITH PASSWORD '${SYNAPSE_DB_PASSWORD:-changeme}';
    GRANT ALL PRIVILEGES ON DATABASE synapse_db TO synapse_user;
    
    -- OpenCloud
    CREATE USER opencloud_user WITH PASSWORD '${OPENCLOUD_DB_PASSWORD:-changeme}';
    GRANT ALL PRIVILEGES ON DATABASE opencloud_db TO opencloud_user;
    
    -- Notes
    CREATE USER notes_user WITH PASSWORD '${NOTES_DB_PASSWORD:-changeme}';
    GRANT ALL PRIVILEGES ON DATABASE notes_db TO notes_user;
    
    -- MOX
    CREATE USER mox_user WITH PASSWORD '${MOX_DB_PASSWORD:-changeme}';
    GRANT ALL PRIVILEGES ON DATABASE mox_db TO mox_user;
    
    -- SOGo
    CREATE USER sogo_user WITH PASSWORD '${SOGO_DB_PASSWORD:-changeme}';
    GRANT ALL PRIVILEGES ON DATABASE sogo_db TO sogo_user;
    
EOSQL

echo "Database initialization completed successfully"
