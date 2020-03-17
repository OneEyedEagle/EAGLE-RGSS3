#==============================================================================
# ■ 事件自主移动扩展 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
$imported ||= {}
$imported["EAGLE-EventSelfMoveEX"] = true
#=============================================================================
# - 2020.3.15.23
#=============================================================================
# - 本插件对事件的自主移动模式进行了扩展
#-----------------------------------------------------------------------------
# - 为指定事件应用（指定地图的、指定事件的、指定页的）自主移动模式
#
#     event.set_move_type(map_id, event_id, page_id)
#
#   其中 event 为 Game_Event 类的实例
#   （可利用 $game_map.events[id] 获取当前地图的id号事件实例）
#
#   若 map_id 传入 0，则取当前地图的ID
#   其中 page_id 与编辑器中所显示的事件页编号一致
#
# - 假设要把 4 号地图的 2 号事件的第 3 页的自主移动模式应用到当前地图的 6 号事件上
#     → $game_map.events[6].set_move_type(4, 2, 3)
#
# - 在设置事件的自主移动路线时，由于当前执行域为 Game_CharacterBase，
#   因此可以在 移动路线-脚本 中写 set_move_type(map_id, event_id, page_id)
#   来直接覆盖当前的自主移动模式
#
# -【注意】
#   ·此为临时设置，不存储，不影响编辑器中事件数据
#   ·若当前激活的事件页发生切换，则应用新事件页的自主移动
#-----------------------------------------------------------------------------
# - 为指定事件应用预设的自主移动模式
#
#     event.set_move_type(move_type_sym)
#
#   其中 move_type_sym 为 MOVE_TYPES 常量中设置的唯一标识符
#
# - 本质依然为拷贝指定地图指定事件指定事件页的自主移动模式
#-----------------------------------------------------------------------------
# - 重置指定事件的自主移动模式
#
#     event.reset_move_type
#
#   可将指定事件的自主移动模式重置为编辑器中预设
#=============================================================================
module MOVE_TYPE_EX
  #--------------------------------------------------------------------------
  # ●【设置】预设移动模式标识符及其数据来源
  #--------------------------------------------------------------------------
  MOVE_TYPES = {
    # Symbol => [map_id, event_id, page_id],
    :move_1 => [2, 3, 1],
  }
  #--------------------------------------------------------------------------
  # ● 读取移动路线所在的事件页
  #--------------------------------------------------------------------------
  def self.get_page(move_type)
    params = move_type
    params = MOVE_TYPES[move_type] if MOVE_TYPES.has_key?(move_type)
    map_id = params[0]
    map_id = $game_map.map_id if map_id == 0
    map = EAGLE.cache_load_map(map_id)
    event = map.events[params[1]]
    return nil if event.nil?
    return event.pages[params[2]-1]
  end
end
#=============================================================================
# ○ EAGLE - Cache
#=============================================================================
module EAGLE
  #--------------------------------------------------------------------------
  # ● 读取地图
  #--------------------------------------------------------------------------
  def self.cache_load_map(map_id)
    @cache_map ||= {}
    return @cache_map[map_id] if @cache_map[map_id]
    @cache_map[map_id] = load_data(sprintf("Data/Map%03d.rvdata2", map_id))
    @cache_map[map_id]
  end
  #--------------------------------------------------------------------------
  # ● 清空缓存
  #--------------------------------------------------------------------------
  def self.cache_clear
    @cache_map ||= {}
    @cache_map.clear
    GC.start
  end
end
#=============================================================================
# ■ Game_Event
#=============================================================================
class Game_Event < Game_Character
  #--------------------------------------------------------------------------
  # ● 设置事件页的设置
  #--------------------------------------------------------------------------
  alias eagle_move_type_ex_setup_page_settings setup_page_settings
  def setup_page_settings
    eagle_move_type_ex_setup_page_settings
    @eagle_origin_move_type = @page.move_type
    @eagle_origin_move_speed = @page.move_speed
    @eagle_origin_move_frequency = @page.move_frequency
    @eagle_origin_move_route = @page.move_route
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）自主移动的更新
  #--------------------------------------------------------------------------
  def update_self_movement
    return if !near_the_screen?
    return if @stop_count <= stop_count_threshold
    case @move_type
    when 0; return
    when 1; move_type_random
    when 2; move_type_toward_player
    when 3; move_type_custom
    else;   move_type_eagle_ex
    end
  end
  #--------------------------------------------------------------------------
  # ● 自主移动模式扩展
  #--------------------------------------------------------------------------
  def move_type_eagle_ex
    page = MOVE_TYPE_EX.get_page(@move_type)
    return if page.nil?
    @move_type          = page.move_type
    @move_speed         = page.move_speed
    @move_frequency     = page.move_frequency
    @move_route         = page.move_route
    @move_route_index   = 0
    @move_route_forcing = false
  end
  #--------------------------------------------------------------------------
  # ● 设置自主移动模式
  #--------------------------------------------------------------------------
  def set_move_type(*move_type)
    move_type = move_type[0] if move_type.size == 1
    @move_type = move_type
  end
  #--------------------------------------------------------------------------
  # ● 重置自主移动模式
  #--------------------------------------------------------------------------
  def reset_move_type
    return if @eagle_origin_move_type.nil?
    @move_type          = @eagle_origin_move_type
    @move_speed         = @eagle_origin_move_speed
    @move_frequency     = @eagle_origin_move_frequency
    @move_route         = @eagle_origin_move_route
    @move_route_index   = 0
    @move_route_forcing = false
  end
end
