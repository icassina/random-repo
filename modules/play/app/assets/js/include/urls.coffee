root = exports ? this

root.urls = do () ->
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

    reports = {
      countriesTop10:     '/api/reports/countries/top10'
      countriesLow10:     '/api/reports/countries/low10'
      runwaysIdentsTop10: '/api/reports/runways/idents/top10'  
      runwaysSurfaces:    '/api/reports/runways/surfaces'
    }

    {
      countries:      countriesUrl
      countryBase:    countryBaseUrl
      airportsBase:   airportsBaseUrl
      runwaysBase:    runwaysBaseUrl

      country:        countryUrl
      airports:       airportsUrl
      runways:        runwaysUrl

      reports:        reports
    }

