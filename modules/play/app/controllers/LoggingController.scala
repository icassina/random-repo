package controllers

import scala.concurrent.Future

import play.api.mvc._

import icassina.lunatech.DAOExecutionContext

trait LoggingController { controller: Controller =>

  private val logger = org.slf4j.LoggerFactory.getLogger(this.getClass)

  private def logIn[A](request: Request[A]) = {
    logger.info(s"← ${request.method} ${request.uri}")
  }
  private def logOut[A](request: Request[A], result: Result) = {
    logger.info(s"→ ${request.method} ${request.uri}: ${result.header.status}")
  }

  case class Logging[A](action: Action[A])(implicit ec: DAOExecutionContext) extends Action[A] {
    def apply(request: Request[A]): Future[Result] = {
      logIn(request)
      action(request).map { result =>
        logOut(request, result)
        result
      }
    }
    lazy val parser = action.parser
  }
}
