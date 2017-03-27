local fun = require("Quadtastic.fun")

do
  local t = {1, 2, 3}
  local f = function(x) return x + 3 end
  fun.map(f, t)
  assert(t[1] == 4)
  assert(t[2] == 5)
  assert(t[3] == 6)
end

do
  local f = function(x) return math.fmod(x, 2) == 0 end
  assert(fun.any(f, {1, 2, 3}) == true)
  assert(fun.any(f, {1, 5, 3}) == false)
end

do
  local f = function(x) return math.fmod(x, 2) == 0 end
  assert(fun.all(f, {1, 2, 3}) == false)
  assert(fun.any(f, {2, 4, -128}) == true)
end

do
  local f = function(x) return math.fmod(x, 2) == 0 end
  local filtered = fun.filter(f, {1, 2, 3, 4, 5, 15, -128})
  assert(#filtered == 3)
  assert(filtered[1] == 2)
  assert(filtered[2] == 4)
  assert(filtered[3] == -128)
end

do
  assert(#fun.filter(nil, {}) == 0)
end

do
  local f = function(x, y) return x + y end
  local part = fun.partial(f, 4)
  assert(part(12) == 16)
  assert(part(-4) == 0)
end

do
  local f = function(a, b, c, d, e, f, g, h, i, j, k, l)
    return a + b + c + d + e + f + g + h + i + j + k + l
  end
  local part = fun.partial(f, 1, 2, 3, 4, 5, 6, 7, 8, 9)
  local expected = 1 + 2 + 3 + 4 + 5 + 6 + 7 + 8 + 9 + 10 + 11 + 12
  assert(part(10, 11, 12) == expected)
end

do
  local f = function(...)
    local sum = 0
    for _,v in ipairs({...}) do
      sum = sum + v
    end
    return sum
  end
  local part = fun.partial(f, 1, 2, 3, 4, 5, 6, 7, 8, 9)
  local expected = 1 + 2 + 3 + 4 + 5 + 6 + 7 + 8 + 9 + 10 + 11 + 12
  assert(part(10, 11, 12) == expected)
end


