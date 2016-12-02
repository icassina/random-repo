package controllers

import javax.inject.{Inject, Singleton}

import play.api.mvc._
import play.api.libs.json._

import icassina.lunatech._
import icassina.lunatech.json.Messages._

@Singleton
class API @Inject() (dao: DAO, daoEC: DAOExecutionContext) extends Controller with LoggingController {

  implicit val ec = daoEC


  def stats = Logging {
    Action.async {
      dao.stats.map(stats => Ok(Json.toJson(stats)))
    }
  }

  def countries = Logging {
    Action.async {
      dao.countries.map(countries => Ok(Json.toJson(countries)))
    }
  }

  def country(countryCode: String) = Logging {
    Action.async {
      dao.country(countryCode).map(country =>
        country.fold[Result](NotFound)(country => Ok(Json.toJson(country)))
      )
    }
  }

  def countryFuzzy(query: String) = Logging {
    Action.async {
      dao.countryFuzzy(query).map(country =>
        country.fold[Result](NotFound)(country => Ok(Json.toJson(country)))
      )
    }
  }

  def airports(countryCode: String) = Logging {
    Action.async {
      dao.airportsByCountry(countryCode).map(airports =>
        airports.fold[Result](NotFound)(airports => Ok(Json.toJson(airports)))
      )
    }
  }

  def airportsGeoJSON(countryCode: String) = Logging {
    Action.async {
      dao.airportsByCountry(countryCode).map(airports =>
        airports.fold[Result](NotFound)(airports => Ok(Json.toJson(AirportsByCountryFeatures(airports))))
      )
    }
  }

  def runways(countryCode: String) = Logging {
    Action.async {
      dao.runwaysByCountry(countryCode).map(runways =>
        runways.fold[Result](NotFound)(runways => Ok(Json.toJson(runways)))
      )
    }
  }

  def runwaysGeoJSON(countryCode: String) = Logging {
    Action.async {
      dao.runwaysByCountry(countryCode).map(runways =>
        runways.fold[Result](NotFound)(runways => Ok(Json.toJson(RunwaysByCountryFeatures(runways))))
      )
    }
  }

  def countriesAirportsTop10 = Logging {
    Action.async {
      dao.topTenCountries.map(top10 => Ok(Json.obj("data" -> Json.toJson(top10))))
    }
  }

  def countriesAirportsLow10 = Logging {
    Action.async {
      dao.lowTenCountries.map(low10 => Ok(Json.obj("data" -> Json.toJson(low10))))
    }
  }

  def runwaySurfaces = Logging {
    Action.async {
      dao.runwaySurfacesByCountry.map(surf => Ok(Json.obj("data" -> Json.toJson(surf))))
    }
  }

  def runwayIdentsTop10 = Logging {
    Action.async {
      dao.topRunwayIdents.map(top10 => Ok(Json.obj("data" -> Json.toJson(top10))))
    }
  }
}
