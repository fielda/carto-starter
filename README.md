Table of Contents
=================

   * [Notice](#notice)
   * [Getting Started](#getting-started)
   * [About the Containers](#about-the-containers)
   * [Your Hosts Config](#your-hosts-config)
   * [Notes on AWS ECS](#notes-on-aws-ecs)

## Notice

This repo is *BETA* software. It attempts to provide a solid starting point
for running CartoDB in a multi-container environment, but CartoDB is
complex and we do not pretend to have all the configurations and installation
steps perfected.

## Getting Started

1. Install and start Docker Compose,
   see https://docs.docker.com/engine/installation/
   and https://docs.docker.com/compose/install/

2. Build the images:

   *Requires an Internet connection because the build process calls apt-get and npm.*

   *Relax, building from scratch may take an hour.*

    ```Shell
    cd /path/to/repo
    make rebuild
    ```

    Docker will build images according to `./docker-compose.yml`

3. Run the images as group of networked containers:

    ```Shell
    make up
    ```

4. *[Optional]* Log into a container:

    ```Shell
    # List running containers
    docker ps
    # Log into the the Maps API, aka "Windshaft"
    docker exec -it carto-starter_carto_mapsapi_1 bash
    ```

    Type `exit` to log out of the container.

5. *[Optional]* Log into the reverse proxy:

    ```Shell
    # List running containers
    docker ps
    # Log into Nginx
    docker exec -it carto-starter_nginx_1 sh
    ```

    *Notice that we use `sh` and not `bash`. The Nginx container is based on
    [Alpine Linux](https://hub.docker.com/_/alpine/) which is small
    and does not have `bash`.*

    Type `exit` to log out of the container.

6. Tear down the environment:

    ```Shell
    # ^C
    # Then call `down`...
    make down
    ```

## About the Containers

![Carto Map UI](/carto-screenshot-01.png?raw=true)

1. **Carto Builder**
`carto-starter_carto_builder_1`:
This is a Ruby on Rails app, formally called the CartoDB Editor.
It provides a nice mapping interface and pages to manage your organization,
user account, and data tables.

2. **Windshaft Maps API**,
`carto-starter_carto_mapsapi_1`:
This is an API to generate map tiles and "static maps" (which are typically
larger than tiles) for display or printing. Windshaft uses Mapnik for
rendering and something called "grainstore" is called to convert CartoCSS
styles into Mapnik XML as needed. You can ask the API for raster tiles
(e.g. PNGs) or Mapbox vector tiles (MVT).

3. **SQL API**
`carto-starter_carto_sqlapi_1`:
The SQL API allows RAW SQL (including PostGIS SQL!) to be passed into
a Carto user's database and the API will return the result as JSON, geoJSON,
CSV, Shapefile, SVG, KML, or SpatialLite. `SELECT`, `INSERT`, `UPDATE` and
`DELETE` statements are allowed...

... You might be thinking, *"That's dangerous! How do they stop SQL injections?"*
Read this: https://carto.com/developers/sql-api/support/tips-and-tricks/

4. **Carto Postgres**
`carto-starter_carto_postgres_1`:
CartoDB creates a central "metadata" database for managing users. Then each
user also gets their own private database for spatial data tables.

We have created one Postgres server (`carto-starter_carto_postgres_1`) for these
potentially hundreds or thousands of databases. At some point, we will
need to setup clustering or some other scaling scheme to handle
the load, but for the near term one database server will handle all
Carto mapping (and yes, Postgres can easily handle thousands of databases).

CartoDB tables have no pre-determined data model except for a
[minimal required schema](https://github.com/CartoDB/cartodb-postgresql/blob/master/scripts-available/CDB_CartodbfyTable.sql).

## Your Hosts Config

The network setup for Builder, SQL API, Maps API, and the database is
complicated. We use Nginx to proxy requests to the APIs and to Carto Builder.

This setup should be improved, but for now, you'll need to add
entries into your machine's `/etc/hosts` file:

```Shell
# Carto Builder
echo "127.0.0.1 carto.lan" | sudo tee -a /etc/hosts
echo "127.0.0.1 bolt.carto.lan" | sudo tee -a /etc/hosts
echo "127.0.0.1 dev.carto.lan" | sudo tee -a /etc/hosts
echo "127.0.0.1 starter.carto.lan" | sudo tee -a /etc/hosts

# Carto Maps API
echo "127.0.0.1 mapsapi.lan" | sudo tee -a /etc/hosts
echo "127.0.0.1 bolt.mapsapi.lan" | sudo tee -a /etc/hosts
echo "127.0.0.1 dev.mapsapi.lan" | sudo tee -a /etc/hosts
echo "127.0.0.1 starter.mapsapi.lan" | sudo tee -a /etc/hosts

# Carto SQL API
echo "127.0.0.1 sqlapi.lan" | sudo tee -a /etc/hosts
echo "127.0.0.1 bolt.sqlapi.lan" | sudo tee -a /etc/hosts
echo "127.0.0.1 dev.sqlapi.lan" | sudo tee -a /etc/hosts
echo "127.0.0.1 starter.sqlapi.lan" | sudo tee -a /etc/hosts
```

## Notes on AWS ECS

At this time, we don't know how to run the CartoDB database in an Amazon RDS
instance, or if that's even possible. CartoDB requires a custom foreign
data wrapper (FWD) extension and another CartoDB extension to be installed:

* https://github.com/CartoDB/odbc_fdw
* https://github.com/CartoDB/cartodb-postgresql

It's not clear if we can use them with RDS, therefore we run our own
Postgres container which is defined by `DockerfileForCartoPostgres`.
