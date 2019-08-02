# Create foreign data wrapper to another Postgres DB.

# Get the database name for organization 'starter' (via admin 'bolt).
ORGANIZATION_DB=`echo "SELECT database_name FROM users WHERE username='bolt'" | psql --tuples-only --host=carto_postgres --port=5432 --username=$POSTGRES_USER -t carto_db_production`
echo "Carto database for 'bolt' is '$ORGANIZATION_DB'"

echo "CREATE EXTENSION IF NOT EXISTS postgres_fdw;" | psql --host=carto_postgres --port=5432 --username=$POSTGRES_USER $ORGANIZATION_DB
echo "CREATE SCHEMA gps;" | psql --host=carto_postgres --port=5432 --username=$POSTGRES_USER $ORGANIZATION_DB
echo "CREATE SERVER remotedb FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host 'db', port '5432', dbname 'starterdb');" | psql --host=carto_postgres --port=5432 --username=$POSTGRES_USER $ORGANIZATION_DB
echo "CREATE FOREIGN TABLE gps.places (id integer NOT NULL, location geometry) SERVER remotedb OPTIONS (schema_name 'gps', table_name 'places');"

# You would use `development_cartodb_user_` or `staging_cartodb_user` for those environments.
for user in `echo "SELECT 'cartodb_user_' || id FROM users WHERE organization_id = (SELECT id FROM organizations WHERE name='starter')" | psql --tuples-only --host=carto_postgres --port=5432 --username=$POSTGRES_USER -t carto_db_production`
do
  echo "GRANT USAGE ON SCHEMA gps TO ${user};" | psql --host=carto_postgres --port=5432 --username=$POSTGRES_USER $ORGANIZATION_DB
  echo "GRANT SELECT ON gps.places TO ${user};" | psql --host=carto_postgres --port=5432 --username=$POSTGRES_USER $ORGANIZATION_DB
  echo "GRANT USAGE ON FOREIGN SERVER remotedb TO ${user}" | psql --host=carto_postgres --port=5432 --username=$POSTGRES_USER $ORGANIZATION_DB
done

# User should be able to create his/her own mapping with
# CREATE USER MAPPING FOR bob SERVER remotedb (user 'bob', password 'secret');
# Then in create empty table in CartoDB and run something like
# SELECT row_number() OVER(ORDER BY id), location the_geom, ST_Transform(location, 3857) AS the_geom_webmercator FROM gps.places;
