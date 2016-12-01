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


    {
      countries:      countriesUrl
      countryBase:    countryBaseUrl
      airportsBase:   airportsBaseUrl
      runwaysBase:    runwaysBaseUrl

      country:        countryUrl
      airports:       airportsUrl
      runways:        runwaysUrl
    }

