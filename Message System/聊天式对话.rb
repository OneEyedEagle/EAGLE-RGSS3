#==============================================================================
# ■ 聊天式对话 by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在
#  【组件-位图绘制转义符文本 by老鹰】与【组件-位图绘制窗口皮肤】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-MessageChat"] = true
#==============================================================================
# - 2021.2.21.20 修复提示精灵位图释放错误的问题
#==============================================================================
# - 本插件新增了仿QQ聊天的对话模式，以替换默认的 事件指令-显示文字
#------------------------------------------------------------------------------
# 【使用】
#
# - 当 S_ID 号开关开启时，事件指令-显示文字 将被替换成聊天式对话
#    此时默认的对话框不再打开，但选择框等其余事件指令依然生效
#
# - 当 S_ID 号开关关闭时，将立即关闭全部聊天式对话
#
# - 在 显示文字 中，新增了如下的编写规则：
#
#  1、在“显示位置”参数中，（默认“居下”，即左对齐）
#    “居上”被视为 右对齐，“居中”被视为 居中对齐，“居下”被视为左对齐
#
#  2、在“文本框”中，开头编写 【...】 或 [...] 用于指定姓名
#    如： 【小明】今天天气真好
#    将显示姓名：小明；显示文本：今天天气真好
#
#  3、脸图规格扩展（同【对话框扩展 by老鹰】中的处理）
#      当脸图文件名包含 _数字1x数字2 时（其中为字母x），
#      将定义该脸图文件的规格为 行数（数字1）x列数（数字2）（默认2行x4列）
#    如：ace_actor_1x1.png → 该脸图规格为 1×1，含有一张脸图，只有index为0时生效
#
#     但由于排版限制，最终都会缩放至指定的 FACE_W * FACE_H 的大小进行显示
#     因此请注意确保脸图大小为预设大小的整数倍，以不因缩放处理而显示模糊
#
#----------------------------------------------------------------------------
# 【注意】
#
# - 由于聊天式对话支持上下方向键滚动查看，但选择框开启时并不会挂起该对话，
#    因此存在选择框切换时，聊天式对话同样滚动的情况
#
#----------------------------------------------------------------------------
# 【扩展】
#
# - 已经兼容【对话日志 by老鹰】，请将本插件置于它之下
#
#----------------------------------------------------------------------------
# 【TODO】
#
# - 自定义窗口皮肤
# - Tag图片
#
#==============================================================================
module MESSAGE_CHAT
  #--------------------------------------------------------------------------
  # ○【常量】当该序号开关开启时，事件的 显示文章 将替换成 聊天式对话
  #--------------------------------------------------------------------------
  S_ID = 15
  #--------------------------------------------------------------------------
  # ○【常量】当S_ID序号开关开启时，该开关开启时，将重新使用默认对话框
  #  即不关闭 聊天式对话 的同时使用默认对话框
  #  【注意】需要手动关闭该开关，以确保聊天式对话能够正常继续使用！
  #--------------------------------------------------------------------------
  S_ID_MSG = 14
  #--------------------------------------------------------------------------
  # ○【常量】定义初始的视图矩形
  #--------------------------------------------------------------------------
  INIT_VIEW = Rect.new(50, 30, Graphics.width-50*2, Graphics.height-30*2)
  #--------------------------------------------------------------------------
  # ○【常量】定义初始的屏幕Z值
  #--------------------------------------------------------------------------
  INIT_Z = 100
  #--------------------------------------------------------------------------
  # ○【常量】定义对话文字的大小
  #--------------------------------------------------------------------------
  FONT_SIZE = 16
  #--------------------------------------------------------------------------
  # ○【常量】文本周围留出空白的宽度（用于绘制窗口的边框）
  #--------------------------------------------------------------------------
  TEXT_BORDER_WIDTH = 8
  #--------------------------------------------------------------------------
  # ○【常量】定义姓名文字的大小
  #--------------------------------------------------------------------------
  NAME_FONT_SIZE = 12
  #--------------------------------------------------------------------------
  # ○【常量】定义脸图的绘制宽度和高度
  #--------------------------------------------------------------------------
  FACE_W = 48
  FACE_H = 48

  #--------------------------------------------------------------------------
  # ●【常量】提示文本的字体大小
  #--------------------------------------------------------------------------
  HINT_FONT_SIZE = 14
  #--------------------------------------------------------------------------
  # ● 【设置】绘制提示精灵
  #--------------------------------------------------------------------------
  def self.draw_hints(s)
    s.bitmap ||= Bitmap.new(Graphics.width, 24)
    s.bitmap.clear
    s.bitmap.font.size = HINT_FONT_SIZE

    # 绘制长横线
    s.bitmap.fill_rect(0, 0, s.width, 1,
      Color.new(255,255,255,120))

    # 绘制 取消键-上一页
    d = 20
    s.bitmap.draw_text(0+d, 2, s.width, s.height, "Shift键 - 回到底部", 0)
    s.bitmap.draw_text(0, 2, s.width-d, s.height, "确定键 - 继续", 2)
    s.bitmap.draw_text(0, 2, s.width, s.height, "上下键 - 滚动查看", 1)

    # 设置摆放位置
    s.oy = s.height
    s.y = Graphics.height
  end

  #--------------------------------------------------------------------------
  # ● 从 显示文本 提取信息
  #--------------------------------------------------------------------------
  def self.extract_info(text, params)
    # 提取位于开头的姓名
    n = ""
    text.sub!(/^【(.*?)】|\[(.*?)\]/) { n = $1 || $2; "" }
    params[:name] = n
  end

  #--------------------------------------------------------------------------
  # ● 新增一个文本块
  #--------------------------------------------------------------------------
  @data = []
  def self.add(params = {})
    @data.push(params)
  end
  #--------------------------------------------------------------------------
  # ● 移出一个文本块
  #--------------------------------------------------------------------------
  def self.get
    return nil if empty?
    @data.shift
  end
  #--------------------------------------------------------------------------
  # ● 没有了文本块？
  #--------------------------------------------------------------------------
  def self.empty?
    @data.empty?
  end

  #--------------------------------------------------------------------------
  # ● 绘制角色肖像图
  #--------------------------------------------------------------------------
  def self.draw_face(bitmap, face_name, face_index, x, y, w=96, h=96)
    _bitmap = Cache.face(face_name)
    face_name =~ /_(\d+)x(\d+)_?/i  # 从文件名获取行数和列数（默认为2行4列）
    num_line = $1 ? $1.to_i : 2
    num_col = $2 ? $2.to_i : 4
    sole_w = _bitmap.width / num_col
    sole_h = _bitmap.height / num_line

    rect = Rect.new(face_index % 4 * sole_w, face_index / 4 * sole_h, sole_w, sole_h)
    des_rect = Rect.new(x, y, w, h)
    bitmap.stretch_blt(des_rect, _bitmap, rect)
  end
end
#===============================================================================
# ○ Game_Message
#===============================================================================
class Game_Message
  attr_accessor :eagle_chat_view
  #--------------------------------------------------------------------------
  # ● 清除
  #--------------------------------------------------------------------------
  alias eagle_message_chat_clear clear
  def clear
    eagle_message_chat_clear
    @eagle_chat_view ||= MESSAGE_CHAT::INIT_VIEW
  end
end
#===============================================================================
# ○ Window_EagleMessage_Chat
#===============================================================================
class Window_EagleMessage_Chat < Window
  attr_reader :vp_oy
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize
    super
    self.openness = 0
    init_sprite_hint
    @blocks = [] # 新的被push到最后
    @viewport = Viewport.new
    reset
  end
  #--------------------------------------------------------------------------
  # ● 设置显示视图
  #--------------------------------------------------------------------------
  def reset_viewport(_rect, _z = MESSAGE_CHAT::INIT_Z)
    @viewport.rect.set(_rect)
    @viewport.z = _z
    @sprite_hint.z = @viewport.z + 1
  end
  #--------------------------------------------------------------------------
  # ● 参数重置
  #--------------------------------------------------------------------------
  def reset
    @vp_oy = 0  # 视图的显示原点
    @d_oxy = 0  # 显示原点的移速
    @move_c = 0 # 移速的更新等待计数
    @blocks.each { |b| b.dispose }
    @blocks.clear
  end
  #--------------------------------------------------------------------------
  # ● 初始化提示精灵
  #--------------------------------------------------------------------------
  def init_sprite_hint
    @sprite_hint = Sprite.new
    @sprite_hint.visible = false
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    super
    dispose_sprite_hint
    @blocks.each { |b| b.dispose }
    @blocks.clear
    @viewport.dispose
    @viewport = nil
  end
  #--------------------------------------------------------------------------
  # ● 释放提示精灵
  #--------------------------------------------------------------------------
  def dispose_sprite_hint
    @sprite_hint.bitmap.dispose if @sprite_hint.bitmap
    @sprite_hint.dispose
  end
  #--------------------------------------------------------------------------
  # ● 显示提示精灵
  #--------------------------------------------------------------------------
  def show_sprite_hint
    MESSAGE_CHAT.draw_hints(@sprite_hint)
    @sprite_hint.visible = true
  end
  #--------------------------------------------------------------------------
  # ● 隐藏提示精灵
  #--------------------------------------------------------------------------
  def hide_sprite_hint
    @sprite_hint.visible = false
  end

  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
    update_fiber
    update_blocks
  end
  #--------------------------------------------------------------------------
  # ● 更新线程
  #--------------------------------------------------------------------------
  def update_fiber
    return @fiber.resume if @fiber
    return if !$game_switches[MESSAGE_CHAT::S_ID]
    @fiber = Fiber.new { fiber_main }
  end
  #--------------------------------------------------------------------------
  # ● 更新文本块
  #--------------------------------------------------------------------------
  def update_blocks
    @blocks.each { |b| b.update }
  end
  #--------------------------------------------------------------------------
  # ● 主线程
  #--------------------------------------------------------------------------
  def fiber_main
    reset_viewport($game_message.eagle_chat_view)
    show_sprite_hint
    loop do
      Fiber.yield
      update_reset_vp
      update_move if update_move?
      break if finish?
      add_new_block
    end
    hide_sprite_hint
    reset
    @fiber = nil
  end
  #--------------------------------------------------------------------------
  # ● 能够更新移动？
  #--------------------------------------------------------------------------
  def update_move?
    !@blocks.empty?
  end
  #--------------------------------------------------------------------------
  # ● 更新移动
  #--------------------------------------------------------------------------
  def update_move
    if Input.press?(:UP)
      @d_oxy -= 0.3
    elsif Input.press?(:DOWN)
      @d_oxy += 0.3
    end
    return if @d_oxy.to_i == 0
    if @blocks[-1].y - @blocks[-1].oy < 0
      @vp_oy -= (@d_oxy * 3)
      @d_oxy = 0
    end
    if @blocks[0].y - @blocks[0].oy > @viewport.rect.height - @blocks[0].height
      @vp_oy -= (@d_oxy * 3)
      @d_oxy = 0
    end
    @vp_oy += @d_oxy
    @move_c -= 1
    if @move_c <= 0 && @d_oxy != 0
      @move_c = 10
      @d_oxy -= @d_oxy / @d_oxy.abs
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新视角重置
  #--------------------------------------------------------------------------
  def update_reset_vp
    reset_vp_to_bottom if Input.trigger?(:A)
  end
  #--------------------------------------------------------------------------
  # ● 将视角移动到底部
  #--------------------------------------------------------------------------
  def reset_vp_to_bottom
    des_vp_oy = @blocks[-1]._y + @blocks[-1].height + 1 - @viewport.rect.height
    init_oy = @vp_oy
    d_oy = des_vp_oy - init_oy
    _i = 0; _t = 30
    while(true)
      break if _i > _t
      per = _i * 1.0 / _t
      per = (_i == _t ? 1 : ease_value(:vp_oy, per))
      @vp_oy = init_oy + d_oy * per
      Fiber.yield
      _i += 1
    end
    @d_oxy = 0
  end
  #--------------------------------------------------------------------------
  # ● 缓动函数
  #--------------------------------------------------------------------------
  def ease_value(type, x)
    1 - 2**(-10 * x)
  end
  #--------------------------------------------------------------------------
  # ● 结束？
  #--------------------------------------------------------------------------
  def finish?
    MESSAGE_CHAT.empty? && !$game_switches[MESSAGE_CHAT::S_ID]
  end
  #--------------------------------------------------------------------------
  # ● 新增一个文本块精灵
  #--------------------------------------------------------------------------
  def add_new_block
    d = MESSAGE_CHAT.get
    return if d.nil?
    s = Sprite_EagleMessage_Chat.new(self, @viewport, d)
    reset_positions(s)
    @blocks.push(s)
    s.update_position
    reset_vp_to_bottom if s.y - s.oy > @viewport.rect.height - s.height
  end
  #--------------------------------------------------------------------------
  # ● 重设全部文本块的位置
  #--------------------------------------------------------------------------
  def reset_positions(new_block)
    if @blocks.empty?
      y = @viewport.rect.height - new_block.height
    else
      y = @blocks[-1]._y + @blocks[-1].height
    end
    new_block.reset_position(0, y)
  end
end
#===============================================================================
# ○ Sprite_EagleMessage_Chat
#===============================================================================
class Sprite_EagleMessage_Chat < Sprite
  attr_reader :text, :params, :_x, :_y
  #--------------------------------------------------------------------------
  # ● 初始时
  #--------------------------------------------------------------------------
  def initialize(_window, _viewport, _params = {})
    super(_viewport)
    @window = _window
    init_params(_params)
    # 左对齐下，在viewport中的左上角的位置
    @_x = 0; @_y = 0
    # viewport中的显示位置偏移量，即以该点为显示原点
    @x0 = 0; @y0 = 0
    redraw
  end
  #--------------------------------------------------------------------------
  # ● 初始化参数（确保部分参数存在）
  #--------------------------------------------------------------------------
  def init_params(_params)
    @params = _params
    params[:name] ||= ""
    params[:face_name] ||= ""
    params[:position] ||= 0
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    self.bitmap.dispose if self.bitmap
    super
  end
  #--------------------------------------------------------------------------
  # ● 重设位置
  #--------------------------------------------------------------------------
  def reset_position(x, y)
    @_x = x if x
    @_y = y if y
  end
  #--------------------------------------------------------------------------
  # ● 获取背景色 1
  #--------------------------------------------------------------------------
  def back_color1
    Color.new(0, 0, 0, 160)
  end
  #--------------------------------------------------------------------------
  # ● 获取背景色 2
  #--------------------------------------------------------------------------
  def back_color2
    Color.new(0, 0, 0, 0)
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
    update_position
  end
  #--------------------------------------------------------------------------
  # ● 更新位置
  #--------------------------------------------------------------------------
  def update_position
    case params[:position]
    when 0 # 右对齐
      self.x = self.viewport.rect.width - self.width - @_x
    when 1
      self.x = (self.viewport.rect.width - self.width) / 2
    when 2 # 左对齐
      self.x = @_x
    end
    @y0 = @window.vp_oy if @window
    self.x = self.x - @x0
    self.y = @_y - @y0
  end
  #--------------------------------------------------------------------------
  # ● 重绘
  #--------------------------------------------------------------------------
  def redraw
    # 姓名高度
    name_h = 0
    if params[:name] != ""
      name_h = 16
    end
    # 脸图宽高
    face_w = 0
    face_h = 0
    if params[:face_name] != ""
      face_w = MESSAGE_CHAT::FACE_W
      face_h = MESSAGE_CHAT::FACE_H
    end
    # tag用的空白宽度
    tag_w = 8
    if params[:background] == 1 # 暗色背景无tag
      tag_w = 0
    end
    # 左右空白
    spacing_lr = 4
    # 上下空白
    spacing_ud = 2

    # 文本宽高
    text_w_max = self.viewport.rect.width - spacing_lr * 2 - face_w - tag_w
    ps = { :font_size => MESSAGE_CHAT::FONT_SIZE, :x0 => 0, :y0 => 0,
      :w => text_w_max }
    d = Process_DrawTextEX.new(params[:text], ps)
    d.run(false)
    text_w = d.width
    text_h = d.height

    # 实际位图宽高
    w = spacing_lr + face_w + tag_w + spacing_lr +
      [text_w + MESSAGE_CHAT::TEXT_BORDER_WIDTH * 2, 32].max
    h = spacing_ud + spacing_ud + 2 +
      [name_h + text_h + MESSAGE_CHAT::TEXT_BORDER_WIDTH * 2, face_h, 32].max
    self.bitmap = Bitmap.new(w, h)

    face_x = face_y = bg_x = bg_y = 0
    name_ali = 0
    case params[:position]
    when 0 # 居右（居上）
      face_x = w - spacing_lr - face_w
      bg_x = spacing_lr
      name_ali = 2
    when 1 # 居中
      face_x = spacing_lr
      bg_x = spacing_lr + face_w + tag_w
      name_ali = 1
    when 2 # 居左（居下）
      face_x = spacing_lr
      bg_x = spacing_lr + face_w + tag_w
      name_ali = 0
    end
    face_y = spacing_ud
    bg_y = spacing_ud + name_h
    bg_w = [text_w + MESSAGE_CHAT::TEXT_BORDER_WIDTH * 2, 32].max
    bg_h = [text_h + MESSAGE_CHAT::TEXT_BORDER_WIDTH * 2, 32].max

    # 绘制背景
    case params[:background]
    when 0 # 普通背景
      EAGLE.draw_windowskin("Window", self.bitmap,
        Rect.new(bg_x, bg_y, bg_w, bg_h))
    when 1 # 暗色背景
      rect1 = Rect.new(0, 0, w, 12)
      rect2 = Rect.new(0, 12, w, h - 24)
      rect3 = Rect.new(0, h - 12, w, 12)
      self.bitmap.gradient_fill_rect(rect1, back_color2, back_color1, true)
      self.bitmap.fill_rect(rect2, back_color1)
      self.bitmap.gradient_fill_rect(rect3, back_color1, back_color2, true)
    when 2 # 透明背景
    end

    # 绘制脸图
    if params[:face_name] != ""
      MESSAGE_CHAT.draw_face(self.bitmap, params[:face_name],
        params[:face_index], face_x, face_y, face_w, face_h)
    end

    # 绘制姓名
    if params[:name] != ""
      name_x = bg_x
      name_y = spacing_ud
      name_w = bg_w
      self.bitmap.font.size = MESSAGE_CHAT::NAME_FONT_SIZE
      self.bitmap.draw_text(name_x, name_y, name_w, name_h,
        params[:name], name_ali)
    end

    # 绘制文本
    text_x = bg_x + MESSAGE_CHAT::TEXT_BORDER_WIDTH
    text_y = bg_y + MESSAGE_CHAT::TEXT_BORDER_WIDTH
    ps = { :font_size => MESSAGE_CHAT::FONT_SIZE, :x0 => text_x, :y0 => text_y,
      :w => text_w_max }
    d = Process_DrawTextEX.new(params[:text], ps, self.bitmap)
    d.run(true)
  end
end

#===============================================================================
# ○ Game_Interpreter
#===============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 显示文字
  #--------------------------------------------------------------------------
  alias eagle_message_chat_command_101 command_101
  def command_101
    if $game_switches[MESSAGE_CHAT::S_ID]
      if $game_switches[MESSAGE_CHAT::S_ID_MSG] == false
        return call_message_chat
      end
    end
    eagle_message_chat_command_101
  end
  #--------------------------------------------------------------------------
  # ● 呼叫聊天对话
  #--------------------------------------------------------------------------
  def call_message_chat
    params = {}
    params[:face_name] = @params[0]
    params[:face_index] = @params[1]
    params[:background] = @params[2]
    params[:position] = @params[3]

    ts = []
    while next_event_code == 401       # 文字数据
      @index += 1
      ts.push(@list[@index].parameters[0])
    end
    t = ts.inject("") {|r, text| r += text + "\n" }
    MESSAGE_CHAT.extract_info(t, params)
    params[:text] = t
    MESSAGE_CHAT.add(params)

    if $imported["EAGLE-MessageLog"]
      ps = {}
      ps[:name] = params[:name] if !params[:name].empty?
      MSG_LOG.new_log(params[:text], ps)
    end

    Input.update
    Fiber.yield until message_chat_next?
  end
  #--------------------------------------------------------------------------
  # ● 聊天对话时 继续下一条指令？
  #--------------------------------------------------------------------------
  def message_chat_next?
    Input.trigger?(:C)
  end
end

#===============================================================================
# ○ Scene_Map
#===============================================================================
class Scene_Map < Scene_Base
  #--------------------------------------------------------------------------
  # ● 生成滚动文字窗口
  #--------------------------------------------------------------------------
  alias eagle_message_chat_scroll_window create_scroll_text_window
  def create_scroll_text_window
    eagle_message_chat_scroll_window
    @eagle_message_chat_window = Window_EagleMessage_Chat.new
  end
end
#===============================================================================
# ○ Scene_Battle
#===============================================================================
class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # ● 生成滚动文字窗口
  #--------------------------------------------------------------------------
  alias eagle_message_chat_scroll_window create_scroll_text_window
  def create_scroll_text_window
    eagle_message_chat_scroll_window
    @eagle_message_chat_window = Window_EagleMessage_Chat.new
  end
end
