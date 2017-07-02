-- A set of test projects that exporters might encounter
return {
  ["empty project"] = {{}},

  ["Single quad"] = {
    {["a quad"] = {x = 4, y = 12, w = 8, h = 8}},
  },

  ["Metatable"] = {
    {
      ["a quad"] = {x = 4, y = 12, w = 8, h = 8},
      ["_META"] = {image_path = "foobar"},
    },
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

  ["Mixed key types"] = {
    {
      ["a group"] = {
        ["first quad"] = {x = 4, y = 12, w = 4, h = 8},
        ["second quad"] = {x = 8, y = 12, w = 4, h = 8},
        ["third quad"] = {x = 12, y = 12, w = 4, h = 8},
        {x = 16, y = 12, w = 4, h = 8},
        [4] = {x = 20, y = 12, w = 4, h = 8},
      },
      ["a quad"] = {x = 4, y = 4, w = 8, h = 8},
    },
  },

  ["Names that make a group look like a quad"] = {
    {
      ["a group"] = {
        x = {x = 4, y = 12, w = 4, h = 8},
        y = {x = 8, y = 12, w = 4, h = 8},
        w = {x = 12, y = 12, w = 4, h = 8},
        h = {x = 16, y = 12, w = 4, h = 8},
      },
    },
  },

  ["Special characters"] = {
    {
      ["a group"] = {
        ["first qüäd"] = {x = 4, y = 12, w = 4, h = 8},
        ["ßecønd quad"] = {x = 8, y = 12, w = 4, h = 8},
        ["third/\\}\";'' quad"] = {x = 12, y = 12, w = 4, h = 8},
      },
      ["a quad"] = {x = 4, y = 4, w = 8, h = 8},
    },
  },

}
