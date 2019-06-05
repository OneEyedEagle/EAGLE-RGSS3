#==============================================================================
# ■ Add-On 选择框扩展(new) by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【对话框扩展 by老鹰】之下
#==============================================================================
# - 2019.6.5.15 新增倒计时自动选择
#==============================================================================
# - 在对话框中利用 \choice[param] 对选择框进行部分参数设置：
#
#     i → 【默认】【重置】设置选择框光标初始所在的选择支
#         （从0开始计数，-1代表不选择）（按实际显示顺序）
#
#   （窗口属性）
#     o → 选择框的显示原点类型（九宫格小键盘）（默认7）（嵌入时固定为7）
#     x/y → 直接指定选择框的坐标（默认不设置）（利用参数重置进行清除）
#     do → 选择框的显示位置类型（覆盖x/y）（默认-10无效）
#          （0嵌入；1~9对话框外边界的九宫格位置；-1~-9屏幕外框的九宫格位置）
#          （当对话框关闭时，0~9的设置均无效）
#     dx/dy → x/y坐标的偏移增量（默认0）
#     w → 选择框的宽度（默认0不设置）（嵌入时该设置无效）
#         （不小于全部选项完整显示的最小宽度）
#     h → 选择框的高度（默认0不设置）（若小于行高，则识别为行数）
#     opa → 选择框的背景不透明度（默认255）（文字内容不透明度固定为255）
#         （嵌入时不显示窗口背景）
#     skin → 选择框皮肤类型（默认取对话框皮肤）（见index → 窗口皮肤文件名 的映射）
#
#   （选项属性）
#     cd  → 设置倒计时的秒数，倒计时结束时，自动选择取消选项（取消项必须有效）
#          （使用默认计时器；若有【计时器扩展 by老鹰】，则占用 :choice_cd 标志符）
#     ali → 选项文本的对齐方式（0左对齐，1居中，2右对齐）（默认0左对齐）
#     cit → 选项移入时，字与字的间隔帧数
#
#   （特殊）
#     charas → 定义预设开启的文字特效（文字特效转义符sym 到 变量参数字符串 的hash）
#              （只能在脚本中进行赋值）
#              （如：$game_message.choice_params[:charas][:cin] = 1
#                    # 用 对话框扩展 中的预设参数设置选择支移入方式）
#
#------------------------------------------------------------------------------
# - 在脚本中利用 $game_message.choice_params[sym] = value 对指定参数赋值
#  示例：
#     $game_message.choice_params[:i] = 1 # 下一次选项框的光标默认在第二个分支
#------------------------------------------------------------------------------
# - 在选择支内容中使用【对话框扩展】的转义符：
#    可用 \c[i] 与 \i[i] 转义符
#    可用 文本替换类 转义符（换行转义符无效）
#    可用 文本特效类 转义符
#------------------------------------------------------------------------------
# - 在选择支内容中新增条件扩展：
#
#     if{string} → 设置该选择支出现的条件
#     en{string} → 设置该选择支能够被选择的条件
#     cl{string} → 设置该选择支为取消项时的条件（按序逐个判定，成功则覆盖上次设置）
#
# - 对 string 的解析：eval(string)后返回布尔值用于判定，可用下列缩写进行简写
#     s 代替 $game_switches   v 代替 $game_variables
#
# - 示例：
#     选项内容Aif{v[1]>0} → 该选择支只有在1号变量值大于0时显示
#     选项内容Ben{s[2]} → 该选择支只有在2号开关开启时才能选择，否则提示禁止音效
#     选项内容Ccl{true} → 该选择支设定为取消分支（覆盖默认取消分支的设置）
#------------------------------------------------------------------------------
# - 在选择支内容中新增额外设置：
#
#     ex{params} → 对该条选择支进行额外的参数设置
#
# - 对 params 的解析：由 变量名 + 数字 构成（同 对话框扩展 中的变量参数字符串）
#     ali → 【默认】设置该选择支的对齐方式（覆盖选择框的设置）
#
# - 示例：
#     选项内容ex{ali1} → 该选择支居中对齐绘制
#------------------------------------------------------------------------------
# - 相邻且同级的 选择支处理 指令将自动合并（若不想自动合并，可在之间插入 注释 指令）
#  【注意】合并后只保留最后一个选项指令中的取消分支（其他选项指令的取消分支无效）
#------------------------------------------------------------------------------
# - 参数重置（具体见 对话框扩展 中的注释）
#      $game_message.reset_params(:choice, code_string)
#------------------------------------------------------------------------------
# - 注意：
#    ·VA默认选择框位置与对话框相关，而【对话框扩展 by老鹰】中对话框初始位置未知，
#      本插件将选择框的默认位置改成了o7时屏幕居中偏下的位置
#==============================================================================

#==============================================================================
# ○ 【设置部分】
#==============================================================================
module MESSAGE_EX
  #--------------------------------------------------------------------------
  # ● 【设置】定义转义符各参数的预设值
  # （对于bool型变量，0与false等价，1与true等价）
  #--------------------------------------------------------------------------
  CHOICE_PARAMS_INIT = {
  # \choice[]
    :i => 0, # 初始光标位置
    # 窗口属性
    :o => 7, # 原点类型
    :x => nil,
    :y => nil,
    :do => 0, # 显示位置类型
    :dx => 0,
    :dy => 0,
    :w => 0,
    :h => 0,
    :opa => 255, # 背景不透明度
    :skin => nil, # 皮肤类型（nil时代表跟随对话框）
    # 选项属性
    :cd => 0, # 倒计时结束后选择取消项（秒数）
    :ali => 0, # 选项对齐方式
    :cit => 0, # 文字显示的间隔帧数
    # 文字特效预设
    :charas => { :cin => "", :cout => "" },
  }
end
#==============================================================================
# ○ Game_Message
#==============================================================================
class Game_Message
  attr_accessor :choice_params, :method_choice_result, :choice_cancel_index
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  alias eagle_choicelist_ex_init initialize
  def initialize
    eagle_choicelist_ex_init
    set_default_params
    @choice_cancel_index = -1 # 取消分支的判别序号（事件中序号）
  end
  #--------------------------------------------------------------------------
  # ● 清除
  # 注：该方法在对话框处理完输入后被调用，所以默认的两个选项参数都被重置了
  #--------------------------------------------------------------------------
  alias eagle_choicelist_ex_clear clear
  def clear
    eagle_choicelist_ex_clear
    @method_choice_result = nil
  end
  #--------------------------------------------------------------------------
  # ● 获取全部可保存params的符号的数组
  #--------------------------------------------------------------------------
  alias eagle_choicelist_ex_params eagle_params
  def eagle_params
    eagle_choicelist_ex_params + [:choice]
  end
end
#==============================================================================
# ○ Window_Message
#==============================================================================
class Window_Message
  #--------------------------------------------------------------------------
  # ● 额外增加的窗口宽度高度
  #--------------------------------------------------------------------------
  alias eagle_choicelist_ex_window_width_add eagle_window_width_add
  def eagle_window_width_add(cur_width)
    w = eagle_choicelist_ex_window_width_add(cur_width)
    w += @choice_window.message_window_w_add if game_message.choice?
    w
  end
  alias eagle_choicelist_ex_window_height_add eagle_window_height_add
  def eagle_window_height_add(cur_height)
    h = eagle_choicelist_ex_window_height_add(cur_height)
    h += @choice_window.message_window_h_add if game_message.choice?
    h
  end
  #--------------------------------------------------------------------------
  # ● 设置choice参数
  #--------------------------------------------------------------------------
  def eagle_text_control_choice(param = "")
    parse_param(game_message.choice_params, param, :i)
  end
end
#==============================================================================
# ○ Window_ChoiceList
#==============================================================================
class Window_ChoiceList < Window_Command
  attr_reader :message_window
  attr_reader :message_window_w_add, :message_window_h_add
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  alias eagle_choicelist_ex_init initialize
  def initialize(message_window)
    @choices = {}
    @choices_info = {} # 选择支的窗口序号 => 信息组
    @choices_num = 0 # 存储总共显示出的选项数目

    @func_key_freeze = false # 冻结功能按键

    @message_window_w_add = @message_window_h_add = 0
    eagle_choicelist_ex_init(message_window)
  end
  #--------------------------------------------------------------------------
  # ● 重置
  #--------------------------------------------------------------------------
  def eagle_reset
    @choices_info.clear
    # 重置对话框wh增量
    @message_window_w_add = @message_window_h_add = 0
    # 重置默认光标位置
    $game_message.choice_params[:i] = MESSAGE_EX.get_default_params(:choice)[:i]
  end
  #--------------------------------------------------------------------------
  # ● 开始输入的处理（覆盖）
  #--------------------------------------------------------------------------
  def start
    process_choice_list
    reset_size
    refresh
    update_placement
    reset_params_ex
    set_init_select
    open
    activate
  end
  #--------------------------------------------------------------------------
  # ● 处理选项列表
  #--------------------------------------------------------------------------
  def process_choice_list
    i = 0 # 选择支的窗口序号
    $game_message.choices.each_with_index do |text, index|
      i += 1 if process_choice(text.dup, index, i, true)
    end
    @choices_num = i
  end
  #--------------------------------------------------------------------------
  # ● 处理指定选项
  # i_e 事件里该选择支的序号
  # i_w 窗口里该选择支的序号
  # apply_if 是否应用if语句的效果
  #--------------------------------------------------------------------------
  def process_choice(text, i_e, i_w, apply_if = true)
    # 缩写
    s = $game_switches; v = $game_variables
    # 判定if{}
    text.gsub!(/(?i:if){(.*?)}/) { "" }
    return false if apply_if && $1 && eval($1) == false # 跳过该选项的增加
    # 初始化对应hash信息组
    @choices_info[i_w] = {}
    @choices_info[i_w][:i_e] = i_e # 存储该选择支在事件页里的序号
    # 判定en{}
    text.gsub!(/(?i:en){(.*?)}/) { "" }
    @choices_info[i_w][:enable] = $1.nil? || eval($1) == true # 初始的启用状态
    # 判定cl{}
    text.gsub!(/(?i:cl){(.*?)}/) { "" }
    $game_message.choice_cancel_index = i_e if $1 && eval($1) == true
    # 判定ex{}
    @choices_info[i_w][:extra] = {}
    text.gsub!(/(?i:ex){(.*?)}/) { "" }
    MESSAGE_EX.parse_param(@choices_info[i_w][:extra], $1, :ali) if $1
    # 存储绘制的原始文本（去除全部判定文本）
    @choices_info[i_w][:text] = text
    # 计算原始文本占用的绘制宽度
    @choices_info[i_w][:width] = cal_width_line(text)
    return true # 成功设置一个需要显示的选项的信息
  end
  #--------------------------------------------------------------------------
  # ● 计算文本块的最大宽度（不计算\{\}转义符造成的影响）
  #--------------------------------------------------------------------------
  def cal_width_line(text)
    text_clone, array_width = text.dup, []
    text_clone.each_line do |line|
      line = @message_window.convert_escape_characters(line)
      line.gsub!(/\n/){ "" }; line.gsub!(/\e[\.\|\^\!\$<>\{|\}]/i){ "" }
      icon_length = 0; line.gsub!(/\ei\[\d+\]/i){ icon_length += 24; "" }
      line.gsub!(/\e\w+\[.*?\]/i){ "" } # 清除掉全部的\w[wd]格式转义符
      array_width.push(text_size(line).width + icon_length)
    end
    array_width.max
  end
  #--------------------------------------------------------------------------
  # ● 设置窗口大小
  #--------------------------------------------------------------------------
  def reset_size
    # 窗口高度
    self.height = fitting_height(@choices_num)
    h = @message_window.eagle_check_param_h($game_message.choice_params[:h])
    self.height = h + standard_padding * 2 if h > 0
    # 窗口宽度
    width_min = @choices_info.values.collect {|v| v[:width]}.max + 8
    self.width = width_min + standard_padding * 2
    self.width = $game_message.choice_params[:w] if $game_message.choice_params[:w] > self.width
    # 嵌入时宽度最小值（不含边界）
    width_min = self.width - standard_padding * 2

    # 嵌入对话框时的特别处理
    if @message_window.open? && $game_message.choice_params[:do] == 0
      self.openness = 255
      win_w = @message_window.eagle_charas_w
      if @message_window.eagle_dynamic_w?
        d = width_min - win_w
        if d > 0
          @message_window_w_add = d # 扩展对话框的宽度
        else # 宽度 = 文字区域宽度
          self.width = win_w + standard_padding * 2
        end
      else # 宽度 = 对话框宽度 - 脸图占用宽度
        self.width = @message_window.width - @message_window.eagle_face_width
      end
      win_h = @message_window.height - @message_window.eagle_charas_h
      if @message_window.eagle_dynamic_h? # 扩展对话框的高度
        d = self.height - win_h
        d += standard_padding if @message_window.eagle_charas_h > 0
        @message_window_h_add = d if d > 0
      else # 压缩高度
        self.height = [[height, win_h].min-standard_padding*2, item_height].max
        # 确保是行高的正整数倍数
        self.height = self.height/item_height*item_height + standard_padding*2
      end
      @message_window.eagle_process_draw_update
    end
    self.z = @message_window.z + 10 # 在文字绘制之前设置，保证文字精灵的z值
  end
  #--------------------------------------------------------------------------
  # ● 更新窗口的位置（覆盖）
  #--------------------------------------------------------------------------
  def update_placement
    self.x = (Graphics.width - width) / 2 # 默认位置
    self.y = Graphics.height - 100 - height

    self.x = $game_message.choice_params[:x] if $game_message.choice_params[:x]
    self.y = $game_message.choice_params[:y] if $game_message.choice_params[:y]
    o = $game_message.choice_params[:o]
    if (d_o = $game_message.choice_params[:do]) < 0 # 相对于屏幕
      MESSAGE_EX.reset_xy_dorigin(self, nil, d_o)
    else
      if @message_window.open?
        if d_o == 0 # 嵌入对话框
          self.x = @message_window.eagle_charas_x0 - standard_padding
          self.y = @message_window.eagle_charas_y0 + @message_window.eagle_charas_h
          self.y -= standard_padding if @message_window.eagle_charas_h == 0
          o = 7
        else
          MESSAGE_EX.reset_xy_dorigin(self, @message_window, d_o)
        end
      end
    end
    MESSAGE_EX.reset_xy_origin(self, o)
    self.x += $game_message.choice_params[:dx]
    self.y += $game_message.choice_params[:dy]
    self.ox = self.oy = 0
  end
  #--------------------------------------------------------------------------
  # ● 设置其他属性
  #--------------------------------------------------------------------------
  def reset_params_ex
    skin = $game_message.choice_params[:skin]
    if $game_message.pop? && !$game_message.pop_params[:skin].nil?
      skin ||= $game_message.pop_params[:skin]
    else
      skin ||= $game_message.win_params[:skin]
    end
    self.windowskin = MESSAGE_EX.windowskin(skin)
    self.opacity = $game_message.choice_params[:opa]
    self.opacity = 0 if @message_window.open? && $game_message.choice_params[:do] == 0
    self.contents_opacity = 255

    if cancel_enabled? && $game_message.choice_params[:cd] > 0
      count = $game_message.choice_params[:cd] * 60
      if $imported["EAGLE-TimerEX"]
        p1 = { :text => "选择倒计时...", :icon => 280 }
        $game_timer[:choice_cd].start(count, p1)
      else
        $game_timer.start(count)
      end
    else
      $game_message.choice_params[:cd] = 0
    end
  end
  #--------------------------------------------------------------------------
  # ● 设置初始选项位置
  #--------------------------------------------------------------------------
  def set_init_select
    i = $game_message.choice_params[:i]
    return unselect if i < 0
    select(i)
  end

  #--------------------------------------------------------------------------
  # ● 生成指令列表（覆盖）
  #--------------------------------------------------------------------------
  def make_command_list
    @choices_info.each { |i, v| add_command(v[:text], :choice, v[:enable]) }
  end
  #--------------------------------------------------------------------------
  # ● 获取指令名称（覆盖）
  #--------------------------------------------------------------------------
  def command_name(index)
    @choices_info[index][:text]
  end
  #--------------------------------------------------------------------------
  # ● 获取指令的有效状态（覆盖）
  #--------------------------------------------------------------------------
  def command_enabled?(index)
    @choices_info[index][:enable]
  end
  #--------------------------------------------------------------------------
  # ● 绘制项目（覆盖）
  #--------------------------------------------------------------------------
  def draw_item(index)
    rect = item_rect_for_text(index)
    dw = self.width - standard_padding*2 - 8 - @choices_info[index][:width]
    ali = @choices_info[index][:extra][:ali] || $game_message.choice_params[:ali]
    case ali
    when 0; x_ = rect.x
    when 1; x_ = rect.x + dw / 2
    when 2; x_ = rect.x + dw
    end
    @choices[index] = Spriteset_Choice.new(self)
    @choices[index].set_xy(x_, rect.y)
    @choices[index].set_enabled(command_enabled?(index))
    @choices[index].draw_text_ex(2, 3, command_name(index))
    @choices[index].update
  end
  #--------------------------------------------------------------------------
  # ● 更新光标
  #--------------------------------------------------------------------------
  alias eagle_choice_ex_update_cursor update_cursor
  def update_cursor
    eagle_choice_ex_update_cursor
    @choices.each do |i, s|
      r = item_rect_for_text(i)
      y_ = r.y - self.oy
      s.set_visible( y_ >= 0 && y_ < (self.height-line_height) )
      s.set_xy( r.x, y_ )
    end
  end

  #--------------------------------------------------------------------------
  # ● 更新（覆盖）
  #--------------------------------------------------------------------------
  def update
    super
    return if !self.active
    @choices.each { |i, s| s.update }
    check_cd_auto if $game_message.choice_params[:cd] > 0
    #check_cd_replace if $game_message.choice_params[:cd] > 0
  end
  #--------------------------------------------------------------------------
  # ● 检查倒计时后自动选择
  #--------------------------------------------------------------------------
  def check_cd_auto
    if $imported["EAGLE-TimerEX"]
      return if !$game_timer[:choice_cd].finish?
    else
      return if $game_timer.sec > 0
    end
    deactivate
    call_cancel_handler
  end
  #--------------------------------------------------------------------------
  # ● 检查倒计时后替换 #TODO
  #--------------------------------------------------------------------------
  def check_cd_replace
    if $imported["EAGLE-TimerEX"]
      return if !$game_timer[:choice_cd].finish?
    else
      return if $game_timer.sec > 0
    end
    replace_choice(3, 2)
    $game_message.choice_params[:cd] = 0
  end
  #--------------------------------------------------------------------------
  # ● 用事件中i_e_new号选项分支替换窗口中i_w号选项
  #--------------------------------------------------------------------------
  def replace_choice(i_e_new, i_w)
    @choices[i_w].move_out
    process_choice($game_message.choices[i_e_new].dup, i_e_new, i_w, false)
    redraw_item(i_w)
    reset_size; update_placement # 更新窗口大小和位置
  end
  #--------------------------------------------------------------------------
  # ● “确定”和“取消”的处理
  #--------------------------------------------------------------------------
  alias eagle_choicelist_ex_process_handling process_handling
  def process_handling
    return if @func_key_freeze
    eagle_choicelist_ex_process_handling
  end
  #--------------------------------------------------------------------------
  # ● 获取“取消处理”的有效状态（覆盖）
  #--------------------------------------------------------------------------
  def cancel_enabled?
    $game_message.choice_cancel_index >= 0
  end
  #--------------------------------------------------------------------------
  # ● 调用“确定”的处理方法（覆盖）
  #--------------------------------------------------------------------------
  def call_ok_handler
    $game_message.method_choice_result.call(@choices_info[index][:i_e])
    close
  end
  #--------------------------------------------------------------------------
  # ● 调用“取消”的处理方法（覆盖）
  #--------------------------------------------------------------------------
  def call_cancel_handler
    $game_message.method_choice_result.call($game_message.choice_cancel_index)
    close
  end
  #--------------------------------------------------------------------------
  # ● 关闭
  #--------------------------------------------------------------------------
  alias eagle_choicelist_ex_close close
  def close
    @choices.each { |i, s| s.move_out }
    eagle_reset
    eagle_choicelist_ex_close
    if $imported["EAGLE-TimerEX"]
      $game_timer[:choice_cd].stop
    else
      $game_timer.stop
    end
  end
end
#==============================================================================
# ○ Spriteset_Choice
#==============================================================================
class Spriteset_Choice
  include MESSAGE_EX::CHARA_EFFECTS
  attr_reader :font
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(choice_window)
    @choice_window = choice_window
    @charas = []
    @chara_effect_params = $game_message.choice_params[:charas].dup
    @chara_win_dx = 0
    @chara_win_dy = 0
    @font = @choice_window.contents.font.dup # 每个选项存储独立的font对象
    @visible = true
    @enabled = true
  end
  #--------------------------------------------------------------------------
  # ● 绑定
  #--------------------------------------------------------------------------
  def message_window
    @choice_window.message_window
  end
  def z
    @choice_window.z + 1
  end
  #--------------------------------------------------------------------------
  # ● 设置文字的左侧起始位置（相对于选项窗口的左上角）
  #--------------------------------------------------------------------------
  def set_xy(x = nil, y = nil)
    @chara_win_dx = x if x
    @chara_win_dy = y if y
  end
  #--------------------------------------------------------------------------
  # ● 绑定
  #--------------------------------------------------------------------------
  def eagle_charas_x0
    @choice_window.x + @choice_window.standard_padding + @chara_win_dx
  end
  def eagle_charas_y0
    @choice_window.y + @choice_window.standard_padding + @chara_win_dy
  end
  #--------------------------------------------------------------------------
  # ● 设置文字的显示状态
  #--------------------------------------------------------------------------
  def set_visible(bool)
    @visible = bool
    @charas.each { |s| s.visible = bool }
  end
  #--------------------------------------------------------------------------
  # ● 设置选项的可选状态
  #--------------------------------------------------------------------------
  def set_enabled(bool)
    @enabled = bool
    change_color(font.color)
  end
  #--------------------------------------------------------------------------
  # ● 更改内容绘制颜色
  #--------------------------------------------------------------------------
  def change_color(color)
    font.color.set(color)
    font.color.alpha = 120 unless @enabled
  end
  #--------------------------------------------------------------------------
  # ● 全部移出
  #--------------------------------------------------------------------------
  def move_out
    @charas.each { |s| s.opacity = 0 if !s.visible; s.move_out }
    @charas.clear
  end
  #--------------------------------------------------------------------------
  # ● 应用文本特效
  #--------------------------------------------------------------------------
  def start_effects(params)
    @charas.each { |s| s.start_effects(params) }
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    return unless @visible
    @fiber.resume if @fiber
    @charas.each { |s| s.update }
  end
  #--------------------------------------------------------------------------
  # ● 绘制
  #--------------------------------------------------------------------------
  def draw_text_ex(x, y, text)
    @fiber = Fiber.new {
      change_color(message_window.normal_color)
      text = message_window.convert_escape_characters(text)
      pos = {:x => x, :y => y, :height => 24}
      process_character(text.slice!(0, 1), text, pos) until text.empty?
      @fiber = nil
    }
  end
  #--------------------------------------------------------------------------
  # ● 文字的处理
  #     c    : 文字
  #     text : 绘制处理中的字符串缓存（字符串可能会被修改）
  #     pos  : 绘制位置 {:x, :y, :new_x, :height}
  #--------------------------------------------------------------------------
  def process_character(c, text, pos)
    case c
    when "\r", "\n", "\f"   # 回车 # 换行 # 翻页
      return
    when "\e"   # 控制符
      process_escape_character(message_window.obtain_escape_code(text), text, pos)
    else        # 普通文字
      process_normal_character(c, pos)
      process_draw_success
    end
  end
  #--------------------------------------------------------------------------
  # ● 处理普通文字
  #--------------------------------------------------------------------------
  def process_normal_character(c, pos)
    c_rect = message_window.text_size(c)
    c_w = c_rect.width; c_h = c_rect.height
    s = eagle_new_chara_sprite(c, pos[:x], pos[:y], c_w, c_h)
    s.bitmap.draw_text(0, 0, c_w, c_h, c, 0)
    pos[:x] += c_w
  end
  #--------------------------------------------------------------------------
  # ● （封装）生成一个新的文字精灵
  #--------------------------------------------------------------------------
  def eagle_new_chara_sprite(c, c_x, c_y, c_w, c_h)
    s = Sprite_EagleCharacter.new(self, c, c_x, c_y, c_w, c_h)
    s.start_effects(@chara_effect_params)
    @charas.push(s)
    s
  end
  #--------------------------------------------------------------------------
  # ● 控制符的处理
  #     code : 控制符的实际形式（比如“\C[1]”是“C”）
  #     text : 绘制处理中的字符串缓存（字符串可能会被修改）
  #     pos  : 绘制位置 {:x, :y, :new_x, :height}
  #--------------------------------------------------------------------------
  def process_escape_character(code, text, pos)
    temp_code = code.downcase
    m_e = ("eagle_chara_effect_" + temp_code).to_sym
    if respond_to?(m_e)
      param = message_window.obtain_escape_param_string(text)
      # 当只传入 0 时，代表关闭该特效
      return @chara_effect_params.delete(temp_code.to_sym) if param == '0'
      @chara_effect_params[temp_code.to_sym] = param
      method(m_e).call(param)
      return
    end
    case code.upcase
    when 'C'
      change_color(@choice_window.text_color(message_window.obtain_escape_param(text)))
    when 'I'
      process_draw_icon(message_window.obtain_escape_param(text), pos)
      process_draw_success
    end
  end
  #--------------------------------------------------------------------------
  # ● 处理控制符指定的图标绘制
  #--------------------------------------------------------------------------
  def process_draw_icon(icon_index, pos)
    s = eagle_new_chara_sprite(' ', pos[:x], pos[:y], 24, 24)
    _bitmap = Cache.system("Iconset")
    rect = Rect.new(icon_index % 16 * 24, icon_index / 16 * 24, 24, 24)
    s.bitmap.blt(0, 0, _bitmap, rect, 255)
    pos[:x] += 24
  end
  #--------------------------------------------------------------------------
  # ● 成功绘制后的处理
  #--------------------------------------------------------------------------
  def process_draw_success
    $game_message.choice_params[:cit].times { Fiber.yield }
  end
end

#==============================================================================
# ○ Game_Interpreter
#==============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 设置选项（覆盖）
  #--------------------------------------------------------------------------
  def setup_choices(params)
    index_cancel = eagle_merge_choices
    params = @list[@index].parameters
    params[0].each {|s| $game_message.choices.push(s) }
    # 绑定返回方法
    $game_message.method_choice_result = method(:eagle_choice_result)
    # 设置取消分支的类型
    #（对于params[1]）
    # 0 代表取消无效，1 ~ size 代表取消时进入对应分支，size+1 代表进入取消专用分支
    #（对于choice_cancel_index）
    # -1 代表无效，0 ~ size-1 代表对应分支，size代表取消分支
    $game_message.choice_cancel_index = params[1] - 1
    $game_message.choice_cancel_index = params[0].size if index_cancel >= 0
  end
  #--------------------------------------------------------------------------
  # ● 合并相邻选项指令
  #  返回 - 最后一个有效的取消分支的事件列表位置index
  #--------------------------------------------------------------------------
  def eagle_merge_choices
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
        @list[index].parameters[0].each { |s| @list[@index].parameters[0].push(s) }
      else
        break
      end
    end # end of while
    index_cancel
  end
  #--------------------------------------------------------------------------
  # ● 设置选项窗口返回的分支判别index
  #--------------------------------------------------------------------------
  def eagle_choice_result(n)
    @branch[@indent] = n
  end
  #--------------------------------------------------------------------------
  # ● 取消的时候（覆盖）
  #--------------------------------------------------------------------------
  def command_403
    command_skip if @branch[@indent] != $game_message.choice_cancel_index
  end
  def command_4031
    command_skip
  end
end
