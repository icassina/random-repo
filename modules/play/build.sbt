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
  "org.webjars.bower" % "jquery" % "3.1.1",
  "org.webjars.bower" % "datatables.net" % "1.10.12",
  "org.webjars.bower" % "datatables.net-bs" % "1.10.12",
  "org.webjars.bower" % "datatables.net-scroller" % "1.4.2",
  "org.webjars.bower" % "datatables.net-select" % "1.2.0"
)
