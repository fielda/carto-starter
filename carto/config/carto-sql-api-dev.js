// Time in milliseconds to force GC cycle.
// Disable by using <=0 value.
module.exports.gc_interval = 10000;
// In case the base_url has a :user param the username will be the one specified in the URL,
// otherwise it will fallback to extract the username from the host header.
module.exports.base_url     = '(?:/api/:version|/user/:user/api/:version)';
// If useProfiler is true every response will be served with an
// X-SQLAPI-Profile header containing elapsed timing for various
// steps taken for producing the response.
module.exports.useProfiler = true;
module.exports.log_format   = '[:date] :remote-addr :method :req[Host]:url :status :response-time ms -> :res[Content-Type] (:res[X-SQLAPI-Profiler]) (:res[X-SQLAPI-Errors])';
// If log_filename is given logs will be written there, in append mode. Otherwise stdout is used (default).
// Log file will be re-opened on receiving the HUP signal
module.exports.log_filename = 'logs/cartodb-sql-api.log';
// Regular expression pattern to extract username
// from hostname. Must have a single grabbing block.
module.exports.user_from_host = process.env.USER_FROM_HOST || '^(.*?)\\.';
module.exports.node_port    = 8080;
// https://groups.google.com/forum/#!msg/cartodb/atRITapYYec/df5oozJXCwUJ
// With 'host' as an empty string, the API listens to all IP addresses,
// not just localhost.
module.exports.node_host    = '';
// idle socket timeout, in miliseconds
module.exports.node_socket_timeout    = 600000;
// This API can run in a "development" environment even if Carto Builder
// and the databases are "production".
module.exports.environment = process.env.NODE_ENV || 'development';
// Remember that the database is created by a Rails Rake script...
// When RAILS_ENV="development" on the Carto Builder machine,
// user databases are found via 'cartodb_dev_user_<%= user_id %>_db'.
module.exports.db_base_name = 'cartodb_user_<%= user_id %>_db';
// And when RAILS_ENV="development" on the Carto Builder machine,
// usernames follow the pattern 'development_cartodb_user_<%= user_id %>'.
// Supported labels: 'user_id' (read from redis)
module.exports.db_user      = 'cartodb_user_<%= user_id %>';
// Supported labels: 'user_id', 'user_password' (both read from redis)
module.exports.db_user_pass = '<%= user_password %>'
// Name of the anonymous PostgreSQL user
module.exports.db_pubuser   = 'publicuser';
// Password for the anonymous PostgreSQL user
module.exports.db_pubuser_pass   = 'publicuser';
module.exports.db_host           = process.env.POSTGRES_HOST || 'carto_postgres';
// If 'staging' or 'production', then use 6432.
// https://github.com/CartoDB/CartoDB-SQL-API/search?utf8=✓&q=6432
module.exports.db_port           = process.env.POSTGRES_PORT || '5432';
module.exports.db_batch_port     = process.env.POSTGRES_PORT || '5432';
module.exports.finished_jobs_ttl_in_seconds = 2 * 3600; // 2 hours
module.exports.batch_query_timeout = 12 * 3600 * 1000; // 12 hours in milliseconds
module.exports.batch_log_filename = 'logs/batch-queries.log';
module.exports.copy_timeout = "'5h'";
module.exports.copy_from_max_post_size = 2 * 1024 * 1024 * 1024 // 2 GB;
module.exports.copy_from_max_post_size_pretty = '2 GB';
// Max number of queued jobs a user can have at a given time
module.exports.batch_max_queued_jobs = 64;
// Capacity strategy to use.
// It allows to tune how many queries run at a db host at the same time.
// Options: 'fixed', 'http-simple', 'http-load'
module.exports.batch_capacity_strategy = 'fixed';
// Applies when strategy='fixed'.
// Number of simultaneous users running queries in the same host.
// It will use 1 as min.
// Default 4.
module.exports.batch_capacity_fixed_amount = 4;
// Applies when strategy='http-simple' or strategy='http-load'.
// HTTP endpoint to check db host load.
// Helps to decide the number of simultaneous users running queries in that host.
// 'http-simple' will use 'available_cores' to decide the number.
// 'http-load' will use 'cores' and 'relative_load' to decide the number.
// It will use 1 as min.
// If no template is provided it will default to 'fixed' strategy.
module.exports.batch_capacity_http_url_template = 'http://<%= dbhost %>:9999/load';
// Max database connections in the pool
// Subsequent connections will wait for a free slot.
// NOTE: not used by OGR-mediated accesses
module.exports.db_pool_size = 500;
// Milliseconds before a connection is removed from pool
module.exports.db_pool_idleTimeout = 30000;
// Milliseconds between idle client checking
module.exports.db_pool_reapInterval = 1000;
// max number of bytes for a row, when exceeded the query will throw an error
//module.exports.db_max_row_size = 10 * 1024 * 1024;
// allows to use an object to connect with node-postgres instead of a connection string
//module.exports.db_use_config_object = true;
// requires enabling db_use_config_object=true
// allows to enable/disable keep alive for database connections
// by default is not enabled
//module.exports.db_keep_alive = {
//    enabled: true,
//    initialDelay: 5000
//};
module.exports.redis_host = process.env.REDIS_HOST || 'redis'; // see docker-compose.yml
module.exports.redis_port = process.env.REDIS_PORT || 6379;
// Max number of connections in each pool.
// Users will be put on a queue when the limit is hit.
module.exports.redisPool    = 50;
module.exports.redisIdleTimeoutMillis   = 100;
module.exports.redisReapIntervalMillis  = 10;
module.exports.redisLog     = false;

// tableCache settings
module.exports.tableCacheEnabled = false; // false by default
// Max number of entries in the query tables cache
module.exports.tableCacheMax = 8192;
// Max age of query table cache items, in milliseconds
module.exports.tableCacheMaxAge = 1000*60*10;

// Temporary directory, make sure it is writable by server user
module.exports.tmpDir = '/tmp';
// change ogr2ogr command or path
module.exports.ogr2ogrCommand = 'ogr2ogr';
// change zip command or path
module.exports.zipCommand = 'zip';
// Optional statsd support
module.exports.statsd = {
  host: 'localhost',
  port: 8125,
  prefix: 'dev.:host.',
  cacheDns: true
  // support all allowed node-statsd options
};
module.exports.health = {
    enabled: true,
    username: 'development',
    query: 'select 1'
};
module.exports.disabled_file = 'pids/disabled';

module.exports.ratelimits = {
  // whether it should rate limit endpoints (global configuration)
  rateLimitsEnabled: false,
  // whether it should rate limit one or more endpoints (only if rateLimitsEnabled = true)
  endpoints: {
    query: false,
    query_format: false,
    job_create: false,
    job_get: false,
    job_delete: false
  }
}

module.exports.validatePGEntitiesAccess = false;
module.exports.dataIngestionLogPath = 'logs/data-ingestion.log';