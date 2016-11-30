// Adding this means no explicit import in *.scala.html files
TwirlKeys.templateImports ++= Seq(
  "icassina.lunatech.Country",
  "icassina.lunatech.Airport",
  "icassina.lunatech.Runway",
  "icassina.lunatech.Stats",
  "icassina.lunatech.AirportsCountByCountry",
  "icassina.lunatech.AirportsByCountry",
  "icassina.lunatech.RunwaysByCountry",
  "icassina.lunatech.RunwaySurfacesCountByCountry",
  "icassina.lunatech.RunwayIdentsCount"
)

libraryDependencies ++= Seq(
  "org.webjars" % "bootstrap" % "3.3.4",
  "org.webjars" % "openlayers" % "3.17.1",
  "org.webjars" % "selectize.js" % "0.12.3",
  "org.webjars" % "datatables" % "1.10.12-1",
  "org.webjars" % "jquery.scrollTo" % "2.1.1"
)
