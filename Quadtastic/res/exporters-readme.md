# Custom exporters

You can define your own exporters for an export format of your choice.

```lua

  local exporter = {}

  -- This is the name under which the exporter will be listed in the menu
  exporter.name = "simple format"
  -- This is the default file extension that will be used when the user does not
  -- specify one.
  exporter.ext = "txt"

  function exporter.export(quads)

  end

  return exporter

```