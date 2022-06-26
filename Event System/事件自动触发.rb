#==============================================================================
# ■ 事件自动触发 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【组件-通用方法汇总 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-EventStart"] = "1.0.0"
#==============================================================================
# - 2022.6.26.21
#==============================================================================
# - 本插件新增了自动触发事件的条件设置，相当于“自动触发”的扩展
#------------------------------------------------------------------------------
# - 事件页的第一条指令为注释，且里面含有该内容时：
#
#   <自动 ...>
#
#     其中 自动 为识别符，不可修改
#     其中 ... 替换为下列的赋值字符串：
#     （可写多条，用空格隔开）
#
#       eval=名称 → 触发所需的条件，将替换为 EVALS 中的脚本进行判定
#                    当条件返回 true 时，将触发当前事件页（效果同“自动触发”）
#
#       wait=数字 → 【可选】每次进行条件判定后的等待帧数，防止可能的卡顿
#                    若不设置，则取脚本中的 WAIT_AFTER_UPDATE 常量
#
#       once=数字 → 【可选】只会触发一次？（在地图切换、事件页更新时重置）
#                    传入 1 代表只触发一次，
#                    传入 0 或 不设置 代表每次触发条件满足时，都会触发一次
#
#     若使用了【事件互动扩展 by老鹰】，则新增三个【可选】设置：
#
#       sym1=标签名 → 条件由不满足变为满足时，触发当前页的 sym1 互动类型
#
#       sym2=标签名 → 条件持续满足时，触发当前页的 sym2 互动类型
#
#       sym3=标签名 → 条件由满足变为不满足时，触发当前页的 sym3 互动类型
#
#---------------------------------------------------------------------------
# - 示例：
#
#    <自动 eval=玩家距离2 sym1=惊讶>
#
#      → 检索 EVALS["玩家距离2"] 对应的脚本，并判定执行
#         如果当前事件与玩家的距离小于等于2，则触发当前事件中的“惊讶”互动
#
#---------------------------------------------------------------------------
# - 若使用了【事件消息机制 by老鹰】，则可将 自动 替换为 并行，以使用事件消息执行
#
#    如： <并行 eval=玩家距离2 sym1=惊讶>
#
#      → 此时触发“惊讶”互动时，将采用并行处理，不会阻止玩家移动
#
#---------------------------------------------------------------------------
# - 为了方便本脚本的更新，推荐在本脚本之下新增一个空白页，命名为“【条件脚本】”
#   并复制如下的内容，进行修改和扩写：
#
=begin
# --------复制以下的内容！--------

module EVENT_START
  EVALS ||= {}

  EVALS["玩家距离5"] = "EVENT_START.distance($game_player, event) <= 5"

  EVALS["倒计时60"] = "
    event.tmp[:auto_count] ||= 60;
    event.tmp[:auto_count] -= 1;
    event.tmp[:auto_count] <= 0
  "

  EVALS["1号区域上"] = "event.region_id == 1"
  EVALS["玩家1号区域上"] = "$game_player.region_id == 1"

end

# --------复制以上的内容！--------
=end
#
#---------------------------------------------------------------------------
# - 高级：
#
# ·为Game_Event类新增了 @tmp 这样一个Hash变量，可以用于存储临时数据
#
#==============================================================================
module EVENT_START
  #--------------------------------------------------------------------------
  # ○【常量】定义条件脚本
  #  其中可用 event 代表当前事件对象
  #--------------------------------------------------------------------------
  EVALS = {}

  EVALS["玩家距离2"] = "EVENT_START.distance($game_player, event) <= 2"

  # 获得两个角色之间的格子距离
  def self.distance(chara1, chara2)
    d = (chara1.x - chara2.x).abs + (chara1.y - chara2.y).abs
    if $imported["EAGLE-PixelMove"]
      d = (chara1.rgss_x - chara2.rgss_x).abs + (chara1.rgss_y - chara2.rgss_y).abs
    end
    return d
  end

  #--------------------------------------------------------------------------
  # ● 运行脚本
  #--------------------------------------------------------------------------
  def self.eval(sym, event)
    t = sym
    t = EVALS[sym] if EVALS[sym]
    ps = { :event => event }
    r = EAGLE_COMMON.eagle_eval(t, ps)
    return EAGLE_COMMON.check_bool(r, false)
  end
  #--------------------------------------------------------------------------
  # ○【常量】每两次更新之间的间隔帧数
  #  确保不因为频繁判定而出现可能的卡顿
  #--------------------------------------------------------------------------
  WAIT_AFTER_UPDATE = 10
  #--------------------------------------------------------------------------
  # ● 解析事件页头部的注释
  #--------------------------------------------------------------------------
  def self.parse_notes(str)
    arr = []
    str.scan( /<(自动|并行) ?(.*?)>/m ).each do |params|
      type = params[0]
      t = params[1]
      _hash = EAGLE_COMMON.parse_tags(t)
      # 是否需要尝试使用事件消息
      _hash[:para] = type == "并行"
      # 更新后的等待计数
      _hash[:wait] ||= WAIT_AFTER_UPDATE
      _hash[:count] = 0
      # 当前是否已经激活
      _hash[:flag] = false
      # 是否一次性
      _hash[:once] ||= 0
      _hash[:once] = EAGLE_COMMON.check_bool(_hash[:once], false)
      # 特别的，如果没有设置 sym，则退化为自动执行条件，设为一次性的
      if _hash[:sym1].nil? && _hash[:sym2].nil? && _hash[:sym3].nil?
        _hash[:once] = true
      end
      # 能够更新？
      _hash[:valid] = true
      arr.push(_hash)
    end
    return arr
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
end
#==============================================================================
# ■ Game_Event
#==============================================================================
class Game_Event
  attr_reader  :tmp
  #--------------------------------------------------------------------------
  # ● 设置事件页的设置
  #--------------------------------------------------------------------------
  alias eagle_event_start_trigger_setup_page_settings setup_page_settings
  def setup_page_settings
    eagle_event_start_trigger_setup_page_settings
    t = EAGLE_COMMON.event_comment_head(@list)
    @eagle_start = EVENT_START.parse_notes(t)
    @tmp = {}
  end
  #--------------------------------------------------------------------------
  # ● 清除事件页的设置
  #--------------------------------------------------------------------------
  alias eagle_event_start_trigger_clear_page_settings clear_page_settings
  def clear_page_settings
    eagle_event_start_trigger_clear_page_settings
    @eagle_start = []
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  alias eagle_event_start_trigger_update update
  def update
    eagle_event_start_trigger_update
    event_start_update if event_start_update?
  end
  #--------------------------------------------------------------------------
  # ● 能够更新自动触发？
  #--------------------------------------------------------------------------
  def event_start_update?
    return false if @eagle_start.empty?
    return false if $game_map.is_event_running?(self.id)
    return true
  end
  #--------------------------------------------------------------------------
  # ● 更新自动触发
  #--------------------------------------------------------------------------
  def event_start_update
    @eagle_start.each do |_hash|
      next if _hash[:valid] == false
      _hash[:count] -= 1
      next if _hash[:count] > 0
      _hash[:count] = _hash[:wait]
      f = EVENT_START.eval(_hash[:eval], self)
      if _hash[:flag] == false
        if f == true # 从未激活到激活
          _hash[:valid] = false if _hash[:once] == true # 一次性的？
          event_start_sym(_hash, _hash[:sym1]) if _hash[:sym1]
        end
      else
        if f == false # 从激活到未激活
          event_start_sym(_hash, _hash[:sym3]) if _hash[:sym3]
        else # 仍在激活中
          event_start_sym(_hash, _hash[:sym2]) if _hash[:sym2]
        end
      end
      _hash[:flag] = f
    end
  end
  #--------------------------------------------------------------------------
  # ● 触发事件
  #--------------------------------------------------------------------------
  def event_start_sym(_hash, sym)
    if $imported["EAGLE-EventMsg"] && _hash[:para] == true
      self.msg(sym)
      return
    end
    if $imported["EAGLE-EventInteractEX"]
      self.start_ex(sym)
      return
    end
    self.start
  end
end
