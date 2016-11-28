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
    case object CountriesList extends Message { type Resp = Response with Response.CountriesListResp }
    case class CountryQuery(str: String) extends Message { type Resp = Response with Response.CountryQueryResp }

    //implicit val countryQueryRead: Reads[CountryQuery] = (
      //(JsPath \ "type").read[String].filter(_ == "country-query") and
      //(JsPath \ "query").read[String]
    //)((_, str) => CountryQuery(str))

    //implicit val countriesListRead: Reads[CountriesList] = (
      //(JsPath \ "type").read[String].filter(_ == "countries-list").map(_ => CountriesList())
    //)

    implicit val messageRead: Reads[Message] = (
      (JsPath \ "type").read[String].flatMap {
        case "countries-list" => Reads.pure(CountriesList)
        case "country-query"  => (
          (JsPath \ "query").read[String].map(CountryQuery.apply)
        )
      }
    )
  }
  sealed trait Response
  object Response {
    sealed trait CountryQueryResp { self: Response => }
    sealed trait CountriesListResp { self: Response => }
    case class MatchingCountries(countries: Seq[Country])               extends Response with CountryQueryResp
    case class CountryFound(country: Country)                           extends Response with CountryQueryResp
    case object NoMatches                                               extends Response with CountryQueryResp
    case class SendCountries(countries: Seq[Country] )                  extends Response with CountriesListResp
    case class SendAirports(country: Country, airports: Seq[Airport])   extends Response
    case class SendRunways(country: Country, runways: Seq[Runway])      extends Response

    sealed trait Error extends Response
    object Error {
      case class MalformedMessage(msg: Message, errors: Seq[String]) extends Error with CountryQueryResp
    }

    implicit val responseWrite: Writes[Response] = Writes[Response] {
      case NoMatches => Json.obj(
        "type"    -> "country-query-response",
        "result"  -> Json.obj(
          "type"  -> "no-matches"
        )
      )
      case MatchingCountries(countries) => Json.obj(
        "type"    -> "country-query-response",
        "result"  -> Json.obj(
          "type"  -> "matching-countries",
          "data"  -> countries
        )
      )
      case CountryFound(country) => Json.obj(
        "type"    -> "country-query-response",
        "result"  -> Json.obj(
          "type"  -> "country-found",
          "data"  -> Json.obj(
            "country"   -> country
          )
        )
      )
      case SendCountries(countries) =>
        Json.obj(
          "type"    -> "send-countries",
          "result"  -> Json.obj(
            "countries"   -> countries
          )
        )
      case SendAirports(country, airports) =>
        Json.obj(
          "type"    -> "send-airports",
          "result"  -> Json.obj(
            "country"   -> country,
            "airports"  -> AirportsFeatures(airports)
          )
        )
      case SendRunways(country, runways) =>
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
      //case SendRunways(country, runways) => Json.obj(
        //"type"    -> "send-runways",
        //"result"  -> Json.obj(
          //"country"   -> country,
          //"runways"   -> RunwaysFeatures(runways)
        //)
      //)
    }
  }
}

class WSActor(client: ActorRef)(implicit dao: DAO, ec: DAOExecutionContext) extends Actor {
  import WSActor.Message
  import WSActor.Response
  import Response._

  private def sendResponse(r: Response) = client ! Json.toJson(r)

  def receive = {
    case (o: JsObject) => o.validate[Message].fold(
      { errors =>
        println("error")
        Future.successful(())
      },
      {
        case Message.CountriesList => {
          dao.countries.map { countries =>
            sendResponse(SendCountries(countries))
          }
        }
        // TODO: simplify this mess (and on API and Slick modules)
        case Message.CountryQuery(queryStr) => {
          println(s"query: ${queryStr}")
          dao.lookupAirportsByCountry(queryStr).map { as =>
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
      }
    )
    case x => {
      println("received: "+ x)
    }
  }
}
