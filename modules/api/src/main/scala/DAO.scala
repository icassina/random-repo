package icassina.lunatech

import scala.concurrent.{ExecutionContext, Future}

import com.vividsolutions.jts.geom.Point
import scala.math.BigDecimal

/**
 * An implementation dependent DAO.  This could be implemented by Slick, Cassandra, or a REST API.
 */
trait DAO {
  def stats(implicit ec: DAOExecutionContext): Future[Stats]
  def country(countryCode: String)(implicit ec: DAOExecutionContext): Future[Option[Country]]
  def countries(implicit ec: DAOExecutionContext): Future[Seq[Country]]
  def airportsByCountry(countryCode: String)(implicit ec: DAOExecutionContext): Future[Option[AirportsByCountry]]
  def runwaysByCountry(countryCode: String)(implicit ec: DAOExecutionContext): Future[Option[RunwaysByCountry]]
  def allAirportsByCountry(implicit ec: DAOExecutionContext): Future[Seq[AirportsCountByCountry]]
  def topTenCountries(implicit ec: DAOExecutionContext): Future[Seq[AirportsCountByCountry]]
  def bottomTenCountries(implicit ec: DAOExecutionContext): Future[Seq[AirportsCountByCountry]]
  def airportsAndRunwaysByCountry(implicit ec: DAOExecutionContext): Future[Seq[AirportsAndRunwaysCountByCountry]]
  def runwaySurfacesByCountry(implicit ec: DAOExecutionContext): Future[Seq[RunwaySurfacesCountByCountry]]
  def topRunwayIdents(implicit ec: DAOExecutionContext): Future[Seq[RunwayIdentsCount]]

  def close(): Future[Unit]
}

import Continents.Continent
import AirportTypes.AirportType
import Surfaces.Surface


case class Stats(
  countries: Int,
  airports: Int,
  runways: Int
)

case class AirportsByCountry(
  country: Country,
  airports: Seq[Airport]
)

case class RunwaysByCountry(
  country: Country,
  runways: Seq[RunwayWithAirportIdent]
)

case class AirportsCountByCountry(
  country: Country,
  airports: Int
)

case class AirportsAndRunwaysCountByCountry(
  country: Country,
  airports: Int,
  runways: Int
)

case class RunwaySurfacesCountByCountry(
  country: Country,
  surface: String,
  runways: Int
)

case class RunwayIdentsCount(
  ident: String,
  runways: Int
)

case class Country(
  id:             Int,
  code:           String,
  name:           String,
  continent:      Continent,
  wikipediaLink:  String,
  keywords:       Option[String]
)

case class Airport(
  id:               Int,
  ident:            String,
  airportType:      AirportType,
  name:             String,
  position:         Point,
  elevation:        Option[Int],
  isoCountry:       String,
  isoRegion:        String,
  municipality:     Option[String],
  scheduledService: Boolean,
  gpsCode:          Option[String],
  iataCode:         Option[String],
  localCode:        Option[String],
  homeLink:         Option[String],
  wikipediaLink:    Option[String],
  keywords:         Option[String]
)

case class Runway(
  id:                   Int,
  airportRef:           Int,
  length:               Option[Int],
  width:                Option[Int],
  surface:              Option[String],
  surfaceStd:           Surface,
  lighted:              Boolean,
  closed:               Boolean,
  leIdent:              Option[String],
  lePosition:           Option[Point],
  leElevation:          Option[Int],
  leHeading:            Option[BigDecimal],
  leDisplacedThreshold: Option[Int],
  heIdent:              Option[String],
  hePosition:           Option[Point],
  heElevation:          Option[Int],
  heHeading:            Option[BigDecimal],
  heDisplacedThreshold: Option[Int]
)

case class RunwayWithAirportIdent(
  runway: Runway,
  airportIdent: String
)


/**
 * Type safe execution context for operations on AirportDAO.
 */
trait DAOExecutionContext extends ExecutionContext
