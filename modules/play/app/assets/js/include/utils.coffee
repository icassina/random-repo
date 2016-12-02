root = exports ? this

root.utils = {
  identity: (value) -> value
  foldOpt: (value) -> (none) -> (somef) ->
    if value?
      somef(value)
    else
      none
}
