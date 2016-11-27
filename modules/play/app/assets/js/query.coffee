$ ->

# Logger
  logArea = $('#query-log-area')
  maxLogLines = 16
  logLines = []

  Logger = () ->
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

# setup
  logger = Logger()

  countriesResultsNode = $('#query-countries-results')

  airportsResultsNode = $('#query-airports-results')

  queryInput = $('#query-input')
  queryForm = $('#query-form')
  querySubmit = $('#query-submit')

  wsconfig = $('#ws-config').data()



# update map functions
  airportsPoints = new ol.source.Vector({
    format: new ol.format.GeoJSON()
  })
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

  map = new ol.Map({
    target:   'map',
    layers: [
      new ol.layer.Tile({
        source: new ol.source.OSM()
      }),
      new ol.layer.Vector({
        source: airportsPoints
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
  geoJSON = new ol.format.GeoJSON()

# update DOM functions
  refreshCountryResults = (matchingCountries) ->
    countriesResultsNode.empty()
    for country in matchingCountries
      countriesResultsNode.append("""
        <li>#{country.data.name} (#{country.data.code} / #{country.data.continent})</li>
      """)

  refreshAirportsResults = (matchingAirports) ->
    airportsResultsNode.empty()
    airportsPoints.clear()
    airportsPoints.addFeatures( geoJSON.readFeatures(matchingAirports))
    map.getView().fit(airportsPoints.getExtent(), map.getSize())

    for feature in matchingAirports.features
      airport = feature.properties.data
      airportsResultsNode.append("""
        <tr>
          <td>#{airport.id}</td>
          <td>#{airport.ident}</td>
          <td>#{airport.name}</td>
        </tr>
      """)

  lastQuery = undefined
  queryUpdate = (socket) ->
    queryStr = queryInput.val()
    if queryStr != lastQuery
      if queryStr.length >= 2
        lastQuery = queryStr
        socket.send(JSON.stringify({
          type: 'country-query'
          query: queryStr
        }))

  setupQuery = (socket) ->
    queryForm.submit (event) ->
      event.preventDefault()
      queryUpdate(socket)

  receive = (msg) ->
    data = JSON.parse(msg.data)
    switch (data.type)
      when 'error'
        logger.err(data.result)

      when 'country-query-response'
        logger.debug("country-query-response: #{data.result.type}")
        switch (data.result.type)
          when 'country-found'      then refreshCountryResults([data.result.data.country])
          when 'no-matches'         then refreshCountryResults([])
          when 'matching-countries' then refreshCountryResults(data.result.data)

      when 'send-airports'
        logger.debug("send-airports for: #{data.result.country.data.name}")
        refreshAirportsResults(data.result.airports)

      when 'send-runways'
        logger.okay("send-runways for: #{data.result.country.data.name}")

      else
        logger.warn("unknown message: #{data}")



  logger.info("Connecting to #{wsconfig.wsuri}…")

  socket = new WebSocket(wsconfig.wsuri)
  socket.onopen = (event) ->
    logger.okay("Connected!")

    socket.onmessage = receive
    setupQuery(socket)
