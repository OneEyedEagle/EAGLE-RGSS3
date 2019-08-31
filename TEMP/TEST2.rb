class Game_Player < Game_Character
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  alias eagle_init initialize
  def initialize
    eagle_init
    @_x = 2
    @_y = 3
  end
  #--------------------------------------------------------------------------
  # ● 获取画面 X 坐标
  #--------------------------------------------------------------------------
  def screen_x
    $game_map.adjust_x(@real_x) * 32 + (@_x-2)*8 + 16
  end
  #--------------------------------------------------------------------------
  # ● 获取画面 Y 坐标
  #--------------------------------------------------------------------------
  def screen_y
    $game_map.adjust_y(@real_y) * 32 - (3-@_y)*8 + 32 - shift_y - jump_height
  end
  #--------------------------------------------------------------------------
  # ● 由方向键移动
  #--------------------------------------------------------------------------
  def move_by_input
    return if !movable? || $game_map.interpreter.running?
    case Input.dir4
    when 8
      @_y -= 1
      if @_y == -1
        @_y = 3
        move_straight(8)
      end
    when 2
      @_y += 1
      if @_y == 4
        @_y = 0
        move_straight(2)
      end
    when 4
      @_x -= 1
      if @_x == -1
        @_x = 3
        move_straight(4)
      end
    when 6
      @_x += 1
      if @_x == 4
        @_x = 0
        move_straight(6)
      end
    end
    #move_straight(Input.dir4) if Input.dir4 > 0
  end
end
