# 
#===============================================================================
# ○ 鼠标拖动判定
#===============================================================================
# - 鼠标按住某个键后，自动开始拖动状态，此时可用以下方法判定：
#
#     boolean = MOUSE_EX.drag?  → 是否处于拖动状态
#
#     sym = MOUSE_EX.drag_key   → 触发拖动状态的鼠标按键
#
#     v   = MOUSE_EX.drag_count → 拖动状态的已持续帧数
#
#     dx, dy = MOUSE_EX.drag_dxy       → 与上一帧位置相比，鼠标的x、y增加量
#
#     dx, dy = MOUSE_EX.drag_dxy_total → 与拖动开始时相比，鼠标的x、y增加量
#
#   当松开按键，将立即结束拖动状态。
#
#   在拖动状态下，如果再按住另一个键，不会重复生效。
#
# - 当鼠标移动速度过快时，可能出现跟不上的情况。
#
module MOUSE_EX
               # [key, count, init xy, last xy, cur - last, cur - init]
  @params_drag = [nil,   0,     0,0,     0,0,       0,0,       0,0]
  def self.update_drag
    if @params_drag[0] == nil
      keys = [:ML, :MM, :MR]
      keys.each do |key|
        break @params_drag = [key, 0, x,y, x,y, 0,0, 0,0] if down?(key)
      end
      return
    end
    return @params_drag[0] = nil if !in? or up?(@params_drag[0],1,0)
    # count 
    @params_drag[1] += 1
    # cur - init
    @params_drag[8] = x - @params_drag[2]; @params_drag[9] = y - @params_drag[3]
    # cur - last
    @params_drag[6] = x - @params_drag[4]; @params_drag[7] = y - @params_drag[5]
    # last xy
    @params_drag[4] = x; @params_drag[5] = y
  end
  def self.drag?
    return false if @params_drag[0] == nil 
    return true
  end
  def self.drag_key
    return @params_drag[0]
  end
  def self.drag_count
    return @params_drag[1]
  end
  def self.drag_dxy
    return @params_drag[6], @params_drag[7]
  end
  def self.drag_dxy_total
    return @params_drag[8], @params_drag[9]
  end
end

class << INPUT_EX
  alias eagle_mouse_ex_update_mouse update_mouse
  def update_mouse
    eagle_mouse_ex_update_mouse
    MOUSE_EX.update_drag
  end
end

class Game_Interpreter
  def show_pic
    s = Sprite.new
    s.bitmap = Bitmap.new(200,200)
    s.bitmap.fill_rect(0,0,200,200,Color.new(255,255,255))
    s.z = 500
    s.ox = s.width / 2; s.oy = s.height / 2
    s.x = Graphics.width / 2; s.y = Graphics.height / 2
    init_x = s.x; init_y = s.y
    loop do 
      if s.mouse_in?
        if MOUSE_EX.drag?
          dx, dy = MOUSE_EX.drag_dxy_total
          s.x = init_x + dx; s.y = init_y + dy
        else
          init_x = s.x; init_y = s.y
        end
      end
      Fiber.yield
    end
  end
end
