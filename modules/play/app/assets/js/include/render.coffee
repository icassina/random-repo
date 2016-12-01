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
  renderOption = (value, someTag, noneTag) ->
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

  renderBoolean = (name) -> (bool) ->
    if bool
      """<span class="label label-success"><abbr title="#{name}: yes">#{symbols.true}</abbr></span>"""
    else
      """<span class="label label-danger"><abbr title="#{name}: no">#{symbols.false}</abbr></span>"""

  renderLink = (link, text, alt) ->
    if link?
      """<a href="#{link}" target="_blank"">#{text}</a>"""
    else
      """#{alt}"""

  renderPosition = (coords) -> """<strong><span class="text-primary">#{ol.coordinate.toStringHDMS(coords)}</span></strong>"""

  renderPositionOpt = (coords) -> utils.foldOpt(p)(symbols.emptySet)(renderPosition)

  renderFeetOpt = (value) -> utils.foldOpt(value)(symbols.emptySet)((v) -> """<strong>#{v}</strong> (ft)""")

  renderIdent = (runway) ->
    """#{renderOption(runway.leIdent, 'strong')} | #{renderOption(runway.heIdent, 'strong')}"""

  renderOpen = (runway) ->
    renderBoolean('Open')(! runway.closed)

  renderLighted = (runway) ->
    renderBoolean('Lighted')(runway.lighted)

  renderAirportLogLine = (airport) ->
    extraInfo = ->
      pre = if airport.municipality? then "in #{airport.municipality}" else "in"
      "#{pre} #{airport.isoRegion} (#{airport.airportType})"

    """
      #{symbols.airplane} ##{airport.id} [#{airport.ident}] #{airport.name} #{extraInfo()}
    """

  renderRunwayLogLine = (runway) ->
    ident = renderIdent(runway)
    length = utils.foldOpt(runway.length)('')((l) -> ", length: #{l}")
    width = utils.foldOpt(runway.width)('')((w) -> ", width: #{w}")
    lighted = ", lighted: #{renderLighted(runway)}"
    open = ", open: #{renderOpen(runway)}"

    """
      #{symbols.upArrow} ##{runway.id} [#{ident}] #{runway.surface}#{length}#{width}#{open}#{lighted}
    """

  renderCountryLogLine = (country) ->
    """
    """

  {
    option:       renderOption
    boolean:      renderBoolean
    link:         renderLink
    position:     renderPosition
    positionOpt:  renderPositionOpt
    feetOpt:      renderFeetOpt
    runway:       {
      ident:        renderIdent
      open:         renderOpen
      lighted:      renderLighted
      logLine:      renderRunwayLogLine
    }
    airport:      {
      logLine:      renderAirportLogLine
    }
    country:      {
      logLine:      renderCountryLogLine
    }
  }
