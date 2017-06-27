# Custom exporters

You can define your own exporters for an export format of your choice.

```lua

  local exporter = {}

  -- This is the name under which the exporter will be listed in the menu.
  --
  -- Use a name that represents what kind of file this exporter produces.
  -- For example, if this produces a sprite sheet that can be used in game
  -- engine X, then "X sprite sheet" would be a good name.
  --
  -- The name should make sense if it is read as: "Export as..." + your name.
  -- So, "exporter for X sprite sheets" is a bad name since it would be
  -- displayed as "Export as... exporter for X sprite sheets".
  exporter.name = "simple format"

  -- This is the default file extension that will be used when the user does not
  -- specify one.
  exporter.ext = "txt"

  -- 'writer' is a function that accepts varargs that can be converted to string
  -- and appends them to the output file. You can treat it like the print()
  -- function in the standard library, with the exception that this function
  -- does not append line breaks automatically.
  -- quads is the table that contains the quads you defined, as well as
  -- the metatable under the '_META' key. You can ignore the metatable if you
  -- don't need it.
  function exporter.export(writer, quads)

  end

  return exporter

```

Choose 'File' -> 'Export as' -> 'Manage exporters' to open the directory that
contains custom exporters. Any .lua files here that define the properties and
function above in this


If you suspect that your custom exporter could be useful for others, consider
adding it to the GitHub repo with a pull request.
