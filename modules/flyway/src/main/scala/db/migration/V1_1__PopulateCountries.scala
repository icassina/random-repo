package db.migration.default

import org.flywaydb.core.api.migration.jdbc.JdbcMigration
import java.sql.Connection

import com.github.tototoshi.csv._

class V1_1__PopulateCountries extends JdbcMigration {
  override def migrate(c: Connection) = {
    val stmt = c.preparedStatement("""
      INSERT INTO countries
        (id, code, name, continent, wikipedia_link)
      VALUES
        (?, ?, ?::Continent, ?)
    """)

    val reader = CSVReader.open(getClass.getResource("/countries.csv"))
  }
}
