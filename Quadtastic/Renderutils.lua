return {
  draw_border = function(sprite, quads, x, y, w, h, s)
    -- corners
    love.graphics.draw(sprite, quads.tl, x        , y        )
    love.graphics.draw(sprite, quads.bl, x        , y + h - s)
    love.graphics.draw(sprite, quads.tr, x + w - s, y        )
    love.graphics.draw(sprite, quads.br, x + w - s, y + h - s)

    -- borders
    love.graphics.draw(sprite, quads.l, x        , y + s   , 0, 1    , h-2*s)
    love.graphics.draw(sprite, quads.r, x + w - s, y + s   , 0, 1    , h-2*s)
    love.graphics.draw(sprite, quads.t, x + s    , y       , 0, w-2*s,     1)
    love.graphics.draw(sprite, quads.b, x + s    , y + h -s, 0, w-2*s,     1)

    -- center
    love.graphics.draw(sprite, quads.c, x + s, y + s, 0, w - 2*s, h - 2*s)
  end,

}