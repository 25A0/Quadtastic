local affine = require("lib/affine")

-- Storing a reference here since we will replace the function pointers later
local lgorigin = love.graphics.origin
local lgscale = love.graphics.scale
local lgrotate = love.graphics.rotate
local lgshear = love.graphics.shear
local lgtranslate = love.graphics.translate
local lgpush = love.graphics.push
local lgpop = love.graphics.pop
-- local lggetscissor = love.graphics.getScissor
-- local lgsetscissor = love.graphics.setScissor
-- local lgintersectscissor = love.graphics.intersectScissor

local transform = {}

local matrix = affine.id()
local scale = {1, 1}
local transform_stack = {}
local scale_stack = {}

function transform.origin()
	matrix = affine.id()
	scale = {1, 1}
	lgorigin()
end

function transform.push(...)
	table.insert(transform_stack, matrix)
	table.insert(scale_stack, scale)
	lgpush(...)
end

function transform.pop()
	matrix = table.remove(transform_stack)
	scale = table.remove(scale_stack)
	lgpop()
end

-- function transform.setScissor()
-- end

-- function transform.getScissor()
-- end

-- function transform.intersectScissor()
-- end

function transform.translate(dx, dy)
	matrix = matrix * affine.trans(dx, dy)
	lgtranslate(dx, dy)
end

function transform.rotate(theta)
	matrix = matrix * affine.rotate(theta)
	lgrotate(theta)
end

function transform.scale(sx, sy)
	matrix = matrix * affine.scale(sx, sy)
	scale[1], scale[2] = scale[1] * sx, scale[2] * sy
	lgscale(sx, sy)
end

function transform.shear(kx, ky)
	matrix = matrix * affine.shear(kx, ky)
	lgshear(kx, ky)
end

function transform.project(x, y)
	return matrix(x, y)
end

function transform.unproject(x, y)
	return (affine.inverse(matrix))(x, y)
end

function transform.project_dimensions(w, h)
	return w * scale[1], h * scale[2]
end

function transform.unproject_dimensions(w, h)
	return w / scale[1], h / scale[2]
end

return transform