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
    airportCallbacks = []
    runwayCallbacks = []

    styles = {
      airports: {
        predef: new ol.style.Style({
          image: new ol.style.Circle({
            fill: new ol.style.Fill({
              color: 'rgba(127, 255, 127, 0.5)'
            })
            stroke: new ol.style.Stroke({
              color: 'rgba(20, 180, 20, 0.75)'
              width: 2
            })
            radius: 8
          })
        })
        highlight: new ol.style.Style({
          image: new ol.style.Circle({
            fill: new ol.style.Fill({
              color: 'rgba(90, 255, 90, 0.75)'
            })
            stroke: new ol.style.Stroke({
              color: 'rgba(0, 180, 0, 0.75)'
              width: 2
            })
            radius: 12
          })
          zIndex: 2
        })
        selected: new ol.style.Style({
          image: new ol.style.Circle({
            fill: new ol.style.Fill({
              color: 'rgba(255, 180, 25, 0.8)'
            })
            stroke: new ol.style.Stroke({
              color: 'rgba(180, 90, 0, 0.8)'
              width: 2
            })
            radius: 12
          })
          zIndex: 1
        })
      }
      runways: {
        predef: new ol.style.Style({
          image: new ol.style.Circle({
            fill: new ol.style.Fill({
              color: 'rgba(127, 127, 255, 0.5)'
            })
            stroke: new ol.style.Stroke({
              color: 'rgba(20, 20, 180, 0.75)'
              width: 2
            })
            radius: 8
          })
        })
        highlight: new ol.style.Style({
          image: new ol.style.Circle({
            fill: new ol.style.Fill({
              color: 'rgba(90, 90, 255, 0.75)'
            })
            stroke: new ol.style.Stroke({
              color: 'rgba(0, 0, 180, 0.75)'
              width: 2
            })
            radius: 12
          })
          zIndex: 2
        })
        selected: new ol.style.Style({
          image: new ol.style.Circle({
            fill: new ol.style.Fill({
              color: 'rgba(25, 255, 180, 0.8)'
            })
            stroke: new ol.style.Stroke({
              color: 'rgba(0, 180, 90, 0.8)'
              width: 2
            })
            radius: 12
          })
          zIndex: 1
        })
      }
    }

    osmTiles = new ol.layer.Tile({
      source: new ol.source.OSM()
    })

    geoJSON = new ol.format.GeoJSON()

    airportsSource = new ol.source.Vector({
      format: geoJSON
    })

    runwaysSource = new ol.source.Vector({
      format: geoJSON
    })

    airportsLayer = new ol.layer.Vector({
      id: 'airports'
      source: airportsSource
      style: styles.airports.predef
    })

    runwaysLayer = new ol.layer.Vector({
      id: 'runways'
      source: runwaysSource
      style: styles.runways.predef
    })

    view = new ol.View({
      projection: 'EPSG:4326'
      center: [5.37437083333, 52.14307022093594] # center of NL airports extent
      zoom: 5
      minZoom: 1
      maxZoom: 20
    })

    hoverAirportInteraction = new ol.interaction.Select({
      condition: ol.events.condition.pointerMove
      layers: (layer) -> layer.get('id') == 'airports'
      style: [styles.airports.highlight]
    })

    selectAirportInteraction = new ol.interaction.Select({
      layers: (layer) -> layer.get('id') == 'airports'
      style: [styles.airports.selected]
    })

    hoverRunwayInteraction = new ol.interaction.Select({
      condition: ol.events.condition.pointerMove
      layers: (layer) -> layer.get('id') == 'runways'
      style: [styles.runways.highlight]
    })

    selectRunwayInteraction = new ol.interaction.Select({
      layers: (layer) -> layer.get('id') == 'runways'
      style: [styles.runways.selected]
    })

    map = new ol.Map({
      target: config.mapId
    })
    map.addLayer(osmTiles)
    map.addLayer(airportsLayer)
    map.addLayer(runwaysLayer)
    map.setView(view)

    map.getInteractions().extend([
      selectAirportInteraction
      hoverAirportInteraction
      selectRunwayInteraction
      hoverRunwayInteraction
    ])

    selectedAirport = selectAirportInteraction.getFeatures()
    selectedAirport.on('add', (event) ->
      feat = event.target.item(0)
      for cb in airportCallbacks
        airport = feat.getProperties()
        cb(airport)
    )

    selectedRunway = selectRunwayInteraction.getFeatures()
    selectedRunway.on('add', (event) ->
      feat = event.target.item(0)
      for cb in runwayCallbacks
        runway = feat.getProperties()
        cb(runway)
    )

    registerAirportCallback = (cb) ->
      airportCallbacks.push(cb)

    registerRunwayCallback = (cb) ->
      runwayCallbacks.push(cb)

    updateAirports = (airportsFeatures) ->
      airportsSource.clear()
      airportsSource.addFeatures(geoJSON.readFeatures(airportsFeatures))
      map.getView().fit(airportsSource.getExtent(), map.getSize())

    updateRunways = (runwaysFeatures) ->
      runwaysSource.clear()
      runwaysSource.addFeatures(geoJSON.readFeatures(runwaysFeatures))

    {
      updateAirports: updateAirports
      updateRunways: updateRunways
      onAirportSelected: registerAirportCallback
      onRunwaySelected: registerRunwayCallback
    }


##############################################################################
  ### Table Results ###
  #####################
  TableResults = (config) ->
    logger = config.logger
    target = config.target
    height = config.height
    extract = config.extract

    dataTable = $("##{target}").DataTable({
      scrollY:          height
      sScrollY:         height
      bScrollCollapse:  false
      scrollCollapse:   false
      paging:           false
    })

    update = (data) ->
      dataTable.rows.add(extract(data)).draw(true)

    {
      update: update
    }


##############################################################################
  ### Airports Results ###
  ########################
  AirportsResults = (config) ->
    TableResults({
      logger: config.logger
      target: 'airports-results-table'
      height: '41vh'
      extract: (airports) ->
        [
          a.id
          a.ident
          a.name
          a.airportType
          a.isoRegion
          a.municipality
        ] for a in (
          feat.properties for feat in airports
        )
    })


##############################################################################
  ### Runways Results ###
  #######################
  RunwaysResults = (config) ->
    TableResults({
      logger: config.logger
      target: 'runways-results-table'
      height: '19vh'
      extract: (runways) ->
        [
          r.id
          r.leIdent
          r.surface
          r.length
          r.width
          r.lighted
          r.closed
          r.leHeading
          r.leHelevation
        ] for r in (
          feat.properties for feat in runways
        )
    })


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
    runwaysResults = RunwaysResults({logger: logger})
    countriesResults = CountriesResults({logger: logger})

    map.onAirportSelected((airport) ->
      extraInfo = ->
        pre = if airport.municipality? then "in #{airport.municipality}" else "in"
        "#{pre} #{airport.isoRegion} (type: #{airport.airportType})"


      logger.info(
        """&uarr; [#{airport.ident}] #{airport.name} #{extraInfo()}"""
      )
    )

    map.onRunwaySelected((runway) ->
      logger.info(
        """&uarr; [#{runway.leIdent}]"""
      )

    refreshCountryResults = (countries) ->
      countriesResults.update(countries)

    refreshAirportsResults = (airports) ->
      airportsResults.update(airports.features)
      map.updateAirports(airports)

    refreshRunwaysResults = (runways) ->
      runwaysResults.update(runways.features)
      map.updateRunways(runways)
      

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
          refreshRunwaysResults(data.result.runways)

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
