package icassina.lunatech

import scala.concurrent.{ExecutionContext, Future}

import com.vividsolutions.jts.geom.Point
import scala.math.BigDecimal

/**
 * An implementation dependent DAO.  This could be implemented by Slick, Cassandra, or a REST API.
 */
trait DAO {
  def stats(implicit ec: DAOExecutionContext): Future[(Int, Int, Int)]
  def countries(implicit ec: DAOExecutionContext): Future[Seq[Country]]
  def airportsByCountry(countryCode: String)(implicit ec: DAOExecutionContext): Future[Option[(Country, Seq[Airport])]]
  def runwaysByCountry(countryCode: String)(implicit ec: DAOExecutionContext): Future[Option[(Country, Seq[Runway])]]
  def allAirportsByCountry(implicit ec: DAOExecutionContext): Future[Seq[(Country, Int)]]
  def topTenCountries(implicit ec: DAOExecutionContext): Future[Seq[(Country, Int)]]
  def bottomTenCountries(implicit ec: DAOExecutionContext): Future[Seq[(Country, Int)]]
  def airportsAndRunwaysByCountry(implicit ec: DAOExecutionContext): Future[Seq[(Country, Int, Int)]]
  def runwaySurfacesByCountry(implicit ec: DAOExecutionContext): Future[Seq[(Country, String, Int)]]
  def topRunwayIdents(implicit ec: DAOExecutionContext): Future[Seq[(String, Int)]]

  def close(): Future[Unit]
}

import Continents.Continent
import AirportTypes.AirportType
import Surfaces.Surface

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


/**
 * Type safe execution context for operations on AirportDAO.
 */
trait DAOExecutionContext extends ExecutionContext