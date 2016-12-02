package controllers

import javax.inject.{Inject, Singleton}

import play.api.mvc._
import play.api.libs.json._
import play.api.libs.streams._

import icassina.lunatech._

@Singleton
class UI @Inject() (dao: DAO, daoEC: DAOExecutionContext) extends Controller with LoggingController {
  implicit val ec = daoEC

  def index = Logging {
    Action.async {
      dao.stats.map(stats => Ok(views.html.index(stats)))
    }
  }

  def reports = Logging {
    Action {
      Ok(views.html.reports())
    }
  }

  def query = Logging {
    Action {
      Ok(views.html.query())
    }
  }
}
