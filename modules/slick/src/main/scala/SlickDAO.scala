package icassina.lunatech.slick

import javax.inject.{Inject, Singleton}

import slick.driver.JdbcProfile
import slick.jdbc.JdbcBackend.Database

import scala.concurrent.Future
import scala.language.implicitConversions

import com.vividsolutions.jts.geom.Point

import icassina.lunatech._

/**
 * A User DAO implemented with Slick, leveraging Slick code gen.
 *
 * Note that you must run "flyway/flywayMigrate" before "compile" here.
 */
@Singleton
class SlickDAO @Inject()(db: Database) extends DAO with Tables {
  override val profile: MyPostgresDriver = MyPostgresDriver
  import profile.api._

  def airportsByCountry(implicit ec: DAOExecutionContext): Future[Seq[(Country, Int)]] = {
    db.run {
      queries.countAirportsByCountry.result.map(_.map { case (c, airportsCount) =>
        (toCountry(c), airportsCount)
      })
    }
  }

  def airportsAndRunwaysByCountry(implicit ec: DAOExecutionContext): Future[Seq[(Country, Int, Int)]] = {
    db.run(queries.countAirportsAndRunwaysByCountry.result.map(_.map { case (c, airportsCount, runwaysCount) =>
      (toCountry(c), airportsCount, runwaysCount)
    }))
  }

  def runwaySurfacesByCountry(implicit ec: DAOExecutionContext): Future[Seq[(Country, String, Int)]] = {
    db.run(queries.countSurfacesByCountry.result).map(_.map { case (c, s, count) =>
      (toCountry(c), s, count)
    })
  }

  def topRunwayIdents(implicit ec: DAOExecutionContext): Future[Seq[(String, Int)]] = {
    db.run(queries.countIdents.result).map(_.take(10))
  }


  object queries {
    val runwaysWithAirport: Query[(Runways, Airports), (RunwaysRow, AirportsRow), Seq] =
      (Runways join Airports)

    val airportsWithCountry: Query[(Airports, Countries), (AirportsRow, CountriesRow), Seq] =
      (Airports join Countries)

    val runwaysWithAirportWithCountry: Query[((Runways, Airports), Countries), ((RunwaysRow, AirportsRow), CountriesRow), Seq] =
      (Runways join Airports join Countries)

    val countAirportsByCountry: Query[(Countries, Rep[Int]), (CountriesRow, Int), Seq] =
      airportsWithCountry.groupBy(_._2).map { case (c, q) =>
        (c, q.map(_._1.ident).countDistinct)
      }

    val countAirportsAndRunwaysByCountry: Query[(Countries, Rep[Int], Rep[Int]), (CountriesRow, Int, Int), Seq] =
      runwaysWithAirportWithCountry.groupBy(_._2).map { case (c, q) =>
        (c, q.map(_._1._1.id).countDistinct, q.map(_._1._2.ident).countDistinct)
      }

    val countSurfacesByCountry: Query[(Countries, Rep[String], Rep[Int]), (CountriesRow, String, Int), Seq] =
      runwaysWithAirportWithCountry.groupBy { case ((r, a), c) => (c, r.surface.getOrElse("")) }.map { case ((c, s), q) =>
        (c, s, q.map(_._1._1.id).countDistinct)
      }

    val countIdents =
      Runways.groupBy(_.leIdent.getOrElse("")).map { case (i, q) =>
        (i, q.map(_.id).countDistinct)
      }.sortBy(_._2.desc)

    object fuzzy {
      def airportsByCountryFuzzy(str: String) =
        sql"""
          SELECT
            id,
            ident,
            type,
            name,
            position,
            elevation_ft,
            iso_country,
            iso_region,
            municipality,
            scheduled_service,
            gps_code,
            iata_code,
            local_code,
            home_link,
            wikipedia_link,
            keywords
          FROM views_airports
          WHERE country_name % $str
        """.as[AirportsRow]

      def airportsByCountryCode(code: String) =
          Airports.filter(_.isoCountry === code)

      def pickFun[T](code: String)(eq: String => T, otherwise: String => T): T =
        (if (code.length == 2) eq else otherwise)(code)

      def airportsByCountry(code: String) = pickFun(code)(
        airportsByCountryCode,
        airportsByCountryFuzzy
      )

      def runwaysByCountryFuzzy(str: String) =
        sql"""
          SELECT
            id,
            airport_ref,

          FROM views_runways
          WHERE country_name % $str
        """.as[RunwaysRow]


      def runwaysByCountryCode(code: String) =
        Runways.filter(_.isoCountry === code)

      def runwaysByCountry(code: String) = pickFun(code)(
        runwaysByCountryCode,
        runwaysByCountryFuzzy
      )
    }

    val airportsByFuzzyCountry = Compiled(fuzzy.airportsByCountry)
    val runwaysByFuzzyCountry = Compiled(fuzzy.runwaysByCountry)
  }


  private def expandKeywords(kws: Option[String]): Seq[String] = kws.map(_.split(",").toSeq.map(_.trim)).getOrElse(Seq.empty)

  private def toCountry(cr: CountriesRow): Country =
    Country(cr.id, cr.code, cr.name, cr.continent, cr.wikipediaLink, expandKeywords(cr.keywords))

}


