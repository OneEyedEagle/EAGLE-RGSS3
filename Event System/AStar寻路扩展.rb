#==============================================================================
# ■ AStar寻路扩展 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
$imported ||= {}
$imported["EAGLE-AStar"] = true
#==============================================================================
# - 2020.2.15.23
#=============================================================================
# - 本插件新增了经典的A*寻路算法
#-----------------------------------------------------------------------------
# - 对于 Game_Character类，新增 astar_goto(x, y) 方法，
#   返回从角色当前位置到（x,y）的移动方向的数组
# - 【兼容】若使用了【像素级移动 by老鹰】，将依然按照原始网格进行搜索寻路
#=============================================================================

module Eagle_AStar
  #--------------------------------------------------------------------------
  # ● A*节点
  #--------------------------------------------------------------------------
  class AStar_Node
    attr_reader    :x, :y, :f, :g, :pre, :dir
    def initialize(x, y, des_x, des_y, g=0, pre=nil, dir=0)
      @x = x; @y = y; @g = g
      @f = calc_f(@g, @x, @y, des_x, des_y)
      @pre = pre; @dir = dir
    end
    def calc_f(g, x, y, des_x, des_y) # 启发函数
      g + (x - des_x).abs + (y - des_y).abs
    end
  end
  #--------------------------------------------------------------------------
  # ● A*寻路算法
  #--------------------------------------------------------------------------
  DIR_TO_DXY = { 2 => [0, 1], 4 => [-1, 0], 6 => [1, 0], 8 => [0, -1] }
  def self.do(chara, des_x, des_y)
    x_init = chara.x
    y_init = chara.y
    if $imported["EAGLE-PixelMove"]
      des_xp, des_yp = PIXEL_MOVE.event_rgss2unit(des_x, des_y)
      return if chara.pos?(des_xp, des_yp)
      x_init, y_init = PIXEL_MOVE.event_unit2rgss(x_init, y_init)
    else
      return if chara.pos?(des_x, des_y)
    end
    _open = [AStar_Node.new(x_init, y_init, des_x, des_y)]; _close = []
    final_node = nil
    while(final_node == nil)
      break if _open.empty?
      cur = _open.min { |a, b| a.f <=> b.f }
      _open.delete(cur); _close.push(cur)
      DIR_TO_DXY.each do |dir, dxy|
        n = AStar_Node.new(cur.x + dxy[0], cur.y + dxy[1], des_x, des_y,
          cur.g + 1, cur, dir)
        break final_node = n if n.x == des_x && n.y == des_y
        next if !passable?(chara, cur.x, cur.y, dir)
        i = nil
        _close.each_with_index{ |m, index| break i = index if m.x == n.x && m.y == n.y }
        next if i
        _open.each_with_index { |m, index| break i = index if m.x == n.x && m.y == n.y }
        if i
          _open[i] = n if n.g < _open[i].g
        else
          _open.push(n)
        end
      end
    end
    return if final_node == nil
    path = [final_node.dir]; cur = final_node
    while(true)
      cur = cur.pre
      cur.dir == 0 ? break : path.unshift( cur.dir )
    end
    return path
  end
  #--------------------------------------------------------------------------
  # ● 可从(x,y)朝dir方向通行？
  #--------------------------------------------------------------------------
  def self.passable?(chara, x, y, dir)
    return chara.passable_pixel?(x, y, dir) if $imported["EAGLE-PixelMove"]
    chara.passable?(x, y, dir)
  end
end

class Game_Character
if $imported["EAGLE-PixelMove"]
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
      next if event == self
      if event.normal_priority? && event.pos_rect?(r)
        return true
      end
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
  #--------------------------------------------------------------------------
  # ● 寻路
  #--------------------------------------------------------------------------
  def astar_goto(x, y)
    list = Eagle_AStar.do(self, x, y)
    move_straight(list[0]) if list
  end
end
