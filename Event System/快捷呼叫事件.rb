#==============================================================================
# ■ 快捷呼叫事件 by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【组件-通用方法汇总 by老鹰】与
#  【组件-位图绘制转义符文本 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-EventBar"] = true
#==============================================================================
# - 2022.2.8.20
#==============================================================================
if $imported["EAGLE-CommonMethods"] == nil
  p "警告：没有放在【组件-通用方法汇总 by老鹰】之下，继续使用一定会报错！"
end
#==============================================================================
# - 本插件新增了在地图上时，显示在玩家头顶的呼叫指定事件页的UI
#---------------------------------------------------------------------------
# 【UI介绍】
#
# - 在地图上时，当玩家一段时间未移动，且不存在事件执行，则显示一个按键提示文本
#   默认提示文本为 按住 ALT 开启功能列表
#
# - 当按住ALT键时，将在玩家头顶显示当前绑定的指令
#   同时将在屏幕底部显示对应的帮助文本
#
# - 当按下 左右方向键 时，将进行指令之间的切换
#   当按下 上方向键 时，将执行当前指令
#   当松开 ALT键 时，将关闭该UI（但会保存当前选项位置）
#
# - 指令的本质为呼叫预设的某一个事件页（任意地图的某个事件的某页/公共事件）
#   在执行过程中，和当前地图的事件的执行保持一致
#
#---------------------------------------------------------------------------
# 【指令新增：征用滚动文本】
#
# - 当 S_ID_SCROLL_TEXT 号开关开启时，
#   事件的【显示滚动文本】将被替换为本脚本的【事件绑定】
#
# - 具体编写格式如下：
#
#   第一行的文本将作为指令的【名称】
#   第二行的文本将作为【参数的标签组合】
#
#   其中 参数的标签组合 可以为以下语句的任意组合，用空格分隔
#         等号左右可以添加冗余空格
#
#      icon=数字 → 所对应的图标ID
#
#      mid=数字  → 所绑定的事件的所在地图的ID
#                    数字 替换为编辑器中的地图序号
#                 （若填入 0，或不写该语句，则取当前地图）
#
#      eid=数字  → 【必须填写】所绑定的事件的ID
#                    数字 替换为编辑器中的事件序号
#
#      pid=数字  → 所绑定的事件的页号
#                    数字 替换为事件编辑器中的页号
#                 （若填入 0，或不写该语句，则取符合出现条件的最大页号）
#
#      t=数字   → 在执行一次后，需要等待的时间（帧数），倒计时归零后才能再次执行
#                 （若填入 0，或不写该语句，则没有冷却时间）
#
#   （若使用了【事件互动扩展 by老鹰】，可使用下述标签）
#      sym=字符串 → 所绑定的事件的被调用的互动
#                    字符串 替换为目标事件中的互动标签
#                 （若不写该语句，默认执行整个事件页）
#
#   第三行及之后的文本将作为帮助文本（可使用转义符）
#
# - 示例1：
#     事件指令【显示滚动文本】中，填入 =begin 和 =end 之间的内容
=begin
你好鸭！
icon=228 eid=1
Hello World!
=end
#     则会绑定一个 显示228号图标、执行当前地图的1号事件 的指令
#
# - 示例2：
#     事件指令【显示滚动文本】中，填入 =begin 和 =end 之间的内容
=begin
思考
icon=4 mid=1 eid=4 sym=灵感 t=60
想一想现在还有没有什么没干完的事情呢？
可能的确还有什么事情？
=end
#     则会绑定一个 显示4号图标、执行1号地图的4号事件当前页中的【灵感】互动 的指令，
#       且执行一次后需要冷却1秒
#     若没有使用【事件互动扩展 by老鹰】，则为执行当前页的全部内容
#
#---------------------------------------------------------------------------
# 【指令新增：全局脚本】
#
# - 利用脚本新增指令（可以在任意位置调用）
#
#      EVENTBAR.bind(name, params, help = nil)
#
#   其中 name 为指令名称的字符串，如："示例指令"
#   其中 params 为指令参数的Hash，和上述一致，但键值为符号类型，值为数字或字符串
#          如： { :mid => 1, :eid => 1, :sym => "灵感" }
#   其中 help 为帮助文本的字符串（可省略）
#          如："这里写帮助文本\n还支持手动换行啦"
#
# - 示例1：
#      EVENTBAR.bind("你好鸭！", {:icon=>228, :eid=>1}, "Hello World!")
#
# - 示例2：
#      EVENTBAR.bind("思考", {:icon=>4, :mid=>1, :eid=>4, :sym=>"灵感", :t=>60},
#            "想一想现在还有没有什么没干完的事情呢？\n可能的确还有什么事情？")
#
#---------------------------------------------------------------------------
# 【指令删除：全局脚本】
#
# - 利用脚本删除指令（可以在任意位置调用）
#
#      EVENTBAR.unbind(name)
#
#   其中 name 为指令名称的字符串，如："示例指令"
#
# - 示例1：
#      EVENTBAR.unbind("你好鸭！")
#
# - 示例2：
#      EVENTBAR.unbind("思考")
#
#---------------------------------------------------------------------------
# 【指令更新】
#
# - 按照【指令新增】进行编写绑定时，
#   若已经存在同名的指令，则会将传入的参数更新到已有指令中，
#   若参数有新的设置，将覆盖旧的；若未设置，则保留原有设置
#
# - 注意：新的帮助文本将完全覆盖旧的，请自己进行字符串的增删
#
# - 可以利用 EVENTBAR.get(name) 获取指定指令的参数Hash，若不存在该指令则返回nil
#   其中 :help 键值对应的为帮助文本字符串
#
#==============================================================================
module EVENTBAR
  #--------------------------------------------------------------------------
  # ● 【常量】当该开关开启时，【显示滚动文本】将被替换为绑定事件指令
  # 推荐给该开关命名为：滚动文本→快捷呼叫事件
  #--------------------------------------------------------------------------
  S_ID_SCROLL_TEXT = 25

  #--------------------------------------------------------------------------
  # ● 【常量】当该帧数时间内，玩家未移动，则显示开启UI的提示文本
  #--------------------------------------------------------------------------
  HINT_SHOW_TIME = 120
  #--------------------------------------------------------------------------
  # ● 【常量】提示打开UI的文本
  #--------------------------------------------------------------------------
  HINT_TEXT_OPEN = "- 按住 ALT 开启功能列表 -"
  #--------------------------------------------------------------------------
  # ● 【常量】提示打开UI的文本的字体大小
  #--------------------------------------------------------------------------
  HINT_FONT_SIZE = 12
  #--------------------------------------------------------------------------
  # ● 【常量】UI内的按键提示文本
  #--------------------------------------------------------------------------
  HINT_TEXT_KEY = "←上一项 | ↑执行 | →下一项"
  HINT_TEXT_CLOSE = "- 松开ALT键关闭 -"
  #--------------------------------------------------------------------------
  # ● 【常量】UI内按键提示文本的宽度
  #--------------------------------------------------------------------------
  HINT_TEXT_WIDTH = Graphics.width / 2 + 100
  #--------------------------------------------------------------------------
  # ● 【常量】UI内帮助文本的字体大小
  #--------------------------------------------------------------------------
  HELP_FONT_SIZE = 16
  #--------------------------------------------------------------------------
  # ● 【常量】帮助文本的开头
  # 其中 <name> 将被替换为名称
  #--------------------------------------------------------------------------
  HELP_TEXT_HEAD = " - \\c[17]<name>\\c[0]"
  #--------------------------------------------------------------------------
  # ● 【常量】指令增减的提示文本的字体大小
  #--------------------------------------------------------------------------
  LOG_FONT_SIZE = 16
  #--------------------------------------------------------------------------
  # ● 【常量】新增指令的提示文本
  # 其中 <name> 将被替换为名称
  #--------------------------------------------------------------------------
  LOG_TEXT_NEW = "指令新增：<name>"
  #--------------------------------------------------------------------------
  # ● 【常量】删除指令的提示文本
  # 其中 <name> 将被替换为名称
  #--------------------------------------------------------------------------
  LOG_TEXT_DEL = "指令删除：<name>"
  #--------------------------------------------------------------------------
  # ● 【常量】更新指令的提示文本
  # 其中 <name> 将被替换为名称
  #--------------------------------------------------------------------------
  LOG_TEXT_UPD = "更新：<name>"
  #--------------------------------------------------------------------------
  # ● 【常量】提示文本的持续显示时间
  #--------------------------------------------------------------------------
  LOG_TIME_SHOW = 120
  #--------------------------------------------------------------------------
  # ● 【常量】UI内指令名称的字体大小
  #--------------------------------------------------------------------------
  NAME_FONT_SIZE = 18

  #--------------------------------------------------------------------------
  # ● 打开UI？
  #--------------------------------------------------------------------------
  def self.call?
    Input.trigger?(:ALT)
  end
  #--------------------------------------------------------------------------
  # ● 关闭UI？
  #--------------------------------------------------------------------------
  def self.close?
    !Input.press?(:ALT) ||  # 松开alt键
    unable? # 不满足开启条件
  end
  #--------------------------------------------------------------------------
  # ● 不可开启UI？
  #--------------------------------------------------------------------------
  def self.unable?
    $game_system.eagle_eventbar.empty? || # 无绑定事件
    $game_map.interpreter.running? || # 地图上正在执行事件
    $game_message.busy?  # 对话框在执行
  end

  #--------------------------------------------------------------------------
  # ● 绑定指令
  #--------------------------------------------------------------------------
  def self.bind(name, params, help = nil)
    i = self.find(name)
    if i
      $game_system.eagle_eventbar[i][1].merge!(params)
      $game_system.eagle_eventbar[i][1][:help] = help if help
      check_params($game_system.eagle_eventbar[i][1])
      new_log(name, :update)
    else
      f = bind_init(params)
      if f == false
        p "错误！在为【快捷呼叫事件 by老鹰】进行指令绑定时，发现参数错误，请检查！"
        p "当前传入参数如下："
        p " - 名称：#{name}"
        p " - 参数组：#{params}"
        p " - 帮助文本：#{help || '无'}"
        p "有可能是未传入 eid 参数！"
        return
      end
      check_params(params)
      params[:help] = help if help
      $game_system.eagle_eventbar.push([name, params])
      new_log(name, :new)
    end
  end
  #--------------------------------------------------------------------------
  # ● 初始化参数Hash，确保部分参数存在
  #--------------------------------------------------------------------------
  def self.bind_init(params)
    params[:icon] ||= 0 # 图标
    params[:mid] ||= 0
    #params[:eid]
    return false if params[:eid] == nil
    params[:pid] ||= 0
    #params[:sym]
    params[:t] ||= 0  # 使用后的冷却时间（帧）
    params[:c] = 0    # 用于倒计时计数
    return true
  end
  #--------------------------------------------------------------------------
  # ● 确保参数格式
  #--------------------------------------------------------------------------
  def self.check_params(params)
    params[:icon] = params[:icon].to_i
    params[:mid] = params[:mid].to_i
    params[:eid] = params[:eid].to_i
    params[:pid] = params[:pid].to_i
    params[:t] = params[:t].to_i
  end
  #--------------------------------------------------------------------------
  # ● 删去某个指令
  #--------------------------------------------------------------------------
  def self.unbind(name)
    i = self.find(name)
    return if i == nil
    $game_system.eagle_eventbar.delete_at(i)
    new_log(name, :delete)
  end
  #--------------------------------------------------------------------------
  # ● 添加日志
  #--------------------------------------------------------------------------
  @logs = []
  class << self; attr_reader :logs; end
  def self.new_log(name, type)
    case type
    when :new
      t = LOG_TEXT_NEW.gsub(/<name>/) { name }
    when :delete
      t = LOG_TEXT_DEL.gsub(/<name>/) { name }
    when :update
      t = LOG_TEXT_UPD.gsub(/<name>/) { name }
    end
    @logs.push(t) if t
  end
  #--------------------------------------------------------------------------
  # ● 查找某个指令的index
  #--------------------------------------------------------------------------
  def self.find(name)
    $game_system.eagle_eventbar.each_with_index { |item, i|
      return i if item[0] == name
    }
    return nil
  end
  #--------------------------------------------------------------------------
  # ● 获取某个指令的参数
  #--------------------------------------------------------------------------
  def self.get(name)
    i = find(name)
    return nil if i == nil
    $game_system.eagle_eventbar[i][1]
  end
  #--------------------------------------------------------------------------
  # ● 获取事件页
  #--------------------------------------------------------------------------
  def self.get_event_list(h)
    event = nil
    h[:mid] = $game_map.map_id if h[:mid].nil? || h[:mid] == 0
    # 公共事件
    if h[:mid] == -1
      event = $data_common_events[h[:eid]]
      return event.list, 0
    end
    # 地图上的事件
    if h[:mid] != $game_map.map_id
      map = EAGLE_COMMON.get_map_data(h[:mid])
      event_data = map.events[h[:eid]] rescue return
      event = Game_Event.new(h[:mid], event_data)
    else
      event = $game_map.events[h[:eid]] rescue return
    end
    page = nil
    if h[:pid] == nil || h[:pid] == 0
      page = event.find_proper_page
    else
      page = event.event.pages[h[:pid]-1] rescue return
    end
    return page.list, h[:eid]
  end
  #--------------------------------------------------------------------------
  # ● 清除
  #--------------------------------------------------------------------------
  def self.clear
    $game_system.eagle_eventbar_active = false
  end
  #--------------------------------------------------------------------------
  # ● 更新（绑定到Spriteset_Map）
  #--------------------------------------------------------------------------
  @fiber = nil
  def self.update(spriteset)
    update_each_command
    if @fiber
      @fiber.resume
    else
      return if unable?
      @fiber = Fiber.new { fiber_main(spriteset) } if self.call?
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新每条绑定事件
  #--------------------------------------------------------------------------
  def self.update_each_command
    $game_system.eagle_eventbar.each do |item|
      name = item[0]
      item[1][:c] -= 1 if item[1][:c] > 0
    end
  end
  #--------------------------------------------------------------------------
  # ● fiber主循环
  #--------------------------------------------------------------------------
  def self.fiber_main(spriteset)
    spriteset.visible = true
    show
    spriteset.redraw
    f = nil
    while true
      Fiber.yield
      break if self.close?
      f = update_cursor
      spriteset.redraw if f == :redraw
      break if f == :active
    end
    spriteset.visible = false
    # 如果触发了事件，则挂起一段时间，防止玩家响应按键
    5.times { Fiber.yield } if f == :active
    hide
    @fiber = nil
  end
  #--------------------------------------------------------------------------
  # ● 当前选中项在数组中的index
  #--------------------------------------------------------------------------
  def self.index
    @index
  end
  #--------------------------------------------------------------------------
  # ● 显示
  #--------------------------------------------------------------------------
  def self.show
    $game_system.eagle_eventbar_active = true
    @index = 0
    if $game_system.eagle_eventbar_last
      i = self.find($game_system.eagle_eventbar_last)
      @index = i if i
      $game_system.eagle_eventbar_last = nil
    end
  end
  #--------------------------------------------------------------------------
  # ● 隐藏
  #--------------------------------------------------------------------------
  def self.hide
    $game_system.eagle_eventbar_active = false
    $game_system.eagle_eventbar_last = $game_system.eagle_eventbar[@index][0]
  end
  #--------------------------------------------------------------------------
  # ● 更新按键
  #--------------------------------------------------------------------------
  def self.update_cursor
    if Input.trigger?(:LEFT)
      Sound.play_cursor
      @index = (@index - 1) % $game_system.eagle_eventbar.size
      return :redraw
    elsif Input.trigger?(:RIGHT)
      Sound.play_cursor
      @index = (@index + 1) % $game_system.eagle_eventbar.size
      return :redraw
    elsif Input.trigger?(:UP) #|| Input.trigger?(:DOWN)
      return :active if process_ok
    end
    return nil
  end
  #--------------------------------------------------------------------------
  # ● 处理执行
  #--------------------------------------------------------------------------
  def self.process_ok
    item = $game_system.eagle_eventbar[@index]
    if item[1][:c] > 0
      Sound.play_buzzer
      return false
    end
    # 记录要被执行的绑定事件的name
    $game_system.eagle_eventbar_cur = item[0]
    # 增加冷却倒计时
    item[1][:c] = item[1][:t] if item[1][:t] > 0
    Sound.play_ok
    return true
  end
end
#===============================================================================
# ○ Game_System
#===============================================================================
class Game_System
  attr_accessor  :eagle_eventbar, :eagle_eventbar_active
  attr_accessor  :eagle_eventbar_cur, :eagle_eventbar_last
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  alias eagle_eventbar_initialize initialize
  def initialize
    eagle_eventbar_initialize
    @eagle_eventbar = [] # [name, {}]
    @eagle_eventbar_active = false
    @eagle_eventbar_cur = nil # name
    @eagle_eventbar_last = nil
  end
  #--------------------------------------------------------------------------
  # ● 获取事件指令集合
  #--------------------------------------------------------------------------
  def eagle_eventbar
    @eagle_eventbar || []
  end
  #--------------------------------------------------------------------------
  # ● 当前事件指令UI是否激活？
  #--------------------------------------------------------------------------
  def eagle_eventbar_active
    @eagle_eventbar_active || false
  end
end
#===============================================================================
# ○ Game_Map
#===============================================================================
class Game_Map
  #--------------------------------------------------------------------------
  # ● 检测／设置启动中的地图事件
  #--------------------------------------------------------------------------
  alias eagle_eventbar_setup_starting_map_event setup_starting_map_event
  def setup_starting_map_event
    if $game_system.eagle_eventbar_cur
      i = EVENTBAR.find($game_system.eagle_eventbar_cur)
      if i
        h = $game_system.eagle_eventbar[i][1]
        list, eid = EVENTBAR.get_event_list(h)
        if list
          @interpreter.setup(list, eid)
          if $imported["EAGLE-EventInteractEX"]
            @interpreter.event_interact_search(h[:sym]) if h[:sym]
          end
          $game_system.eagle_eventbar_cur = nil
          return true
        end
      end
    end
    eagle_eventbar_setup_starting_map_event
  end
end
#===============================================================================
# ○ Game_Player
#===============================================================================
class Game_Player < Game_Character
  #--------------------------------------------------------------------------
  # ● 由方向键移动
  #--------------------------------------------------------------------------
  alias eagle_eventbar_move_by_input move_by_input
  def move_by_input
    return if $game_system.eagle_eventbar_active
    eagle_eventbar_move_by_input
  end
end
#===============================================================================
# ○ Spriteset_Map
#===============================================================================
class Spriteset_Map
  #--------------------------------------------------------------------------
  # ● 生成人物精灵
  #--------------------------------------------------------------------------
  alias eagle_eventbar_create_characters create_characters
  def create_characters
    eagle_eventbar_create_characters
    @spriteset_eventbar = Spriteset_EventBar.new(@viewport1)
  end
  #--------------------------------------------------------------------------
  # ● 释放人物精灵
  #--------------------------------------------------------------------------
  alias eagle_eventbar_dispose_characters dispose_characters
  def dispose_characters
    eagle_eventbar_dispose_characters
    @spriteset_eventbar.dispose
  end
  #--------------------------------------------------------------------------
  # ● 更新人物精灵
  #--------------------------------------------------------------------------
  alias eagle_eventbar_update_characters update_characters
  def update_characters
    eagle_eventbar_update_characters
    @spriteset_eventbar.update
    EVENTBAR.update(@spriteset_eventbar)
  end
end

#===============================================================================
# ○ Spriteset_EventBar
#===============================================================================
class Spriteset_EventBar
  include EVENTBAR
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(viewport)
    @sprite_eventbar = Sprite.new(viewport)
    @sprite_eventbar.z = 500
    @sprite_layer = Sprite.new(viewport)
    @sprite_layer.z = 501
    @sprite_layer.bitmap ||= Bitmap.new(200, 120)
    @sprite_help = Sprite.new(viewport)
    @sprite_help.z = 501
    @sprite_hint = Sprite.new(viewport)
    @sprite_hint.z = 501
    draw_hint

    @sprite_log = Sprite.new(viewport)
    @sprite_log.z = @sprite_eventbar.z - 1

    @count_hint = 0
    @count_log = 0
 end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    EVENTBAR.clear
    instance_variables.each do |varname|
      ivar = instance_variable_get(varname)
      if ivar.is_a?(Sprite)
        ivar.bitmap.dispose if ivar.bitmap
        ivar.dispose
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 显隐
  #--------------------------------------------------------------------------
  def visible; @sprite_eventbar.visible; end
  def visible=(v)
    @sprite_eventbar.visible = v
    @sprite_layer.visible = v
    @sprite_help.visible = v
    @sprite_hint.visible = !v
    if v
      @sprite_hint.opacity = 0
      @count_hint = 0
    end
  end

  #--------------------------------------------------------------------------
  # ● 重绘
  #--------------------------------------------------------------------------
  def redraw
    @sprite_eventbar.bitmap ||= Bitmap.new(200, 120)
    @sprite_eventbar.bitmap.clear
    sprite = @sprite_eventbar
    bitmap = @sprite_eventbar.bitmap
    total = $game_system.eagle_eventbar.size
    cur_i = EVENTBAR.index

    bitmap.font.size = EVENTBAR::NAME_FONT_SIZE
    # [指令的序号, 在环形菜单里的序号（2为头顶处）]
    [[(cur_i - 2) % total, 0], [(cur_i + 2) % total, 4],
     [(cur_i - 1) % total, 1], [(cur_i + 1) % total, 3],
     [cur_i, 2]].each do |i|
      draw_item(bitmap, i[0], i[1])
    end

    sprite.ox = sprite.width / 2
    sprite.oy = sprite.height / 2
    sprite.x = $game_player.screen_x
    sprite.y = $game_player.screen_y - 16

    @sprite_layer.ox = sprite.width / 2
    @sprite_layer.oy = sprite.height / 2
    @sprite_layer.x = $game_player.screen_x
    @sprite_layer.y = $game_player.screen_y - 16

    redraw_help
  end
  #--------------------------------------------------------------------------
  # ● 绘制第i项
  #--------------------------------------------------------------------------
  def draw_item(bitmap, i, ring_index)
    item = $game_system.eagle_eventbar[i]
    dx, dy = get_item_dxy(ring_index)
    x = bitmap.width / 2 + dx
    y = bitmap.height / 2 + 48 + dy
    d = (ring_index - 2).abs
    opa = 255 - d * 70
    draw_icon(bitmap, item[1][:icon], x-11, y-11, opa)
    if ring_index == 2
      r = bitmap.text_size(item[0])
      w = r.width + 24
      h = 24
      y = y - 12 - 24
      bitmap.fill_rect(x-w/2-2, y-1, w+4, h+2, Color.new(0,0,0,150))
      draw_icon(bitmap, item[1][:icon], x-w/2, y)
      bitmap.draw_text(x-w/2+24, y, w * 2, h, item[0], 0)
    end
  end
  #--------------------------------------------------------------------------
  # ● 获取某个环形位置
  #--------------------------------------------------------------------------
  def get_item_dxy(ring_index)
    r = 64
    a = (15 * (ring_index-2) + 270) / 180.0 * Math::PI
    dx = r * Math.cos(a)
    dy = r * Math.sin(a)
    return dx, dy
  end
  #--------------------------------------------------------------------------
  # ● 绘制图标
  #--------------------------------------------------------------------------
  def draw_icon(bitmap, icon_index, x, y, opa = 255)
    _bitmap = Cache.system("Iconset")
    rect = Rect.new(icon_index % 16 * 24, icon_index / 16 * 24, 24, 24)
    bitmap.blt(x, y, _bitmap, rect, opa)
  end
  #--------------------------------------------------------------------------
  # ● 绘制说明文本
  #--------------------------------------------------------------------------
  def redraw_help
    cur_i = EVENTBAR.index
    item = $game_system.eagle_eventbar[cur_i]

    @sprite_help.bitmap ||= Bitmap.new(HINT_TEXT_WIDTH, Graphics.height / 2)
    @sprite_help.bitmap.clear
    bitmap = @sprite_help.bitmap

    h = 0
    text_help = item[1][:help] || ""
    if text_help != ""
      t = HELP_TEXT_HEAD.dup
      t.gsub!(/<name>/) { item[0] }
      t += " | #{sprintf("%0.1f", item[1][:t]/60.0)}秒冷却" if item[1][:t] > 0
      t += "\n"
      if $TEST
        t += "[DEBUG] "
        if item[1][:mid] < 0
          t += "公共事件"
        else
          mid = item[1][:mid] || 0
          mid = $game_map.map_id if item[1][:mid].nil? || item[1][:mid] == 0
          t += "地图 #{item[1][:mid]}"
        end
        t += " | 事件 #{item[1][:eid]}"
        t += " | 页 #{item[1][:pid]}" if item[1][:pid] > 0
        t += " | SYM #{item[1][:sym]}" if item[1][:sym]
        t += "\n"
      end
      t += text_help
      ps = { :font_size => HELP_FONT_SIZE, :x0=>4, :y0=>h+4, :lhd=>4 }
      d = Process_DrawTextEX.new(t, ps, bitmap)
      d.run(false)
      bitmap.fill_rect(0, 0, bitmap.width, d.height + 4, Color.new(0,0,0,150))
      d.run(true)
      h = d.height + 4 + 4
    end

    bitmap.font.size = HINT_FONT_SIZE
    y = h
    bitmap.fill_rect(0, y, bitmap.width, 32, Color.new(0,0,0,150))
    bitmap.draw_text(0, y + 2, bitmap.width, 16, HINT_TEXT_KEY, 1)
    bitmap.draw_text(0, y + 2 + 16, bitmap.width, 16, HINT_TEXT_CLOSE, 1)
    h += 36

    @sprite_help.ox = @sprite_help.width / 2
    @sprite_help.oy = h
    @sprite_help.x = Graphics.width / 2
    @sprite_help.y = Graphics.height - 10
  end

  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    if $game_system.eagle_eventbar_active
      update_layer
    else
      update_hint if !EVENTBAR.unable?
    end
    update_log
  end
  #--------------------------------------------------------------------------
  # ● 更新遮挡层
  #--------------------------------------------------------------------------
  def update_layer
    @sprite_layer.bitmap.clear
    b = @sprite_layer.bitmap
    item = $game_system.eagle_eventbar[EVENTBAR.index]
    params = item[1]

    # 更新当前项的倒计时
    if params[:c] > 0
      rate = params[:c] * 1.0 / params[:t]
      # 获取显示当前项的位置
      dx, dy = get_item_dxy(2)
      x = b.width / 2 + dx
      y = b.height / 2 + 48 + dy
      # 先盖一层阴影
      b.font.size = EVENTBAR::NAME_FONT_SIZE
      r = b.text_size(item[0])
      w = r.width + 24
      h = 26
      y = y - 12 - 24
      b.fill_rect(x-w/2-2, y-1, w+4, h, Color.new(0,0,0,160))
      # 绘制倒计时
      dy = h * (1 - rate)
      b.fill_rect(x-w/2-2, y-1+dy, w+4, h * rate, Color.new(0,0,0,220))
      b.draw_text(x-w/2, y, w, h, sprintf("%0.1f", params[:c]/60.0), 1)
    end
  end

  #--------------------------------------------------------------------------
  # ● 绘制UI开启提示
  #--------------------------------------------------------------------------
  def draw_hint
    b = Bitmap.new(32, 32)
    b.font.size = HINT_FONT_SIZE
    t = HINT_TEXT_OPEN
    r = b.text_size(t)
    b.dispose
    @sprite_hint.bitmap = Bitmap.new(r.width + 24, r.height * 2)
    @sprite_hint.bitmap.font.size = HINT_FONT_SIZE
    @sprite_hint.bitmap.fill_rect(0, 0, @sprite_hint.width,
      @sprite_hint.height, Color.new(0,0,0,150))
    @sprite_hint.bitmap.draw_text(0, 0, @sprite_hint.width,
      @sprite_hint.height, t, 1)
    @sprite_hint.opacity = 0
    @sprite_hint.visible = true
  end
  #--------------------------------------------------------------------------
  # ● 更新UI开启提示
  #--------------------------------------------------------------------------
  def update_hint
    if Input.dir8 == 0
      @count_hint += 1
    else # 如果存在方向按键，就归零
      @count_hint = 0
      @sprite_hint.opacity = 0
    end
    return if @count_hint < HINT_SHOW_TIME
    @sprite_hint.opacity += 15
    @sprite_hint.ox = @sprite_hint.width / 2
    @sprite_hint.oy = 0
    @sprite_hint.x = $game_player.screen_x
    @sprite_hint.y = $game_player.screen_y + 4
    @sprite_hint.y = Graphics.height if @sprite_hint.y > Graphics.height
  end

  #--------------------------------------------------------------------------
  # ● 更新日志显示
  #--------------------------------------------------------------------------
  def update_log
    update_log_old if @sprite_log.bitmap
    update_log_new if @sprite_log.bitmap == nil && EVENTBAR.logs.size > 0
    update_log_position if @sprite_log.opacity > 0
  end
  #--------------------------------------------------------------------------
  # ● 显示现有日志
  #--------------------------------------------------------------------------
  def update_log_old
    @sprite_log.opacity += 15
    @count_log += 1
    if @count_log > LOG_TIME_SHOW
      @sprite_log.bitmap.dispose
      @sprite_log.bitmap = nil
      @sprite_log.opacity = 0
      @count_log = 0
    end
  end
  #--------------------------------------------------------------------------
  # ● 显示新日志
  #--------------------------------------------------------------------------
  def update_log_new
    t = EVENTBAR.logs.shift
    b = Bitmap.new(32, 32)
    b.font.size = LOG_FONT_SIZE
    r = b.text_size(t)
    b.dispose
    @sprite_log.bitmap = Bitmap.new(r.width + 16, r.height+8)
    @sprite_log.bitmap.font.size = LOG_FONT_SIZE
    @sprite_log.bitmap.fill_rect(0, 0, @sprite_log.width,
      @sprite_log.height, Color.new(0,0,0,150))
    @sprite_log.bitmap.draw_text(0, 0, @sprite_log.width,
      @sprite_log.height, t, 1)
  end
  #--------------------------------------------------------------------------
  # ● 更新日志位置
  #--------------------------------------------------------------------------
  def update_log_position
    @sprite_log.ox = @sprite_log.width / 2
    @sprite_log.oy = @sprite_log.height
    @sprite_log.x = $game_player.screen_x
    @sprite_log.y = $game_player.screen_y - 36
    if $game_system.eagle_eventbar_active
      @sprite_log.y -= 36
    end
  end
end

#===============================================================================
# ○ 征用滚动文本
#===============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 显示滚动文字
  #--------------------------------------------------------------------------
  alias eagle_eventbar_command_105 command_105
  def command_105
    return call_eventbar if $game_switches[EVENTBAR::S_ID_SCROLL_TEXT]
    eagle_eventbar_command_105
  end
  #--------------------------------------------------------------------------
  # ● 写入绑定事件
  #--------------------------------------------------------------------------
  def call_eventbar
    ensure_fin = @list[@index].parameters[1]
    # 第一行为显示名称
    n = ""
    if next_event_code == 405
      @index += 1
      n += @list[@index].parameters[0]
    end
    # 第二行为参数
    ps_t = ""
    if next_event_code == 405
      @index += 1
      ps_t += @list[@index].parameters[0]
    end
    ps = EAGLE_COMMON.parse_tags(ps_t)
    # 之后为帮助文本
    t = ""
    while next_event_code == 405
      @index += 1
      t += @list[@index].parameters[0]
      t += "\n"
    end
    EVENTBAR.bind(n, ps, t)
    Fiber.yield
  end
end
