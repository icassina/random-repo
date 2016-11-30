package controllers

import javax.inject.{Inject, Singleton}

import play.api.mvc._
import play.api.libs.json._
import play.api.libs.streams._

import icassina.lunatech._
import icassina.lunatech.json.Messages._

@Singleton
class API @Inject() (dao: DAO, daoEC: DAOExecutionContext) extends Controller {

  private val logger = org.slf4j.LoggerFactory.getLogger(this.getClass)

  implicit val ec = daoEC


  def stats = Action.async {
    dao.stats.map(stats => Ok(Json.toJson(stats)))
  }

  def countries = Action.async {
    dao.countries.map(countries => Ok(Json.toJson(countries)))
  }

  def country(countryCode: String) = Action.async {
    dao.country(countryCode).map(country =>
      country.fold[Result](NotFound)(country => Ok(Json.toJson(country)))
    )
  }

  def airports(countryCode: String) = Action.async {
    dao.airportsByCountry(countryCode).map(airports =>
      airports.fold[Result](NotFound)(airports => Ok(Json.toJson(airports)))
    )
  }

  def airportsGeoJSON(countryCode: String) = Action.async {
    dao.airportsByCountry(countryCode).map(airports =>
      airports.fold[Result](NotFound)(airports => Ok(Json.toJson(AirportsByCountryFeatures(airports))))
    )
  }

  def runways(countryCode: String) = Action.async {
    dao.runwaysByCountry(countryCode).map(runways =>
      runways.fold[Result](NotFound)(runways => Ok(Json.toJson(runways)))
    )
  }

  def runwaysGeoJSON(countryCode: String) = Action.async {
    dao.runwaysByCountry(countryCode).map(runways =>
      runways.fold[Result](NotFound)(runways => Ok(Json.toJson(RunwaysByCountryFeatures(runways))))
    )
  }
}
