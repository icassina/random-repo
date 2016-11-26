Lunatech assigment
==================


Requirements
------------

* Postgresql 9.5.4
* Postgis 2.2.2
* sbt


Installation
------------

### Setup database user, db and postgis extension

as postgres user (`sudo su - postgres`):
```sh
cat << EOF | psql -U postgres -d postgres
  DROP DATABASE lunatech;
  DROP USER lunatech;
  CREATE USER lunatech WITH
    INHERIT
    LOGIN
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    ENCRYPTED PASSWORD 'assignment';
  CREATE DATABASE lunatech WITH
    OWNER = "lunatech";
  ALTER ROLE lunatech SET search_path TO lunatech,public;
EOF

cat << EOF | psql -U postgres -d lunatech
  CREATE EXTENSION "postgis";
  CREATE EXTENSION "pg_trgm"; -- for fuzzy search
EOF
```
