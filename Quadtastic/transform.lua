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
local transform_stack = {}

function transform.origin()
	matrix = affine.id()
	lgorigin()
end

function transform.push(...)
	table.insert(transform_stack, matrix)
	lgpush(...)
end

function transform.pop()
	matrix = table.remove(transform_stack)
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

return transform