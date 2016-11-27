import sbt.{AutoPlugin, Resolver}
import sbt.plugins.JvmPlugin
import sbt.Keys._
import sbt.{Resolver, _}

object Common extends AutoPlugin {
  override def trigger = allRequirements
  override def requires = JvmPlugin

  override def projectSettings = Seq(
    scalaVersion := "2.11.8",
    javacOptions ++= Seq("-source", "1.8", "-target", "1.8"),
    scalacOptions ++= Seq(
      "-encoding", "UTF-8", // yes, this is 2 args
      "-deprecation",
      "-feature",
      "-unchecked",
      "-Xlint",
      "-Yno-adapted-args",
      "-Ywarn-numeric-widen",
      "-Xfatal-warnings"
    ),
    resolvers ++= Seq(
      "scalaz-bintray" at "http://dl.bintray.com/scalaz/releases",
       Resolver.sonatypeRepo("releases"),
       Resolver.typesafeRepo("releases"),
       Resolver.sonatypeRepo("snapshots")),
    libraryDependencies ++= Seq(
      "javax.inject" % "javax.inject" % "1",
      "com.google.inject" % "guice" % "4.0"
    ),
    scalacOptions in Test ++= Seq("-Yrangepos")
  )

  def databaseUrl = sys.env.getOrElse("DB_DEFAULT_URL", "jdbc:postgresql://localhost:5432/lunatech")
  def databaseUser = sys.env.getOrElse("DB_DEFAULT_PASSWORD", "lunatech")
  def databasePassword = sys.env.getOrElse("DB_DEFAULT_USER", "assignment")
  def databaseSchemas = Seq("lunatech")
}
