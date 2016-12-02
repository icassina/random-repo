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

  def stats(implicit ec: DAOExecutionContext): Future[Stats] =
    db.run(queries.stats.result.map(Stats.tupled))

  def country(countryCode: String)(implicit ec: DAOExecutionContext): Future[Option[Country]] =
    db.run(Countries.filter(_.code === countryCode).result.headOption)

  def countryFuzzy(str: String)(implicit ec: DAOExecutionContext): Future[Option[Country]] =
    db.run(queries.countryFuzzy(str).headOption)

  def countries(implicit ec: DAOExecutionContext): Future[Seq[CountryDef]] =
    db.run(Countries.result.map(_.map(c => CountryDef(c.code, c.name, c.keywords))))

  def airportsByCountry(countryCode: String)(implicit ec: DAOExecutionContext): Future[Option[AirportsByCountry]] =
    db.run {
      Countries.filter(_.code === countryCode).result.headOption.flatMap { countryOpt =>
        countryOpt.map { country =>
          Airports.filter(_.isoCountry === country.code).result.map(airports => country -> airports)
        }.fold[DBIOAction[Option[AirportsByCountry], NoStream, Effect.Read]](DBIO.successful(None)) { dbio =>
          dbio.map { case (country, airports) =>
            Some(AirportsByCountry(country, airports))
          }
        } // ugliness due to https://github.com/slick/slick/issues/1192 (DBIO.sequence not working on Option monad)
      }
    }

  def runwaysByCountry(countryCode: String)(implicit ec: DAOExecutionContext): Future[Option[RunwaysByCountry]] =
    db.run {
      Countries.filter(_.code === countryCode).result.headOption.flatMap { countryOpt =>
        countryOpt.map { country =>
          val runways = (
            for {
              runway <- Runways
              airport <- runway.airport
              if airport.isoCountry === country.code
            } yield (runway, airport)
          )
          runways.result.map(runways =>
            country -> runways.map { case (runway, airport) =>
              RunwayWithAirportIdent(runway, airport.ident)
            }
          )
        }.fold[DBIOAction[Option[RunwaysByCountry], NoStream, Effect.Read]](DBIO.successful(None)) { dbio =>
          dbio.map { case (country, runways) =>
            Some(RunwaysByCountry(country, runways))
          }
        } // ugliness due to https://github.com/slick/slick/issues/1192 (DBIO.sequence not working on Option monad)
      }
    }

  def allAirportsByCountry(implicit ec: DAOExecutionContext): Future[Seq[AirportsCountByCountry]] =
    db.run(queries.countAirportsByCountry.result.map(_.map(AirportsCountByCountry.tupled)))

  def topTenCountries(implicit ec: DAOExecutionContext): Future[Seq[AirportsCountByCountry]] =
    db.run(queries.countAirportsByCountry.sortBy(_._2.desc).take(10).result.map(_.map(AirportsCountByCountry.tupled)))

  def lowTenCountries(implicit ec: DAOExecutionContext): Future[Seq[AirportsCountByCountry]] =
    db.run(queries.countAirportsByCountry.sortBy(_._2.asc).take(10).result.map(_.map(AirportsCountByCountry.tupled)))

  def airportsAndRunwaysByCountry(implicit ec: DAOExecutionContext): Future[Seq[AirportsAndRunwaysCountByCountry]] =
    db.run(queries.countAirportsAndRunwaysByCountry.result.map(_.map(AirportsAndRunwaysCountByCountry.tupled)))

  def runwaySurfacesByCountry(implicit ec: DAOExecutionContext): Future[Seq[RunwaySurfacesCountByCountry]] =
    db.run(queries.countSurfacesByCountry.result.map(_.map(RunwaySurfacesCountByCountry.tupled)))

  // it makes more sense to count le_ident + he_ident pairs, a runway has generally two ways.
  def topRunwayIdents(implicit ec: DAOExecutionContext): Future[Seq[RunwayIdentsCount]] =
    db.run(queries.countIdents2.map(_.map(RunwayIdentsCount.tupled)))

  def topRunwayIdentsSingle(implicit ec: DAOExecutionContext): Future[Seq[RunwayIdentsCount]] =
    db.run(queries.countIdents.take(10).result.map(_.map(RunwayIdentsCount.tupled)))

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

    val countIdents2 =
      sql"""
        SELECT
          (coalesce(le_ident, '') || '/' || coalesce(he_ident, '')) AS ident,
          count(1) AS runways
        FROM runways
        GROUP BY (coalesce(le_ident, '') || '/' || coalesce(he_ident, ''))
        ORDER BY runways DESC
        LIMIT 10
      """.as[(String, Int)]

    // Not actually used, as it is handled in the client. This could be much more powerful.
    def countryFuzzy(str: String) = {
      val query = str.split(" ").mkString(" & ")
      sql"""
        SELECT * FROM countries WHERE code % $str OR name % $str OR keywords @@ to_tsquery($query) ORDER BY name <-> $str LIMIT 1
      """.as[Country]
    }
  }
}

