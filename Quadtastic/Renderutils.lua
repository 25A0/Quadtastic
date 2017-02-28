return {
  draw_border = function(sprite, quads, x, y, w, h)
    -- corners
    love.graphics.draw(sprite, quads.ul, x        , y        )
    love.graphics.draw(sprite, quads.ll, x        , y + h - 3)
    love.graphics.draw(sprite, quads.ur, x + w - 3, y        )
    love.graphics.draw(sprite, quads.lr, x + w - 3, y + h - 3)

    -- borders
    love.graphics.draw(sprite, quads.l, x        , y + 3   , 0, 1  , h-6)
    love.graphics.draw(sprite, quads.r, x + w - 3, y + 3   , 0, 1  , h-6)
    love.graphics.draw(sprite, quads.t, x + 3    , y       , 0, w-6, 1  )
    love.graphics.draw(sprite, quads.b, x + 3    , y + h -3, 0, w-6, 1  )

    -- center
    love.graphics.draw(sprite, quads.c, x + 3, y + 3, 0, w - 6, h - 6)
  end
}