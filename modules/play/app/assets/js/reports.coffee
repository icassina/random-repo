$ ->

  countriesColumns = [
    { data: 'country.id' }
    { data: 'country.code',           render: render.strong }
    { data: 'country.name',           render: render.strong }
    { data: 'airports',               render: render.strong }
    { data: 'country.continent' }
    { data: 'country.wikipedia_link', render: (a) -> render.link(a, a, symbols.emptySet) }
    { data: 'country.keywords' }
  ]

  ct10 = $('#countries-top-10').DataTable({
    ajax:             urls.reports.countriesTop10
    scrollY:          '32vh'
    sScrollY:         '32vh'
    bScrollCollapse:  false
    scrollCollapse:   false
    paging:           true
    scroller:         true
    deferRender:      true
    bFilter:          false
    order:            [[3, 'desc'], [2, 'asc']]
    columns:          countriesColumns
  })

  cl10 = $('#countries-low-10').DataTable({
    ajax:             urls.reports.countriesLow10
    scrollY:          '32vh'
    sScrollY:         '32vh'
    bScrollCollapse:  false
    scrollCollapse:   false
    paging:           true
    scroller:         true
    deferRender:      true
    bFilter:          false
    order:            [[3, 'asc'], [2, 'asc']]
    columns:          countriesColumns
  })
      
  $('#runway-idents-top-10').DataTable({
    ajax:             urls.reports.runwaysIdentsTop10
    scrollY:          '30vh'
    sScrollY:         '30vh'
    bScrollCollapse:  false
    scrollCollapse:   false
    paging:           true
    scroller:         true
    deferRender:      true
    bFilter:          false
    order:            [[1, 'desc'], [0, 'asc']]
    columns:          [
      { data: "ident",    render: render.strong }
      { data: "runways",  render: render.strong }
    ]
  })

  $('#runway-surfaces').DataTable({
    ajax:             urls.reports.runwaysSurfaces
    scrollY:          '27vh'
    sScrollY:         '27vh'
    bScrollCollapse:  false
    scrollCollapse:   false
    paging:           true
    scroller:         true
    deferRender:      true
    order:            [[1, 'desc'], [0, 'asc'], [2, 'asc']]
    columns:          [
      { data: "surface",                render: render.strong }
      { data: "runways",                render: render.strong }
      { data: "country.code",           render: render.strong }
      { data: "country.name",           render: render.strong }
      { data: "country.continent" }
      { data: "country.id" }
      { data: "country.wikipedia_link", render: (a) -> render.link(a, a, symbols.emptySet) }
      { data: "country.keywords" }
    ]
  })
