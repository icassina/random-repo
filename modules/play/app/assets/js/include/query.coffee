root = exports ? this

### Query(config)
# requires:
#   * lib/jquery/jquery.js
#   * lib/selectize.js/js/standalone/selectize.js
#   * js/include/logger.js
#   * js/include/urls.js
#
# <- config
#   logger: Logger instance
#
# -> 
#   beforeRequest:  (() -> ) ->
#   afterRequest:   ((country) -> ) ->
###
root.Query = (config) ->
  queryForm = $('#query-form')
  queryInput = $('#query-input')
  querySubmit = $('#query-submit')
  selector = undefined
  lastQuery = undefined
  afterCallbacks = []
  beforeCallbacks = []

  logger = config.logger

  sendQuery = (queryStr) ->
    if queryStr != lastQuery
      if queryStr.length >= 2
        lastQuery = queryStr
        url = urls.country(queryStr)
        for cb in beforeCallbacks
          cb()
        logger.out(url)
        $.ajax(url, {
          type: 'GET'

          error: (jqXHR, status, error) ->
            logger.err(url, status, error)

          success: (data, status, jqXHR) ->
            logger.in(url)
            for cb in afterCallbacks
              cb(data)
        })

  setup = (countries) ->
    selector = queryInput.selectize({
      maxItems: 1
      labelField: 'name'
      valueField: 'code'
      searchField: ['name', 'code', 'keywords']
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

  logger.out(urls.countries)
  $.ajax(urls.countries, {
    type: 'GET'

    error: (jqXHR, status, error) ->
      logger.err(countriesUrl, status, error)

    success: (data, status, jqXHR) ->
      logger.in(urls.countries)
      setup(data)
  })

  {
    beforeRequest: (cb) -> beforeCallbacks.push(cb)
    onCountryResults: (cb) -> afterCallbacks.push(cb)
  }
