### Controller(config)
# requires:
#   * js/include/logger.js
#   * js/include/urls.js
#   * js/include/map.js
#   * js/include/table_results.js
#   * js/include/query.js
#
# <- config
#   logger: Logger instance
#
###
Controller = (config) ->
  logger = config.logger

  query             = Query(config)
  airportsResults   = AirportsResults(config)
  runwaysResults    = RunwaysResults(config)
  map               = Map(config)

  fetchAirports = (countryCode) ->
    url = urls.airports(countryCode, 'geojson')
    logger.out(url)
    $.ajax(url, {
      type: 'GET'

      error: (jqXHR, status, error) ->
        logger.err(url, status, error)

      success: (data, status, jqXHR) ->
        logger.in(url)
        airportsResults.updateAirports({
          country: data.country
          airports: feat.properties for feat in data.airports.features
        })
        map.updateAirports(data.airports)
    })

  fetchRunways = (countryCode) ->
    url = urls.runways(countryCode)
    logger.out(url)
    $.ajax(url, {
      type: 'GET',

      error: (jqXHR, status, error) ->
        logger.err(url, status, error)

      success: (data, status, jqXHR) ->
        logger.in(url)
        runwaysResults.updateRunways(data)
        map.updateRunways(data.runways)
    })


  ### Country selected ###
  query.beforeRequest(() ->
    map.unselect()
  )
  query.onCountryResults((country) ->
    fetchAirports(country.code)
    fetchRunways(country.code)
  )

  airportSelected = (airport) ->
    logger.info(render.airport.logLine(airport))
    runwaysResults.unselect()
    runwaysResults.search(airport.ident)

  runwaySelected = (runway) ->
    logLine = render.runway.logLine(runway)
    if runway.lePosition? or runway.hePosition?
      logger.info(logLine)
    else
      logger.warn("#{logLine}: runway position not found!")
    airportsResults.unselect()

  map
    .onAirportSelected((airport) ->
      airportSelected(airport)
      airportsResults.selectAirport(airport)
    )
    .onRunwaySelected((runway) ->
      runwaySelected(runway)
      runwaysResults.selectRunway(runway)
    )
    .onAirportUnselected((airport) ->
      airportsResults.unselect()
    )
    .onRunwayUnselected((runway) ->
      runwaysResults.unselect()
    )

  airportsResults
    .onSelectRow((airport) ->
      airportSelected(airport)
      map.selectAirport(airport)
    )
    .onUnselectRow((airport) ->
      map.unselect()
    )

  runwaysResults
    .onSelectRow((runway) ->
      runwaySelected(runway)
      map.selectRunway(runway)
    )
    .onUnselectRow((runway) ->
      map.unselect()
    )

### Initialization ###
$ -> 
  logger = Logger({maxLogLines: 15})
  controller = Controller({logger: logger})
