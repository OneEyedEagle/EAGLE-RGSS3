#==============================================================================
# ■ 聊天式对话 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在
#  【组件-位图绘制转义符文本 by老鹰】与【组件-位图绘制窗口皮肤 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-MessageChat"] = "1.2.0"
#==============================================================================
# - 2024.6.30.12 增加移入动画
#==============================================================================
# - 本插件新增了仿QQ聊天的对话模式，以替换默认的 事件指令-显示文字
#------------------------------------------------------------------------------
# 【使用】
#
# - 当 S_ID 号开关开启时，事件指令-显示文字 将被替换成聊天式对话，
#    同时 事件指令-显示选项 将被替换成聊天式选择。
#
#    此时默认的对话框不再打开。
#
# - 当 S_ID 号开关关闭时，将立即关闭全部聊天式对话。
#
#---------------------------------------------------------------------------
# - 在 显示文字 中，新增了如下的编写规则：
#
#  （特别的，以下标签中的英语冒号均可以省略不写。）
#
#  1、在“显示位置”参数中，（默认“居下”，即左对齐）
#    “居上”= 右对齐，“居中”= 居中对齐，“居下”= 左对齐。
#
#  2、在“文本框”中，文本开头编写 【...】 或 [...] 用于指定姓名。
#    如： 【小明】今天天气真好
#    将显示姓名：小明；显示文本：今天天气真好
#
#  3、脸图规格扩展（同【对话框扩展 by老鹰】中的处理）
#      当脸图文件名包含 _数字1x数字2 时（其中为字母x），
#      将定义该脸图文件的规格为 行数（数字1）x列数（数字2）（默认2行x4列）
#    如：ace_actor_1x1.png → 该脸图规格为 1×1，含有一张脸图，只有index为0时生效
#
#     但由于排版限制，最终都会缩放至指定的 FACE_W * FACE_H 的大小进行显示，
#     因此请注意确保脸图大小为预设大小的整数倍，保证脸图不会因为缩放而模糊。
#
#  4、在“文本框”中，编写 <pic: filename> 用于显示图片。
#     （图片需放置于 Graphics/Pictures 目录下。）
#    如： 【小明】<pic bird_happy>
#    将显示姓名：小明；显示图片：bird_happy.png
#
#     注意：图片将被单独拆开，显示成一个新的聊天对话框。
#     （图片若大于可显示的最大宽度，将等比例缩小至最大宽度。）
#
#  5、在“文本框”中，编写 <no wait> 将不等待按键，将自动继续之后的事件指令。
#     （也可以写成 <nowait>，大小写均可。）
#
#  6、在“文本框”中，编写 <skin: id> 用于为当前的聊天对话框切换窗口皮肤。
#     其中 id 会先在 ID_TO_SKIN 常量中查找预设的名称映射，
#       若不存在，则认定其为窗口皮肤的名称（位于Graphics/System目录下）
#     如：<skin0> 将切换回默认皮肤
#     如：<skin Window_Blue> 将切换成 Window_Blue 名称的窗口皮肤文件
#
#  7、在“文本框”中，编写 <unsend: 数字> 用于在指定帧后撤回该对话（从开始显示计时）
#
#     特别的，可以使用数学表达式，并利用 s 代表开关组，v 代表变量组。
#
#     如：【小明】<pic: bird_happy><unsend200>我觉得不妥吧……
#     将显示姓名：小明；显示图片：bird_happy
#       显示姓名：小明；显示文本：我觉得不妥吧……
#       并且在200帧后撤回，显示撤回消息：小明撤回了一条消息
#
#     如：<unsend v[1]> 代表将在 1 号变量的值的帧数后撤回
#
#---------------------------------------------------------------------------
# - 在 显示选项 中，新增了如下的编写规则：
#
#  1、在选择支内容中新增条件扩展：
#
#     if{string} → 设置该选择支显示的条件
#     en{string} → 设置该选择支能够被选择的条件
#
#    对 string 的解析：eval(string)后返回布尔值用于判定，可用下列缩写进行简写
#      s 代替 $game_switches   v 代替 $game_variables
#
#    示例：
#      选项内容Aif{v[1]>0} → 该选择支只有在1号变量大于0时才正常显示，
#                          否则显示 TEXT_CHOICE_IF 指定的文本，且不可选择
#      选项内容Ben{s[2]} → 该选择支只有在2号开关开启时才能选择，否则提示禁止音效
#
#  2、在选择支内容中调用脚本输出：
#
#     rb{string} → eval(string) 的返回值将替换该内容
#
#  3、相邻且同级的 选择支处理 指令将自动合并（若不想自动合并，可在之间插入 注释 指令）
#
#    【注意】合并后只保留最后一个选项指令中的取消分支（其他选项指令的取消分支无效）
#
#---------------------------------------------------------------------------
# 【注意】
#
# - 由于聊天式对话支持上下方向键滚动查看，但选择框开启时并不会挂起该对话，
#    因此存在选择框切换时，聊天式对话同样滚动的情况
#
# - 本插件未设置背景图片，请自行使用 显示图片 事件指令添加
#
#---------------------------------------------------------------------------
# 【扩展】
#
# - 已经兼容【对话日志 by老鹰】，请将本插件置于它下面
#
#==============================================================================
module MESSAGE_CHAT
  #--------------------------------------------------------------------------
  # ○【常量】当该序号开关开启时，事件的 显示文章 将替换成 聊天式对话
  #--------------------------------------------------------------------------
  S_ID = 19
  #--------------------------------------------------------------------------
  # ○【常量】当S_ID序号开关开启时，该开关开启时，将重新使用默认对话框
  #  即不关闭 聊天式对话 的同时使用默认对话框
  #  【注意】需要手动关闭该开关，以确保聊天式对话能够正常继续使用！
  #--------------------------------------------------------------------------
  S_ID_MSG = 20
  #--------------------------------------------------------------------------
  # ○【常量】定义初始的视图矩形
  #--------------------------------------------------------------------------
  INIT_VIEW = Rect.new(20, 30, Graphics.width-20*2, Graphics.height-30*2)
  #--------------------------------------------------------------------------
  # ○【常量】定义初始的屏幕Z值
  #--------------------------------------------------------------------------
  INIT_Z = 10
  #--------------------------------------------------------------------------
  # ○【常量】定义文本块的初始Y位置（在视图中的位置）
  # 其中 <vph> 将被替换为视图的高度，<th> 将被替换成文本块的高度
  # 如 "<vph> - <th>" 代表最新的对话将位于视图的最底部
  #--------------------------------------------------------------------------
  INIT_TEXT_Y = "<vph> - <th>"
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
  # ○【常量】姓名文字的补足宽度（当发现姓名拥挤时，请尝试调大该值）
  #--------------------------------------------------------------------------
  NAME_FONT_W_ADD = 1
  #--------------------------------------------------------------------------
  # ○【常量】定义脸图的绘制宽度和高度
  #--------------------------------------------------------------------------
  FACE_W = 48
  FACE_H = 48
  #--------------------------------------------------------------------------
  # ○【常量】定义两个对话之间的Y方向间隔
  #--------------------------------------------------------------------------
  OFFSET = 2
  #--------------------------------------------------------------------------
  # ○【常量】定义取消分支的显示文本
  #--------------------------------------------------------------------------
  TEXT_CHOICE_CANCEL = "（不说话）"
  #--------------------------------------------------------------------------
  # ○【常量】定义if条件不足的分支的显示文本
  #--------------------------------------------------------------------------
  TEXT_CHOICE_IF =  "（？？？）"
  #--------------------------------------------------------------------------
  # ○【常量】定义撤回消息的显示文本
  #  其中 <name> 将被替换成姓名
  #--------------------------------------------------------------------------
  TEXT_UNSEND = "<name>撤回了一条消息"

  #--------------------------------------------------------------------------
  # ○【常量】定义对话框皮肤
  #--------------------------------------------------------------------------
  ID_TO_SKIN = {}
  ID_TO_SKIN[0] = "Window"  # 默认窗口皮肤
  #--------------------------------------------------------------------------
  # ○【常量】定义默认使用的对话框皮肤
  #--------------------------------------------------------------------------
  DEF_SKIN_ID = 0

  #--------------------------------------------------------------------------
  # ●【常量】提示文本的字体大小
  #--------------------------------------------------------------------------
  HINT_FONT_SIZE = 14
  #--------------------------------------------------------------------------
  # ● 【设置】绘制提示精灵
  #--------------------------------------------------------------------------
  def self.draw_hints(s, fs = {})
    s.bitmap ||= Bitmap.new(Graphics.width, 24)
    s.bitmap.clear
    s.bitmap.font.size = HINT_FONT_SIZE

    # 绘制长横线
    s.bitmap.fill_rect(0, 0, s.width, 1,
      Color.new(255,255,255,120))

    # 绘制
    t1 = ""
    t2 = ""
    t3 = ""

    if fs[:shift]
      t1 = "Shift键 - 回到底部"
    end
    if fs[:move]
      t2 = "上下键 - 滚动"
    end
    if fs[:text]
      t3 = "确定键 - 继续"
    end
    if fs[:choice]
      t2 += " | 切换"
      t3 = "确定键 - 选择"
      if fs[:choice].is_a?(Integer) && fs[:choice] >= 0
        t3 = "确定键、取消键 - 选择"
      end
    end

    if fs[:choice_lock]
      t1 = "确定键 - 选择"
      t2 = fs[:choice_lock]
      t3 = "取消键 - 撤销"
    end

    d = 10
    s.bitmap.draw_text(0+d, 2, s.width, s.height, t1, 0)
    s.bitmap.draw_text(0, 2, s.width-d, s.height, t3, 2)
    s.bitmap.draw_text(0, 2, s.width, s.height, t2, 1)

    # 设置摆放位置
    s.oy = s.height
    s.y = Graphics.height
  end

  #--------------------------------------------------------------------------
  # ● 从 显示文本 提取信息
  #--------------------------------------------------------------------------
  def self.extract_text_info(text, params)
    result = false # 是否成功导入了对话
    # 缩写
    s = $game_switches; v = $game_variables
    # 定义类型
    params[:type] = :text
    # 提取可能存在的flags
    text.gsub!( /<no ?wait>/im ) { params[:flag_no_wait] = true; "" }
    text.gsub!( /<skin:? ?(.*?)>/im ) { params[:skin] = $1; "" }
    text.gsub!( /<unsend:? ?(.*?)>/im ) { params[:unsend] = eval($1).to_i; "" }
    # 提取位于开头的姓名
    n = ""
    text.sub!(/^【(.*?)】|\[(.*?)\]/m) { n = $1 || $2; "" }
    params[:name] = n
    # 提取可能存在的显示图片（将独立为新的对话框显示）
    text.gsub!(/<pic:? ?(.*?)>/im) {
      _params = params.dup
      _params[:pic] = $1
      $game_message.add_chat(_params)
      result = true
      ""
    }
    # 提取文本 删去前后的换行
    text.chomp!
    text.sub!(/^\n/) { "" }
    params[:text] = text
    if text != ""
      $game_message.add_chat(params)
      result = true
    end
    return result
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
  #--------------------------------------------------------------------------
  # ● 获取窗口皮肤名称
  #--------------------------------------------------------------------------
  def self.get_skin_name(sym)
    return ID_TO_SKIN[sym] if ID_TO_SKIN.has_key?(sym)
    return ID_TO_SKIN[sym.to_i] if ID_TO_SKIN.has_key?(sym.to_i)
    return sym
  end

  #--------------------------------------------------------------------------
  # ● 初始化（绑定在Scene中）
  #--------------------------------------------------------------------------
  def self.init
    @ui = UI_EagleMessage_Chat.new
  end
  #--------------------------------------------------------------------------
  # ● 更新（绑定在Scene中）
  #--------------------------------------------------------------------------
  def self.update
    @ui.update
  end
end

#===============================================================================
# ○ Scene_Base
#===============================================================================
class Scene_Base
  #--------------------------------------------------------------------------
  # ● 开始后处理
  #--------------------------------------------------------------------------
  alias eagle_message_chat_post_start post_start
  def post_start
    MESSAGE_CHAT.init
    eagle_message_chat_post_start
  end
  #--------------------------------------------------------------------------
  # ● 基础更新
  #--------------------------------------------------------------------------
  alias eagle_message_chat_update_basic update_basic
  def update_basic
    eagle_message_chat_update_basic
    MESSAGE_CHAT.update
  end
end

#===============================================================================
# ○ Game_System
#===============================================================================
class Game_System
  #--------------------------------------------------------------------------
  # ● 读档后的处理
  #--------------------------------------------------------------------------
  alias eagle_message_chat_on_after_load on_after_load
  def on_after_load
    eagle_message_chat_on_after_load
    $game_message.load_latest_chat
  end
end
#===============================================================================
# ○ Game_Message
#===============================================================================
class Game_Message
  attr_accessor  :eagle_chat_params, :eagle_chat_choice_cancel_i_e
  #--------------------------------------------------------------------------
  # ● 清除
  #--------------------------------------------------------------------------
  alias eagle_message_chat_clear clear
  def clear
    eagle_message_chat_clear
    clear_chat_params
  end
  #--------------------------------------------------------------------------
  # ● 重置
  #--------------------------------------------------------------------------
  def clear_chat_params
    @eagle_chat_data = []
    @eagle_chat_params ||= {}
    @eagle_chat_params[:view] ||= MESSAGE_CHAT::INIT_VIEW
    @eagle_chat_params[:skin] ||= MESSAGE_CHAT::DEF_SKIN_ID
    @eagle_chat_choice_cancel_i_e = -1
    @eagle_chat_params[:type] = nil  # 最后导入的文本块的类型
    @eagle_chat_data_latest = nil  # 当clear时，清除保留的data
  end
  #--------------------------------------------------------------------------
  # ● 新增一个文本块
  #--------------------------------------------------------------------------
  def add_chat(data = {})
    @eagle_chat_data.push(data)
    @eagle_chat_data_latest = data # 保留最后一个data
  end
  #--------------------------------------------------------------------------
  # ● 移出一个文本块
  #--------------------------------------------------------------------------
  def get_chat
    return nil if chat_empty?
    @eagle_chat_data.shift
  end
  #--------------------------------------------------------------------------
  # ● 没有了文本块？
  #--------------------------------------------------------------------------
  def chat_empty?
    @eagle_chat_data.empty?
  end
  #--------------------------------------------------------------------------
  # ● 等待额外处理？
  #--------------------------------------------------------------------------
  def chat_busy?
    @eagle_chat_params[:type] != nil
  end
  #--------------------------------------------------------------------------
  # ● 需要在事件解释器中等待？
  #--------------------------------------------------------------------------
  def chat_wait?
    # 存在未处理的文本块 或 需要特别处理
    !chat_empty? || chat_busy?
  end
  #--------------------------------------------------------------------------
  # ● （读档后）重新显示上一个文本块（如果有的话）
  #--------------------------------------------------------------------------
  def load_latest_chat
    return if @eagle_chat_data_latest.nil?
    @eagle_chat_params[:type] = nil  # 清除旧的类型，保证顺利重新绘制
    add_chat(@eagle_chat_data_latest)
  end
end
#===============================================================================
# ○ UI_EagleMessage_Chat
#===============================================================================
class UI_EagleMessage_Chat
  attr_reader :vp_oy
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize
    init_sprite_hint
    @blocks = [] # 新的被push到最后
    @viewport = Viewport.new
    reset
  end
  #--------------------------------------------------------------------------
  # ● 被释放？
  #--------------------------------------------------------------------------
  def disposed?
    @viewport == nil #or @viewport.disposed?
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
    @flag_hints = {}
    change_hints(:add, :move)
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
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
    @sprite_hint.visible = true
  end
  #--------------------------------------------------------------------------
  # ● 隐藏提示精灵
  #--------------------------------------------------------------------------
  def hide_sprite_hint
    @sprite_hint.visible = false
  end
  #--------------------------------------------------------------------------
  # ● 更新提示
  #--------------------------------------------------------------------------
  def change_hints(type, sym, v = true)
    if type == :add
      return if @flag_hints[sym] == v
      @flag_hints[sym] = v
    elsif type == :del
      return if @flag_hints[sym] == nil
      @flag_hints.delete(sym)
    end
    MESSAGE_CHAT.draw_hints(@sprite_hint, @flag_hints)
  end

  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    update_viewport
    update_fiber
    update_blocks
  end
  #--------------------------------------------------------------------------
  # ● 更新视图
  #--------------------------------------------------------------------------
  def update_viewport
    #@viewport.tone.set($game_map.screen.tone)
    @viewport.ox = $game_map.screen.shake
    #@viewport.color.set($game_map.screen.flash_color)
    @viewport.update
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
    reset_viewport($game_message.eagle_chat_params[:view])
    show_sprite_hint
    loop do
      Fiber.yield
      update_move if update_move?
      update_new_blocks if update_new?
      update_extra_process if update_extra?
      break if finish?
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
    update_reset_vp
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
    s = @blocks[-1]
    if s.y != get_text_init_y(s)
      change_hints(:add, :shift)
      reset_vp_to_bottom if Input.trigger?(:A)
    else
      change_hints(:del, :shift)
    end
  end
  #--------------------------------------------------------------------------
  # ● 将视角移动到底部
  #--------------------------------------------------------------------------
  def reset_vp_to_bottom
    change_hints(:del, :shift)
    des_vp_oy = @blocks[-1]._y - get_text_init_y(@blocks[-1])
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
  # ● 更新新文本？
  #--------------------------------------------------------------------------
  def update_new?
    !$game_message.chat_empty? && !$game_message.chat_busy?
  end
  #--------------------------------------------------------------------------
  # ● 更新新文本
  #--------------------------------------------------------------------------
  def update_new_blocks
    loop do
      d = $game_message.get_chat
      break if d.nil?
      add_new_block(d)
    end
    s = @blocks[-1]
    reset_vp_to_bottom if s.y - s.oy > @viewport.rect.height - s.height
  end
  #--------------------------------------------------------------------------
  # ● 新增一个精灵
  #--------------------------------------------------------------------------
  def add_new_block(d)
    type = d[:type]
    s = method("add_new_block_#{type}").call(d)
    reset_position_with_new(s)
    @blocks.push(s)
    $game_message.eagle_chat_params[:type] = type
    change_hints(:add, type)
  end
  #--------------------------------------------------------------------------
  # ● 新增一个文本块
  #--------------------------------------------------------------------------
  def add_new_block_text(d)
    Sprite_EagleChat_Text.new(self, @viewport, d)
  end
  #--------------------------------------------------------------------------
  # ● 新增一个文本块-选项
  #--------------------------------------------------------------------------
  def add_new_block_choice(d)
    Sprite_EagleChat_Choice.new(self, @viewport, d)
  end
  #--------------------------------------------------------------------------
  # ● 重设文本块的位置（最新的文本块）
  #--------------------------------------------------------------------------
  def reset_position_with_new(new_block)
    if @blocks.empty?
      _y = get_text_init_y(new_block)
    else
      _y = @blocks[-1]._y + @blocks[-1].height + MESSAGE_CHAT::OFFSET
    end
    new_block.reset_position(0, _y)
    new_block.update_position
  end
  #--------------------------------------------------------------------------
  # ● 获取文本块的初始位置
  #--------------------------------------------------------------------------
  def get_text_init_y(block)
    # 缩写
    s = $game_switches; v = $game_variables
    t = MESSAGE_CHAT::INIT_TEXT_Y.dup
    t.gsub!( /<vph>/im ) { "#{@viewport.rect.height}" }
    t.gsub!( /<th>/im ) { "#{block.height}" }
    return eval(t).to_i
  end
  #--------------------------------------------------------------------------
  # ● 重设文本块的位置（从指定文本块开始）
  #--------------------------------------------------------------------------
  def reset_position_with_block(_block)
    return if @blocks.empty?
    i = @blocks.index(_block)
    loop do
      i += 1
      break if i >= @blocks.size
      _y = @blocks[i-1]._y + @blocks[i-1].height + MESSAGE_CHAT::OFFSET
      @blocks[i].reset_position(0, _y)
      @blocks[i].update_position
    end
  end

  #--------------------------------------------------------------------------
  # ● 特殊处理？
  #--------------------------------------------------------------------------
  def update_extra?
    $game_message.chat_busy?
  end
  #--------------------------------------------------------------------------
  # ● 特殊处理
  #--------------------------------------------------------------------------
  def update_extra_process
    type = $game_message.eagle_chat_params[:type]
    result = method("update_process_#{type}").call
    if result
      change_hints(:del, type)
      $game_message.eagle_chat_params[:type] = nil
    end
  end
  #--------------------------------------------------------------------------
  # ● 处理纯文字块
  #  - 按键后结束处理
  #--------------------------------------------------------------------------
  def update_process_text
    s = @blocks[-1]
    return true if s.params[:flag_no_wait]
    Input.trigger?(:C)
  end
  #--------------------------------------------------------------------------
  # ● 处理选项
  #  - 按键后结束处理
  #--------------------------------------------------------------------------
  def update_process_choice
    s = @blocks[-1]
    if !s.in_view?
      change_hints(:del, :choice)
      return false
    end
    change_hints(:add, :choice, s.params[:choice_cancel_type])
    # 选项切换
    if Input.trigger?(:UP)
      s.index -= 1
      Sound.play_cursor
      return false
    elsif Input.trigger?(:DOWN)
      s.index += 1
      Sound.play_cursor
      return false
    end
    # 选项决定
    f = nil
    f = true  if Input.trigger?(:C)
    f = false if s.params[:choice_cancel_type] >= 0 && Input.trigger?(:B)
    if f != nil
      Input.update
      if f && !s.selectable?
        Sound.play_buzzer
        return false
      end
      Sound.play_ok
      change_hints(:add, :choice_lock, f == false ? "选中取消项" : "选中选项")
      # 锁定当前项
      s.lock(f)
      r = false
      while true
        Fiber.yield
        # 再次确定，触发该项
        if Input.trigger?(:C)
          Sound.play_ok
          s.consider(f)
          r = true
          break
        # 返回选择
        elsif Input.trigger?(:B)
          Sound.play_cancel
          s.lock(nil)
          r = false
          break
        end
      end
      change_hints(:del, :choice_lock)
      return r
    end
    return false
  end

  #--------------------------------------------------------------------------
  # ● 结束显示？
  #--------------------------------------------------------------------------
  def finish?
    !$game_switches[MESSAGE_CHAT::S_ID]
  end
end

#===============================================================================
# ○ Sprite_EagleChat
#===============================================================================
class Sprite_EagleChat < Sprite
  attr_reader :params, :callbacks, :_x, :_y
  #--------------------------------------------------------------------------
  # ● 初始时
  #--------------------------------------------------------------------------
  def initialize(_window, _viewport, _params = {})
    super(_viewport)
    @window = _window
    # 左对齐下，在viewport中的左上角的位置
    @_x = 0; @_y = 0
    # viewport中的显示位置偏移量，即以该点为显示原点
    @x0 = 0; @y0 = 0
    # 移动用的增量
    @x_move = 0; @y_move = 0
    # 初始时
    init_params(_params)
    init_callbacks
    redraw
  end
  #--------------------------------------------------------------------------
  # ● 初始化参数（确保部分参数存在）
  #--------------------------------------------------------------------------
  def init_params(_params)
    @params = _params
    params[:face_name] ||= ""
    params[:face_index] ||= 0
    params[:background] ||= 0
    params[:position] ||= 1
    params[:name] ||= ""
    params[:skin] ||= $game_message.eagle_chat_params[:skin]
    
    case params[:position]
    when 0 # 右对齐
      @x_move = 12
    when 1
    when 2 # 左对齐
      @x_move = -12
    end
    self.opacity = 0
  end
  #--------------------------------------------------------------------------
  # ● 初始化倒计时处理
  #--------------------------------------------------------------------------
  def init_callbacks
    @callbacks = {}
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    self.bitmap.dispose if self.bitmap
    super
  end
  #--------------------------------------------------------------------------
  # ● 完整的在视图可视范围内？
  #--------------------------------------------------------------------------
  def in_view?
    self.y >= 0 && self.y + self.height <= self.viewport.rect.height
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
    update_callback
    update_move
    update_position
    update_opacity
  end
  #--------------------------------------------------------------------------
  # ● 更新处理
  #--------------------------------------------------------------------------
  def update_callback
  end
  #--------------------------------------------------------------------------
  # ● 更新移动增量
  #--------------------------------------------------------------------------
  def update_move
    if @x_move > 0
      @x_move -= 1
    elsif @x_move < 0
      @x_move += 1
    end
    if @y_move > 0
      @y_move -= 1
    elsif @y_move < 0
      @y_move += 1
    end
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
    self.x = self.x - @x0 + @x_move
    self.y = @_y - @y0 + @y_move
  end
  #--------------------------------------------------------------------------
  # ● 更新不透明度
  #--------------------------------------------------------------------------
  def update_opacity
    self.opacity += 30
  end
  #--------------------------------------------------------------------------
  # ● 重绘
  #--------------------------------------------------------------------------
  def redraw
    reset_constant
    redraw_name_wh
    redraw_face_wh
    redraw_tag_wh
    redraw_content_wh
    redraw_bg_wh
    recreate_bitmap
    redraw_bg
    redraw_tag
    redraw_face
    redraw_name
    redraw_content
  end
  #--------------------------------------------------------------------------
  # ● 设置常量
  #--------------------------------------------------------------------------
  def reset_constant
    # 对话框外围 左右空白
    params[:spacing_lr] = 4
    # 对话框外围 上下空白
    params[:spacing_ud] = 2
    # 姓名与背景之间的空白
    params[:spacing_name] = 2
  end
  #--------------------------------------------------------------------------
  # ● 获取姓名宽高
  #--------------------------------------------------------------------------
  def redraw_name_wh
    params[:name_w] = 0
    params[:name_h] = 0
    if params[:name] != ""
      _bitmap = Cache.empty_bitmap
      _bitmap.font.size = MESSAGE_CHAT::NAME_FONT_SIZE
      r = _bitmap.text_size(params[:name])
      params[:name_w] = r.width + MESSAGE_CHAT::NAME_FONT_W_ADD * params[:name].size
      params[:name_h] = r.height
      _bitmap.dispose
    end
  end
  #--------------------------------------------------------------------------
  # ● 获取脸图宽高
  #--------------------------------------------------------------------------
  def redraw_face_wh
    params[:face_w] = 0
    params[:face_h] = 0
    if params[:face_name] != ""
      params[:face_w] = MESSAGE_CHAT::FACE_W
      params[:face_h] = MESSAGE_CHAT::FACE_H
    end
  end
  #--------------------------------------------------------------------------
  # ● 获取小箭头宽高
  #--------------------------------------------------------------------------
  def redraw_tag_wh
    # 小箭头用的空白宽度
    params[:tag_w] = 8
    if params[:background] == 1 # 暗色背景无tag
      params[:tag_w] = 0
    end
  end
  #--------------------------------------------------------------------------
  # ● 获取内容宽高
  #--------------------------------------------------------------------------
  def redraw_content_wh
    params[:cont_w] = 0
    params[:cont_h] = 0
    # 最大内容宽度
    params[:cont_w_max] = self.viewport.rect.width - params[:spacing_lr] * 2 -
      params[:face_w] - params[:tag_w] - 2
  end
  #--------------------------------------------------------------------------
  # ● 获取背景宽高
  #--------------------------------------------------------------------------
  def redraw_bg_wh
    params[:bg_w] = [params[:cont_w] + MESSAGE_CHAT::TEXT_BORDER_WIDTH * 2, 32].max
    params[:bg_h] = [params[:cont_h] + MESSAGE_CHAT::TEXT_BORDER_WIDTH * 2, 32].max
  end
  #--------------------------------------------------------------------------
  # ● 设置位图
  #--------------------------------------------------------------------------
  def recreate_bitmap
    # 实际位图宽高
    w = params[:spacing_lr] * 2 + params[:face_w] + params[:tag_w] +
      [params[:cont_w] + MESSAGE_CHAT::TEXT_BORDER_WIDTH * 2, params[:name_w],
       32].max
    h = params[:spacing_ud] * 2 + params[:spacing_name] +
      [params[:name_h] + params[:cont_h] + MESSAGE_CHAT::TEXT_BORDER_WIDTH * 2,
       params[:face_h], 32].max
    self.bitmap = Bitmap.new(w, h)
  end
  #--------------------------------------------------------------------------
  # ● 绘制背景
  #--------------------------------------------------------------------------
  def redraw_bg
    params[:bg_x] = params[:bg_y] = 0
    case params[:position]
    when 0 # 居右（居上）
      params[:bg_x] = params[:spacing_lr]
      if params[:name_w] > params[:bg_w] # 如果姓名更长，则需要补足差值
        params[:bg_x] = params[:name_w] - params[:bg_w]
      end
    when 1 # 居中
      params[:bg_x] = params[:spacing_lr] + params[:face_w] + params[:tag_w]
    when 2 # 居左（居下）
      params[:bg_x] = params[:spacing_lr] + params[:face_w] + params[:tag_w]
    end
    params[:bg_y] = params[:spacing_ud] + params[:name_h] + params[:spacing_name]

    # 绘制背景
    case params[:background]
    when 0 # 普通背景
      skin = MESSAGE_CHAT.get_skin_name(params[:skin])
      EAGLE.draw_windowskin(skin, self.bitmap,
        Rect.new(params[:bg_x], params[:bg_y], params[:bg_w], params[:bg_h]))
    when 1 # 暗色背景
      w = self.bitmap.width
      h = self.bitmap.height
      rect1 = Rect.new(0, 0, w, 12)
      rect2 = Rect.new(0, 12, w, h - 24)
      rect3 = Rect.new(0, h - 12, w, 12)
      self.bitmap.gradient_fill_rect(rect1, back_color2, back_color1, true)
      self.bitmap.fill_rect(rect2, back_color1)
      self.bitmap.gradient_fill_rect(rect3, back_color1, back_color2, true)
    when 2 # 透明背景
    end
  end
  #--------------------------------------------------------------------------
  # ● 绘制姓名
  #--------------------------------------------------------------------------
  def redraw_name
    if params[:name] != ""
      name_ali = 0
      case params[:position]
      when 0 # 居右（居上）
        name_ali = 2
      when 1 # 居中
        name_ali = 1
      when 2 # 居左（居下）
        name_ali = 0
      end
      name_x = params[:bg_x]
      if params[:position] == 0 && params[:name_w] > params[:cont_w]
        name_x = params[:spacing_lr]
      end
      name_y = params[:spacing_ud]
      self.bitmap.font.size = MESSAGE_CHAT::NAME_FONT_SIZE
      self.bitmap.draw_text(name_x, name_y,
        [params[:name_w], params[:bg_w]].max, params[:name_h],
        params[:name], name_ali)
    end
  end
  #--------------------------------------------------------------------------
  # ● 绘制脸图
  #--------------------------------------------------------------------------
  def redraw_face
    if params[:face_name] != ""
      face_x = face_y = 0
      case params[:position]
      when 0 # 居右（居上）
        face_x = self.bitmap.width - params[:spacing_lr] - params[:face_w]
      when 1 # 居中
        face_x = params[:spacing_lr]
      when 2 # 居左（居下）
        face_x = params[:spacing_lr]
      end
      face_y = params[:spacing_ud]
      MESSAGE_CHAT.draw_face(self.bitmap, params[:face_name],
        params[:face_index], face_x, face_y, params[:face_w], params[:face_h])
    end
  end
  #--------------------------------------------------------------------------
  # ● 绘制TAG
  #--------------------------------------------------------------------------
  def redraw_tag
    # TODO
  end
  #--------------------------------------------------------------------------
  # ● 绘制内容
  #--------------------------------------------------------------------------
  def redraw_content
  end
end
#===============================================================================
# ○ Sprite_EagleChat_Text
#===============================================================================
class Sprite_EagleChat_Text < Sprite_EagleChat
  #--------------------------------------------------------------------------
  # ● 初始化参数（确保部分参数存在）
  #--------------------------------------------------------------------------
  def init_params(_params)
    super(_params)
    params[:text] ||= ""
    params[:pic] ||= ""
  end
  #--------------------------------------------------------------------------
  # ● 初始化倒计时处理
  #--------------------------------------------------------------------------
  def init_callbacks
    super
    if params[:unsend]
      callbacks[:unsend] = [params[:unsend].to_i, 1].max
      params.delete(:unsend)
    end
  end
  #--------------------------------------------------------------------------
  # ● 获取内容宽高
  #--------------------------------------------------------------------------
  def redraw_content_wh
    super
    if params[:text] != ""
      ps = { :font_size => MESSAGE_CHAT::FONT_SIZE, :x0 => 0, :y0 => 0,
        :w => params[:cont_w_max], :lhd => 2 }
      d = Process_DrawTextEX.new(params[:text], ps)
      d.run(false)
      params[:cont_w] = d.width
      params[:cont_h] = d.height
    elsif params[:pic] != ""
      bitmap_pic = Cache.picture(params[:pic]) rescue Cache.empty_bitmap
      params[:cont_w] = [bitmap_pic.width, params[:cont_w_max]].min
      params[:cont_h] = params[:cont_w] / bitmap_pic.width * bitmap_pic.height
    end
  end
  #--------------------------------------------------------------------------
  # ● 绘制内容
  #--------------------------------------------------------------------------
  def redraw_content
    super
    cont_x = params[:bg_x] + MESSAGE_CHAT::TEXT_BORDER_WIDTH
    cont_y = params[:bg_y] + MESSAGE_CHAT::TEXT_BORDER_WIDTH
    if params[:text] != ""
      ps = { :font_size => MESSAGE_CHAT::FONT_SIZE, :x0 => cont_x, :y0 => cont_y,
        :w => cont_x+params[:cont_w_max], :lhd => 2 }
      d = Process_DrawTextEX.new(params[:text], ps, self.bitmap)
      d.run(true)
    elsif params[:pic] != ""
      bitmap_pic = Cache.picture(params[:pic]) rescue Cache.empty_bitmap
      rect = Rect.new(0, 0, bitmap_pic.width, bitmap_pic.height)
      des_rect = Rect.new(cont_x, cont_y, params[:cont_w], params[:cont_h])
      self.bitmap.stretch_blt(des_rect, bitmap_pic, rect)
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新处理
  #--------------------------------------------------------------------------
  def update_callback
    super
    if callbacks[:unsend]
      callbacks[:unsend] -= 1
      unsend if callbacks[:unsend] <= 0
    end
  end
  #--------------------------------------------------------------------------
  # ● 撤回
  #--------------------------------------------------------------------------
  def unsend
    name = params[:name]
    params[:face_name] = ""
    params[:face_index] = 0
    params[:background] = 2
    params[:position] = 1
    params[:name] = ""
    t = MESSAGE_CHAT::TEXT_UNSEND.dup
    t.gsub! ( /<name>/im ) { name }
    params[:text] = t
    params[:pic] = ""
    redraw
    @window.reset_position_with_block(self)
    callbacks.delete(:unsend)
  end
end
#===============================================================================
# ○ Sprite_EagleChat_Choice
#===============================================================================
class Sprite_EagleChat_Choice < Sprite_EagleChat
  #--------------------------------------------------------------------------
  # ● 初始化参数（确保部分参数存在）
  #--------------------------------------------------------------------------
  def init_params(_params)
    super(_params)
    params[:choices] ||= []
    params[:choice_cancel_type] ||= 0

    params[:choices_draw] = []
    params[:choice_enables] = []
    params[:choice_ys] = []
    params[:choice_ws] = []
    params[:choice_hs] = []
    params[:choice_index] = 0
    params[:choice_result] = nil
    params[:lock] = nil
  end
  #--------------------------------------------------------------------------
  # ● 设置常量
  #--------------------------------------------------------------------------
  def reset_constant
    super
    # 选择项之间 空白
    params[:spacing_in] = 4
    # 预处理选项文本
    params[:choices].size.times { |i| pre_process_choice(i) }
  end
  #--------------------------------------------------------------------------
  # ● 预处理
  #--------------------------------------------------------------------------
  def pre_process_choice(i)
    # 缩写
    s = $game_switches; v = $game_variables
    # 当前选项文本
    text = params[:choices][i].dup
    # 判定rb{}
    text.gsub!(/(?i:rb){(.*?)}/) { eval($1) }
    # 判定en{}
    text.gsub!(/(?i:en){(.*?)}/) { "" }
    params[:choice_enables][i] = $1.nil? || eval($1) == true # 可选状态
    # 判定if{}
    text.gsub!(/(?i:if){(.*?)}/) { "" }
    if $1 && eval($1) == false
      params[:choice_enables][i] = false
      text = MESSAGE_CHAT::TEXT_CHOICE_IF
    end
    params[:choices_draw][i] = text
  end
  #--------------------------------------------------------------------------
  # ● 获取内容宽高
  #--------------------------------------------------------------------------
  def redraw_content_wh
    super
    return redraw_content_wh_result if params[:choice_result]

    params[:choice_ws].clear
    params[:choice_hs].clear
    params[:choice_enables].size.times { |i| check_choice(i) }
    params[:cont_w] = params[:choice_ws].max
    params[:cont_h] = params[:choice_hs].inject{|s, v| s + v} +
      params[:spacing_in] * (params[:choice_hs].size - 1)
  end
  #--------------------------------------------------------------------------
  # ● 处理指定选项
  #--------------------------------------------------------------------------
  def check_choice(i)
    ps = { :font_size => MESSAGE_CHAT::FONT_SIZE, :x0 => 0, :y0 => 0,
      :w => params[:cont_w_max], :lhd => 2 }
    d = Process_DrawTextEX.new(params[:choices_draw][i], ps)
    d.run(false)
    params[:choice_ws].push(d.width)
    params[:choice_hs].push(d.height)
  end
  #--------------------------------------------------------------------------
  # ● 获取内容宽高（选项完成）
  #--------------------------------------------------------------------------
  def redraw_content_wh_result
    params[:choice_result_text] = ""
    # 额外的取消分支
    if params[:choice_result] == $game_message.eagle_chat_choice_cancel_i_e &&
       $game_message.eagle_chat_choice_cancel_i_e == params[:choices].size
      params[:choice_result_text] = MESSAGE_CHAT::TEXT_CHOICE_CANCEL
    else
      params[:choice_result_text] = params[:choices][params[:choice_result]]
    end
    ps = { :font_size => MESSAGE_CHAT::FONT_SIZE, :x0 => 0, :y0 => 0,
      :w => params[:cont_w_max], :lhd => 2 }
    d = Process_DrawTextEX.new(params[:choice_result_text], ps)
    d.run(false)
    params[:cont_w] = d.width
    params[:cont_h] = d.height
  end
  #--------------------------------------------------------------------------
  # ● 重绘内容
  #--------------------------------------------------------------------------
  def redraw_content
    super
    return redraw_content_result if params[:choice_result]

    cont_x = params[:bg_x] + MESSAGE_CHAT::TEXT_BORDER_WIDTH
    cont_y = params[:bg_y] + MESSAGE_CHAT::TEXT_BORDER_WIDTH
    _y = cont_y
    params[:choices_draw].each_with_index do |t, i|
      params[:choice_ys][i] = _y
      ps = { :font_size => MESSAGE_CHAT::FONT_SIZE, :x0 => cont_x, :y0 => _y,
        :w => cont_x+params[:cont_w_max], :lhd => 2 }
      # 颜色处理
      #  若未被选中，则半透明
      ps[:trans] = params[:choice_index] != i
      #  若无法确定，则灰色
      if params[:choice_enables][i] == false
        ps[:font_color] = Color.new(100, 100, 100)
      end
      #  若锁定状态，则红色
      if params[:lock]
        ps[:trans] = params[:lock] != i
        ps[:font_color] = Color.new(255,50,50) if params[:lock] == i
      end
      d = Process_DrawTextEX.new(t, ps, self.bitmap)
      d.run(true)
      _y += params[:choice_hs][i] + params[:spacing_in]
    end
  end
  #--------------------------------------------------------------------------
  # ● 重绘内容（选项结果）
  #--------------------------------------------------------------------------
  def redraw_content_result
    cont_x = params[:bg_x] + MESSAGE_CHAT::TEXT_BORDER_WIDTH
    cont_y = params[:bg_y] + MESSAGE_CHAT::TEXT_BORDER_WIDTH
    ps = { :font_size => MESSAGE_CHAT::FONT_SIZE, :x0 => cont_x, :y0 => cont_y,
      :w => cont_x+params[:cont_w_max], :lhd => 2 }
    d = Process_DrawTextEX.new(params[:choice_result_text], ps, self.bitmap)
    d.run(true)
  end
  #--------------------------------------------------------------------------
  # ● 获取当前选项序号
  #--------------------------------------------------------------------------
  def index
    params[:choice_index]
  end
  #--------------------------------------------------------------------------
  # ● 设置当前选项
  #--------------------------------------------------------------------------
  def index=(i)
    params[:choice_index] = i
    params[:choice_index] = 0 if params[:choice_index] == params[:choices].size
    params[:choice_index] = params[:choices].size-1 if params[:choice_index] < 0
    redraw
  end
  #--------------------------------------------------------------------------
  # ● 可以被选择？
  #--------------------------------------------------------------------------
  def selectable?(i = nil)
    i ||= params[:choice_index]
    params[:choice_enables][i] == true
  end
  #--------------------------------------------------------------------------
  # ● 锁定当前项
  #--------------------------------------------------------------------------
  def lock(flag = true)
    if flag == true
      params[:lock] = params[:choice_index]
    elsif flag == false
      params[:lock] = params[:choice_cancel_type]
    else
      params[:lock] = nil
    end
    redraw
  end
  #--------------------------------------------------------------------------
  # ● 决定当前项
  #--------------------------------------------------------------------------
  def consider(flag = true)
    if flag == true
      params[:choice_result] = params[:choice_index]
    elsif flag == false
      params[:choice_result] = params[:choice_cancel_type]
    end
    redraw
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
        call_message_chat
        return
      end
    end
    eagle_message_chat_command_101
  end
  #--------------------------------------------------------------------------
  # ● 呼叫聊天对话
  #--------------------------------------------------------------------------
  def call_message_chat
    wait_for_chat
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
    result = MESSAGE_CHAT.extract_text_info(t, params)

    if $imported["EAGLE-MessageLog"]
      ps = {}
      ps[:name] = params[:name] if !params[:name].empty?
      MSG_LOG.new_log(params[:text], ps) if params[:text] != ""
    end

    case next_event_code
    when 102  # 显示选项
      @index += 1
      call_message_chat_choice(@list[@index].parameters, params.dup)
    end

    return if result == false
    wait_for_chat
  end
  #--------------------------------------------------------------------------
  # ● 等待聊天对话结束更新
  #--------------------------------------------------------------------------
  def wait_for_chat
    Input.update
    Fiber.yield while $game_message.chat_wait?
  end
  #--------------------------------------------------------------------------
  # ● 显示选项
  #--------------------------------------------------------------------------
  alias eagle_message_chat_command_102 command_102
  def command_102
    if $game_switches[MESSAGE_CHAT::S_ID]
      if $game_switches[MESSAGE_CHAT::S_ID_MSG] == false
        call_message_chat_choice(@params, {})
        return
      end
    end
    eagle_message_chat_command_102
  end
  #--------------------------------------------------------------------------
  # ● 处理选项
  #--------------------------------------------------------------------------
  def call_message_chat_choice(params, data)
    wait_for_chat

    data[:type] = :choice
    data[:choices] = []
    params[0].each {|s| data[:choices].push(s) }
    data[:choice_cancel_type] = params[1]-1
    # 处理合并选项，其中会将新选项直接传入 data[:choices] 中
    cancel_index = chat_merge_choice(data)
    # 设置取消分支的类型（事件中序号）
    #（对于params[1]）
    # 0 代表取消无效，1 ~ size 代表取消时进入对应分支，size+1 代表进入取消专用分支
    #（对于choice_cancel_i_e）
    # -1 代表无效，0 ~ size-1 代表对应分支，size代表取消分支
    #（对于choice_cancel_i_w）
    # -1 代表有独立取消分支，0 ~ win_size-1 代表对应窗口中分支
    data[:choice_cancel_type] = data[:choices].size if cancel_index >= 0
    # 存储全局变量，用于后续跳转
    $game_message.eagle_chat_choice_cancel_i_e = data[:choice_cancel_type]
    $game_message.add_chat(data)
    # 等待处理结束
    wait_for_chat
    # 处理跳转
    @branch[@indent] = data[:choice_result]

    if $imported["EAGLE-MessageLog"]
      t = data[:choice_result_text]
      MSG_LOG.new_log(t, { :choice => true })
    end
  end
  #--------------------------------------------------------------------------
  # ● 处理选项合并
  #--------------------------------------------------------------------------
  def chat_merge_choice(data)
    index = @index # 当前迭代到的指令的所在index # 主选项所在位置为 @index
    index_choice_add = 0 # 主选择项组的下一个选项的判别index的加值
    index_cancel = -1 # 最后一个有效的（之后没有其它主选项）取消分支的所在index
    while true # 未到最后一个
      index += 1
      return if @list[index].nil?
      # 大于主选项缩进值的命令全部跳过
      next if @list[index].indent > @list[@index].indent
      # 更新选择项分支的判别index为 原序号+主选项组选项数目
      @list[index].parameters[0] += index_choice_add if @list[index].code == 402
      # 更新取消分支的所在index记录
      index_cancel = index if @list[index].code == 403
      # 寻找该选择项组的结尾指令
      next if @list[index].code != 404
      # 如果接下来为新的选项组，则处理合并
      if @list[index + 1].code == 102
        # 更新当前主选项组的下一个选项分支的判别index的加值
        index_choice_add = @list[@index].parameters[0].size
        # 上一个存储的取消分支已经无效，将其code置为4031
        @list[index_cancel].code = 4031 if index_cancel >= 0
        index_cancel = -1
        @list[index].code = 0 # 删去该404指令（选项结束）
        index += 1
        @list[index].code = 0 # 删去该102指令（选项开始）
        # 该选项组的内容放入主选项组
        @list[index].parameters[0].each { |s|
          @list[@index].parameters[0].push(s)
          data[:choices].push(s)
        }
      else
        break
      end
    end # end of while
    index_cancel
  end
  #--------------------------------------------------------------------------
  # ● 取消的时候
  #--------------------------------------------------------------------------
  alias eagle_message_chat_command_403 command_403
  def command_403
    if $game_switches[MESSAGE_CHAT::S_ID]
      if $game_switches[MESSAGE_CHAT::S_ID_MSG] == false
        command_skip if @branch[@indent] != $game_message.eagle_chat_choice_cancel_i_e
        return
      end
    end
    eagle_message_chat_command_403
  end
  def command_4031
    command_skip
  end
end
