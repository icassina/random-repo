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

  def countries(implicit ec: DAOExecutionContext): Future[Seq[Country]] =
    db.run(Countries.result)

  def airportsByCountry(countryCode: String)(implicit ec: DAOExecutionContext): Future[Option[(Country, Seq[Airport])]] =
    db.run {
      Countries.filter(_.code === countryCode).result.headOption.flatMap { countryOpt =>
        countryOpt.map { country =>
          Airports.filter(_.isoCountry === country.code).result.map(airports => country -> airports)
        }.fold[DBIOAction[Option[(Country, Seq[Airport])], NoStream, Effect.Read]](DBIO.successful(None)) { dbio =>
          dbio.map { case (country, airports) =>
            Some(country -> airports)
          }
        } // ugliness due to https://github.com/slick/slick/issues/1192 (DBIO.sequence not working on Option monad)
      }
    }

  def runwaysByCountry(countryCode: String)(implicit ec: DAOExecutionContext): Future[Option[(Country, Seq[Runway])]] =
    db.run {
      Countries.filter(_.code === countryCode).result.headOption.flatMap { countryOpt =>
        countryOpt.map { country =>
          val runways = (
            for {
              runway <- Runways
              airport <- runway.airport
              if airport.isoCountry === country.code
            } yield runway
          )
          runways.result.map(runways => country -> runways)
        }.fold[DBIOAction[Option[(Country, Seq[Runway])], NoStream, Effect.Read]](DBIO.successful(None)) { dbio =>
          dbio.map { case (country, runways) =>
            Some(country -> runways)
          }
        } // ugliness due to https://github.com/slick/slick/issues/1192 (DBIO.sequence not working on Option monad)
      }
    }

  def allAirportsByCountry(implicit ec: DAOExecutionContext): Future[Seq[(Country, Int)]] =
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

    def countries(str: String) = {
      sql"""
        SELECT * FROM countries WHERE country_name % $str
      """.as[Country]
    }
  }


  private def pickFun[T](countryStr: String)(eq: LiteralColumn[String] => T, otherwise: String => T): T =
    if (countryStr.value.length == 2) eq(new LiteralColumn(countryStr)) else otherwise(countryStr)

  //private def expandKeywords(kws: Option[String]): Seq[String] = kws.map(_.split(",").toSeq.map(_.trim)).getOrElse(Seq.empty)
}
