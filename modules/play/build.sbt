// Adding this means no explicit import in *.scala.html files
TwirlKeys.templateImports ++= Seq(
  "icassina.lunatech.Country",
  "icassina.lunatech.Airport",
  "icassina.lunatech.Runway"
)

libraryDependencies ++= Seq(
  "org.webjars" % "bootstrap" % "3.3.4",
  "org.webjars" % "openlayers" % "3.17.1"
)


pipelineStages := Seq(gzip)
