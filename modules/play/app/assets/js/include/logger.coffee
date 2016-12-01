root = exports ? this

### Logger(config)
# requires:
#   * lib/jquery/jquery.js
#   * js/include/symbols
#
# <- config:
#   maxLogLines: <int>  number of lines to display
#
# ->
#   trace:  (line) ->
#   debug:  (line) ->
#   info:   (line) ->
#   warn:   (line) ->
#   out:    (url) ->
#   in:     (url) ->
#   err:    (url, status, error) ->
#   clear:  () ->
###
root.Logger = (config) ->
  logArea = $('#query-log-area')
  maxLogLines = config.maxLogLines
  logLines = []

  level2class = (lvl) ->
    switch (lvl)
      when 'trace'  then 'text-muted'
      when 'debug'  then 'text-muted'
      when 'info'   then 'text-warning'
      when 'in'     then 'text-primary'
      when 'out'    then 'text-success'
      when 'warn'   then 'text-danger'
      when 'err'    then 'text-danger'
      else ''

  _log = (level) -> (line) ->
    pClass = level2class(level)

    if logLines.length >= maxLogLines
      logLines.shift()
      logArea.children().first().remove()

    logLines.push(line)
    logArea.append("""<p class="log-line #{pClass}">#{line}</p>""")

  for i in [0 .. maxLogLines]
    _log('__internal__')(symbols.space)

  clear = () ->
    logLines = []
    logArea.empty()

  _out  = (url) ->
    _log('out')("#{symbols.rArrow} GET #{url}")

  _in   = (url) ->
    _log('in') ("#{symbols.lArrow} GET #{url}")

  _err  = (url, status, error) ->
    _log('err') ("#{symbols.lArrow} GET #{url}: Error: #{status} #{error}")

  {
    trace:  _log('trace')
    debug:  _log('debug')
    info:   _log('info')
    warn:   _log('warn')
    out:    _out
    in:     _in
    err:    _err
    clear:  clear
  }
