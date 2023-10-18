#==============================================================================
# ■ 地图卷动-缓动VX by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【组件-缓动函数 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-VX-MapEaseScroll"] = "1.0.1"
#==============================================================================
# - 2023.10.18.2 兼容 Map Effects v1.4.1 for VX and VXace by Zeus81
#==============================================================================
# - 本插件新增了地图中使用的缓动版地图卷动
#-----------------------------------------------------------------------------
# 【使用】
#
#   利用 全局脚本 调用缓动版地图卷动（不包含等待）：
#
#   $game_map.eagle_start_scroll(x, y, t, type)
#
#     其中 x y 为卷动后的画面中心位置（地图坐标）
#       （注：显示的范围不会超过地图大小）
#
#     其中 t 为卷动耗时帧数（1秒等于60帧）
#
#     其中 type 为缓动函数名称（字符串）
#       （具体见【组件-缓动函数 by老鹰】中的“方法调用（字符串）”部分）
#
# 【示例】
#
#    $game_map.eagle_start_scroll(15, 14)
#
#      → 正弦缓动，60帧内，卷动到地图（15,14）为中心的位置
#
#    $game_map.eagle_start_scroll(0, 0, 120)
#
#      → 正弦缓动，120帧内，卷动到地图（0,0）为中心的位置
#         但由于(0,0)为中心时，地图左上角将超出范围，因此将修正为 (8,6) 为中心
#
#    $game_map.eagle_start_scroll(5, 10, 60, "easeInCubic")
#
#      → 立方缓动，60帧内，卷动到地图（5,10）为中心的位置
#
#==============================================================================

class Game_Map
  #--------------------------------------------------------------------------
  # ● 更新卷动
  #--------------------------------------------------------------------------
  alias eagle_ease_update_scroll update_scroll
  def update_scroll
    return eagle_update_scroll if @eagle_scroll != nil
    eagle_ease_update_scroll
  end
  #--------------------------------------------------------------------------
  # ● 开始卷动
  #--------------------------------------------------------------------------
  def eagle_start_scroll(map_x, map_y, t=60, type="easeInSine")
    @eagle_scroll = {}
    @eagle_scroll["x1"] = @display_x / 256.0
    @eagle_scroll["y1"] = @display_y / 256.0
    @eagle_scroll["x2"] = map_x - Game_Player::CENTER_X / 256.0
    @eagle_scroll["y2"] = map_y - Game_Player::CENTER_Y / 256.0
    @eagle_scroll["xd"] = @eagle_scroll["x2"] - @eagle_scroll["x1"]
    @eagle_scroll["yd"] = @eagle_scroll["y2"] - @eagle_scroll["y1"]
    @eagle_scroll["t"] = t
    @eagle_scroll["c"] = 0
    @eagle_scroll["type"] = type
  end
  #--------------------------------------------------------------------------
  # ● 更新卷动
  #--------------------------------------------------------------------------
  def eagle_update_scroll
    return @eagle_scroll = nil if @eagle_scroll["c"] > @eagle_scroll["t"]
    t = @eagle_scroll["c"] * 1.0 / @eagle_scroll["t"]
    v = EasingFuction.call(@eagle_scroll["type"], t)
    @eagle_scroll["c"] += 1
    @display_x = @eagle_scroll["x1"] + @eagle_scroll["xd"] * v
    @display_y = @eagle_scroll["y1"] + @eagle_scroll["yd"] * v
    
    @display_x = @display_x * 256
    @display_y = @display_y * 256

    if $imported[:Zeus_Map_Effects]
      @display_x = limit_x(@display_x)
      @display_y = limit_y(@display_y)
      return 
    end
  
    @display_x = [@display_x, 0].max
    @display_y = [@display_y, 0].max
    @display_x = [@display_x, (width - screen_tile_x) * 256].min
    @display_y = [@display_y, (height - screen_tile_y) * 256].min
  end
  #--------------------------------------------------------------------------
  # ● 画面的横向图块数
  #--------------------------------------------------------------------------
  def screen_tile_x
    Graphics.width / 32
  end
  #--------------------------------------------------------------------------
  # ● 画面的纵向图块数
  #--------------------------------------------------------------------------
  def screen_tile_y
    Graphics.height / 32
  end
end
