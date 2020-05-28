#==============================================================================
# ■ 事件拷贝 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
$imported ||= {}
$imported["EAGLE-EventCopy"] = true
#=============================================================================
# - 2020.5.28.21 优化
#=============================================================================
# - 原始创意：Yanfly Engine Ace - Spawn Event
# - 本插件新增了拷贝事件的方法
#-----------------------------------------------------------------------------
# - 从指定地图将指定事件拷贝到当前地图
#
#     event = $game_map.copy_event(map_id, event_id, x, y)
#
#   传入参数：
#      map_id 为原始地图的id，若传入 0 则为当前地图
#      event_id 为原始事件的id
#      (x, y) 为拷贝后的事件的初始位置
#   返回值：
#      event 为拷贝后的事件（Game_Event实例）（若拷贝失败，则为nil）
#
# - 示例：
#      $game_map.copy_event(0, 3, 2, 2)
#         → 将当前地图的3号事件拷贝一份，并放置到(2,2)
#      event = $game_map.copy_event(1, 6, 12, 5)
#         → 将1号地图的6号事件拷贝一份，并放置到(12,5)，
#            它在当前地图的实例为 event
#
# - 注意：
#    ·本插件只临时增加新事件，并不会将其保存在数据库/存档内；
#       在重新读取地图时，将不会复原全部因拷贝而产生的事件。
#    ·由于拷贝事件的ID是动态增加的，因此推荐不要在事件内部使用独立开关，
#       独立开关是全局存储，且只与地图ID/事件ID/开关名称相关，易发生冲突
#-----------------------------------------------------------------------------
# - 事件的临时变量
#   为Game_Event类新增了可以存储临时数据的Hash变量 event.tmp
#     ·获取事件的临时变量 key 的值
#        event.tmp[key]
#     ·设置事件的临时变量 key 的值
#        event.tmp[key] = value
# - 注意：
#    ·该临时变量在重新读取地图后将被丢弃
#    ·可结合【事件页触发条件扩展 by老鹰】为拷贝事件设置触发条件
#-----------------------------------------------------------------------------
# - 回收拷贝事件（节约空间并减少精灵）
#
#     event.copy_finish
#
#   若拷贝事件已经不再需要，调用该方法将其回收，以用于下一次同事件的复制
#=============================================================================

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
# ○ Game_Map
#=============================================================================
class Game_Map
  attr_reader  :events_tmp
  #--------------------------------------------------------------------------
  # ● 设置
  #--------------------------------------------------------------------------
  alias eagle_copy_event_setup setup
  def setup(map_id)
    eagle_copy_event_setup(map_id)
    @events_tmp = {} # 临时新增的事件id => 事件
    @events_copy = {} # 原始事件所在地图id, 原始事件id => 拷贝事件id的数组
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
    @events_copy[map_id] ||= {}
    @events_copy[map_id][event_id] ||= []
    if !@events_copy[map_id][event_id].empty?
      id = nil
      @events_copy[map_id][event_id].each do |eid|
        break id = eid if @events[eid].flag_copy_restore
      end
      if id
        @events[id].copy_reset(x, y)
        return @events[id]
      end
      id = @events_copy[map_id][event_id][0]
      event = @events[id].event.dup
    else
      map = get_map_data(map_id)
      event = map.events[event_id] rescue return
    end
    id = @events.keys.max
    id = [id, @events_tmp.keys.max].max if !@events_tmp.empty?
    id = [id, 100].max # 直接增大事件ID，尽可能确保不产生冲突
    id += 1
    cloned_event = Marshal.load(Marshal.dump(event))
	  cloned_event.id = id
    @events_tmp[id] = Game_Event.new(@map_id, cloned_event)
    @events_tmp[id].flag_copy = true
    @events_tmp[id].copy_origin = [map_id, event_id]
    @events_tmp[id].moveto(x, y)
    @events_tmp[id]
  end
  #--------------------------------------------------------------------------
  # ● 更新拷贝事件
  #--------------------------------------------------------------------------
  def update_copy_events
    @events_tmp.each do |id, e|
      e.update
      @events_copy[e.copy_origin[0]][e.copy_origin[1]].push(id)
    end
    s = get_cur_scene
    return if !s.respond_to?(:spriteset)
    s.spriteset.add_characters_tmp
    @events.merge!(@events_tmp)
    @events_tmp.clear
  end
  #--------------------------------------------------------------------------
  # ● 获取地图数据
  #--------------------------------------------------------------------------
  def get_map_data(map_id)
    EAGLE.cache_load_map(map_id)
  end
  #--------------------------------------------------------------------------
  # ● 获取当前场景
  #--------------------------------------------------------------------------
  def get_cur_scene
    SceneManager.scene
  end
end
#=============================================================================
# ○ Game_Event
#=============================================================================
class Game_Event < Game_Character
  attr_reader    :event
  attr_reader    :tmp
  attr_accessor  :flag_copy, :flag_copy_restore
  attr_accessor  :copy_origin # [原始地图id, 原始事件id]
  #--------------------------------------------------------------------------
  # ● 初始化公有成员变量
  #--------------------------------------------------------------------------
  alias eagle_copy_event_init_public_members init_public_members
  def init_public_members
    eagle_copy_event_init_public_members
    @flag_copy = false
    @tmp = {}
  end
  #--------------------------------------------------------------------------
  # ● 回收拷贝事件
  #--------------------------------------------------------------------------
  def copy_finish
    return if @flag_copy.nil?
    @flag_copy_restore = true
  end
  #--------------------------------------------------------------------------
  # ● 重置拷贝事件
  #--------------------------------------------------------------------------
  def copy_reset(x, y)
    init_public_members
    init_private_members
    @flag_copy = true # 若为copy的事件，置为true
    @flag_copy_restore = false # 若copy事件已经可以回收，置为true
    moveto(x, y)
    refresh
  end
end
#=============================================================================
# ○ Spriteset_Map
#=============================================================================
class Spriteset_Map
  #--------------------------------------------------------------------------
  # ● 新增拷贝事件
  #--------------------------------------------------------------------------
  def add_characters_tmp
    $game_map.events_tmp.values.each do |event|
      @character_sprites.push(Sprite_Character.new(@viewport1, event))
    end
  end
end
#=============================================================================
# ○ Scene_Map
#=============================================================================
class Scene_Map; attr_reader :spriteset; end
