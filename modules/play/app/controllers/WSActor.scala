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
    case class CountryQuery(countryCode: String) extends Message { type Resp = Response with Response.CountryQueryResp }

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
    case class CountryFound(country: Country)                         extends Response with CountryQueryResp
    case class SendAirports(airports: AirportsByCountry)              extends Response with CountryQueryResp
    case class SendRunways(runways: RunwaysByCountry)                 extends Response with CountryQueryResp
    case class SendCountries(countries: Seq[CountryDef])              extends Response with CountriesListResp

    sealed trait Error extends Response
    object Error {
      case class MalformedMessage(msg: Message, errors: Seq[String])  extends Error with CountryQueryResp
      case class NotCountryCode(queryStr: String)                     extends Error with CountryQueryResp
      case object NoMatches                                           extends Error with CountryQueryResp
    }

    implicit val responseWrite: Writes[Response] = Writes[Response] {
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
      case SendAirports(airports) =>
        Json.obj(
          "type"    -> "send-airports",
          "result"  -> airports
        )
      case SendRunways(runways) =>
        Json.obj(
          "type"    -> "send-runways",
          "result"  -> runways
        )
      case Error.MalformedMessage(msg, errors) => Json.obj(
        "type"    -> "error",
        "result"  -> Json.obj(
          "type"    -> "malformed-message",
          "data"    -> errors
        )
      )
      case Error.NotCountryCode(queryStr) => Json.obj(
        "type"    -> "error",
        "result"  -> Json.obj(
          "type"  -> "not-country-code",
          "data"  -> queryStr
        )
      )
      case Error.NoMatches => Json.obj(
        "type"    -> "country-query-response",
        "result"  -> Json.obj(
          "type"  -> "no-matches"
        )
      )
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
        case Message.CountryQuery(queryStr) => {
          val countryOrError = {
            if (queryStr.length == 2) {
              dao.country(queryStr).map(
                _.fold[Either[Error with Message.CountryQuery#Resp, Country]](Left(Error.NotCountryCode(queryStr)))(Right.apply)
              )
            } else {
              dao.country(queryStr).map(
                _.fold[Either[Error with Message.CountryQuery#Resp, Country]](Left(Error.NoMatches))(Right.apply)
              )
            }
          }
          countryOrError.map(
            _.left.map(sendResponse(_)).right.map { country =>
              val airportsQuery = dao.airportsByCountry(country.code)
              val runwaysQuery = dao.runwaysByCountry(country.code)

              airportsQuery.map(res => sendResponse(res.fold[Message.CountryQuery#Resp](Error.NoMatches)(SendAirports.apply)))
              runwaysQuery.map(res => sendResponse(res.fold[Message.CountryQuery#Resp](Error.NoMatches)(SendRunways.apply)))
            }
          )
        }
      }
    )
    case x => {
      println("received: "+ x)
    }
  }
}
