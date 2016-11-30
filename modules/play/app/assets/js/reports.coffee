$ ->

  strong = (v) -> "<strong>#{v}</strong>"

  link = (a) -> """<a target="_blank" href="#{a}">#{a}</a>"""

  console.log("loading countries-top-10")

  countriesColumns = [
    { data: 'country.id' }
    { data: 'country.code',           render: strong }
    { data: 'country.name',           render: strong }
    { data: 'airports',               render: strong }
    { data: 'country.continent' }
    { data: 'country.wikipedia_link', render: link }
    { data: 'country.keywords' }
  ]

  ct10 = $('#countries-top-10').DataTable({
    ajax:             '/api/reports/countries/top10'
    sScrollY:         '32vh'
    bScrollCollapse:  false
    scrollCollapse:   false
    paging:           false
    scroller:         true
    bFilter:          false
    order:            [[3, 'desc'], [2, 'asc']]
    columns:          countriesColumns
  })

  cl10 = $('#countries-low-10').DataTable({
    ajax: '/api/reports/countries/low10'
    sScrollY:         '32vh'
    bScrollCollapse:  false
    scrollCollapse:   false
    paging:           false
    scroller:         true
    bFilter:          false
    order:            [[3, 'asc'], [2, 'asc']]
    columns:          countriesColumns
  })
      
  $('#runway-idents-top-10').DataTable({
    ajax:             '/api/reports/runways/idents/top10'
    sScrollY:         '30vh'
    bScrollCollapse:  false
    scrollCollapse:   false
    paging:           false
    scroller:         true
    bFilter:          false
    order:            [[1, 'desc'], [0, 'asc']]
    columns:          [
      { data: "ident",    render: strong }
      { data: "runways",  render: strong }
    ]
  })

  $('#runway-surfaces').DataTable({
    ajax:             '/api/reports/runways/surfaces'
    sScrollY:         '27vh'
    bScrollCollapse:  false
    scrollCollapse:   false
    paging:           false
    scroller:         true
    order:            [[1, 'desc'], [0, 'asc'], [2, 'asc']]
    columns:          [
      { data: "surface",                render: strong }
      { data: "runways",                render: strong }
      { data: "country.code",           render: strong }
      { data: "country.name",           render: strong }
      { data: "country.continent" }
      { data: "country.id" }
      { data: "country.wikipedia_link", render: link }
      { data: "country.keywords" }
    ]
  })
