#==============================================================================
# ■ 简易地图放大 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
#==============================================================================
$imported ||= {}
$imported["EAGLE-MapZoom"] = "1.0.2"
#==============================================================================
# - 2025.5.11.13 修改为以地图格子中心为放大基准点
#==============================================================================
# - 本插件新增了一个简单的地图放大功能
#   本质为实时截图，并放大显示该截图
#----------------------------------------------------------------------------
# 【使用】
#
# - 利用脚本设置地图放大：
#
#     $game_map.zoom = 数字
#
#  · 其中 数字 为需要放大的百分数，比如 100 为 100%，200 为 200%
#
#     （注：数字小于 100 时无效）
#
# - 利用脚本设置地图放大时的中心点：
#
#     $game_map.zoom_center = 数字 或 数组
#
#  · 其中 数字 为需要作为中心点的事件的ID
#
#  · 其中 数组 为需要作为中心点的地图坐标[x,y]
#
#  · 如果填入 nil 或 -1，则取屏幕中心为放大点
#
#  · 如果填入 0 或对应事件不存在，则取玩家为中心
#
#  · 该中心点并不是指目标作为屏幕中心，而是确保放大后其显示在可见区域内，
#     如果100%缩放时目标事件位于屏幕外，则地图放大失效，重置为 100% 缩放
#
#----------------------------------------------------------------------------
# 【示例】
#
# - 地图放大为 200%，且以1号事件为中心：
#
#      $game_map.zoom = 200
#      $game_map.zoom_center = 1
#
# - 地图放大为 300%，且以玩家为中心：
#
#      $game_map.zoom = 300
#      $game_map.zoom_center = 0
#
# - 地图放大为 150%，且以屏幕中心为中心：
#
#      $game_map.zoom = 150
#      $game_map.zoom_center = nil
#
# - 地图放大为 120%，且以地图[1,1]为中心：
#
#      $game_map.zoom = 120
#      $game_map.zoom_center = [1,1]
#
# - 地图复原：
#
#      $game_map.zoom = 100
#
#==============================================================================

module EAGLE
  #--------------------------------------------------------------------------
  # ●【常量】地图放缩时所用帧数
  #--------------------------------------------------------------------------
  MAP_ZOOM_T = 30
  #--------------------------------------------------------------------------
  # ●【常量】地图放缩时所用缓动函数
  #--------------------------------------------------------------------------
  def self.map_zoom_ease(x)  # x 为0~1之间的小数
    1 - 2**(-10 * x)
  end
end

module SceneManager
  #--------------------------------------------------------------------------
  # ● 生成指定元素的截图
  #  其中 objs 数组中的元素必须有 z 属性
  #--------------------------------------------------------------------------
  def self.snapshot_custom(objs=[])
    z_max = 65535
    sprite_back = Sprite.new
    sprite_back.bitmap = Bitmap.new(1,1)
    sprite_back.zoom_x = Graphics.width
    sprite_back.zoom_y = Graphics.height
    sprite_back.z = z_max
    objs.each { |s| s.z += z_max }
    b = Graphics.snap_to_bitmap
    objs.each { |s| s.z -= z_max }
    sprite_back.bitmap.dispose
    sprite_back.dispose
    return b
  end
end

class Game_Map
  attr_accessor  :zoom, :zoom_center
end

class Spriteset_Map
  #--------------------------------------------------------------------------
  # ● 生成远景图
  #--------------------------------------------------------------------------
  alias eagle_map_zoom_create_parallax create_parallax
  def create_parallax
    eagle_map_zoom_create_parallax
    @eagle_sprite_zoom = Sprite.new
    @eagle_sprite_zoom.z = 1
    @eagle_sprite_zoom.visible = false
    @eagle_zoom = { :v_des => 100, :v => 100, :v1 => 0, :vd => 0,
      :t => EAGLE::MAP_ZOOM_T, :c => nil }
  end
  #--------------------------------------------------------------------------
  # ● 释放远景图
  #--------------------------------------------------------------------------
  alias eagle_map_zoom_dispose_parallax dispose_parallax
  def dispose_parallax
    eagle_map_zoom_dispose_parallax
    @eagle_sprite_zoom.bitmap.dispose if @eagle_sprite_zoom.bitmap
    @eagle_sprite_zoom.dispose
  end
  #--------------------------------------------------------------------------
  # ● 更新远景图
  #--------------------------------------------------------------------------
  alias eagle_map_zoom_update_parallax update_parallax
  def update_parallax
    eagle_map_zoom_update_parallax
    v = $game_map.zoom.to_i rescue 100
    v = 100 if v < 100
    if v != @eagle_zoom[:v_des]
      @eagle_zoom[:v_des] = v
      @eagle_zoom[:v1] = @eagle_zoom[:v]
      @eagle_zoom[:vd] = v - @eagle_zoom[:v]
      @eagle_zoom[:c] = 0
      @eagle_sprite_zoom.visible = true
    end
    if @eagle_zoom[:c] != nil
      @eagle_zoom[:c] += 1
      r = @eagle_zoom[:c] * 1.0 / @eagle_zoom[:t]
      v = @eagle_zoom[:v1] + @eagle_zoom[:vd] * EAGLE.map_zoom_ease(r)
      @eagle_zoom[:v] = v
      @eagle_sprite_zoom.zoom_x = @eagle_sprite_zoom.zoom_y = v / 100.0
      if @eagle_zoom[:c] == @eagle_zoom[:t]
        @eagle_zoom[:c] = nil
        @eagle_sprite_zoom.visible = false if @eagle_zoom[:v_des] == 100
      end
    end
    if @eagle_zoom[:v] > 100
      _x, _y = check_zoom_center
      if _x > Graphics.width ||_x < 0 || _y > Graphics.height || _y < 0
        $game_map.zoom = 100
        $game_map.zoom_center = nil
      end
      s = @eagle_sprite_zoom
      s.x = s.ox = _x
      s.y = s.oy = _y
      s.bitmap.dispose if s.bitmap
      s.bitmap = SceneManager.snapshot_custom(get_snap_objs)
    end
  end
  #--------------------------------------------------------------------------
  # ● 处理放大中心点
  #--------------------------------------------------------------------------
  def check_zoom_center
    v = $game_map.zoom_center
    if v.is_a?(Array)
      _x = (v[0].to_i - $game_map.display_x) * 32 + 16
      _y = (v[1].to_i - $game_map.display_y) * 32 + 16
      return _x, _y
    end
    case v
    when -1, nil
      _x = Graphics.width / 2
      _y = Graphics.height / 2
    when 0
      e = $game_player
      _x = e.screen_x
      _y = e.screen_y
    else
      e = $game_map.events[v] rescue $game_player
      _x = e.screen_x
      _y = e.screen_y
    end
    return _x, _y
  end
  #--------------------------------------------------------------------------
  # ● 获取放大时应被截图的内容
  #--------------------------------------------------------------------------
  def get_snap_objs
    [@viewport1]
  end
end
