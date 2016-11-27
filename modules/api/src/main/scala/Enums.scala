package icassina.lunatech

object AirportTypes extends Enumeration {
  type AirportType = Value
  val balloonport, closed, heliport, large_airport, medium_airport, seaplane_base, small_airport = Value

  def fromString(s: String): AirportType = s.toLowerCase match {
    case "ballonport"     => balloonport
    case "closed"         => closed
    case "heliport"       => heliport
    case "large_airport"  => large_airport
    case "medium_airport" => medium_airport
    case "seaplane_base"  => seaplane_base
    case "small_airport"  => small_airport
    case _  => throw new RuntimeException(s"cannot convert $s to AirportType") // FIXME: proper exception
  }
}

object Continents extends Enumeration {
  type Continent = Value
  val AF, AN, AS, EU, NA, OC, SA = Value

  def fromString(s: String): Continent = s match {
    case "AF" => AF
    case "AN" => AN
    case "AS" => AS
    case "EU" => EU
    case "NA" => NA
    case "OC" => OC
    case "SA" => SA
    case _ => throw new RuntimeException(s"cannot convert $s to Continent") // FIXME
  }
}

object Surfaces extends Enumeration {
  type Surface = Value
  val ASP, BIT, BRI, CLA, COM, CON, COP, COR, GRE, GRS, GVL, ICE, LAT, MAC, PEM, PER, PSP, SAN, SMT, SNO, U = Value

  def fromString(s: String): Surface = s match {
    case "ASP" => ASP
    case "BIT" => BIT
    case "BRI" => BRI
    case "CLA" => CLA
    case "COM" => COM
    case "CON" => CON
    case "COP" => COP
    case "COR" => COR
    case "GRE" => GRE
    case "GRS" => GRS
    case "GVL" => GVL
    case "ICE" => ICE
    case "LAT" => LAT
    case "MAC" => MAC
    case "PEM" => PEM
    case "PER" => PER
    case "PSP" => PSP
    case "SAN" => SAN
    case "SMT" => SMT
    case "SNO" => SNO
    case "U"   => U
    case _ => throw new RuntimeException(s"cannot convert $s to Surface") // FIXME
  }
}
