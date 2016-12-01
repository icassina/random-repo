root = exports ? this

### TableResults(config)
# requires:
#   * lib/jquery/jquery.js
#   * lib/datatables/js/jquery.dataTables.js
#   * lib/jquery.scrollTo/jquery.scrollTo.js
#   * js/include/logger.js
#
# <- config:
#   logger:   <Logger>            logger instance
#   target:   <String>            <table id="…"> target
#   height:   <String>            height
#   rowId:    (data) -> String    function for row IDs
#   columns:  [{}]                columns definition
#
# ->
#   update:         (data) ->
#   selectedData:   () -> 
#   onSelectRow:    ((data) -> ) ->
#   search:         (query) -> 
#   searchColumn:   (index) -> (query) -> searchColumn
#   select:         (rowId) ->
#   unselect:       () ->
###
root.TableResults = (config) ->
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

### AirportsResults(config)
# requires:
#   * js/include/render.js
#
# <- config
#   logger: Logger instance
#
# -> TableResults ++
#   updateAirports: (airports) ->
#   selectAirport:  (airport) ->
###
root.AirportsResults = (config) ->
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
    titleExtra.html("""in #{render.country.logLine(data.country)} """)
    tableResults.update(data.airports)

  selectAirport = (airport) ->
    tableResults.select(idFn(airport))

  $.extend(tableResults, {
    updateAirports: updateAirports
    selectAirport: selectAirport
  })

### RunwaysResults(config)
# requires:
#   * js/include/render.js
#
# <- config
#   logger: Logger instance
#
# -> TableResults ++
#   updateRunways: (runways) ->
#   selectRunway:  (runway) ->
###
root.RunwaysResults = (config) ->
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
      { data: 'closed',       render: (b) -> render.boolean('Open')(! b) }
      { data: 'lighted',      render: (b) -> render.boolean('Lighted')(b) }
      { data: 'leHeading' }
      { data: 'leElevation' }
    ]
  })
  selectRunway = (runway) ->
    tableResults.select(idFn(runway))

  updateRunways = (data) ->
    titleExtra.html("""in #{render.country.logLine(data.country)}""")
    tableResults.update(data.runways)

  $.extend(tableResults, {
    updateRunways: updateRunways
    selectRunway: selectRunway
  })
