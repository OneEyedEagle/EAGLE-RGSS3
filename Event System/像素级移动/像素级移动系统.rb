#==============================================================================
# ■ 像素级移动系统 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
#==============================================================================
# 【版本】1.5.0
# 【更新】2026.2.11 利用DeepSeek优化代码结构与注释
#-----------------------------------------------------------------------------
# 【前置】需置于【组件-通用方法汇总 by老鹰】插件之下
# 【兼容】本插件已兼容 Map Effects v1.4.1 for VX and VXace by Zeus81，请置于其下
#==============================================================================

$imported ||= {}
$imported["EAGLE-PixelMove"] = "1.5.0"

#=============================================================================
# ○ 核心功能概述
#=============================================================================
# - 本插件对 RPG Maker VX Ace 的默认移动系统进行了根本性改进：
#   1. 将原本的32×32像素网格进一步细分，实现更精细的像素级移动
#   2. 引入碰撞矩形概念，允许精确控制角色和事件的碰撞区域
#   3. 支持移动单位系统，平衡移动精度与性能
#
# - 主要特性：
#   * 精确的像素级碰撞检测
#   * 可自定义的角色/事件碰撞框
#   * 移动平台和强制移动区域
#   * 区域通行控制系统
#   * 八方向移动支持
#   * 与载具系统完全兼容
#-----------------------------------------------------------------------------

#=============================================================================
# ○ 核心概念说明
#=============================================================================
#-----------------------------------------------------------------------------
# → 碰撞矩形 (Collision Rect)
#-----------------------------------------------------------------------------
#  在默认RGSS中，事件占用整个32×32像素的格子，碰撞检测基于格子坐标。
#  本插件引入碰撞矩形概念，使碰撞检测更加精确：
#
# - 碰撞矩形的原点：行走图底部中心点（宽度为奇数时取正中，偶数时取左侧像素）
# - 坐标系：向右为+X轴，向下为+Y轴
# - 单位：像素（内部会自动转换为移动单位）
#
#  示例：一个20×30像素的行走图（无底部空白）可设置碰撞矩形为：
#    x=-11, y=-30, w=20, h=30
#  表示以事件底部中心为原点，碰撞框左上角在(-11,-30)处，宽20像素，高30像素

#-----------------------------------------------------------------------------
# → 移动单位 (Move Unit)
#-----------------------------------------------------------------------------
#  为了平衡移动精度和性能，引入移动单位概念：
#
# - 移动单位：将32×32像素格子细分后的最小移动单位
# - 大小配置：通过 PIXEL_PER_UNIT 常量设置（必须为32的约数）
#
#  示例：
#   PIXEL_PER_UNIT = 8  # 每移动单位=8像素，每RGSS格分为4×4个单位
#   PIXEL_PER_UNIT = 4  # 每移动单位=4像素，每RGSS格分为8×8个单位

#=============================================================================
# ○ 事件页配置说明
#=============================================================================

#-----------------------------------------------------------------------------
# → 碰撞矩形配置
#-----------------------------------------------------------------------------
#  在事件页的第一个注释指令中可配置碰撞矩形：
#
#  格式：
#    <rect x数字 y数字 w数字 h数字>
#
#  参数说明：
#    x, y - 碰撞矩形左上角相对于事件原点的偏移（像素，可负）
#    w, h - 碰撞矩形的宽度和高度（像素）
#
#  特殊值：
#    <rect grid> - 使用默认格子大小（32×32像素）
#
#  示例：
#    <rect x=5 y=1>           # 修改左上角位置
#    <rect w=16 h=16>         # 修改宽度高度
#    <rect x=12 y=24 w=32 h=32> # 恢复为完整格子大小
#
#  注意：
#   1. 参数顺序可调整，可省略（使用默认值）
#   2. 数字都需要为 PIXEL_PER_UNIT 的倍数
#   3. 可在多个注释指令中配置，后写的覆盖先写的
#   4. 配置后，以图块为图像的事件将不再被确定键触发

#-----------------------------------------------------------------------------
# → 事件交互绑定
#-----------------------------------------------------------------------------
#  在事件页的第一个注释指令中可绑定其他事件：
#
#  格式：
#    <bind 目标ID>...</bind>
#
#  目标ID：
#    0 或省略 - 绑定玩家
#    正整数   - 绑定指定ID的事件
#
#  可用标签：
#    <platform> - 设置为移动平台（绑定对象站上后会随事件移动）
#    <move d>   - 设置为强制移动区域（d=2/4/6/8，绑定对象进入后会向该方向持续移动）
#
#  示例：
#    <bind 0><platform></bind>     # 玩家站上该事件后会随事件移动
#    <bind 3><move 6></bind>       # 事件3进入该区域后会向右持续移动
#
#  注意：当绑定对象位于事件上时，会先移动到事件中心再跟随移动，避免位置偏移

#=============================================================================
# ○ 脚本接口说明
#=============================================================================

#-----------------------------------------------------------------------------
# → 区域通行控制
#-----------------------------------------------------------------------------
#  脚本调用：
#    $game_map.set_region(区域ID, 通行状态)
#
#  参数：
#    区域ID     - 地图编辑器中的区域ID（1-63）
#    通行状态   - true（可通行，默认）/ false（不可通行）
#
#  示例：
#    $game_map.set_region(5, false)  # 禁止区域5通行
#    $game_map.set_region(3, true)   # 允许区域3通行
#
#  注意：区域通行设置全局生效，且在图块可通行的基础上进行判定

#-----------------------------------------------------------------------------
# → 高级编程接口
#-----------------------------------------------------------------------------
# 关键方法列表（chara为Game_CharacterBase实例）：
#
# 坐标相关：
#   chara.x, chara.y                 # 移动单位网格坐标
#   chara.rgss_x, chara.rgss_y       # 编辑器网格坐标（RGSS坐标）
#
# 碰撞检测：
#   chara.get_collision_rect(raw)    # 获取碰撞矩形
#                                     # raw=true：返回相对坐标的矩形
#                                     # raw=false：返回地图坐标的矩形
#   chara.pos_rect?(rect)            # 判断是否与矩形相交
#
# 移动控制：
#   chara.move_unit(d, n[, turn_ok]) # 向d方向移动n个单位
#   chara.move_forward_unit(n)       # 向前方移动n个单位
#
# 地图查询：
#   $game_map.events_rect(rect)      # 获取与矩形相交的所有事件
#   $game_map.events_rect_nt(rect)   # 获取与矩形相交的所有事件（不含穿透）

#=============================================================================

#==============================================================================
# ■ 核心模块：常量定义、单位换算、几何运算、注释解析
#==============================================================================
module PIXEL_MOVE
  #--------------------------------------------------------------------------
  # ● 系统常量（可在此调整性能与精度平衡）
  #--------------------------------------------------------------------------

  # 【移动单位】每单位包含的像素数。必须为 32 的正约数。
  # 可选值：1,2,4,8,16,32。值越小移动越精细，性能开销越大。
  PIXEL_PER_UNIT = 8

  # 【角色碰撞矩形】（单位：像素）以角色底部中心为原点，x,y为左上角偏移。
  #  PIXEL_PER_UNIT = 4 时
  #EVENT_RECT    = Rect.new(-4, -16, 16, 16)   # 默认事件
  #PLAYER_RECT   = Rect.new(-4, -16, 16, 16)   # 玩家
  BOAT_RECT     = Rect.new(-8, -16, 16, 16)   # 小船
  SHIP_RECT     = Rect.new(-16, -32, 32, 32)  # 大船
  AIRSHIP_RECT  = Rect.new(-8, -16, 16, 16)   # 飞艇
  
  #  PIXEL_PER_UNIT = 8 时
  EVENT_RECT    = Rect.new(-8, -24, 24, 16)   # 默认事件
  PLAYER_RECT   = Rect.new(-8, -24, 16, 16)   # 玩家

  # 【移动行为】
  PLAYER_MOVE_UNIT   = 1      # 玩家每按一次方向键移动的单位数
  PLAYER_4DIR        = false  # 玩家是否强制四方向移动（false = 八方向）
  FOLLOWER_MIN_UNIT  = 32     # 队友开始跟随的曼哈顿距离阈值（单位）

  # 【测试用】
  DRAW_EVENT_RECT    = true   # 绘制事件的碰撞矩形（仅 游戏测试 时生效）
  
  #--------------------------------------------------------------------------
  # ● 单位换算（内部使用，请勿修改）
  #--------------------------------------------------------------------------
  # 每个 RGSS 格子包含的移动单位数（自动计算）
  UNIT_PER_MAP_GRID = 32 / PIXEL_PER_UNIT

  # @!group 单位换算
  def self.unit2pixel(unit)   ; unit * PIXEL_PER_UNIT       ; end
  def self.pixel2unit(pixel)  ; pixel / PIXEL_PER_UNIT      ; end

  # 移动单位 → RGSS 格子坐标及余数像素
  def self.unit2rgss(v, e = 0)
    pixel = v * PIXEL_PER_UNIT + e
    [pixel / 32, pixel % 32]
  end

  # RGSS 格子坐标及余数像素 → 移动单位
  def self.rgss2unit(v, e = 0)
    pixel = v * 32 + e
    [pixel / PIXEL_PER_UNIT, pixel % PIXEL_PER_UNIT]
  end

  #--------------------------------------------------------------------------
  # ● 坐标系统转换（事件坐标系与移动单位坐标系）
  #--------------------------------------------------------------------------
  # 事件默认原点：格子底部中心（水平居中偏左，垂直底部）
  RGSS_CENTER_X = (32 - 1) / 2  # 15 像素
  RGSS_BOTTOM_Y = 32 - 1        # 31 像素

  def self.event_rgss2unit(x, y)
    x_p, _ = rgss2unit(x, RGSS_CENTER_X)   # 水平取中心偏左
    y_p, _ = rgss2unit(y, RGSS_BOTTOM_Y)   # 垂直取底部
    [x_p, y_p]
  end

  def self.event_unit2rgss(x, y)
    dx_pixel = -RGSS_CENTER_X
    x_, _ = unit2rgss(x, dx_pixel)
    dy_pixel = -RGSS_BOTTOM_Y
    y_, _ = unit2rgss(y, dy_pixel)
    [x_, y_]
  end
  
  def self.grid_rgss2unit(x, y)  # 地图网格转换为移动单位坐标
    x_p, _ = rgss2unit(x, 16)   # 水平取中心
    y_p, _ = rgss2unit(y, 16)   # 垂直取中心
    [x_p, y_p]
  end

  # RGSS 格子矩形 → 移动单位矩形（左上角原点）
  def self.rgssGrid2unitRect(x, y)
    x_p, _ = rgss2unit(x)
    y_p, _ = rgss2unit(y)
    w_p = pixel2unit(32)
    Rect.new(x_p, y_p, w_p, w_p)
  end

  #--------------------------------------------------------------------------
  # ● 矩形几何运算（单位：移动单位）
  #--------------------------------------------------------------------------
  # @!group 矩形操作

  # 移动矩形（原地复制后平移）
  def self.move_rect(rect, d, step = 1)
    r = rect.dup
    case d
    when 2; r.y  += step
    when 4; r.x  -= step
    when 6; r.x  += step
    when 8; r.y  -= step
    end
    r
  end

  # 拉伸矩形（向指定方向扩大）
  def self.lengthen_rect(rect, d, step = 1)
    r = rect.dup
    case d
    when 2; r.height += step
    when 4; r.x -= step; r.width += step
    when 6; r.width += step
    when 8; r.y -= step; r.height += step
    end
    r
  end

  # 点是否在矩形内（包含边界）
  def self.in_rect?(x, y, rect)
    x >= rect.x && y >= rect.y &&
    x <= rect.x + rect.width - 1 &&
    y <= rect.y + rect.height - 1
  end

  # 获取矩形内指定位置（小键盘编号）的坐标
  def self.rect_xy(rect, pos)
    case pos
    when 1; [rect.x,                     rect.y + rect.height - 1] # 左下
    when 2; [rect.x + (rect.width-1)/2, rect.y + rect.height - 1] # 下中
    when 3; [rect.x + rect.width - 1,    rect.y + rect.height - 1] # 右下
    when 4; [rect.x,                     rect.y + (rect.height-1)/2] # 左中
    when 5; [rect.x + (rect.width-1)/2, rect.y + (rect.height-1)/2] # 中心
    when 6; [rect.x + rect.width - 1,    rect.y + (rect.height-1)/2] # 右中
    when 7; [rect.x,                     rect.y]                     # 左上
    when 8; [rect.x + (rect.width-1)/2, rect.y]                     # 上中
    when 9; [rect.x + rect.width - 1,    rect.y]                     # 右上
    end
  end

  # 获取矩形指定边（方向）的两个端点编号
  def self.rect_border(d)
    case d
    when 2; [1, 3]   # 下边：左下、右下
    when 4; [1, 7]   # 左边：左下、左上
    when 6; [3, 9]   # 右边：右下、右上
    when 8; [7, 9]   # 上边：左上、右上
    end
  end

  # 两个矩形是否相交
  def self.rect_collide?(r1, r2)
    !(r1.x > r2.x + r2.width - 1 ||
      r1.x + r1.width - 1 < r2.x ||
      r1.y > r2.y + r2.height - 1 ||
      r1.y + r1.height - 1 < r2.y)
  end

  #--------------------------------------------------------------------------
  # ● 事件注释解析
  #--------------------------------------------------------------------------
  # @!group 注释解析

  # 解析碰撞矩形配置 <rect ...>
  # @param str [String] 事件页首条注释全文
  # @return [Array<(Integer,nil)>] [x, y, w, h] 像素值，未指定则为 nil
  def self.parse_collision_xywh_str(str)
    x = y = w = h = nil
    return x, y, w, h unless str =~ /<rect ?(.*?)>/mi
    t = $1.strip

    # 特殊指令：还原为默认格子
    if t == "grid"
      return -12, -28, 32, 32
    end

    t.scan(/[xywh][ =]*-?\d+/mi).each do |param|
      type = param[0]
      val = param[1..-1].gsub(/^[ =]*/, '').to_i
      case type
      when 'x'; x = val
      when 'y'; y = val
      when 'w'; w = val
      when 'h'; h = val
      end
    end
    [x, y, w, h]
  end

  # 解析事件绑定配置 <bind ...> ... </bind>
  # @param str [String] 事件页首条注释全文
  # @return [Hash] 格式：{ 目标ID => { :platform => true, :move => 方向 } }
  def self.parse_event_bindings(str)
    binds = {}
    str.scan(/<bind ?(\d+)?>(.*?)<\/bind>/m).each do |args|
      id = args[0].to_i || 0   # 0 表示玩家
      binds[id] ||= {}

      binds[id][:platform] = true if args[1].include?('<platform>')
      if args[1] =~ /<move ?(\d+)>/
        binds[id][:move] = $1.to_i
      end
    end
    binds
  end

  # 根据绑定目标 ID 获取对应的 Game_Character 对象
  def self.get_target(t_id)
    return $game_player if t_id == 0
    $game_map.events[t_id]
  end
end

#==============================================================================
# ■ Game_Map
#==============================================================================
class Game_Map
  #--------------------------------------------------------------------------
  # ● 公开属性：以移动单位为基础的视口坐标（内部使用）
  #--------------------------------------------------------------------------
  alias _pixelmove_display_x display_x
  alias _pixelmove_display_y display_y
  def display_x; PIXEL_MOVE.unit2rgss(@display_x)[0]; end
  def display_y; PIXEL_MOVE.unit2rgss(@display_y)[0]; end

  #--------------------------------------------------------------------------
  # ● 视口位置设置（单位：移动单位）
  #--------------------------------------------------------------------------
  def set_display_pos(x, y)
    w = width_unit; h = height_unit
    x = [[x, width_unit - screen_unit_x].min, 0].max unless loop_horizontal?
    y = [[y, height_unit - screen_unit_y].min, 0].max unless loop_vertical?
    @display_x = (x + w) % w
    @display_y = (y + h) % h
    @parallax_x = x
    @parallax_y = y
  end

  #--------------------------------------------------------------------------
  # ● 远景图偏移（重定义，适配移动单位）
  #--------------------------------------------------------------------------
  def parallax_ox(bitmap)
    v, _ = PIXEL_MOVE.unit2rgss(@parallax_x)
    if @parallax_loop_x
      v * 16
    else
      w1 = [bitmap.width - Graphics.width, 0].max
      w2 = [PIXEL_MOVE.unit2pixel(width_unit) - Graphics.width, 1].max
      v * 16 * w1 / w2
    end
  end

  def parallax_oy(bitmap)
    v, _ = PIXEL_MOVE.unit2rgss(@parallax_y)
    if @parallax_loop_y
      v * 16
    else
      h1 = [bitmap.height - Graphics.height, 0].max
      h2 = [PIXEL_MOVE.unit2pixel(height_unit) - Graphics.height, 1].max
      v * 16 * h1 / h2
    end
  end

  #--------------------------------------------------------------------------
  # ● 地图尺寸（移动单位）
  #--------------------------------------------------------------------------
  def width_unit;   @map.width  * PIXEL_MOVE::UNIT_PER_MAP_GRID; end
  def height_unit;  @map.height * PIXEL_MOVE::UNIT_PER_MAP_GRID; end
  def screen_unit_x; PIXEL_MOVE.pixel2unit(Graphics.width);  end
  def screen_unit_y; PIXEL_MOVE.pixel2unit(Graphics.height); end

  #--------------------------------------------------------------------------
  # ● 坐标转换（屏幕显示用）
  #--------------------------------------------------------------------------
  def adjust_x(x)
    w = width_unit
    if loop_horizontal? && x < @display_x - (w - screen_unit_x) / 2
      x - @display_x + w
    else
      x - @display_x
    end
  end

  def adjust_y(y)
    h = height_unit
    if loop_vertical? && y < @display_y - (h - screen_unit_y) / 2
      y - @display_y + h
    else
      y - @display_y
    end
  end

  #--------------------------------------------------------------------------
  # ● 循环边界修正
  #--------------------------------------------------------------------------
  def round_x(x); loop_horizontal? ? (x + width_unit) % width_unit : x; end
  def round_y(y); loop_vertical?   ? (y + height_unit) % height_unit : y; end

  def x_with_direction_n(x, d, n = 1)
    x + (d == 6 ? n : d == 4 ? -n : 0)
  end
  def y_with_direction_n(y, d, n = 1)
    y + (d == 2 ? n : d == 8 ? -n : 0)
  end
  def round_x_with_direction_n(x, d, n = 1)
    round_x(x_with_direction_n(x, d, n))
  end
  def round_y_with_direction_n(y, d, n = 1)
    round_y(y_with_direction_n(y, d, n))
  end

  #--------------------------------------------------------------------------
  # ● 事件查询（基于移动单位）
  #--------------------------------------------------------------------------
  def events_xy(x, y);      @events.values.select { |e| e.pos?(x, y) }; end
  def events_xy_nt(x, y);   @events.values.select { |e| e.pos_nt?(x, y) }; end
  def events_rect(rect);    @events.values.select { |e| e.pos_rect?(rect) }; end
  def events_rect_nt(rect); @events.values.select { |e| e.pos_rect_nt?(rect) }; end

  #--------------------------------------------------------------------------
  # ● 区域通行控制
  #--------------------------------------------------------------------------
  def region_passable?(x, y)
    id = region_id(x, y)
    !regions_unpassable.include?(id)
  end

  def regions_unpassable
    @regions_unpassable ||= []
  end

  def set_region(region_id, passable = true)
    if passable
      regions_unpassable.delete(region_id)
    else
      regions_unpassable.push(region_id) unless regions_unpassable.include?(region_id)
    end
  end

  #--------------------------------------------------------------------------
  # ● （兼容）原版方法重定义，适配 RGSS 坐标输入
  #--------------------------------------------------------------------------
  def tile_events_xy(x, y)
    @tile_events.select { |ev| ev.pos_rgss_nt?(x, y) }
  end

  def all_tiles(x, y)
    tile_events_xy(x, y).collect(&:tile_id) + layered_tiles(x, y)
  end

  alias _pixelmove_event_id_xy event_id_xy
  def event_id_xy(x, y)
    # 默认方法仍使用格子坐标，保留原样
    _pixelmove_event_id_xy(x, y)
  end

  def valid?(x, y)
    x >= 0 && x < @map.width && y >= 0 && y < @map.height
  end

  #--------------------------------------------------------------------------
  # ● 卷动（输入距离为 RGSS 格子数，内部转换为移动单位）
  #--------------------------------------------------------------------------
  def start_scroll(direction, distance, speed)
    @scroll_direction = direction
    v, _ = PIXEL_MOVE.rgss2unit(distance)
    @scroll_rest = v
    @scroll_speed = speed
  end

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

  def scroll_right(distance)
    if loop_horizontal?
      @display_x += distance
      @display_x %= width_unit
      @parallax_x += distance if @parallax_loop_x
    else
      last_x = @display_x
      @display_x = [@display_x + distance, width_unit - screen_unit_x].min
      @parallax_x += @display_x - last_x
    end
  end

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

  def scroll_distance
    2 ** @scroll_speed / (8.0 * PIXEL_MOVE::PIXEL_PER_UNIT)
  end
end

#==============================================================================
# ■ Game_CharacterBase
#==============================================================================
class Game_CharacterBase
  #--------------------------------------------------------------------------
  # ● 新增公开属性
  #--------------------------------------------------------------------------
  attr_reader :rgss_x, :rgss_y          # 用于兼容原版系统的格子坐标（近似）

  #--------------------------------------------------------------------------
  # ● 初始化（增强）
  #--------------------------------------------------------------------------
  alias _pixelmove_init_public init_public_members
  def init_public_members
    _pixelmove_init_public
    @rgss_x = 0
    @rgss_y = 0
    @collision_rect = Rect.new        # 移动单位矩形，相对于角色原点
    reset_collision_to_default
  end

  #--------------------------------------------------------------------------
  # ● 默认碰撞矩形（像素）—— 子类可覆盖
  #--------------------------------------------------------------------------
  def default_collision_rect
    PIXEL_MOVE::EVENT_RECT
  end

  # 修正旧版拼写，保留兼容（新代码请使用 default_collision_rect）
  alias default_collisin_rect default_collision_rect

  #--------------------------------------------------------------------------
  # ● 碰撞矩形设置（参数为像素值，内部自动转换为移动单位）
  #--------------------------------------------------------------------------
  def set_collision_xywh(x = nil, y = nil, w = nil, h = nil)
    @collision_rect.x = PIXEL_MOVE.pixel2unit(x) if x
    @collision_rect.y = PIXEL_MOVE.pixel2unit(y) if y
    @collision_rect.width  = PIXEL_MOVE.pixel2unit(w) if w
    @collision_rect.height = PIXEL_MOVE.pixel2unit(h) if h
  end

  def set_collision_rect(rect_pixel)
    set_collision_xywh(rect_pixel.x, rect_pixel.y, rect_pixel.width, rect_pixel.height)
  end

  def reset_collision_to_default
    set_collision_rect(default_collision_rect)
  end

  #--------------------------------------------------------------------------
  # ● 获取碰撞矩形
  #   raw_rect = true  : 返回相对自身原点的矩形（移动单位）
  #   raw_rect = false : 返回地图绝对坐标矩形（移动单位）
  #--------------------------------------------------------------------------
  def get_collision_rect(raw_rect = true)
    rect = @collision_rect.dup
    unless raw_rect
      rect.x += @x
      rect.y += @y
    end
    rect
  end

  # 获取实时显示位置对应的碰撞矩形（用于事件触发判定）
  def get_collision_rect_real
    rect = @collision_rect.dup
    rect.x += @real_x
    rect.y += @real_y
    rect
  end

  # 获取碰撞矩形指定位置的实际地图坐标（移动单位）
  def get_collision_xy(pos)
    dx, dy = PIXEL_MOVE.rect_xy(@collision_rect, pos)
    x = $game_map.round_x(dx + @real_x)
    y = $game_map.round_y(dy + @real_y)
    [x, y]
  end

  #--------------------------------------------------------------------------
  # ● 画面显示坐标（重定义）
  #--------------------------------------------------------------------------
  def screen_x
    PIXEL_MOVE.unit2pixel($game_map.adjust_x(@real_x)) + PIXEL_MOVE::PIXEL_PER_UNIT
  end

  def screen_y
    PIXEL_MOVE.unit2pixel($game_map.adjust_y(@real_y)) - shift_y - jump_height +
      PIXEL_MOVE::PIXEL_PER_UNIT
  end

  #--------------------------------------------------------------------------
  # ● 更新 RGSS 近似坐标（用于与原版系统兼容）
  #--------------------------------------------------------------------------
  alias _pixelmove_base_update update
  def update
    _pixelmove_base_update
    update_rgss_xy
  end

  def update_rgss_xy
    @rgss_x, _ = PIXEL_MOVE.unit2rgss(@x)
    @rgss_x = @rgss_x.round
    @rgss_y, _ = PIXEL_MOVE.unit2rgss(@y)
    @rgss_y = @rgss_y.round
    #if self == $game_player
    #  p "unit #{x},#{y} → rgss #{@rgss_x},#{@rgss_y}"
    #end
  end

  #--------------------------------------------------------------------------
  # ● 位置判定（移动单位坐标）
  #--------------------------------------------------------------------------
  def pos?(x, y, rect = @collision_rect)
    PIXEL_MOVE.in_rect?(x - @x, y - @y, rect)
  end

  def pos_nt?(x, y)
    pos?(x, y) && !@through
  end

  def real_pos?(x, y)
    PIXEL_MOVE.in_rect?(x - @real_x, y - @real_y, @collision_rect)
  end

  #--------------------------------------------------------------------------
  # ● 矩形相交判定
  #--------------------------------------------------------------------------
  def pos_rect?(rect)
    PIXEL_MOVE.rect_collide?(rect, get_collision_rect(false))
  end

  def pos_rect_real?(rect)
    PIXEL_MOVE.rect_collide?(rect, get_collision_rect_real)
  end

  def pos_rect_nt?(rect)
    pos_rect?(rect) && !@through
  end

  #--------------------------------------------------------------------------
  # ● RGSS 格子坐标判定（原版兼容）
  #--------------------------------------------------------------------------
  def pos_rgss?(x, y)
    @rgss_x == x && @rgss_y == y
  end

  def pos_rgss_nt?(x, y)
    pos_rgss?(x, y) && !@through
  end

  #--------------------------------------------------------------------------
  # ● 移动速度相关（重定义）
  #--------------------------------------------------------------------------
  def distance_per_frame
    2 ** real_move_speed / 256.0 * PIXEL_MOVE::UNIT_PER_MAP_GRID
  end

  #--------------------------------------------------------------------------
  # ● 设置/移动位置（移动单位）
  #--------------------------------------------------------------------------
  def moveto(x, y)   # 输入 RGSS 格子坐标
    x = x % $game_map.width
    y = y % $game_map.height
    xu, yu = PIXEL_MOVE.event_rgss2unit(x, y)
    moveto_unit(xu, yu)
  end

  def moveto_unit(x, y)
    @x = @real_x = x
    @y = @real_y = y
    update_rgss_xy
    @prelock_direction = 0
    straighten
    update_bush_depth
  end

  def set_xy(x = nil, y = nil)
    @x = x.to_i if x
    @y = y.to_i if y
  end

  # 直接增量移动（用于平台跟随等）
  def moveto_dxy_unit(dx, dy)
    @x += dx; @y += dy
    @real_x += dx; @real_y += dy
  end

  #--------------------------------------------------------------------------
  # ● 通行判定（核心）
  #--------------------------------------------------------------------------
  alias _pixelmove_passable? passable?
  def passable?(x, y, d)
    # 对碰撞盒边界上的两个点分别进行通行检查
    PIXEL_MOVE.rect_border(d).each do |pos|
      dx, dy = PIXEL_MOVE.rect_xy(@collision_rect, pos)
      x1 = $game_map.round_x(x + dx)
      y1 = $game_map.round_y(y + dy)
      x2 = $game_map.round_x_with_direction(x1, d)
      y2 = $game_map.round_y_with_direction(y1, d)

      x1_rgss, _ = PIXEL_MOVE.unit2rgss(x1)
      y1_rgss, _ = PIXEL_MOVE.unit2rgss(y1)
      x2_rgss, _ = PIXEL_MOVE.unit2rgss(x2)
      y2_rgss, _ = PIXEL_MOVE.unit2rgss(y2)

      return false unless $game_map.valid?(x2_rgss, y2_rgss)
      next if @through || debug_through?

      if x1_rgss != x2_rgss || y1_rgss != y2_rgss
        return false unless map_passable?(x1_rgss, y1_rgss, d)
        return false unless map_passable?(x2_rgss, y2_rgss, reverse_dir(d))
      end
      return false unless region_passable?(x2_rgss, y2_rgss)
    end

    # 移动后整体碰撞盒与其他角色的碰撞检测
    dx, dy = PIXEL_MOVE.rect_xy(@collision_rect, 7)  # 左上角
    moved_rect = get_collision_rect(false)
    moved_rect.x = $game_map.round_x_with_direction(x + dx, d)
    moved_rect.y = $game_map.round_y_with_direction(y + dy, d)

    return false if collide_with_charas_rect?(moved_rect)
    return false if collide_with_events_rect?(moved_rect)
    true
  end

  def region_passable?(x, y)
    $game_map.region_passable?(x, y)
  end

  def collide_with_charas_rect?(rect)
    [$game_player, $game_map.boat, $game_map.ship].each do |chara|
      next if self == chara || chara.through
      return true if PIXEL_MOVE.rect_collide?(chara.get_collision_rect(false), rect)
    end
    false
  end

  def collide_with_events_rect?(rect)
    $game_map.events.each do |_, event|
      next if self == event || !event.normal_priority? || event.through
      return true if PIXEL_MOVE.rect_collide?(event.get_collision_rect(false), rect)
    end
    false
  end

  # 原版 collide_with_events? 适配
  def collide_with_events?(x, y)
    rect = PIXEL_MOVE.rgssGrid2unitRect(x, y)
    $game_map.events.any? do |_, e|
      next if self == e || !e.normal_priority? || e.through
      e.pos_rect?(rect)
    end
  end

  def collide_with_vehicles?(x, y)
    rect = PIXEL_MOVE.rgssGrid2unitRect(x, y)
    $game_map.boat.pos_rect?(rect) || $game_map.ship.pos_rect?(rect)
  end

  #--------------------------------------------------------------------------
  # ● 移动指令（单位：移动单位）
  #--------------------------------------------------------------------------
  def move_straight(d, turn_ok = true, n = PIXEL_MOVE::UNIT_PER_MAP_GRID)
    x_ = @x; y_ = @y
    n.times do |i|
      break n = i unless passable?(x_, y_, d)
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

  def move_unit(d, n = 1, turn_ok = true)
    move_straight(d, turn_ok, n)
  end

  def move_forward_unit(n = 1)
    move_straight(@direction, true, n)
  end

  def move_diagonal(horz, vert, n = PIXEL_MOVE::UNIT_PER_MAP_GRID)
    x_ = @x; y_ = @y
    n.times do |i|
      break n = i unless diagonal_passable?(x_, y_, horz, vert)
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

  #--------------------------------------------------------------------------
  # ● 事件触发检测（取碰撞盒面向方向的中点）
  #--------------------------------------------------------------------------
  def check_event_trigger_touch_front
    x, y = get_collision_xy(@direction)
    x2 = $game_map.round_x_with_direction(x, @direction)
    y2 = $game_map.round_y_with_direction(y, @direction)
    check_event_trigger_touch(x2, y2)
  end

  #--------------------------------------------------------------------------
  # ● 地形属性（适配 RGSS 坐标）
  #--------------------------------------------------------------------------
  def ladder?; $game_map.ladder?(@rgss_x, @rgss_y); end
  def bush?;   $game_map.bush?(@rgss_x, @rgss_y);   end
  def terrain_tag; $game_map.terrain_tag(@rgss_x, @rgss_y); end
  def region_id;   $game_map.region_id(@rgss_x, @rgss_y);   end
end

#==============================================================================
# ■ Game_Character
#==============================================================================
class Game_Character < Game_CharacterBase
  #--------------------------------------------------------------------------
  # ● 距离计算（移动单位）
  #--------------------------------------------------------------------------
  def distance_x_from(x)
    result = @x - x
    if $game_map.loop_horizontal? && result.abs > $game_map.width_unit / 2
      result < 0 ? result + $game_map.width_unit : result - $game_map.width_unit
    else
      result
    end
  end

  def distance_y_from(y)
    result = @y - y
    if $game_map.loop_vertical? && result.abs > $game_map.height_unit / 2
      result < 0 ? result + $game_map.height_unit : result - $game_map.height_unit
    else
      result
    end
  end

  #--------------------------------------------------------------------------
  # ● 跳跃（输入 RGSS 格子增量）
  #--------------------------------------------------------------------------
  def jump(x_plus, y_plus)
    if x_plus.abs > y_plus.abs
      set_direction(x_plus < 0 ? 4 : 6) if x_plus != 0
    else
      set_direction(y_plus < 0 ? 8 : 2) if y_plus != 0
    end
    xu, _ = PIXEL_MOVE.rgss2unit(x_plus)
    yu, _ = PIXEL_MOVE.rgss2unit(y_plus)
    @x += xu
    @y += yu
    distance = Math.sqrt(x_plus * x_plus + y_plus * y_plus).round
    @jump_peak = 10 + distance - @move_speed
    @jump_count = @jump_peak * 2
    @stop_count = 0
    straighten
  end
end

#==============================================================================
# ■ Game_Player
#==============================================================================
class Game_Player < Game_Character
  #--------------------------------------------------------------------------
  # ● 默认碰撞矩形
  #--------------------------------------------------------------------------
  def default_collision_rect
    PIXEL_MOVE::PLAYER_RECT
  end

  #--------------------------------------------------------------------------
  # ● 画面中央坐标（移动单位）
  #--------------------------------------------------------------------------
  def center_x; PIXEL_MOVE.pixel2unit(Graphics.width  / 2.0); end
  def center_y; PIXEL_MOVE.pixel2unit(Graphics.height / 2.0); end

  #--------------------------------------------------------------------------
  # ● 设置显示位置（输入 RGSS 格子坐标）
  #--------------------------------------------------------------------------
  def center(x, y)
    xu, _ = PIXEL_MOVE.rgss2unit(x)
    yu, _ = PIXEL_MOVE.rgss2unit(y)
    $game_map.set_display_pos(xu - center_x, yu - center_y)
  end
  
  def center_unit(xu, yu)
    $game_map.set_display_pos(xu - center_x, yu - center_y)
  end

  #--------------------------------------------------------------------------
  # ● 增量移动（更新卷动）
  #--------------------------------------------------------------------------
  def moveto_dxy_unit(dx = 0, dy = 0)
    last_x = @real_x; last_y = @real_y
    super
    update_scroll(last_x, last_y)
  end

  #--------------------------------------------------------------------------
  # ● 方向键移动
  #--------------------------------------------------------------------------
  def move_by_input
    return unless movable? && !$game_map.interpreter.running?
    if PIXEL_MOVE::PLAYER_4DIR && Input.dir4 > 0
      move_straight(Input.dir4, true, PIXEL_MOVE::PLAYER_MOVE_UNIT)
      return
    end
    case Input.dir8
    when 0; return
    when 1; move_straight_8dir(4, 2)
    when 3; move_straight_8dir(6, 2)
    when 7; move_straight_8dir(4, 8)
    when 9; move_straight_8dir(6, 8)
    else    move_straight(Input.dir4, true, PIXEL_MOVE::PLAYER_MOVE_UNIT)
    end
  end

  def move_straight_8dir(horz, vert)
    move_diagonal(horz, vert, PIXEL_MOVE::PLAYER_MOVE_UNIT)
    return if @move_succeed
    move_straight(horz, true, PIXEL_MOVE::PLAYER_MOVE_UNIT)
    return if @move_succeed
    move_straight(vert, true, PIXEL_MOVE::PLAYER_MOVE_UNIT)
  end

  #--------------------------------------------------------------------------
  # ● 移动时同步跟随者
  #--------------------------------------------------------------------------
  def move_straight(d, turn_ok = true, n = PIXEL_MOVE::UNIT_PER_MAP_GRID)
    @followers.move if passable?(@x, @y, d)
    super
  end

  def move_diagonal(horz, vert, n = PIXEL_MOVE::UNIT_PER_MAP_GRID)
    @followers.move if diagonal_passable?(@x, @y, horz, vert)
    super
  end

  #--------------------------------------------------------------------------
  # ● 事件触发（基于碰撞矩形）
  #--------------------------------------------------------------------------
  def check_event_trigger_here(triggers)
    $game_map.events_rect(get_collision_rect(false)).each do |event|
      next if event.tile? && event.priority_type == 0
      event.start if event.trigger_in?(triggers)
    end
  end

  def check_event_trigger_there(triggers)
    x, y = get_collision_xy(@direction)
    x2 = $game_map.round_x_with_direction(x, @direction)
    y2 = $game_map.round_y_with_direction(y, @direction)
    start_map_event(x2, y2, triggers, true)
    return if $game_map.any_event_starting?

    x2_rgss, _ = PIXEL_MOVE.unit2rgss(x2)
    y2_rgss, _ = PIXEL_MOVE.unit2rgss(y2)
    return unless $game_map.counter?(x2_rgss, y2_rgss)
    # 柜台：再前进一格（32像素）
    x3 = $game_map.round_x_with_direction_n(x2, @direction, PIXEL_MOVE.pixel2unit(32))
    y3 = $game_map.round_y_with_direction_n(y2, @direction, PIXEL_MOVE.pixel2unit(32))
    start_map_event(x3, y3, triggers, true)
  end

  def check_event_trigger_touch(x, y)
    start_map_event(x, y, [1,2], true)
  end

  #--------------------------------------------------------------------------
  # ● 载具
  #--------------------------------------------------------------------------
  def get_on_vehicle
    step = PIXEL_MOVE.pixel2unit(32)
    rect = PIXEL_MOVE.lengthen_rect(get_collision_rect(false), @direction, step)
    @vehicle_type = :boat    if $game_map.boat.pos_rect?(rect)
    @vehicle_type = :ship    if $game_map.ship.pos_rect?(rect)
    @vehicle_type = :airship if $game_map.airship.pos_rect?(get_collision_rect(false))
    if vehicle
      @vehicle_getting_on = true
      set_xy(vehicle.x, vehicle.y)
      @followers.gather
    end
    @vehicle_getting_on
  end

  def get_off_vehicle
    if vehicle.land_ok?(@x, @y, @direction)
      set_direction(2) if in_airship?
      @followers.synchronize_unit(@x, @y, @direction)
      vehicle.get_off
      unless in_airship?
        n, _ = PIXEL_MOVE.rgss2unit(1)
        des_x = $game_map.round_x_with_direction_n(vehicle.x, @direction, n)
        des_y = $game_map.round_y_with_direction_n(vehicle.y, @direction, n)
        set_xy(des_x, des_y)
        @transparent = false
      end
      @vehicle_getting_off = true
      @move_speed = 4
      @through = false
      make_encounter_count
      @followers.gather
    end
    @vehicle_getting_off
  end

  #--------------------------------------------------------------------------
  # ● 碰撞？（适配矩形）
  #--------------------------------------------------------------------------
  def collide?(x, y)
    rect = PIXEL_MOVE.rgssGrid2unitRect(x, y)
    !@through && (pos_rect?(rect) || followers.collide?(x, y))
  end
end

#==============================================================================
# ■ Game_Follower
#==============================================================================
class Game_Follower < Game_Character
  def collide?(x, y)
    rect = PIXEL_MOVE.rgssGrid2unitRect(x, y)
    visible_followers.any? { |f| f.pos_rect?(rect) }
  end

  def chase_preceding_character(gathering = false)
    return if moving?
    sx = distance_x_from(@preceding_character.x).to_i
    sy = distance_y_from(@preceding_character.y).to_i
    dx = sx.abs; dy = sy.abs
    return if !gathering && dx + dy < PIXEL_MOVE::FOLLOWER_MIN_UNIT

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

#==============================================================================
# ■ Game_Followers
#==============================================================================
class Game_Followers
  def move
    reverse_each { |f| f.chase_preceding_character(@gathering) }
  end

  def synchronize_unit(x, y, d)
    each do |f|
      f.moveto_unit(x, y)
      f.set_direction(d)
    end
  end
end

#==============================================================================
# ■ Game_Vehicle
#==============================================================================
class Game_Vehicle < Game_Character
  alias _pixelmove_initialize initialize
  def initialize(type)
    _pixelmove_initialize(type)
    case @type
    when :boat;    set_collision_rect(PIXEL_MOVE::BOAT_RECT)
    when :ship;    set_collision_rect(PIXEL_MOVE::SHIP_RECT)
    when :airship; set_collision_rect(PIXEL_MOVE::AIRSHIP_RECT)
    end
  end

  def land_ok?(x, y, d)
    if @type == :airship
      x_rgss, _ = PIXEL_MOVE.unit2rgss(x)
      y_rgss, _ = PIXEL_MOVE.unit2rgss(y)
      return false unless $game_map.airship_land_ok?(x_rgss, y_rgss)
      return false unless $game_map.events_rect_nt(get_collision_rect(false)).empty?
    else
      n, _ = PIXEL_MOVE.rgss2unit(1)
      x2 = $game_map.round_x_with_direction_n(x, d, n)
      y2 = $game_map.round_y_with_direction_n(y, d, n)
      x2_rgss, _ = PIXEL_MOVE.unit2rgss(x2)
      y2_rgss, _ = PIXEL_MOVE.unit2rgss(y2)
      return false unless $game_map.valid?(x2_rgss, y2_rgss)
      return false unless $game_map.passable?(x2_rgss, y2_rgss, reverse_dir(d))
      rect = PIXEL_MOVE.lengthen_rect(get_collision_rect(false), d, n)
      return false if collide_with_events_rect?(rect)
    end
    true
  end
end

#==============================================================================
# ■ Game_Event
#==============================================================================
class Game_Event < Game_Character
  #--------------------------------------------------------------------------
  # ● 设置事件页时解析注释
  #--------------------------------------------------------------------------
  alias _pixelmove_setup_page setup_page
  def setup_page(new_page)
    _pixelmove_setup_page(new_page)
    comment = EAGLE_COMMON.event_comment_head(@list)

    # 碰撞矩形
    x, y, w, h = PIXEL_MOVE.parse_collision_xywh_str(comment)
    set_collision_xywh(x, y, w, h)

    # 事件绑定
    @eagle_binds = PIXEL_MOVE.parse_event_bindings(comment)
  end

  #--------------------------------------------------------------------------
  # ● 更新（处理平台、强制移动）
  #--------------------------------------------------------------------------
  alias _pixelmove_event_update update
  def update
    last_x = @real_x
    last_y = @real_y
    _pixelmove_event_update
    return unless @eagle_binds
    @eagle_binds.each do |c_id, params|
      update_binding_platform(c_id, last_x, last_y) if params[:platform]
      update_binding_move(c_id, last_x, last_y)      if params[:move]
    end
  end

  # 移动平台
  def update_binding_platform(c_id, last_x, last_y)
    chara = PIXEL_MOVE.get_target(c_id)
    if real_pos?(chara.real_x, chara.real_y)
      unless @eagle_binds[c_id][:f_on_platform]
        @eagle_binds[c_id][:f_on_platform] = true
        dx, dy = PIXEL_MOVE.rect_xy(@collision_rect, 5)
        chara.set_xy(last_x + dx, last_y + dy)
        return
      end
      chara.moveto_dxy_unit(@real_x - last_x, @real_y - last_y)
    else
      @eagle_binds[c_id][:f_on_platform] = false
    end
  end

  # 强制移动区域
  def update_binding_move(c_id, last_x, last_y)
    chara = PIXEL_MOVE.get_target(c_id)
    return if chara.moving?
    cx, cy = chara.get_collision_xy(5)
    if pos?(cx, cy)
      unless @eagle_binds[c_id][:f_on_move]
        @eagle_binds[c_id][:f_on_move] = true
        dx, dy = PIXEL_MOVE.rect_xy(@collision_rect, 5)
        chara.set_xy(last_x + dx, last_y + dy)
        return
      end
      d = @eagle_binds[c_id][:move]
      tx = $game_map.x_with_direction_n(chara.x, d, 4)
      ty = $game_map.y_with_direction_n(chara.y, d, 4)
      chara.set_direction(d)
      chara.moveto_dxy_unit(tx - chara.x, ty - chara.y)
    else
      @eagle_binds[c_id][:f_on_move] = false
    end
  end

  #--------------------------------------------------------------------------
  # ● 其他重定义
  #--------------------------------------------------------------------------
  def near_the_player?
    sx = distance_x_from($game_player.x).abs
    sy = distance_y_from($game_player.y).abs
    sx + sy < 20 * PIXEL_MOVE::UNIT_PER_MAP_GRID
  end

  def near_the_screen?(dx = Graphics.width / 2, dy = Graphics.height / 2)
    ax, ay = PIXEL_MOVE.rect_xy(@collision_rect, 5)
    ax = PIXEL_MOVE.unit2pixel($game_map.adjust_x(@real_x + ax)) - dx
    ay = PIXEL_MOVE.unit2pixel($game_map.adjust_y(@real_y + ay)) - dy
    ax >= -dx && ax <= dx && ay >= -dy && ay <= dy
  end

  def check_event_trigger_touch(x, y)
    return if $game_map.interpreter.running?
    return unless @trigger == 2
    r = PIXEL_MOVE.move_rect(get_collision_rect_real, @direction, 1)
    if PIXEL_MOVE.rect_collide?(r, $game_player.get_collision_rect_real)
      start if !jumping? && normal_priority?
    end
  end
end

#==============================================================================
# ■ 显示碰撞矩形
#==============================================================================
if $TEST and PIXEL_MOVE::DRAW_EVENT_RECT
class Sprite_Character < Sprite_Base
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #     character : Game_Character
  #--------------------------------------------------------------------------
  alias eagle_pixel_move_init initialize
  def initialize(viewport, character = nil)
    @sprite_collision_rect = Sprite.new
    @collision_rect = Rect.new
    eagle_pixel_move_init(viewport, character)
    reset_sprite_collsion
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  alias eagle_pixel_move_dispose dispose
  def dispose
    eagle_pixel_move_dispose
    @sprite_collision_rect.bitmap.dispose 
    @sprite_collision_rect.dispose
  end
  #--------------------------------------------------------------------------
  # ● 更新位置
  #--------------------------------------------------------------------------
  alias eagle_pixel_move_update_position update_position
  def update_position
    eagle_pixel_move_update_position
    r = @character.get_collision_rect(true)
    @sprite_collision_rect.x = self.x + PIXEL_MOVE.unit2pixel(r.x)
    @sprite_collision_rect.y = self.y + PIXEL_MOVE.unit2pixel(r.y) + @character.shift_y
    @sprite_collision_rect.z = self.z + 1
    @sprite_collision_rect.opacity = @character.opacity
    @sprite_collision_rect.visible = !@character.transparent
    return if r.width == @collision_rect.width and r.height == @collision_rect.height
    reset_sprite_collsion
  end
  #--------------------------------------------------------------------------
  # ● 重置碰撞矩形精灵
  #--------------------------------------------------------------------------
  def reset_sprite_collsion
    r = @character.get_collision_rect(true)
    @collision_rect.width  = r.width
    @collision_rect.height = r.height
    
    w = PIXEL_MOVE.unit2pixel(r.width)
    h = PIXEL_MOVE.unit2pixel(r.height)
    @sprite_collision_rect.bitmap.dispose if @sprite_collision_rect.bitmap
    @sprite_collision_rect.bitmap = Bitmap.new(w,h)
    d = 1
    @sprite_collision_rect.bitmap.fill_rect(0,0,w,h,Color.new(255,255,255,150))
    @sprite_collision_rect.bitmap.clear_rect(d,d,w-d*2,h-d*2)
  end
end
end

#==============================================================================
# ■ DataManager（修复版本更新时地图重载的BUG）
#==============================================================================
module DataManager
  def self.reload_map_if_updated
    if $game_system.version_id != $data_system.version_id
      $game_map.setup($game_map.map_id)
      $game_player.center($game_player.rgss_x, $game_player.rgss_y)
      $game_player.make_encounter_count
    end
  end
end

#==============================================================================
# ■ 兼容 Map Effects
#==============================================================================
if $imported[:Zeus_Map_Effects]
  
class Game_Map_Effects
  
  def update_animation_variable_zoom2(variable, base_value, target_value, 
      duration, duration_total, center_on_player)
    update_animation_Float(variable, base_value, target_value, 
      duration, duration_total, nil)
    @zoom_y = @zoom_x = @zoom2 ** 2 / 100.0
    display_ratio = Game_Map::DisplayRatio.to_f
    if center_on_player
      x = $game_player.real_x / display_ratio
      y = $game_player.real_y / display_ratio
    else
      x = $game_map.display_x / display_ratio + $game_map.screen_unit_x / 2
      y = $game_map.display_y / display_ratio + $game_map.screen_unit_y / 2
    end
    $game_player.center_unit(x, y)
  end
  
end

class Game_Map
  
  def zoom_ox_unit
    return 0 unless effects.active and effects.zoom_x > 1
    (1 - 1 / effects.zoom_x) * screen_unit_x / 2
  end
  def zoom_oy_unit
    return 0 unless effects.active and effects.zoom_y > 1
    (1 - 1 / effects.zoom_y) * screen_unit_y / 2
  end
  
  def limit_x_unit(x)
    ox  = zoom_ox_unit
    min = DisplayRatio * -ox
    max = DisplayRatio * (width_unit - screen_unit_x + ox)
    x < max ? x < min ? min : x : max
  end
  def limit_y_unit(y)
    oy  = zoom_oy_unit
    min = DisplayRatio * -oy
    max = DisplayRatio * (height_unit - screen_unit_y + oy)
    y < max ? y < min ? min : y : max
  end
  
  def set_display_x(x)
    x = loop_horizontal? ? x % (width_unit * DisplayRatio) : limit_x_unit(x)
    @parallax_x += x - @display_x if @parallax_loop_x or !loop_horizontal?
    @display_x   = x
  end
  def set_display_y(y)
    y = loop_vertical? ? y % (height_unit * DisplayRatio) : limit_y_unit(y)
    @parallax_y += y - @display_y if @parallax_loop_y or !loop_vertical?
    @display_y   = y
  end
  
  def set_display_pos(x, y)  set_display_x(x); set_display_y(y)   end
  def scroll_down(distance)  set_display_y(@display_y + distance) end
  def scroll_left(distance)  set_display_x(@display_x - distance) end
  def scroll_right(distance) set_display_x(@display_x + distance) end
  def scroll_up(distance)    set_display_y(@display_y - distance) end
    
end

end
