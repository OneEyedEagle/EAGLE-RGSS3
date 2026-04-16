#==============================================================================
# ■ 事件互动扩展 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【组件-通用方法汇总 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-EventInteractEX"] = "1.3.0"
#==============================================================================
# - 2026.4.13.23 
#==============================================================================
# - 本插件新增了按空格键触发事件的不同互动
#------------------------------------------------------------------------------
# 【思路】
#
# - 默认的“按确定键”触发事件页，仅单纯执行当前事件页的全部指令，
#   且无法提示玩家，面前是否有可以触发的事件。
#
# - 本插件便增加了一个事件互动列表UI，效仿大部分游戏都有的互动提示。
#
#---------------------------------------------------------------------------
# 【UI交互】
#
# - 显示事件互动列表UI后：
#
#     按 SHIFT键 能够切换到下一个互动。
#
#     按 确定键 执行当前互动的对应事件指令。
#
#     按 方向键 将正常移动玩家，即事件互动列表UI不会干扰玩家的移动。
#
# - 特别的，触发互动不会调整、锁定事件的朝向，请手动添加【朝向玩家】。
#
#---------------------------------------------------------------------------
# 【设置：事件互动列表】
#
# - 当玩家紧挨且朝向事件，该事件当前页的第一条指令为注释，其中包含【xx】类型的文本时，
#   将自动开启事件互动列表。
#
# - 注意：
#
#    ·可重复多次填写【xx】。
#
#    ·未填写【xx】的事件页，依然按照默认方式执行全部指令。
#
#---------------------------------------------------------------------------
# 【设置：事件互动内容】
#
# - 在事件页中，按照与【事件消息机制 by老鹰】中的同样格式进行编写：
#
#   对于注释中的【xx】互动，需要在当前事件页中编写下列指令来设置该互动的内容：
#
#    |-标签：xx
#    |
#    |-...其余事件指令...
#    |
#    |-标签：END
#
# - 注意：
#
#   ·若未编写该样式的内容，则触发【xx】互动时，不会执行任何事件指令。
#
#   ·事件的【转至标签】指令仍然有效，在使用时请注意不要出现循环嵌套。
#
#---------------------------------------------------------------------------
# 【设置：事件互动的出现条件】
#
# - 在【xx】文本中，可以增加 if{cond} 来设置该互动的出现条件。
#
#   当 eval(cond) 返回 true 时，才会显示这个互动。
#   其中可以用 s 代表开关组，v 代表变量组，e 代表当前事件（Game_Event），
#             es 代表 $game_map.events，gp 代表 $game_player 。
#
# - 示例：
#
#    【偷窃if{s[1]}】   → 只有当1号开关开启时，才显示偷窃指令。
#
#---------------------------------------------------------------------------
# 【示例】
#
#  - 当前地图的 1 号事件的第 1 页中指令列表（事件页的出现条件已经满足）
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
#      其中显示 交谈、商店、贿赂 三个互动类型，按shift可以切换。
#
#    若当前显示的为 交谈，则按下确定键后，将显示 测试语句1 和 测试语句2，结束；
#    若当前显示的为 商店，则按下确定键后，将显示商店，结束；
#    若按下方向键，则玩家正常移动，且自动关闭列表。
#
#   注意1：其中的 测试语句3 将永远不会被执行。
#   注意2：若删去事件页开头的注释指令，将回归默认的事件页执行方式，
#          即按确定键后，依次执行全部指令。
#
#---------------------------------------------------------------------------
# 【联动】
#
# - 由于本插件使用了与【事件消息机制 by老鹰】中的同样格式，
#   因此可以用【事件消息机制 by老鹰】中的脚本，来触发对应的事件指令。
#
#   但注意，其触发方式为并行执行。
#
#  - 如 $game_map.events[1].msg("贿赂", true)
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
#
#==============================================================================
module EVENT_INTERACT
  #--------------------------------------------------------------------------
  # ●【常量】互动文本相关
  #--------------------------------------------------------------------------
  SYM_TO_ICON = {
    "交谈" => 4,
    "偷窃" => 482,
    "送礼" => 259,
    "贿赂" => 361,
    "推" => 11,
    "拉" => 11,
  }
  # 如果没定义，则显示这里的默认图标
  DEFAULT_ICON = 4
  
  #--------------------------------------------------------------------------
  # ●【常量】互动列表相关
  #--------------------------------------------------------------------------
  # 设置互动列表的显示模式
  #  0 - 横向排列   1 - 纵向排列
  SYM_LIST_TYPE = 1
  
  # 互动列表的文字大小
  SYM_FONT_SIZE = 18
  
  # 互动列表的显示位置
  #  0 - 事件下方   1 - 事件上方   2 - 事件右侧
  SYM_LIST_POS = 2
  
  # 切换按键提示文本
  SYM_HELP_TEXT_NEXT = "↑↓ SHIFT"
  # 切换按键提示文本的文字大小
  SYM_HELP_FONT_SIZE = 12
  
  #（SYM_LIST_TYPE=0 时生效）每一行的最大显示数量
  #  若为 nil，则不换行
  SYM_EACH_LINE_MAX = nil
  
  #--------------------------------------------------------------------------
  # ●【判定】切换互动
  #--------------------------------------------------------------------------
  # 返回true时，切换到下一个互动
  def self.next_sym?
    return true if $imported["EAGLE-MouseEX"] and MOUSE_EX.scroll_down?
    Input.trigger?(:A)
  end
  
  # 返回true时，切换到上一个互动
  def self.prev_sym?
    return true if $imported["EAGLE-MouseEX"] and MOUSE_EX.scroll_up?
    return false
  end
  
  #--------------------------------------------------------------------------
  # ● 通用方法
  #--------------------------------------------------------------------------
  # 提取事件页开头注释指令中预设的互动类型的数组
  def self.extract_syms(event)  # Game_Event
    syms = []
    t = EAGLE_COMMON.event_comment_head(event.list)
    t.scan(/【(.*?)】/mi).each do |ps|
      _t = ps[0]
      _t.gsub!(/ *(?i:if){(.*?)} */) { "" }
      next if $1 && EAGLE_COMMON.eagle_eval($1, {:event => event}) == false
      syms.push(_t)
    end
    return syms
  end
  
  # 获取指定互动的图标
  def self.icon(t)
    SYM_TO_ICON[t.to_s] || DEFAULT_ICON
  end
end

module EVENT_INTERACT
  # 清除
  @info = nil
  def self.clear
    @info = nil
  end

  # 重置
  def self.reset(event, syms)
    # 如果没变化，就不重置
    if @info && @info[:event].id == event.id && @info[:syms].size == syms.size &&
       @info[:syms].all? { |s| syms.include?(s) }
      return false
    end
    @info = {}
    @info[:event] = event
    @info[:syms] = syms
    @info[:i] = 0
    @info[:i_draw] = -1 # 当前绘制的索引
    return true
  end
  
  # 更新切换
  def self.next_sym
    if self.next_sym?
      @info[:i] += 1
      @info[:i] = 0 if @info[:i] >= @info[:syms].size
    elsif self.prev_sym?
      @info[:i] -= 1
      @info[:i] = @info[:syms].size - 1 if @info[:i] < 0
    end
  end

  # 获取当前互动
  def self.sym
    @info[:syms][@info[:i]]
  end

  # 每帧更新（于Spriteset_Map中调用）
  def self.update(sprite, event_sprites)
    if @info == nil || self.sym == nil || $game_map.interpreter.running?
      return sprite.visible = false
    end
    sprite.visible = true
    case SYM_LIST_TYPE
    when 0
      redraw_type0(sprite)
    when 1
      redraw_type1(sprite)
    end
    update_position(sprite, event_sprites)
  end
  
  # 重绘：横向排布模式
  def self.redraw_type0(sprite)
    # 如果当前索引没变，则不用重绘
    return if @info[:i_draw] == @info[:i]
    @info[:i_draw] = @info[:i]
    # 获取当前事件的全部互动
    syms = @info[:syms]
    # 如果互动数目大于1，则需要绘制按键切换的提示文本
    flag_draw_hint = syms.size > 1
    # 互动类型文本的文字大小
    sym_font_size = SYM_FONT_SIZE
    # 图标的宽高
    icon_wh = 28
    # 两个互动文本之间的间隔值
    sym_offset = 0
    # 每行最大数量
    max_each_line = SYM_EACH_LINE_MAX
    # 行间距
    offset_line = 2
    # 左右的留空
    padding = 3
    # 上下的留空
    padding_ud = 2

    # 预计算每个互动文本的宽度
    ws = []
    _b = Cache.empty_bitmap
    _b.font.size = sym_font_size
    syms.each { |t| r = _b.text_size(t); ws.push(r.width) }

    # 计算互动文本占据的宽高
    w = h = 0
    # 存在分行
    if max_each_line
      ws_line = ws.each_slice(max_each_line).to_a
      # 计算每一行的最大宽度
      _ws_max = []
      ws_line.each { |_ws|
        _w = _ws.size * (icon_wh + sym_offset) + _ws.max + padding * 2
        _ws_max.push( _w )
      }
      # 计算全部的最大宽度
      w = _ws_max.max + padding * 2
      # 计算总体高度
      h = icon_wh * ws_line.size + offset_line * (ws_line.size - 1)
      h += padding_ud * 2
    end
    # 只有一行
    if max_each_line == nil
      # 总的宽度 = 最大互动文本的宽度 + 图标数目*图标宽度
      w = syms.size * (icon_wh + sym_offset) + ws.max + padding * 2
      # 假定：文本高度 小于 图标的高度
      h = padding_ud + icon_wh + padding_ud
    end
    h += (SYM_HELP_FONT_SIZE+4) if flag_draw_hint

    # 重设位图
    if sprite.bitmap && (sprite.width != w || sprite.height != h)
      sprite.bitmap.dispose
      sprite.bitmap = nil
    end
    sprite.bitmap ||= Bitmap.new(w, h)
    sprite.bitmap.clear
    sprite.bitmap.font.outline = true
    sprite.bitmap.font.shadow = false
    sprite.bitmap.font.color.alpha = 255

    # 绘制用y
    _y = 0

    # 绘制背景
    _h = h
    _h -= (SYM_HELP_FONT_SIZE+4) if flag_draw_hint
    sprite.bitmap.fill_rect(0, 0, sprite.width, _h, Color.new(0,0,0,160))
    _y += 2 # 顶部的空白

    # 绘制互动文本
    sprite.bitmap.font.size = sym_font_size
    _x = 2
    _ox = 0
    syms.each_with_index do |t, i|
      # 绘制图标
      icon_index = self.icon(t)
      dx = (icon_wh-24) / 2
      dy = (icon_wh-24) / 2
      draw_icon(sprite.bitmap, icon_index, _x+dx, _y+dy, i == @info[:i])
      _x += icon_wh+sym_offset
      # 若当前项被选中，绘制文本
      if i == @info[:i]
        _ox = _x - icon_wh + (icon_wh + ws[i])/2
        _x -= sym_offset
        sprite.bitmap.draw_text(_x, _y, ws[i]+24, icon_wh, t, 0)
        _x += ws[i]+sym_offset
      end
      # 处理换行
      if max_each_line
        if i != (syms.size - 1) && (i + 1) % max_each_line == 0
          _x = 2
          _y += icon_wh + offset_line
        end
      end
    end
    _y += icon_wh

    if flag_draw_hint
      # 绘制按键说明文本
      sprite.bitmap.font.size = SYM_HELP_FONT_SIZE
      sprite.bitmap.font.color.alpha = 255
      sprite.bitmap.draw_text(0, _y-4, sprite.width, SYM_HELP_FONT_SIZE+2,
        SYM_HELP_TEXT_NEXT, 2)
    end

    # 将当前选中的互动类型，移动到行走图下方
    sprite.ox = _ox
    sprite.oy = 0
  end
  
  # 重绘：纵向排布模式
  def self.redraw_type1(sprite)
    # 如果当前索引没变，则不用重绘
    return if @info[:i_draw] == @info[:i]
    @info[:i_draw] = @info[:i]
    # 获取当前事件的全部互动
    syms = @info[:syms]
    # 如果互动数目大于1，则需要绘制按键切换的提示文本
    flag_draw_hint = syms.size > 1
    # 互动类型文本的文字大小
    sym_font_size = SYM_FONT_SIZE
    
    # 预计算每个互动文本的宽度
    ws = []; hs = []
    _b = Cache.empty_bitmap
    _b.font.size = sym_font_size
    syms.each do |t| 
      r = _b.text_size(t)
      ws << r.width + 24
      hs << (r.height > 24 ? r.height : 24)
    end
    
    # 计算互动文本占据的宽高
    w = ws.max + 4 + 8
    h = hs.inject(0) { |s, v| s += v } + 4 + 4
    h += (SYM_HELP_FONT_SIZE+4) if flag_draw_hint
    
    # 重设位图
    if sprite.bitmap && (sprite.width != w || sprite.height != h)
      sprite.bitmap.dispose
      sprite.bitmap = nil
    end
    sprite.bitmap ||= Bitmap.new(w, h)
    sprite.bitmap.clear
    sprite.bitmap.font.outline = true
    sprite.bitmap.font.shadow = false
    sprite.bitmap.font.color.alpha = 255
    
    _y = 4; _oy = 0
    
    # 绘制背景
    _r = Rect.new(2,0,w,h)
    _r.height -= (SYM_HELP_FONT_SIZE+4) if flag_draw_hint
    sprite.bitmap.gradient_fill_rect(_r, Color.new(0,0,0,220), Color.new(0,0,0,150))
    sprite.bitmap.fill_rect(0,0,2,_r.height,Color.new(255,255,255,200))
    
    # 绘制互动文本
    sprite.bitmap.font.size = sym_font_size
    syms.each_with_index do |t, i|
      _x = 4
      icon_index = self.icon(t)
      # 若当前项被选中
      if i == @info[:i]
        sprite.bitmap.font.color = Color.new(255,255,255,255)
        _oy = _y
      else
        sprite.bitmap.font.color = Color.new(150,150,150,255)
      end
      draw_icon(sprite.bitmap, icon_index, _x, _y+(hs[i]-24)/2, i == @info[:i])
      _x += 24 + 2
      sprite.bitmap.draw_text(_x, _y, ws[i]+24, hs[i], t, 0)
      _y += hs[i]
    end
    
    if flag_draw_hint  # 按键提示文本
      sprite.bitmap.font.size = SYM_HELP_FONT_SIZE
      sprite.bitmap.font.color = Color.new(255,255,255,255)
      sprite.bitmap.draw_text(0, _y-2, sprite.width, SYM_HELP_FONT_SIZE+2,
        SYM_HELP_TEXT_NEXT, 1)
    end
    
    # 将当前选中的互动类型，移动到行走图下方
    sprite.ox = 0
    sprite.oy = _oy
  end
  
  # 更新位置
  def self.update_position(sprite, event_sprites)
    sprite.x = @info[:event].screen_x
    sprite.y = @info[:event].screen_y
    sprite_e = nil
    event_sprites.each {|s| break sprite_e = s if s.character == @info[:event]}
    if sprite_e
      case SYM_LIST_POS
      when 0
      when 1
        sprite.y = sprite.y - sprite.height - sprite_e.oy
      when 2
        sprite.ox = 0
        sprite.x = sprite.x + sprite_e.ox
        sprite.y = sprite.y - sprite_e.height
      end
    end
    if sprite.x + sprite.width > Graphics.width
      sprite.x = Graphics.width - sprite.width
    end
    if sprite.y + sprite.height > Graphics.height
      sprite.y = Graphics.height - sprite.height
    end
  end
  
  # 绘制图标
  def self.draw_icon(bitmap, icon_index, x, y, enabled = true)
    _bitmap = Cache.system("Iconset")
    rect = Rect.new(icon_index % 16 * 24, icon_index / 16 * 24, 24, 24)
    bitmap.blt(x, y, _bitmap, rect, enabled ? 255 : 120)
  end
end

#===============================================================================
# ○ Game_Interpreter
#===============================================================================
class Game_Interpreter
  attr_reader :eagle_sym
  # 添加标签
  alias eagle_event_interact_command_118 command_118
  def command_118
    eagle_event_interact_command_118
    event_interact_finish if @eagle_sym && @params[0] == 'END'
  end
  
  # 转至互动
  def event_interact_search(sym)
    @eagle_sym = sym
    @list.size.times do |i|
      if @list[i].code == 118 && @list[i].parameters[0] == @eagle_sym
        @index = i
        return
      end
    end
    event_interact_finish if @eagle_sym # 若未找到互动，则直接结束
  end

  # 结束互动
  def event_interact_finish
    @index = @list.size
    @eagle_sym = nil
  end
end

#===============================================================================
# ○ Game_Map
#===============================================================================
class Game_Map
  # （覆盖）检测／设置启动中的地图事件
  def setup_starting_map_event
    event = @events.values.find {|event| event.starting }
    if event
      @interpreter.setup(event.list, event.id)
      # 新增处理，跳转到当前互动类型的指令组
      @interpreter.event_interact_search(event.starting_type)
      # 将flag重置放到最后处理
      event.clear_starting_flag
    end
    event
  end
end

#===============================================================================
# ○ Game_Event
#===============================================================================
class Game_Event < Game_Character
  attr_reader  :starting_type
  # 清除启动中的标志
  alias eagle_event_interact_clear_starting_flag clear_starting_flag
  def clear_starting_flag
    eagle_event_interact_clear_starting_flag
    @starting_type = nil
  end

  # 事件启动（扩展）
  def start_ex(type = nil)
    return if empty?
    @starting_type = type
    @starting = true
    @locked = true
  end
end

#===============================================================================
# ○ Game_Player
#===============================================================================
class Game_Player < Game_Character
  # 获取指定触发条件的事件
  def eagle_get_map_event(x, y, triggers, normal)
    $game_map.events_xy(x, y).each do |event|
      if event.trigger_in?(triggers) &&
         (normal == nil || event.normal_priority? == normal) &&
         event.list.size > 1  # 事件页不为空
        return event
      end
    end
    return nil
  end

  # 获取角色当前格子的可触发事件
  def eagle_get_event_here(triggers)
    return eagle_get_map_event(@x, @y, triggers, nil)
  end

  # 获取角色面前的可触发事件
  def eagle_get_event_there(triggers)
    x2 = $game_map.round_x_with_direction(@x, @direction)
    y2 = $game_map.round_y_with_direction(@y, @direction)
    e = eagle_get_map_event(x2, y2, triggers, true)
    return e if e
    return nil unless $game_map.counter?(x2, y2)
    x3 = $game_map.round_x_with_direction(x2, @direction)
    y3 = $game_map.round_y_with_direction(y2, @direction)
    e = eagle_get_map_event(x3, y3, triggers, true)
    return e
  end

  # （覆盖）非移动中的处理
  #     last_moving : 此前是否正在移动
  def update_nonmoving(last_moving)
    return if $game_map.interpreter.running?
    if last_moving
      $game_party.on_player_walk
      return if check_touch_event
    end
    if movable? # 不再统一判定按键，改为各自处理
      return if Input.trigger?(:C) && get_on_off_vehicle
      return if eagle_check_action_event # 将默认的替换成新的方法
    end
    update_encounter if last_moving
  end

  # 检查主动触发事件
  def eagle_check_action_event
    e = nil
    # 检查位于玩家底层的可以被按键触发的事件
    e = eagle_get_event_here([0]) if e == nil
    # 检查位于前面的可以被按键触发的事件
    e = eagle_get_event_there([0,1,2]) if e == nil
    # 如果存在事件
    if e
      @last_e = e
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
    else # 如果之前有，现在没有事件，则清除数据
      if @last_e
        EVENT_INTERACT.clear
        @last_e = nil
      end
    end
    # 最后返回 false，代表没有按键触发事件
    return false
  end
end

#===============================================================================
# ○ 兼容 Sapphire Action System IV By Khas Arcthunder - arcthunder.site40.net
#===============================================================================
$khas_awesome ||= []
FLAG_khas_SAS = $khas_awesome.any? { |s| s[0] == "Sapphire Action System" }
if FLAG_khas_SAS
class Game_Player < Game_Character
  # 获取指定触发条件的事件
  def eagle_get_map_event(px, py, triggers, normal)
    for event in $game_map.events.values
      if (event.px - px).abs <= event.cx && (event.py - py).abs <= event.cy
        if event.trigger_in?(triggers) &&
           (normal == nil || event.normal_priority? == normal) &&
           event.list.size > 1  # 事件页不为空
          return event
        end
      end
    end
    return nil
  end

  # 获取角色当前格子的可触发事件
  def eagle_get_event_here(triggers)
    return eagle_get_map_event(@px, @py, triggers, nil)
  end

  # 获取角色面前的可触发事件
  def eagle_get_event_there(triggers)
    fx = @px+Trigger_Range[@direction][0]
    fy = @py+Trigger_Range[@direction][1]
    e = eagle_get_map_event(fx, fy, triggers, true)
    return e if e
    if $game_map.pixel_table[fx,fy,5] == 1
      fx += Counter_Range[@direction][0]
      fy += Counter_Range[@direction][1]
      e = eagle_get_map_event(fx, fy, triggers, true)
      return e if e
    end
    return nil
  end
end
end

#===============================================================================
# ○ 兼容 像素级移动 by 老鹰
#===============================================================================
if $imported["EAGLE-PixelMove"]
class Game_Player < Game_Character
  # 获取角色当前格子的可触发事件
  def eagle_get_event_here(triggers)
    $game_map.events_rect(get_collision_rect(false)).each do |event|
      next if event.tile? && event.priority_type == 0  # 去除图块事件
      if event.trigger_in?(triggers) && # 去除了与人物同层的限制
         event.list.size > 1  # 事件页不为空
        return event
      end
    end
    return nil
  end

  # 获取角色面前的可触发事件
  def eagle_get_event_there(triggers)
    x_p, y_p = get_collision_xy(@direction)
    x2 = $game_map.round_x_with_direction(x_p, @direction)
    y2 = $game_map.round_y_with_direction(y_p, @direction)
    e = eagle_get_map_event(x2, y2, triggers, true)
    return e if e
    x2_rgss, e = PIXEL_MOVE.unit2rgss(x2)
    y2_rgss, e = PIXEL_MOVE.unit2rgss(y2)
    return unless $game_map.counter?(x2_rgss, y2_rgss)
    # 柜台属性：向前方推进 RGSS 中的一格来查找事件
    x3 = $game_map.round_x_with_direction_n(x2, @direction,
      PIXEL_MOVE.pixel2unit(32))
    y3 = $game_map.round_y_with_direction_n(y2, @direction,
      PIXEL_MOVE.pixel2unit(32))
    e = eagle_get_map_event(x3, y3, triggers, true)
    return e
  end
end
end

#===============================================================================
# ○ Spriteset_Map
#===============================================================================
class Spriteset_Map
  # 生成人物精灵
  alias eagle_event_interact_create_characters create_characters
  def create_characters
    eagle_event_interact_create_characters
    @sprite_trigger_hint = Sprite.new(@viewport1)
    @sprite_trigger_hint.z = 500
  end

  # 释放人物精灵
  alias eagle_event_interact_dispose_characters dispose_characters
  def dispose_characters
    eagle_event_interact_dispose_characters
    EVENT_INTERACT.clear
    @sprite_trigger_hint.bitmap.dispose if @sprite_trigger_hint.bitmap
    @sprite_trigger_hint.dispose
  end

  # 更新人物精灵
  alias eagle_event_interact_update_characters update_characters
  def update_characters
    eagle_event_interact_update_characters
    EVENT_INTERACT.update(@sprite_trigger_hint, @character_sprites)
  end
end
