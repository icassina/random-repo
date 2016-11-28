$ ->

##############################################################################
  ### Logger ###
  ##############
  Logger = (config) ->
    logArea = $('#query-log-area')
    maxLogLines = config.maxLogLines
    logLines = []

    level2class = (lvl) ->
      switch (lvl)
        when 'trace'  then 'text-muted'
        when 'debug'  then ''
        when 'info'   then 'text-info'
        when 'okay'   then 'text-success'
        when 'warn'   then 'text-warning'
        when 'err'    then 'text-danger'
        else ''

    log = (level) -> (line) ->
      pClass = level2class(level)

      if logLines >= maxLogLines
        logLines.shift()
        logArea.children.first.remove()

      logLines.push(line)
      console.log("#{level} | #{line}")
      logArea.append("""<p class="#{pClass}">#{line}</p>""")

    clear = () ->
      logLines = []
      logArea.empty()

    {
      trace: log('trace')
      debug: log('debug')
      info:  log('info')
      okay:  log('okay')
      warn:  log('warn')
      err:   log('err')
      clear: clear
    }

##############################################################################
  ### Map ###
  ###########
  MyMap = (config) ->
    fill = new ol.style.Fill({
      color: 'rgba(255, 25, 25, 0.8)'
    })
    stroke = new ol.style.Stroke({
      color: '#000000'
      width: 2
    })
    styles = {
      predef: new ol.style.Style({
        image: new ol.style.Circle({
          fill: fill
          stroke: stroke
          radius: 5
        })
      })
    }

    geoJSON = new ol.format.GeoJSON()

    airportsSource = new ol.source.Vector({
      format: geoJSON
    })

    map = new ol.Map({
      target: config.mapId
      layers: [
        new ol.layer.Tile({
          source: new ol.source.OSM()
        }),
        new ol.layer.Vector({
          source: airportsSource
          style: styles.predef
        })
      ],
      renderer: 'canvas',
      view: new ol.View({
        projection: 'EPSG:4326'
        center: ol.proj.fromLonLat([0, 0])
        zoom: 4
      })
    })

    updateAirports = (airportsFeatures) ->
      airportsSource.clear()
      airportsSource.addFeatures( geoJSON.readFeatures(airportsFeatures))
      map.getView().fit(airportsSource.getExtent(), map.getSize())

    {
      updateAirports: updateAirports
    }


##############################################################################
  ### Airports Results ###
  ########################
  AirportsResults = (config) ->
    logger = config.logger

    ### DataTable ###
    dataTable = $('#airports-results-table').DataTable( {
      scollY:         "50vh"
      sScrollY:       "50vh"
      scrollCollapse: true
      paging:         false
    })

    airportsColumns = (airports) ->
      [
        a.id,
        a.ident,
        a.name,
        a.airportType,
        a.isoRegion,
        a.municipality
      ] for a in (
        feat.properties.data for feat in airports
      )

    update = (airports) ->
      dataTable.rows.add(
        airportsColumns(airports)
      ).draw(true)

    {
      update: update
    }


##############################################################################
  ### Countries Results ###
  #########################
  CountriesResults = (config) ->
    logger = config.logger

    selectedCountryNode = $('#airports-results-title-extra')

    countriesColumns = (countries) ->
      [
        c.id,
        c.code,
        c.name,
        c.continent,
        c.wikipediaLink,
        c.keywords
      ] for c in countries

    update = (countries) ->
      switch(countries.length)
        when 0
          selectedCountryNode.empty()
        when 1
          country = countries[0]
          selectedCountryNode.html("""
            in #{country.name} [#{country.code}/#{country.continent}]
          """)
        else
          selectedCountryNode.html("""
            (query matches #{countries.length} countries)
          """)

    {
      update: update
    }

##############################################################################
  ### Query ###
  #############
  Query = (config) ->
    queryInput = $('#query-input')
    queryForm = $('#query-form')
    querySubmit = $('#query-submit')

    lastQuery = undefined

    logger = config.logger
    socket = config.socket

    sendQuery = (queryStr) ->
      if queryStr != lastQuery
        if queryStr.length >= 2
          lastQuery = queryStr
          logger.okay("&rarr; country-query: #{queryStr}")
          socket.send(JSON.stringify({
            type: 'country-query'
            query: queryStr
          }))

    # bind on queryForm submit event
    setup = () ->
      queryForm.submit (event) ->
        event.preventDefault()
        sendQuery(queryInput.val())

    {
      setup: setup
      sendQuery: sendQuery
    }


##############################################################################
  ### Socket Controller ###
  #########################
  SocketController = (config) ->
    wsuri = config.wsuri
    logger = config.logger

    socket = undefined 
    query = undefined

    map = MyMap({
      mapId: 'map'
      logger: logger
    })
    airportsResults = AirportsResults({logger: logger})
    countriesResults = CountriesResults({logger: logger})

    refreshCountryResults = (countries) ->
      countriesResults.update(countries)

    refreshAirportsResults = (airports) ->
      airportsResults.update(airports.features)
      map.updateAirports(airports)
      

    # receive function
    receive = (msg) ->
      data = JSON.parse(msg.data)
      switch (data.type)
        when 'error'
          logger.err(data.result)

        when 'country-query-response'
          switch (data.result.type)
            when 'country-found'
              logger.okay("&larr; country-query-response/country-found: #{data.result.data.country.data.name}")
              refreshCountryResults([data.result.data.country.data])
            when 'no-matches'
              logger.warn("&larr; country-query-response/no-matches")
              refreshCountryResults([])
            when 'matching-countries'
              logger.info("&larr; country-query-response/matching-countries: #{data.result.data.length} countries")
              refreshCountryResults(data.result.data)

        when 'send-airports'
          logger.okay("&larr; send-airports for #{data.result.country.data.name}")
          refreshAirportsResults(data.result.airports)

        when 'send-runways'
          logger.okay("send-runways for: #{data.result.country.data.name}")

        else
          logger.warn("unknown message: #{data}")


    logger.info("Connecting to #{wsconfig.wsuri}…")
    socket = new WebSocket(wsuri)

    socket.onopen = (event) ->
      logger.okay("Connected!")

      socket.onmessage = receive
      query = Query({
        logger: logger
        socket: socket
      })
      query.setup()

##############################################################################
  # Initialization #
  ##################

  logger = Logger({
    maxLogLines: 16
  })

  wsconfig = $('#ws-config').data()

  controller = SocketController({
    logger: logger
    wsuri: wsconfig.wsuri
  })

  ### interactive nodes ###
  countriesResultsNode = $('#query-countries-results')

  ### update country TODO ###
  refreshCountryResults = (matchingCountries) ->
    countriesResultsNode.empty()
    for country in matchingCountries
      countriesResultsNode.append("""
          <li>#{country.data.name} (#{country.data.code} / #{country.data.continent})</li>
        """)
