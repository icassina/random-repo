root = exports ? this

### render
# requires:
#   * js/include/utils.js
# 
# -> 
#   option:       (value, someTag, noneTag) ->
#   boolean:      (name) -> (bool) ->
#   link:         (link, text, alt) ->
#   position:     (coords) ->
#   positionOpt:  (coords) ->
#   feetOpt:      (value) ->
#   runway:
#     ident:        (runway) ->
#     open:         (runway) ->
#     lighted:      (runway) ->
#     logLine:      (runway) ->
#   airport:
#     logLine:      (runway) ->
#   country:
#     logLine:      (runway) ->
###
root.render = do () ->
  strong = (value) -> """<strong>#{value}</strong>"""

  option = (value, someTag, noneTag) ->
    if value? 
      if someTag?
        "<#{someTag}>#{value}</#{someTag}>"
      else
        "#{value}"
    else
      if noneTag?
        "<#{noneTag}>#{symbols.emptySet}</#{noneTag}>"
      else
        symbols.emptySet

  boolean = (name) -> (bool) ->
    if bool
      """<span class="label label-success"><abbr title="#{name}: yes">#{symbols.true}</abbr></span>"""
    else
      """<span class="label label-danger"><abbr title="#{name}: no">#{symbols.false}</abbr></span>"""

  link = (link, text, alt) ->
    if link?
      """<a href="#{link}" target="_blank"">#{text}</a>"""
    else
      """#{alt}"""

  trim = (length) -> (str) ->
    utils.foldOpt(str)(symbols.emptySet)((v) ->
      if v.length <= length
        v
      else
        """<abbr title="#{v}">#{v.substring(0, length - 1)}…</abbr>"""
    )

  center = (v) -> """<p class="text-center">#{v}</p>"""

  right = (v) -> """<p class="text-right">#{v}</p>"""

  small = (v) -> """<small>#{v}</small>"""

  pairs = (values) ->
    """#{option(values[0])} / #{option(values[1])}"""

  list = (values) ->
    (option(v) for v in values).join(', ')

  position = (coords) -> strong("""<span class="text-primary">#{ol.coordinate.toStringHDMS(coords)}</span>""")

  positionOpt = (coords) -> utils.foldOpt(coords)(symbols.emptySet)(position)

  feetOpt = (value) -> utils.foldOpt(value)(symbols.emptySet)((v) -> """#{strong(v)} (ft)""")

  degtOpt = (value) -> utils.foldOpt(value)(symbols.emptySet)((v) -> """#{strong(v)} (degt)""")

  ### ident ###
  airportIdent = (airport) ->
    strong("""#{symbols.airplane} #{airport.name}""")

  runwayIdent = (runway) ->
    """#{strong(symbols.upArrow)} #{option(runway.leIdent, 'strong')} | #{option(runway.heIdent, 'strong')}"""

  ### code ###
  airportCode = (airport) ->
    airport.ident

  airportType = (airportType) ->
    switch(airportType)
      when 'large_airport'  then 'Large'
      when 'medium_airport' then 'Medium'
      when 'small_airport'  then 'Small'
      when 'seaplane_base'  then 'Seaplane'
      when 'closed'         then 'Closed'
      when 'balloonport'    then 'Ballonport'
      when 'heliport'       then 'Heliport'

  runwayOpen = (runway) ->
    boolean('Open')(! runway.closed)

  runwayLighted = (runway) ->
    boolean('Lighted')(runway.lighted)

  runwayCode = (runway) ->
    """#{runwayOpen(runway)} #{runwayLighted(runway)}"""

  ### logLine ###
  countryLogLine = (country) ->
    """
      #{country.name} [#{country.code}/#{country.continent}]
    """

  airportLogLine = (airport) ->
    extraInfo = ->
      pre = if airport.municipality? then "in #{airport.municipality}" else "in"
      "#{pre} #{airport.isoRegion} (#{airportType(airport.airportType)})"

    """
      #{symbols.airplane} ##{airport.id} [#{airport.ident}] #{airport.name} #{extraInfo()}
    """

  runwayLogLine = (runway) ->
    ident = """#{option(runway.leIdent, 'strong')} | #{option(runway.heIdent, 'strong')}"""
    length = utils.foldOpt(runway.length)('')((l) -> ", length: #{l}")
    width = utils.foldOpt(runway.width)('')((w) -> ", width: #{w}")
    lighted = ", lighted: #{runwayLighted(runway)}"
    open = ", open: #{runwayOpen(runway)}"

    """
      #{symbols.upArrow} ##{runway.id} [#{ident}] #{runway.surface}#{length}#{width}#{open}#{lighted}
    """

  ### popup content ###
  airportPopupContent = (a) ->
    """
      <ul class="list-group box-shadow">
        <li class="list-group-item list-group-item-info">
          <span class="feature-name">#{airportIdent(a)}</span>
          <span class="feature-code pull-right label label-default">#{a.ident}</span>
        </li>
        <li class="list-group-item popover-table-info">
          <table class="table table-airport-info">
            <tbody>
              <tr>
                <td>ID:</td>
                <td colspan="3">#{strong(a.id)}</td>
              </tr>
              <tr>
                <td>Type:</td>
                <td colspan="3">#{strong(airportType(a.airportType))}</td>
              </tr>
              <tr>
                <td>Region:</td>
                <td colspan="3">#{option(a.isoRegion, 'strong')}</td>
              </tr>
              <tr>
                <td>Municipality:</td>
                <td colspan="3">#{option(a.municipality, 'strong')}</td>
              </tr>
              <tr>
                <td>Position:</td>
                <td colspan="3">#{position(a.position)}</td>
              </tr>
              <tr>
                <td>Elevation:</td>
                <td colspan="3">#{feetOpt(a.elevation)}</td>
              </tr>
              <tr>
                <td>Scheduled Service:</td>
                <td colspan="3">#{boolean('Scheduled service')(a.scheduledService)}</td>
              </tr>
              <tr>
                <td>Codes:</td>
                <td>GPS: #{option(a.gpsCode, 'strong')}</td>
                <td>IATA: #{option(a.iataCode, 'strong')}</td>
                <td>Local: #{option(a.localCode, 'strong')}</td>
              </tr>
              <tr>
                <td>Links:</td>
                <td>#{link(a.homeLink, "Home: #{symbols.rArrow}", "Home: #{symbols.emptySet}")}</td>
                <td colspan="2">#{link(a.wikipediaLink, "Wikipedia: #{symbols.rArrow}", "Wikipedia: #{symbols.emptySet}")}</td>
              </tr>
              <tr>
                <td>Keywords:</td>
                <td colspan="3"#{option(a.keywords)}</td>
              </tr>
          </tbody>
        </table>
      </li>
    </ul>
    """

  runwayPopupContent = (r) ->
    """
      <ul class="list-group box-shadow">
        <li class="list-group-item list-group-item-info">
          <span class="feature-name">#{runwayIdent(r)}</span>
          <span class="feature-code pull-right label label-default">#{runwayCode(r)}</span>
        </li>
        <li class="list-group-item popover-table-info">
          <table class="table">
            <tbody>
              <tr>
                <td>ID:</td>
                <td>#{strong(r.id)}</td>
                <td><span class="feature-code label label-default">#{strong(r.airportIdent)}</span> #{symbols.airplane}</td>
              </tr>
              <tr>
                <td>Surface:</td>
                <td colspan="2"><strong>#{r.surface}</strong></td>
              </tr>
              <tr>
                <td>Positions:</td>
                <td>#{positionOpt(r.lePosition)}</td>
                <td>#{positionOpt(r.hePosition)}</td>
              </tr>
              <tr>
                <td>Dimensions:</td>
                <td>Length: #{feetOpt(r.length)}</td>
                <td>Width: #{feetOpt(r.width)}</td>
              </tr>
              <tr>
                <td>Elevations:</td>
                <td>le: #{feetOpt(r.leElevation)}</td>
                <td>he: #{feetOpt(r.heElevation)}</td>
              </tr>
              <tr>
                <td>Headings:</td>
                <td>le: #{degtOpt(r.leHeading)}</td>
                <td>he: #{degtOpt(r.heHeading)}</td>
              </tr>
              <tr>
                <td>Disp. Threshs.:</td>
                <td>le: #{feetOpt(r.leDisplacement)}</td>
                <td>he: #{feetOpt(r.heDisplacement)}</td>
              </tr>
            </tbody>
          </table>
        </li>
      </ul>
    """

  {
    strong:       strong
    option:       option
    boolean:      boolean
    link:         link
    trim:         trim
    right:        right
    small:        small
    pairs:        pairs
    list:         list
    position:     position
    positionOpt:  positionOpt
    feetOpt:      feetOpt
    degtOpt:      degtOpt
    runway:       {
      ident:        runwayIdent
      code:         runwayCode
      open:         runwayOpen
      lighted:      runwayLighted
      logLine:      runwayLogLine
      popupContent: runwayPopupContent

    }
    airport:      {
      ident:        airportIdent
      code:         airportCode
      type:         airportType
      logLine:      airportLogLine
      popupContent: airportPopupContent
    }
    country:      {
      logLine:      countryLogLine
    }
  }
