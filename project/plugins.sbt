//resolvers += "Typesafe repository" at "https://repo.typesafe.com/typesafe/releases/"
resolvers += Resolver.typesafeRepo("releases")

resolvers += Resolver.sonatypeRepo("snapshots")

resolvers += Resolver.sonatypeRepo("releases")

//resolvers += "Sonatype OSS Snapshots" at "https://oss.sonatype.org/content/repositories/snapshots"

resolvers += "Flyway" at "https://flywaydb.org/repo"

// Database migration
addSbtPlugin("org.flywaydb" % "flyway-sbt" % "4.0")

// Slick code generation
// https://github.com/tototoshi/sbt-slick-codegen
// addSbtPlugin("com.github.tototoshi" % "sbt-slick-codegen" % "1.2.0")

libraryDependencies += "org.postgresql" % "postgresql" % "9.4-1201-jdbc41"

// The Play plugin
addSbtPlugin("com.typesafe.play" % "sbt-plugin" % "2.5.10")

addSbtPlugin("com.typesafe.sbt" % "sbt-coffeescript" % "1.0.0")

addSbtPlugin("com.typesafe.sbt" % "sbt-less" % "1.1.0")

addSbtPlugin("com.typesafe.sbt" % "sbt-digest" % "1.1.1")

addSbtPlugin("com.typesafe.sbt" % "sbt-gzip" % "1.0.0")

// addSbtPlugin("com.typesafe.sbt" % "sbt-jshint" % "1.0.4")

// addSbtPlugin("com.typesafe.sbt" % "sbt-rjs" % "1.0.8")

// addSbtPlugin("com.typesafe.sbt" % "sbt-mocha" % "1.1.0")
