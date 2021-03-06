#==============================================================================
# ■ AStar寻路扩展 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
$imported ||= {}
$imported["EAGLE-AStar"] = true
#==============================================================================
# - 2020.12.31.14 修复事件自主移动中使用寻路时可能的bug
#=============================================================================
# - 本插件新增了经典的A*寻路算法
# - 参考：https://taroxd.github.io/rgss/astar.html
#-----------------------------------------------------------------------------
# 【使用】
# - 在事件脚本中，使用该脚本将事件移动到目的地并等待结束
#        astar_goto(chara_id, x, y[, wait])
#
#     其中 chara_id 为 -1 是玩家、0 是本事件、正数 是指定的事件ID
#     其中 (x,y) 为地图编辑器中的坐标
#     其中 wait 为是否等待移动结束，可不传入，默认等待
#
# - 示例：
#     astar_goto(0, 5,5,false)  → 当前事件寻路移动至(5,5)处，且事件继续执行
#     astar_goto(-1, 12,1)      → 玩家寻路移动至(12,1)处，等待移动结束
#
# - 注意：
#     当寻路失败时（被其他事件挡住所有通路；目的地周围不可通行），
#      将强制等待 WAIT_WHEN_FAIL_ASTAR 帧，以保证不会重复多次寻路造成卡顿
#-----------------------------------------------------------------------------
# 【使用】
# - 若 S_ID_EVENT_CHASE_PLAYER_ON 所对应的开关开启，
#   则事件的自主移动中，会将 类型：接近 替换成使用A*寻路算法，
#   也会将移动路线设置中的 接近玩家 替换成使用A*寻路算法
#-----------------------------------------------------------------------------
# 【兼容】
# - 若使用了【像素级移动 by老鹰】，将依然按照原始网格进行搜索寻路
#-----------------------------------------------------------------------------
# 【高级】
# - 为 Game_Character类新增了方法，这些方法可以直接用于 移动路线 - 脚本 中
#     astar_one_step(x, y)  → 朝(x,y)寻路前进一步
#     astar_toward(chara_id)→ 朝 chara_id 的事件寻路前进一步
#     astar_until(x, y)     → 朝(x,y)寻路直至到达（不考虑事件移动频率）
#     astar_until_self(x, y)→ 朝(x,y)寻路直至到达
#                            （事件-自主移动-自定义中使用，以契合事件移动频率）
#     astar_moving          → 若在寻路中，则返回 true
#=============================================================================

module Eagle_AStar
  #--------------------------------------------------------------------------
  # ● 【常量】当开关开启时，将事件的接近玩家更改为使用自动寻路
  #--------------------------------------------------------------------------
  S_ID_EVENT_CHASE_PLAYER_ON = 1
  #--------------------------------------------------------------------------
  # ● 【常量】当寻路失败，强制等待的帧数（防止多次寻路造成卡顿）
  #--------------------------------------------------------------------------
  WAIT_WHEN_FAIL_ASTAR = 40
  #--------------------------------------------------------------------------
  # ● A*寻路算法
  #--------------------------------------------------------------------------
  def self.do(chara, des_x, des_y)
    pro = Process.new(chara, des_x, des_y)
    pro.do_search
    pro.output_path
  end
class Process
  #--------------------------------------------------------------------------
  # ● A*寻路算法
  #--------------------------------------------------------------------------
  def initialize(chara, des_x, des_y)
    @chara = chara
    @des_x = des_x
    @des_y = des_y
    x_init = @chara.x
    y_init = @chara.y
    if $imported["EAGLE-PixelMove"]
      des_xp, des_yp = PIXEL_MOVE.event_rgss2unit(@des_x, @des_y)
      return true if @chara.pos?(des_xp, des_yp)
      x_init, y_init = PIXEL_MOVE.event_unit2rgss(x_init, y_init)
    else
      return true if @chara.pos?(@des_x, @des_y)
    end

    @w = $game_map.width; @h = $game_map.height
    @g_data = Table.new(@w, @h)
    @f_data = Table.new(@w, @h)
    @dir_data = Table.new(@w, @h)

    @open = [ [x_init, y_init] ]
    @g_data[x_init, y_init] = 1
    @f_data[x_init, y_init] = calc_f(1, x_init ,y_init)
    @dir_data[x_init, y_init] = 5
  end
  #--------------------------------------------------------------------------
  # ● 搜索
  #--------------------------------------------------------------------------
  DIR_TO_DXY = { 2 => [0, 1], 4 => [-1, 0], 6 => [1, 0], 8 => [0, -1] }
    {1 => [-1, 1], 3 => [1, 1], 7 => [-1, -1], 9 => [1, -1] }
  def do_search
    @flag_fin = false
    cur = nil
    while( !@flag_fin )
      break if @open.empty?
      cur = @open.shift
      cur_g = @g_data[cur[0], cur[1]]
      DIR_TO_DXY.each do |dir, dxy|
        x_ = cur[0] + dxy[0]
        y_ = cur[1] + dxy[1]
        check_point(cur[0], cur[1], dir, x_, y_, cur_g)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 检查指定位置
  #--------------------------------------------------------------------------
  def check_point(x_old, y_old, dir, x, y, g)
    return if x < 0 || y < 0
    return if x >= @w || y >= @h
    return if @g_data[x, y] > 0 # 已经被索引过
    if !passable?(@chara, x_old, y_old, dir)
      @dir_data[x, y] = -1
      @g_data[x, y] = 999
      @f_data[x, y] = calc_f(g, x ,y)
    else
      @dir_data[x, y] = dir
      @g_data[x, y] = g + 1
      f = @f_data[x, y] = calc_f(g, x ,y)
      point = @open[0]
      if point.nil? || f > @f_data[point[0], point[1]]
        @open.push( [x, y] )
      else
        @open.unshift( [x, y] )
      end
    end
    if x == @des_x && y == @des_y
      @dir_data[x, y] = dir
      @flag_fin = true
    end
  end
  #--------------------------------------------------------------------------
  # ● 启发函数
  #--------------------------------------------------------------------------
  def calc_f(g, x, y)
    g + (x - @des_x).abs + (y - @des_y).abs
  end
  #--------------------------------------------------------------------------
  # ● 可从(x,y)朝dir方向通行？
  #--------------------------------------------------------------------------
  def passable?(chara, x, y, dir)
    return chara.passable_pixel?(x, y, dir) if $imported["EAGLE-PixelMove"]
    chara.passable?(x, y, dir)
  end
  #--------------------------------------------------------------------------
  # ● 输出移动的数组（2,4,6,8）
  #--------------------------------------------------------------------------
  def output_path
    return nil if !@flag_fin
    path = []; x = @des_x; y = @des_y; dir = @dir_data[x, y]
    while ( dir != 5 )
      break if @dir_data[x, y] == -1
      path.unshift( dir )
      x = x + DIR_TO_DXY[ 10 - dir ][0]
      y = y + DIR_TO_DXY[ 10 - dir ][1]
      dir = @dir_data[x, y]
    end
    path
  end
end # end of class
end

if $imported["EAGLE-PixelMove"]
class Game_Character
  #--------------------------------------------------------------------------
  # ● 可以通行？
  #  IN: rgssXY
  #--------------------------------------------------------------------------
  def passable_pixel?(x, y, dir)
    x2 = $game_map.round_x_with_direction(x, dir)
    y2 = $game_map.round_y_with_direction(y, dir)
    return false unless $game_map.valid?(x2, y2)
    return true if @through || debug_through?
    return false unless map_passable?(x, y, dir)
    return false unless map_passable?(x2, y2, reverse_dir(dir))
    return false if self != $game_player && collide_with_player_pixel?(x2, y2)
    return false if collide_with_events_pixel?(x2, y2)
    return false if collide_with_vehicles_pixel?(x2, y2)
    return true
  end
  #--------------------------------------------------------------------------
  # ● 判定是否与玩家碰撞
  #  IN: rgssXY
  #--------------------------------------------------------------------------
  def collide_with_player_pixel?(x, y)
    x_p, e = PIXEL_MOVE.rgss2unit(x)
    y_p, e = PIXEL_MOVE.rgss2unit(y)
    r = Rect.new(x_p, y_p, PIXEL_MOVE.pixel2unit(32), PIXEL_MOVE.pixel2unit(32))
    $game_player.pos_rect?(r)
  end
  #--------------------------------------------------------------------------
  # ● 判定是否与事件碰撞
  #  IN: rgssXY
  #--------------------------------------------------------------------------
  def collide_with_events_pixel?(x, y)
    x_p, e = PIXEL_MOVE.rgss2unit(x)
    y_p, e = PIXEL_MOVE.rgss2unit(y)
    r = Rect.new(x_p, y_p, PIXEL_MOVE.pixel2unit(32), PIXEL_MOVE.pixel2unit(32))
    $game_map.events.each do |id, event|
      next if event == self || !event.normal_priority? || event.through
      return true if event.pos_rect?(r)
    end
    return false
  end
  #--------------------------------------------------------------------------
  # ● 判定是否与载具碰撞
  #  IN: rgssXY
  #--------------------------------------------------------------------------
  def collide_with_vehicles_pixel?(x, y)
    x_p, e = PIXEL_MOVE.rgss2unit(x)
    y_p, e = PIXEL_MOVE.rgss2unit(y)
    r = Rect.new(x_p, y_p, PIXEL_MOVE.pixel2unit(32), PIXEL_MOVE.pixel2unit(32))
    $game_map.boat.pos_rect_nt?(r) || $game_map.ship.pos_rect_nt?(r)
  end
end
end

class Game_Character
  attr_reader :astar_moving, :astar_moving_self
  #--------------------------------------------------------------------------
  # ● 寻路前进一步
  #--------------------------------------------------------------------------
  def astar_one_step(x, y)
    list = Eagle_AStar.do(self, x, y) rescue nil
    return true if list == true
    return false if list.nil? || list.empty?
    move_straight(list[0])
    return list[0]
  end
  #--------------------------------------------------------------------------
  # ● 获取事件
  #     param : -1 则玩家、0 则本事件、其他 则是指定的事件ID
  #--------------------------------------------------------------------------
  def get_character(param)
    if $game_party.in_battle
      nil
    elsif param < 0
      $game_player
    else
      events = same_map? ? $game_map.events : {}
      events[param > 0 ? param : @event_id]
    end
  end
  #--------------------------------------------------------------------------
  # ● 寻路前进一步
  #--------------------------------------------------------------------------
  def astar_toward(chara_id)
    ch = get_character(chara_id)
    x = ch.x; y = ch.y
    if $imported["EAGLE-PixelMove"]
      x = ch.rgss_x; y = ch.rgss_y
    end
    return astar_one_step(x, y)
  end
  #--------------------------------------------------------------------------
  # ● 强制移动路径
  #--------------------------------------------------------------------------
  def astar_until(x, y)
    @astar_moving = true
    @astar_des_x = x
    @astar_des_y = y
    @astar_wait = 1
    update_astar_move
  end
  #--------------------------------------------------------------------------
  # ● 强制移动路径（自主移动）
  #--------------------------------------------------------------------------
  def astar_until_self(x, y)
    astar_until(x, y)
    @astar_moving = false
    @astar_moving_self = true
  end
  #--------------------------------------------------------------------------
  # ● 更新停止
  #--------------------------------------------------------------------------
  alias eagle_astar_update_stop update_stop
  def update_stop
    eagle_astar_update_stop
    update_astar_move if @astar_moving
  end
  #--------------------------------------------------------------------------
  # ● 更新寻路
  # 返回 true 代表寻路结束
  #--------------------------------------------------------------------------
  def update_astar_move
    return false if (@astar_wait -= 1) > 0
    if astar_reach?
      process_astar_reach
      return true
    end
    f = astar_one_step(@astar_des_x, @astar_des_y)
    @astar_wait = Eagle_AStar::WAIT_WHEN_FAIL_ASTAR if f == false
    set_direction(f)
    return false
  end
  #--------------------------------------------------------------------------
  # ● 到达目的地？
  #--------------------------------------------------------------------------
  def astar_reach?
    if $imported["EAGLE-PixelMove"]
      return @astar_des_x == self.rgss_x && @astar_des_y == self.rgss_y
    end
    @astar_des_x == self.x && @astar_des_y == self.y
  end
  #--------------------------------------------------------------------------
  # ● 到达目的地时的处理
  #--------------------------------------------------------------------------
  def process_astar_reach
    @astar_moving = false
    @astar_moving_self = false
  end
  #--------------------------------------------------------------------------
  # ● 接近玩家
  #--------------------------------------------------------------------------
  alias eagle_astar_move_toward_player move_toward_player
  def move_toward_player
    if $game_switches[Eagle_AStar::S_ID_EVENT_CHASE_PLAYER_ON]
      return if move_toward_player_astar
    end
    eagle_astar_move_toward_player
  end
  #--------------------------------------------------------------------------
  # ● Astar接近玩家（一步）
  #--------------------------------------------------------------------------
  def move_toward_player_astar
    return false if @astar_wait && (@astar_wait -=1) > 0
    r = astar_one_step($game_player.x, $game_player.y)
    @astar_wait = Eagle_AStar::WAIT_WHEN_FAIL_ASTAR if !r
    return r
  end
end

class Game_Event
  #--------------------------------------------------------------------------
  # ● 移动类型 : 接近
  #--------------------------------------------------------------------------
  alias eagle_astar_move_type_toward_player move_type_toward_player
  def move_type_toward_player
    if $game_switches[Eagle_AStar::S_ID_EVENT_CHASE_PLAYER_ON]
      return if move_toward_player_astar
    end
    eagle_astar_move_type_toward_player
  end
  #--------------------------------------------------------------------------
  # ● 移动类型 : 自定义
  #--------------------------------------------------------------------------
  def move_type_custom
    return if @astar_moving_self && !update_astar_move
    update_routine_move
  end
end

class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 寻路
  #     chara_id : -1 则玩家、0 则本事件、其他 则是指定的事件ID
  #--------------------------------------------------------------------------
  def astar_goto(chara_id, x, y, wait = true)
    $game_map.refresh if $game_map.need_refresh
    character = get_character(chara_id)
    return if character.nil?
    character.astar_until(x, y)
    Fiber.yield while character.astar_moving if wait
  end
end
