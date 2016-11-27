package controllers

import java.util.UUID
import javax.inject.{Inject, Singleton}

import akka.actor.ActorSystem
import icassina.lunatech.Country
import icassina.lunatech.Airport
import icassina.lunatech.Runway
import icassina.lunatech.DAO
import icassina.lunatech.DAOExecutionContext
import play.api.mvc._

@Singleton
class HomeController @Inject() (dao: DAO, daoEC: DAOExecutionContext) extends Controller {

  private val logger = org.slf4j.LoggerFactory.getLogger(this.getClass)

  implicit val ec = daoEC

  def index = Action.async {
    dao.stats.map { case (countries, airports, runways) =>
      logger.info("Calling index")
      Ok(views.html.index(countries, airports, runways))
    }
  }

  def reports = Action.async {
    for {
      top10 <- dao.topTenCountries
      low10 <- dao.bottomTenCountries
      surf  <- dao.runwaySurfacesByCountry
      topId <- dao.topRunwayIdents
    } yield {
      Ok(views.html.reports(top10, low10, surf, topId))
    }
  }

}
