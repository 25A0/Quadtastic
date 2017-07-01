-- A set of test projects that exporters might encounter
return {
  ["empty project"] = {},

  ["Single quad"] = {
    {["a quad"] = {x = 4, y = 12, w = 8, h = 8}},
  },

  ["Nested group"] = {
    {
      ["a group"] = {
        ["first quad"] = {x = 4, y = 12, w = 4, h = 8},
        ["second quad"] = {x = 8, y = 12, w = 4, h = 8},
        ["third quad"] = {x = 12, y = 12, w = 4, h = 8},
        ["fourth quad"] = {x = 16, y = 12, w = 4, h = 8},
      },
      ["a quad"] = {x = 4, y = 4, w = 8, h = 8},
    },
  },
}
