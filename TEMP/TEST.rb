module EAGLE
  #--------------------------------------------------------------------------
  # ● 【常量】每个移动单位所含有的像素数
  #--------------------------------------------------------------------------
  PIXEL_PER_UNIT = 1
  #--------------------------------------------------------------------------
  # ● 地图格子细分出的移动单位数（需要保证为整数）
  #  rgss中的一格被拆成 UNIT_PER_MAP_GRID x UNIT_PER_MAP_GRID 格
  #--------------------------------------------------------------------------
  UNIT_PER_MAP_GRID = 32 / PIXEL_PER_UNIT
  #--------------------------------------------------------------------------
  # ● 像素长度转换成移动单位数
  #--------------------------------------------------------------------------
  def self.pixel2unit(pixel)
    pixel / PIXEL_PER_UNIT
  end
  #--------------------------------------------------------------------------
  # ● 移动单位数转换为rgss地图格子数
  #--------------------------------------------------------------------------
  def self.unit2rgss(v, e = 0)
    _s = v * PIXEL_PER_UNIT + e
    _r = _s / 32 # 格子数目
    _e = _s - _r * 32 # 剩余不足一格长度的像素数
    return _r, _e
  end
  #--------------------------------------------------------------------------
  # ● rgss地图格子数转换为移动单位数
  #--------------------------------------------------------------------------
  def self.rgss2unit(v, e = 0)
    _s = v * 32 + e
    _r = _s / PIXEL_PER_UNIT # 移动单位数
    _e = _s - _r * PIXEL_PER_UNIT # 不足一个移动单位的像素数
    return _r, _e
  end
  #--------------------------------------------------------------------------
  # ● 点在矩形内部？
  #--------------------------------------------------------------------------
  def self.in_rect?(x, y, rect)
    x >= rect.x && y >= rect.y &&
    x <= rect.x + rect.width && y <= rect.y + rect.height
  end
  def self.rect_collision?(rect1, rect2)
    dx = (rect1.x + rect1.width/2 - rect2.x - rect2.width/2).abs
    dy = (rect1.y + rect1.height/2 - rect2.y - rect2.height/2).abs
    return dx <= rect1.width/2+rect2.width/2 && dy <= rect1.height/2+rect2.height/2
  end
  #--------------------------------------------------------------------------
  # ● 获取矩形边上指定点的坐标
  #--------------------------------------------------------------------------
  def self.get_rect_xy(rect, pos)
    case pos
    when 1; return rect.x,              rect.y+rect.height
    when 2; return rect.x+rect.width/2, rect.y+rect.height
    when 3; return rect.x+rect.width,   rect.y+rect.height
    when 4; return rect.x,              rect.y+rect.height/2
    when 5; return rect.x+rect.width/2, rect.y+rect.height/2
    when 6; return rect.x+rect.width,   rect.y+rect.height/2
    when 7; return rect.x,              rect.y
    when 8; return rect.x+rect.width/2, rect.y
    when 9; return rect.x+rect.width,   rect.y
    end
  end
end

class Game_Map
  # 计算循环修正后的 X 坐标
  # IN/OUT: pixelX
  alias eagle_pixel_move_round_x round_x
  def round_x(x)
    _rgss, _e = EAGLE.unit2rgss(x)
    _rgss = eagle_pixel_move_round_x(_rgss)
    _unit, _e = EAGLE.rgss2unit(_rgss, _e)
    return _unit
  end
  # 计算循环修正后的 Y 坐标
  alias eagle_pixel_move_round_y round_y
  def round_y(y)
    _rgss, _e = EAGLE.unit2rgss(y)
    _rgss = eagle_pixel_move_round_y(_rgss)
    _unit, _e = EAGLE.rgss2unit(_rgss, _e)
    return _unit
  end
  # 计算特定方向推移一个单位的 X 坐标（有循环修正）
  # IN/OUT: pixelX
  def round_x_with_direction(x, d)
    _x = x_with_direction(x, d)
    return round_x(_x)
  end
  # 计算特定方向推移一个单位的 Y 坐标（有循环修正）
  def round_y_with_direction(y, d)
    _y = y_with_direction(y, d)
    return round_y(_y)
  end
end

class Game_CharacterBase
  #--------------------------------------------------------------------------
  # ● 初始化公有成员变量
  #--------------------------------------------------------------------------
  alias eagle_pixel_move_init init_public_members
  def init_public_members
    eagle_pixel_move_init
    # 以格子底部中心为原点的碰撞矩形
    @collision_rect = Rect.new(
      EAGLE.pixel2unit(-12), EAGLE.pixel2unit(-16),
      EAGLE.pixel2unit(24), EAGLE.pixel2unit(16) )
  end
  #--------------------------------------------------------------------------
  # ● 获取画面 X 坐标
  #--------------------------------------------------------------------------
  def screen_x
    _x, _e = EAGLE.unit2rgss(@real_x)
    return $game_map.adjust_x(_x) * 32 + _e
  end
  #--------------------------------------------------------------------------
  # ● 获取画面 Y 坐标
  #--------------------------------------------------------------------------
  def screen_y
    _y, _e = EAGLE.unit2rgss(@real_y)
    return $game_map.adjust_y(_y) * 32 + _ye - shift_y - jump_height
  end
  #--------------------------------------------------------------------------
  # ● 坐标一致判定
  # IN: pixelXY
  #--------------------------------------------------------------------------
  def pos?(x, y)
    return EAGLE.in_rect?(x - @x, y - @y, @collision_rect)
  end
  #--------------------------------------------------------------------------
  # ● 计算一帧内移动的距离
  #--------------------------------------------------------------------------
  def distance_per_frame
    2 ** real_move_speed / (8.0 * EAGLE::PIXEL_PER_UNIT)
  end
  #--------------------------------------------------------------------------
  # ● 移动到指定位置
  #  IN: rgssXY
  #--------------------------------------------------------------------------
  def moveto(x, y)
    # 在pixelXY中，行走图坐标为底部中心点
    @x = EAGLE.rgss2unit(x % $game_map.width, 16)
    @y = EAGLE.rgss2unit(y % $game_map.height, 32)
    @real_x = @x
    @real_y = @y
    @prelock_direction = 0
    straighten
    update_bush_depth
  end
  #--------------------------------------------------------------------------
  # ● 判定是否可以通行（检查 地图的通行度 和 前方是否有路障）
  #     d : 方向（2,4,6,8）
  #  IN: pixelXY
  #--------------------------------------------------------------------------
  def passable?(x, y, d)
    pos = [] # 需要进行判定的位置
    case d
    when 2; pos.push(1); pos.push(3) # 左下和右下
    when 4; pos.push(1); pos.push(7)
    when 6; pos.push(3); pos.push(9)
    when 8; pos.push(7); pos.push(9)
    end
    pos.each do |p_|
      # 移动前坐标 pixelXY
      x0, y0 = EAGLE.get_rect_xy(@collision_rect, p_)
      x0 += x; y0 += y
      # 移动后坐标 pixelXY
      x2_p = $game_map.round_x_with_direction(x0, d)
      y2_p = $game_map.round_y_with_direction(y0, d)
      # 移动前坐标 rgssXY
      x1, e = EAGLE.unit2rgss(x0)
      y1, e = EAGLE.unit2rgss(y0)
      # 移动后坐标 rgssXY
      x2, e = EAGLE.unit2rgss(x2_p)
      y2, e = EAGLE.unit2rgss(y2_p)
      if x1 != x2 || y1 != y2
        return false unless $game_map.valid?(x2, y2)
        return true if @through || debug_through?
        return false unless map_passable?(x1, y1, d)
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
  alias eagle_pixel_move_straight move_straight
  def move_straight(d, turn_ok = true)
    3.times do
      eagle_pixel_move_straight(d, turn_ok)
    end
  end
end

class Game_Player < Game_Character
  #--------------------------------------------------------------------------
  # ● 判定前方事件是否被启动
  #--------------------------------------------------------------------------
  def check_event_trigger_there(triggers)
    # 取角色碰撞盒的四边中点作为判定点
    x, y = EAGLE.get_rect_xy(@collision_rect, @direction)
    x2 = $game_map.round_x_with_direction(x, @direction)
    y2 = $game_map.round_y_with_direction(y, @direction)
    start_map_event(x2, y2, triggers, true)
    return if $game_map.any_event_starting?
    return unless $game_map.counter?(x2, y2)
    x3 = $game_map.round_x_with_direction(x2 + EAGLE.pixel2unit(32), @direction)
    y3 = $game_map.round_y_with_direction(y2 + EAGLE.pixel2unit(32), @direction)
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
    ax = $game_map.adjust_x(@real_x / EAGLE::UNIT_PER_MAP_GRID) - Graphics.width / 2 / 32
    ay = $game_map.adjust_y(@real_y / EAGLE::UNIT_PER_MAP_GRID) - Graphics.height / 2 / 32
    ax >= -dx && ax <= dx && ay >= -dy && ay <= dy
  end
end
