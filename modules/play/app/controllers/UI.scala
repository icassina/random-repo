package controllers

import javax.inject.{Inject, Singleton}

import akka.actor.ActorSystem
import akka.stream.Materializer

import play.api.mvc._
import play.api.libs.json._
import play.api.libs.streams._

import icassina.lunatech._

@Singleton
class UI @Inject() (dao: DAO, daoEC: DAOExecutionContext, actorSystem: ActorSystem, m: Materializer) extends Controller {

  private val logger = org.slf4j.LoggerFactory.getLogger(this.getClass)

  implicit val ec = daoEC
  implicit val as: ActorSystem = actorSystem
  implicit val mr: Materializer = m

  def index = Action.async { implicit request =>
    dao.stats.map(stats => Ok(views.html.index(stats)))
  }

  def reports = Action.async { implicit request =>
    for {
      surf  <- dao.runwaySurfacesByCountry
      topId <- dao.topRunwayIdents
    } yield {
      Ok(views.html.reports(surf, topId))
    }
  }

  def query = Action { implicit request =>
    Ok(views.html.query())
  }

  def ws = WebSocket.accept[JsValue, JsValue] { implicit request =>
    ActorFlow.actorRef(WSActor.props(_)(dao, ec))
  }
}
