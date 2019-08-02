cd /cartodb

# The names of these environment variables are not arbitrary.
# https://github.com/CartoDB/cartodb/blob/master/lib/tasks/setup.rake#L135
EMAIL="geocoder@example.org"
USERNAME="geocoder"
PASSWORD="bitcoin legend 8"
ADMIN_PASSWORD="bitcoin legend 8"
BUILDER_ENABLED="true"

# It is mandatory to install cdb_geocoder into a CARTO user's database,
# so we create a user called "geocoder".
# https://github.com/CartoDB/data-services/blob/master/geocoder/extension/README.md
echo "----- Creating '${USERNAME}' user..."
bundle exec rake cartodb:db:create_user --trace SUBDOMAIN="${USERNAME}" \
                                                PASSWORD="${PASSWORD}" \
                                                ADMIN_PASSWORD="${ADMIN_PASSWORD}" \
                                                EMAIL="${EMAIL}" > /dev/null 2>&1

echo "----- Updating 'geocoder' quota to 10GB"
bundle exec rake cartodb:db:set_user_quota[$USERNAME,10240] > /dev/null 2>&1

echo "----- Allowing unlimited tables creation for '${USERNAME}'"
bundle exec rake cartodb:db:set_unlimited_table_quota[$USERNAME] > /dev/null 2>&1

# Get the database name for user 'geocoder'.
GEOCODER_DB=`echo "SELECT database_name FROM users WHERE username='$USERNAME'" | PGPASSWORD=$POSTGRES_PASSWORD psql --tuples-only --host=$POSTGRES_HOST --port=5432 --username=$POSTGRES_USER --dbname=carto_db_production`
echo "----- GEOCODER_DB=$GEOCODER_DB"
PGPASSWORD=$POSTGRES_PASSWORD psql --host=$POSTGRES_HOST \
                                   --port=5432 \
                                   --username=$POSTGRES_USER \
                                   --command="SELECT format('----- GEOCODER_DB: %s, User: %s',current_database(),user) db_details;" \
                                   -d $GEOCODER_DB

# Configure the 'geocoder' database.
PGPASSWORD=$POSTGRES_PASSWORD psql --host=$POSTGRES_HOST \
                                   --port=5432 \
                                   --username=$POSTGRES_USER \
                                   -d $GEOCODER_DB < /cartodb/script/geocoder_server.sql

# Import observatory test dataset into 'geocoder' database.
PGPASSWORD=$POSTGRES_PASSWORD psql --host=$POSTGRES_HOST \
                                   --port=5432 \
                                   --username=$POSTGRES_USER \
                                   -d $GEOCODER_DB \
                                   -f /observatory-extension/src/pg/test/fixtures/load_fixtures.sql

# Setup Observatory inside 'geocoder' database.
PGPASSWORD=$POSTGRES_PASSWORD psql --host=$POSTGRES_HOST \
                                   --port=5432 \
                                   --username=$POSTGRES_USER \
                                   --echo-queries \
                                   --command="BEGIN;CREATE EXTENSION IF NOT EXISTS observatory VERSION 'dev'; COMMIT" \
                                   -d $GEOCODER_DB
PGPASSWORD=$POSTGRES_PASSWORD psql --host=$POSTGRES_HOST \
                                   --port=5432 \
                                   --username=$POSTGRES_USER \
                                   --echo-queries \
                                   --command="BEGIN;GRANT SELECT ON ALL TABLES IN SCHEMA cdb_observatory TO geocoder; COMMIT" \
                                   -d $GEOCODER_DB
PGPASSWORD=$POSTGRES_PASSWORD psql --host=$POSTGRES_HOST \
                                   --port=5432 \
                                   --username=$POSTGRES_USER \
                                   --echo-queries \
                                   --command="BEGIN;GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA cdb_observatory TO geocoder; COMMIT" \
                                   -d $GEOCODER_DB
PGPASSWORD=$POSTGRES_PASSWORD psql --host=$POSTGRES_HOST \
                                   --port=5432 \
                                   --username=$POSTGRES_USER \
                                   --echo-queries \
                                   --command="BEGIN;GRANT SELECT ON ALL TABLES IN SCHEMA observatory TO geocoder; COMMIT" \
                                   -d $GEOCODER_DB
PGPASSWORD=$POSTGRES_PASSWORD psql --host=$POSTGRES_HOST \
                                   --port=5432 \
                                   --username=$POSTGRES_USER \
                                   --echo-queries \
                                   --command="BEGIN;GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA observatory TO geocoder; COMMIT" \
                                   -d $GEOCODER_DB

# Get the database name for user 'dev'.
USER_DB=`echo "SELECT database_name FROM users WHERE username='dev'" | PGPASSWORD=$POSTGRES_PASSWORD psql --tuples-only --host=$POSTGRES_HOST --port=5432 --username=$POSTGRES_USER --dbname=carto_db_production`
echo "----- USER_DB=$USER_DB"
PGPASSWORD=$POSTGRES_PASSWORD psql --host=$POSTGRES_HOST \
                                   --port=5432 \
                                   --username=$POSTGRES_USER \
                                   --echo-queries \
                                   --command="SELECT format('----- USER_DB: %s, User: %s',current_database(),user) db_details;" \
                                   -d $USER_DB

# Setup dataservices client for 'dev'.
PGPASSWORD=$POSTGRES_PASSWORD psql --host=$POSTGRES_HOST \
                                   --port=5432 \
                                   --username=$POSTGRES_USER \
                                   --echo-queries \
                                   --command="CREATE EXTENSION cdb_dataservices_client;" \
                                   -d $USER_DB
PGPASSWORD=$POSTGRES_PASSWORD psql --tuples-only \
                                   --host=$POSTGRES_HOST \
                                   --port=5432 \
                                   --username=$POSTGRES_USER \
                                   --echo-queries \
                                   --command="SELECT CDB_Conf_SetConf('user_config', '{"'"is_organization"'": false, "'"entity_name"'": "'"dev"'"}');" \
                                   -d $USER_DB
# echo "----- IS THIS RIGHT?!?! --> SELECT CDB_Conf_SetConf('geocoder_server_config', '{ \"connection_str\": \"host=carto_postgres port=5432 dbname=${GEOCODER_DB# } user=postgres\"}');"
PGPASSWORD=$POSTGRES_PASSWORD psql --tuples-only \
                                   --host=$POSTGRES_HOST \
                                   --port=5432 \
                                   --username=$POSTGRES_USER \
                                   --echo-queries \
                                   --command="SELECT CDB_Conf_SetConf('geocoder_server_config', '{ \"connection_str\": \"host=carto_postgres port=5432 dbname=${GEOCODER_DB# } user=postgres\"}');" \
                                   -d $USER_DB

echo "----- Set geocoding limits for user 'dev'..."
bundle exec rake cartodb:services:set_user_quota["dev",geocoding,100000] > /dev/null 2>&1

# Get the database name for organization 'starter' (via admin 'bolt).
ORGANIZATION_DB=`echo "SELECT database_name FROM users WHERE username='bolt'" | PGPASSWORD=$POSTGRES_PASSWORD psql --tuples-only --host=$POSTGRES_HOST --port=5432 --username=$POSTGRES_USER --dbname=carto_db_production`
echo "----- ORGANIZATION_DB=$ORGANIZATION_DB"
PGPASSWORD=$POSTGRES_PASSWORD psql --host=$POSTGRES_HOST \
                                   --port=5432 \
                                   --username=$POSTGRES_USER \
                                   --echo-queries \
                                   --command="SELECT format('----- ORGANIZATION_DB: %s, User: %s',current_database(),user) db_details;" \
                                   -d $ORGANIZATION_DB

# Setup dataservices client for 'starter'.
PGPASSWORD=$POSTGRES_PASSWORD psql --host=$POSTGRES_HOST \
                                   --port=5432 \
                                   --username=$POSTGRES_USER \
                                   --echo-queries \
                                   --command="CREATE EXTENSION cdb_dataservices_client;" \
                                   -d $ORGANIZATION_DB
PGPASSWORD=$POSTGRES_PASSWORD psql --host=$POSTGRES_HOST \
                                   --port=5432 \
                                   --username=$POSTGRES_USER \
                                   --echo-queries \
                                   --command="SELECT CDB_Conf_SetConf('user_config', '{"'"is_organization"'": true, "'"entity_name"'": "'"starter"'"}');" \
                                   -d $ORGANIZATION_DB
# echo "----- IS THIS RIGHT?!?! --> SELECT CDB_Conf_SetConf('geocoder_server_config', '{ \"connection_str\": \"host=carto_postgres port=5432 dbname=${GEOCODER_DB# } user=postgres\"}');"
PGPASSWORD=$POSTGRES_PASSWORD psql --tuples-only \
                                   --host=$POSTGRES_HOST \
                                   --port=5432 \
                                   --username=$POSTGRES_USER \
                                   --echo-queries \
                                   --command="SELECT CDB_Conf_SetConf('geocoder_server_config', '{ \"connection_str\": \"host=carto_postgres port=5432 dbname=${GEOCODER_DB# } user=postgres\"}');" \
                                   -d $ORGANIZATION_DB

echo "----- Set geocoding limits for organization 'starter'..."
bundle exec rake cartodb:services:set_org_quota["starter",geocoding,100000] > /dev/null 2>&1

echo "----- Configuring geocoder extension for ALL non-org users..."
bundle exec rake cartodb:db:configure_geocoder_extension_for_non_org_users["",true] > /dev/null 2>&1

