#==============================================================================
# ■ 像素级移动 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
$imported ||= {}
$imported["EAGLE-PixelMove"] = true
#=============================================================================
# - 2020.1.5.16 增强兼容性；修改注释
#=============================================================================
# - 本插件对默认移动方式进行了修改，将默认网格进行了细分
#-----------------------------------------------------------------------------
# ○ 碰撞矩形
#-----------------------------------------------------------------------------
# - 在 RGSS 中，事件默认占据一个格子，其坐标为该格坐标，
#    但如果行走图并不是恰好一个格子大小（32×32像素），
#    比如过大的Boss敌人图像或过小的物品图像，
#    而实际的事件交互范围仍为位于行走图底部中央的一个格子大小的区域，
#    可能造成通行度上的错误。
#
# - 在本插件的移动模式下，光凭事件坐标已经无法满足交互需要，因此引入碰撞矩形概念。
#    为了更贴合实际的游戏表现，同时也方便自定义碰撞矩形，
#    我们设置行走图底部中心位置（若有两个中心，则取左边的）为碰撞矩形的坐标原点，
#    朝右为 x 轴正方向，朝下为 y 轴正方向。
#
#-----------------------------------------------------------------------------
# ○ 自定义事件页的碰撞矩形
#-----------------------------------------------------------------------------
# - 事件页的第一个指令为 注释 时，在其中填入下式来设置该事件页的碰撞矩形
#
#      <rect x数字y数字w数字h数字>
#
#   其中 数字 推荐为整数，可带负号（单位为像素）
#   其中 xywh 的顺序可调换，可省略（默认取常量设置中的事件初始碰撞矩形的参数）
#
# - 示例：
#     <rect x-5y-1> 修改当前事件页的碰撞矩形的左上角为 (-5, -1)
#        即从原点朝左侧移动5像素，朝上移动1像素后的点，为碰撞矩形的左上角
#     <rect w16h16> 修改当前事件页的碰撞矩形的宽度高度均为 16
#        即从矩形左上角开始，朝右侧和下侧各移动 15 像素后，到达碰撞矩形的右下角
#
# - 若第一个 注释 指令内无法写下，可在之后继续添加新的 注释 指令，将合并读取
#
#-----------------------------------------------------------------------------
# ○ 移动平台
#-----------------------------------------------------------------------------
# - 事件页的第一个指令为 注释 时，在其中填入下式将当前事件设置为移动平台
#
#      <platform>
#
# - 当玩家位于该事件上时（玩家的坐标处于该事件的碰撞矩形内部），
#    玩家将首先移动到该事件中心位置，再跟随事件移动
#-----------------------------------------------------------------------------
# ○ 高级
#-----------------------------------------------------------------------------
# - 以下为脚本中可用的新增方法一览
#   设 chara 为 Game_CharacterBase 类的实例
#
#  chara.get_collision_rect(raw=true) 获取碰撞矩形Rect
#      若传入 true ，返回以 chara 所在坐标为原点的碰撞矩形
#      若传入 false，返回划分后网格坐标中的碰撞矩形
#
#  chara.pos_rect?(rect) 是否与矩形相交（划分后网格坐标）
#
#  $game_map.events_rect(rect) 获取与 rect 相交的全部事件（rect 为划分后网格坐标中的矩形）
#  $game_map.events_rect_nt(rect) 获取与 rect 相交的全部事件（不含穿透）
#=============================================================================

module PIXEL_MOVE
#==============================================================================
# ■ 常量设置
#==============================================================================
  #--------------------------------------------------------------------------
  # ● 【设置】每个移动单位所含有的像素数
  #  正整数，小于等于 32（默认RGSS中一格的长度），且为 32 的约数
  #--------------------------------------------------------------------------
  PIXEL_PER_UNIT = 1
  #
  # 若 RGSS 中的一格被分成了 4×4（即 PIXEL_PER_UNIT = 32/4 = 8）
  #  +-------→ x
  #  | □□□□    左图为在屏幕坐标下的事件格子划分示意图，
  #  | □□□□    其中黑色方块为事件的实际坐标，
  #  | □□□□      若事件原本位于地图编辑器中的 (2,5)，
  #  ↓ □■□□      则在划分后，其坐标为 (2*4+1, 5*4+3) = (9,23)
  #  y
  #     黑色方块也为事件自身碰撞矩形的坐标原点
  #
  #--------------------------------------------------------------------------
  # ● 【设置】事件的初始碰撞矩形（单位：像素）
  #--------------------------------------------------------------------------
  EVENT_RECT = Rect.new(-9, -15, 20, 16)
  #
  # 第一项为矩形左上角像素的横坐标（以黑色方块为原点）
  # 第二项为矩形左上角像素的纵坐标
  # 第三项为矩形的宽度（在横轴上所占的像素数目）
  # 第四项为矩形的高度（在纵轴上所占的像素数目）
  #
  #  以 RGSS 中的一格被分成 4×4 为例：
  #   若想要事件的碰撞矩形依旧为原始一格大小，则设置为 (-1, -3, 4, 4)
  #
  #--------------------------------------------------------------------------
  # ● 【设置】玩家的初始碰撞矩形（单位：像素）
  #--------------------------------------------------------------------------
  PLAYER_RECT = Rect.new(-7, -15, 16, 16)
  #--------------------------------------------------------------------------
  # ● 【设置】玩家每次按键移动的移动单位数
  #--------------------------------------------------------------------------
  PLAYER_MOVE_UNIT = 4
  #--------------------------------------------------------------------------
  # ● 【设置】玩家使用4方向移动？（若为 false，则启用八方向移动）
  #--------------------------------------------------------------------------
  PLAYER_4DIR = false
  #--------------------------------------------------------------------------
  # ● 【设置】队友开始移动时，与玩家的最小坐标差（移动单位数）
  #  当 |跟随角色x - 玩家x| + |跟随角色y - 玩家y| 大于该值时，跟随角色才移动接近
  #--------------------------------------------------------------------------
  FOLLOWER_MIN_UNIT = 32
#==============================================================================
# ■ 单位转换
#==============================================================================
  #--------------------------------------------------------------------------
  # ● RGSS中一格含有的移动单位数
  #  rgss中的一格被拆成 UNIT_PER_MAP_GRID x UNIT_PER_MAP_GRID 格
  #--------------------------------------------------------------------------
  UNIT_PER_MAP_GRID = 32 / PIXEL_PER_UNIT
  #--------------------------------------------------------------------------
  # ● 移动单位数转换成像素数
  #--------------------------------------------------------------------------
  def self.unit2pixel(unit)
    unit * PIXEL_PER_UNIT
  end
  #--------------------------------------------------------------------------
  # ● 像素长度转换成移动单位数
  #--------------------------------------------------------------------------
  def self.pixel2unit(pixel)
    pixel / PIXEL_PER_UNIT
  end
  #--------------------------------------------------------------------------
  # ● 移动单位数转换为rgss地图格子数
  #  e ：补足的像素数
  #--------------------------------------------------------------------------
  def self.unit2rgss(v, e = 0)
    _s = v * PIXEL_PER_UNIT + e
    _r = _s / 32 # 格子数
    _e = _s - _r * 32 # 剩余不足一格长度的像素数
    return _r, _e
  end
  #--------------------------------------------------------------------------
  # ● rgss地图格子数转换为移动单位数
  #  e ：补足的像素数
  #--------------------------------------------------------------------------
  def self.rgss2unit(v, e = 0)
    _s = v * 32 + e
    _r = _s / PIXEL_PER_UNIT # 移动单位数
    _e = _s - _r * PIXEL_PER_UNIT # 不足一个移动单位的像素数
    return _r, _e
  end
#==============================================================================
# ■ 编辑器坐标转换
#==============================================================================
  #--------------------------------------------------------------------------
  # ● rgss编辑器中事件坐标转换为移动单位坐标
  #  取 事件所在格子的底部中心（左）位置 为新坐标
  #--------------------------------------------------------------------------
  def self.event_rgss2unit(x, y)
    x_p, e = rgss2unit(x, 15) # (32 - 1) / 2
    y_p, e = rgss2unit(y, 31) # 32 - 1
    return x_p, y_p
  end
#==============================================================================
# ■ 字符串解析
#==============================================================================
  #--------------------------------------------------------------------------
  # ● 解析碰撞矩形字符串
  #--------------------------------------------------------------------------
  def self.parse_collision_xywh_str(str)
    x = y = w = h = nil
    if str =~ /<rect ?(.*?)>/mi
      $1.scan(/[xywh]-?\d+/mi).each do |param|
        type = param[0]; v = param[1..-1].to_i
        case type
        when 'x'; x = v
        when 'y'; y = v
        when 'w'; w = v
        when 'h'; h = v
        end
      end
    end
    return x, y, w, h
  end
  #--------------------------------------------------------------------------
  # ● 解析浮动平台字符串
  #--------------------------------------------------------------------------
  def self.parse_floating_platform_str(str)
    if str =~ /<platform>/i
      return true
    end
    return false
  end
#==============================================================================
# ■ 碰撞判定
#==============================================================================
  #--------------------------------------------------------------------------
  # ● 点在矩形内部？
  #--------------------------------------------------------------------------
  def self.in_rect?(x, y, rect)
    x >= rect.x && y >= rect.y &&
    x <= rect.x + rect.width - 1 && y <= rect.y + rect.height - 1
  end
  #--------------------------------------------------------------------------
  # ● 获取矩形边上指定点的坐标
  #--------------------------------------------------------------------------
  def self.get_rect_xy(rect, pos)
    case pos
    when 1; return rect.x,                  rect.y+(rect.height-1)
    when 2; return rect.x+(rect.width-1)/2, rect.y+(rect.height-1)
    when 3; return rect.x+(rect.width-1),   rect.y+(rect.height-1)
    when 4; return rect.x,                  rect.y+(rect.height-1)/2
    when 5; return rect.x+(rect.width-1)/2, rect.y+(rect.height-1)/2
    when 6; return rect.x+(rect.width-1),   rect.y+(rect.height-1)/2
    when 7; return rect.x,                  rect.y
    when 8; return rect.x+(rect.width-1)/2, rect.y
    when 9; return rect.x+(rect.width-1),   rect.y
    end
  end
  #--------------------------------------------------------------------------
  # ● 矩形之间碰撞？
  #--------------------------------------------------------------------------
  def self.rect_collide_rect?(rect1, rect2)
    w1 = (rect1.width-1)/2; h1 = (rect1.height-1)/2
    w2 = (rect2.width-1)/2; h2 = (rect2.height-1)/2
    dx = (rect1.x+w1 - (rect2.x+w2)).abs
    dy = (rect1.y+h1 - (rect2.y+h2)).abs
    return dx <= w1 + w2 && dy <= h1 + h2
  end
end
#==============================================================================
# ■ 【读取部分】
#==============================================================================
module EAGLE
  #--------------------------------------------------------------------------
  # ● 读取事件页开头的注释组
  #--------------------------------------------------------------------------
  def self.event_comment_head(command_list)
    return "" if command_list.nil? || command_list.empty?
    t = ""; index = 0
    while command_list[index].code == 108 || command_list[index].code == 408
      t += command_list[index].parameters[0]
      index += 1
    end
    t
  end
end
#==============================================================================
# ■ Game_Map
#==============================================================================
class Game_Map
  #--------------------------------------------------------------------------
  # ● （覆盖）兼容RGSS坐标
  #  OUT: rgssXY
  #--------------------------------------------------------------------------
  def display_x
    x_, e = PIXEL_MOVE.unit2rgss(@display_x)
    x_
  end
  def display_y
    y_, e = PIXEL_MOVE.unit2rgss(@display_y)
    y_
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）设置显示位置
  #--------------------------------------------------------------------------
  def set_display_pos(x, y)
    w = width_unit; h = height_unit
    x = [0, [x, w - screen_unit_x].min].max unless loop_horizontal?
    y = [0, [y, h - screen_unit_y].min].max unless loop_vertical?
    @display_x = (x + w) % w
    @display_y = (y + h) % h
    @parallax_x = x
    @parallax_y = y
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）计算远景图显示的原点 X 坐标
  #--------------------------------------------------------------------------
  def parallax_ox(bitmap)
    if @parallax_loop_x
      @parallax_x * 16
    else
      w1 = [bitmap.width - Graphics.width, 0].max
      w2 = [PIXEL_MOVE.unit2pixel(width_unit) - Graphics.width, 1].max
      @parallax_x * 16 * w1 / w2
    end
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）计算远景图显示的原点 Y 坐标
  #--------------------------------------------------------------------------
  def parallax_oy(bitmap)
    if @parallax_loop_y
      @parallax_y * 16
    else
      h1 = [bitmap.height - Graphics.height, 0].max
      h2 = [PIXEL_MOVE.unit2pixel(height_unit) - Graphics.height, 1].max
      @parallax_y * 16 * h1 / h2
    end
  end
  #--------------------------------------------------------------------------
  # ○ 获取地图宽度（移动单位数）
  #--------------------------------------------------------------------------
  def width_unit
    @map.width * PIXEL_MOVE::UNIT_PER_MAP_GRID
  end
  #--------------------------------------------------------------------------
  # ○ 获取地图高度（移动单位数）
  #--------------------------------------------------------------------------
  def height_unit
    @map.height * PIXEL_MOVE::UNIT_PER_MAP_GRID
  end
  #--------------------------------------------------------------------------
  # ○ 画面的横向移动单位数
  #--------------------------------------------------------------------------
  def screen_unit_x
    PIXEL_MOVE.pixel2unit(Graphics.width)
  end
  #--------------------------------------------------------------------------
  # ○ 画面的纵向移动单位数
  #--------------------------------------------------------------------------
  def screen_unit_y
    PIXEL_MOVE.pixel2unit(Graphics.height)
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）计算显示坐标的剩余 X 坐标
  #  IN: unitXY
  #--------------------------------------------------------------------------
  def adjust_x(x)
    w = width_unit
    if loop_horizontal? && x < @display_x - (w - screen_unit_x) / 2
      x - @display_x + w
    else
      x - @display_x
    end
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）计算显示坐标的剩余 Y 坐标
  #  IN: unitXY
  #--------------------------------------------------------------------------
  def adjust_y(y)
    h = height_unit
    if loop_vertical? && y < @display_y - (h - screen_unit_y) / 2
      y - @display_y + h
    else
      y - @display_y
    end
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）计算循环修正后的 X 坐标
  #--------------------------------------------------------------------------
  def round_x(x)
    w = width_unit
    loop_horizontal? ? (x + w) % w : x
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）计算循环修正后的 Y 坐标
  #--------------------------------------------------------------------------
  def round_y(y)
    h = height_unit
    loop_vertical? ? (y + h) % h : y
  end
  #--------------------------------------------------------------------------
  # ○ 计算特定方向推移n个单位的 X 坐标（没有循环修正）
  #--------------------------------------------------------------------------
  def x_with_direction_n(x, d, n = 1)
    x + (d == 6 ? n : d == 4 ? -n : 0)
  end
  #--------------------------------------------------------------------------
  # ○ 计算特定方向推移n个单位的 Y 坐标（没有循环修正）
  #--------------------------------------------------------------------------
  def y_with_direction_n(y, d, n = 1)
    y + (d == 2 ? n : d == 8 ? -n : 0)
  end
  #--------------------------------------------------------------------------
  # ○ 计算特定方向推移n个单位的 X 坐标（有循环修正）
  #--------------------------------------------------------------------------
  def round_x_with_direction_n(x, d, n = 1)
    round_x(x + (d == 6 ? n : d == 4 ? -n : 0))
  end
  #--------------------------------------------------------------------------
  # ○ 计算特定方向推移n个单位的 Y 坐标（有循环修正）
  #--------------------------------------------------------------------------
  def round_y_with_direction_n(y, d, n = 1)
    round_y(y + (d == 2 ? n : d == 8 ? -n : 0))
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）获取指定坐标处存在的事件的数组
  #  IN: unitXY
  #--------------------------------------------------------------------------
  def events_xy(x, y)
    @events.values.select {|event| event.pos?(x, y) }
  end
  #--------------------------------------------------------------------------
  # ○ 获取指定矩形处存在的事件的数组
  #  IN: unitXY 下的矩形
  #--------------------------------------------------------------------------
  def events_rect(rect)
    @events.values.select {|event| event.pos_rect?(rect) }
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）获取指定坐标处存在的事件（穿透以外）的数组
  #  IN: unitXY
  #--------------------------------------------------------------------------
  def events_xy_nt(x, y)
    @events.values.select {|event| event.pos_nt?(x, y) }
  end
  #--------------------------------------------------------------------------
  # ○ 获取指定矩形处存在的事件的数组
  #  IN: unitXY 下的矩形
  #--------------------------------------------------------------------------
  def events_rect_nt(rect)
    @events.values.select {|event| event.pos_rect_nt?(rect) }
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）获取指定坐标处存在的图块事件（穿透以外）的数组
  #  IN: unitXY
  #--------------------------------------------------------------------------
  def tile_events_xy(x, y)
    @tile_events.select {|event| event.pos_nt?(x, y) }
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）获取指定坐标处存在的事件的 ID （仅一个）
  #  IN: rgssXY
  #--------------------------------------------------------------------------
  alias eagle_pixel_move_event_id_xy event_id_xy
  def event_id_xy(x, y)
    x_, y_ = PIXEL_MOVE.event_rgss2unit(x, y)
    return eagle_pixel_move_event_id_xy(x, y)
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）向下卷动
  #  IN: unitXY
  #--------------------------------------------------------------------------
  def scroll_down(distance)
    if loop_vertical?
      @display_y += distance
      @display_y %= height_unit
      @parallax_y += distance if @parallax_loop_y
    else
      last_y = @display_y
      @display_y = [@display_y + distance, height_unit - screen_unit_y].min
      @parallax_y += @display_y - last_y
    end
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）向左卷动
  #--------------------------------------------------------------------------
  def scroll_left(distance)
    if loop_horizontal?
      @display_x += width_unit - distance
      @display_x %= width_unit
      @parallax_x -= distance if @parallax_loop_x
    else
      last_x = @display_x
      @display_x = [@display_x - distance, 0].max
      @parallax_x += @display_x - last_x
    end
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）向右卷动
  #--------------------------------------------------------------------------
  def scroll_right(distance)
    if loop_horizontal?
      @display_x += distance
      @display_x %= width_unit
      @parallax_x += distance if @parallax_loop_x
    else
      last_x = @display_x
      @display_x = [@display_x + distance, (width_unit - screen_unit_x)].min
      @parallax_x += @display_x - last_x
    end
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）向上卷动
  #--------------------------------------------------------------------------
  def scroll_up(distance)
    if loop_vertical?
      @display_y += height_unit - distance
      @display_y %= height_unit
      @parallax_y -= distance if @parallax_loop_y
    else
      last_y = @display_y
      @display_y = [@display_y - distance, 0].max
      @parallax_y += @display_y - last_y
    end
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）有效坐标判定
  #  IN: rgssXY
  #--------------------------------------------------------------------------
  def valid?(x, y)
    x >= 0 && x < @map.width && y >= 0 && y < @map.height
  end
end
#==============================================================================
# ■ Game_CharacterBase
#==============================================================================
class Game_CharacterBase
  #--------------------------------------------------------------------------
  # ● 初始化公有成员变量
  #--------------------------------------------------------------------------
  alias eagle_pixel_move_init init_public_members
  def init_public_members
    eagle_pixel_move_init
    @collision_rect = Rect.new
    set_collision_rect(default_collisin_rect)
  end
  #--------------------------------------------------------------------------
  # ○ 默认碰撞矩形（单位：像素）
  #--------------------------------------------------------------------------
  def default_collisin_rect
    PIXEL_MOVE::EVENT_RECT
  end
  #--------------------------------------------------------------------------
  # ○ 设置碰撞矩形（角色底部中心为原点）（单位：像素）
  #  传入 nil 时，代表不修改
  #--------------------------------------------------------------------------
  def set_collision_xywh(_x = nil, _y = nil, _w = nil, _h = nil)
    @collision_rect.x = PIXEL_MOVE.pixel2unit(_x) if _x
    @collision_rect.y = PIXEL_MOVE.pixel2unit(_y) if _y
    @collision_rect.width = PIXEL_MOVE.pixel2unit(_w) if _w
    @collision_rect.height = PIXEL_MOVE.pixel2unit(_h) if _h
  end
  def set_collision_rect(_rect)
    @collision_rect.x = PIXEL_MOVE.pixel2unit(_rect.x)
    @collision_rect.y = PIXEL_MOVE.pixel2unit(_rect.y)
    @collision_rect.width = PIXEL_MOVE.pixel2unit(_rect.width)
    @collision_rect.height = PIXEL_MOVE.pixel2unit(_rect.height)
  end
  #--------------------------------------------------------------------------
  # ○ 获取碰撞矩形
  #  当 raw_rect 为 false 时，返回实际坐标下的碰撞矩形
  #--------------------------------------------------------------------------
  def get_collision_rect(raw_rect = true)
    return @collision_rect if raw_rect
    rect = @collision_rect.dup
    rect.x += @x
    rect.y += @y
    return rect
  end
  #--------------------------------------------------------------------------
  # ○ 获取碰撞矩形指定位置的实际坐标
  #--------------------------------------------------------------------------
  def get_collision_xy(dir)
    dx, dy = PIXEL_MOVE.get_rect_xy(@collision_rect, dir)
    x = $game_map.round_x(dx + @x)
    y = $game_map.round_y(dy + @y)
    return x, y
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）获取画面 X 坐标
  #--------------------------------------------------------------------------
  def screen_x
    PIXEL_MOVE.unit2pixel($game_map.adjust_x(@real_x))
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）获取画面 Y 坐标
  #--------------------------------------------------------------------------
  def screen_y
    PIXEL_MOVE.unit2pixel($game_map.adjust_y(@real_y)) - shift_y - jump_height
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）坐标一致判定
  #  IN: unitXY
  #--------------------------------------------------------------------------
  def pos?(x, y, rect = @collision_rect)
    return PIXEL_MOVE.in_rect?(x - @x, y - @y, rect)
  end
  #--------------------------------------------------------------------------
  # ○ 实际坐标一致判定
  #  IN: unitXY
  #--------------------------------------------------------------------------
  def real_pos?(x, y, rect = @collision_rect)
    return PIXEL_MOVE.in_rect?(x - @real_x, y - @real_y, rect)
  end
  #--------------------------------------------------------------------------
  # ○ 矩形碰撞判断
  #  IN: 实际坐标下的碰撞矩形（左上角点的xy与wh）
  #--------------------------------------------------------------------------
  def pos_rect?(rect)
    return PIXEL_MOVE.rect_collide_rect?(rect, get_collision_rect(false))
  end
  #--------------------------------------------------------------------------
  # ○ 判定 矩形是否碰撞 与“穿透是否关闭”（nt = No Through）
  #--------------------------------------------------------------------------
  def pos_rect_nt?(rect)
    pos_rect?(rect) && !@through
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）计算一帧内移动的距离
  #--------------------------------------------------------------------------
  def distance_per_frame
    2 ** real_move_speed / (8.0 * PIXEL_MOVE::PIXEL_PER_UNIT)
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）移动到指定位置
  #  在unitXY中，行走图坐标为底部中心点
  #  IN: rgssXY
  #--------------------------------------------------------------------------
  def moveto(x, y)
    x = x % $game_map.width
    y = y % $game_map.height
    x_, y_ = PIXEL_MOVE.event_rgss2unit(x, y)
    moveto_unit(x_, y_)
  end
  #--------------------------------------------------------------------------
  # ○ 移动到指定位置
  #  IN: unitXY
  #--------------------------------------------------------------------------
  def moveto_unit(x, y)
    @x = x
    @y = y
    @real_x = @x
    @real_y = @y
    @prelock_direction = 0
    straighten
    update_bush_depth
  end
  #--------------------------------------------------------------------------
  # ○ 直接指定理论坐标
  #  IN: unitXY
  #--------------------------------------------------------------------------
  def set_xy(x = nil, y = nil)
    @x = x.to_i if x
    @y = y.to_i if y
  end
  #--------------------------------------------------------------------------
  # ○ 强制移动
  #  IN: unitXY
  #--------------------------------------------------------------------------
  def move_force_pixel(dx, dy)
    @x += dx; @y += dy
    @real_x += dx; @real_y += dy
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）判定是否可以通行（检查 地图的通行度 和 前方是否有路障）
  #     d : 方向（2,4,6,8）
  #  IN: unitXY
  #--------------------------------------------------------------------------
  def passable?(x, y, d)
    pos = []
    case d
    when 2; pos.push(1); pos.push(3) # 左下和右下
    when 4; pos.push(1); pos.push(7) # 左上和左下
    when 6; pos.push(3); pos.push(9) # 右上和右下
    when 8; pos.push(7); pos.push(9) # 左上和右上
    end
    pos.each do |p_|
      dx, dy = PIXEL_MOVE.get_rect_xy(@collision_rect, p_)
      # 移动前坐标 unitXY
      x1_p = $game_map.round_x(x + dx)
      y1_p = $game_map.round_y(y + dy)
      # 移动后坐标 unitXY
      x2_p = $game_map.round_x_with_direction(x1_p, d)
      y2_p = $game_map.round_y_with_direction(y1_p, d)
      # 移动前坐标 rgssXY
      x1, e = PIXEL_MOVE.unit2rgss(x1_p)
      y1, e = PIXEL_MOVE.unit2rgss(y1_p)
      # 移动后坐标 rgssXY
      x2, e = PIXEL_MOVE.unit2rgss(x2_p)
      y2, e = PIXEL_MOVE.unit2rgss(y2_p)
      return false unless $game_map.valid?(x2, y2)
      return true if @through || debug_through?
      if x1 != x2 || y1 != y2
        return false unless map_passable?(x1, y1, d)
        return false unless map_passable?(x2, y2, reverse_dir(d))
      end
      return false if collide_with_characters?(x2_p, y2_p)
    end
    return true
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）判定面前的事件是否被启动
  #  取碰撞盒四边中点
  #--------------------------------------------------------------------------
  def check_event_trigger_touch_front
    x, y = PIXEL_MOVE.get_rect_xy(@collision_rect, @direction)
    x2 = $game_map.round_x_with_direction(x + @x, @direction)
    y2 = $game_map.round_y_with_direction(y + @y, @direction)
    check_event_trigger_touch(x2, y2)
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）径向移动
  #     d       : 方向（2,4,6,8）
  #     turn_ok : 是否可以改变方向
  #--------------------------------------------------------------------------
  def move_straight(d, turn_ok = true, n = PIXEL_MOVE::UNIT_PER_MAP_GRID)
    x_ = @x; y_ = @y
    # 尝试移动，获取能够成功移动的次数
    n.times do |i|
      break n = i if !passable?(x_, y_, d)
      x_ = $game_map.round_x_with_direction(x_, d)
      y_ = $game_map.round_y_with_direction(y_, d)
    end
    if n > 0
      @move_succeed = true
      set_direction(d)
      @x = x_; @y = y_
      @real_x = $game_map.x_with_direction_n(@x, reverse_dir(d), n)
      @real_y = $game_map.y_with_direction_n(@y, reverse_dir(d), n)
      increase_steps
    elsif turn_ok
      @move_succeed = false
      set_direction(d)
      check_event_trigger_touch_front
    end
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）斜向移动
  #     horz : 横向（4 or 6）
  #     vert : 纵向（2 or 8）
  #--------------------------------------------------------------------------
  def move_diagonal(horz, vert, n = PIXEL_MOVE::UNIT_PER_MAP_GRID)
    x_ = @x; y_ = @y
    n.times do |i|
      break n = i if !diagonal_passable?(x, y, horz, vert)
      x_ = $game_map.round_x_with_direction(x_, horz)
      y_ = $game_map.round_y_with_direction(y_, vert)
    end
    if n > 0
      @move_succeed = true
      @x = x_; @y = y_
      @real_x = $game_map.x_with_direction_n(@x, reverse_dir(horz), n)
      @real_y = $game_map.y_with_direction_n(@y, reverse_dir(vert), n)
      increase_steps
    else
      @move_succeed = false
    end
    set_direction(horz) if @direction == reverse_dir(horz)
    set_direction(vert) if @direction == reverse_dir(vert)
  end
end
#==============================================================================
# ■ Game_Character
#==============================================================================
class Game_Character < Game_CharacterBase
  #--------------------------------------------------------------------------
  # ● （覆盖）计算 X 方向的距离
  #  IN: unitXY
  #--------------------------------------------------------------------------
  def distance_x_from(x)
    result = @x - x
    if $game_map.loop_horizontal? && result.abs > $game_map.width_unit / 2
      if result < 0
        result += $game_map.width_unit
      else
        result -= $game_map.width_unit
      end
    end
    result
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）计算 y 方向的距离
  #  IN: unitXY
  #--------------------------------------------------------------------------
  def distance_y_from(y)
    result = @y - y
    if $game_map.loop_vertical? && result.abs > $game_map.height_unit / 2
      if result < 0
        result += $game_map.height_unit
      else
        result -= $game_map.height_unit
      end
    end
    result
  end
end
#==============================================================================
# ■ Game_Player
#==============================================================================
class Game_Player < Game_Character
  #--------------------------------------------------------------------------
  # ○ 默认碰撞矩形（单位：像素）
  #--------------------------------------------------------------------------
  def default_collisin_rect
    PIXEL_MOVE::PLAYER_RECT
  end
  #--------------------------------------------------------------------------
  # ● 画面中央的 X 坐标
  #  OUT: unitXY
  #--------------------------------------------------------------------------
  def center_x
    PIXEL_MOVE.pixel2unit(Graphics.width / 2.0)
  end
  #--------------------------------------------------------------------------
  # ● 画面中央的 Y 坐标
  #  OUT: unitXY
  #--------------------------------------------------------------------------
  def center_y
    PIXEL_MOVE.pixel2unit(Graphics.height / 2.0)
  end
  #--------------------------------------------------------------------------
  # ● 设置显示位置为地图中央
  #  IN: rgssXY
  #--------------------------------------------------------------------------
  def center(x, y)
    x_, e = PIXEL_MOVE.rgss2unit(x)
    y_, e = PIXEL_MOVE.rgss2unit(y)
    $game_map.set_display_pos(x_ - center_x, y_ - center_y) # unitXY
  end
  #--------------------------------------------------------------------------
  # ○ 强制移动
  #  IN: unitXY
  #--------------------------------------------------------------------------
  def move_force_pixel(dx = 0, dy = 0)
    last_real_x = @real_x; last_real_y = @real_y
    super
    update_scroll(last_real_x, last_real_y)
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）由方向键移动
  #--------------------------------------------------------------------------
  def move_by_input
    return if !movable? || $game_map.interpreter.running?
    if PIXEL_MOVE::PLAYER_4DIR && Input.dir4 > 0
      return move_straight(Input.dir4, true, PIXEL_MOVE::PLAYER_MOVE_UNIT)
    end
    case Input.dir8
    when 1; move_straight_8dir(4, 2)
    when 3; move_straight_8dir(6, 2)
    when 7; move_straight_8dir(4, 8)
    when 9; move_straight_8dir(6, 8)
    else; move_straight(Input.dir4, true, PIXEL_MOVE::PLAYER_MOVE_UNIT)
    end
  end
  #--------------------------------------------------------------------------
  # ○ 八方向移动
  #--------------------------------------------------------------------------
  def move_straight_8dir(horz, vert)
    move_diagonal(horz, vert, PIXEL_MOVE::PLAYER_MOVE_UNIT)
    return if @move_succeed
    move_straight(horz, true, PIXEL_MOVE::PLAYER_MOVE_UNIT)
    return if @move_succeed
    move_straight(vert, true, PIXEL_MOVE::PLAYER_MOVE_UNIT)
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）径向移动
  #--------------------------------------------------------------------------
  def move_straight(d, turn_ok = true, n = PIXEL_MOVE::UNIT_PER_MAP_GRID)
    @followers.move if passable?(@x, @y, d)
    super
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）斜向移动
  #     horz : 横向（4 or 6）
  #     vert : 纵向（2 or 8）
  #--------------------------------------------------------------------------
  def move_diagonal(horz, vert, n = PIXEL_MOVE::UNIT_PER_MAP_GRID)
    @followers.move if diagonal_passable?(@x, @y, horz, vert)
    super
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）判定前方事件是否被启动
  #   取角色碰撞盒的四边中点作为判定点
  #--------------------------------------------------------------------------
  def check_event_trigger_there(triggers)
    x_p, y_p = get_collision_xy(@direction)
    x2 = $game_map.round_x_with_direction(x_p, @direction)
    y2 = $game_map.round_y_with_direction(y_p, @direction)
    start_map_event(x2, y2, triggers, true)
    return if $game_map.any_event_starting?
    x2_rgss, e = PIXEL_MOVE.unit2rgss(x2)
    y2_rgss, e = PIXEL_MOVE.unit2rgss(y2)
    return unless $game_map.counter?(x2_rgss, y2_rgss)
    # 柜台属性：向前方推进 RGSS 中的一格来查找事件
    x3 = $game_map.round_x_with_direction_n(x2, @direction,
      PIXEL_MOVE.pixel2unit(32))
    y3 = $game_map.round_y_with_direction_n(y2, @direction,
      PIXEL_MOVE.pixel2unit(32))
    start_map_event(x3, y3, triggers, true)
  end
end
#==============================================================================
# ■ Game_Follower
#==============================================================================
class Game_Follower < Game_Character
  #--------------------------------------------------------------------------
  # ● （覆盖）追随带队角色
  #--------------------------------------------------------------------------
  def chase_preceding_character
    unless moving?
      sx = distance_x_from(@preceding_character.x).to_i
      sy = distance_y_from(@preceding_character.y).to_i
      dx = sx.abs; dy = sy.abs
      return if dx + dy < PIXEL_MOVE::FOLLOWER_MIN_UNIT
      if sx != 0 && sy != 0
        n = [dx, dy, PIXEL_MOVE::PLAYER_MOVE_UNIT].min
        move_diagonal(sx > 0 ? 4 : 6, sy > 0 ? 8 : 2, n)
      elsif sx != 0
        n = [dx, PIXEL_MOVE::PLAYER_MOVE_UNIT].min
        move_straight(sx > 0 ? 4 : 6, true, n)
      elsif sy != 0
        n = [dy, PIXEL_MOVE::PLAYER_MOVE_UNIT].min
        move_straight(sy > 0 ? 8 : 2, true, n)
      end
    end
  end
end
#==============================================================================
# ■ Game_Vehicle
#==============================================================================
class Game_Vehicle < Game_Character
  #--------------------------------------------------------------------------
  # ● （覆盖）判定是否可以靠岸／着陆
  #     d : 方向（2,4,6,8）
  #  IN: unitXY
  #--------------------------------------------------------------------------
  def land_ok?(x, y, d)
    if @type == :airship
      return false unless $game_map.events_rect(get_collision_rect(false)).empty?
    else
      x2_p = $game_map.round_x_with_direction(x, d)
      y2_p = $game_map.round_y_with_direction(y, d)
      # 移动后坐标 rgssXY
      x2, e = PIXEL_MOVE.unit2rgss(x2_p)
      y2, e = PIXEL_MOVE.unit2rgss(y2_p)
      return false unless $game_map.valid?(x2, y2)
      return false unless $game_map.passable?(x2, y2, reverse_dir(d))
      return false if collide_with_characters?(x2_p, y2_p)
    end
    return true
  end
end
#==============================================================================
# ■ Game_Event
#==============================================================================
class Game_Event < Game_Character
  #--------------------------------------------------------------------------
  # ● 设置事件页的设置
  #--------------------------------------------------------------------------
  alias eagle_pixel_move_setup_page_settings setup_page_settings
  def setup_page_settings
    eagle_pixel_move_setup_page_settings
    t = EAGLE.event_comment_head(@list)
    # 检查碰撞矩形
    x, y, w, h = PIXEL_MOVE.parse_collision_xywh_str(t)
    set_collision_xywh(x, y, w, h)
    # 检查浮动平台
    @flag_platform = PIXEL_MOVE.parse_floating_platform_str(t)
    @flag_player_on_platform = false
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）判定事件是否临近玩家
  #--------------------------------------------------------------------------
  def near_the_player?
    sx = distance_x_from($game_player.x).abs
    sy = distance_y_from($game_player.y).abs
    sx + sy < 20 * PIXEL_MOVE::UNIT_PER_MAP_GRID
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）判定是否在画面的可视区域內
  #     dx : 从画面中央开始计算，左右有多少像素
  #     dy : 从画面中央开始计算，上下有多少像素
  #  IN: rgssXY
  #--------------------------------------------------------------------------
  def near_the_screen?(dx = Graphics.width / 2, dy = Graphics.height / 2)
    ax, ay = PIXEL_MOVE.get_rect_xy(@collision_rect, 5)
    ax = PIXEL_MOVE.unit2pixel($game_map.adjust_x(@real_x + ax)) - dx
    ay = PIXEL_MOVE.unit2pixel($game_map.adjust_y(@real_y + ay)) - dy
    ax >= -dx && ax <= dx && ay >= -dy && ay <= dy
  end
  #--------------------------------------------------------------------------
  # ● 更新画面
  #--------------------------------------------------------------------------
  alias eagle_pixel_move_update update
  def update
    last_real_x = @real_x; last_real_y = @real_y
    eagle_pixel_move_update
    update_floating_platform(last_real_x, last_real_y) if @flag_platform
  end
  #--------------------------------------------------------------------------
  # ○ 更新浮动平台（主角专用）
  #--------------------------------------------------------------------------
  def update_floating_platform(last_real_x, last_real_y)
    f = real_pos?($game_player.real_x, $game_player.real_y)
    if f
      if !@flag_player_on_platform # 强制居中于浮动平台 防止卡位bug
        dx, dy = PIXEL_MOVE.get_rect_xy(@collision_rect, 5)
        $game_player.set_xy(last_real_x+dx, last_real_y+dy)
      end
      @flag_player_on_platform = true
      $game_player.move_force_pixel(@real_x-last_real_x, @real_y - last_real_y)
    else
      @flag_player_on_platform = false
    end
  end
end
