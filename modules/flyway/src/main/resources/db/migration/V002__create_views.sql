
CREATE VIEW view_airports AS (
  SELECT
    a.id                    AS id,
    a.ident                 AS ident,
    a.type                  AS type,
    a.name                  AS name,
    a.position              AS position,
    a.elevation_ft          AS elevation_ft,
    c.continent             AS continent,
    a.iso_country           AS iso_country,
    c.name                  AS country_name,
    a.iso_region            AS iso_region,
    a.municipality          AS municipality,
    a.scheduled_service     AS scheduled_service,
    a.gps_code              AS gps_code,
    a.iata_code             AS iata_code,
    a.local_code            AS local_code,
    a.home_link             AS home_link,
    a.wikipedia_link        AS wikipedia_link,
    a.keywords              AS keywords
  FROM airports AS a
  INNER JOIN countries AS c ON a.iso_country = c.code
);

CREATE VIEW view_runways AS (
  SELECT
    r.id                            AS id,
    r.airport_ref                   AS airport_ref,
    a.ident                         AS airport_ident,
    c.continent                     AS continent,
    a.iso_country                   AS iso_country,
    c.name                          AS country_name,
    r.length_ft                     AS length_ft,
    r.width_ft                      AS width_ft,
    r.surface                       AS surface,
    r.surface_std                   AS surface_std,
    r.lighted                       AS lighted,
    r.closed                        AS closed,
    r.le_ident                      AS le_ident,
    r.le_position                   AS le_position,
    r.le_elevation_ft               AS le_elevation_ft,
    r.le_heading_degt               AS le_heading_degt,
    r.le_displaced_threshold_ft     AS le_displaced_threshold_ft,
    r.he_ident                      AS he_ident,
    r.he_position                   AS he_position,
    r.he_elevation_ft               AS he_elevation_ft,
    r.he_heading_degt               AS he_heading_degt,
    r.he_displaced_threshold_ft     AS he_displaced_threshold_ft
  FROM runways AS r
  INNER JOIN airports AS a ON r.airport_ref = a.id
  INNER JOIN countries AS c ON a.iso_country = c.code
);

CREATE VIEW view_airport_and_runways_count_by_country AS (
  SELECT
    a.iso_country   AS iso_country,
    a.country_name  AS country_name,
    count(a.*)      AS airports,
    count(r.*)      AS runways
  FROM view_airports AS a
  LEFT OUTER JOIN view_runways AS r ON a.id = r.airport_ref
  GROUP BY a.iso_country, a.country_name
);

CREATE VIEW view_runway_surface_by_country AS (
  SELECT
    iso_country   AS iso_country,
    country_name  AS country_name,
    surface       AS surface,
    count(*)      AS runways
  FROM view_runways
  GROUP BY iso_country, country_name, surface
  ORDER BY iso_country ASC, runways DESC, surface ASC
);

CREATE VIEW view_le_ident AS (
  SELECT
    le_ident    AS le_ident,
    count(*)    AS count
  FROM runways
  GROUP BY le_ident
  ORDER BY count DESC
);
