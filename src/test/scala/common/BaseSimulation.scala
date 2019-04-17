package common

import java.nio.file.Paths
import java.util.UUID

import com.typesafe.config.{Config, ConfigFactory}
import io.gatling.core.scenario.Simulation

import scala.concurrent.duration.{Duration, FiniteDuration}
import scala.util.Try

abstract class BaseSimulation extends Simulation {

  implicit def asFinite(d: java.time.Duration): FiniteDuration = Duration.fromNanos(d.toNanos)

  lazy val own = properties.getConfig(this.getClass.getName)
  val properties = configFile

  def configFile: Config = {
    List(
      Try {
        val path = System.getenv("SARDIN_CONFIG")
        ConfigFactory.parseFileAnySyntax(Paths.get(path).toFile)
      },
      Try {
        val wd = System.getProperty("user.dir");
        ConfigFactory.parseFileAnySyntax(Paths.get(wd, "environment").toFile)
      },
      Try(ConfigFactory.parseResourcesAnySyntax("environment")),
      Try(ConfigFactory.systemEnvironment()),
      Try(ConfigFactory.systemProperties()),

    )
      .filter(_.isSuccess)
      .foldLeft(ConfigFactory.empty()) {
        (a, b) => a.withFallback(b.get)
      }.resolve()
  }

  def uuid = UUID.randomUUID().toString

  def foo = properties.getString("foo.endpoint")

  def clientId = properties.getString("client_id")

  def clientSecret = properties.getString("client_secret")

  def name = this.getClass.getName
}
