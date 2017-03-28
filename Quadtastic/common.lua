-- Utility functions that don't deserve their own module

local common = {}

-- Load an image from outside the game's source and save folder
function common.load_image(filepath)
  local filehandle, err = io.open(filepath, "rb")
  if err then
    error(err)
  end
  local filecontent = filehandle:read("*a")
  filehandle:close()
  local imagedata = love.image.newImageData(
    love.filesystem.newFileData(filecontent, 'img', 'file'))
  return love.graphics.newImage(imagedata)
end

return common
