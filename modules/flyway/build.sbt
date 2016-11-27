libraryDependencies ++= Seq(
  "org.flywaydb" % "flyway-core" % "4.0",
  "com.github.tototoshi" %% "scala-csv" % "1.3.4"
)

flywayLocations := Seq("classpath:db/migration")

flywayUrl := Common.databaseUrl
flywayUser := Common.databaseUser
flywayPassword := Common.databasePassword
flywaySchemas := Common.databaseSchemas
