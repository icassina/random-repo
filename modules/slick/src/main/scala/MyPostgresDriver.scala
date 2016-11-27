package icassina.lunatech.slick

import com.github.tminglei.slickpg._

/**
 * A postgresql driver with extended Joda and JSON support.
 */
trait MyPostgresDriver extends ExPostgresDriver
  with PgPostGISSupport
  with PgEnumSupport
{
  override val api = new MyAPI {}

  trait MyAPI extends API with PostGISImplicits with PostGISAssistants with MyEnumImplicits

  val plainAPI = new API with PostGISPlainImplicits

  trait MyEnumImplicits {
    import slick.jdbc.GetResult
    import icassina.lunatech.Continents
    import icassina.lunatech.AirportTypes
    import icassina.lunatech.Surfaces

    implicit val continentMapper = createEnumJdbcType("Continent", Continents)
    implicit val contintentListTypeMapper = createEnumListJdbcType("Continent", Continents)
    implicit val airportTypeMapper = createEnumJdbcType("AirportType", AirportTypes)
    implicit val airportTypeListTypeMapper = createEnumListJdbcType("AirportType", AirportTypes)
    implicit val surfaceMapper = createEnumJdbcType("Surface", Surfaces)
    implicit val surfaceListTypeMapper = createEnumListJdbcType("Surface", Surfaces)
    implicit val continentColumnExtensionMethodsBuilder = createEnumColumnExtensionMethodsBuilder(Continents)
    implicit val airportTypeColumnExtensionMethodsBuilder = createEnumColumnExtensionMethodsBuilder(AirportTypes)
    implicit val surfaceColumnExtensionMethodsBuilder = createEnumColumnExtensionMethodsBuilder(Surfaces)

    import Continents.Continent
    import AirportTypes.AirportType
    import Surfaces.Surface
    implicit val getContinent: GetResult[Continent] = GetResult(v => Continents.fromString(v.nextString))
    implicit val getAirportTypes: GetResult[AirportType] = GetResult(v => AirportTypes.fromString(v.nextString))
    implicit val getSurface: GetResult[Surface] = GetResult(v => Surfaces.fromString(v.nextString))

    import icassina.lunatech.Country
    implicit val getCountry: GetResult[Country] = GetResult(v =>
      Country(
        v.nextInt,
        v.nextString, v.nextString, getContinent(v),
        v.nextString, v.nextStringOption.map(_.split(",").toSeq.map(_.trim)).getOrElse(Seq.empty)
      )
    )
  }
}

object MyPostgresDriver extends MyPostgresDriver
