#a 当前事件
#b 目标（0为玩家，正数为事件id）（默认 0）
#dx dy 坐标差的绝对值

a = "<alert 1><repeat>
<cond>..
<eval>...
</alert>"

module EVENT_ALERT
  def self.parse_note(str)
    _array = []
    str.scan( /<alert ?(\d+)?>(.*?)<\/alert>/m ).each do |params|
      t_id = params[0].to_i || 0
      _hash = { :t_id => t_id }
      lines = params[1].split(/\n/)
      # 第一行为参数
      _hash[:repeat] = lines[0] =~ /<repeat>/i ? true : false
      # 第二行为触发条件
      _hash[:cond] = lines[1][6..-1]
      # 第三行为执行内容
      _hash[:eval] = lines[2][6..-1]
      _array.push( _hash )
    end
    return _array
  end

  def self.get_target(t_id)
    return $game_player if t_id == 0
    return $game_map.events[t_id]
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
  # ● 更新
  #--------------------------------------------------------------------------
  alias eagle_event_alert_trigger_update update
  def update
    eagle_event_alert_trigger_update
    alert_triggers_update
  end

  def alert_triggers_update
    a = self
    @eagle_alerts.each do |hash|
      b = EVENT_ALERT.get_target(hash[:t_id])
      next if b.nil?
      s = $game_switches; v = $game_variables
      ss = $game_self_switches
      sv = $game_self_variables if $imported["EAGLE-EventCondEX"]
      dx = (a.x - b.x).abs
      dy = (a.y - b.y).abs
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
