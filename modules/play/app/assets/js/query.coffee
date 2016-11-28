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
        when 'in'     then 'text-success'
        when 'out'    then 'text-primary'
        when 'warn'   then 'text-warning'
        when 'err'    then 'text-danger'
        else ''

    _log = (level) -> (line) ->
      pClass = level2class(level)

      if logLines.length >= maxLogLines
        logLines.shift()
        logArea.children().first().remove()

      logLines.push(line)
      if level != 'trace' and level != 'debug'
        logArea.append("""<p class="#{pClass}">#{line}</p>""")

    for i in [0 .. maxLogLines]
      _log('__internal__')("&nbsp;")

    clear = () ->
      logLines = []
      logArea.empty()

    {
      trace:  _log('trace')
      debug:  _log('debug')
      info:   _log('info')
      out:    _log('out')
      in:     _log('in')
      warn:   _log('warn')
      err:    _log('err')
      clear:  clear
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
        center: [5.37437083333, 52.14307022093594] # center of NL airports extent
        zoom: 5
        minZoom: 1
        maxZoom: 20
      })
    })

    updateAirports = (airportsFeatures) ->
      airportsSource.clear()
      airportsSource.addFeatures( geoJSON.readFeatures(airportsFeatures))
      extent = airportsSource.getExtent()

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
      scollY:         "75vh"
      sScrollY:       "75vh"
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
        feat.properties for feat in airports
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
    queryForm = $('#query-form')
    queryInput = $('#query-input')
    querySubmit = $('#query-submit')
    selector = undefined

    lastQuery = undefined

    logger = config.logger
    socket = config.socket

    sendQuery = (queryStr) ->
      if queryStr != lastQuery
        if queryStr.length >= 2
          lastQuery = queryStr
          logger.out("&rarr; country-query: #{queryStr}")
          socket.send(JSON.stringify({
            type: 'country-query'
            query: queryStr
          }))

    # bind on queryForm submit event
    setup = (countries) ->
      selector = queryInput.selectize({
        maxItems: 1
        labelField: 'name'
        valueField: 'code'
        searchField: ['code', 'name', 'keywords']
        options: countries
        preload: false
        persist: false
      })
      selector = selector[0].selectize
      #selector.change(() ->
      selector.on('change', () ->
        sendQuery(queryInput.val())
      )
      queryForm.submit (event) ->
        event.preventDefault()
        sendQuery(queryInput.val())

      queryForm.removeClass('hidden')
      querySubmit.removeClass('hidden')

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
              logger.in("&larr; country-query-response/country-found: #{data.result.data.country.name}")
              refreshCountryResults([data.result.data.country])
            when 'no-matches'
              logger.warn("&larr; country-query-response/no-matches")
              refreshCountryResults([])
            when 'matching-countries'
              logger.info("&larr; country-query-response/matching-countries: #{data.result.data.length} countries")
              refreshCountryResults(data.result.data)

        when 'send-countries'
          logger.in("&larr; send-countries")
          query.setup(data.result.countries)

        when 'send-airports'
          logger.in("&larr; send-airports for #{data.result.country.name}")
          refreshAirportsResults(data.result.airports)

        when 'send-runways'
          logger.in("send-runways for: #{data.result.country.name}")

        else
          logger.warn("unknown message: #{data}")


    logger.info("Connecting to #{wsconfig.wsuri}…")
    socket = new WebSocket(wsuri)

    socket.onopen = (event) ->
      logger.info("Connected!")

      socket.onmessage = receive
      query = Query({
        logger: logger
        socket: socket
      })
      logger.out("&rarr; countries-list")
      socket.send(JSON.stringify({
        type: 'countries-list'
      }))

##############################################################################
  # Initialization #
  ##################

  logger = Logger({
    maxLogLines: 13
  })

  wsconfig = $('#ws-config').data()

  controller = SocketController({
    logger: logger
    wsuri: wsconfig.wsuri
  })
