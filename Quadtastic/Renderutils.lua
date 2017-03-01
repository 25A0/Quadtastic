return {
  draw_border = function(sprite, quads, x, y, w, h, s)
    -- corners
    love.graphics.draw(sprite, quads.ul, x        , y        )
    love.graphics.draw(sprite, quads.ll, x        , y + h - s)
    love.graphics.draw(sprite, quads.ur, x + w - s, y        )
    love.graphics.draw(sprite, quads.lr, x + w - s, y + h - s)

    -- borders
    love.graphics.draw(sprite, quads.l, x        , y + s   , 0, 1    , h-2*s)
    love.graphics.draw(sprite, quads.r, x + w - s, y + s   , 0, 1    , h-2*s)
    love.graphics.draw(sprite, quads.t, x + s    , y       , 0, w-2*s,     1)
    love.graphics.draw(sprite, quads.b, x + s    , y + h -s, 0, w-2*s,     1)

    -- center
    love.graphics.draw(sprite, quads.c, x + s, y + s, 0, w - 2*s, h - 2*s)
  end,

  border_quads = function(base_x, base_y, 
                          width, height, 
                          sprite_w, sprite_h,
                          corner_size)
    return {
      ul = love.graphics.newQuad(
        base_x, base_y, corner_size, corner_size, sprite_w, sprite_h),
       l = love.graphics.newQuad(
        base_x, base_y + corner_size, corner_size, 1, sprite_w, sprite_h),
      ll = love.graphics.newQuad(
        base_x, base_y + height - corner_size, corner_size, corner_size, sprite_w, sprite_h),
       b = love.graphics.newQuad(
        base_x + corner_size, base_y + height - corner_size, 1, corner_size, sprite_w, sprite_h),
      lr = love.graphics.newQuad(
        base_x + width - corner_size, base_y + height - corner_size, corner_size, corner_size, sprite_w, sprite_h),
       r = love.graphics.newQuad(
        base_x + width - corner_size, base_y + corner_size, corner_size, 1, sprite_w, sprite_h),
      ur = love.graphics.newQuad(
        base_x + width - corner_size, base_y, corner_size, corner_size, sprite_w, sprite_h),
       t = love.graphics.newQuad(
        base_x + corner_size, base_y, 1, corner_size, sprite_w, sprite_h),
       c = love.graphics.newQuad(
        base_x + corner_size, base_y + corner_size, 1, 1, sprite_w, sprite_h),
    }
  end,
}