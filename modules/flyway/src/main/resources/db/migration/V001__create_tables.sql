

CREATE TYPE AirportType AS ENUM (
  'balloonport',
  'closed',
  'heliport',
  'large_airport',
  'medium_airport',
  'seaplane_base',
  'small_airport'
);

CREATE TYPE Continent AS ENUM (
  'AF',
  'AN',
  'AS',
  'EU',
  'NA',
  'OC',
  'SA'
);

-- from https://en.wikipedia.org/wiki/Runway#Pavement_surface
CREATE TYPE Surface AS ENUM (
  'ASP',
  'BIT',
  'BRI',
  'CLA',
  'COM',
  'CON',
  'COP',
  'COR',
  'GRE',
  'GRS',
  'GVL',
  'ICE',
  'LAT',
  'MAC',
  'PEM',
  'PER',
  'PSP',
  'SAN',
  'SMT',
  'SNO',
  'U'
);

CREATE TABLE countries (
  id                INTEGER       NOT NULL,
  code              CHAR(2)       NOT NULL,
  name              VARCHAR(64)   NOT NULL,
  continent         Continent     NOT NULL,
  wikipedia_link    VARCHAR(128)  NOT NULL,
  keywords          tsvector,

  PRIMARY KEY (id),
  UNIQUE (code),
  UNIQUE (name)
);
CREATE INDEX countries_continent_idx ON countries (continent);
CREATE INDEX countries_keywords_idx ON countries USING gist(keywords);

CREATE TABLE airports (
  id                INTEGER       NOT NULL,
  ident             VARCHAR(8)    NOT NULL,
  type              AirportType   NOT NULL,
  name              VARCHAR(128)  NOT NULL,
  elevation_ft      INTEGER,
  iso_country       CHAR(2)       NOT NULL,
  iso_region        VARCHAR(8)    NOT NULL,
  municipality      VARCHAR(64),
  scheduled_service BOOLEAN       NOT NULL,
  gps_code          VARCHAR(4),
  iata_code         VARCHAR(4),
  local_code        VARCHAR(4),
  home_link         VARCHAR(128),
  wikipedia_link    VARCHAR(128),
  keywords          tsvector,


  PRIMARY KEY (id),
  FOREIGN KEY (iso_country) REFERENCES countries (code),
  UNIQUE (ident)
);
SELECT AddGeometryColumn('lunatech', 'airports', 'position', 4326, 'POINT', 2);
ALTER TABLE airports ALTER COLUMN position SET NOT NULL;
CREATE INDEX airports_iso_country_idx ON airports (iso_country);
CREATE INDEX airports_keywords_idx ON airports USING gist(keywords);

CREATE TABLE runways (
  id                        INTEGER       NOT NULL,
  airport_ref               INTEGER       NOT NULL,
  length_ft                 INTEGER,
  width_ft                  INTEGER,
  surface                   VARCHAR(64),
  surface_std               Surface       NOT NULL DEFAULT 'U'::Surface,
  lighted                   BOOLEAN       NOT NULL,
  closed                    BOOLEAN       NOT NULL,
  le_ident                  VARCHAR(8),
  le_elevation_ft           INTEGER,
  le_heading_degt           NUMERIC(8, 1),
  le_displaced_threshold_ft INTEGER,
  he_ident                  VARCHAR(8),
  he_elevation_ft           INTEGER,
  he_heading_degt           NUMERIC(8, 1),
  he_displaced_threshold_ft INTEGER,

  PRIMARY KEY (id),
  FOREIGN KEY (airport_ref) REFERENCES airports (id)
);
SELECT AddGeometryColumn('lunatech', 'runways', 'le_position', 4326, 'POINT', 2);
SELECT AddGeometryColumn('lunatech', 'runways', 'he_position', 4326, 'POINT', 2);
CREATE INDEX runways_surface_idx ON runways (surface);
CREATE INDEX runways_surface_std_idx ON runways (surface_std);
CREATE INDEX runways_le_ident_idx ON runways (le_ident);
