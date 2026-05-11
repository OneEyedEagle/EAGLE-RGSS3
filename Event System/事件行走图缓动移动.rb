#==============================================================================
# ■ 事件行走图缓动移动 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# 【此插件兼容VX和VX Ace】
# ※ 本插件需要放置在【组件-缓动函数 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-CharacterMoveEase"] = "1.0.0"
#==============================================================================
# - 2026.5.11.21 兼容VX
#==============================================================================
# - 本插件新增了行走图的缓动移动。
#
# - 对于地图上的行走图（事件/玩家）：
#
#   1. 让角色进行一次缓动移动：
#
#      对于1号事件： $game_map.events[1].move_straight_ease(d, n, t, ease)
#      对于玩家：    $game_player.move_straight_ease(d, n, t, ease)
#
#      其中 d 是移动的方向（2-往下，4-往左，6-往右，8-往下，0-当前）。
#
#      其中 n 是移动的步数，如果途中有不可通行的区域，则自动在前一格停止。
#
#      其中 t 是移动的所需帧数。
#
#      其中 ease 是【组件-缓动函数】中的缓动函数名称（字符串）。
#
#   2. 在移动路线中调用：
#
#        move_straight_ease(d, n, t, ease)
#
# - 示例：
#
#   1. 7号事件在30帧内往右移动10格。
#
#        $game_map.events[7].move_straight_ease(6, 10, 30, "easeInSine")
#
#   2. 玩家在60帧内朝前移动5格。
#
#        $game_player.move_straight_ease(0, 5, 60, "easeInSine")
#
#==============================================================================

#-----------------------------------------------------------------------------
# 【兼容VX】
#-----------------------------------------------------------------------------
MODE_VX = RUBY_VERSION[0..2] == "1.8"

if MODE_VX

class Game_Character
  #--------------------------------------------------------------------------
  # ● 初始化对像
  #--------------------------------------------------------------------------
  alias eagle_ease_move_initialize initialize
  def initialize
    eagle_ease_move_initialize
    @ease_params = { :active => false }
  end

  #--------------------------------------------------------------------------
  # ● 径向移动
  #     d       : 方向（2,4,6,8）
  #     n       ：步数
  #     ease    ：缓动函数名称
  #     turn_ok : 是否可以改变方向
  #--------------------------------------------------------------------------
  def move_straight_ease(d, n=1, t=20, ease="easeInCubic", turn_ok=true)
    _x = @x; _y = @y; _n = 0
    d = @direction if d == 0
    n.times do |i| 
      f = false
      case d 
        when 2; passable?(_x, _y+1) ? _y = $game_map.round_y(_y+1) : f = true
        when 4; passable?(_x-1, _y) ? _x = $game_map.round_x(_x-1) : f = true
        when 6; passable?(_x+1, _y) ? _x = $game_map.round_x(_x+1) : f = true
        when 8; passable?(_x, _y-1) ? _y = $game_map.round_y(_y-1) : f = true
      end
      break if f
      _n += 1
    end
    if _n > 0
      case d 
        when 2; turn_down
        when 4; turn_left
        when 6; turn_right
        when 8; turn_up
      end
      @x = _x
      @y = _y
      @ease_params[:active] = true
      @ease_params[:type] = ease
      @ease_params[:x0] = @real_x; @ease_params[:x1] = @x * 256
      @ease_params[:dx] = @ease_params[:x1] - @ease_params[:x0]
      @ease_params[:y0] = @real_y; @ease_params[:y1] = @y * 256
      @ease_params[:dy] = @ease_params[:y1] - @ease_params[:y0]
      @ease_params[:t] = t
      @ease_params[:c] = 0
      @move_failed = false
      increase_steps
    elsif turn_ok
      case d 
        when 2; turn_down; check_event_trigger_touch(@x, @y+1)
        when 4; turn_left; check_event_trigger_touch(@x-1, @y)
        when 6; turn_right;check_event_trigger_touch(@x+1, @y)
        when 8; turn_up;   check_event_trigger_touch(@x, @y-1)
      end
      @move_failed = true
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 更新移动
  #--------------------------------------------------------------------------
  alias eagle_ease_move_update_move update_move
  def update_move
    return update_move_ease if @ease_params[:active]
    eagle_ease_move_update_move
  end

  # 更新缓动移动
  def update_move_ease
    @ease_params[:c] += 1
    per = @ease_params[:c] * 1.0 / @ease_params[:t]
    v = EasingFuction.call(@ease_params[:type], per)
    if @ease_params[:c] == @ease_params[:t]
      @real_x = @ease_params[:x1]
      @real_y = @ease_params[:y1]
      @ease_params[:active] = false 
    else
      @real_x = @ease_params[:x0] + @ease_params[:dx] * v
      @real_y = @ease_params[:y0] + @ease_params[:dy] * v
    end
    update_bush_depth unless moving?
  end
end
  
else  # VA

class Game_CharacterBase
  #--------------------------------------------------------------------------
  # ● 初始化公有成员变量
  #--------------------------------------------------------------------------
  alias eagle_ease_move_init_public_members init_public_members
  def init_public_members
    eagle_ease_move_init_public_members
    @ease_params = { :active => false }
  end

  #--------------------------------------------------------------------------
  # ● 径向移动
  #     d       : 方向（2,4,6,8）
  #     n       ：步数
  #     ease    ：缓动函数名称
  #     turn_ok : 是否可以改变方向
  #--------------------------------------------------------------------------
  def move_straight_ease(d, n=1, t=20, ease="easeInCubic", turn_ok=true)
    _x = @x; _y = @y; _n = 0
    d = @direction if d == 0
    n.times do |i| 
      if passable?(_x, _y, d)
        _x = $game_map.round_x_with_direction(_x, d)
        _y = $game_map.round_y_with_direction(_y, d)
        _n += 1
      else
        break
      end
    end
    if _n > 0
      set_direction(d)
      @x = _x
      @y = _y
      @ease_params[:active] = true
      @ease_params[:type] = ease
      @ease_params[:x0] = @real_x; @ease_params[:x1] = @x
      @ease_params[:dx] = @ease_params[:x1] - @ease_params[:x0]
      @ease_params[:y0] = @real_y; @ease_params[:y1] = @y
      @ease_params[:dy] = @ease_params[:y1] - @ease_params[:y0]
      @ease_params[:t] = t
      @ease_params[:c] = 0
      increase_steps
    elsif turn_ok
      set_direction(d)
      check_event_trigger_touch_front
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 更新移动
  #--------------------------------------------------------------------------
  alias eagle_ease_move_update_move update_move
  def update_move
    return update_move_ease if @ease_params[:active]
    eagle_ease_move_update_move
  end

  # 更新缓动移动
  def update_move_ease
    @ease_params[:c] += 1
    per = @ease_params[:c] * 1.0 / @ease_params[:t]
    v = EasingFuction.call(@ease_params[:type], per)
    if @ease_params[:c] == @ease_params[:t]
      @real_x = @ease_params[:x1]
      @real_y = @ease_params[:y1]
      @ease_params[:active] = false 
    else
      @real_x = @ease_params[:x0] + @ease_params[:dx] * v
      @real_y = @ease_params[:y0] + @ease_params[:dy] * v
    end
    update_bush_depth unless moving?
  end
end

end
