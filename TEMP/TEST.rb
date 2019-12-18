module EAGLE
  #--------------------------------------------------------------------------
  # ● 【常量】细分后格子宽度（像素）
  #--------------------------------------------------------------------------
  GRID_W = 1
  #--------------------------------------------------------------------------
  # ● 原始格子细分后的格子数目
  #--------------------------------------------------------------------------
  def self.grid_n # rgss的一格被拆成了 grid_n x grid_n 格（需要为 32 的约数）
    32 / GRID_W
  end

  #--------------------------------------------------------------------------
  # ● 由RGSS坐标转换为pixel坐标
  #--------------------------------------------------------------------------
  # rgssXY 格子左上角的坐标
  # pixelXY 格子底部中心的坐标
  def self.rgssXY2pixelXY(x, y, xe = 0, ye = 0)
    _x = x * EAGLE.grid_n + 16 / GRID_W + xe
    _y = y * EAGLE.grid_n + 32 / GRID_W + ye
    return _x, _y
  end
  #--------------------------------------------------------------------------
  # ● 由pixel坐标转换为RGSS坐标
  #--------------------------------------------------------------------------
  def self.pixelXY2rgssXY(x, y)
    x = x - 16 / GRID_W
    _x = x / EAGLE.grid_n
    _xe = x - _x * EAGLE.grid_n # rgssXY中无法记录的偏差量
    y = y - 32 / GRID_W
    _y = y / EAGLE.grid_n
    _ye = y - _y * EAGLE.grid_n
    return _x, _y, _xe, _ye
  end

  def self.in_rect?(x, y, rect)
    x >= rect.x && y >= rect.y && x <= rect.x + rect.width && y <= rect.y + rect.height
  end

  def self.rect_collision?(rect1, rect2)
    dx = (rect1.x + rect1.width/2 - rect2.x - rect2.width/2).abs
    dy = (rect1.y + rect1.height/2 - rect2.y - rect2.height/2).abs
    return dx <= rect1.width/2+rect2.width/2 && dy <= rect1.height/2+rect2.height/2
  end
end

class Game_Map
end

class Game_CharacterBase
  #--------------------------------------------------------------------------
  # ● 初始化公有成员变量
  #--------------------------------------------------------------------------
  alias eagle_pixel_move_init init_public_members
  def init_public_members
    eagle_pixel_move_init
    # 以格子底部中心为原点 碰撞矩形
    @collision_rect = Rect.new(-12/EAGLE::GRID_W, -16/EAGLE::GRID_W,
      24/EAGLE::GRID_W, 16/EAGLE::GRID_W)
  end
  #--------------------------------------------------------------------------
  # ● 获取画面 X 坐标
  #--------------------------------------------------------------------------
  def screen_x
    _x = @real_x / EAGLE.grid_n
    _xe = @real_x - _x * EAGLE.grid_n
    return $game_map.adjust_x(_x) * 32 + EAGLE::GRID_W * _xe
  end
  #--------------------------------------------------------------------------
  # ● 获取画面 Y 坐标
  #--------------------------------------------------------------------------
  def screen_y
    _y = @real_y / EAGLE.grid_n
    _ye = @real_y - _y * EAGLE.grid_n
    return $game_map.adjust_y(_y) * 32 + EAGLE::GRID_W * _ye - shift_y - jump_height
  end
  #--------------------------------------------------------------------------
  # ● 坐标一致判定
  #--------------------------------------------------------------------------
  def pos?(x, y) # pixelXY
    rect = @collision_rect
    x >= @x + rect.x && x <= @x + rect.x + rect.width &&
    y >= @y + rect.y && y <= @y + rect.y + rect.height
  end
  #--------------------------------------------------------------------------
  # ● 计算一帧内移动的距离
  #--------------------------------------------------------------------------
  def distance_per_frame
    2 ** real_move_speed / (8.0 * EAGLE::GRID_W)
  end
  #--------------------------------------------------------------------------
  # ● 移动到指定位置
  #--------------------------------------------------------------------------
  def moveto(x, y)
    @x, @y = EAGLE.rgssXY2pixelXY(x % $game_map.width, y % $game_map.height)
    @real_x = @x
    @real_y = @y
    @prelock_direction = 0
    straighten
    update_bush_depth
  end
  #--------------------------------------------------------------------------
  # ● 判定是否可以通行（检查 地图的通行度 和 前方是否有路障）
  #     d : 方向（2,4,6,8）
  #--------------------------------------------------------------------------
  def passable?(x, y, d) # pixelXY
    # 计算碰撞盒坐标 pixelXY（矩形左上为原点）
    rect = @collision_rect.dup
    rect.x += x
    rect.y += y
    # 需要进行判定的点
    points = []
    case d
    when 2 # 碰撞盒左下和右下
      points.push( [rect.x, rect.y+rect.height] )
      points.push( [rect.x+rect.width, rect.y+rect.height])
    when 4
      points.push( [rect.x, rect.y] )
      points.push( [rect.x, rect.y+rect.height])
    when 6
      points.push( [rect.x+rect.width, rect.y] )
      points.push( [rect.x+rect.width, rect.y+rect.height])
    when 8
      points.push( [rect.x, rect.y] )
      points.push( [rect.x+rect.width, rect.y])
    end
    points.each do |point|
      # 实际坐标 rgssXY
      x0 = $game_map.round_x( point[0] / EAGLE.grid_n)
      y0 = $game_map.round_x( point[1] / EAGLE.grid_n)
      # 移动后的坐标 pixelXY
      x2_p = $game_map.x_with_direction(point[0], d)
      y2_p = $game_map.y_with_direction(point[1], d)
      # 移动后的坐标 rgssXY
      x2 = $game_map.round_x(x2_p / EAGLE.grid_n)
      y2 = $game_map.round_y(y2_p / EAGLE.grid_n)
      if x0 != x2 || y0 != y2
        return false unless $game_map.valid?(x2, y2)
        return true if @through || debug_through?
        return false unless map_passable?(x0, y0, d)
        return false unless map_passable?(x2, y2, reverse_dir(d))
      end
      return false if collide_with_characters?(x2_p, y2_p)
    end
    return true
  end
  #--------------------------------------------------------------------------
  # ● 径向移动
  #     d       : 方向（2,4,6,8）
  #     turn_ok : 是否可以改变方向
  #--------------------------------------------------------------------------
  def move_straight(d, turn_ok = true)
   3.times do
    @move_succeed = passable?(@x, @y, d)
    if @move_succeed
      set_direction(d)
      @x = $game_map.round_x_with_direction(@x, d)
      @y = $game_map.round_y_with_direction(@y, d)
      @real_x = $game_map.x_with_direction(@x, reverse_dir(d))
      @real_y = $game_map.y_with_direction(@y, reverse_dir(d))
      increase_steps
    elsif turn_ok
      set_direction(d)
      check_event_trigger_touch_front
    end
   end
  end
end

class Game_Player < Game_Character
  #--------------------------------------------------------------------------
  # ● 判定前方事件是否被启动
  #--------------------------------------------------------------------------
  def check_event_trigger_there(triggers)
    rect = @collision_rect; x = @x + rect.x; y = @y + rect.y
    case @direction
    when 2; x = x + rect.width / 2; y = y + rect.height
    when 4; x = x + rect.x + rect.height / 2; y = y + rect.height / 2
    when 6; x = x + rect.width; y = y + rect.height / 2
    when 8; x = x + rect.width / 2; y = y
    end
    x2 = $game_map.round_x_with_direction(x, @direction)
    y2 = $game_map.round_y_with_direction(y, @direction)
    start_map_event(x2, y2, triggers, true)
    return if $game_map.any_event_starting?
    return unless $game_map.counter?(x2, y2)
    x3 = $game_map.round_x_with_direction(x2, @direction)
    y3 = $game_map.round_y_with_direction(y2, @direction)
    start_map_event(x3, y3, triggers, true)
  end
end

class Game_Event < Game_Character
  #--------------------------------------------------------------------------
  # ● 判定是否在画面的可视区域內
  #     dx : 从画面中央开始计算，左右有多少个图块。
  #     dy : 从画面中央开始计算，上下有多少个图块。
  #--------------------------------------------------------------------------
  def near_the_screen?(dx = 12, dy = 8)
    ax = $game_map.adjust_x(@real_x / EAGLE.grid_n) - Graphics.width / 2 / 32
    ay = $game_map.adjust_y(@real_y / EAGLE.grid_n) - Graphics.height / 2 / 32
    ax >= -dx && ax <= dx && ay >= -dy && ay <= dy
  end
end
