package db.migration.default

import java.sql.Connection

import com.github.tototoshi.csv._

class V001_1__PopulateCountries extends CommonMigration {

  override def migrate(c: Connection) = {
    val stmt = c.prepareStatement("""
      INSERT INTO countries
        (id, code, name, continent, wikipedia_link, keywords)
      VALUES
        (?, ?, ?, ?::Continent, ?, to_tsvector(?))
    """)

    val reader = CSVReader.open(io.Source.fromInputStream(getClass.getResourceAsStream("/data/countries.csv")))

    // NOTE: the CSVReader *withHeaders methods fail miserably for unknown reasons.
    // 0:"id", 1:"code", 2:"name", 3:"continent", 4:"wikipedia_link", 5:"keywords"
    reader.all.drop(1).zipWithIndex.foreach { case (row, idx) =>
      val id = row(0).toInt
      val code = row(1)
      val name = row(2)
      val continent = row(3)
      val wiki_link = noneIfEmpty(row(4))
      val keywords = noneIfEmpty(row(5))

      stmt.setInt(1, id)
      stmt.setString(2, code)
      stmt.setString(3, name)
      stmt.setString(4, continent)
      stmt.setString(5, wiki_link)
      stmt.setString(6, keywords)
      stmt.execute()
    }
  }
}
