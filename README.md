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

### Create the tables and populate the database

Run sbt in the project's directory, with instructions to execute the database migration.

```sh
sbt "; project flyway; flywayMigrate"
```

The database is now ready for use.


Running
-------

Run sbt in the project's directory starting up the play web server:

```sh
sbt run
```

A webserver is started listening on port 9000


Usage
-----

Once the application is setup and running, point a web browser to `http://localhost:9000`

The application is composed of three pages:

* `http://localhost:9000`: index page, with just a table showing how many
  entries each table has.
* `http://localhost:9000/reports`: reports page, with four tables showing the
  reports.
* `http://localhost:9000/query`: query page, with country search box, two
  tables, a map and a log panel.

### Index page

If the database is setup correctly it should display the following information:

* Countries: 247 entries
* Airports: 46505 entries
* Runways: 39536 entries

### Reports page

There are four tables, two on the upper half of the window, two on the lower half:

* Upper half
  * Countries having most airports
  * Countries having less airports
* Lower half
  * Most common used runway surface identifiers per country
  * Most common runway indentifiers


#### Countries having most airports

The table shows a country per row, with all the country information (id, code,
name, continent, wikipedia link, keywords) and the number of airports belonging
to it.  By default the table is ordered from the country having most airports
to the one having less airports.  The table displays only the first ten
entries, as per specification.


#### Countries having less airports

Like the previous tables, but showing the last ten entries.  It is a bit
problematic as there are more than ten countries having just one airport (24 to
be precise), so the information is not complete.

#### Most common used runway surfaces identifiers per country

It shows the number of different surfaces (with count) split by country.
So, for example, the "TURF" surface (case sensitive) is seen:
* 7175 times in the United States
* 306 times in Canada
* 3 times in Australia
* 2 times in Puerto Rico
* 1 time in Germany
* 1 time in United Kingdom

Again, full country information is shown, along with the surface name and how
many runways use that identifier in that country.  By default the table is
ordered by
* the number of runways sharing the same identifier in that particular country,
* if the number is the same, using the alphabetical order of the surface identifier
* lastly, the country code

#### Most common runway identifiers

It simply shows the number of runways using a particular 'leIdent' identifier.
The table contains the 10 most popular occurrences, ordered by popularity.


### Query page

The most interactive page.

You'll notice that the bavigation bar has been augmented with a search box and
a submit button, and a misterious light blue and gray area on the right side.
The search box should be glowing blue. An indication that it is the starting
point of the interaction.

Other elements in the pages are:

* a map, on the upper-right side, centered on Europe (if you zoom in, you'll
  notice that Netherland is in the center);
* a black-ish area on the bommo-left side, showing two entries, one in green,
  the other in blue. It shows some logs;
* two empty tables labeled "Airports" and "Runways" in the upper-left and
  bottom-right corners respectively.

#### Search country

As you click on the "Search country…" box, a drop-down menu appears, with a
list of countries.  As you start typing, the list shrinks showing only the
countries matching the string the search box.  Note: it will use the name, the
code and the keywords of each country to find a match.

As the you hit enter, the first country matching the criteria is selected and
three requests are sent to the server, as shown in the logs box (here using
Netherland as example):
```
-> GET /api/country/NL
<- GET /api/country/NL
```
The client asks for full information about the country, then requests the
corresponding list of airports and runways:
```
-> GET /api/airports/NL/geojson
-> GET /api/runways/NL
<- GET /api/airports/NL/geojson
<- GET /api/airports/NL
```

It then populates the map and the two tables with airports and runways.

#### The Airports table

Once populated, the Airports table displays in the title which country the
airports belong to, in this example it shows:

`Airports in Netherlands [NL/EU]`

It also display one airport per row, with the following columns:

* Ident
* Name
* Type
* Region
* Municipality
* Elevation
* Codes (GPS, IATA, Local)

You can scroll down to look for more entries, or use the search box in the
upper right corner of the table to filter the results. Clicking on a column
header will sort the data according to that column.

#### The Runways table

Like the Airports table, it displays in the title which country the runways belong to.

The information shown by this table is:
* Airport (its Ident)
* Idents
* Surface
* Dimensions (Length and Width)
* Open (green/check is yes, red/cross is no)
* Lighted (green/check is yes, red/cross is no)
* Headings ("le" and "he", in degrees from true north)
* Elevations ("le" and "he", in feet)
* Displaced Threshold ("le" and "he", in feet)

Like the Airports table, you can scroll and search and reorder the table.


#### The Map

The map has three visible buttons on the top-left, top-right and bottom-left
corner:

* bottom-left: it shows the information about the tiles used (OpenStreetMap)
* top-left: the '+' sign will zoom in, while the '-' sign will zoom out. You
  can also use the mouse's scroll wheel.
* top-right: enabled the map in full screen. A cross sign on the top-right
  corner will bring you back to the original view.

When populated with airports and runways of a country, the map will show some
markers related to them and also change the view so that all the markers will
fit within the map.

Legend:
* Circle:
  * grey, very small: balloonport
  * blue, very small: seaplane base
  * pink, small: small airport
  * orange, medium: medium airport
  * green, large: large airport
* Plus:
  * brown, small: heliport
* Cross:
  * dark grey, very small: closed airport
  * dark blue, very small: closed runway
* Triangle:
  * blue, medium: open and not lighted runway
* Square:
  * yellow, medium: open and lighted runway


Holding the mouse's left button and moving it withing the map will move the
map.  Clicking on a marker will select it and show the full information on a
popup next to the marker.  Selecting a marker will also select it on the
relevant table (airports or runways).  Clicking anywhere on the map will remove
the popup and unselect it on the respective table.

When passing over a marker with the mouse, some information will be shown in
the upper right blue and grey rectangle, that just stopped being mysterious.
On airports, it will show and airplane and the airport name on the blue area,
and it's ident in the grey area.  On runways, it will show an upper arrow and
the runways idents (le | he) in the blue area and it's status (open | lighted)
in the grey area.

You will notice that the country search box and the information area will
appear in the fullscreen version of the map as well.

#### More interactions

##### Airports table

Clicking on a row will select that airport, instructing the Runways table to
show runways belonging to that airport (by applying the airport Ident in the
search box). The map will also have that airport selected and centered, and a
popup will show more information about the airport as if you clicked on the
airport marker.
Clicking on the selected airport will have the effect of unselect it, and
remove the popup information in the map.

#### Runways table

Likewise, clicking on a row will select the corresponding marker on the map…
except that many runways do not have any position information and are not shown
on the map. To still be able to view the full information, a temporary marker
will appear at the same position as the airport of that runway, and the popup
will appear next to it. Unselecting the runway will make the marker disappear
again.


Enjoy and profit!
-----------------


