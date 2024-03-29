#==============================================================================
# ■ Add-On 事件触发事件 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【事件互动扩展 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-EventTriggerEvent"] = "1.2.0"
#==============================================================================
# - 2022.2.27.20 新增 事件碰撞事件时存入target变量
#==============================================================================
# - 本插件新增了事件之间的接触触发
#------------------------------------------------------------------------------
# 【思路】
#
# - 由于事件触发事件在默认设计中是不存在的，
#   如果使用并行触发或自动触发，又会影响事件的正常按键触发，
#   但如果使用另一个并行事件，在需要判定多个事件时，又非常复杂和冗余，
#   因此我设计了事件触发事件的特定指令，在触发时，将和玩家按键触发一样挂起其他内容
#
#------------------------------------------------------------------------------
# 【使用 - 事件触发事件（主动式）】
#
# - 在事件页中，编写下述的指令，来设置【自己接触指定事件】后，触发自己的内容
#
#    |-标签：接触事件 id
#    |
#    |-...其余事件指令...
#    |
#    |-标签：END
#
#   其中 接触事件 为识别文本，可通过 E2E_SELF_REGEXP 进行修改，不可缺少
#   其中 id 为 需要检测与之碰撞的事件的ID 或者 它的名字中含有的字符串
#
#      如编写标签“接触事件 5”，即为监测本事件是否与 5 号事件接触，
#         如果接触，则触发本事件的该互动，从“接触事件 5”执行到“END”为止
#
#      如编写标签“接触事件 NPC”，即为监测本事件是否与名称含有“NPC”的事件接触，
#         如果接触，则触发本事件的该互动，从“接触事件 NPC”执行到“END”为止
#
# - 注意：
#
#     1. 触发时，同样会挂起玩家的操作，即与玩家主动触发保持一致效果
#
#     2. 此处的碰撞为广义的：
#          若事件不可穿透，在移动失败后判定面前一格的同层事件
#          若事件允许穿透，在移动成功后判定自身当前格的任意层事件
#
# - 如果想绑定多个事件，可以通过以下方式：
#
#    |-标签：接触事件 id1
#    |-标签：接触事件 id2
#    |-标签：接触事件 id3
#    |
#    |-...其余事件指令...
#    |
#    |-标签：END
#
#   这是因为利用标签进行跳转执行时，不会受到其它标签的影响，
#     而只有遇到第一个END时才结束执行，
#     也因此，可以通过重复填写的方式，来制作与多个事件的接触判定
#
# - 高级：
#
#    在成功触发时，Game_Event 类的event对象中，会在 @target 变量存储碰撞事件的对象
#
#    如 3 号事件设置了标签“接触事件 5”，且与 5 号事件碰撞了，
#      则 3 号事件 $game_map.events[3].target 的值为 $game_map.events[5]
#
#    如 9 号事件设置了标签“接触事件 NPC”，且与名称为“NPC 1号”的 7 号事件碰撞，
#      则 9 号事件 $game_map.events[9].target 的值为 $game_map.events[7]
#
#---------------------------------------------------------------------------
# 【使用 - 事件触发事件（被动式）】
#
# - 在事件页中，编写下述的指令，来设置【自己被指定事件接触】后，触发自己的内容
#
#    |-标签：被事件接触 id
#    |
#    |-...其余事件指令...
#    |
#    |-标签：END
#
#   其中 被事件接触 为识别文本，可通过 E2E_BY_OTHERS_REGEXP 进行修改，不可缺少
#   其中 id 为 需要检测与之碰撞的事件的ID 或者 它的名字中含有的字符串
#
#      如编写标签“被事件接触 3”，即为监测 3 号事件是否与本事件接触，
#         如果被接触，则触发本事件的该互动，从“被事件接触 3”执行到“END”为止
#
#      如编写标签“被事件接触 <敌人>”，
#         即为监测本事件是否与名称含有“<敌人>”的事件接触，如果被接触，
#         则触发本事件的该互动，从“被事件接触 <敌人>”执行到“END”为止
#
# - 如果想绑定多个事件，方法同【事件触发事件（主动式）】
#
#---------------------------------------------------------------------------
# 【使用 - 玩家靠近事件】
#
# - 在事件页中，编写下述的指令，来设置【玩家靠近事件一定距离】后，触发自己的内容
#
#    |-标签：玩家靠近 d
#    |
#    |-...其余事件指令...
#    |
#    |-标签：END
#
#   其中 玩家靠近 为识别文本，可通过 E2E_BY_PLAYER_REGEXP 进行修改，不可缺少
#   其中 d 为玩家与自身之间的距离小于等于该值，在被 eval 后取整数
#
#      距离的计算：玩家与事件之间 x 的差值的绝对值 + y 的差值的绝对值
#
#      如编写标签“玩家靠近 3”，即当玩家与事件距离小于等于3时，
#         触发本事件的该互动，从“玩家靠近 3”执行到“END”为止
#
#      如编写标签“玩家靠近 v[1]”，即当玩家与事件距离小于等于1号变量的值时，
#         触发本事件的该互动，从“玩家靠近 v[1]”执行到“END”为止
#
# - 注意：
#
#  1. 如果使用了【像素级移动 by老鹰】，则距离计算使用 rgss_x 与 rgss_y，
#     即依然为地图编辑器中的格子位置
#
#  2. 当距离值等于 0 时表示重合，小于 0 时无效
#
#---------------------------------------------------------------------------
# 【联动】
#
# - 由于本插件使用了与【事件消息机制 by老鹰】中的同样格式，
#   因此特别增加了调用事件消息进行执行的方式：
#
#    【事件触发事件（主动式）】中编写的标签修改为 接触事件p id
#
#    【事件触发事件（被动式）】中编写的标签修改为 被事件接触p id
#
#    【玩家靠近事件】中编写的标签修改为 玩家靠近p d
#
#   其它内容与上述介绍一致
#
# - 注意：
#
#  1. 在使用事件消息进行执行时，不再挂起玩家的移动
#
#  2. 为了与事件互动保持统一，事件消息也只会检索当前页中的标签
#
#  3. 任意时刻下，只会由此途径触发一次消息，执行完成后才能再次触发同一消息
#     但不同消息之间互不干扰
#
#---------------------------------------------------------------------------
# 【兼容】
#
# - 本插件已经兼容【像素级移动 by老鹰】V1.3.2，请放置于其下
#
#==============================================================================

module EVENT_INTERACT
  #--------------------------------------------------------------------------
  # ● 【常量】定义事件指令-标签中的正则表达式
  #  当自己主动接触了目标事件时，自己触发的互动
  #--------------------------------------------------------------------------
  E2E_SELF_REGEXP = /^接触事件(p?) *(.*)/

  #--------------------------------------------------------------------------
  # ● 【常量】定义事件指令-标签中的正则表达式
  # 当自己被目标事件接触时，自己触发的互动
  #--------------------------------------------------------------------------
  E2E_BY_OTHERS_REGEXP = /^被事件接触(p?) *(.*)/

  #--------------------------------------------------------------------------
  # ● 【常量】定义事件指令-标签中的正则表达式
  # 当玩家靠近自己时，自己触发的互动
  #--------------------------------------------------------------------------
  E2E_BY_PLAYER_REGEXP = /^玩家靠近(p?) *(.*)/

end
#=============================================================================
# ■ Game_Event
#=============================================================================
class Game_Event
  attr_reader    :priority_type,  :eagle_e2e_triggers2
  attr_accessor  :through,  :target
  #--------------------------------------------------------------------------
  # ● 获取事件名称
  #--------------------------------------------------------------------------
  def name
    @event.name
  end
  #--------------------------------------------------------------------------
  # ● 已经结束了的事件
  #--------------------------------------------------------------------------
  def finish?
    empty? || @erased == true
  end
  #--------------------------------------------------------------------------
  # ● 初始化私有成员变量
  #--------------------------------------------------------------------------
  alias eagle_event2event_init_private_members init_private_members
  def init_private_members
    eagle_event2event_init_private_members
    # 主动接触别的事件时，触发自己的指定label [ [label, eid/ename, para] ]
    @eagle_e2e_triggers1 = []
    # 被接触时，触发自己的指定label
    @eagle_e2e_triggers2 = []
    # 玩家靠近时，触发自己的指定label [ [label, d, para] ]
    @eagle_e2e_triggers3 = []
    # 接触/被接触时，另一个事件对象
    @target = nil
  end
  #--------------------------------------------------------------------------
  # ● 设置事件页的设置
  #--------------------------------------------------------------------------
  alias eagle_event2event_setup_page_settings setup_page_settings
  def setup_page_settings
    eagle_event2event_setup_page_settings
    # 解析可能是事件触发事件的标签
    get_value = lambda { |t| v = t.to_i; v != 0 ? v : t }
    @list.size.times do |i|
      next if @list[i].code != 118  # 不为标签指令
      label = @list[i].parameters[0]
      if label =~ EVENT_INTERACT::E2E_SELF_REGEXP
        v = [label, get_value.call($2), false]
        v[2] = true if $1 == "p"
        @eagle_e2e_triggers1.push(v)
        next
      end
      if label =~ EVENT_INTERACT::E2E_BY_OTHERS_REGEXP
        v = [label, get_value.call($2), false]
        v[2] = true if $1 == "p"
        @eagle_e2e_triggers2.push(v)
        next
      end
      if label =~ EVENT_INTERACT::E2E_BY_PLAYER_REGEXP
        d = EAGLE_COMMON.eagle_eval($2).to_i rescue -1
        next if d < 0
        a = [label, d, false]
        a[2] = true if $1 == "p"
        @eagle_e2e_triggers3.push(a)
        next
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● （移动成功时）增加步数
  #--------------------------------------------------------------------------
  def increase_steps
    super
    eagle_check_e2e_triggers_current  # 新增事件触发事件的判定
  end
  #--------------------------------------------------------------------------
  # ● 检查当前格的事件的接触触发
  #--------------------------------------------------------------------------
  def eagle_check_e2e_triggers_current
    x = @x; y = @y
    if $imported["EAGLE-PixelMove"]
      _x, _y = PIXEL_MOVE.get_rect_xy(@collision_rect, 5)
      x += _x
      y += _y
    end
    eagle_trigger_event_pos(x, y, false)
  end
  #--------------------------------------------------------------------------
  # ● （移动失败时）判定面前的事件是否被启动
  #--------------------------------------------------------------------------
  def check_event_trigger_touch_front
    super
    eagle_check_e2e_triggers_front
  end
  #--------------------------------------------------------------------------
  # ● 检查面前一格的事件的接触触发
  #--------------------------------------------------------------------------
  def eagle_check_e2e_triggers_front
    return eagle_check_e2e_triggers_pixel if $imported["EAGLE-PixelMove"]
    x2 = $game_map.round_x_with_direction(@x, @direction)
    y2 = $game_map.round_y_with_direction(@y, @direction)
    eagle_trigger_event_pos(x2, y2)
  end
  #--------------------------------------------------------------------------
  # ● 判断是否与事件接触
  #--------------------------------------------------------------------------
  def eagle_trigger_event_pos(x, y, same_priority = true)
    $game_map.events.each do |eid, event|
      next if event.finish? || !event.pos?(x, y)
      next if same_priority && event.priority_type != @priority_type
      f = eagle_check_trigger1(event)
      f = f || eagle_check_trigger2(event)
      return if f
    end
  end
  #--------------------------------------------------------------------------
  # ● 检查面前一格的事件的接触触发（兼容【像素级移动 by老鹰】）
  #--------------------------------------------------------------------------
  def eagle_check_e2e_triggers_pixel
    x, y = PIXEL_MOVE.get_rect_xy(@collision_rect, @direction)
    x2 = $game_map.round_x_with_direction(x + @x, @direction)
    y2 = $game_map.round_y_with_direction(y + @y, @direction)
    eagle_trigger_event_pos(x2, y2)
  end
  #--------------------------------------------------------------------------
  # ● 主动接触其他事件后，触发自己的label
  #--------------------------------------------------------------------------
  def eagle_check_trigger1(event2)
    @eagle_e2e_triggers1.each do |v|
      label = v[0]
      e = v[1]
      if (e.is_a?(Integer) && event2.id == e) ||
        (e.is_a?(String) && event2.name.include?(e))
        if v[2] && $imported["EAGLE-EventMsg"]
          if !msg?(label)
            self.target = event2
            msg(label, true)
          end
          return true
        end
        self.target = event2
        start_ex(label)
        return true
      end
    end
    return false
  end
  #--------------------------------------------------------------------------
  # ● 主动接触其他事件后，触发它的label
  #--------------------------------------------------------------------------
  def eagle_check_trigger2(event2)
    event2.eagle_e2e_triggers2.each do |v|
      label = v[0]
      e = v[1]
      if (e.is_a?(Integer) && self.id == e) ||
          (e.is_a?(String) && self.name.include?(e))
        if v[2] && $imported["EAGLE-EventMsg"]
          if !event2.msg?(label)
            event2.target = self
            event2.msg(label, true)
          end
          return true
        end
        event2.target = self
        event2.start_ex(label)
        return true
      end
    end
    return false
  end
  #--------------------------------------------------------------------------
  # ● 自动事件的启动判定
  #--------------------------------------------------------------------------
  alias eagle_event2event_check_event_trigger_auto check_event_trigger_auto
  def check_event_trigger_auto
    eagle_event2event_check_event_trigger_auto
    eagle_check_trigger3
  end
  #--------------------------------------------------------------------------
  # ● 玩家靠近事件后，触发label
  #--------------------------------------------------------------------------
  def eagle_check_trigger3
    @eagle_e2e_triggers3.each do |v|
      label = v[0]
      d = v[1]
      d_cur = ($game_player.x - self.x).abs + ($game_player.y - self.y).abs
      if $imported["EAGLE-PixelMove"]
        d_cur = ($game_player.rgss_x - self.rgss_x).abs
        d_cur += ($game_player.rgss_y - self.rgss_y).abs
      end
      next if d_cur > d
      self.target = nil
      if v[2] && $imported["EAGLE-EventMsg"]
        msg(label, true)
        return true
      end
      start_ex(label)
      return true
    end
    return false
  end
end
