#!/bin/bash
set -e

# These users are used by some CartoDB apps internally:
echo "----- Creating CartoDB users..."
createuser publicuser --no-createrole --no-createdb --no-superuser -U postgres
# It seems the publicuser password *must* be "publicuser", otherwise
# <Sequel::DatabaseConnectionError: PG::Error: FATAL:  password authentication failed for user "publicuser"
# I see nowhere to configure Carto Builder to use a different password.
psql --dbname=postgres --username=$POSTGRES_USER \
     --command="ALTER USER publicuser WITH PASSWORD 'publicuser';"
createuser tileuser --no-createrole --no-createdb --no-superuser -U postgres

# These steps which call out to a running Postgres server
# can't be moved to the Dockerfile because the server won't be ready
# during those build steps.
echo "----- Creating other required Postgres extensions..."
POSTGIS_SQL_PATH=`pg_config --sharedir`/contrib/postgis-2.4;
# CartoDB depends on a geospatial database template named template_postgis.
createdb --template=template0 --owner=$POSTGRES_USER --encoding=UTF8 template_postgis
psql --dbname=postgres --username=$POSTGRES_USER \
     --command="UPDATE pg_database SET datistemplate='true' \
                WHERE datname='template_postgis'"
psql --dbname=template_postgis --username=$POSTGRES_USER \
     --command="CREATE EXTENSION postgis; \
                CREATE EXTENSION postgis_topology; \
                GRANT ALL ON geometry_columns TO PUBLIC; \
                GRANT ALL ON spatial_ref_sys TO PUBLIC;"
psql --dbname=template_postgis --username=$POSTGRES_USER \
     --command="CREATE EXTENSION plpythonu;"
psql --dbname=template_postgis --username=$POSTGRES_USER \
     --command="CREATE EXTENSION crankshaft VERSION 'dev';"
psql --dbname=template_postgis --username=$POSTGRES_USER \
     --command="CREATE EXTENSION plproxy;"

# Note that schema_triggers are no longer needed
# See https://github.com/CartoDB/cartodb-postgresql/pull/190

psql --dbname=postgres --username=$POSTGRES_USER \
     --command="CREATE EXTENSION plpythonu; \
                CREATE EXTENSION postgis; \
                CREATE EXTENSION cartodb; \
                CREATE EXTENSION crankshaft VERSION 'dev'; \
                CREATE EXTENSION plproxy;"

# Create a geocoder database and user, https://github.com/CartoDB/dataservices-api
# psql --dbname=postgres --username=$POSTGRES_USER \
#      --command="CREATE DATABASE dataservices_db ENCODING='UTF8' LC_COLLATE='en_US.UTF-8' LC_CTYPE='en_US.UTF-8';"
# psql --dbname=postgres --username=$POSTGRES_USER \
#      --command="CREATE USER geocoder_api;"
# psql --dbname=dataservices_db --username=$POSTGRES_USER \
#      --command="BEGIN;CREATE EXTENSION IF NOT EXISTS plproxy; COMMIT" -e
# psql --dbname=dataservices_db --username=$POSTGRES_USER \
#      --command="BEGIN;CREATE EXTENSION IF NOT EXISTS cdb_dataservices_server; COMMIT" -e

# Overwrite pg_hba.conf (to include our CartoDB connection rules) and
# also postgresql.conf (to set listen_addresses).
# 1. Doing this in the Dockerfile would mess up initialization of the base
#    Docker image, so we do it here after Postgres is already running.
# 2. mv fails due to permission issues, but `truncate` and `cat >>` work fine.
# 3. Keep this last.
truncate -s 0 $PGDATA/pg_hba.conf
cat /tmp/pg_hba.conf >> $PGDATA/pg_hba.conf
truncate -s 0 $PGDATA/postgresql.conf
cat /tmp/postgresql.conf >> $PGDATA/postgresql.conf
psql --dbname=postgres --username=$POSTGRES_USER \
     --command="SELECT pg_reload_conf();"
