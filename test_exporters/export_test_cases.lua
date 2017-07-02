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

  ["Group"] = {
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

  ["Nested group"] = {
    {
      scrollpane = {
        buttons = {
          down = {
            default = {x = 80, y = 9, w = 7, h = 7},
            hovered = {x = 112, y = 9, w = 7, h = 7},
            pressed = {x = 112, y = 25, w = 7, h = 7},
          },
          left = {
            default = {x = 96, y = 9, w = 7, h = 7},
            hovered = {x = 121, y = 9, w = 7, h = 7},
            pressed = {x = 121, y = 25, w = 7, h = 7},
          },
          right = {
            default = {x = 96, y = 0, w = 7, h = 7},
            hovered = {x = 121, y = 0, w = 7, h = 7},
            pressed = {x = 121, y = 16, w = 7, h = 7},
          },
          up = {
            default = {x = 80, y = 0, w = 7, h = 7},
            hovered = {x = 112, y = 0, w = 7, h = 7},
            pressed = {x = 112, y = 16, w = 7, h = 7},
          },
        },
        corner = {x = 105, y = 9, w = 7, h = 7},
        scrollbar_h = {
          background = {x = 105, y = 0, w = 1, h = 7},
          center = {x = 108, y = 0, w = 1, h = 7},
          left = {x = 106, y = 0, w = 2, h = 7},
          right = {x = 109, y = 0, w = 2, h = 7},
        },
        scrollbar_v = {
          background = {x = 105, y = 0, w = 7, h = 1},
          bottom = {x = 105, y = 4, w = 7, h = 2},
          center = {x = 105, y = 3, w = 7, h = 1},
          top = {x = 105, y = 1, w = 7, h = 2},
        },
      },
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
