#==============================================================================
# ■ 事件警报机制 by 老鹰（http://oneeyedeagle.lofter.com/）
# 【此插件兼容VX和VX Ace】
#==============================================================================
$imported ||= {}
$imported["EAGLE-EventAlert"] = true
#==============================================================================
# - 2021.2.13.22 新增预定公共事件的执行条件
#==============================================================================
# - 本插件新增警报机制，以并行判定并执行简单脚本
#--------------------------------------------------------------------------
# ○ 事件页设置警报
#--------------------------------------------------------------------------
# - 当事件页的第一个指令为 注释 时，在其中按下述格式填写，以设置并行判定
#   （可重复填写）（若单个指令写不下，可写在之后连续的 注释 指令内，将一并读取）
#
#    <alert[ 目标对象id]>[<repeat>]<cond>..<eval>..</alert>
#
#   其中 目标对象id 为绑定的目标对象（0为玩家，正数为事件id）（默认不填取 0）
#     （若目标不存在，依然可以更新）
#
#   其中填入 <repeat> 代表当条件满足时，将反复执行脚本
#     （若无该标签，则只在条件由不满足变为满足时，执行一次脚本）
#
#   其中 <cond>.. 中的 .. 替换为判定条件脚本
#      可用 map_id 代表当前地图id
#      可用 s 代表开关组，v 代表变量组
#      可用 ss 代表独立开关组
#           如 ss[ [map_id, a.id, 'A'] ] = true 为开启当前事件的A号独立开关
#      可用 sv 代表独立变量组（若使用了【事件页触发条件扩展 by 老鹰】）
#           如 sv[ [map_id, a.id, 1] ] = 2 为当前事件的1号独立变量赋值 2
#      可用 a 代表当前事件，b 代表目标对象（若不存在则为 nil）
#           dx 与 dy 为当前事件与目标对象间的坐标差的绝对值
#
#   其中 <eval>.. 中的 .. 替换为需要执行的脚本
#
# - 示例
#    <alert 0> <cond> dx+dy <= 1 <eval> b.balloon_id = 1 </alert>
#      → 当玩家与当前事件的距离小于等于1时，玩家头顶显示1号心情气泡
#
#--------------------------------------------------------------------------
# ○ 注意
#--------------------------------------------------------------------------
# - 当事件正在执行时，其预设的警报不会被触发
# - 当存在预定调用的公共事件时，如使用物品调用公共事件，事件的全部警报不会被触发
#
#==============================================================================

module EVENT_ALERT
  #--------------------------------------------------------------------------
  # ● 【常量】该序号的开关开启时，预定公共事件不再影响事件警报的触发
  #--------------------------------------------------------------------------
  S_ID_COMMON = 0
  #--------------------------------------------------------------------------
  # ● 解析字符串
  #--------------------------------------------------------------------------
  def self.parse_note(str)
    _array = []
    str.scan( /<alert ?(\d+)?>(.*?)<\/alert>/m ).each do |params|
      t_id = params[0].to_i || 0
      _hash = { :t_id => t_id }
      lines = params[1].split(/<cond>/)
      _hash[:repeat] = lines[0] =~ /<repeat>/i ? true : false
      lines_ = lines[1].split(/<eval>/)
      _hash[:cond] = lines_[0]
      _hash[:eval] = lines_[1]
      _array.push( _hash )
    end
    return _array
  end
  #--------------------------------------------------------------------------
  # ● 获取角色对象
  #--------------------------------------------------------------------------
  def self.get_target(t_id)
    return $game_player if t_id == 0
    return $game_map.events[t_id] rescue nil
  end
end
#==============================================================================
# ■ 【读取部分】
#==============================================================================
module EAGLE
  #--------------------------------------------------------------------------
  # ● 读取事件页开头的注释组
  #--------------------------------------------------------------------------
  def self.event_comment_head(command_list)
    return "" if command_list.nil? || command_list.empty?
    t = ""; index = 0
    while command_list[index].code == 108 || command_list[index].code == 408
      t += command_list[index].parameters[0]
      index += 1
    end
    t
  end
end

#==============================================================================
# ■ 兼容VX
#==============================================================================
if RUBY_VERSION[0..2] == "1.8"
class Game_Event
  #--------------------------------------------------------------------------
  # ● 设置事件页
  #--------------------------------------------------------------------------
  alias eagle_event_alert_trigger_setup setup
  def setup(new_page)
    eagle_event_alert_trigger_setup(new_page)
    setup_page_settings
  end
  def setup_page_settings
    clear_page_settings
  end
  #--------------------------------------------------------------------------
  # ● 清除事件页的设置
  #--------------------------------------------------------------------------
  def clear_page_settings
  end
end
class Game_Interpreter
  attr_reader :event_id
end
end

#==============================================================================
# ■ Game_Map
#==============================================================================
class Game_Map
  #--------------------------------------------------------------------------
  # ● 指定事件正在执行？
  #--------------------------------------------------------------------------
  def is_event_running?(event_id)
    @interpreter.running? && @interpreter.event_id == event_id
  end
  #--------------------------------------------------------------------------
  # ● 预定公共事件执行？
  #--------------------------------------------------------------------------
  def is_common_event_running?(common_event_id = 0)
    return false if !@interpreter.running?
    if common_event_id == 0
      return true if @interpreter.event_id < 0
    else
      return true if @interpreter.event_id.abs == common_event_id
    end
    return false
  end
end
#==============================================================================
# ■ Game_Event
#==============================================================================
class Game_Event
  #--------------------------------------------------------------------------
  # ● 设置事件页的设置
  #--------------------------------------------------------------------------
  alias eagle_event_alert_trigger_setup_page_settings setup_page_settings
  def setup_page_settings
    eagle_event_alert_trigger_setup_page_settings
    t = EAGLE.event_comment_head(@list)
    @eagle_alerts = EVENT_ALERT.parse_note(t)
  end
  #--------------------------------------------------------------------------
  # ● 清除事件页的设置
  #--------------------------------------------------------------------------
  alias eagle_event_alert_trigger_clear_page_settings clear_page_settings
  def clear_page_settings
    eagle_event_alert_trigger_clear_page_settings
    @eagle_alerts = []
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  alias eagle_event_alert_trigger_update update
  def update
    eagle_event_alert_trigger_update
    alert_triggers_update if update_alert_triggers?
  end
  #--------------------------------------------------------------------------
  # ● 更新警报？
  #--------------------------------------------------------------------------
  def update_alert_triggers?
    return false if @eagle_alerts.empty?
    return false if $game_map.is_event_running?(self.id)
    return false if !$game_switches[EVENT_ALERT::S_ID_COMMON] && $game_map.is_common_event_running?
    return true
  end
  #--------------------------------------------------------------------------
  # ● 更新警报
  #--------------------------------------------------------------------------
  def alert_triggers_update
    a = self
    map_id = $game_map.map_id
    @eagle_alerts.each do |hash|
      b = EVENT_ALERT.get_target(hash[:t_id])
      s = $game_switches; v = $game_variables
      ss = $game_self_switches
      sv = $game_self_variables if $imported["EAGLE-EventCondEX"]
      if b
        dx = (a.x - b.x).abs
        dy = (a.y - b.y).abs
      end
      if eval(hash[:cond]) == true
        next if hash[:repeat] == false && hash[:trigger] == true
        hash[:trigger] = true
        eval(hash[:eval])
      else
        hash[:trigger] = false
      end
    end
  end
end
#==============================================================================
# ■ Game_Interpreter
#==============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 设置事件
  #--------------------------------------------------------------------------
  alias eagle_event_alert_trigger_setup setup
  def setup(list, event_id = 0)
    eagle_event_alert_trigger_setup(list, event_id)
    # 扩展：当执行预定的通常公共事件时，记录其id的负数
    @event_id = -$game_temp.common_event_id if $game_temp.common_event_id > 0
  end
end
