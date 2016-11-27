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

  def stats(implicit ec: DAOExecutionContext): Future[(Int, Int, Int)] =
    db.run(queries.stats.result)

  def airportsByCountry(implicit ec: DAOExecutionContext): Future[Seq[(Country, Int)]] =
    db.run(queries.countAirportsByCountry.result)

  def topTenCountries(implicit ec: DAOExecutionContext): Future[Seq[(Country, Int)]] =
    db.run(queries.countAirportsByCountry.sortBy(_._2.desc).take(10).result)

  def bottomTenCountries(implicit ec: DAOExecutionContext): Future[Seq[(Country, Int)]] =
    db.run(queries.countAirportsByCountry.sortBy(_._2.asc).take(10).result)

  def airportsAndRunwaysByCountry(implicit ec: DAOExecutionContext): Future[Seq[(Country, Int, Int)]] =
    db.run(queries.countAirportsAndRunwaysByCountry.result)

  def runwaySurfacesByCountry(implicit ec: DAOExecutionContext): Future[Seq[(Country, String, Int)]] =
    db.run(queries.countSurfacesByCountry.result)

  def topRunwayIdents(implicit ec: DAOExecutionContext): Future[Seq[(String, Int)]] =
    db.run(queries.countIdents.result).map(_.take(10))

  def lookupAirportsByCountry(countryStr: String)(implicit ec: DAOExecutionContext): Future[Either[Seq[Country], (Country, Seq[Airport])]] =
    db.run(queries.countryOrAirports(countryStr))

  def lookupRunwaysByCountry(countryStr: String)(implicit ec: DAOExecutionContext): Future[Either[Seq[Country], (Country, Seq[Runway])]] =
    db.run(queries.countryOrRunways(countryStr))

  def close() = Future.successful(db.close())


  object queries {
    val stats = (
      Countries.map(_.id).length,
      Airports.map(_.id).length,
      Runways.map(_.id).length
    )

    val runwaysWithAirport: Query[(Runways, Airports), (Runway, Airport), Seq] =
      (Runways join Airports on (_.airportRef === _.id))

    val airportsWithCountry: Query[(Airports, Countries), (Airport, Country), Seq] =
      (Airports join Countries on (_.isoCountry === _.code))

    val runwaysWithAirportWithCountry: Query[((Runways, Airports), Countries), ((Runway, Airport), Country), Seq] =
      (runwaysWithAirport join Countries on (_._2.isoCountry === _.code))

    val countAirportsByCountry: Query[(Countries, Rep[Int]), (Country, Int), Seq] =
      airportsWithCountry.groupBy(_._2).map { case (c, q) =>
        (c, q.map(_._1.ident).length)
      }

    val countAirportsAndRunwaysByCountry: Query[(Countries, Rep[Int], Rep[Int]), (Country, Int, Int), Seq] =
      runwaysWithAirportWithCountry.groupBy(_._2).map { case (c, q) =>
        (c, q.map(_._1._1.id).length, q.map(_._1._2.ident).length)
      }

    val countSurfacesByCountry: Query[(Countries, Rep[String], Rep[Int]), (Country, String, Int), Seq] =
      runwaysWithAirportWithCountry.groupBy { case ((r, a), c) => (c, r.surface.getOrElse("")) }.map { case ((c, s), q) =>
        (c, s, q.map(_._1._1.id).length)
      }.sortBy(_._3.desc)

    val countIdents =
      Runways.groupBy(_.leIdent.getOrElse("")).map { case (i, q) =>
        (i, q.map(_.id).length)
      }.sortBy(_._2.desc)

    def airportsByCountryCode(code: LiteralColumn[String]) =
        Airports.filter(_.isoCountry === code)

    def runwaysByCountryCode(code: LiteralColumn[String]) =
      for {
        r <- Runways
        a <- r.airport
        if a.isoCountry === code
      } yield r


    object fuzzy {
      def airportsByCountryFuzzy(str: String) = {
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
          ORDER BY name, position ASC
        """.as[Airport]
      }

      def runwaysByCountryFuzzy(str: String) = {
        sql"""
          SELECT
            id,
            airport_ref,
            length_ft,
            width_ft,
            surface,
            surface_std,
            lighted,
            closed,
            le_ident,
            le_position,
            le_elevation_ft,
            le_heading_degt,
            le_displaced_threshold_ft,
            he_ident,
            he_position,
            he_elevation_ft,
            he_heading_degt,
            he_displaced_threshold_ft
          FROM views_runways
          WHERE country_name % $str
          ORDER BY airport_ident, le_ident
        """.as[Runway]
      }
    }

    def countries(str: String) = {
      sql"""
        SELECT * FROM countries WHERE country_name % $str
      """.as[Country]
    }

    def countryOrSeq[R, T](s: String)(f: (Country) => Query[R, T, Seq])(
      implicit ec: DAOExecutionContext
    ): DBIO[Either[Seq[Country], (Country, Seq[T])]] =
      if (s.length < 2) {
        println("less than 2")
        DBIO.successful(Left(Seq.empty))
      } else if (s.length == 2) {
        println("exactly 2")
        Countries.filter(_.code === s.toUpperCase).take(1).result.headOption.flatMap(_.map { country =>
          f(country).result.map(as => {
            Right(country -> as)
          })
        }.getOrElse(DBIO.successful(Left(Seq.empty))))
      } else {
        println("more than 2")
        countries(s).flatMap { cs =>
          if (cs.length > 1) {
            DBIO.successful(Left(cs))
          } else {
            cs.headOption.map { country =>
              f(country).result.map(res => Right((country -> res)))
            }.getOrElse {
              Countries.take(0).result.map(Left.apply)
            }
          }
        }
      }

    def countryOrAirports(s: String)(implicit ec: DAOExecutionContext): DBIO[Either[Seq[Country], (Country, Seq[Airport])]] =
      countryOrSeq(s)(c => Airports.filter(_.isoCountry === c.code))

    def countryOrRunways(s: String)(implicit ec: DAOExecutionContext): DBIO[Either[Seq[Country], (Country, Seq[Runway])]] =
      countryOrSeq(s)(c => runwaysWithAirport.filter(_._2.isoCountry === c.code).map(_._1))
  }


  private def pickFun[T](countryStr: String)(eq: LiteralColumn[String] => T, otherwise: String => T): T =
    if (countryStr.value.length == 2) eq(new LiteralColumn(countryStr)) else otherwise(countryStr)

  //private def expandKeywords(kws: Option[String]): Seq[String] = kws.map(_.split(",").toSeq.map(_.trim)).getOrElse(Seq.empty)
}

