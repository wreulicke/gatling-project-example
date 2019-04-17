package login

import common.BaseSimulation
import io.gatling.core.Predef._
import io.gatling.http.Predef._

class AccessTokenSimulation extends BaseSimulation {

  val httpConf = http
    .baseUrl(foo)
    .acceptEncodingHeader("gzip, deflate")
    .acceptLanguageHeader("en-US,en;q=0.5")
    .warmUp(foo + "/health")
    .shareConnections

  val oauthHeader = Map(
    "Accept" -> "application/json",
    "Content-Type" -> "application/x-www-form-urlencoded, charset=UTF-8")

  val scn = scenario(name)
    .exec(http("create_token")
    .post(foo + "/oauth/token")
    .basicAuth(clientId, clientSecret)
    .headers(oauthHeader)
    .queryParam("grant_type", "client_credentials")
    .queryParam("scope", "root"))

  setUp(scn.inject(
    rampUsersPerSec(own.getInt("from")) to own.getInt("to")
      during own.getDuration("duration")
  ).protocols(httpConf))
}
