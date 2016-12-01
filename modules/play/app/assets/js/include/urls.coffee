root = exports ? this

root.urls = do () ->
    countriesUrl        = '/api/countries'
    countryBaseUrl      = '/api/country'
    countryFuzzyBaseUrl = '/api/country/fuzzy'
    airportsBaseUrl     = '/api/airports'
    runwaysBaseUrl      = '/api/runways'

    reports = {
      countriesTop10:     '/api/reports/countries/top10'
      countriesLow10:     '/api/reports/countries/low10'
      runwaysIdentsTop10: '/api/reports/runways/idents/top10'  
      runwaysSurfaces:    '/api/reports/runways/surfaces'
    }

    countryUrl = (countryCode) ->
      "#{countryBaseUrl}/#{countryCode}"

    countryFuzzyUrl = (query) ->
      "#{countryFuzzyBaseUrl}/#{query}"

    airportsUrl = (countryCode, suffix) ->
      extra = if suffix? then "/#{suffix}" else ""
      "#{airportsBaseUrl}/#{countryCode}#{extra}"

    runwaysUrl = (countryCode, suffix) ->
      extra = if suffix? then "/#{suffix}" else ""
      "#{runwaysBaseUrl}/#{countryCode}#{extra}"

    {
      countries:      countriesUrl

      country:        countryUrl
      countryFuzzy:   countryFuzzyUrl
      airports:       airportsUrl
      runways:        runwaysUrl

      reports:        reports
    }
