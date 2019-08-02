#!/bin/bash

# TODO: Wait for the database container to be ready.
# Use condition: service_healthy and healthcheck
# See https://docs.docker.com/compose/compose-file/compose-file-v2
sleep 10

# Make directory that some scripts expect.
mkdir --parents /home/cartodb/cartodb/log

cd /cartodb

if [ "$HOSTING_ENVIRONMENT" = "AWS" ] ; then
  # We need to override some configs before the Rails app is started.
  echo "----- Setting app and database configs for AWS..."
  # /w /dev/stdout is to write changes to stdout so that they get logged.
  sed -i "s/host: 'redis'/host: '$REDIS_HOST'/w /dev/stdout" /cartodb/config/app_config.aws.yml
  # Overwrite app_config.yml and clean up the aws version of the file (no longer needed).
  cp /cartodb/config/app_config.aws.yml /cartodb/config/app_config.yml
  rm /cartodb/config/app_config.aws.yml
  sed -i "s/host: carto_postgres/host: '$POSTGRES_HOST'/w /dev/stdout" /cartodb/config/database.yml
fi

# There isn't a rake for this setting...
echo "----- Increasing Carto's hard-coded importer limit, MAX_TABLES_PER_IMPORT (10 --> 200)..."
sed -i "s/MAX_TABLES_PER_IMPORT = 10/MAX_TABLES_PER_IMPORT = 200/w /dev/stdout" /cartodb/services/importer/lib/importer/runner.rb

# Silence SQL logging which Carto enables by default when
# running the app in dev mode.
sed -i "s/Logger::DEBUG/Logger::INFO/w /dev/stdout" /cartodb/config/environments/development.rb

echo "----- Creating dev user..."
# This step creates the Carto metadata database and an initial user.
bash script/create_dev_user

echo "----- Creating a default organization and owner..."
bash script/setup_organization.sh

echo "----- Setting up the geocoder..."
bash script/geocoder.sh

echo "----- Starting the Varnish service..."
/opt/varnish/sbin/varnishd -a :6081 -T localhost:6082 -s malloc,256m -f /etc/varnish.vcl

# I'm pretty sure this isn't needed...
# echo "----- Restoring Redis..."
# bundle exec script/restore_redis

# The Resque daemon is needed for import jobs.
echo "----- Starting the Resque daemon..."
bundle exec script/resque > resque.log 2>&1 &

echo "----- Starting sync_tables loop..."
bash script/sync_tables_trigger.sh &

# Recreate API keys in db and Redis, so SQL API is authenticated
# See https://github.com/sverhoeven/docker-cartodb/commit/0f1d69e
echo "----- Recreating API keys..."
PGPASSWORD=$POSTGRES_PASSWORD psql --tuples-only \
                                   --host=$POSTGRES_HOST \
                                   --port=5432 \
                                   --username=$POSTGRES_USER \
                                   --echo-queries \
                                   --command="DELETE FROM api_keys" \
                                   --dbname=carto_db_production
bundle exec rake carto:api_key:create_default > /dev/null 2>&1

echo "----- Listing all available feature flags..."
bundle exec rake cartodb:features:list_all_features

# Keep this as the last task...
echo "----- Starting the Carto Builder Rails server..."
PORT=3000
bundle exec thin start --threaded -a 0.0.0.0 -p $PORT --threadpool-size 5
