root = requires ? this

### Map()
# requires:
#   * lib/jquery/jquery.js
#   * lib/openlayers/ol.js
#   * lib/bootstrap/js/tooltip.js
#   * lib/bootstrap/js/popover.js
#   * js/include/symbols.js
#   * js/include/render.js
#   * js/include/utils.js
#   * js/include/logger.js
#
# <- ()
#   
# ->
#   updateAirports:     (airports) ->
#   updateRunways:      (runways) ->
#   onAirportSelected:  ((airport) -> ) ->
#   onRunwaysSelected:  ((runway) -> ) ->
#   selectAirport:      (airport) ->
#   selectRunway:       (runway) ->
#   unselect:           () ->
###
root.Map = () ->
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
    controls: ol.control.defaults({
      attributionOptions: {
        collapsible: false
      }
    })
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
      content:    content(data)
    })
    element.popover('show')

  showAirportPopup = (data, coords) ->
    showPopup(render.airport.popupContent)(data, coords)
    $('.popover-content').addClass('airport-content')

  showRunwayPopup = (data, coords) ->
    showPopup(render.runway.popupContent)(data, coords)
    $('.popover-content').addClass('runway-content')

  hideHoverInfo = () ->
    mapHoverInfo.html(symbols.space)
    mapHoverCode.html(symbols.space)
    mapHoverCode.attr('class', 'pull-right label label-default')

  showAiportHoverInfo = (data) ->
    mapHoverInfo.html(render.airport.ident(data))
    mapHoverCode.html(render.airport.code(data))

  showRunwayHoverInfo = (data) ->
    mapHoverInfo.html("""#{symbols.upArrow} #{render.runway.ident(data)} #{data.surface}""")
    mapHoverCode.removeClass('hidden')
    mapHoverCode.html("""#{render.runway.open(data)} #{render.runway.lighted(data)}""")

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

  unselect = () ->
    noNotify = true
    selected.clear()
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
    unselect: unselect
  }
