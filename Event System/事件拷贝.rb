#==============================================================================
# ■ 事件拷贝 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
$imported ||= {}
$imported["EAGLE-EventCopy"] = true
#=============================================================================
# - 2022.1.15.18 新增临时保存
#=============================================================================
# - 原始创意：Yanfly Engine Ace - Spawn Event
# - 本插件新增了拷贝事件的方法
#-----------------------------------------------------------------------------
# 【兼容VX】
#-----------------------------------------------------------------------------
MODE_VX = false # 如果要在RPG Maker VX中使用，请修改为 true
#-----------------------------------------------------------------------------
# 【使用方法 - 事件注释】
#
# - 在 事件指令-注释 中，如下格式编写来解锁指定任务：
#  （具体形式可以通过修改 COMMENT_EVENT_COPY 这个正则表达式来改变。）
#
#     事件拷贝|来源地图ID,来源事件ID|拷贝后x坐标,拷贝后y坐标,拷贝后事件ID
#
#   其中 事件拷贝 为固定的识别文本，需要位于行首，前面不可有其它文本或空格。
#
#   其中 来源地图ID 和 来源事件ID 为原始事件的所在地图ID及其事件ID。
#
#   其中 拷贝后x坐标 和 拷贝后y坐标 为生成的拷贝事件在当前地图的坐标。
#
#   其中 拷贝后事件ID 为生成的拷贝事件的ID，若不写则自动分配，保证不与现有事件冲突。
#
#   这些ID均可以使用Ruby脚本，只要其中不重复出现英语逗号和 | 符号
#     可以用 s 代表开关组，v 代表变量组，es 代表当前地图的事件组，e 代表当前事件
#
# - 示例：
#
#      事件拷贝|0, 3|2, 2
#         → 将当前地图的3号事件拷贝一份，并放置到(2,2)
#
#      事件拷贝|1, 6|12, 5, 1
#         → 将1号地图的6号事件拷贝一份，并放置到(12,5)，ID为1（覆盖原ID为1的事件）
#
#      事件拷贝|0, v[1]|$game_player.x, $game_player.y
#         → 将当前地图的1号变量值为ID的事件拷贝一份，放置到玩家所在位置
#
#-----------------------------------------------------------------------------
# 【使用方法 - 全局脚本】
#
# - 利用全局脚本（事件脚本）从指定地图将指定事件拷贝到当前地图
#
#     event = $game_map.copy_event(map_id, event_id, x, y[,id])
#
#   传入参数解释：
#      map_id   为来源地图的id，若传入 0 则为当前地图
#      event_id 为来源事件的id
#      (x, y)   为拷贝后的事件的初始放置位置，编辑器中的地图坐标
#      id 【可选】为拷贝后的事件的新ID，若传入，则会覆盖当前地图已存在的同ID事件，
#         若不传入，则为当前地图最大事件ID+100后的次序编号，确保不覆盖现有事件
#
#   返回值解释：
#      event 为拷贝后的事件（Game_Event实例）（若拷贝失败，则为nil）
#
# 【示例】
#
#      $game_map.copy_event(0, 3, 2, 2)
#         → 将当前地图的3号事件拷贝一份，并放置到(2,2)
#
#      event = $game_map.copy_event(1, 6, 12, 5, 1)
#         → 将1号地图的6号事件拷贝一份，并放置到(12,5)，
#            它在当前地图的实例为 event，ID为1（覆盖原ID为1的事件）
#
# 【注意】
#
#   ·当未指定拷贝后的事件ID时，拷贝事件的ID是动态增加的，
#     因此推荐不要在事件内部使用独立开关，
#     独立开关是全局存储，且只与地图ID/事件ID/开关名称相关，易发生冲突
#
#-----------------------------------------------------------------------------
# 【拷贝事件的保存】
#
# - 在任意地方（事件脚本、全局脚本）调用 $game_map.save_copy
#    来保存当前地图的拷贝事件，至下一次返回该地图时
#
# - 每一次切换地图时，该开关默认置为关闭，即不复原上一次的拷贝事件，
#    如果想继续使当前地图也能复原拷贝事件，请再次调用
#
# - 只保存基本信息，下一次读取时，本质依然是从原始地图拷贝一份到保存的位置
#
#-----------------------------------------------------------------------------
# 【事件的临时变量】
#
# - 本插件为Game_Event类新增了可以存储临时数据的Hash变量：event.tmp
#
#   ·获取事件的临时变量 key 的值
#      event.tmp[key]
#
#   ·设置事件的临时变量 key 的值
#      event.tmp[key] = value
#
# 【注意】
#
#   ·该临时变量在重新读取地图后将被丢弃
#
#   ·可结合【事件页触发条件扩展 by老鹰】为拷贝事件设置触发条件
#
#-----------------------------------------------------------------------------
# 【回收】
#
# - 若拷贝事件已经不再需要，可将其回收，用于下一次同事件的复制：
#
#  1. 利用 事件脚本 回收
#
#     event.copy_finish
#
#  2. 利用 事件指令-暂时消除事件 回收
#
#=============================================================================
# - 特别感谢：葱兔
#=============================================================================

module EAGLE
  #--------------------------------------------------------------------------
  # ○【常量】事件指令-注释 中新增/更新任务的文本
  #--------------------------------------------------------------------------
  COMMENT_EVENT_COPY = /^事件拷贝 ?\| *?(.*?) *?\| *?(.*)/i
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
# ○ Game_Map
#=============================================================================
class Game_Map
  attr_reader  :events_tmp
  @@copy_log = {}
  #--------------------------------------------------------------------------
  # ● 设置
  #--------------------------------------------------------------------------
  alias eagle_copy_event_setup setup
  def setup(map_id)
    copy_save_all(map_id)
    eagle_copy_event_setup(map_id)
    @events_tmp = {} # 临时新增的事件id => 事件
    @events_copy = {} # 原始事件所在地图id, 原始事件id => 拷贝事件id的数组
    process_copy_log(map_id)
  end
  #--------------------------------------------------------------------------
  # ● 保存当前地图的全部拷贝事件
  #--------------------------------------------------------------------------
  def copy_save_all(map_id)
    return if map_id == @map_id
    @@copy_log[@map_id] ||= {}
    a = []
    @events.each do |i, e|
      next if e.flag_copy == false
      next if e.flag_copy_restore == true  # 已经
      # [origin_mid, origin_eid, x, y, id]
      a.push([e.copy_origin[0],e.copy_origin[1], e.x, e.y, e.id])
    end
    @@copy_log[@map_id][:data] = a
    @@copy_log[@map_id][:flag] = @flag_save_copy
    @flag_save_copy = false  # 当为 true 时，下一次回到当前地图时，拷贝事件将复原
  end
  #--------------------------------------------------------------------------
  # ● 地图导入前，处理上一次保存的拷贝
  #--------------------------------------------------------------------------
  def process_copy_log(map_id)
    # map_id => { :data => [copy_params], :flag => false  }
    @@copy_log[map_id] ||= {}
    @@copy_log[map_id][:data] ||= []
    @@copy_log[map_id][:flag] = false if @@copy_log[map_id][:flag].nil?
    if @@copy_log[map_id][:flag] == true
      @@copy_log[map_id][:data].each { |a| self.send(:copy_event, *a) }
    end
  end
  #--------------------------------------------------------------------------
  # ●【外部调用】保存当前地图的拷贝事件
  #--------------------------------------------------------------------------
  def save_copy
    @flag_save_copy = true
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
  def copy_event(map_id, event_id, x, y, id_want = nil)
    # 确定原始事件的所在地图
    map_id = @map_id if map_id == 0
    # 初始化
    @events_copy[map_id] ||= {}
    @events_copy[map_id][event_id] ||= []
    # 获取原始事件
    if !@events_copy[map_id][event_id].empty?
      id = nil
      # 寻找一个已经拷贝的，并且使用完毕的事件
      @events_copy[map_id][event_id].each do |eid|
        break id = eid if @events[eid].flag_copy_restore
      end
      if id # 找到一个空闲的，直接进行重置并返回使用
        @events[id].copy_reset(id, x, y)
        return @events[id]
      end
      # 没找到，依据已经复制的事件进行再次的复制与生成
      id = @events_copy[map_id][event_id][0]
      event = @events[id].event.dup
    else
      # 从原始地图中拷贝
      map = get_map_data(map_id)
      event = map.events[event_id] rescue return
    end
    # 获取拷贝后的ID
    if id_want
      id = id_want
    else
      id = @events.keys.max
      id = [id, @events_tmp.keys.max].max if !@events_tmp.empty?
      id = [id, 100].max # 直接增大事件ID，尽可能确保不产生冲突
      id += 1
    end
    # 实际生成一个事件
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
      @events_copy[e.copy_origin[0]][e.copy_origin[1]].push(id) if e.flag_copy
    end
    s = get_cur_scene
    return if !s.respond_to?(:spriteset)
    s.spriteset.add_characters_tmp
    @events.merge!(@events_tmp)
    @events_tmp.clear
    $game_map.need_refresh = true
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
  if MODE_VX
    def init_public_members; end
  end
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
    erase
  end
  #--------------------------------------------------------------------------
  # ● 暂时消除
  #--------------------------------------------------------------------------
  alias eagle_copy_event_erase erase
  def erase
    eagle_copy_event_erase
    return if !@flag_copy
    @flag_copy_restore = true
  end
  #--------------------------------------------------------------------------
  # ● 重置拷贝事件
  #--------------------------------------------------------------------------
  def copy_reset(id, x, y)
    init_public_members
    init_private_members
    @id = id
    @flag_copy = true # 若为copy的事件，置为true
    @flag_copy_restore = false # 若copy事件已经可以回收，置为true
    moveto(x, y)
    refresh
  end
end
#=============================================================================
# ○ Sprite_Character
#=============================================================================
class Sprite_Character < Sprite_Base
  #--------------------------------------------------------------------------
  # ● 绑定character
  #--------------------------------------------------------------------------
  def rebind_character(character)
    @character = character
    @balloon_duration = 0
    update
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
      if event.flag_copy == false  # 指定了ID的拷贝事件，检查是否已经有精灵存在
        s = nil
        @character_sprites.each do |a|
          s = a if a.character.is_a?(Game_Event) && a.character.id == event.id
        end
        next s.rebind_character(event) if s
      end
      # 需要新增的拷贝事件的精灵
      s = Sprite_Character.new(@viewport1, event)
      @character_sprites.push(s)
    end
  end
end
#=============================================================================
# ○ Scene_Map
#=============================================================================
class Scene_Map; attr_reader :spriteset; end

#=============================================================================
# ○ 兼容VX
#=============================================================================
if MODE_VX
class Game_Map
  #--------------------------------------------------------------------------
  # ● 获取地图数据
  #--------------------------------------------------------------------------
  def get_map_data(map_id)
    load_data(sprintf("Data/Map%03d.rvdata", map_id))
  end
  #--------------------------------------------------------------------------
  # ● 获取当前场景
  #--------------------------------------------------------------------------
  def get_cur_scene
    $scene
  end
end
class Game_Event
  attr_accessor :opacity
  #--------------------------------------------------------------------------
  # ● 初始化对像
  #     map_id : 地图 ID
  #     event  : 事件 (RPG::Event)
  #--------------------------------------------------------------------------
  alias eagle_event_copy_init initialize
  def initialize(map_id, event)
    eagle_event_copy_init(map_id, event)
    init_public_members
  end
  #--------------------------------------------------------------------------
  # ● 初始化变量
  #--------------------------------------------------------------------------
  def init_public_members
    @opacity = 255
    @blend_type = 0
    @transparent = false
    @erased = false
    @starting = false
  end
  def init_private_members
    setup(nil)
  end
end
end

#===============================================================================
# ○ Game_Interpreter
#===============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 添加注释
  #--------------------------------------------------------------------------
  alias eagle_event_copy_command_108 command_108
  def command_108
    eagle_event_copy_command_108
    @comments.each do |t|
      if t =~ EAGLE::COMMENT_EVENT_COPY
        ps1 = $1; ps2 = $2
        ps1 = ps1.split(/,/)
        next if ps1.size != 2
        ps2 = ps2.split(/,/)
        next if ps2.size != 2 and ps2.size != 3
        v = $game_variables; s = $game_switches
        es = $game_map.events; e = $game_map.events[@event_id]
        $game_map.copy_event(eval(ps1[0]).to_i, eval(ps1[1]).to_i,
          eval(ps2[0]).to_i, eval(ps2[1]).to_i, ps2[2] ? eval(ps2[2]).to_i : nil)
      end
    end
  end
end
