#!/bin/sh

set -e

# TODO: If $SYNC_TABLES_INTERVAL is not found or less than 1min, set it to 1min.

while :
do
sleep $SYNC_TABLES_INTERVAL
cd /cartodb
bundle exec rake cartodb:sync_tables[true]
done

