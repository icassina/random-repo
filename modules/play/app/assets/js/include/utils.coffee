root = exports ? this

root.utils = {
  foldOpt: (value) -> (none) -> (somef) ->
    if value?
      somef(value)
    else
      none
}
