package db.migration.default

import java.sql.Connection
import java.sql.JDBCType

import com.github.tototoshi.csv._

class V001_3__PopulateRunways extends CommonMigration {
  override def migrate(c: Connection) = {
    val queryRef = c.prepareStatement("""
      SELECT (ident) FROM airports WHERE id = ?
    """)
    val queryIdent = c.prepareStatement("""
      SELECT (id) FROM airports WHERE ident = ?
    """)
    val stmt = c.prepareStatement("""
      INSERT INTO runways (
        id,                         --  1
        airport_ref,                --  2
        length_ft,                  --  3
        width_ft,                   --  4
        surface,                    --  5
        surface_std,                --  6
        lighted,                    --  7
        closed,                     --  8
        le_ident,                   --  9
        le_position,                -- 10, 11
        le_elevation_ft,            -- 12
        le_heading_degt,            -- 13
        le_displaced_threshold_ft,  -- 14
        he_ident,                   -- 15
        he_position,                -- 16, 17
        he_elevation_ft,            -- 18
        he_heading_degt,            -- 19
        he_displaced_threshold_ft   -- 20
      ) VALUES (
        ?, ?, ?, ?,
        ?, ?::Surface,
        ?, ?,
        ?, ST_SetSRID(ST_MakePoint(?, ?), 4326), ?, ?, ?,
        ?, ST_SetSRID(ST_MakePoint(?, ?), 4326), ?, ?, ?
      )
    """)

    val reader = CSVReader.open(io.Source.fromInputStream(getClass.getResourceAsStream("/data/runways.csv")))

    // NOTE: the CSVReader *withHeaders methods fail miserably for unknown reasons.
    // 0:"id", 1:"airport_ref", 2:"airport_ident", 3:"length_ft", 4:"width_ft", 5:"surface", 6:"lighted", 7:"closed",
    // 8:"le_ident", 9:"le_latitude_deg", 10:"le_longitude_deg",
    // 11:"le_elevation_ft", 12:"le_heading_degT", 13:"le_displaced_threshold_ft",
    // 14:"he_ident", 15:"he_latitude_deg", 16:"he_longitude_deg", 17:"he_elevation_ft",
    // 18:"he_heading_degT", 19:"he_displaced_threshold_ft",
    reader.toStream.drop(1).zipWithIndex.foreach { case (row, idx) =>
      val id = row(0).toInt
      val ref = row(1).toInt
      val ident = row(2)
      val length = noneIfEmpty(row(3)).map(_.toInt)
      val width = noneIfEmpty(row(4)).map(_.toInt)
      val surface = noneIfEmpty(row(5))
      val surface_std = "U" // FIXME: standardize surface: https://en.wikipedia.org/wiki/Runway#Pavement_surface
      val lighted = if (row(6) == "0") false else true
      val closed = if (row(7) == "0") false else true
      val le_ident = noneIfEmpty(row(8))
      val le_lat = noneIfEmpty(row(9)).map(_.toDouble)
      val le_lon = noneIfEmpty(row(10)).map(_.toDouble)
      val le_elevation_ft = noneIfEmpty(row(11)).map(_.toInt)
      val le_heading_degt = noneIfEmpty(row(12)).map(_.toDouble)
      val le_displaced_thresh = noneIfEmpty(row(13)).map(_.toInt)
      val he_ident = noneIfEmpty(row(14))
      val he_lat = noneIfEmpty(row(15)).map(_.toDouble)
      val he_lon = noneIfEmpty(row(16)).map(_.toDouble)
      val he_elevation_ft = noneIfEmpty(row(17)).map(_.toInt)
      val he_heading_degt = noneIfEmpty(row(18)).map(_.toDouble)
      val he_displaced_thresh = noneIfEmpty(row(19)).map(_.toInt)

      queryRef.setInt(1, ref)
      queryIdent.setString(1, ident)
      val refEntry = queryRef.executeQuery()
      val identEntry = queryIdent.executeQuery()
      refEntry.next()
      identEntry.next()
      val foundRef = identEntry.getInt(1)
      val foundIdent = refEntry.getString(1)

      if (foundRef != ref) {
        println(s"airport ref mismatch: $foundRef != $ref (key: ident = $ident). airport = $id")
      }
      if (foundIdent != ident) {
        println(s"airport ident mismatch: $foundIdent != $ident (key: ref = $ref). airport = $id")
      }

      // id, -- 1 airport_ref, -- 2 length_ft, -- 3 width_ft, -- 4 surface, -- 5 surface_std, -- 6 lighted, -- 7 closed, -- 8
      stmt.setInt(1, id)
      stmt.setInt(2, ref)
      stmt.setInt(3, length)
      stmt.setInt(4, width)
      stmt.setString(5, surface)
      stmt.setString(6, surface_std) // FIXME
      stmt.setBoolean(7, lighted)
      stmt.setBoolean(8, closed)
      // le_ident, -- 9 le_position, -- 10, 11 le_elevation_ft, -- 12 le_heading_degt, -- 13 le_displaced_threshold_ft, -- 14
      stmt.setString(9, le_ident)
      stmt.setPoint((10, 11), le_lon, le_lat)
      stmt.setInt(12, le_elevation_ft)
      stmt.setDouble(13, le_heading_degt)
      stmt.setInt(14, le_displaced_thresh)
      // he_ident, -- 15 he_position, -- 16, 17 he_elevation_ft, -- 18 he_heading_degt, -- 19 he_displaced_threshold_ft -- 20
      stmt.setString(15, he_ident)
      stmt.setPoint((16, 17), he_lon, he_lat)
      stmt.setInt(18, he_elevation_ft)
      stmt.setDouble(19, he_heading_degt)
      stmt.setInt(20, he_displaced_thresh)
      stmt.execute()

    }
  }
}
