#==============================================================================
# ■ Add-On 事件调查提示 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# 【此插件兼容VX和VX Ace】
# ※ 本插件需要放置在【组件-通用方法汇总 by老鹰】>1.1.7 
#    与【角色头顶显示图标 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-EventTSearchIcon"] = "2.2.0"
#==============================================================================
# - 2023.11.27.231 新增脚本内预设
#==============================================================================
# - 本插件新增了玩家接近或面向事件时自动显示图标的功能
#-----------------------------------------------------------------------------
# 1.1 玩家接近事件时，在事件头顶显示图标
#--------------------------------------------------------------------
# - 事件页的第一条指令为注释，且里面含有下述内容时，
#   当玩家与事件的距离小于等于指定值，将在该事件头顶显示设置的图标：
#
#     <图标靠近 icon ...>{{eval}} 
#   或
#     <图标靠近 事件 icon ...>{{eval}}
#
#   其中 icon 替换为需要显示的图标的ID
#   其中 ... 替换为下列的赋值字符串，可写多条，用空格隔开
#     具体参数可见【角色头顶显示图标】中的 @pop_icon_params
#
#      def=数字 → 应用预设中的对应设置，然后再用实际编写的设置覆盖（图标不变）
#      （由于脚本设计缺陷，虽然预设中已经有了图标，但事件注释的icon还是要写，
#        比如 <图标靠近 1 def=调查>，其中的 1 无效，因为预设中的图标优先级最高）
#
#      pos=数字 → 显示位置（0事件头顶，1事件脚底，2事件中心）
#      type=数字 → 设置移动的类型
#      dir=数字 → 图标移动模式（2朝下移再上移，468同理）
#      opa=数字 → 0为关闭显隐切换效果，1为开启
#      dx=数字 dy=数字 → 坐标的偏移量
#
#      pri=数字 → 显示优先级（数字大的将覆盖数字小的）（默认0）
#                （若优先级相同，则写在后面的、事件ID大的显示）
#
#   其中 {{eval}} 替换成该条显示图标的执行条件（可省略，默认true）
#     （可用简写： s = $game_switches; v = $game_variables; 
#        ss = $game_self_switches;
#        es = $game_map.events; gp = $game_player; event 为当前事件）
#
#   当存在多条显示图标时，将按顺序逐条判定条件，并显示第一条满足条件的。
#
#--------------------------------------------------------------------
# 1.2 玩家接近事件时，在玩家头顶显示图标
#--------------------------------------------------------------------
# - 事件页的第一条指令为注释，且里面含有下述内容时，
#   当玩家与事件的距离小于等于指定值，将在玩家头顶显示设置的图标：
#
#     <图标靠近 玩家 icon ...>{{eval}}
#
#   其余同上
#
#--------------------------------------------------------------------
# 1.3 设置玩家接近事件的距离
#--------------------------------------------------------------------
# - SEARCH_RANGE 常量设置了玩家接近事件时显示图标的最大距离
#   该距离计算方式为 x坐标差值绝对值 + y坐标差值绝对值
#
# - V_ID_SEARCH_RANGE 常量序号的变量的值大于 0 时，将作为触发的最大距离
#
# - 事件页的第一条指令为注释时，在其中编写
# 
#      <图标距离 d>
#
#   其中 d 为最大距离数字，可以为该事件页设置独立的触发距离
#
#--------------------------------------------------------------------
# 2.1 玩家面对事件时，在事件头顶显示图标
# （优先级大于 1.1，将覆盖全部 1.1 中设置的显示图标）
#--------------------------------------------------------------------
# - 事件页的第一条指令为注释，且里面含有该内容时：
#   当玩家面对事件时（按确定键就可触发的状态），将在该事件头顶显示该图标。
#
#     <图标面朝 icon ...>{{eval}}
#   或
#     <图标面朝 事件 icon ...>{{eval}}
#
#   其余同上
#
#--------------------------------------------------------------------
# 2.2 玩家面对事件时，在事件头顶显示图标
# （优先级大于 1.2，将覆盖全部 1.2 中设置的显示图标）
#--------------------------------------------------------------------
# - 事件页的第一条指令为注释，且里面含有该内容时：
#   当玩家面对事件时（按确定键就可触发的状态），将在玩家头顶显示该图标。
#
#     <图标面朝 玩家 icon ...>{{eval}}
#
#   其余同上
#
#--------------------------------------------------------------------
# ● 示例
#--------------------------------------------------------------------
# - 示例1：
#
#    <图标靠近 4> 
#        → 当玩家与事件距离小于等于 3 时，事件头顶显示4号图标
#
#    <图标靠近 160 pos=2 pri=10> 
#        → 距离判定同上，事件中心显示160号图标，优先级为10
#
#    <图标靠近 玩家 4>{{s[1]}} 
#        → 距离判定同上，1号开关开启时，玩家头顶显示4号图标
#
#---------------------------------------------------------------
# - 示例2：
#
#    <图标面朝 5> 
#        → 当玩家面朝事件时，事件头顶显示5号图标
#
#    <图标面朝 玩家 10 type=1 pri=20> 
#        → 判定同上，玩家头顶显示10号图标，使用1号移动类型，
#           优先级为20（且额外增加1000，确保比1.2中的优先级大）
#
#    <图标面朝 事件 20>{{v[1]>10}} 
#        → 判定同上，1号变量大于10时，事件头顶显示20号图标
#
#--------------------------------------------------------------------
# ● 高级
#--------------------------------------------------------------------
#
#   ·图标设置为 0 则为不显示
#
#==============================================================================
module POP_ICON
  #--------------------------------------------------------------------------
  # ●【常量】正则表达式-玩家靠近时，事件头顶显示图标
  #--------------------------------------------------------------------------
  REGEXP_EVENT_NEAR  = /<图标靠近 *(事件|玩家)? *(\d+) *?(.*?)>({{.*?}})?/m
  #--------------------------------------------------------------------------
  # ●【常量】正则表达式-玩家面向事件时，玩家头顶显示图标
  #--------------------------------------------------------------------------
  REGEXT_EVENT_FRONT = /<图标面朝 *(事件|玩家)? *(\d+) *?(.*?)>({{.*?}})?/m

  #--------------------------------------------------------------------------
  # ●【常量】控制开关
  # 当该序号开关开启时，不再自动显示该addon中的任何调查提示的图标
  #--------------------------------------------------------------------------
  S_ID_NO_POPHINT = 0

  #--------------------------------------------------------------------------
  # ●【常量】检测半径
  #--------------------------------------------------------------------------
  # 当玩家与事件距离小于等于该值时，激活事件页中设置的图标
  #--------------------------------------------------------------------------
  SEARCH_RANGE = 3
  #--------------------------------------------------------------------------
  # 如果不想把激活距离设置为固定值，可以修改该项为变量序号
  #   该序号的变量的值如果大于0，则会被读取作为距离值
  #   该序号设置为 0 时，依然取 SEARCH_RANGE 设置的固定值
  #--------------------------------------------------------------------------
  V_ID_SEARCH_RANGE = 0
  #--------------------------------------------------------------------------
  # 如果想为特定事件页设置激活距离，可以在第一条注释指令中写该表达式
  #   如 <图标距离 1> 就是指定该事件页的头顶图标在与玩家距离1格时激活
  #--------------------------------------------------------------------------
  REGEXP_EVENT_ICON_DIST = /<图标距离 *(\d+)>/m

  #--------------------------------------------------------------------------
  # ●【常量】检测频率
  #--------------------------------------------------------------------------
  # 每隔该帧数进行一次图标显示的刷新
  #   需要设置该值小于【角色头顶显示图标】中的MAX_SHOW_FRAME，保证图标连续显示
  #   同时也不要太小，防止刷新频率过多而出现可能的卡顿……
  #--------------------------------------------------------------------------
  FREQ_UPDATE = 7

  #--------------------------------------------------------------------------
  # ●【常量】玩家靠近时，事件头顶显示图标的默认运动类型
  #--------------------------------------------------------------------------
  DEF_TYPE_EVENT_NEAR = 3
  #--------------------------------------------------------------------------
  # ●【常量】玩家面向事件时，玩家头顶显示图标的默认运动类型
  #--------------------------------------------------------------------------
  DEF_TYPE_EVENT_FRONT = 1
  #--------------------------------------------------------------------------
  # ●【常量】玩家靠近时，玩家及事件头顶显示图标的默认优先级
  #--------------------------------------------------------------------------
  DEF_PRI_EVENT_NEAR = 0
  #--------------------------------------------------------------------------
  # ●【常量】玩家面向事件时，玩家及事件头顶显示图标的默认优先级增量
  #--------------------------------------------------------------------------
  DEF_PRI_EVENT_FRONT = 1000

  #--------------------------------------------------------------------------
  # ● 获取检测半径
  #--------------------------------------------------------------------------
  def self.get_search_range
    v = $game_variables[V_ID_SEARCH_RANGE]
    return v if v > 0
    return SEARCH_RANGE
  end
end

class Game_Player
  #--------------------------------------------------------------------------
  # ● 更新画面
  #--------------------------------------------------------------------------
  alias eagle_search_pop_update update
  def update
    eagle_search_pop_update
    update_search_pop
  end
  #--------------------------------------------------------------------------
  # ● 更新调查图标
  #--------------------------------------------------------------------------
  def update_search_pop
    return if $game_switches[POP_ICON::S_ID_NO_POPHINT]
    return if $game_map.interpreter.running?
    @eagle_search_count ||= 0
    @eagle_search_count += 1
    return if @eagle_search_count <= POP_ICON::FREQ_UPDATE
    check_search_pop
    @eagle_search_count = 0
  end
  #--------------------------------------------------------------------------
  # ● 检查事件的调查图标
  #--------------------------------------------------------------------------
  def check_search_pop
    $game_map.events.each do |id, e|
      f_event, f_player = check_event_front(e)
      check_event_near(e, f_event, f_player)
    end
  end
  #--------------------------------------------------------------------------
  # ● 检查玩家面向时显示图标
  #--------------------------------------------------------------------------
  def check_event_front(event)
    if EAGLE_COMMON::MODE_VA
      x2 = $game_map.round_x_with_direction(@x, @direction)
      y2 = $game_map.round_y_with_direction(@y, @direction)
    elsif EAGLE_COMMON::MODE_VX
      x2 = $game_map.x_with_direction(@x, @direction)
      y2 = $game_map.y_with_direction(@y, @direction)
    end
    f = event.x == x2 && event.y == y2
    if $imported["EAGLE-PixelMove"]
      x_p, y_p = get_collision_xy(@direction)
      x2 = $game_map.round_x_with_direction(x_p, @direction)
      y2 = $game_map.round_y_with_direction(y_p, @direction)
      f = event.pos?(x2, y2)
    end
    if f
      t = EAGLE_COMMON.event_comment_head(event.list)
      f_event = false; f_player = false
      t.scan(POP_ICON::REGEXT_EVENT_FRONT).each do |ps|
        _f_event = (ps[0] || "事件") == "事件"
        e = (_f_event ? event : self)
        h = { :event => e }
        next if ps[-1] && EAGLE_COMMON.check_bool(ps[-1][2..-3], false, h) != true
        h = EAGLE_COMMON.parse_tags(ps[2].lstrip)
        h = POP_ICON.apply_default(h[:def], h) if h[:def]
        h[:type] ||= POP_ICON::DEF_TYPE_EVENT_FRONT
        h[:pri]  = (h[:pri] || POP_ICON::DEF_PRI_EVENT_NEAR).to_i
        h[:pri] += POP_ICON::DEF_PRI_EVENT_FRONT
        e.pop_icon_params[:pri] ||= 0
        next if e.pop_icon_params[:pri] > h[:pri]
        e.pop_icon = ps[1].to_i rescue 0
        # 应用预设中的icon
        e.pop_icon = h[:icon].to_i if h[:icon].to_i > 0
        h[:icon] = 0  # 置零，防止重复刷新和持续显示
        e.pop_icon_params.merge!(h)
        _f_event ? (f_event = true) : (f_player = true)
      end
      return f_event, f_player
    end
    return false, false
  end
  #--------------------------------------------------------------------------
  # ● 检查玩家靠近时显示图标
  #--------------------------------------------------------------------------
  def check_event_near(event, f_event=false, f_player=false)
    d = (event.x - @x).abs + (event.y - @y).abs
    if $imported["EAGLE-PixelMove"]
      d = (event.rgss_x - @rgss_x).abs + (event.rgss_y - @rgss_y).abs
    end
    t = EAGLE_COMMON.event_comment_head(event.list)
    t =~ POP_ICON::REGEXP_EVENT_ICON_DIST
    dist = ($1 || POP_ICON.get_search_range).to_i
    return if d > dist
    t.scan(POP_ICON::REGEXP_EVENT_NEAR).each do |ps|
      _f_event = (ps[0] || "事件") == "事件"
      # 如果已经有对应的玩家面朝事件时显示图标，则跳过判定
      next if (f_event && _f_event) || (f_player && !_f_event)
      # 区分 显示在事件头顶的图标 和 显示在玩家头顶的图标
      e = (_f_event ? event : self)
      h = { :event => e }
      next if ps[-1] && EAGLE_COMMON.check_bool(ps[-1][2..-3], false, h) != true
      h = EAGLE_COMMON.parse_tags(ps[2].lstrip)
      h = POP_ICON.apply_default(h[:def], h) if h[:def]
      h[:type] ||= POP_ICON::DEF_TYPE_EVENT_NEAR
      h[:pri]  = (h[:pri] || POP_ICON::DEF_PRI_EVENT_NEAR).to_i
      e.pop_icon_params[:pri] ||= 0
      # 如果当前显示的图标的优先级更大，则跳过
      next if e.pop_icon_params[:pri] > h[:pri]
      e.pop_icon = ps[1].to_i rescue 0
      # 应用预设中的icon
      e.pop_icon = h[:icon].to_i if h[:icon].to_i > 0
      h[:icon] = 0  # 置零，防止重复刷新和持续显示
      e.pop_icon_params.merge!(h)
    end
  end
end

#=============================================================================
# ○ Sprite_Character
#=============================================================================
class Sprite_Character
  #--------------------------------------------------------------------------
  # ● 释放图标pop
  #--------------------------------------------------------------------------
  alias eagle_search_pop_end_popicon end_popicon
  def end_popicon
    eagle_search_pop_end_popicon
    @character.pop_icon_params[:pri] = 0  # 每次显示结束，优先级重置
  end
end
