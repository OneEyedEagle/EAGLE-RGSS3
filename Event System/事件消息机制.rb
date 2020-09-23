#==============================================================================
# ■ 事件消息机制 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
$imported ||= {}
$imported["EAGLE-EventMsg"] = true
#==============================================================================
# - 2020.9.17.9 扩展 msg? 方法调用
#==============================================================================
# - 本插件新增消息机制，以直接触发事件中的指令
#--------------------------------------------------------------------------
# ○ 地图的事件
#--------------------------------------------------------------------------
# - 对于 Game_Event 对象，新增 msg(LABEL[, cur_page]) 方法，并行调用指定指令序列
#
#    其中 LABEL 为事件中的标签内容的字符串
#               需要与 事件指令-标签 中所写的内容完全一致，包括前后空格
#
#    其中 cur_page 传入 false，则在事件的全部事件页中搜索 LABEL 标签
#                  传入 true，则只在当前激活的事件页中搜索 LABEL 标签
#                  可省略，默认传入 false
#
# 【逻辑】
#    1、在目标事件页（无视事件触发条件）中搜索内容为 LABEL 的标签
#    2、若找到，则继续查找在该标签后的第一个内容为 END 的标签
#    3、立即执行这两个标签中间的事件指令（若未找到 END，则一直执行到事件结尾）
#    4、当成功找到标签时，msg 方法返回 true，否则返回 false
#
# 【示例】
#    当前地图的 1 号事件的第 2 页中指令列表
#    |- 显示文字：测试语句1
#    |- 标签：A
#    |- 显示文字：测试语句2
#    |- 标签：END
#    |- 显示文字：测试语句3
#    |- 标签：B
#    |- 显示文字：测试语句4
#    |- 标签：END
#
#  ·正常执行该事件，将按序显示 测试语句1、测试语句2、测试语句3、测试语句4
#  ·若在另一事件中调用事件脚本 $game_map.events[1].msg("A")，则只显示 测试语句2
#  ·若在另一事件中调用事件脚本 $game_map.events[1].msg("B")，则只显示 测试语句4
#
# 【注意】
#   1、为了保证事件的等待指令有意义，并且不出现明显的操作延时感，
#      若消息未执行完，此时再传入同一消息，将不会重复执行，但依然返回 true
#   2、为了确保并行，当事件在执行消息时，不再执行其 start 方法
#
# 【高级】
#    event.msg?  → 当指定事件存在任意正在执行的消息时，返回true
#    event.msg?(LABEL) → 当指定事件正在执行 LABEL 编号的消息时，返回true
#
#--------------------------------------------------------------------------
# ○ 地图的公共事件
#--------------------------------------------------------------------------
# - 利用脚本调用公共事件中的消息
#
#      $game_map.msg_common(LABLE[, common_event])
#
#    其中 LABEL 同上，与事件中的标签文本完全一致的字符串
#    其中 common_event 传入 0 ，将按序查询全部公共事件，并调用第一组匹配
#                      传入数组，将在数组范围内按序查询公共事件，并调用第一组匹配
#                      传入正整数，将在该ID的公共事件内查询
#                      可省略，默认传入 0
#
#    当成功查找到LABEL时，将返回 true 并立即执行；否则返回 false
#
# 【高级】
#    $game_map.msg?  → 当公共事件存在任意正在执行的消息时，返回true
#
#--------------------------------------------------------------------------
# ○ 战斗的敌群事件
#--------------------------------------------------------------------------
# - 利用脚本调用敌群事件中的消息
#
#      $game_troop.msg(LABEL[, cond_met])
#
#    其中 LABEL 同上，与事件中的标签文本完全一致的字符串
#    其中 cond_met 传入 true 时，将只在满足条件的全部事件页中搜索
#                  传入 false 时，将在全部事件页中搜索
#                  可省略，默认传入 true
#
# 【注意】
#   ·消息指令的执行不受战斗系统的等待影响，
#     因此可能导致消息中的对话覆盖战斗系统的对话
#   （例如：技能释放后调用消息显示文本，而此时敌人全灭，则可能覆盖胜利结算文本）
#
# 【高级】
#    $game_troop.msg?  → 当敌群存在任意正在执行的消息时，返回true
#
#--------------------------------------------------------------------------
# ○ 高级
#--------------------------------------------------------------------------
# - 新增了部分便利的全局方法，用于获取指定对象
#
#    $game_temp.last_menu_item → 获取最近一次在菜单中所使用物品/技能的实例
#
#    $game_map.forward_event_id(chara) → 获取 chara 面前一格事件的ID
#       其中 chara 为 Game_CharacterBase 对象
#       如 $game_player 代表玩家，$game_map.events[id] 代表id号事件
#==============================================================================

module EAGLE
#==============================================================================
# ■ 通用
#==============================================================================
module EVENT_MSG
  #--------------------------------------------------------------------------
  # ● 获取指定LABEL的指令序列
  #--------------------------------------------------------------------------
  def find_label_list(msg_label, lists)
    list_start = false
    eagle_list = []
    lists.each do |list|
      list.each do |command|
        if command.code == 118
          label = command.parameters[0]
          if list_start
            break if label == "END"
          else
            next list_start = true if label == msg_label
          end
        end
        eagle_list.push(command) if list_start
      end
      break if list_start
    end
    return nil if eagle_list.empty?
    eagle_list.push( RPG::EventCommand.new )
    return eagle_list
  end
  #--------------------------------------------------------------------------
  # ● 初始化消息
  #--------------------------------------------------------------------------
  def msg_trigger_init
    @eagle_msg_lists = []
    @interpreter_eagle = Game_Interpreter.new
    @eagle_msg_cur_event_id = 0
    @eagle_msg_cur_label = nil
  end
  #--------------------------------------------------------------------------
  # ● 新增消息
  #--------------------------------------------------------------------------
  def msg_trigger_call(label, lists)
    label = label.to_s
    list = find_label_list(label, lists)
    return false if list == nil
    @eagle_msg_lists.push( [label, list] )
    return true
  end
  #--------------------------------------------------------------------------
  # ● 当前正在执行指定消息？
  #--------------------------------------------------------------------------
  def msg_trigger_running?(label)
    label == @eagle_msg_cur_label
  end
  #--------------------------------------------------------------------------
  # ● 更新消息
  #--------------------------------------------------------------------------
  def msg_trigger_update
    if !@interpreter_eagle.running?
      if !@eagle_msg_lists.empty?
        list = @eagle_msg_lists.shift
        @eagle_msg_cur_label = list[0]
        @interpreter_eagle.setup(list[1], @eagle_msg_cur_event_id)
      else
        @eagle_msg_cur_label = nil
      end
    else
      @interpreter_eagle.update
    end
  end
  #--------------------------------------------------------------------------
  # ● 当前正在执行消息？
  #--------------------------------------------------------------------------
  def msg?(label = nil)
    return true if label.nil? && @eagle_msg_cur_label
    return true if label.to_s == @eagle_msg_cur_label
    return false
  end
end
end
#==============================================================================
# ■ Game_Temp
#==============================================================================
class Game_Temp
  attr_accessor :last_menu_item
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  alias eagle_event_msg_trigger_init initialize
  def initialize
    eagle_event_msg_trigger_init
    @last_menu_item = nil
  end
end
#==============================================================================
# ■ Game_Troop
#==============================================================================
class Game_Troop < Game_Unit
  include EAGLE::EVENT_MSG
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  alias eagle_event_msg_trigger_init initialize
  def initialize
    eagle_event_msg_trigger_init
    msg_trigger_init
  end
  #--------------------------------------------------------------------------
  # ● 新增消息
  #--------------------------------------------------------------------------
  def msg(label, cond_met = true)
    return true if msg_trigger_running?(label)
    lists = []
    troop.pages.each do |page|
      if cond_met == true
        next unless conditions_met?(page)
      end
      lists.push(page.list)
    end
    return msg_trigger_call(label, lists)
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  alias eagle_event_msg_trigger_update update
  def update
    eagle_event_msg_trigger_update
    msg_trigger_update
  end
end
#==============================================================================
# ■ Game_Map
#==============================================================================
class Game_Map
  include EAGLE::EVENT_MSG
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  alias eagle_event_msg_trigger_init initialize
  def initialize
    eagle_event_msg_trigger_init
    msg_trigger_init
  end
  #--------------------------------------------------------------------------
  # ○ 获取角色面前一格的事件ID
  #--------------------------------------------------------------------------
  def forward_event_id(chara)
    x = $game_map.round_x_with_direction(chara.x, chara.direction)
    y = $game_map.round_y_with_direction(chara.y, chara.direction)
    events = events_xy(x, y)
    return events.empty? ? 0 : events[0].id
  end
  #--------------------------------------------------------------------------
  # ● 新增消息
  #--------------------------------------------------------------------------
  def msg_common(label, common_event_id = 0)
    return true if msg_trigger_running?(label)
    lists = []
    if common_event_id.is_a?(Array)
      common_event_id.each do |i|
        lists.push( $data_common_events[common_event_id].list )
      end
    elsif common_event_id == 0
      $data_common_events.each { |event| lists.push( event.list ) }
    else
      lists.push( $data_common_events[common_event_id].list )
    end
    return msg_trigger_call(label, lists)
  end
  #--------------------------------------------------------------------------
  # ● 更新事件
  #--------------------------------------------------------------------------
  alias eagle_event_msg_trigger_update_events update_events
  def update_events
    eagle_event_msg_trigger_update_events
    msg_trigger_update
  end
end
#==============================================================================
# ■ Game_Event
#==============================================================================
class Game_Event
  include EAGLE::EVENT_MSG
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  alias eagle_event_msg_trigger_init initialize
  def initialize(map_id, event)
    eagle_event_msg_trigger_init(map_id, event)
    msg_trigger_init
    @eagle_msg_cur_event_id = @event.id
  end
  #--------------------------------------------------------------------------
  # ● 新增消息
  #--------------------------------------------------------------------------
  def msg(label, cur_page = false)
    return true if msg_trigger_running?(label)
    return false if cur_page && @page.nil?
    lists = (cur_page ? [@page.list] : @event.pages.collect { |e| e.list })
    return msg_trigger_call(label, lists)
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  alias eagle_event_msg_trigger_update update
  def update
    eagle_event_msg_trigger_update
    msg_trigger_update
  end
  #--------------------------------------------------------------------------
  # ● 事件启动
  #--------------------------------------------------------------------------
  alias eagle_event_msg_trigger_start start
  def start
    return if @eagle_msg_cur_label # 如果当前事件有消息，则自身不再触发
    eagle_event_msg_trigger_start
  end
end
#==============================================================================
# ■ Scene_ItemBase
#==============================================================================
class Scene_ItemBase < Scene_MenuBase
  #--------------------------------------------------------------------------
  # ● 公共事件预定判定
  #    如果预约了事件的调用，则切换到地图画面。
  #--------------------------------------------------------------------------
  alias eagle_event_msg_trigger_check_common_event check_common_event
  def check_common_event
    $game_temp.last_menu_item = item
    eagle_event_msg_trigger_check_common_event
  end
end
