package icassina.lunatech

import scala.concurrent.{ExecutionContext, Future}

import com.vividsolutions.jts.geom.Point

/**
 * An implementation dependent DAO.  This could be implemented by Slick, Cassandra, or a REST API.
 */
trait DAO {
  def lookupAirportsByCountry(query: String)(implicit ec: DAOExecutionContext): Future[Seq[Airport]]
  def lookupRunwaysByCountry(query: String)(implicit ec: DAOExecutionContext): Future[Seq[Runway]]
  def airportsByCountry(implicit ec: DAOExecutionContext): Future[Seq[(Country, Int)]]
  def airportsAndRunwaysByCountry(implicit ec: DAOExecutionContext): Future[Seq[(Country, Int, Int)]]
  def runwaySurfacesByCountry(implicit ec: DAOExecutionContext): Future[Seq[(Country, String, Int)]]
  def topRunwayIdents(implicit ec: DAOExecutionContext): Future[Seq[(String, Int)]]
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
  keywords:       Seq[String]
)

case class Airport(
  id:               Int,
  ident:            String,
  airportType:      AirportType,
  name:             String,
  position:         Point,
  elevation:        Option[Int],
  country:          Country,
  isoRegion:        String,
  municipality:     Option[String],
  scheduledService: Boolean,
  gpsCode:          Option[String],
  iataCode:         Option[String],
  localCode:        Option[String],
  homeLink:         Option[String],
  wikipediaLink:    Option[String],
  keywords:         Seq[String]
)

case class Runway(
  id:                     Int,
  airport:                Airport,
  length_ft:              Option[Int],
  surface:                Option[String],
  surfaceStd:             Surface,
  lighted:                Boolean,
  closed:                 Boolean,
  leIdent:                Option[String],
  lePosition:             Option[Point],
  leElevationFt:          Option[Int],
  leHeadingDegT:          Option[Double],
  leDisplacedThresholdFt: Option[Int],
  heIdent:                Option[String],
  hePosition:             Option[Point],
  heElevationFt:          Option[Int],
  heHeadingDegT:          Option[Double],
  heDisplacedThresholdFt: Option[Int]
)


/**
 * Type safe execution context for operations on AirportDAO.
 */
trait DAOExecutionContext extends ExecutionContext
