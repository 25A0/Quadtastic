local LoadingAnim = {}

function LoadingAnim.draw(gui_state, x, y, w, h)
  x = x or gui_state.layout.next_x
  y = y or gui_state.layout.next_y
  w = w or gui_state.layout.max_w
  h = h or gui_state.layout.max_h

  local anim_set = gui_state.style.loading
  local frame = 1 + math.fmod(gui_state.t / anim_set.duration, #anim_set.frames)
  frame = math.modf(frame)
  local frame_x = x + math.floor((w - anim_set.w)/2)
  local frame_y = y + math.floor((h - anim_set.h)/2)
  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.draw(anim_set.sheet, anim_set.frames[frame], frame_x, frame_y)
  gui_state.layout.adv_x, gui_state.layout.adv_y = w, h
end

return LoadingAnim