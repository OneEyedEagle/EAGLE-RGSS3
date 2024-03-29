#==============================================================================
# ■ 事件拷贝 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
#==============================================================================
$imported ||= {}
$imported["EAGLE-EventCopy"] = "1.2.5"
#=============================================================================
# - 2023.9.13.20 新增一次性消除全部拷贝事件的快捷指令
#=============================================================================
# - 原始创意：Yanfly Engine Ace - Spawn Event
# - 本插件新增了拷贝事件的方法
#-----------------------------------------------------------------------------
# 【兼容VX】
#-----------------------------------------------------------------------------
MODE_VX = RUBY_VERSION[0..2] == "1.8"
#-----------------------------------------------------------------------------
# 【使用方法 - 事件注释】
#
# - 在 事件指令-注释 中，如下格式编写来拷贝一个事件：
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
# - 利用全局脚本（事件脚本）从指定地图将指定事件拷贝到当前地图：
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
#    来保存当前地图的拷贝事件，下一次返回该地图时，将全部复原
#
#   每一次切换地图时，该功能将重置为关闭，即不复原新地图的拷贝事件，
#    如果想继续使新地图里的拷贝事件也能在下一次复原，请再次调用该脚本
#
# - 或者可以通过打开 S_ID_COPY_SAVE 号开关，来长时间启用这个 保存-复原 的状态
#    当开关开启时，将默认保存拷贝事件，不用再反复调用上一条脚本
#
# - 这个功能只会保存拷贝动作信息，临时变量 tmp 的值不会被保存
#   下一次回到该地图时，本质依然是从原始地图拷贝到保存的位置
#
#-----------------------------------------------------------------------------
# 【拷贝事件的回收】
#
# - 若某个拷贝事件已经不再需要，可选择立即将其回收，在下一次事件拷贝时重复使用：
#
#  1. 利用 事件脚本 回收当前拷贝事件（同时会暂时消除）
#
#       copy_finish
#
#  2. 利用 全局脚本 回收指定拷贝事件（同时会暂时消除）
#     其中 event 为之前生成拷贝事件时的返回值
#
#       event.copy_finish
#
# - 如果不进行回收，则调用了暂时消除指令的拷贝事件同样会被复用，无须担心浪费
#
#-----------------------------------------------------------------------------
# 【拷贝事件的批量操作】
#
# - 因为拷贝事件无法在事件编辑器中获得，因此添加下述指令，方便进行批量操作：
#
#  1. 利用 全局脚本 获取全部同一来源的拷贝事件
#
#    es = $game_map.get_copy_events(omid, oeid)
#
#     其中 omid 为来源地图的id，若传入 0 则为当前地图
#          oeid 为来源事件的id
#     返回 es 为 Game_Event 的数组，其中每个都是从指定事件生成的拷贝事件
#
#  2. 利用 全局脚本 清除回收由指定事件生成的全部拷贝事件
#
#    $game_map.erase_copy_events(omid, oeid)
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
#=============================================================================
# - 特别感谢：葱兔
#=============================================================================

module EAGLE
  #--------------------------------------------------------------------------
  # ○【常量】当该序号开关开启时，将复原上一次离开地图时的全部拷贝事件
  #--------------------------------------------------------------------------
  S_ID_COPY_SAVE = 0

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
    return if @events.nil?
    @@copy_log[@map_id] ||= {}
    a = []
    @events.each do |i, e|
      # [origin_mid, origin_eid, x, y, id]
      a.push([e.copy_origin[0],e.copy_origin[1], e.x, e.y, e.id]) if e.flag_copy
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
    if @@copy_log[map_id][:flag] || $game_switches[EAGLE::S_ID_COPY_SAVE]
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
    # 对于不指定ID的，寻找一个已经使用完毕的拷贝的事件
    if id_want == nil && !@events_copy[map_id][event_id].empty?
      id = @events_copy[map_id][event_id].shift
      # 直接重置并返回使用
      @events[id].copy_reset(id, x, y)
      @events[id].id_want_copy = nil
      return @events[id]
    end
    # 从原始地图中获取原始事件
    map = get_map_data(map_id)
    event = map.events[event_id] rescue return
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
    @events_tmp[id].id_want_copy = id_want
    @events_tmp[id].copy_origin = [map_id, event_id]
    @events_tmp[id].moveto(x, y)
    @events_tmp[id]
  end
  #--------------------------------------------------------------------------
  # ● 更新拷贝事件
  #--------------------------------------------------------------------------
  def update_copy_events
    @events_tmp.each { |id, e| e.update }
    s = get_cur_scene
    return if !s.respond_to?(:spriteset)
    s.spriteset.add_characters_tmp
    @events.merge!(@events_tmp)
    @events_tmp.clear
    $game_map.need_refresh = true
  end
  #--------------------------------------------------------------------------
  # ● 将已经完成的拷贝事件存入备份池
  #--------------------------------------------------------------------------
  def restore_copy_event(id)
    e = @events[id]
    return if e.flag_copy == nil
    @events_copy[e.copy_origin[0]][e.copy_origin[1]].push(id)
    e.flag_copy = nil  # 回收了，等待下一次使用，不会被清理
  end
  #--------------------------------------------------------------------------
  # ● 获取地图数据
  #--------------------------------------------------------------------------
  def get_map_data(map_id)
    return load_data(sprintf("Data/Map%03d.rvdata", map_id)) if MODE_VX
    EAGLE.cache_load_map(map_id)
  end
  #--------------------------------------------------------------------------
  # ● 获取当前场景
  #--------------------------------------------------------------------------
  def get_cur_scene
    return $scene if MODE_VX
    SceneManager.scene
  end
  #--------------------------------------------------------------------------
  # ● 批量操作拷贝事件
  #--------------------------------------------------------------------------
  def get_copy_events(omid, oeid)
    omid = @map_id if omid == 0
    return @events.values.select do |e|
      e.flag_copy == true && e.copy_origin[0] == omid && e.copy_origin[1] == oeid
    end
  end
  #--------------------------------------------------------------------------
  # ● 批量清除拷贝事件
  #--------------------------------------------------------------------------
  def erase_copy_events(omid, oeid)
    es = get_copy_events(omid, oeid)
    es.each { |e| e.copy_finish }
  end
end
#=============================================================================
# ○ Game_Event
#=============================================================================
class Game_Event < Game_Character
  attr_reader    :event
  attr_reader    :tmp
  attr_accessor  :flag_copy, :id_want_copy
  attr_accessor  :copy_origin # [原始地图id, 原始事件id]
  if MODE_VX  # 为 VX 新增初始化方法，方便对拷贝事件初始化
    attr_accessor :opacity
    #--------------------------------------------------------------------------
    # ● 初始化对像
    #     map_id : 地图 ID
    #     event  : 事件 (RPG::Event)
    #--------------------------------------------------------------------------
    alias eagle_event_copy_init initialize
    def initialize(map_id, event)
      init_public_members
      eagle_event_copy_init(map_id, event)
    end
    #--------------------------------------------------------------------------
    # ● 初始化公有成员变量
    #--------------------------------------------------------------------------
    def init_public_members # 确保拷贝事件能正常初始化
      @opacity = 255
      @blend_type = 0
      @transparent = false
      @erased = false
      @starting = false
    end
    #--------------------------------------------------------------------------
    # ● 初始化私有成员变量
    #--------------------------------------------------------------------------
    def init_private_members
      setup(nil)
    end
  end  # end of MODE_VX
  #--------------------------------------------------------------------------
  # ● 初始化公有成员变量
  #--------------------------------------------------------------------------
  alias eagle_copy_event_init_public_members init_public_members
  def init_public_members
    eagle_copy_event_init_public_members
    @flag_copy = nil   # nil 代表非拷贝事件，true 代表正在使用，false 代表使用完毕
    @id_want_copy = nil  # 如果拷贝时指定了ID，则需要赋值
    @tmp = {}
  end
  #--------------------------------------------------------------------------
  # ● 回收拷贝事件
  #--------------------------------------------------------------------------
  def copy_finish
    $game_map.restore_copy_event(@id)
    erase
  end
  #--------------------------------------------------------------------------
  # ● 暂时消除
  #--------------------------------------------------------------------------
  alias eagle_copy_event_erase erase
  def erase
    eagle_copy_event_erase
    @flag_copy = false if @flag_copy
  end
  #--------------------------------------------------------------------------
  # ● 重置拷贝事件
  #--------------------------------------------------------------------------
  def copy_reset(id, x, y)
    init_public_members
    init_private_members
    @id = id
    @flag_copy = true # 若为copy的事件，置为true
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
      if event.id_want_copy  # 指定了ID的拷贝事件，检查是否已经有精灵存在
        s = nil
        @character_sprites.each do |a|
          c = a.character
          break s = a if c.is_a?(Game_Event) && c.id == event.id
        end
        next s.rebind_character(event) if s
      end
      # 找找有没有使用完的拷贝事件的精灵
      s = nil
      @character_sprites.each do |a|
        c = a.character
        break s = a if c.is_a?(Game_Event) && c.flag_copy == false
      end
      if s
        # 可以删除 game_map 中用完的拷贝事件数据了
        $game_map.events.delete(s.character.id)
        next s.rebind_character(event)
      end
      # 需要新增拷贝事件的精灵
      s = Sprite_Character.new(@viewport1, event)
      @character_sprites.push(s)
    end
  end
end
#=============================================================================
# ○ Scene_Map
#=============================================================================
class Scene_Map; attr_reader :spriteset; end

#===============================================================================
# ○ Game_Interpreter
#===============================================================================
class Game_Interpreter
if MODE_VX  # 为VX增加注释指令
  #--------------------------------------------------------------------------
  # ● 事件命令执行
  #--------------------------------------------------------------------------
  alias eagle_copy_event_execute_command execute_command
  def execute_command
    f = eagle_copy_event_execute_command
    return false if !f  # 如果返回的是false，则需要等待，下一帧再继续判定
    return true if @list == nil
    command_108 if @list[@index].code == 108
    return true 
  end
  #--------------------------------------------------------------------------
  # ● 添加注释
  #--------------------------------------------------------------------------
  def command_108
    @comments = @list[@index].parameters
  end
end
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
  #--------------------------------------------------------------------------
  # ● 判定当前地图是否和事件启动时的地图相同
  #--------------------------------------------------------------------------
  def same_map?
    @map_id == $game_map.map_id
  end
  #--------------------------------------------------------------------------
  # ● 回收事件
  #--------------------------------------------------------------------------
  def copy_finish
    if same_map? && @event_id > 0
      e = $game_map.events[@event_id]
      e.copy_finish
    end
  end
end
