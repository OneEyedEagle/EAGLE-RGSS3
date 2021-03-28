#==============================================================================
# ■ 事件互动列表 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
$imported ||= {}
$imported["EAGLE-MessageBlock"] = true
#==============================================================================
# - 2021.3.28.16
#==============================================================================
# - 本插件新增了事件页的按空格键触发的互动类型
#------------------------------------------------------------------------------
# 【思路】
#
# - 由于默认的“按确定键”触发事件页，是单纯的执行事件页的全部指令，
#   而且对于玩家面前是否存在可触发的事件，无法给出一个提示，
#   因此我设计了这个外置的并行的互动列表UI，效仿大部分游戏都有的互动提示功能
#
# 【使用】
#
# - 当事件页的第一条指令为注释，且其中包含【xx】类型的文本时，
#     在玩家面朝事件，且事件页出现条件均满足，将自动开启它的互动列表
#
#   注意：注释中的【xx】可重复填写多次。
#
#   对于未填写【xx】类型注释内容的事件页，依然按照默认的方式执行全部指令。
#
# - 在事件页的执行内容中，按照与【事件消息机制 by老鹰】中的同样策略进行编写
#   对于注释中写的【xx】类型的互动，应在当前事件页中编写：
#
#     标签： xx
#       其余事件指令
#     标签：END
#
#   来定义这个互动能触发的事件指令
#   若未编写，则不触发任何指令
#
# - 此时按下 SHIFT键 能够在不同的互动类型中切换
#       按下 确定键 执行对应的互动类型中的指令
#       按下 方向键 将正常移动，即在显示互动列表时，不会干扰玩家的移动
#
# 【示例】
#
# - 当前地图的 1 号事件的第 1 页中指令列表（事件页的出现条件已经满足）
#    |- 注释：【交谈】【商店】【贿赂】
#    |- 标签：交谈
#    |- 显示文字：测试语句1
#    |- 显示文字：测试语句2
#    |- 标签：END
#    |- 显示文字：测试语句3
#    |- 标签：商店
#    |- 显示商店
#    |- 标签：END
#    |- 标签：贿赂
#    |- 显示文字：测试语句4
#    |- 标签：END
#
#    当玩家面对这个事件时，将显示一个列表，
#    其中显示 交谈、商店、贿赂 三个类型，按shift可以切换
#    若当前显示的为 交谈，则按下确定键后，将显示 测试语句1 和 测试语句2 ，随后结束
#    若当前显示的为 商店，则按下确定键后，将显示商店，随后结束
#    若按下方向键，则玩家正常移动，且自动关闭列表
#
#   注意1：其中的 测试语句3 将不会被执行到。
#   注意2：若删去事件页开头的注释指令，将回归默认的事件页执行方式，
#          即按确定键后，依次执行全部指令
#
#---------------------------------------------------------------------------
# 【联动】
#
# - 由于本插件使用了与【事件消息机制 by老鹰】中的同样格式
#   因此可以用【事件消息机制 by老鹰】中的脚本，来触发对应的事件指令
#
#   但注意，其触发方式为 并行执行
#
#   如 $game_map.events[1].msg("贿赂", true)
#     → 触发 1号事件 的 当前事件页 的 贿赂 标签中的指令
#
#---------------------------------------------------------------------------
# 【兼容性】
#
# - 本插件覆盖了 Game_Map 中的 setup_starting_map_event 方法
#     该方法用于执行当前被标记为启动的事件
#   本插件新增了对事件中指令列表的筛选，选出了与其互动类型相对应的指令
#
# - 本插件覆盖了 Game_Player 中的 update_nonmoving 方法
#     该方法用于在玩家停止移动时，判定事件的接触触发、按键触发等
#   本插件扩展了按键触发部分，先提取位于玩家面前的可触发的事件，
#     随后显示列表，再判定按键并执行事件的触发
#==============================================================================
module EVENT_INTERACT
  #--------------------------------------------------------------------------
  # ● 【常量】定义互动文本的图标索引号
  #--------------------------------------------------------------------------
  SYM_TO_ICON = {
    "交谈" => 4,
    "偷窃" => 482,
    "送礼" => 259,
    "贿赂" => 361,
  }
  #--------------------------------------------------------------------------
  # ● 【常量】当未定义互动文本的图标时，使用这里的图标
  #--------------------------------------------------------------------------
  DEFAULT_ICON = 4
  #--------------------------------------------------------------------------
  # ● 当返回true时，切换到下一个互动类型
  #--------------------------------------------------------------------------
  def self.next_sym?
    Input.trigger?(:A)
  end

  #--------------------------------------------------------------------------
  # ● 提取事件页开头注释指令中预设的互动类型的数组
  #  event 为 Game_Event 的对象
  #--------------------------------------------------------------------------
  def self.extract_syms(event)
    syms = []
    t = EAGLE.event_comment_head(event.list)
    t.scan(/【(.*?)】/mi).each { |ps| syms.push(ps[0]) }
    return syms
  end
  #--------------------------------------------------------------------------
  # ● 清除数据
  #--------------------------------------------------------------------------
  @info = nil
  def self.clear
    @info = nil
  end
  #--------------------------------------------------------------------------
  # ● 重置存储的数据
  #--------------------------------------------------------------------------
  def self.reset(event, syms)
    return if @info != nil && @info[:syms] == syms
    @info = {}
    @info[:event] = event
    @info[:syms] = syms
    @info[:i] = 0
    @info[:i_draw] = -1 # 当前绘制的索引
  end
  #--------------------------------------------------------------------------
  # ● 切换至下一个互动类型
  #--------------------------------------------------------------------------
  def self.next_sym
    return if !self.next_sym?
    @info[:i] += 1
    @info[:i] = 0 if @info[:i] >= @info[:syms].size
  end
  #--------------------------------------------------------------------------
  # ● 获取当前的互动类型
  #--------------------------------------------------------------------------
  def self.sym
    @info[:syms][@info[:i]]
  end
  #--------------------------------------------------------------------------
  # ● 每帧更新（于Spriteset_Map中调用）
  #--------------------------------------------------------------------------
  def self.update(sprite)
    if @info == nil || self.sym == nil || $game_map.interpreter.running?
      return sprite.visible = false
    end
    sprite.visible = true
    redraw(sprite)
  end
  #--------------------------------------------------------------------------
  # ● 每帧重绘
  #--------------------------------------------------------------------------
  def self.redraw(sprite)
    return if @info[:i_draw] == @info[:i]
    @info[:i_draw] = @info[:i]
    syms = @info[:syms]

    # 互动类型文本的文字大小
    sym_font_size = 16
    # 图标的宽高
    icon_wh = 28
    # 两个互动文本之间的间隔值
    sym_offset = 0

    # 预计算每个互动文本的宽度
    ws = []
    _b = Cache.empty_bitmap
    _b.font.size = sym_font_size
    syms.each { |t| r = _b.text_size(t); ws.push(r.width) }

    w = syms.size * (icon_wh + sym_offset) + ws.max + 8
    h = 2 + 12 + 2 + icon_wh
    if sprite.bitmap && (sprite.width != w || sprite.height != h)
      sprite.bitmap.dispose
      sprite.bitmap = nil
    end
    sprite.bitmap ||= Bitmap.new(w, h)
    sprite.bitmap.clear
    sprite.bitmap.font.outline = true
    sprite.bitmap.font.shadow = false
    sprite.bitmap.font.color.alpha = 255
    _y = 0

    # 绘制背景
    sprite.bitmap.fill_rect(0, 0, sprite.width, sprite.height,
      Color.new(0, 0, 0, 160))
    _y += 2

    # 绘制具体的选项
    sprite.bitmap.font.size = sym_font_size
    _x = 4
    _ox = 0
    syms.each_with_index do |t, i|
      # 绘制图标
      icon_index = SYM_TO_ICON[t] || DEFAULT_ICON
      dx = (icon_wh-24) / 2
      dy = (icon_wh-24) / 2
      draw_icon(sprite.bitmap, icon_index, _x+dx, _y+dy, i == @info[:i])
      _x += icon_wh+sym_offset
      # 若当前项被选中，绘制文本
      if i == @info[:i]
        _ox = _x - icon_wh + (icon_wh + ws[i])/2
        _x -= sym_offset
        sprite.bitmap.draw_text(_x, _y, ws[i]+2, icon_wh, t, 1)
        _x += ws[i]+sym_offset
      end
    end
    _y += icon_wh

    # 绘制分割线
    sprite.bitmap.fill_rect(0, _y, sprite.width, 1,
      Color.new(255,255,255,120))
    _y += 2

    # 绘制按键说明文本
    sprite.bitmap.font.size = 12
    sprite.bitmap.font.color.alpha = 255
    sprite.bitmap.draw_text(0, _y, sprite.width, 14,
      " SHIFT →", 0)
    _y += 12

    # 将当前选中的互动类型，移动到行走图下方
    sprite.ox = _ox
    sprite.oy = 0
    sprite.x = @info[:event].screen_x
    sprite.y = @info[:event].screen_y
  end
  #--------------------------------------------------------------------------
  # ● 绘制图标
  #     enabled : 有效的标志。false 的时候使用半透明效果绘制
  #--------------------------------------------------------------------------
  def self.draw_icon(bitmap, icon_index, x, y, enabled = true)
    _bitmap = Cache.system("Iconset")
    rect = Rect.new(icon_index % 16 * 24, icon_index / 16 * 24, 24, 24)
    bitmap.blt(x, y, _bitmap, rect, enabled ? 255 : 120)
  end
end
#=============================================================================
# ■ 读取部分
#=============================================================================
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
  #--------------------------------------------------------------------------
  # ● 读取事件页中指定标签对之间的指令数组
  #--------------------------------------------------------------------------
  def self.find_label_list(msg_label, lists)
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
end
#===============================================================================
# ○ Game_Map
#===============================================================================
class Game_Map
  #--------------------------------------------------------------------------
  # ● （覆盖）检测／设置启动中的地图事件
  #--------------------------------------------------------------------------
  def setup_starting_map_event
    event = @events.values.find {|event| event.starting }
    if event
      list = event.list
      # 新增处理，提取当前互动类型的指令组
      if event.starting_type
        list = EAGLE.find_label_list(event.starting_type, [list])
      end
      @interpreter.setup(list, event.id)
      event.clear_starting_flag  # 将flag重置放到最后处理
    end
    event
  end
end
#===============================================================================
# ○ Game_Event
#===============================================================================
class Game_Event < Game_Character
  attr_reader :starting_type
  #--------------------------------------------------------------------------
  # ● 初始化公有成员变量
  #--------------------------------------------------------------------------
  alias eagle_event_interact_init_public_members init_public_members
  def init_public_members
    eagle_event_interact_init_public_members
    @starting_type = nil
  end
  #--------------------------------------------------------------------------
  # ● 清除启动中的标志
  #--------------------------------------------------------------------------
  alias eagle_event_interact_clear_starting_flag clear_starting_flag
  def clear_starting_flag
    eagle_event_interact_clear_starting_flag
    @starting_type = nil
  end
  #--------------------------------------------------------------------------
  # ● 事件启动（扩展）
  #--------------------------------------------------------------------------
  def start_ex(type = nil)
    return if empty?
    start
    @starting_type = type
  end
end
#===============================================================================
# ○ Game_Player
#===============================================================================
class Game_Player < Game_Character
  #--------------------------------------------------------------------------
  # ● 获取角色当前格子的可触发事件
  #--------------------------------------------------------------------------
  def eagle_check_event_here(triggers)
    e = get_map_event(@x, @y, triggers, false)
    return e
  end
  #--------------------------------------------------------------------------
  # ● 获取角色面前的可触发事件
  #--------------------------------------------------------------------------
  def eagle_check_event_there(triggers)
    x2 = $game_map.round_x_with_direction(@x, @direction)
    y2 = $game_map.round_y_with_direction(@y, @direction)
    e = get_map_event(x2, y2, triggers, true)
    return e unless $game_map.counter?(x2, y2)
    x3 = $game_map.round_x_with_direction(x2, @direction)
    y3 = $game_map.round_y_with_direction(y2, @direction)
    e = get_map_event(x3, y3, triggers, true)
    return e
  end
  #--------------------------------------------------------------------------
  # ● 获取指定触发条件的事件
  #--------------------------------------------------------------------------
  def get_map_event(x, y, triggers, normal)
    $game_map.events_xy(x, y).each do |event|
      if event.trigger_in?(triggers) && event.normal_priority? == normal
        return event
      end
    end
    return nil
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）非移动中的处理
  #     last_moving : 此前是否正在移动
  #--------------------------------------------------------------------------
  def update_nonmoving(last_moving)
    return if $game_map.interpreter.running?
    if last_moving
      $game_party.on_player_walk
      return if check_touch_event
    end
    if movable?
      f = Input.trigger?(:C)
      return if f && get_on_off_vehicle
      return if eagle_check_action_event
    end
    update_encounter if last_moving
  end
  #--------------------------------------------------------------------------
  # ● 检查主动触发事件
  #--------------------------------------------------------------------------
  def eagle_check_action_event
    e = nil
    # 检查位于玩家底层的可以被按键触发的事件
    if e == nil
      e = eagle_check_event_here([0])
    end
    # 检查位于前面的可以被按键触发的事件
    if e == nil
      e = eagle_check_event_there([0,1,2])
    end
    # 如果存在事件
    if e
      # 提取事件页预设的互动列表
      syms = EVENT_INTERACT.extract_syms(e)
      # 重置数据
      EVENT_INTERACT.reset(e, syms)
      # 更新切换
      EVENT_INTERACT.next_sym
      # 判定空格键触发事件
      if Input.trigger?(:C)
        syms.empty? ? e.start : e.start_ex(EVENT_INTERACT.sym)
        $game_map.setup_starting_event
        return true
      end
    else # 如果不存在事件，则清除数据
      EVENT_INTERACT.clear
    end
    # 最后返回 false，代表没有按键触发事件
    return false
  end
end
#===============================================================================
# ○ Spriteset_Map
#===============================================================================
class Spriteset_Map
  #--------------------------------------------------------------------------
  # ● 生成人物精灵
  #--------------------------------------------------------------------------
  alias eagle_event_interact_create_characters create_characters
  def create_characters
    eagle_event_interact_create_characters
    @sprite_trigger_hint = Sprite.new(@viewport1)
    @sprite_trigger_hint.z = 500
  end
  #--------------------------------------------------------------------------
  # ● 释放人物精灵
  #--------------------------------------------------------------------------
  alias eagle_event_interact_dispose_characters dispose_characters
  def dispose_characters
    eagle_event_interact_dispose_characters
    @sprite_trigger_hint.bitmap = nil
    @sprite_trigger_hint.dispose
    EVENT_INTERACT.clear
  end
  #--------------------------------------------------------------------------
  # ● 更新人物精灵
  #--------------------------------------------------------------------------
  alias eagle_event_interact_update_characters update_characters
  def update_characters
    eagle_event_interact_update_characters
    EVENT_INTERACT.update(@sprite_trigger_hint)
  end
end
