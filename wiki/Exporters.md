When the default save format is not useful to you, you can use the pre-defined
exporters to export your quad definitions to a different format.
Open 'File' -> 'Export as...' to see which export formats are available.

This page will cover how you can write your own exporter. See [this
page](/Exporter/README.md) instead
for information about the available exporters.

## Custom exporters

You can write your own exporter if the provided exporters don't fit your needs.

Choose 'File' -> 'Export as...' -> 'Manage exporters' to open the directory that
contains custom exporters. Any Lua module in this directory that qualifies as an
exporter will be listed in Quadtastic.

### Exporter structure

You can use the provided template (`exporter_template.lua`) to get started. Be
sure to uncomment the last line so that the module is actually recognized as an
exporter.

A valid exporter module must return a table that contains the following fields:

 - a string `name` that contains the name of the exporter,
 - a string 'ext' that contains the default file extension of the exported file, and
 - a function `export(write, project, info)` that exports the quad definitions.

There are also some optional fields you might find useful:

 - a function `can_export(project)` that you can use to define which projects
   can be exported by your exporter, and
 - a table `test_cases` that you can use if you want to test your exporter
   semi-automatically (see [Testing](#testing) below).

So, an exporter can look like this:

```lua
local exporter = {

  name = "Dummy format",

  ext = "txt",

  export = function(write, project, info)
    write("This does not actually export anything. What a disappointment!")
  end,

  -- optionally:
  can_export = function(project)
    return true -- This exporter can export all projects
  end,

  -- optionally:
  test_cases = {
    ["A simple test case"] = {
      -- input table
      {["a quad"] = {x = 4, y = 12, w = 8, h = 8}},
      -- expected output
      [[a quad: 4, 12, 8, 8]],
    },
  }

}

return exporter
```

The individual fields are explained in more detail below.

#### Name `name`

This is the name under which the exporter will be listed in Quadtastic.

Use a name that represents what kind of file this exporter produces. For
example, if this produces a sprite sheet in a format that can be used in game
engine X, then "X sprite sheet" would be a good name.

The name will be displayed in Quadtastic in the menu 'File' -> 'Export as...',
so your name should make sense if it is read as "Export as..." + your name.
Thus, "exporter for X sprite sheets" is a bad name since it would be displayed
as "Export as... exporter for X sprite sheets".

#### Extension `ext`

This is the default file extension that will be used when the user does not
specify one.

#### The `export` function

This is the function that exports the quad definitions in the way you want.

The function must have the signature `export(write, project, info)`. Here,
`write` is a function that accepts varargs that can be converted to string and
appends them to the output file. You can treat it like the `print(...)` function
in the standard library, with the exception that this function does not append
line breaks automatically. `project` is the table that contains the quads you
defined, as well as  the metatable under the '_META' key. You can ignore the
metatable if you don't need it. Finally, `info` is a table that contains
additional information that might be useful for the exporter. Currently it only
contains `filepath` -- the full path and filename of the file that the exported
quad definitions will be written to. It might be expanded in the future.

##### Deterministic table iterator

Lua's `pair` function is non-deterministic, meaning that each time you use it,
it might iterate over the items in the table in a different order. This is fine
in most cases, but this non-determinism can lead to large diffs when the
exported files are under version control.

You can use a deterministic iterator that iterates over the items of a table in
a predictable order to fix this problem. If you don't want to write your own,
you can use `det_pairs` that is available in Quadtastic's `common` module.
That could look like this:

```lua
local common = require("Quadtastic.common")

local exporter = {}

-- other functions omitted

function exporter.export(write, project, info)
  -- This will always iterate over the elements of project in the same order.
  for k, v in common.det_pairs(project) do
    -- ...
  end
end

return exporter
```

Note that you can get unexpected results when you mix using `det_pairs` and the
regular `next` function. If you do need the functionality of `next`, you can use
the deterministic variant like so:

```lua
local det_next = common.det_pairs(tab)

if det_next(tab) then
  -- tab is not empty
end

-- No need to call common.det_pairs again if you already have the det_next
-- function for this particular table.
for k, v in det_next, tab do
  -- you can use det_next just like you would use next.
  if det_next(tab, k) then
    -- k was not the last index of the table when iterated
  end
end
```

**Caveat**: Because of the underlying magic™, the function `det_next` that is
returned by `det_pairs(tab)` only works for the table `tab`, and not for any
other table.

#### The `can_export` function

Not all export formats are as flexible as Lua tables. For example, JSON cannot
handle tables that have both, numeric and string keys.

In case your exporter cannot handle arbitrary projects, you can define a
function `can_export(project)` to check the project before it is passed to the
`export` function. This function should return `true` if your exporter is able
to process the project, and `false` otherwise.

If `false` is returned, a string can be returned as the second return value that
will be displayed as the reason why your exporter cannot handle the project. You
can use this to explain how users can alter their quad definitions so that they
can be exported.

### Testing

You should test your exporter (duh!), especially if you plan to share it with
others. Quadtastic comes with a tool that you can use to test your exporter with
some example projects to make sure that it does not crash when it encounters
things like empty projects, non-ASCII characters, tables with both numeric and
string keys and so on. When your exporter does not support certain projects by
design, you can check for those projects in `can_export`, and provide an
appropriate error message that helps the user understand why your exporter does
not support that.

The file [`test_exporters/README.md`](/test_exporters/README.md)
explains how you can use the testing tool.

You can use the table `test_cases` to provide additional test cases. Each table
entry should be a table. The first element of that table is the project to
be exported, and the second element is the string you expect your exporter
to produce for that project. If you omit the second element, the test will
merely check that the exporter does not crash when exporting your test
project.

## Sharing

If you think that your custom exporter could be useful for others, consider
adding it to the GitHub repo with a pull request.

