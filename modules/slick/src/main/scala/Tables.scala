package icassina.lunatech.slick

object Tables extends {
  val profile = icassina.lunatech.slick.MyPostgresDriver
} with Tables

/** Slick data model trait for extension, choice of backend or usage in the cake pattern. (Make sure to initialize this late.) */
trait Tables {
  val profile: icassina.lunatech.slick.MyPostgresDriver

  import profile.api._
  import profile.plainAPI.PostGISPositionedResult
  import profile.plainAPI.getGeometry
  import profile.plainAPI.getGeometryOption

  import slick.model.ForeignKeyAction
  import slick.jdbc.{GetResult => GR}

  import scala.math.BigDecimal
  import com.vividsolutions.jts.geom.Geometry
  import com.vividsolutions.jts.geom.Point

  import icassina.lunatech._
  import Continents.Continent
  import AirportTypes.AirportType
  import Surfaces.Surface

  /** DDL for all tables. Call .create to execute. */
  def schema: profile.SchemaDescription = Airports.schema ++ Countries.schema ++ Runways.schema
  def ddl = schema

  implicit def GetResultCountry(implicit e0: GR[Int], e1: GR[String], e2: GR[Option[String]]): GR[Country] = GR{
    prs => import prs._
    Country.tupled((<<[Int], <<[String], <<[String], <<[Continent], <<[String], <<?[String]))
  }
  class Countries(_tableTag: Tag) extends Table[Country](_tableTag, Some("lunatech"), "countries") {
    val id:             Rep[Int]            = column[Int]           ("id",              O.PrimaryKey)
    val code:           Rep[String]         = column[String]        ("code",            O.Length(2,varying=false))
    val name:           Rep[String]         = column[String]        ("name",            O.Length(64,varying=true))
    val continent:      Rep[Continent]      = column[Continent]     ("continent")
    val wikipediaLink:  Rep[String]         = column[String]        ("wikipedia_link",  O.Length(128,varying=true))
    val keywords:       Rep[Option[String]] = column[Option[String]]("keywords",        O.Length(2147483647,varying=false), O.Default(None))

    def * = (id, code, name, continent, wikipediaLink, keywords) <> (Country.tupled, Country.unapply)

    val index1 = index("countries_code_key", code, unique=true)
    val index2 = index("countries_continent_idx", continent)
    val index3 = index("countries_keywords_idx", keywords)
    val index4 = index("countries_name_key", name, unique=true)
  }
  lazy val Countries = new TableQuery(tag => new Countries(tag))

  import icassina.lunatech.Airport
  implicit def GetResultAirport(implicit e0: GR[Int], e1: GR[String], e2: GR[Option[Int]], e3: GR[Option[String]], e4: GR[Boolean]): GR[Airport] = GR {
    prs => import prs._
    Airport.tupled((<<[Int], <<[String], <<[AirportType], <<[String], prs.nextGeometry[Point], <<?[Int], <<[String], <<[String], <<?[String], <<[Boolean], <<?[String], <<?[String], <<?[String], <<?[String], <<?[String], <<?[String]))
  }

  class Airports(_tableTag: Tag) extends Table[Airport](_tableTag, Some("lunatech"), "airports") {
    val id:               Rep[Int]            = column[Int]             ("id",                O.PrimaryKey)
    val ident:            Rep[String]         = column[String]          ("ident",             O.Length(8,varying=true))
    val airportType:      Rep[AirportType]    = column[AirportType]     ("type")
    val name:             Rep[String]         = column[String]          ("name",              O.Length(128,varying=true))
    val position:         Rep[Point]          = column[Point]           ("position",          O.Length(2147483647,varying=false))
    val elevation:        Rep[Option[Int]]    = column[Option[Int]]     ("elevation_ft",      O.Default(None))
    val isoCountry:       Rep[String]         = column[String]          ("iso_country",       O.Length(2,varying=false))
    val isoRegion:        Rep[String]         = column[String]          ("iso_region",        O.Length(8,varying=true))
    val municipality:     Rep[Option[String]] = column[Option[String]]  ("municipality",      O.Length(64,varying=true), O.Default(None))
    val scheduledService: Rep[Boolean]        = column[Boolean]         ("scheduled_service")
    val gpsCode:          Rep[Option[String]] = column[Option[String]]  ("gps_code",          O.Length(4,varying=true), O.Default(None))
    val iataCode:         Rep[Option[String]] = column[Option[String]]  ("iata_code",         O.Length(4,varying=true), O.Default(None))
    val localCode:        Rep[Option[String]] = column[Option[String]]  ("local_code",        O.Length(4,varying=true), O.Default(None))
    val homeLink:         Rep[Option[String]] = column[Option[String]]  ("home_link",         O.Length(128,varying=true), O.Default(None))
    val wikipediaLink:    Rep[Option[String]] = column[Option[String]]  ("wikipedia_link",    O.Length(128,varying=true), O.Default(None))
    val keywords:         Rep[Option[String]] = column[Option[String]]  ("keywords",          O.Length(2147483647,varying=false), O.Default(None))

    lazy val country = foreignKey("airports_iso_country_fkey", isoCountry, Countries)(r => r.code, onUpdate=ForeignKeyAction.NoAction, onDelete=ForeignKeyAction.NoAction)

    def * = (id, ident, airportType, name, position, elevation, isoCountry, isoRegion, municipality, scheduledService, gpsCode, iataCode, localCode, homeLink, wikipediaLink, keywords) <> (Airport.tupled, Airport.unapply)

    val index1 = index("airports_ident_key", ident, unique=true)
    val index2 = index("airports_keywords_idx", keywords)
  }
  lazy val Airports = new TableQuery(tag => new Airports(tag))

  implicit def GetResultRunway(implicit e0: GR[Int], e1: GR[Option[Int]], e2: GR[Option[String]], e3: GR[String], e4: GR[Boolean], e5: GR[Option[BigDecimal]]): GR[Runway] = GR{
    prs => import prs._
    Runway.tupled((
      <<[Int], <<[Int], <<?[Int], <<?[Int], <<?[String], <<[Surface], <<[Boolean], <<[Boolean],
      <<?[String], prs.nextGeometryOption[Point], <<?[Int], <<?[BigDecimal], <<?[Int],
      <<?[String], prs.nextGeometryOption[Point], <<?[Int], <<?[BigDecimal], <<?[Int]
    ))
  }
  class Runways(_tableTag: Tag) extends Table[Runway](_tableTag, Some("lunatech"), "runways") {
    val id:                   Rep[Int]                = column[Int]               ("id",                        O.PrimaryKey)
    val airportRef:           Rep[Int]                = column[Int]               ("airport_ref")
    val length:               Rep[Option[Int]]        = column[Option[Int]]       ("length_ft",                 O.Default(None))
    val width:                Rep[Option[Int]]        = column[Option[Int]]       ("width_ft",                  O.Default(None))
    val surface:              Rep[Option[String]]     = column[Option[String]]    ("surface",                   O.Length(64,varying=true), O.Default(None))
    val surfaceStd:           Rep[Surface]            = column[Surface]           ("surface_std")
    val lighted:              Rep[Boolean]            = column[Boolean]           ("lighted")
    val closed:               Rep[Boolean]            = column[Boolean]           ("closed")
    val leIdent:              Rep[Option[String]]     = column[Option[String]]    ("le_ident",                  O.Length(8,varying=true), O.Default(None))
    val lePosition:           Rep[Option[Point]]      = column[Option[Point]]     ("le_position",               O.Length(2147483647,varying=false), O.Default(None))
    val leElevation:          Rep[Option[Int]]        = column[Option[Int]]       ("le_elevation_ft",           O.Default(None))
    val leHeading:            Rep[Option[BigDecimal]] = column[Option[BigDecimal]]("le_heading_degt",           O.Default(None))
    val leDisplacedThreshold: Rep[Option[Int]]        = column[Option[Int]]       ("le_displaced_threshold_ft", O.Default(None))
    val heIdent:              Rep[Option[String]]     = column[Option[String]]    ("he_ident",                  O.Length(8,varying=true), O.Default(None))
    val hePosition:           Rep[Option[Point]]      = column[Option[Point]]     ("he_position",               O.Length(2147483647,varying=false), O.Default(None))
    val heElevation:          Rep[Option[Int]]        = column[Option[Int]]       ("he_elevation_ft",           O.Default(None))
    val heHeading:            Rep[Option[BigDecimal]] = column[Option[BigDecimal]]("he_heading_degt",           O.Default(None))
    val heDisplacedThreshold: Rep[Option[Int]]        = column[Option[Int]]       ("he_displaced_threshold_ft", O.Default(None))

    lazy val airport = foreignKey("runways_airport_ref_fkey", airportRef, Airports)(r => r.id, onUpdate=ForeignKeyAction.NoAction, onDelete=ForeignKeyAction.NoAction)

    def * = (id, airportRef, length, width, surface, surfaceStd, lighted, closed, leIdent, lePosition, leElevation, leHeading, leDisplacedThreshold, heIdent, hePosition, heElevation, heHeading, heDisplacedThreshold) <> (Runway.tupled, Runway.unapply)

    val index1 = index("runways_le_ident_idx", leIdent)
    val index2 = index("runways_surface_idx", surface)
    val index3 = index("runways_surface_std_idx", surfaceStd)
  }
  lazy val Runways = new TableQuery(tag => new Runways(tag))
}
