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
  unselectCallbacks = []

  dataTable = $("##{target}").DataTable({
    scrollY:          height
    sScrollY:         height
    bScrollCollapse:  false
    scrollCollapse:   false
    paging:           true
    scroller:         true
    deferRender:      true
    select: {
      style:  'single'
    }
    rowId:            rowId
    columns:          columns
  })

  notify = (observers) -> (data) ->
    if noNotify == false
      for cb in observers
        cb(data)

  notifySelected    = notify(selectCallbacks)
  notifyUnselected  = notify(unselectCallbacks)

  unselect = () ->
    noNotify = true
    dataTable.rows({selected: true}).deselect().draw(false)
    noNotify = false

  select = (id) ->
    noNotify = true
    dataTable.row("##{id}").select().scrollTo()
    noNotify = false

  dataTable.on('deselect', (e, dt, type, indexes) ->
    for idx in indexes
      row = dataTable.row(idx)
      data = row.data()
      $(row.node()).removeClass('active')
      notifyUnselected(data)
  )
  dataTable.on('select', (e, dt, type, indexes) ->
    for idx in indexes
      row = dataTable.row(idx)
      data = row.data()
      $(row.node()).addClass('active')
      notifySelected(data)
  )

  update = (data) ->
    dataTable.clear()
    dataTable.search("")
    dataTable.rows.add(data).draw(true)

  search = (query) ->
    dataTable.search(query).draw(true)

  onSelect = (cb) ->
    selectCallbacks.push(cb)
    this

  onUnselect = (cb) ->
    unselectCallbacks.push(cb)
    this

  {
    update:         update
    onSelectRow:    onSelect
    onUnselectRow:  onUnselect
    search:         search
    select:         select
    unselect:       unselect
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
    height: '27.3vh'
    select: true
    rowId: idFn
    columns: [
      { data: 'ident' }
      { data: 'name',         render: render.trim(24) }
      { data: 'airportType',  render: render.airport.type }
      { data: 'isoRegion' }
      { data: 'municipality', render: render.trim(24) }
      { data: 'elevation',    render: (v) -> render.option(v) }
      { data: 'codes',        render: (v) -> render.small(render.list(v)) }
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
    height: '26vh'
    rowId: idFn
    columns: [
      { data: 'airportIdent' }
      { data: 'ident',        render: render.pairs }
      { data: 'surface',      render: render.trim(24) }
      { data: 'dimensions',   render: render.pairs }
      { data: 'closed',       render: (b) -> render.boolean('Open')(! b) }
      { data: 'lighted',      render: (b) -> render.boolean('Lighted')(b) }
      { data: 'heading',      render: render.pairs }
      { data: 'elevation',    render: render.pairs }
      { data: 'displacement', render: render.pairs }
    ]
  })
  selectRunway = (runway) ->
    tableResults.search("")
    tableResults.select(idFn(runway))

  updateRunways = (data) ->
    titleExtra.html("""in #{render.country.logLine(data.country)}""")
    tableResults.update(data.runways)

  $.extend(tableResults, {
    updateRunways: updateRunways
    selectRunway: selectRunway
  })
