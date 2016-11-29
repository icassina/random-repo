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

  airplane = "&#x2708;"
  upArrow = "&#x2b06;"

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
        when 'debug'  then 'text-muted'
        when 'info'   then 'text-warning'
        when 'in'     then 'text-primary'
        when 'out'    then 'text-success'
        when 'warn'   then 'text-danger'
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

    mapHoverCode = $('#map-hover-code')
    mapHoverInfo = $('#map-hover-info')

    mkColor = (alpha) -> (e) -> "rgba(#{e.r}, #{e.g}, #{e.b}, #{alpha})"

    mkShape = {
      circle:   (def) -> new ol.style.Circle(def)
      triangle: (def) -> new ol.style.RegularShape($.extend(def, {points: 3, angle: 0, rotation: Math.PI / 4}))
      square:   (def) -> new ol.style.RegularShape($.extend(def, {points: 4, angle: Math.PI / 4}))
      plus:     (def) -> new ol.style.RegularShape($.extend(def, {points: 4, angle: 0, radius2: 0}))
      cross:    (def) -> new ol.style.RegularShape($.extend(def, {points: 4, angle: Math.PI / 4, radius2: 0}))
      star:     (def) -> new ol.style.RegularShape($.extend(def, {points: 5, angle: 0, radius2: (def.radius / 2)}))
    }


    mkStyle = (e) -> (type) ->
      switch(type)
          when 'highlight'
            fill    = new ol.style.Fill({color: mkColor(0.2)(e.color)})
            stroke  = new ol.style.Stroke({color: mkColor(0.9)(e.color), width: 4})
            shape = mkShape[e.shape]({fill: fill, stroke: stroke, radius: (1.8 * e.radius)})
            new ol.style.Style({image: shape, zIndex: (e.index+40)})
          when 'selected'
            fill    = new ol.style.Fill({color: mkColor(0.8)(e.color)})
            stroke  = new ol.style.Stroke({color: mkColor(1.0)(e.color), width: 4})
            shape = mkShape[e.shape]({fill: fill, stroke: stroke, radius: (1.4 * e.radius)})
            new ol.style.Style({image: shape, zIndex: (e.index+20)})
          else
            fill    = new ol.style.Fill({color: mkColor(0.6)(e.color)})
            stroke  = new ol.style.Stroke({color: mkColor(0.8)(e.color), width: 2})
            shape = mkShape[e.shape]({fill: fill, stroke: stroke, radius: e.radius})
            new ol.style.Style({image: shape, zIndex: e.index})

    buildStyles = (stylesDef) ->
      result = {}
      for section, entries of stylesDef
        result[section] = {}
        for subsection, entry of entries
          result[section][subsection] = {
            predef:     { zoom_0: mkStyle(entry)('predef') }
            highlight:  { zoom_0: mkStyle(entry)('highlight') }
            selected:   { zoom_0: mkStyle(entry)('selected') }
          }

      result
      
    stylesDef = {
      airports: {
        large_airport:  { color: {r: 217, g: 100, b:  89}, radius: 18, shape: 'circle',   index: 9 }
        medium_airport: { color: {r: 242, g: 174, b: 114}, radius: 14, shape: 'circle',   index: 8 }
        small_airport:  { color: {r: 242, g: 227, b: 148}, radius: 10, shape: 'circle',   index: 7 }
        seaplane_base:  { color: {r:  82, g: 118, b: 183}, radius:  8, shape: 'circle',   index: 6 }
        balloonport:    { color: {r: 172, g:  83, b: 147}, radius:  8, shape: 'circle',   index: 5 }
        heliport:       { color: {r: 140, g:  70, b:  70}, radius:  8, shape: 'plus',     index: 5 }
        closed:         { color: {r:  50, g:  50, b:  50}, radius:  6, shape: 'cross',    index: 4 }
      }
      runways: {
        lighted:        { color: {r:  50, g: 150, b:  70}, radius:  5, shape: 'square',   index: 3 }
        notLighted:     { color: {r:  50, g:  80, b: 180}, radius:  4, shape: 'triangle', index: 2 }
        closed:         { color: {r:  50, g:  50, b:  50}, radius:  3, shape: 'cross',    index: 1 }
      }
    }

    featFold = (feat) -> (onAirport, onRunway) ->
      switch (feat.get('type'))
        when 'airport' then onAirport(feat)
        when 'runway' then onRunway(feat)

    runwayStyleKey = (feat) ->
      closed = feat.get('closed')
      lighted = feat.get('lighted')
      if closed then 'closed' else if lighted then 'lighted' else 'notLighted'

    airportStyleKey = (feat) ->
      feat.get('airportType')

    styles = buildStyles(stylesDef)

    runwayStyle = (feat) ->
      styles.runways[runwayStyleKey(feat)]

    airportStyle = (feat) ->
      styles.airports[airportStyleKey(feat)]

    featStyle = (feat) ->
      featFold(feat)(
        (a) -> airportStyle(feat),
        (r) -> runwayStyle(feat)
      )

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
        #console.log('airport style function')
        #console.log(resolution)
        [airportStyle(feat).predef.zoom_0]
        #zoomKey = "zoom_#{zoom}"
        #styleBase = airportStyle(feat).predef
        #if zoomKey of styleBase
          #[styleBase[zoomKey]]
        #else
          #original = styleBase["zoom_0"]

    })

    runwaysLayer = new ol.layer.Vector({
      id: 'runways'
      source: runwaysSource
      style: (feat, resolution) ->
        [runwayStyle(feat).predef.zoom_0]
    })

    view = new ol.View({
      projection: 'EPSG:4326'
      center: [5.37437083333, 52.14307022093594] # center of NL airports extent
      zoom: 5
      minZoom: 1
      maxZoom: 20
    })

    featRadius = (resolution) ->
      console.log('zoom')
      zoom = view.getZoom()
      console.log(zoom)

      (feat) ->
        styleDef = featFold(feat)(
          (a) -> styleDefs.airports[airportStyleKey(feat)].predef.zoom_0,
          (r) -> stylesDef.runways[runwayStyleKey(feat)].predef.zoom_0
        )
        original = styleDef.radius
      

    view.on('change:resolution', (event) ->
      console.log('change res')
      #r = featRadius(event.target.get(event.key))
    )

    interactiveLayers = (layer) ->
      layerId = layer.get('id')
      layerId == 'airports' or layerId == 'runways'

    selectInteraction = new ol.interaction.Select({
      layers: interactiveLayers
      style: (feat, resolution) ->
        condition: ol.events.condition.pointerMove
        [featStyle(feat).selected.zoom_0]
    })

    hoverInteraction = new ol.interaction.Select({
      condition: ol.events.condition.pointerMove
      layers: interactiveLayers
      style: (feat, resolution) ->
        console.log(resolution)
        [featStyle(feat).highlight.zoom_0]
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
      hoverInteraction
      selectInteraction
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

    classForAirportType = (airportType) ->
      switch(airportType)
        when 'small_airport'  then 'warning'
        when 'medium_airport' then 'warning'
        when 'large_airport'  then 'danger'
        when 'baloonport'     then 'info'
        when 'seaplane_base'  then 'primary'
        when 'heliport'       then 'success'
        when 'closed'         then 'default'
        else 'default'

    #classForRunway = (runway) ->
      #if runway.closed
        #'danger'
      #else
        #if runway.lighted
          #'success'
        #else
          #'warning'

    ### TODO: move this big chunk to somewhere else ###
    airportContent = (feat, coords) ->
      a = feat.getProperties()
      position = ol.coordinate.toStringHDMS(coords)
      strong = (value) -> fold(value)('?')((v) -> "<strong>#{v}</strong>")
      elevation = fold(a.elevation)('?')((v) -> "<strong>#{v}</strong> (ft)")
      """
        <ul class="list-group box-shadow">
          <li class="list-group-item list-group-item-info">
            <span class="feature-name">#{airplane} #{a.name}</span>
            <span class="feature-code pull-right label label-default">#{a.ident}</span>
          </li>
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
    #showRunwayPopup = showPopup(runwayContent)

    hideHoverInfo = () ->
      mapHoverCode.html('&nbsp;')
      mapHoverCode.attr('class', 'pull-right label label-default')
      mapHoverInfo.html('&nbsp;')

    showAiportHoverInfo = (data) ->
      mapHoverCode.html("""#{data.ident}""")
      mapHoverInfo.html("""#{data.name}""")

    showRunwayHoverInfo = (data) ->
      mapHoverCode.removeClass('hidden')
      mapHoverCode.html("""#{renderBoolean(data.lighted)} #{renderBoolean(! data.closed)}""")
      mapHoverInfo.html("""#{data.leIdent} #{data.surface}""")

    panTo = (location) ->
      pan = ol.animation.pan({
        source: view.getCenter()
      })
      map.beforeRender(pan)
      view.setCenter(location)

    selected = selectInteraction.getFeatures()
    selected.on('add', (event) ->
      feat = event.target.item(0)
      coords = feat.getGeometry().getCoordinates()
      data = feat.getProperties()
      panTo(coords)
      switch (data.type)
        when 'airport'
          showAirportPopup(feat, coords)
          if noNotify == false
            for cb in airportCallbacks
              cb(data)
        when 'runway'
          #showRunwayPopup(feat, coords)
          if noNotify == false
            for cb in runwayCallbacks
              cb(data)
    )
    selected.on('remove', (event) ->
      element = $(popup.getElement())
      element.popover('destroy')
    )

    select = (type) -> (id) ->
      selected.clear()
      feat = switch (type)
        when 'airport' then airportsSource.getFeatureById(id)
        when 'runway' then runwaysSource.getFeatureById(id)
      noNotify = true
      selected.push(feat)
      noNotify = false

    highlighted = hoverInteraction.getFeatures()
    highlighted.on('add', (event) ->
      feat = event.target.item(0)
      data = feat.getProperties()
      dataType = feat.get('type')
      switch (data.type)
        when 'airport' then showAiportHoverInfo(data)
        when 'runway'  then showRunwayHoverInfo(data)
    )
    highlighted.on('remove', hideHoverInfo)
      
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

    $('#map-hover-container').removeClass('hidden')

    {
      updateAirports: updateAirports
      updateRunways: updateRunways
      onAirportSelected: registerAirportCallback
      onRunwaySelected: registerRunwayCallback
      selectAirport: select('airport')
      selectRunway: select('runway')
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
      dataTable.clear()
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
      selectAirport: (airport) -> tableResults.select(idFn(airport))
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
      ]
    })
    selectRunway = (runway) ->
      tableResults.select(idFn(runway))

    $.extend(tableResults, {
      selectRunway: selectRunway
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
        """#{airplane} [#{airport.ident}] #{airport.name} #{extraInfo()}"""
      )

    logRunwaySelected = (runway) ->
      length = fold(runway.length)('')((l) -> ", length: #{l}")
      width = fold(runway.width)('')((w) -> ", width: #{w}")
      lighted = ", lighted: #{renderBoolean(runway.lighted)}"
      open = ", open: #{renderBoolean(! runway.open)}"

      logger.info("""
        #{upArrow} [#{runway.leIdent}] #{runway.surface}#{length}#{width}#{lighted}#{open}
      """)

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

    runwaysResults.onSelectRow((runway) ->
      logRunwaySelected(runway)
      map.selectRunway(runway.id)
    )

    map.onRunwaySelected((runway) ->
      runwaysResults.selectRunway(runway)
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


    logger.debug("Connecting to #{wsconfig.wsuri}…")
    socket = new WebSocket(wsuri)

    socket.onopen = (event) ->
      logger.debug("Connected!")

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
