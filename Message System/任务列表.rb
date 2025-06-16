#==============================================================================
# ■ 任务列表 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【组件-位图绘制转义符文本 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-QuestList"] = "1.1.0"
#==============================================================================
# - 2025.5.25.12 新增Scene调用方法
#==============================================================================
# - 本插件新增了简易的文字版任务列表UI
#------------------------------------------------------------------------------
# 【介绍】
#
# - 在许多游戏中都有任务系统，但默认VA中并没有这类设计，
#    尽管已经有许多前辈设计了各式各样的任务系统，但使用起来总觉得有一些难度。
#
# - 本插件汲取【词条系统（文字版） by老鹰】的设计模式，编写了一套简洁的任务列表UI：
#    1. 在脚本中预先编写好各个任务的名称及内容
#    2. 在事件中，使用 注释 或 事件脚本 ，让指定名称的任务显示在UI中
#    3. 在事件中，使用 注释 或 事件脚本 ，更改指定名称的任务的完成状态
#
# - 但注意，本插件只有显示预设任务文本的作用，并不和其他系统交互（比如战斗），
#    请自己利用本插件提供的全局脚本，手动编写、设计任务的领取、完成等。
#
#---------------------------------------------------------------------------
# 【任务新增：事件指令-注释】
#
# - 在 事件指令-注释 中，如下格式编写来解锁指定任务：
#  （具体形式可以通过修改 COMMENT_UNLOCK 这个正则表达式来改变。）
#
#     任务|任务名称|任务状态
#
#   其中 任务 为固定的识别文本，需要位于行首，前面不可有其它文本或空格。
#
#   其中 任务名称 为编写任务时所设置的唯一标识，请注意与任务标题区分。
#
#   其中 任务状态 为 QUEST_STATE_TEXT 中的键值，为数字或指定字符。
#     预设： 0 进行， 1 完成， 2 失败， 3 过期， 其它情况将显示为 无
#
# - 示例：
#
#    任务|第一个任务|进行 → 新增任务 “第一个任务”，且状态为 进行
#    任务|第一个任务|0    → 新增任务 “第一个任务”，且状态为 进行
#    任务|第一个任务|完成 → 修改任务 “第一个任务”，且状态为 完成
#    任务|第一个任务|1    → 修改任务 “第一个任务”，且状态为 完成
#
#---------------------------------------------------------------------------
# 【任务新增：全局脚本】
#
# - 使用全局脚本 QUEST.add(name, state) 新增/更新指定任务的状态
#
#   其中 name 为编写任务时所设置的唯一标识，即 DATA["name"] 中的 name
#    可以与任务标题一样，也可以不一样（另外设置 :title 所对应的字符串）
#
#   其中 state 为任务状态，为常量 QUEST_STATE_TEXT 中预设的数字（不可为字符串）
#     预设： 0 进行， 1 完成， 2 失败， 3 过期， 其它情况将显示为 无
#
# - 示例：
#
#     QUEST.add("第一个任务", 0)  → 新增任务 “第一个任务”，且状态为 进行
#     QUEST.add("第一个任务", 1)  → 修改任务 “第一个任务”，且状态为 完成
#
#---------------------------------------------------------------------------
# 【任务编写】
#
# - 由于默认事件并不方便进行大批文本的编写与修改，而外置文件又面临加密后的读取问题，
#   本插件使用了原始的脚本内编写预设文本的方式。
#
# - 推荐在本插件的下一页脚本中，新增一个空白页，命名为“【任务设置】”，
#   并复制如下的内容，进行修改和扩写：
#
=begin
# --------复制以下的内容！--------

module QUEST
  DATA ||= {} # 确保常量存在，不要删除

DATA["任务名称"] = {  # 需要保证唯一性

  # 任务详情页中所显示的任务内容文本
  #   可以使用转义符，但需要用 \e 代替 \，可以用 \n 换行
  :info => "任务内容文本",  
  
  # 任务排序时的数字，可以为小数，将由小到大排序
  # （可以省略，默认取 0）
  #:v => 数字，
  
  # 任务详情页中显示的标题文本
  # （可以省略，默认与 "任务名称" 一致）
  #:title => "任务标题",
  
  # 显示在任务名称前的一个标签文本，方便识别类型
  # （可以省略）
  #:tag => "", 
  
  # 任务详情页中的左侧自定义
  # （利用 UI_LIST_INFO_LEFT 常量来设置左侧可以显示哪些项）
  
} # 别忘记结尾的括号

DATA["第一个任务"] = {
  :title => "初露锋芒",
  :info => "第一个任务的说明文本\n这样就换了一行
这样也可以换一行哦",
  :tag => "新手",  # 这是本系统预设的一个详情页左侧项，可以显示短词组
  :reward => "测试用物品 x1\n剧情用关键道具 x1", # 只是单纯显示，没有获得物品的功能
}

end  # 必须的结尾，不要漏掉

# --------复制以上的内容！--------
=end
#
# - 除了 :title 所对应的文本，其它字符串中均可以使用转义符。
#
#---------------------------------------------------------------------------
# 【自定义任务详情页】
#
# - 任务详情页的左半部分，其显示内容为动态自适应的，
#     即在脚本中预设了多种可能的显示内容，当任务有对应设置时，才会显示。
#
# - 在常量 UI_LIST_INFO_LEFT 中设置了可能的项：
#     比如针对 :tag => " >> 标签" 这一行，
#     如果在任务数据中设置了 :tag => "任意文本" 这样的键值，
#       就会在详情页左侧显示其中的内容，小标题为 >> 标签，内容为 "任意文本"；
#     如果任务数据中没有 :tag 这一项，就不会显示。
#
# - "任意文本" 中可以使用转义符，但记得用 \\ 代替 \
#
# - 示例：
#
#     在常量 UI_LIST_INFO_LEFT 中设置了 :loc => " >> 地点"
#     那么任务中可以这样编写
#        DATA["任务名称"] = { :title => "任务标题", :info => "任务具体内容",
#                            :loc => "任务地点" }
#       当查看任务详情时，左半边将显示 >> 地点。
#     但如果任务中并没有写 :loc 的键值，那么并不会显示 地点 内容。
#
#---------------------------------------------------------------------------
# 【呼叫UI】
#
#  方式一：利用全局脚本 QUEST.start_list 来呼叫本插件编写的简易UI。
#          可以在事件脚本中调用，将立即暂停其他内容并优先处理。
#
#  方式二：利用 SceneManager.call(Scene_Quest) 来呼叫UI，便于在菜单中调用。
#
#---------------------------------------------------------------------------
# 【联动】
#
# - 当使用了【AddOn-并行对话 by老鹰】或【并行式对话 by老鹰】或【通知队列 by老鹰】，
#   在新增任务时，将显示提示文本窗口，若不想使用该功能，请注释掉 add_hint 方法。
#
# - 本插件已兼容【鼠标扩展 by老鹰】，可以使用鼠标进行操作，请置于其下。
#
#===============================================================================

#===============================================================================
# □ 常量设置
#===============================================================================
module QUEST
  #--------------------------------------------------------------------------
  # ○【常量】事件指令-注释 中新增/更新任务的文本
  #--------------------------------------------------------------------------
  COMMENT_UNLOCK = /^任务 ?\| *?(.*?) *?\| *?(.*)/i
  #--------------------------------------------------------------------------
  # ○【常量】UI - 类别文本的字体大小
  #--------------------------------------------------------------------------
  CATE_FONT_SIZE = 24
  #--------------------------------------------------------------------------
  # ○【常量】UI - 详细信息文本的字体大小
  #--------------------------------------------------------------------------
  INFO_FONT_SIZE = 21
  #--------------------------------------------------------------------------
  # ○【常量】UI - 按键提示文本的字体大小
  #--------------------------------------------------------------------------
  HINT_FONT_SIZE = 15
  #--------------------------------------------------------------------------
  # ○【常量】任务排序时的默认数字
  #--------------------------------------------------------------------------
  QUEST_DEFAULT_V = 0
  #--------------------------------------------------------------------------
  # ○【常量】UI - 任务的全部状态数字及对应的UI文字
  #  由于使用了数组的 sort 进行排序，key需要为数字，value字符串中可以使用转义符
  #--------------------------------------------------------------------------
  QUEST_STATE_TEXT = {
    # key => "value",
    0 => "\ec[3]进行\ec[0]",
    1 => "\ec[1]完成\ec[0]",
    2 => "\ec[10]失败\ec[0]",
    3 => "\ec[8]过期\ec[0]",
  }
  #--------------------------------------------------------------------------
  # ○【常量】在事件注释中编写的任务状态
  # 进行一次替换，以方便在注释中直观编写
  #--------------------------------------------------------------------------
  QUEST_STATE_NOTE = {
    # 注释中的状态 => 实际状态（数字）
    "进行" => 0,
    "完成" => 1,
    "失败" => 2,
    "过期" => 3,
  }
  #--------------------------------------------------------------------------
  # ○【常量】UI - 任务详情页中，标题文本的前缀
  #--------------------------------------------------------------------------
  UI_LIST_INFO_TITLE_PREFIX = "◇ "
  #--------------------------------------------------------------------------
  # ○【常量】UI - 任务详情页中，左半侧的绘制内容（按顺序从上到下绘制）
  # 若任务中不存在对应项，则会继续绘制下一项
  #--------------------------------------------------------------------------
  UI_LIST_INFO_LEFT = {
    # 任务编写时，可以有的项 => 显示名称
    :tag => " >> 标签",
    :from => " >> 来源",
    :reward => " >> 报酬",
  }
  #--------------------------------------------------------------------------
  # ○【常量】UI - 任务详情页中，右半侧的标题文本
  #--------------------------------------------------------------------------
  UI_LIST_INFO_RIGHT = " >> 详细说明"
end

#===============================================================================
# □ QUEST
#===============================================================================
module QUEST
  #--------------------------------------------------------------------------
  # ○【常量】数据
  #--------------------------------------------------------------------------
  DATA = {}
  #--------------------------------------------------------------------------
  # ○ 新增一个任务
  #--------------------------------------------------------------------------
  # state = nil删除 0进行中 1完成 2失败 3过期
  def self.add(sym, state = 0)
    if state == nil
      $game_system.eagle_quest.delete_if { |q| q.sym == sym }
      return
    end
    if $game_system.eagle_quest.has_key?(sym)
      d = $game_system.eagle_quest[sym]
      d.set_state(state)
    else
      d = Data_Quest.new(sym)
      d.set_state(state)
      $game_system.eagle_quest[sym] = d
    end
    add_hint(d, state) if d
    $game_system.eagle_quest_new.push(sym)
  end
  #--------------------------------------------------------------------------
  # ○ 数据类
  #--------------------------------------------------------------------------
  class Data_Quest
    attr_reader :sym, :state
    #--------------------------------------------------------------------------
    # ○ 初始化
    #--------------------------------------------------------------------------
    def initialize(sym)
      @sym = sym
      @state = 0
    end
    #--------------------------------------------------------------------------
    # ○ 设置状态
    #--------------------------------------------------------------------------
    def set_state(s)
      @state = s
    end
    #--------------------------------------------------------------------------
    # ○ 获取状态文本
    #--------------------------------------------------------------------------
    def get_state_s
      QUEST::QUEST_STATE_TEXT[@state] || "无"
    end
    #--------------------------------------------------------------------------
    # ○ 获取任务名
    #--------------------------------------------------------------------------
    def get_title
      d = DATA[@sym]
      return d[:title] || @sym
    end
    #--------------------------------------------------------------------------
    # ○ 获取详细介绍文本
    #--------------------------------------------------------------------------
    def get_info
      d = DATA[@sym]
      return d[:info] || ""
    end
    #--------------------------------------------------------------------------
    # ○ 获取标签文本
    #--------------------------------------------------------------------------
    def get_tag
      d = DATA[@sym]
      return d[:tag] || ""
    end
    #--------------------------------------------------------------------------
    # ○ 获取排序用数字
    #--------------------------------------------------------------------------
    def v
      d = DATA[@sym]
      return d[:v].to_i || QUEST_DEFAULT_V
    end
    #--------------------------------------------------------------------------
    # ○ 绘制任务名
    #--------------------------------------------------------------------------
    def draw_title(sprite)
      # 此为全屏的bitmap，可以绘制一些其他东西
      sprite.bitmap.clear

      # -----绘制标题-----
      # 标题的文字大小
      font_title = 32
      pre_title = QUEST::UI_LIST_INFO_TITLE_PREFIX

      x_l = 12
      font_size = sprite.bitmap.font.size
      sprite.bitmap.font.size = font_title
      sprite.bitmap.draw_text(x_l, 12, sprite.width-24, 36,
        pre_title + get_title, 0)
      sprite.bitmap.font.size = font_size
      # 绘制标题下的横线
      sprite.bitmap.fill_rect(x_l, 50, sprite.width-24, 1,
        Color.new(255,255,255,120))

      # 绘制任务状态
      t = get_state_s
      ps = { :font_size => font_title, :x0 => 0, :y0 => 12, :lhd => 2}
      d = Process_DrawTextEX.new(t, ps, sprite.bitmap)
      d.run(false)
      ps[:x0] = Graphics.width - 12 - d.width
      d.run(true)
    end
    #--------------------------------------------------------------------------
    # ○ 绘制详细介绍
    #--------------------------------------------------------------------------
    def draw_info(sprite)
      # 需要先手动设置其viewport的位置，结合上面的标题占据的高度
      h_title = 50 + 12
      w = Graphics.width - 12 * 2
      h = Graphics.height - h_title - 36 # 底部按键提示的高度与12像素间隔
      sprite.viewport.rect.set(12, h_title, w, h)
      sprite.bitmap = Bitmap.new(w, h) if sprite.bitmap.nil?
      sprite.bitmap.font.size = QUEST::INFO_FONT_SIZE
      sprite.bitmap.clear

      # -----绘制左半边内容-----
      # 中轴线朝左侧移动的像素值，可用于增加右侧区域的宽度
      offset = 50

      x_l = 0
      y_l = 0
      w_l = (sprite.width / 2 - offset) - 12
      QUEST::UI_LIST_INFO_LEFT.each do |sym, sym_name|
        t = DATA[@sym][sym]
        next if t == nil or t.empty?
        sprite.bitmap.font.color = text_color(16)
        sprite.bitmap.draw_text(x_l, y_l, w_l, 24, sym_name, 0)
        # 绘制分隔横线
        sprite.bitmap.fill_rect(x_l, y_l+23, w_l, 1, Color.new(255,255,255,120))
        y_l += 24
        sprite.bitmap.font.color = text_color(0)
        t.split("\n").each do |_t|
          ps = { :x0 => x_l, :y0 => y_l }
          d = Process_DrawTextEX.new(_t, ps, sprite.bitmap)
          d.run(false)
          ps[:x0] = (w_l - d.width) / 2
          d.run(true)
          y_l += (d.height - ps[:y0])
        end
        y_l += 4
      end

      # -----绘制中轴线-----
      x_c = (sprite.width / 2 - offset)
      sprite.bitmap.fill_rect(x_c, 0, 1, sprite.height,
        Color.new(255,255,255,120))

      # -----绘制右半边内容-----
      x_r = (sprite.width / 2 - offset) + 12
      y_r = 0
      w_r = (sprite.width / 2 + offset) - 12
      sprite.bitmap.font.color = text_color(16)
      sprite.bitmap.draw_text(x_r, y_r, w_r, 24, QUEST::UI_LIST_INFO_RIGHT, 0)
      # 绘制分隔横线
      sprite.bitmap.fill_rect(x_r, y_r+23, w_r, 1, Color.new(255,255,255,120))
      y_r += 24
      sprite.bitmap.font.color = text_color(0)

      t = get_info
      ps = { :font_size => QUEST::INFO_FONT_SIZE,
        :x0 => x_r, :y0 => y_r+4, :lhd => 2, :w => w_r
      }
      d = Process_DrawTextEX.new(t, ps, sprite.bitmap)
      d.run(true)
    end
    #--------------------------------------------------------------------------
    # ● 获取文字颜色
    #     n : 文字颜色编号（0..31）
    #--------------------------------------------------------------------------
    def text_color(n)
      Cache.system("Window").get_pixel(64 + (n % 8) * 8, 96 + (n / 8) * 8)
    end
  end
  #--------------------------------------------------------------------------
  # ● 待显示的提示文本
  #--------------------------------------------------------------------------
  @data_hints = []
  def self.add_hint(data, type)
    @data_hints.push([data, type])
  end
  #--------------------------------------------------------------------------
  # ● 显示提示
  #--------------------------------------------------------------------------
  def self.show_hint
    return if @data_hints.empty?
    if $imported["EAGLE-MessageHint"]
      t = ""
      @data_hints.each do |data|
        _s1 = data[0].get_title
        _s2 = data[0].get_state_s
        t += "#{_s1} - #{_s2}\n"
      end
      MESSAGE_HINT.add({:text => t}, id="居中偏上")
      @data_hints.clear
      return
    end
    if $imported["EAGLE-MessagePara"]
      return if MESSAGE_PARA.list_exist?(:quest)
      t = ""
      @data_hints.each do |data|
        _s1 = data[0].get_title
        _s2 = data[0].get_state_s
        t += "#{_s1} - #{_s2}\n"
      end
      t = "<msg>\\win[do-2 o5 dx0dy-100 w0h0 fw1fh1 z250]\\ins#{t}</msg>"
      MESSAGE_PARA.add(:quest, t)
      @data_hints.clear
      return
    end
    if $imported["EAGLE-MessagePara2"]
      return if !MESSAGE_PARA2.finish?(:quest)
      t = ""
      @data_hints.each do |data|
        _s1 = data[0].get_title
        _s2 = data[0].get_state_s
        t += "#{_s1} - #{_s2}\n"
      end
      d = { :text => t,
      :pos => { :o => 5, :wx => Graphics.width/2, :wy => Graphics.height-100 } }
      MESSAGE_PARA2.add(:quest, d)
      @data_hints.clear
      return
    end
  end
end # end of module
#===============================================================================
# □ Game_System
#===============================================================================
class Game_System
  #--------------------------------------------------------------------------
  # ○ 已获得的任务
  #--------------------------------------------------------------------------
  def eagle_quest
    @eagle_quest ||= {}  # sym => Data_Quest
    @eagle_quest
  end
  #--------------------------------------------------------------------------
  # ○ 新增任务的数组
  #--------------------------------------------------------------------------
  def eagle_quest_new
    @eagle_quest_new ||= []
    @eagle_quest_new
  end
end
#===============================================================================
# ○ Game_Interpreter
#===============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 添加注释
  #--------------------------------------------------------------------------
  alias eagle_quest_command_108 command_108
  def command_108
    eagle_quest_command_108
    @comments.each do |t|
      if t =~ QUEST::COMMENT_UNLOCK
        name = $1
        state = QUEST::QUEST_STATE_NOTE[$2] || $2.to_i
        QUEST.add(name, state)
      end
    end
  end
end
#===============================================================================
# ○ Scene_Base
#===============================================================================
class Scene_Base
  #--------------------------------------------------------------------------
  # ● 更新画面
  #--------------------------------------------------------------------------
  alias eagle_quest_list_update update
  def update
    eagle_quest_list_update
    QUEST.show_hint
  end
end

#===============================================================================
# □ UI 任务列表
#===============================================================================
class << QUEST
  attr_reader  :window_list
  #--------------------------------------------------------------------------
  # ○ 打开任务列表UI
  #--------------------------------------------------------------------------
  def start_list
    ui_list_call
  end
  #--------------------------------------------------------------------------
  # ○ UI-基础更新
  #--------------------------------------------------------------------------
  def ui_update_basic
    Graphics.update
    Input.update
  end

  #--------------------------------------------------------------------------
  # ○ 列表UI-呼叫
  #--------------------------------------------------------------------------
  def ui_list_call
    begin
      ui_list_init
      ui_list_update
    rescue
      p $!
    ensure
      ui_list_dispose
    end
  end
  #--------------------------------------------------------------------------
  # ○ 列表UI-初始化
  #--------------------------------------------------------------------------
  def ui_list_init
    # 生成背景精灵
    @sprite_bg = Sprite.new
    @sprite_bg.z = 250
    set_sprite_bg(@sprite_bg)

    # 生成背景文字
    @sprite_bg_info = Sprite.new
    @sprite_bg_info.z = @sprite_bg.z + 1
    set_sprite_title(@sprite_bg_info)

    # 生成底部按键提示
    @sprite_hint = Sprite.new
    @sprite_hint.z = @sprite_bg.z + 20
    set_sprite_hint(@sprite_hint)

    # 生成类别组
    @sprites_category = []; i = 0
    @rect_category = Rect.new(0,0,Graphics.width, 60)
    i_w = (@rect_category.width-@rect_category.x) / QUEST::QUEST_STATE_TEXT.size
    QUEST::QUEST_STATE_TEXT.each do |state, t|
      s = Sprite_EagleQuest_Category.new(state)
      ps = { :x0 => 0, :y0 => 0, :font_size => QUEST::CATE_FONT_SIZE }
      d = Process_DrawTextEX.new(t, ps)
      d.run(false)
      s.bitmap = Bitmap.new(d.width, d.height)
      d.bind_bitmap(s.bitmap)
      d.run(true)
      s.ox = s.width / 2
      s.oy = s.height / 2
      s.x = @rect_category.x + i_w / 2 + i_w * i
      s.y = @rect_category.y + 24 + s.height / 2
      s.z = @sprite_bg.z + 10
      @sprites_category.push(s)
      i += 1
    end
    @index_category = 0

    # 任务列表
    x = 64
    y = @rect_category.y + @rect_category.height
    w = Graphics.width - x * 2
    h = Graphics.height - y - 24
    @window_list = Window_EagleQuest_List.new(x, y, w, h)
    @window_list.z = @sprite_bg.z + 30
    @window_list.set_handler(:ok, method(:list_call_info))
    @window_list.data = $game_system.eagle_quest.values

    @window_list.open.activate
    @window_list.select(0)

    # 详情页
    @sprite_quest_title = Sprite.new
    @sprite_quest_title.z = @sprite_bg.z + 40
    @sprite_quest_title.bitmap = Bitmap.new(Graphics.width, Graphics.height)

    @viewport_quest_info = Viewport.new
    @viewport_quest_info.z = @sprite_bg.z + 39
    @sprite_quest_info = Sprite.new(@viewport_quest_info)

    list_refresh_category(@window_list.item.state)
  end
  #--------------------------------------------------------------------------
  # ● 设置背景精灵
  #--------------------------------------------------------------------------
  def set_sprite_bg(sprite)
    sprite.bitmap = Bitmap.new(Graphics.width, Graphics.height)
    sprite.bitmap.fill_rect(0, 0, sprite.width, sprite.height,
      Color.new(0,0,0,200))
  end
  #--------------------------------------------------------------------------
  # ● 设置标题精灵
  #--------------------------------------------------------------------------
  def set_sprite_title(sprite)
    sprite.zoom_x = sprite.zoom_y = 1.5
    sprite.bitmap = Bitmap.new(Graphics.height, Graphics.height)
    sprite.bitmap.font.size = 64
    sprite.bitmap.font.color = Color.new(255,255,255,10)
    sprite.bitmap.draw_text(0,0,sprite.width,64, "任务日志", 0)
    sprite.x = 4
    sprite.y = 4
  end
  #--------------------------------------------------------------------------
  # ● 设置按键提示精灵
  #--------------------------------------------------------------------------
  def set_sprite_hint(sprite)
    sprite.bitmap = Bitmap.new(Graphics.width, 24)
    sprite.bitmap.font.size = QUEST::HINT_FONT_SIZE

    sprite.oy = sprite.height
    sprite.y = Graphics.height

    draw_sprite_hint(sprite)
  end
  #--------------------------------------------------------------------------
  # ○ 重绘按键提示精灵
  #--------------------------------------------------------------------------
  def draw_sprite_hint(sprite, type = :normal)
    t = ""
    case type
    when :normal;
      t = "上/下方向键 - 切换 | 左/右方向键 - 切换类别 | 确定键 - 详情 | 取消键 - 退出"
    when :info;
      t = "确定键/取消键 - 返回任务列表"
    end
    sprite.bitmap.clear
    sprite.bitmap.draw_text(0, 2, sprite.width, sprite.height, t, 1)
    sprite.bitmap.fill_rect(0, 0, sprite.width, 1,
      Color.new(255,255,255,120))
  end
  #--------------------------------------------------------------------------
  # ○ 列表UI-释放
  #--------------------------------------------------------------------------
  def ui_list_dispose
    instance_variables.each do |varname|
      ivar = instance_variable_get(varname)
      if ivar.is_a?(Sprite)
        ivar.bitmap.dispose if ivar.bitmap
        ivar.dispose
      end
    end
    @viewport_quest_info.dispose
    @window_list.dispose
    @sprites_category.each { |s| s.bitmap.dispose; s.dispose }
  end
  #--------------------------------------------------------------------------
  # ○ 列表UI-循环更新
  #--------------------------------------------------------------------------
  def ui_list_update
    loop do
      ui_update_basic
      break if list_update_exit?
      list_update_category
      @window_list.update
    end
  end
  #--------------------------------------------------------------------------
  # ○ 列表UI-退出？
  #--------------------------------------------------------------------------
  def list_update_exit?
    return true if $imported["EAGLE-MouseEX"] && MOUSE_EX.up?(:MR)
    Input.trigger?(:B)
  end
  #--------------------------------------------------------------------------
  # ○ 列表UI-更新分类
  #--------------------------------------------------------------------------
  def list_update_category
    if Input.trigger?(:LEFT)
      list_prev_category
    elsif Input.trigger?(:RIGHT)
      list_next_category
    elsif $imported["EAGLE-MouseEX"] && MOUSE_EX.in?(@rect_category)
      list_update_category_mouse
    else
      data = @window_list.item
      if data.state != @sprites_category[@index_category].state
        list_refresh_category(data.state)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ○ 列表UI-更新分类（鼠标）
  #--------------------------------------------------------------------------
  def list_update_category_mouse
    @sprites_category.each_with_index do |s, i|
      next if i == @index_category
      if s.mouse_in?(true, false)
        index = @window_list.get_state_index(s.state)
        if index
          @window_list.index = index
          Sound.play_cursor
          list_refresh_category(s.state)
        end
        return
      end
    end
  end
  #--------------------------------------------------------------------------
  # ○ 列表UI-上一个类别
  #--------------------------------------------------------------------------
  def list_prev_category
    @index_category -= 1
    @index_category = @sprites_category.size - 1 if @index_category < 0
    s = @sprites_category[@index_category].state
    r = @window_list.select_state(s)
    return list_prev_category if r == false
    Sound.play_cursor
    list_refresh_category(s)
  end
  #--------------------------------------------------------------------------
  # ○ 列表UI-下一个类别
  #--------------------------------------------------------------------------
  def list_next_category
    @index_category += 1
    @index_category = 0 if @index_category > @sprites_category.size - 1
    s = @sprites_category[@index_category].state
    r = @window_list.select_state(s)
    return list_next_category if r == false
    Sound.play_cursor
    list_refresh_category(s)
  end
  #--------------------------------------------------------------------------
  # ○ 列表UI-刷新类别
  #--------------------------------------------------------------------------
  def list_refresh_category(state)
    @sprites_category.each_with_index do |s, i|
      s.opacity = 120
      if s.state == state
        @index_category = i
        s.opacity = 255
      end
    end
  end
  #--------------------------------------------------------------------------
  # ○ 列表UI-打开详情页
  #--------------------------------------------------------------------------
  def list_call_info
    data = @window_list.item
    # 删去new 标志
    $game_system.eagle_quest_new.delete(data.sym)
    # 隐藏列表
    @sprites_category.each { |s| s.visible = false }
    @window_list.close
    # 绘制详情
    @sprite_quest_title.opacity = 0
    @sprite_quest_info.opacity = 0
    data.draw_title(@sprite_quest_title)
    data.draw_info(@sprite_quest_info)
    # 移入
    20.times {
      @sprite_quest_title.opacity += 13
      @sprite_quest_info.opacity += 13
      list_info_update_basic
    }
    draw_sprite_hint(@sprite_hint, :info)
    # 循环更新
    loop do
      ui_update_basic
      break if $imported["EAGLE-MouseEX"] && (MOUSE_EX.up?(:ML) || MOUSE_EX.up?(:MR))
      break if Input.trigger?(:B) || Input.trigger?(:C)
    end
    Input.update
    # 回到列表
    @sprites_category.each { |s| s.visible = true }
    @window_list.open.redraw_current_item
    20.times {
      @sprite_quest_title.opacity -= 13
      @sprite_quest_info.opacity -= 13
      list_info_update_basic
    }
    @window_list.activate
    draw_sprite_hint(@sprite_hint)
  end
  #--------------------------------------------------------------------------
  # ○ 列表UI-详情页的基础更新
  #--------------------------------------------------------------------------
  def list_info_update_basic
    ui_update_basic
    @window_list.update
    yield if block_given?
  end
end
#===============================================================================
# ○ Sprite_EagleQuest_Category
#===============================================================================
class Sprite_EagleQuest_Category < Sprite
  attr_reader :state
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize(state)
    super(nil)
    @state = state
  end
end
#===============================================================================
# ○ Window_EagleQuest_List
#===============================================================================
class Window_EagleQuest_List < Window_Selectable
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize(x, y, width, height)
    super
    @data = []
    self.back_opacity = 0
    self.opacity = 0
    self.contents_opacity = 255
  end
  #--------------------------------------------------------------------------
  # ● 设置数据
  #--------------------------------------------------------------------------
  def data=(d)
    @data = d.dup  # [Data_Quest]
    @data = @data.sort_by { |q| [q.state, q.v] }
  end
  #--------------------------------------------------------------------------
  # ● 设置光标位置
  #--------------------------------------------------------------------------
  def index=(index)
    @index = index
    update_cursor
    call_update_help
    refresh
  end
  #--------------------------------------------------------------------------
  # ● 返回上一个选择的位置
  #--------------------------------------------------------------------------
  def select_last
    select(0)
  end
  #--------------------------------------------------------------------------
  # ● 获取指定类别的第一项的位置
  #--------------------------------------------------------------------------
  def get_state_index(state)
    return @data.index { |d| d.state == state }
  end
  #--------------------------------------------------------------------------
  # ● 选择指定类别的第一项
  #--------------------------------------------------------------------------
  def select_state(state)
    i = get_state_index(state)
    if i == nil
      return false
    end
    self.top_row = i
    self.index = i
    return true
  end
  #--------------------------------------------------------------------------
  # ● 获取列数
  #--------------------------------------------------------------------------
  def col_max
    return 1
  end
  #--------------------------------------------------------------------------
  # ● 获取项目数
  #--------------------------------------------------------------------------
  def item_max
    @data ? @data.size : 1
  end
  #--------------------------------------------------------------------------
  # ● 获取项目的高度
  #--------------------------------------------------------------------------
  def item_height
    line_height + 24
  end
  #--------------------------------------------------------------------------
  # ● 获取物品
  #--------------------------------------------------------------------------
  def item
    @data && index >= 0 ? @data[index] : nil
  end
  #--------------------------------------------------------------------------
  # ● 获取选择项目的有效状态
  #--------------------------------------------------------------------------
  def current_item_enabled?
    true
  end
  #--------------------------------------------------------------------------
  # ● 刷新
  #--------------------------------------------------------------------------
  def refresh
    make_item_list
    create_contents
    draw_all_items
  end
  #--------------------------------------------------------------------------
  # ● 生成物品列表
  #--------------------------------------------------------------------------
  def make_item_list
  end
  #--------------------------------------------------------------------------
  # ● 绘制项目
  #--------------------------------------------------------------------------
  def draw_item(index)
    item = @data[index]
    if item
      rect = item_rect(index)
      rect.width -= 4
      f = index == @index ? true : false
      draw_item_name(item, rect.x+2, rect.y+12, f, rect.width)
      draw_symbol_new(rect.x, rect.y, rect.width, rect.height) if new?(item)
    end
  end
  #--------------------------------------------------------------------------
  # ● 绘制物品名称
  #     enabled : 有效的标志。false 的时候使用半透明效果绘制
  #--------------------------------------------------------------------------
  def draw_item_name(item, x, y, enabled = true, width = 172)
    return unless item
    change_color(normal_color, enabled)
    t = item.get_state_s + " >> "
    t += "[" + item.get_tag + "]" if item.get_tag != ""
    t += item.get_title
    draw_text_ex(x, y, t)
  end
  #--------------------------------------------------------------------------
  # ● 放大字体尺寸
  #--------------------------------------------------------------------------
  def make_font_bigger
    contents.font.size += 4 if contents.font.size <= 64
  end
  #--------------------------------------------------------------------------
  # ● 缩小字体尺寸
  #--------------------------------------------------------------------------
  def make_font_smaller
    contents.font.size -= 4 if contents.font.size >= 16
  end
  #--------------------------------------------------------------------------
  # ● 新增？
  #--------------------------------------------------------------------------
  def new?(item)
    $game_system.eagle_quest_new.include?(item.sym)
  end
  #--------------------------------------------------------------------------
  # ● 绘制“新”标志
  #--------------------------------------------------------------------------
  def draw_symbol_new(x, y, w, h)
    change_color(system_color)
    s = contents.font.size
    contents.font.size = 15
    draw_text(x, y, w-4, h, "新", 2)
    contents.font.size = s
  end
end

#==============================================================================
# ■ 以 SceneManager.call(Scene_Quest) 的方式呼叫
#==============================================================================
class Scene_Quest < Scene_MenuBase
  #--------------------------------------------------------------------------
  # ● 开始后处理
  #--------------------------------------------------------------------------
  def post_start
    super
    QUEST.ui_list_init
  end
  #--------------------------------------------------------------------------
  # ● 更新画面
  #--------------------------------------------------------------------------
  def update 
    super
    QUEST.list_update_category
    QUEST.window_list.update
    return_scene if QUEST.list_update_exit?
  end
  #--------------------------------------------------------------------------
  # ● 结束处理
  #--------------------------------------------------------------------------
  def terminate
    QUEST.ui_list_dispose
    super
  end
end
