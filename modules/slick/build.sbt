// import slick.codegen.SourceCodeGenerator
// import slick.profile.SqlProfile.ColumnOption
// import slick.{ model => m }

libraryDependencies ++= Seq(
  "com.zaxxer" % "HikariCP" % "2.4.1",
  "com.typesafe.slick" %% "slick" % "3.1.1",
  "com.typesafe.slick" %% "slick-hikaricp" % "3.1.1",
  "org.postgresql" % "postgresql" % "9.4-1201-jdbc41",
  "com.github.tminglei" %% "slick-pg" % "0.12.0",
  "com.github.tminglei" %% "slick-pg_jts" % "0.12.0",
  "com.vividsolutions" % "jts" % "1.13"
)

/*
slickCodegenSettings
slickCodegenDatabaseUrl := Common.databaseUrl
slickCodegenDatabaseUser := Common.databaseUser
slickCodegenDatabasePassword := Common.databasePassword
slickCodegenDriver := slick.driver.PostgresDriver
slickCodegenJdbcDriver := "org.postgresql.Driver"
slickCodegenOutputPackage := "icassina.lunatech.slick"
slickCodegenExcludedTables := Seq("schema_version")


slickCodegenCodeGenerator := { (model: m.Model) =>
  new SourceCodeGenerator(model) {
    override def code =
      "import com.vividsolutions.jts._\n" + super.code

    override def Table = new Table(_) {
      override def Column = new Column(_) {
        override def rawType = model.tpe match {
          case "String" =>
            model.options.find(_.isInstanceOf[ColumnOption.SqlType]).map(_.asInstanceOf[ColumnOption.SqlType].typeName).map({
              case "geometry" => "com.vividsolutions.jts.geom.Geometry"
              case _ => "String"
            }).getOrElse("String")
          case _ => super.rawType
        }
      }
    }
    override def packageCode(profile: String, pkg: String, container: String, parentType: Option[String]): String = {
        s"""
package ${pkg}
// AUTO-GENERATED Slick data model
/** Stand-alone Slick data model for immediate use */
object ${container} extends {
  val profile = ${profile}
} with ${container}
/** Slick data model trait for extension, choice of backend or usage in the cake pattern. (Make sure to initialize this late.) */
trait ${container}${parentType.map(t => s" extends $t").getOrElse("")} {
  val profile: $profile
  import profile.api._
  ${indent(code)}
}
      """.trim()
    }
  }
}
sourceGenerators in Compile <+= slickCodegen
*/
