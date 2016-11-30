$ ->

  countriesUrl    = '/api/countries'
  countryBaseUrl  = '/api/country'
  airportsBaseUrl = '/api/airports'
  runwaysBaseUrl  = '/api/runways'

  countryUrl = (countryCode) ->
    "#{countryBaseUrl}/#{countryCode}"

  airportsUrl = (countryCode, suffix) ->
    extra = if suffix? then "/#{suffix}" else ""
    "#{airportsBaseUrl}/#{countryCode}#{extra}"

  runwaysUrl = (countryCode, suffix) ->
    extra = if suffix? then "/#{suffix}" else ""
    "#{runwaysBaseUrl}/#{countryCode}#{extra}"

  ### constants ###
  sym = {
    airplane: '&#x2708;'
    upArrow:  '&#x2b06;'
    rArrow:   '&rarr;'
    lArrow:   '&larr;'
    emptySet: '&empty;'
    space:    '&nbsp;'
    true:     '&#x2714;'
    false:    '&#x2716;'
  }

  ### Utils ###
  foldOpt = (value) -> (none) -> (somef) ->
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
        "<#{noneTag}>#{sym.emptySet}</#{noneTag}>"
      else
        sym.emptySet

  renderLink = (link, text, alt) ->
    if link?
      """<a href="#{link}" target="_blank"">#{text}</a>"""
    else
      """#{alt}"""

  renderBoolean = (name) -> (bool) ->
    if bool
      """<span class="label label-success"><abbr title="#{name}: yes">#{sym.true}</abbr></span>"""
    else
      """<span class="label label-danger"><abbr title="#{name}: no">#{sym.false}</abbr></span>"""

  renderPosition = (coords) -> """<strong><span class="text-primary">#{ol.coordinate.toStringHDMS(coords)}</span></strong>"""

  renderPositionOpt = (p) -> foldOpt(p)(sym.emptySet)(renderPosition)

  renderFeetOpt = (f) -> foldOpt(f)(sym.emptySet)((v) -> """<strong>#{v}</strong> (ft)""")

  renderIdent = (runway) ->
    """#{renderOption(runway.leIdent, 'strong')} | #{renderOption(runway.heIdent, 'strong')}"""

  renderOpen = (runway) ->
    renderBoolean('Open')(! runway.closed)

  renderLighted = (runway) ->
    renderBoolean('Lighted')(runway.lighted)

  airportLogLine = (airport) ->
    extraInfo = ->
      pre = if airport.municipality? then "in #{airport.municipality}" else "in"
      "#{pre} #{airport.isoRegion} (#{airport.airportType})"

    """
      #{sym.airplane} ##{airport.id} [#{airport.ident}] #{airport.name} #{extraInfo()}
    """

  runwayLogLine = (runway) ->
    ident = renderIdent(runway)
    length = foldOpt(runway.length)('')((l) -> ", length: #{l}")
    width = foldOpt(runway.width)('')((w) -> ", width: #{w}")
    lighted = ", lighted: #{renderLighted(runway)}"
    open = ", open: #{renderOpen(runway)}"

    """
      #{sym.upArrow} ##{runway.id} [#{ident}] #{runway.surface}#{length}#{width}#{open}#{lighted}
    """

  countryLogLine = (country) ->
    """
    """


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
      logArea.append("""<p class="log-line #{pClass}">#{line}</p>""")

    for i in [0 .. maxLogLines]
      _log('__internal__')(sym.space)

    clear = () ->
      logLines = []
      logArea.empty()

    _out  = (url) ->
      _log('out')("#{sym.rArrow} GET #{url}")

    _in   = (url) ->
      _log('in') ("#{sym.lArrow} GET #{url}")

    _err  = (url, status, error) ->
      _log('err') ("#{sym.lArrow} GET #{url}: Error: #{status} #{error}")

    {
      trace:  _log('trace')
      debug:  _log('debug')
      info:   _log('info')
      warn:   _log('warn')
      out:    _out
      in:     _in
      err:    _err
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


    mkStyle = (e) -> (kind) -> (scale) ->
      switch(kind)
          when 'highlight'
            fill    = new ol.style.Fill({color: mkColor(0.2)(e.color)})
            stroke  = new ol.style.Stroke({color: mkColor(0.9)(e.color), width: 4})
            shape = mkShape[e.shape]({fill: fill, stroke: stroke, radius: (scale * (1.8 * e.radius))})
            new ol.style.Style({image: shape, zIndex: (e.index+40)})
          when 'selected'
            fill    = new ol.style.Fill({color: mkColor(0.8)(e.color)})
            stroke  = new ol.style.Stroke({color: mkColor(1.0)(e.color), width: 4})
            shape = mkShape[e.shape]({fill: fill, stroke: stroke, radius: (scale * (1.4 * e.radius))})
            new ol.style.Style({image: shape, zIndex: (e.index+20)})
          else
            fill    = new ol.style.Fill({color: mkColor(0.6)(e.color)})
            stroke  = new ol.style.Stroke({color: mkColor(0.8)(e.color), width: 2})
            shape = mkShape[e.shape]({fill: fill, stroke: stroke, radius: (scale * e.radius)})
            new ol.style.Style({image: shape, zIndex: e.index})

    buildStyles = (stylesDef) ->
      result = {}
      for section, entries of stylesDef
        result[section] = {}
        for subsection, entry of entries
          result[section][subsection] = {
            predef: {}
            highlight: {}
            selected: {}
            #predef:     { zoom_0: mkStyle(entry)('predef')(1.0) }
            #highlight:  { zoom_0: mkStyle(entry)('highlight')(1.0) }
            #selected:   { zoom_0: mkStyle(entry)('selected')(1.0) }
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
        lighted:        { color: {r:  50, g: 150, b:  70}, radius:  8, shape: 'square',   index: 3 }
        notLighted:     { color: {r:  50, g:  80, b: 180}, radius:  8, shape: 'triangle', index: 2 }
        closed:         { color: {r:  50, g:  50, b:  50}, radius:  6, shape: 'cross',    index: 1 }
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

    airportStyle = (feat) ->
      styles.airports[airportStyleKey(feat)]

    runwayStyle = (feat) ->
      styles.runways[runwayStyleKey(feat)]

    airportStyleDef = (feat) ->
      stylesDef.airports[airportStyleKey(feat)]

    runwayStyleDef = (feat) ->
      stylesDef.runways[runwayStyleKey(feat)]

    featStyle = (feat) ->
      featFold(feat)(
        (a) -> airportStyle(feat),
        (r) -> runwayStyle(feat)
      )

    featStyleDef = (feat) ->
      featFold(feat)(
        (a) -> airportStyleDef(feat),
        (r) -> runwayStyleDef(feat)
      )

    newStyleKind = (kind) ->
      (styleDef) -> (zoom) -> mkStyle(styleDef)(kind)(zoom / 10.0)

    styleBaseKind = (kind) ->
      (feat) -> featStyle(feat)[kind]

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

    view = new ol.View({
      projection: 'EPSG:4326'
      center: [5.37437083333, 52.14307022093594] # center of NL airports extent
      zoom: 5
      minZoom: 1
      maxZoom: 20
    })

    styleFunction = (styleBase, styleDef, newStyle) ->
      (feat, resolution) ->
        zoom = view.getZoom()
        zoomKey = "zoom_#{zoom}"
        base = styleBase(feat)
        if not (zoomKey of base)
          def = styleDef(feat)
          base[zoomKey] = newStyle(def)(zoom)

        [base[zoomKey]]

    styleFunctionPredef = (type) ->
      styleBase = switch(type)
        when 'airport' then (feat) -> airportStyle(feat).predef
        when 'runway'  then (feat) -> runwayStyle(feat).predef
      styleDef = switch (type)
        when 'airport' then (feat) -> airportStyleDef(feat)
        when 'runway'  then (feat) -> runwayStyleDef(feat)
      newStyle = newStyleKind('predef')

      styleFunction(styleBase, styleDef, newStyle)

    styleFunctionKind = (kind) ->
      styleFunction(
        (feat) -> featStyle(feat)[kind],
        featStyleDef,
        newStyleKind(kind)
      )

    # TODO: change radius according to zoom level
    airportsLayer = new ol.layer.Vector({
      id: 'airports'
      source: airportsSource
      style: styleFunctionPredef('airport')
    })

    runwaysLayer = new ol.layer.Vector({
      id: 'runways'
      source: runwaysSource
      style: styleFunctionPredef('runway')
    })

    interactiveLayers = (layer) ->
      layerId = layer.get('id')
      layerId == 'airports' or layerId == 'runways'

    selectInteraction = new ol.interaction.Select({
      layers: interactiveLayers
      style: styleFunctionKind('selected')
    })

    hoverInteraction = new ol.interaction.Select({
      condition: ol.events.condition.pointerMove
      layers: interactiveLayers
      style: styleFunctionKind('highlight')
    })

    popup = new ol.Overlay({
      element: $('#query-info-box')[0]
      autoPan: false
      positioning: 'bottom-right'
    })

    map = new ol.Map({
      target: 'map'
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

    showPopup = (content) -> (data, coords) ->
      element = $(popup.getElement())
      element.popover('destroy')
      popup.setPosition(coords)
      element.popover({
        animation:  false
        html:       true
        content:    content(data, coords)
      })
      element.popover('show')

    airportContent = (data, coords) ->
      a = data
      """
        <ul class="list-group box-shadow">
          <li class="list-group-item list-group-item-info">
            <span class="feature-name"><strong>#{sym.airplane} #{a.name}</strong></span>
            <span class="feature-code pull-right label label-default">#{a.ident}</span>
          </li>
          <li class="list-group-item popover-table-info">
            <table class="table table-airport-info">
              <tbody>
                <tr>
                  <td>Type:</td>
                  <td colspan="3"><strong>#{a.airportType}</strong></td>
                </tr>
                <tr>
                  <td>Region:</td>
                  <td colspan="3">#{renderOption(a.isoRegion, 'strong')}</td>
                </tr>
                <tr>
                  <td>Municipality:</td>
                  <td colspan="3">#{renderOption(a.municipality, 'strong')}</td>
                </tr>
                <tr>
                  <td>Position:</td>
                  <td colspan="3">#{renderPosition(coords)}</td>
                </tr>
                <tr>
                  <td>Elevation:</td>
                  <td colspan="3">#{renderFeetOpt(a.elevation)}</td>
                </tr>
                <tr>
                  <td>Scheduled Service:</td>
                  <td colspan="3">#{renderBoolean('Scheduled service')(a.scheduledService)}</td>
                </tr>
                <tr>
                  <td>Codes:</td>
                  <td>GPS: #{renderOption(a.gpsCode, 'strong')}</td>
                  <td>IATA: #{renderOption(a.iataCode, 'strong')}</td>
                  <td>Local: #{renderOption(a.localCode, 'strong')}</td>
                </tr>
                <tr>
                  <td>Links:</td>
                  <td>#{renderLink(a.homeLink, "Home: #{sym.rArrow}", "Home: #{sym.emptySet}")}</td>
                  <td colspan="2">#{renderLink(a.wikipediaLink, "Wikipedia: #{sym.rArrow}", "Wikipedia: #{sym.emptySet}")}</td>
                </tr>
                <tr>
                  <td>Keywords:</td>
                  <td colspan="3"#{renderOption(a.keywords)}</td>
                </tr>
            </tbody>
          </table>
        </li>
      </ul>
      """

    runwayContent = (data, coords) ->
      r = data
      leHeading = renderFeetOpt(r.leHeading)
      heHeading = renderFeetOpt(r.heHeading)
      leDisplacement = renderFeetOpt(r.leDisplacementThreshold)
      heDisplacement = renderFeetOpt(r.heDisplacementThreshold)
      """
        <ul class="list-group box-shadow">
          <li class="list-group-item list-group-item-info">
            <span class="feature-name"><strong>#{sym.upArrow} #{renderIdent(r)}</span>
            <span class="feature-code pull-right label label-default">#{renderOpen(r)} #{renderLighted(r)}</span>
          </li>
          <li class="list-group-item popover-table-info">
            <table class="table">
              <tbody>
                <tr>
                  <td>Surface:</td>
                  <td colspan="2"><strong>#{r.surface}</strong></td>
                </tr>
                <tr>
                  <td>Positions:</td>
                  <td>#{renderPosition(r.lePosition)}</td>
                  <td>#{renderPosition(r.hePosition)}</td>
                </tr>
                <tr>
                  <td>Dimensions:</td>
                  <td>#{renderFeetOpt(r.length)}</td>
                  <td>#{renderFeetOpt(r.width)}</td>
                </tr>
                <tr>
                  <td>Elevations:</td>
                  <td>#{renderFeetOpt(r.leElevation)}</td>
                  <td>#{renderFeetOpt(r.heElevation)}</td>
                </tr>
                <tr>
                  <td>Headings:</td>
                  <td>#{renderFeetOpt(leHeading)}</td>
                  <td>#{renderFeetOpt(heHeading)}</td>
                </tr>
                <tr>
                  <td>Disp. Threshs.:</td>
                  <td>#{renderFeetOpt(leDisplacement)}</td>
                  <td>#{renderFeetOpt(heDisplacement)}</td>
                </tr>
              </tbody>
            </table>
          </li>
        </ul>
      """

    showAirportPopup = (data, coords) ->
      showPopup(airportContent)(data, coords)
      $('.popover-content').addClass('airport-content')

    showRunwayPopup = (data, coords) ->
      showPopup(runwayContent)(data, coords)
      $('.popover-content').addClass('runway-content')

    hideHoverInfo = () ->
      mapHoverInfo.html(sym.space)
      mapHoverCode.html(sym.space)
      mapHoverCode.attr('class', 'pull-right label label-default')

    showAiportHoverInfo = (data) ->
      mapHoverInfo.html("""#{sym.airplane} #{data.name}""")
      mapHoverCode.html("""#{data.ident}""")

    showRunwayHoverInfo = (data) ->
      mapHoverInfo.html("""#{sym.upArrow} #{renderIdent(data)} #{data.surface}""")
      mapHoverCode.removeClass('hidden')
      mapHoverCode.html("""#{renderOpen(data)} #{renderLighted(data)}""")

    panTo = (location) -> (cb) ->
      pan = ol.animation.pan({
        duration: 300
        source: view.getCenter()
      })
      map.beforeRender((map, framestate) ->
        animation = pan(map, framestate)
        if animation == false
          cb()
        animation
      )
      view.setCenter(location)

    selected = selectInteraction.getFeatures()
    selected.on('add', (event) ->
      feat = event.target.item(0)
      coords = feat.getGeometry().getCoordinates()
      data = feat.getProperties()
      featFold(feat)(
        (a) ->
          panTo(coords)(() -> showAirportPopup(data, coords))
          if noNotify == false
            for cb in airportCallbacks
              cb(data)
        (r) ->
          panTo(coords)(() -> showRunwayPopup(data, coords))
          if noNotify == false
            for cb in runwayCallbacks
              cb(data)
      )
    )
    selected.on('remove', (event) ->
      element = $(popup.getElement())
      element.popover('destroy')
      popup.setPosition(undefined)
    )

    selectFeat = (feat) ->
      selected.clear()
      noNotify = true
      selected.push(feat)
      noNotify = false

    selectRunway = (runway) ->
      feat = runwaysSource.getFeatureById(runway.id)
      if feat?
        selectFeat(feat)
      else
        feat = airportsSource.getFeatureById(runway.airportRef)
        showRunwayPopup(runway, feat.getGeometry().getCoordinates())


    select = (type) -> (data) ->
      element = $(popup.getElement())
      element.popover('destroy')
      feat = switch (type)
        when 'airport' then selectFeat(airportsSource.getFeatureById(data.id))
        when 'runway' then selectRunway(data)

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

    unselect = () ->
      $("##{target} tbody tr.selected").removeClass('selected active')
      ### TODO: callback, unselect in map!! ###

    select = (id) ->
      noNotify = true
      unselect()
      row = dataTable.row("##{id}")
      data = row.data()
      $("##{id}").addClass('selected active')
      $('.dataTables_scrollBody').scrollTo("##{id}")
      noNotify = false

    $("##{config.target} tbody").on('click', 'tr', () ->
      elem = $(this)
      if elem.hasClass('selected')
        # already selected -> unselect
        elem.removeClass('selected active')
      else
        # not the same row -> unselect other, then select this
        unselect()
        elem.addClass('selected active')
        data = getSelectedData()
        notifySelected(data)
    )

    update = (data) ->
      dataTable.clear()
      dataTable.search("")
      dataTable.rows.add(data).draw(true)

    search = (query) ->
      dataTable.search(query).draw(true)

    searchColumn = (idx) -> (query) ->
      dataTable.columns(idx).search(query).draw(true)

    {
      update: update
      selectedData: getSelectedData
      onSelectRow:  (cb) -> selectCallbacks.push(cb)
      search: search
      searchColumn: searchColumn
      select: select
      unselect: unselect
    }


##############################################################################
  ### Airports Results ###
  ########################
  AirportsResults = (config) ->
    titleExtra = $('#airports-results-title-extra')

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

    updateAirports = (data) ->
      titleExtra.html("""in #{countryLogLine(data.country)} """)
      tableResults.update(data.airports)

    selectAirport = (airport) ->
      tableResults.select(idFn(airport))

    $.extend(tableResults, {
      updateAirports: updateAirports
      selectAirport: selectAirport
    })


##############################################################################
  ### Runways Results ###
  #######################
  RunwaysResults = (config) ->
    titleExtra = $('#runways-results-title-extra')

    idFn = (data) -> "runway_id_#{data.id}"
    tableResults = TableResults({
      logger: config.logger
      target: 'runways-results-table'
      height: '22vh'
      rowId: idFn
      columns: [
        { data: 'airportIdent' }
        { data: 'id' }
        { data: 'leIdent' }
        { data: 'heIdent' }
        { data: 'surface' }
        { data: 'length' }
        { data: 'width' }
        { data: 'closed',       render: (b) -> renderBoolean('Open')(! b) }
        { data: 'lighted',      render: renderBoolean('Lighted') }
        { data: 'leHeading' }
        { data: 'leElevation' }
      ]
    })
    selectRunway = (runway) ->
      tableResults.select(idFn(runway))

    updateRunways = (data) ->
      titleExtra.html("""in #{countryLogLine(data.country)}""")
      tableResults.update(data.runways)

    $.extend(tableResults, {
      updateRunways: updateRunways
      selectRunway: selectRunway
    })


##############################################################################
  ### Query ###
  #############
  Query = (config) ->
    queryForm = $('#query-form')
    queryInput = $('#query-input')
    querySubmit = $('#query-submit')
    selector = undefined
    lastQuery = undefined
    callbacks = []

    logger = config.logger
    refresh = config.refresh

    sendQuery = (queryStr) ->
      if queryStr != lastQuery
        if queryStr.length >= 2
          lastQuery = queryStr
          url = countryUrl(queryStr)
          logger.out(url)
          $.ajax(countryUrl(queryStr), {
            type: 'GET'

            error: (jqXHR, status, error) ->
              logger.err(url, status, error)

            success: (data, status, jqXHR) ->
              logger.in(url)
              for cb in callbacks
                cb(data)
          })

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
      $('.selectize-input').addClass('focus')

      #selector.focus()

    logger.out(countriesUrl)
    $.ajax(countriesUrl, {
      type: 'GET'

      error: (jqXHR, status, error) ->
        logger.err(countriesUrl, status, error)

      success: (data, status, jqXHR) ->
        logger.in(countriesUrl)
        setup(data)
    })

    registerCallback = (cb) ->
      callbacks.push(cb)

    {
      onCountryResults: registerCallback
    }


##############################################################################
  ### Controller ###
  ##################
  Controller = (config) ->
    logger = config.logger

    map               = MyMap(config)
    query             = Query(config)
    airportsResults   = AirportsResults(config)
    runwaysResults    = RunwaysResults(config)

    fetchAirports = (countryCode) ->
      url = airportsUrl(countryCode, 'geojson')
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
      url = runwaysUrl(countryCode)
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
    query.onCountryResults((country) ->
      fetchAirports(country.code)
      fetchRunways(country.code)
    )

    ### Airport selected ###
    airportSelected = (airport) ->
      logger.info(airportLogLine(airport))
      runwaysResults.unselect()
      runwaysResults.search(airport.ident)

    # selected from table -> select on map
    airportsResults.onSelectRow((airport) ->
      airportSelected(airport)
      map.selectAirport(airport)
    )
    # selected from map -> select on table
    map.onAirportSelected((airport) ->
      airportSelected(airport)
      airportsResults.selectAirport(airport)
    )

    ### Runway selected ###
    runwaySelected = (runway) ->
      if runway.lePosition? or runway.hePosition?
        logger.info(runwayLogLine(runway))
      else
        logger.warn("#{runwayLogLine(runway)}: runway position not found!")
      airportsResults.unselect()

    # selected from table -> select on map
    runwaysResults.onSelectRow((runway) ->
      runwaySelected(runway)
      map.selectRunway(runway)
    )
    # selected from map -> select on table
    map.onRunwaySelected((runway) ->
      runwaySelected(runway)
      runwaysResults.selectRunway(runway)
    )


##############################################################################
  # Initialization #
  ##################
  logger = Logger({maxLogLines: 13})
  controller = Controller({logger: logger})
