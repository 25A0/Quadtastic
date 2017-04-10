local libquadtastic = require("libquadtastic")

local image, raw_quads, quads, liquid
local bubble_pos
local tube = {x = (400-14) / 2, y = (300 - 30) / 2, w = 14, h = 30}

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")

  raw_quads = require("res/quads") -- load raw quad definitions
  image = love.graphics.newImage("res/sheet.png") -- load spritesheet

  -- Create LOVE Quads from raw quad definitions
  quads = libquadtastic.create_quads(raw_quads, image:getWidth(), image:getHeight())
  -- Extract color value from spritesheet. In this case we just extract a single
  -- color, but we could also pass in a table of quads.
  liquid = libquadtastic.create_palette(raw_quads.liquid, image)

  bubble_pos = {}
  for i, raw_bubble in ipairs(raw_quads.bubbles) do
    bubble_pos[i] = {
      x = tube.x + love.math.random(0, tube.w - raw_bubble.w),
      y = 0,
      time_delta = love.math.random(0, 2*math.pi)
    }
  end
end

function love.draw()
  love.graphics.scale(2, 2)
  love.graphics.clear(255, 255, 255)

  love.graphics.draw(image, quads.base, tube.x - 1, tube.y + tube.h - raw_quads.base.h)

  for i=1,#quads.bubbles do
    love.graphics.draw(image, quads.bubbles[i], bubble_pos[i].x, bubble_pos[i].y)
  end

  love.graphics.setColor(liquid)
  love.graphics.rectangle("fill", tube.x, tube.y, tube.w, tube.h)

  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.draw(image, quads.stand, tube.x - 1, tube.y + tube.h - 3)
  love.graphics.draw(image, quads.lid, tube.x - 1, tube.y + 3 - raw_quads.lid.h)
end

function love.update()
  for i, pos in ipairs(bubble_pos) do
    pos.y = math.floor(tube.y + (tube.h/2 - 2) *
            (1 + math.sin(pos.time_delta + love.timer.getTime() / 4)))
    pos.x = math.floor(tube.x + ((tube.w - raw_quads.bubbles[i].w)/2) *
            (1 + math.sin(pos.time_delta + love.timer.getTime() / 8)))
  end
end
