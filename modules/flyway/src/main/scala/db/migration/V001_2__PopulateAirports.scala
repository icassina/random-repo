package db.migration.default

import java.sql.Connection
import java.sql.JDBCType

import com.github.tototoshi.csv._

class V001_2__PopulateAirports extends CommonMigration {
  override def migrate(c: Connection) = {
    val query = c.prepareStatement("""
      SELECT (continent) FROM countries WHERE code = ?
    """)
    val stmt = c.prepareStatement("""
      INSERT INTO airports (
        id,                     --  1
        ident,                  --  2
        type,                   --  3
        name,                   --  4
        position,               --  5, 6
        elevation_ft,           --  7
        iso_country,            --  8
        iso_region,             --  9
        municipality,           -- 10
        scheduled_service,      -- 11
        gps_code,               -- 12
        iata_code,              -- 13
        local_code,             -- 14
        home_link,              -- 15
        wikipedia_link,         -- 16
        keywords                -- 17
      ) VALUES (
        ?, ?,
        ?::AirportType,
        ?,
        ST_SetSRID(ST_MakePoint(?, ?), 4326),
        ?,
        ?, ?, ?,
        ?,
        ?, ?, ?,
        ?, ?,
        to_tsvector(?)
      )
    """)

    val reader = CSVReader.open(io.Source.fromInputStream(getClass.getResourceAsStream("/data/airports.csv")))

    // NOTE: the CSVReader *withHeaders methods fail miserably for unknown reasons.
    // 0:"id", 1:"ident", 2:"type", 3:"name",
    // 4:"latitude_deg", 5:"longitude_deg", 6:"elevation_ft",
    // 7:"continent", 8:"iso_country", 9:"iso_region", 10:"municipality",
    // 11:"scheduled_service", 12:"gps_code", 13:"iata_code", 14:"local_code",
    // 15:"home_link", 16:"wikipedia_link", 17:"keywords"
    reader.all.drop(1).zipWithIndex.foreach { case (row, idx) =>
      val id = row(0).toInt
      val ident = row(1)
      val airport_type = row(2)
      val name = row(3)
      val lat = row(4).toDouble
      val lon = row(5).toDouble
      val elevation_ft = noneIfEmpty(row(6)).map(_.toInt)
      val continent = row(7)
      val country = row(8)
      val region = row(9)
      val municipality = noneIfEmpty(row(10))
      val scheduled_service = if (row(11) == "yes") true else false
      val gps_code = noneIfEmpty(row(12))
      val iata_code = noneIfEmpty(row(13))
      val local_code = noneIfEmpty(row(14))
      val home_link = noneIfEmpty(row(15))
      val wiki_link = noneIfEmpty(row(16))
      val keywords = noneIfEmpty(row(17))

      query.setString(1, country)
      val countryEntry = query.executeQuery()
      countryEntry.next()
      val foundContinent = countryEntry.getString(1)

      if (foundContinent != continent) {
        println(s"Continent mismatch: $country->$continent != $country->$foundContinent ($ident '$name')")
      }

      stmt.setInt(1, id)
      stmt.setString(2, ident)
      stmt.setString(3, airport_type)
      stmt.setString(4, name)
      stmt.setDouble(5, lon)
      stmt.setDouble(6, lat)
      stmt.setInt(7, elevation_ft)
      stmt.setString(8, country)
      stmt.setString(9, region)
      stmt.setString(10, municipality)
      stmt.setBoolean(11, scheduled_service)
      stmt.setString(12, gps_code)
      stmt.setString(13, iata_code)
      stmt.setString(14, local_code)
      stmt.setString(15, home_link)
      stmt.setString(16, wiki_link)
      stmt.setString(17, keywords)
      stmt.execute()
    }
  }
}
