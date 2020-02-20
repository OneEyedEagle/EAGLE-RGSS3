#==============================================================================
# ■ 事件拷贝 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
$imported ||= {}
$imported["EAGLE-EventCopy"] = true
#=============================================================================
# - 2020.2.20.22
#=============================================================================
# - 原始插件：Yanfly Engine Ace - Spawn Event
# - 本插件新增了拷贝事件的方法
#-----------------------------------------------------------------------------
# - 从指定地图将指定事件拷贝到当前地图
#
#     new_id = $game_map.copy_event(map_id, event_id, x, y)
#
#   传入参数：
#      map_id 为原始地图的id，若传入 0 则为当前地图
#      event_id 为原始事件的id
#      (x, y) 为拷贝后的事件的初始位置
#   返回值：
#      new_id 为拷贝后的事件的新ID
#
# - 示例：
#      $game_map.copy_event(0, 3, 2, 2)
#         → 将当前地图的3号事件拷贝一份，并放置到(2,2)
#      id = $game_map.copy_event(1, 6, 12, 5)
#         → 将1号地图的6号事件拷贝一份，并放置到(12,5)，
#            它在当前地图的ID为 id
#
# - 注意：
#     本插件只临时增加新事件，并不会将其保存在数据库/存档内；
#     在重新读取地图时，将不会复原全部因拷贝而产生的事件。
#=============================================================================

class Game_Map
  #--------------------------------------------------------------------------
  # ● 设置
  #--------------------------------------------------------------------------
  alias eagle_copy_event_setup setup
  def setup(map_id)
    eagle_copy_event_setup(map_id)
    @events_tmp = {} # 存储临时新增的事件id => 事件
  end
  #--------------------------------------------------------------------------
  # ● 更新事件
  #--------------------------------------------------------------------------
  alias eagle_copy_event_update_events update_events
  def update_events
    eagle_copy_event_update_events
    update_copy_events if !@events_tmp.empty?
  end
  #--------------------------------------------------------------------------
  # ● 预定拷贝事件
  #--------------------------------------------------------------------------
  def copy_event(map_id, event_id, x, y)
    map_id = @map_id if map_id == 0
    map = load_data(sprintf("Data/Map%03d.rvdata2", map_id))
    event = map.events[event_id] rescue return
    id = @events.keys.max
    id = [id, @events_tmp.keys.max] if !@events_tmp.empty?
    id += 1
    cloned_event = Marshal.load(Marshal.dump(event))
	  cloned_event.id = id
    @events_tmp[id] = Game_Event.new(@map_id, cloned_event)
    @events_tmp[id].moveto(x, y)
    id
  end
  #--------------------------------------------------------------------------
  # ● 更新拷贝事件
  #--------------------------------------------------------------------------
  def update_copy_events
    keys = @events_tmp.keys
    @events.merge!(@events_tmp)
    @events_tmp.clear
    keys.each { |id| @events[id].update }
    SceneManager.scene.spriteset.refresh_characters
  end
end
