package icassina.lunatech.json

import com.vividsolutions.jts.geom.Point
import com.vividsolutions.jts.io.WKTWriter

import play.api.libs.json._
import play.api.libs.functional.syntax._

import icassina.lunatech._


object Messages {
  lazy val wktWriter = new WKTWriter(2)

  implicit val countryWrite: Writes[Country] = Writes[Country] { d =>
    Json.obj(
      "id"              -> d.id,
      "code"            -> d.code,
      "name"            -> d.name,
      "continent"       -> d.continent,
      "wikipedia_link"  -> d.wikipediaLink,
      "keywords"        -> d.keywords,
      "type"            -> "country"
    )
  }

  implicit val airportWrite: Writes[Airport] = Writes[Airport] { d =>
    Json.obj(
      "id"                -> d.id,
      "ident"             -> d.ident,
      "airportType"       -> d.airportType,
      "name"              -> d.name,
      "position"          -> Seq(d.position.getX, d.position.getY),
      "elevation"         -> d.elevation,
      "isoCountry"        -> d.isoCountry,
      "isoRegion"         -> d.isoRegion,
      "municipality"      -> d.municipality,
      "scheduledService"  -> d.scheduledService,
      "gpsCode"           -> d.gpsCode,
      "iataCode"          -> d.iataCode,
      "localCode"         -> d.localCode,
      "homeLink"          -> d.homeLink,
      "wikipediaLink"     -> d.wikipediaLink,
      "keywords"          -> d.keywords,
      "type"              -> "airport"
    )
  }

  def runwayToJsObj(d: Runway): JsObject =
    Json.obj(
      "id"                    -> d.id,
      "airportRef"            -> d.airportRef,
      "length"                -> d.length,
      "width"                 -> d.width,
      "surface"               -> d.surface,
      "surfaceStd"            -> d.surfaceStd,
      "lighted"               -> d.lighted,
      "closed"                -> d.closed,
      "leIdent"               -> d.leIdent,
      "lePosition"            -> d.lePosition.map(p => Seq(p.getX, p.getY)),
      "leElevation"           -> d.leElevation,
      "leHeading"             -> d.leHeading,
      "leDisplacedThreshold"  -> d.leDisplacedThreshold,
      "heIdent"               -> d.heIdent,
      "hePosition"            -> d.hePosition.map(p => Seq(p.getX, p.getY)),
      "heElevation"           -> d.heElevation,
      "heHeading"             -> d.heHeading,
      "heDisplacedThreshold"  -> d.heDisplacedThreshold,
      "type"                  -> "runway"
    )

  implicit val runwayWrite: Writes[Runway] = Writes[Runway](runwayToJsObj)

  implicit val runwayWithAirportIdentWrite: Writes[RunwayWithAirportIdent] = Writes[RunwayWithAirportIdent] { d =>
    runwayToJsObj(d.runway) + ("airportIdent" -> Json.toJson(d.airportIdent))
  }

  case class AirportFeature(airport: Airport) extends AnyVal
  implicit val airportFeatureWrite: Writes[AirportFeature] = Writes[AirportFeature] { d =>
    Json.obj(
      "id"        -> d.airport.id,
      "type"      -> "Feature",
      "geometry"  -> Json.obj(
        "type"        -> "Point",
        "coordinates" -> Seq(d.airport.position.getX, d.airport.position.getY)
      ),
      "properties" -> Json.toJson(d.airport)
    )
  }

  case class AirportsFeatures(airports: Seq[Airport]) extends AnyVal
  implicit val airportsFeaturesWrite: Writes[AirportsFeatures] = Writes[AirportsFeatures] { d =>
    Json.obj(
      "type"      -> "FeatureCollection",
      "crs"       -> Json.obj(
        "type"        -> "name",
        "properties"  -> Json.obj(
          "name"  -> "EPSG:4326"
        )
      ),
      "features" -> d.airports.map(AirportFeature.apply)
    )
  }
  case class RunwayFeature(runway: Runway) extends AnyVal
  implicit val runwayFeatureWrite: Writes[RunwayFeature] = Writes[RunwayFeature] { d =>
    d.runway.lePosition.map(p => Seq(p.getX, p.getY)).map { coords =>
      Json.obj(
        "id"        -> d.runway.id,
        "type"      -> "Feature",
        "geometry"  -> Json.obj(
          "type"        -> "Point",
          "coordinates" -> coords
        ),
        "properties" -> Json.toJson(d.runway)
      )
    }.orElse {
      d.runway.hePosition.map(p => Seq(p.getX, p.getY)).map { coords =>
        Json.obj(
          "id"        -> d.runway.id,
          "type"      -> "Feature",
          "geometry"  -> Json.obj(
            "type"        -> "Point",
            "coordinates" -> coords
          ),
          "properties" -> Json.toJson(d.runway)
        )
      }
    }.getOrElse(JsNull)
  }

  case class RunwaysFeatures(runways: Seq[Runway]) extends AnyVal
  implicit val runwaysFeaturesWrite: Writes[RunwaysFeatures] = Writes[RunwaysFeatures] { d =>
    Json.obj(
      "type"      -> "FeatureCollection",
      "crs"       -> Json.obj(
        "type"        -> "name",
        "properties"  -> Json.obj(
          "name"  -> "EPSG:4326"
        )
      ),
      "features" -> d.runways.map(RunwayFeature.apply)
    )
  }

  implicit val statsWrite: Writes[Stats] = Writes[Stats] { d =>
    Json.obj(
      "countries" -> d.countries,
      "airports"  -> d.airports,
      "runways"   -> d.runways
    )
  }

  implicit val airportsByCountryWrite: Writes[AirportsByCountry] = Writes[AirportsByCountry] { d =>
    Json.obj(
      "country"   -> d.country,
      "airports"  -> d.airports
    )
  }

  implicit val runwaysByCountryWrite: Writes[RunwaysByCountry] = Writes[RunwaysByCountry] { d =>
    Json.obj(
      "country"   -> d.country,
      "runways"   -> d.runways
    )
  }

  implicit val airportsCountByCounytryWrite: Writes[AirportsCountByCountry] = Writes[AirportsCountByCountry] { d =>
    Json.obj(
      "country"   -> d.country,
      "airports"  -> d.airports
    )
  }

  implicit val airportsAndRunwaysCountByCountryWrite: Writes[AirportsAndRunwaysCountByCountry] = Writes[AirportsAndRunwaysCountByCountry] { d =>
    Json.obj(
      "country"   -> d.country,
      "airports"  -> d.airports,
      "runways"   -> d.runways
    )
  }

  implicit val runwaySurfacesCountByCountry: Writes[RunwaySurfacesCountByCountry] = Writes[RunwaySurfacesCountByCountry] { d =>
    Json.obj(
      "country"   -> d.country,
      "surface"   -> d.surface,
      "runways"   -> d.runways
    )
  }

  implicit val runwayIdentsCount: Writes[RunwayIdentsCount] = Writes[RunwayIdentsCount] { d =>
    Json.obj(
      "ident"   -> d.ident,
      "runways" -> d.runways
    )
  }

}
