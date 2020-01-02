#==============================================================================
# ■ 事件消息机制 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
$imported ||= {}
$imported["EAGLE-EventMsg"] = true
#==============================================================================
# - 2020.1.1.16 兼容像素移动
#==============================================================================
# - 本插件新增消息机制，以直接触发事件中的指令
#--------------------------------------------------------------------------
# ○ 当前地图上的事件对象
#--------------------------------------------------------------------------
# - 对于 Game_Event 对象，新增 msg(LABEL) 方法，来快速调用其中的事件指令序列
#
#    1、在它的所有事件页（无视事件触发条件）中搜索内容为 LABEL 的标签
#    2、若找到，则继续查找在该标签后的第一个内容为 END 的标签
#    3、立即执行这两个标签中间的事件指令（若未找到 END，则一直执行到事件结尾）
#    4、当成功找到标签时，msg 方法返回 true，否则返回 false
#
# 【注意】
#   事件列表中的标签内容需要与 msg 方法传入的标签名称字符串完全一致（包括前后空格）
#
# - 示例：
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
#    正常执行该事件，将按序显示 测试语句1、测试语句2、测试语句3、测试语句4
#    若在另一事件中调用事件脚本 $game_map.events[1].msg("A")，则只显示 测试语句2
#    若在另一事件中调用事件脚本 $game_map.events[1].msg("B")，则只显示 测试语句4
#
# - 扩展：
#    1、利用 $game_temp.last_menu_item 获取最近一次在菜单中所使用物品/技能的实例
#    2、利用 $game_map.forward_event_id(chara) 获取 chara 面前一格事件的ID
#        其中 chara 为 Game_CharacterBase 对象
#        如 $game_player 代表玩家，$game_map.events[id] 代表id号事件
#--------------------------------------------------------------------------
# ○ 地图上的公共事件
#--------------------------------------------------------------------------
# - 利用 $game_map.msg_common(LABLE[, common_event]) 来快速调用公共事件中的指令
#   其中 LABEL 同上，与事件指令列表中完全一致的标签字符串
#   其中 common_event 传入0或省略时，将查询全部公共事件，并返回第一组匹配的LABEL；
#             若传入数组，将在数组范围内按序查询第一组匹配的LABEL；
#             若传入数字，将在该指定的公共事件内查询
#   当成功查找到LABEL时，将返回 true 并立即执行；否则返回 false
#--------------------------------------------------------------------------
# ○ 战斗中的敌群事件
#--------------------------------------------------------------------------
# - 利用 $game_troop.msg(LABEL) 在当前敌群的全部事件页中查询LABEL
# 【注意】
#   该事件指令的执行不受战斗系统的等待影响，因此可能导致其中的对话覆盖战斗系统的对话
#   （如技能释放后调用文本显示，同时敌人全灭，则可能使得胜利结算文本无法显示）
#==============================================================================

module EAGLE
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
  end
  #--------------------------------------------------------------------------
  # ● 新增消息
  #--------------------------------------------------------------------------
  def msg_trigger_call(label, lists)
    list = find_label_list(label.to_s, lists)
    return false if list == nil
    @eagle_msg_lists.push(list)
    return true
  end
  #--------------------------------------------------------------------------
  # ● 更新消息
  #--------------------------------------------------------------------------
  def msg_trigger_update
    if !@eagle_msg_lists.empty? && !@interpreter_eagle.running?
      list = @eagle_msg_lists.shift
      @interpreter_eagle.setup(list, @eagle_msg_cur_event_id)
    end
    @interpreter_eagle.update
  end
end
end

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
  def msg(label)
    lists = troop.pages.collect { |e| e.list }
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
  # ● 获取角色面前一格的事件ID
  #--------------------------------------------------------------------------
  def forward_event_id(chara)
    x = $game_map.round_x_with_direction(chara.x, chara.direction)
    y = $game_map.round_y_with_direction(chara.y, chara.direction)
    events = $game_map.event_xy(x, y)
    return events.empty? ? 0 : events[0].id
  end
  #--------------------------------------------------------------------------
  # ● 新增消息
  #--------------------------------------------------------------------------
  def msg_common(label, common_event_id = 0)
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
  def msg(label)
    lists = @event.pages.collect { |e| e.list }
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
