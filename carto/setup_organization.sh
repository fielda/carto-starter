#!/bin/sh

set -e

cd /cartodb

# TODO: Manage feature flags via Carto's Rake tasks.
# http://cartodb.readthedocs.io/en/latest/operations/change_feature_flags.html
# echo "INSERT INTO feature_flags (id,name,restricted) VALUES (nextval('machine_added_feature_flags_id_seq'), 'editor-3', false);" | PGPASSWORD=$POSTGRES_PASSWORD psql --host=$POSTGRES_HOST --port=5432 --username=$POSTGRES_USER --dbname=carto_db_production && \
# echo "INSERT INTO feature_flags (id,name,restricted) VALUES (nextval('machine_added_feature_flags_id_seq'), 'explore_site', false);" | PGPASSWORD=$POSTGRES_PASSWORD psql --host=$POSTGRES_HOST --port=5432 --username=$POSTGRES_USER --dbname=carto_db_production && \

# ORGANIZATION_NAME is a short name for the organization.
# It may contain letters, numbers and dash (-) characters.
ORGANIZATION_NAME="starter"
# ORGANIZATION_DISPLAY_NAME may contain any characters needed.
ORGANIZATION_DISPLAY_NAME="Carto Starter, Inc."
# In honor of Usain Bolt, the fastest man on Earth...
USERNAME="bolt"
EMAIL="bolt@example.org"
PASSWORD="bitcoin legend 8"

# https://github.com/CartoDB/cartodb/blob/master/lib/tasks/setup.rake#L144
DATABASE_HOST=$POSTGRES_HOST

# create_user and create_new_organization_with_owner tasks read BUILDER_ENABLED.
# https://github.com/CartoDB/cartodb/blob/master/lib/tasks/setup.rake#L135
# https://github.com/CartoDB/cartodb/blob/master/lib/tasks/db_maintenance.rake#L865
BUILDER_ENABLED="true"

# For create_new_organization_with_owner to work properly, a user created
# beforehand must be provided as an owner.
echo "----- Creating user '${USERNAME}'..."
bundle exec rake cartodb:db:create_user EMAIL="${EMAIL}" PASSWORD="${PASSWORD}" SUBDOMAIN="${USERNAME}" > /dev/null 2>&1

echo "----- Increasing '${USERNAME}' user max layers..."
bundle exec rake user:change:max_layers["${USERNAME}",99] > /dev/null 2>&1

# USER_QUOTA is the space in MB that the user is assigned.
USER_QUOTA=20480
echo "----- Updating '${USERNAME}' user quota to 20GB..."
bundle exec rake cartodb:db:set_user_quota["${USERNAME}",$USER_QUOTA] > /dev/null 2>&1

# echo "----- Allowing unlimited tables creation for '${USERNAME}'..."
# bundle exec rake cartodb:db:set_unlimited_table_quota["${USERNAME}"] > /dev/null 2>&1

echo "----- Allowing 10,000 tables creation for '${USERNAME}'..."
bundle exec rake cartodb:db:set_user_table_quota["${USERNAME}",10000] > /dev/null 2>&1

echo "----- Allowing private tables creation for '${USERNAME}'..."
bundle exec rake cartodb:db:set_user_private_tables_enabled["${USERNAME}",'true'] > /dev/null 2>&1

echo "----- Updating '${USERNAME}' import limits..."
# https://github.com/CartoDB/cartodb/blob/master/doc/manual/source/operations/changing_limits.rst
MAX_BYTES=15000000000 # 15GB
MAX_ROWS=7000000 # seven million
MAX_CONCURRENT_IMPORTS=20
bundle exec rake cartodb:set_custom_limits_for_user["${USERNAME}",$MAX_BYTES,$MAX_ROWS,$MAX_CONCURRENT_IMPORTS] > /dev/null 2>&1

echo "----- Set monthly geocoding limits for '${USERNAME}'..."
bundle exec rake cartodb:services:set_user_quota["${USERNAME}",geocoding,10000] > /dev/null 2>&1

# ORGANIZATION_SEATS is the number of users that will be able to be
# created under the organization.
ORGANIZATION_SEATS=7
# ORGANIZATION_QUOTA is the quota_in_bytes that the organization is assigned.
ORGANIZATION_QUOTA=2684354560
echo "----- Creating organization '${ORGANIZATION_NAME}'..."
bundle exec rake cartodb:db:create_new_organization_with_owner ORGANIZATION_NAME="${ORGANIZATION_NAME}" USERNAME="${USERNAME}" ORGANIZATION_SEATS=$ORGANIZATION_SEATS ORGANIZATION_QUOTA=$ORGANIZATION_QUOTA ORGANIZATION_DISPLAY_NAME="${ORGANIZATION_NAME}" > /dev/null 2>&1
bundle exec rake cartodb:db:set_organization_quota["${ORGANIZATION_NAME}",$ORGANIZTION_QUOTA] > /dev/null 2>&1

# See https://github.com/CartoDB/dataservices-api
echo "----- Configuring geocoder extension for ALL organizations..."
bundle exec rake cartodb:db:configure_geocoder_extension_for_organizations["",true] > /dev/null 2>&1

echo "----- Enabling sync tables for '${ORGANIZATION_NAME}'..."
echo "UPDATE users SET sync_tables_enabled=true WHERE username='${ORGANIZATION_NAME}'" |\
  PGPASSWORD=$POSTGRES_PASSWORD psql --host=$POSTGRES_HOST \
                                     --port=5432 \
                                     --username=$POSTGRES_USER \
                                     -t carto_db_production \
                                     --echo-queries

# Enable private maps
echo "UPDATE users SET private_maps_enabled = 't'" |\
  PGPASSWORD=$POSTGRES_PASSWORD psql --host=$POSTGRES_HOST \
                                     --port=5432 \
                                     --username=$POSTGRES_USER \
                                     -t carto_db_production \
                                     --echo-queries

# The new_dashboard feature flag will trigger a user notification about their dashboard.
echo "----- Enabling feature flags for all users..."
bundle exec rake cartodb:features:enable_feature_for_all_users["new_dashboard"] > /dev/null 2>&1
# bundle exec rake cartodb:features:enable_feature_for_all_users["new_public_dashboard_global"]
# bundle exec rake cartodb:features:enable_feature_for_all_users["new_public_dashboard"]
