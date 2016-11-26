

// Database Migrations:
// run with "sbt flywayMigrate"
// http://flywaydb.org/getstarted/firststeps/sbt.html

//$ export DB_DEFAULT_URL="jdbc:h2:/tmp/example.db"
//$ export DB_DEFAULT_USER="sa"
//$ export DB_DEFAULT_PASSWORD=""

libraryDependencies += "org.flywaydb" % "flyway-core" % "4.0"

flywayLocations := Seq("classpath:db/migration")

flywayUrl := Common.databaseUrl
flywayUser := Common.databaseUser
flywayPassword := Common.databasePassword
flywaySchemas := Common.databaseSchemas
