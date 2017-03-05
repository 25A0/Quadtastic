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

local Transform = {}

setmetatable(Transform,
	{
		__call = function(_, matrix, scale_tbl)
			local transform = setmetatable({}, {__index = Transform})
			transform.matrix = matrix or affine.id()
			transform.scale_tbl = scale_tbl or {1, 1}
			transform.transform_stack = {}
			transform.scale_stack = {}
			return transform
		end,
	})

function Transform.origin(self)
	self.matrix = affine.id()
	self.scale_tbl = {1, 1}
	lgorigin()
end

function Transform.push(self, ...)
	table.insert(self.transform_stack, affine.clone(self.matrix))
	table.insert(self.scale_stack, {self.scale_tbl[1], self.scale_tbl[2]})
	lgpush(...)
end

function Transform.pop(self)
	self.matrix = table.remove(self.transform_stack)
	self.scale_tbl = table.remove(self.scale_stack)
	lgpop()
end

-- function Transform.setScissor()
-- end

-- function Transform.getScissor()
-- end

-- function Transform.intersectScissor()
-- end

function Transform.translate(self, dx, dy)
	self.matrix = self.matrix * affine.trans(dx, dy)
	lgtranslate(dx, dy)
end

function Transform.rotate(self, theta)
	self.matrix = self.matrix * affine.rotate(theta)
	lgrotate(theta)
end

function Transform.scale(self, sx, sy)
	self.matrix = self.matrix * affine.scale(sx, sy)
	self.scale_tbl[1], self.scale_tbl[2] = self.scale_tbl[1] * sx, self.scale_tbl[2] * sy
	lgscale(sx, sy)
end

function Transform.shear(self, kx, ky)
	self.matrix = self.matrix * affine.shear(kx, ky)
	lgshear(kx, ky)
end

function Transform.project(self, x, y)
	return self.matrix(x, y)
end

function Transform.unproject(self, x, y)
	return (affine.inverse(self.matrix))(x, y)
end

function Transform.project_dimensions(self, w, h)
	return w * self.scale_tbl[1], h * self.scale_tbl[2]
end

function Transform.unproject_dimensions(self, w, h)
	return w / self.scale_tbl[1], h / self.scale_tbl[2]
end

function Transform.clone(self)
	return Transform(self.matrix, self.scale_tbl)
end

return Transform