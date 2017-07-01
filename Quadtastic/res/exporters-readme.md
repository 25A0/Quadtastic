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

  -- `writer` is a function that accepts varargs that can be converted to string
  -- and appends them to the output file. You can treat it like the print()
  -- function in the standard library, with the exception that this function
  -- does not append line breaks automatically.
  -- `project` is the table that contains the quads you defined, as well as
  -- the metatable under the '_META' key. You can ignore the metatable if you
  -- don't need it.
  function exporter.export(writer, project)

  end

  -- In case your exporter cannot handle arbitrary projects, you can use this
  -- function to check the project before it is passed to the export function.
  -- This function should return true if your exporter is able to process the
  -- project, and false otherwise.
  --
  -- If false is returned, a string can be returned as the second return value
  -- that will be displayed as the reason why your exporter cannot handle the
  -- project. For example, JSON cannot handle tables that have both, numeric and
  -- string keys. You should make use of this to explain how users can alter
  -- their quad definitions so that they can be exported.
  function exporter.can_export(project)
    return true
  end

  -- You should test your exporter, especially if you plan to share it with
  -- others. When you run TODO, a few default projects will be thrown at your
  -- exporter to make sure that it does not crash when it encounters things like
  -- empty projects, non-ASCII characters, tables with both numeric and string
  -- keys and so on. When your exporter does not support certain projects by
  -- design, you can check for those projects in `can_export`, and provide an
  -- appropriate error message that helps the user understand why your exporter
  -- does not support that.
  --
  -- You can use the table below to provide additional test cases. Each table
  -- entry should be a table. The first element of that table is the project to
  -- be exported, and the second element is the string you expect your exporter
  -- to produce for that project. If you omit the second element, the test will
  -- merely check that the exporter does not crash when exporting your test
  -- project.
  exporter.test_cases = {
    ["Single quad"] = {
      -- input table
      {["a quad"] = {x = 4, y = 12, w = 8, h = 8}},
      -- expected output
      [[a quad: 4, 12, 8, 8]],
    },
    ["Nested group"] = {
      -- input table
      {
        ["a group"] = {
          ["first quad"] = {x = 4, y = 12, w = 4, h = 8},
          ["second quad"] = {x = 8, y = 12, w = 4, h = 8},
          ["third quad"] = {x = 12, y = 12, w = 4, h = 8},
          ["fourth quad"] = {x = 16, y = 12, w = 4, h = 8},
        },
        ["a quad"] = {x = 4, y = 4, w = 8, h = 8},
      },
      -- expected output
      [[...]],
    },
  }

  return exporter

```

Choose 'File' -> 'Export as' -> 'Manage exporters' to open the directory that
contains custom exporters. Any .lua files here that define the properties and
function above in this


If you suspect that your custom exporter could be useful for others, consider
adding it to the GitHub repo with a pull request.
