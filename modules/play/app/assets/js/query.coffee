$ ->

  ### Utils ###
  renderBoolean = (bool) ->
    if bool
      """<span class="label label-success">&#x2714;</span>"""
    else
      """<span class="label label-danger">&#x2716;</span>"""

  fold = (value) -> (none) -> (somef) ->
    if value?
      somef(value)
    else
      none

  renderOption = (value, someTag, noneTag) ->
    if value? 
      if someTag?
        "<#{someTag}>#{value}</#{someTag}>"
      else
        "#{value}"
    else
      if noneTag?
        "<#{noneTag}>?</#{noneTag}>"
      else
        "?"

  renderLink = (link, text, alt) ->
    if link?
      """<a href="#{link}" target="_blank"">#{text}</a>"""
    else
      """#{alt}"""

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
    noNotify = false
    airportCallbacks = []
    runwayCallbacks = []

    # TODO: finish styles (airportType, runways(length/width, light, open)
    styles = {
      airports: {
        predef: new ol.style.Style({
          image: new ol.style.Circle({
            fill:   new ol.style.Fill(  {color: 'rgba(127, 255, 127, 0.5)' })
            stroke: new ol.style.Stroke({color: 'rgba(10,  30,  10,  0.75)', width: 2})
            radius: 8
          })
          zIndex: 1
        })
        small: new ol.style.Style({
          image: new ol.style.Circle({
            fill:   new ol.style.Fill(  {color: 'rgba(127, 255, 127, 0.5)' })
            stroke: new ol.style.Stroke({color: 'rgba(10,  30,  10,  0.75)', width: 2})
            radius: 4
          })
          zIndex: 2
        })
        medium: new ol.style.Style({
          image: new ol.style.Circle({
            fill:   new ol.style.Fill(  {color: 'rgba(127, 127, 127, 0.6)' })
            stroke: new ol.style.Stroke({color: 'rgba(10,  30,  10,  0.75)', width: 2})
            radius: 6
          })
          zIndex: 2
        })
        large: new ol.style.Style({
          image: new ol.style.Circle({
            fill:   new ol.style.Fill(  {color: 'rgba(255, 127, 127, 0.7)' })
            stroke: new ol.style.Stroke({color: 'rgba(10,  30,  10,  0.75)', width: 2})
            radius: 15
          })
          zIndex: 2
        })
        highlight: new ol.style.Style({
          image: new ol.style.Circle({
            fill:   new ol.style.Fill(  {color: 'rgba(90,  255, 90,  0.75)' })
            stroke: new ol.style.Stroke({color: 'rgba(0,   180, 0,   0.75)', width: 2})
            radius: 12
          })
          zIndex: 3
        })
        selected: new ol.style.Style({
          image: new ol.style.Circle({
            fill:   new ol.style.Fill(  {color: 'rgba(255, 180, 25,  0.8)' })
            stroke: new ol.style.Stroke({color: 'rgba(180, 90,  0,   0.8)', width: 2})
            radius: 12
          })
          zIndex: 4
        })
      }
      runways: {
        predef: new ol.style.Style({
          image: new ol.style.RegularShape({
            fill: new ol.style.Fill(    {color: 'rgba(127, 127, 255, 0.5)'})
            stroke: new ol.style.Stroke({color: 'rgba(20, 20, 180, 0.75)', width: 2})
            points: 4
            radius: 8
            angle: Math.PI / 4
          })
        })
        highlight: new ol.style.Style({
          image: new ol.style.RegularShape({
            fill: new ol.style.Fill(    {color: 'rgba(90, 90, 255, 0.75)'})
            stroke: new ol.style.Stroke({color: 'rgba(0, 0, 180, 0.75)', width: 2})
            points: 4
            radius: 12
            angle: Math.Pi / 4
          })
          zIndex: 3
        })
        selected: new ol.style.Style({
          image: new ol.style.RegularShape({
            fill: new ol.style.Fill(    {color: 'rgba(25, 255, 180, 0.8)'})
            stroke: new ol.style.Stroke({color: 'rgba(0, 180, 90, 0.8)', width: 2})
            points: 4
            radius: 12
            angle: Math.PI / 4
          })
          zIndex: 4
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
      style: (feat, resolution) ->
        airport = feat.getProperties()
        switch(airport.airportType)
          when 'small_airport' then styles.airports.small
          when 'medium_airport' then styles.airports.medium
          when 'large_airport' then styles.airports.large
          else styles.airports.predef
    })

    runwaysLayer = new ol.layer.Vector({
      id: 'runways'
      source: runwaysSource
      style: (feat, resolution) ->
        #runway = feat.getProperties()
        styles.runway.predef
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

    popup = new ol.Overlay({
      element: $('#query-info-box')[0]
    })

    map = new ol.Map({
      target: config.mapId
    })
    map.addLayer(osmTiles)
    map.addLayer(airportsLayer)
    map.addLayer(runwaysLayer)
    map.addOverlay(popup)
    map.setView(view)

    map.getInteractions().extend([
      hoverRunwayInteraction
      hoverAirportInteraction
      selectRunwayInteraction
      selectAirportInteraction
    ])

    showPopup = (content) -> (feat, coords) ->
      element = $(popup.getElement())
      element.popover('destroy')
      popup.setPosition(coords)
      element.popover({
        placement:  'right'
        animation:  true
        html:       true
        content:    content(feat, coords)
      })
      element.popover('show')
      #$('.popover a.close').click(() ->
        #element.popover('destroy')
      #)

    ### TODO: move this big chunk to somewhere else ###
    airportContent = (feat, coords) ->
      a = feat.getProperties()
      position = ol.coordinate.toStringHDMS(coords)
      strong = (value) -> fold(value)('?')((v) -> "<strong>#{v}</strong>")
      elevation = fold(a.elevation)('?')((v) -> "<strong>#{v}</strong> (ft)")
      """
        <ul class="list-group box-shadow">
          <li class="list-group-item list-group-item-info"><strong>#{a.name}</strong> <span class="badge">#{a.ident}</span></li>
          <li class="list-group-item">Type: <strong>#{a.airportType}</strong></li>
          <li class="list-group-item">Region: #{strong(a.isoRegion)}</li>
          <li class="list-group-item">Municipality: #{strong(a.municipality)}</li>
          <li class="list-group-item">Position: <strong><span class="text-primary">#{position}</span></strong></li>
          <li class="list-group-item">Elevation: #{elevation}</li>
          <li class="list-group-item">Scheduled Service: #{renderBoolean(a.scheduledService)}</li>
          <li class="list-group-item">
            GPS: #{renderOption(a.gpsCode, 'strong')} |
            IATA: #{renderOption(a.iataCode, 'strong')} |
            Local: #{renderOption(a.localCode, 'strong')}
          </li>
          <li class="list-group-item">#{renderLink(a.homeLink, 'Home: &rArr;', 'Home: ?')}</li>
          <li class="list-group-item">#{renderLink(a.wikipediaLink, 'Wikipedia: &rArr;', 'Wikipedia: ?')}</li>
          <li  class="list-group-item">Keywords: #{renderOption(a.keywords)}</li>
        </div>
      """

    showAirportPopup = showPopup(airportContent)

    panTo = (location) ->
      pan = ol.animation.pan({
        source: view.getCenter()
      })
      map.beforeRender(pan)
      view.setCenter(location)

    selectedAirport = selectAirportInteraction.getFeatures()
    selectedAirport.on('add', (event) ->
      feat = event.target.item(0)
      coords = feat.getGeometry().getCoordinates()
      showAirportPopup(feat, coords)
      panTo(coords)
      airport = feat.getProperties()
      if noNotify == false
        for cb in airportCallbacks
          cb(airport)
    )
    selectedAirport.on('remove', (event) ->
      element = $(popup.getElement())
      element.popover('destroy')
    )

    selectAirport = (id) ->
      selectedAirport.clear()
      feat = airportsSource.getFeatureById(id)
      noNotify = true
      selectedAirport.push(feat)
      noNotify = false

    selectedRunway = selectRunwayInteraction.getFeatures()
    selectedRunway.on('add', (event) ->
      feat = event.target.item(0)
      runway = feat.getProperties()
      if noNotify == false
        for cb in runwayCallbacks
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

    updateRunways = (runways) ->
      features = {
        type: 'FeatureCollection'
        crs: {
          type: 'name'
          properties: {
            name: 'EPSG:4326'
          }
        }
        features: runways.filter((r) -> r.lePosition? or r.hePosition).map((r) ->
          coords = if r.lePosition? then r.lePosition else r.hePosition
          {
            id:     r.id
            type:   'Feature'
            geometry: {
              type:         'Point'
              coordinates:  coords
            }
            properties: r
          }
        )
      }
      runwaysSource.clear()
      runwaysSource.addFeatures(geoJSON.readFeatures(features))

    {
      updateAirports: updateAirports
      updateRunways: updateRunways
      onAirportSelected: registerAirportCallback
      onRunwaySelected: registerRunwayCallback
      selectAirport: selectAirport
    }


##############################################################################
  ### Table Results ###
  #####################
  TableResults = (config) ->
    logger = config.logger
    target = config.target
    height = config.height
    rowId = config.rowId
    columns = config.columns

    noNotify = false
    selectCallbacks = []
    unselectCallbacks = []

    dataTable = $("##{target}").DataTable({
      scrollY:          height
      sScrollY:         height
      bScrollCollapse:  false
      scrollCollapse:   false
      paging:           false
      scroller:         true
      rowId:            rowId
      columns:          columns
    })

    getSelectedData = () ->
      idx = dataTable.row('.selected').index()
      data = dataTable.row(idx).data()
      data

    notifySelected = (data) ->
      if noNotify == false
        for cb in selectCallbacks
          cb(data)

    notifyUnselected = (data) ->
      if noNotify == false
        for cb in unselectCallbacks
          cb(data)

    unselect = () ->
      dataTable.$('tr.selected').each(() ->
        self = $(this)
        data = getSelectedData()
        self.removeClass('selected active')
        notifyUnselected(data)
      )

    select = (id) ->
      noNotify = true
      unselect()
      row = dataTable.row("##{id}")
      data = row.data()
      $("##{id}").addClass('selected active')
      $('.dataTables_scrollBody').scrollTo("##{id}")
      data = dataTable.row("##{id}").data()
      noNotify = false

    $("##{config.target} tbody").on('click', 'tr', () ->
      elem = $(this)
      if elem.hasClass('selected')
        # already selected -> unselect
        data = getSelectedData()
        elem.removeClass('selected active')
        notifyUnselected(data)
      else
        # not the same row -> unselect other, then select this
        unselect()
        elem.addClass('selected active')
        data = getSelectedData()
        notifySelected(data)
    )

    update = (data) ->
      dataTable.rows.add(data).draw(true)

    search = (query) ->
      dataTable.search(query).draw(true)

    {
      update: update
      selectedData: getSelectedData
      onSelectRow:  (cb) -> selectCallbacks.push(cb)
      onUnselectRow: (cb) -> unselectCallbacks.push(cb)
      search: search
      select: select
      unselect: () ->
        noNotify = true
        unselect
        noNotify = false
    }


##############################################################################
  ### Airports Results ###
  ########################
  AirportsResults = (config) ->
    idFn = (data) -> "airport_id_#{data.id}"
    tableResults = TableResults({
      logger: config.logger
      target: 'airports-results-table'
      height: '33vh'
      select: true
      rowId: idFn
      columns: [
        { data: 'id' }
        { data: 'ident' }
        { data: 'name' }
        { data: 'airportType' }
        { data: 'isoRegion' }
        { data: 'municipality' }
      ]
    })

    $.extend(tableResults, {
      selectAirport: (id) -> tableResults.select(idFn(id))
    })


##############################################################################
  ### Runways Results ###
  #######################
  RunwaysResults = (config) ->
    idFn = (data) -> "runway_id_#{data.id}"
    tableResults = TableResults({
      logger: config.logger
      target: 'runways-results-table'
      height: '22vh'
      rowId: idFn
      columns: [
        { data: 'airportRef' }
        { data: 'id' }
        { data: 'leIdent' }
        { data: 'surface' }
        { data: 'length' }
        { data: 'width' }
        { data: 'lighted', render: renderBoolean }
        { data: 'closed', render: (b) -> renderBoolean(! b) }
        { data: 'leHeading' }
        { data: 'leElevation' }
        { data: 'airportRef', visible: false }
      ]
    })
    $.extend(tableResults, {
      selectRunway: (id) -> tableResults.select(idFn(id))
    })


# FIXME
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

    logAirportSelected = (airport) ->
      extraInfo = ->
        pre = if airport.municipality? then "in #{airport.municipality}" else "in"
        "#{pre} #{airport.isoRegion} (type: #{airport.airportType})"

      logger.info(
        """&uarr; [#{airport.ident}] #{airport.name} #{extraInfo()}"""
      )

    airportsResults.onSelectRow((airport) ->
      logAirportSelected(airport)
      map.selectAirport(airport.id)
      runwaysResults.search(airport.id)
    )

    map.onAirportSelected((airport) ->
      logAirportSelected(airport)
      airportsResults.selectAirport(airport)
      runwaysResults.search(airport.id)
    )

    map.onRunwaySelected((runway) ->
      logger.info(
        """&uarr; [#{runway.leIdent}]"""
      )
    )

    refreshCountryResults = (countries) ->
      countriesResults.update(countries)

    refreshAirportsResults = (airports) ->
      airportsResults.update(feat.properties for feat in airports.features)
      map.updateAirports(airports)

    refreshRunwaysResults = (runways) ->
      runwaysResults.update(runways)
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
          logger.in("&larr; send-runways for: #{data.result.country.name}")
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
    maxLogLines: 14
  })

  wsconfig = $('#ws-config').data()

  controller = SocketController({
    logger: logger
    wsuri: wsconfig.wsuri
  })
