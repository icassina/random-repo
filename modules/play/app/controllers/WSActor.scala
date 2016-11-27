package icassina.lunatech

import scala.concurrent.Future

import akka.actor._

import play.api.libs.json._
import play.api.libs.functional.syntax._

object WSActor {
  def props(client: ActorRef)(implicit dao: DAO, ec: DAOExecutionContext) = Props(new WSActor(client))

  import json.Messages._

  sealed trait Message { type Resp <: Response}
  object Message {
    case class CountryQuery(str: String) extends Message { type Resp = Response with Response.CountryQueryResp }

    implicit val countryQueryRead: Reads[Message.CountryQuery] = (
      (JsPath \ "type").read[String].filter(_ == "country-query") and
      (JsPath \ "query").read[String]
    )((_, str) => Message.CountryQuery(str))
  }
  sealed trait Response
  object Response {
    sealed trait CountryQueryResp { self: Response => }
    case class MatchingCountries(countries: Seq[Country]) extends Response with CountryQueryResp
    case class CountryFound(country: Country) extends Response with CountryQueryResp
    case object NoMatches extends Response with CountryQueryResp
    case class SendAirports(country: Country, airports: Seq[Airport]) extends Response
    case class SendRunways(country: Country, runways: Seq[Runway]) extends Response

    implicit val countryQueryRespWrite: Writes[Response] = Writes[Response] {
      case Response.NoMatches => Json.obj(
        "type"    -> "country-query-response",
        "result"  -> Json.obj(
          "type"  -> "no-matches"
        )
      )
      case Response.MatchingCountries(countries) => Json.obj(
        "type"    -> "country-query-response",
        "result"  -> Json.obj(
          "type"  -> "matching-countries",
          "data"  -> countries
        )
      )
      case Response.CountryFound(country) => Json.obj(
        "type"    -> "country-query-response",
        "result"  -> Json.obj(
          "type"  -> "country-found",
          "data"  -> Json.obj(
            "country"   -> country
          )
        )
      )
      case Response.SendAirports(country, airports) =>
        Json.obj(
          "type"    -> "send-airports",
          "result"  -> Json.obj(
            "country"   -> country,
            "airports"  -> AirportsFeatures(airports)
          )
        )
      case Response.SendRunways(country, runways) =>
        Json.obj(
          "type"    -> "send-runways",
          "result"  -> Json.obj(
            "country"   -> country,
            "runways"   -> RunwaysFeatures(runways)
          )
        )
      case Error.MalformedMessage(msg, errors) => Json.obj(
        "type"    -> "error",
        "result"  -> Json.obj(
          "type"    -> "malformed-message",
          "data"    -> errors
        )
      )
    }
    //case Response.SendRunways(country, runways) => Json.obj(
      //"type"    -> "send-runways",
      //"result"  -> Json.obj(
        //"country"   -> country,
        //"runways"   -> RunwaysFeatures(runways)
      //)
    //)
  }
  sealed trait Error extends Response
  object Error {
    import Response._
    case class MalformedMessage(msg: Message, errors: Seq[String]) extends Error with CountryQueryResp
  }
}

class WSActor(client: ActorRef)(implicit dao: DAO, ec: DAOExecutionContext) extends Actor {
  import WSActor.Message._
  import WSActor.Response
  import Response._

  private def sendResponse(r: Response) = client ! Json.toJson(r)

  def receive = {
    case (o: JsObject) => o.validate[CountryQuery].fold(
      { errors =>
        println("error")
        Future.successful(())
      },
      { query =>
          println(s"query: ${query.str}")
          dao.lookupAirportsByCountry(query.str).map { as =>
            as.fold(
              { cs => if (cs.isEmpty) Seq(NoMatches) else Seq(MatchingCountries(cs)) },
              { case (country, airports) => Seq(CountryFound(country), SendAirports(country, airports)) }
            )
          }.map(_.foreach(resp =>{
            println("response:")
            println(resp.getClass.getName)
            sendResponse(resp)
          }))
      }
    )
    case x => {
      println("received: "+ x)
    }
  }
}
