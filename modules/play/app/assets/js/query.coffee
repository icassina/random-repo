countriesResultsNode = $('#query-countries-results')

airportsResultsNode = $('#query-airports-results')

refreshCountryResults = (matchingCountries) ->
  console.log(matchingCountries)
  countriesResultsNode.empty()
  for country in matchingCountries
    countriesResultsNode.append("""
      <li>#{country.name} (#{country.code} / #{country.continent})</li>
    """)

refreshAirportsResults = (matchingAirports) ->
  airportsResultsNode.empty()
  for airport in matchingAirports
    airportsResultsNode.append("""
      <tr>
        <td>#{airport.id}</td>
        <td>#{airport.ident}</td>
        <td>#{airport.name}</td>
      </tr>
    """)


airportsPoints = new ol.source.Vector({})

map = new ol.Map({
  target:   'map',
  layers: [
    new ol.layer.Tile({
      source: new ol.source.OSM()
    }),
    new ol.layer.Vector({
      source: airportsPoints
    })
  ],
  renderer: 'canvas',
  view: new ol.View({
    center: ol.proj.fromLonLat([37.41, 8.82]),
    zoom: 4
  })
})

airportsPoints.addFeature(new ol.Feature({
  name: 'airport',
  geometry: new ol.geom.Point( [ol.proj.transform([-16, -22], 'EPSG:4326', 'EPSG:3857')] )
}))
