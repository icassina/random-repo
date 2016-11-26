package db.migration.default

import java.sql.PreparedStatement
import java.sql.JDBCType

import org.flywaydb.core.api.migration.jdbc.JdbcMigration

trait CommonMigration extends JdbcMigration {
  def noneIfEmpty(s: String) = if (s.isEmpty) None else Some(s)

  implicit class RichPreparedStatementWithOption(stmt: PreparedStatement) {
    def setString(n: Int, s: Option[String]) =
      s.map { s =>
        stmt.setString(n, s)
      }.getOrElse {
        stmt.setNull(n, JDBCType.VARCHAR.getVendorTypeNumber())
      }

    def setInt(n: Int, i: Option[Int]) =
      i.map { i =>
        stmt.setInt(n, i)
      }.getOrElse {
        stmt.setNull(n, JDBCType.INTEGER.getVendorTypeNumber())
      }

    def setDouble(n: Int, d: Option[Double]) =
      d.map { d =>
        stmt.setDouble(n, d)
      }.getOrElse {
        stmt.setNull(n, JDBCType.DOUBLE.getVendorTypeNumber())
      }

    def setPoint(n: (Int, Int), lon: Option[Double], lat: Option[Double]) =
      (for(lon <- lon; lat <- lat) yield {
          stmt.setDouble(n._1, lon)
          stmt.setDouble(n._2, lat)
      }).getOrElse {
        stmt.setNull(n._1, JDBCType.DOUBLE.getVendorTypeNumber())
        stmt.setNull(n._2, JDBCType.DOUBLE.getVendorTypeNumber())
      }
  }
}
