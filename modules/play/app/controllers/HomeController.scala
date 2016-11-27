package controllers

import java.util.UUID
import javax.inject.{Inject, Singleton}

import akka.actor.ActorSystem
import akka.stream.Materializer

import play.api.mvc._
import play.api.libs.json._
import play.api.libs.streams._

import icassina.lunatech.Country
import icassina.lunatech.Airport
import icassina.lunatech.Runway
import icassina.lunatech.DAO
import icassina.lunatech.DAOExecutionContext
import icassina.lunatech.WSActor

@Singleton
class HomeController @Inject() (dao: DAO, daoEC: DAOExecutionContext, actorSystem: ActorSystem, m: Materializer) extends Controller {

  private val logger = org.slf4j.LoggerFactory.getLogger(this.getClass)

  implicit val ec = daoEC
  implicit val as: ActorSystem = actorSystem
  implicit val mr: Materializer = m

  private def wsuri(implicit req: Request[_]) = routes.HomeController.ws.webSocketURL(false)

  def index = Action.async { implicit request =>
    dao.stats.map { case (countries, airports, runways) =>
      logger.info("Calling index")
      Ok(views.html.index(countries, airports, runways)(wsuri))
    }
  }

  def reports = Action.async { implicit request =>
    for {
      top10 <- dao.topTenCountries
      low10 <- dao.bottomTenCountries
      surf  <- dao.runwaySurfacesByCountry
      topId <- dao.topRunwayIdents
    } yield {
      Ok(views.html.reports(top10, low10, surf, topId)(wsuri))
    }
  }

  def query = Action { implicit request =>
    Ok(views.html.query()(wsuri))
  }

  def ws = WebSocket.accept[JsValue, JsValue] { implicit request =>
    ActorFlow.actorRef(WSActor.props(_)(dao, ec))
  }
}
