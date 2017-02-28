local inspect = require("lib/inspect")

if os.getenv("DEBUG") then
  require("lib/lovedebug/lovedebug")
  require("debugconfig")
end

text = "Hello World!"

function love.load()
  font = love.graphics.newFont("res/m5x7.ttf", 16)
  love.graphics.setFont(font)
end

function love.draw()
  love.graphics.print(text, 400, 300)
end

function love.mousepressed(x, y, button)

end

function love.mousemoved(x, y, dx, dy)

end


function love.update()
end
