package icassina.lunatech.json

import com.vividsolutions.jts.geom.Point
import com.vividsolutions.jts.io.WKTWriter

import play.api.libs.json._
import play.api.libs.functional.syntax._

import icassina.lunatech.Country
import icassina.lunatech.Airport
import icassina.lunatech.Runway


object Messages {
  lazy val wktWriter = new WKTWriter(2)

  implicit val countryWrite: Writes[Country] = Writes[Country] { c =>
    Json.obj(
      "id"              -> c.id,
      "code"            -> c.code,
      "name"            -> c.name,
      "continent"       -> c.continent,
      "wikipedia_link"  -> c.wikipediaLink,
      "keywords"        -> c.keywords
    )
  }

  implicit val airportWrite: Writes[Airport] = Writes[Airport] { a =>
    Json.obj(
      "id"                -> a.id,
      "ident"             -> a.ident,
      "airportType"       -> a.airportType,
      "name"              -> a.name,
      "position"          -> wktWriter.write(a.position),
      "elevation"         -> a.elevation,
      "isoCountry"        -> a.isoCountry,
      "isoRegion"         -> a.isoRegion,
      "municipality"      -> a.municipality,
      "scheduledService"  -> a.scheduledService,
      "gpsCode"           -> a.gpsCode,
      "iataCode"          -> a.iataCode,
      "localCode"         -> a.localCode,
      "homeLink"          -> a.homeLink,
      "wikipediaLink"     -> a.wikipediaLink,
      "keywords"          -> a.keywords
    )
  }

  implicit val runwayWrite: Writes[Runway] = Writes[Runway] { r =>
    Json.obj(
      "id"                    -> r.id,
      "airportRef"            -> r.airportRef,
      "length"                -> r.length,
      "width"                 -> r.width,
      "surface"               -> r.surface,
      "surfaceStd"            -> r.surfaceStd,
      "lighted"               -> r.lighted,
      "closed"                -> r.closed,
      "leIdent"               -> r.leIdent,
      "lePosition"            -> r.lePosition.map(wktWriter.write(_)),
      "leElevation"           -> r.leElevation,
      "leHeading"             -> r.leHeading,
      "leDisplacedThreshold"  -> r.leDisplacedThreshold,
      "heIdent"               -> r.heIdent,
      "hePosition"            -> r.hePosition.map(wktWriter.write(_)),
      "heElevation"           -> r.heElevation,
      "heHeading"             -> r.heHeading,
      "heDisplacedThreshold"  -> r.heDisplacedThreshold
    )
  }

  case class AirportFeature(airport: Airport) extends AnyVal
  implicit val airportFeatureWrite: Writes[AirportFeature] = Writes[AirportFeature] { a =>
    Json.obj(
      "id"        -> a.airport.id,
      "type"      -> "Feature",
      "geometry"  -> Json.obj(
        "type"        -> "Point",
        "coordinates" -> Seq(a.airport.position.getX, a.airport.position.getY)
      ),
      "properties" -> Json.toJson(a.airport)
    )
  }

  case class AirportsFeatures(airports: Seq[Airport]) extends AnyVal
  implicit val airportsFeaturesWrite: Writes[AirportsFeatures] = Writes[AirportsFeatures] { as =>
    Json.obj(
      "type"      -> "FeatureCollection",
      "crs"       -> Json.obj(
        "type"        -> "name",
        "properties"  -> Json.obj(
          "name"  -> "EPSG:4326"
        )
      ),
      "features" -> as.airports.map(AirportFeature.apply)
    )
  }
  case class RunwayFeature(runway: Runway) extends AnyVal
  implicit val runwayFeatureWrite: Writes[RunwayFeature] = Writes[RunwayFeature] { r =>
    r.runway.lePosition.map(p => Seq(p.getX, p.getY)).map { coords =>
      Json.obj(
        "id"        -> r.runway.id,
        "type"      -> "Feature",
        "geometry"  -> Json.obj(
          "type"        -> "Point",
          "coordinates" -> coords
        ),
        "properties" -> Json.toJson(r.runway)
      )
    }.orElse {
      r.runway.hePosition.map(p => Seq(p.getX, p.getY)).map { coords =>
        Json.obj(
          "id"        -> r.runway.id,
          "type"      -> "Feature",
          "geometry"  -> Json.obj(
            "type"        -> "Point",
            "coordinates" -> coords
          ),
          "properties" -> Json.toJson(r.runway)
        )
      }
    }.getOrElse(JsNull)
  }

  case class RunwaysFeatures(runways: Seq[Runway]) extends AnyVal
  implicit val runwaysFeaturesWrite: Writes[RunwaysFeatures] = Writes[RunwaysFeatures] { rs =>
    Json.obj(
      "type"      -> "FeatureCollection",
      "crs"       -> Json.obj(
        "type"        -> "name",
        "properties"  -> Json.obj(
          "name"  -> "EPSG:4326"
        )
      ),
      "features" -> rs.runways.map(RunwayFeature.apply)
    )
  }

}
