#==============================================================================
# ■ Add-On 选择框扩展 by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【对话框扩展 by老鹰】之下
#==============================================================================
# - 2019.4.7.23 新增倒计时选择支
#==============================================================================
# - 在对话框中利用 \choice[param] 对选择框进行部分参数设置：
#     i - 【默认】【重置】设置选择框光标初始所在的选择支
#         （从0开始计数，-1代表不选择）（按实际显示顺序）
#     o - 选择框的显示原点类型（九宫格小键盘）（默认7）（嵌入时固定为7）
#     x/y - 直接指定选择框的坐标（默认不设置）（利用参数重置进行清除）
#     do - 选择框的显示位置类型（覆盖x/y）（默认-10无效）
#          （0为嵌入；1~9对话框外边界的九宫格位置；-1~-9屏幕外框的九宫格位置）
#          （当对话框关闭时，0~9的设置均无效）
#     dx/dy - x/y坐标的偏移增量（默认0）
#     w - 设置选择框的宽度（默认0不设置）（嵌入时该设置无效）
#         （不小于全部选项完整显示的最小宽度）
#     h - 设置选择框的高度（默认0不设置）（若小于行高，则为行数）
#     ali - 选项文本的对齐方式（0左对齐，1居中，2右对齐）（默认0左对齐）
#     opa - 选择框的背景不透明度（默认255）（文字内容不透明度固定为255）
#         （嵌入do=0时不显示窗口背景）
#     skin - 选择框皮肤类型（每次默认取对话框皮肤）（见index → windowskin名称 的映射）
#------------------------------------------------------------------------------
# - 在 事件脚本 中利用 $game_message.choice_params[sym] = value 对指定参数赋值
#   举例：
#     $game_message.choice_params[:i] = 1 # 下一次选项框的光标默认在第二个分支
#------------------------------------------------------------------------------
# - 在选择支内容中新增条件扩展：
#
#     if{string} - 设置该选择支出现的条件
#     en{string} - 设置该选择支能够被选择的条件
#     cl{string} - 设置该选择支为取消项时的条件（按序逐个判定，成功则覆盖上次设置）
#
#   对 string 的解析：eval后返回布尔值，可用下列缩写进行简写
#     s 代替 $game_switches    v 代替 $game_variables
#
#   示例：
#     选项内容Aif{v[1]>0} - 该选择支只有在1号变量值大于0时显示
#     选项内容Ben{s[2]} - 该选择支只有在2号开关开启时才能选择，否则提示禁止音效
#     选项内容Ccl{true} - 该选择支设定为取消分支（覆盖默认取消分支的设置）
#------------------------------------------------------------------------------
# - 在选择支内容中新增额外设置：
#
#     ex{params} - 对该条选择支进行额外的参数设置
#
#   对 params 的解析：由 变量名 + 数字 构成（同 对话框扩展 中的变量参数字符串）
#     ali - 【默认】设置该选择支的对齐方式（覆盖选择框的设置）
#     t - 【重置】设置该选择支在倒计时结束后将自动被选择（只有最后一个有效）（单位为帧）
#     tv - 【重置】设置该选择支的倒计时文本是否显示（1为显示，0为不显示）（默认显示）
#
#   示例：
#     选项内容Dex{ali1} - 该选择支居中对齐绘制
#------------------------------------------------------------------------------
# - 相邻的同级的 选择支处理 指令将自动合并（若不想自动合并，可在之间插入 注释 指令）
#  【注意】合并后只保留最后出现的一个取消分支
#------------------------------------------------------------------------------
# - 参数重置（具体见 对话框扩展 中的注释）
#      $game_message.reset_params(:choice, code_string)
#------------------------------------------------------------------------------
# - 注意：
#    ·VA默认选择框位置与对话框相关，而 对话框扩展 中对话框初始位置未知，
#       本插件将选择框的默认位置改成了o7时屏幕居中偏下的位置
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
    :i => -1, # 初始光标位置
    :o => 7, # 原点类型
    :x => nil,
    :y => nil,
    :do => 0, # 显示位置类型
    :dx => 0,
    :dy => 0,
    :w => 0,
    :h => 0,
    :ali => 0, # 选项对齐方式
    :opa => 255, # 背景不透明度
    :skin => nil, # 皮肤类型（nil时代表跟随对话框）
  }
  #--------------------------------------------------------------------------
  # ● 【设置】倒计时选择支的文本格式
  #  <choice> 将会被替换成原始选择支内容
  #  <time> 将会被替换成倒计时秒数
  #--------------------------------------------------------------------------
  CHOICE_AUTO_CD_TEXT = "<choice> / <time> s"
  #--------------------------------------------------------------------------
  # ● 【设置】倒计时选择支自动选中后，重新绘制时添加的前缀
  #  （由于重绘时没有重置选择框大小，所以不推荐新增绘制文本）
  #  其中转义符用 \\ 代替 \
  #--------------------------------------------------------------------------
  CHOICE_AUTO_TEXT_OK_PREFIX = "\\c[1]"
  #--------------------------------------------------------------------------
  # ● 获取倒计时选择支的文本
  #--------------------------------------------------------------------------
  def self.get_auto_cd_choice_text(text, frame)
    t = CHOICE_AUTO_CD_TEXT.dup
    v = frame / 60 + (frame % 60 > 0 ? 1 : 0)
    t.sub!(/<choice>/) { text }
    t.sub!(/<time>/) { sprintf("%2d", v) }
    t
  end
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
    @choice_cancel_index = -1 # 取消分支的判别index
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
  attr_reader :message_window_w_add, :message_window_h_add
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  alias eagle_choicelist_ex_init initialize
  def initialize(message_window)
    @choices_texts = []
    @choices_info = {} # 选择支在窗口中的index => 信息组
    @func_key_freeze = false # 冻结功能按键
    @choice_auto_t = 0 # 倒计时计数
    @choice_auto_index = -1 # 倒计时的选择支index（实际显示index）
    @choice_auto_show = false # 是否要修改选项文本
    @choice_auto_ok = false # 倒计时的选择支被自动选中？
    @message_window_w_add = @message_window_h_add = 0
    eagle_choicelist_ex_init(message_window)
  end
  #--------------------------------------------------------------------------
  # ● 关闭
  #--------------------------------------------------------------------------
  alias eagle_choicelist_ex_close close
  def close
    # 重置对话框wh增量
    @message_window_w_add = @message_window_h_add = 0
    # 重置默认光标位置
    $game_message.choice_params[:i] = MESSAGE_EX.get_default_params(:choice)[:i]
    # 重置倒计时选择支index
    @choice_auto_index = -1
    eagle_choicelist_ex_close
  end
  #--------------------------------------------------------------------------
  # ● 开始输入的处理（覆盖）
  #--------------------------------------------------------------------------
  def start
    process_choices
    update_size
    refresh
    update_placement
    update_params_ex
    set_init_select
    open
    activate
  end
  #--------------------------------------------------------------------------
  # ● 设置初始选项位置
  #--------------------------------------------------------------------------
  def set_init_select
    i = $game_message.choice_params[:i]
    if i < 0
      unselect
      return self.oy = 0
    end
    select(i)
  end
  #--------------------------------------------------------------------------
  # ● 处理选项
  #--------------------------------------------------------------------------
  def process_choices
    @choices_texts.clear; @choices_info.clear
    s = $game_switches
    v = $game_variables
    i = 0 # 实际显示出来的选项组中的序号
    $game_message.choices.each_with_index do |text_, index|
      text = text_.dup
      text.gsub!(/(?i:if){(.*?)}/) { "" }
      next if $1 && eval($1) == false
      @choices_info[i] = {} # 初始化
      text.gsub!(/(?i:en){(.*?)}/) { "" }
      @choices_info[i][:enable] = $1.nil? || eval($1) == true
      text.gsub!(/(?i:cl){(.*?)}/) { "" }
      $game_message.choice_cancel_index = index if $1 && eval($1) == true
      text.gsub!(/(?i:ex){(.*?)}/) { "" }
      @choices_info[i][:extra] = {}
      parse_extra_info(@choices_info[i][:extra], $1, :ali) if $1
      check_auto_cd_choice(i) if @choices_info[i][:extra][:t]

      @choices_texts.push(text) # 存储原始文本
      @choices_info[i][:index] = index # 存储该选择支在事件页里的序号
      i += 1
    end
  end
  #--------------------------------------------------------------------------
  # ● 分析额外设置参数
  #--------------------------------------------------------------------------
  def parse_extra_info(params, param_s, default_type)
    @message_window.parse_param(params, param_s, default_type)
  end
  #--------------------------------------------------------------------------
  # ● 分析倒计时选项参数
  #--------------------------------------------------------------------------
  def check_auto_cd_choice(i)
    @choice_auto_t = @choices_info[i][:extra][:t]
    @choice_auto_show = @choices_info[i][:extra][:tv] == 0 ? false : true
    @choice_auto_index = i
  end
  #--------------------------------------------------------------------------
  # ● 检查高度参数
  #--------------------------------------------------------------------------
  def eagle_check_param_h(h)
    return 0 if h <= 0
    # 如果h小于行高，则判定其为行数
    return line_height * h + standard_padding * 2 if h < line_height
    return h
  end
  #--------------------------------------------------------------------------
  # ● 更新窗口的大小
  #--------------------------------------------------------------------------
  def update_size
    @choices_texts.size.times do |i|
      @choices_info[i][:width] = cal_width_line( command_name(i) )
    end
    # 窗口宽度最小值（不含边界）
    width_min = @choices_info.values.collect {|v| v[:width]}.max + 8
    self.height = fitting_height(@choices_texts.size)
    h = eagle_check_param_h($game_message.choice_params[:h])
    self.height = h if h > 0

    if @message_window.open? && $game_message.choice_params[:do] == 0 # 嵌入对话框
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
    else
      self.width = width_min + standard_padding * 2
      self.width = $game_message.choice_params[:w] if $game_message.choice_params[:w] > self.width
    end

    create_contents
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
    self.z = @message_window.z + 10
  end
  #--------------------------------------------------------------------------
  # ● 更新其他属性
  #--------------------------------------------------------------------------
  def update_params_ex
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
  end
  #--------------------------------------------------------------------------
  # ● 生成指令列表（覆盖）
  #--------------------------------------------------------------------------
  def make_command_list
    @choices_texts.each_with_index do |choice, i|
      add_command(choice, :choice, @choices_info[i][:enable])
    end
  end
  #--------------------------------------------------------------------------
  # ● 获取指令名称
  #--------------------------------------------------------------------------
  def command_name(index)
    text = @choices_texts[index] #@list[index][:name]
    if index == @choice_auto_index
      text = MESSAGE_EX.get_auto_cd_choice_text(text, @choice_auto_t) if @choice_auto_show
      text = MESSAGE_EX::CHOICE_AUTO_TEXT_OK_PREFIX + text if @choice_auto_ok
    end
    text
  end
  #--------------------------------------------------------------------------
  # ● 绘制项目
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
    @cur_item_enable = @choices_info[index][:enable]
    draw_text_ex(x_, rect.y, command_name(index))
  end
  #--------------------------------------------------------------------------
  # ● 计算文本块的最大宽度（不计算\{\}转义符造成的影响）
  #--------------------------------------------------------------------------
  def cal_width_line(text)
    reset_font_settings
    text_clone, array_width = text.dup, []
    text_clone.each_line do |line|
      line = convert_escape_characters(line)
      line.gsub!(/\n/){ "" }; line.gsub!(/\e[\.\|\^\!\$<>\{|\}]/i){ "" }
      icon_length = 0; line.gsub!(/\ei\[\d+\]/i){ icon_length += 24; "" }
      line.gsub!(/\e\w+\[(\d|\w)+\]/i){ "" } # 清除掉全部的\w[wd]格式转义符
      array_width.push(text_size(line).width + icon_length)
    end
    array_width.max
  end
  #--------------------------------------------------------------------------
  # ● 更改内容绘制颜色
  #     enabled : 有效的标志。false 的时候使用半透明效果绘制
  #--------------------------------------------------------------------------
  def change_color(color, enabled = true)
    contents.font.color.set(color)
    contents.font.color.alpha = translucent_alpha if !enabled || !@cur_item_enable
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
    $game_message.method_choice_result.call(@choices_info[index][:index])
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
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
    update_auto_cd_choice if self.active && @choice_auto_t != 0
  end
  #--------------------------------------------------------------------------
  # ● 更新倒计时选项
  #--------------------------------------------------------------------------
  def update_auto_cd_choice
    if @choice_auto_t > 0
      @choice_auto_t -= 1
      redraw_item(@choice_auto_index) if @choice_auto_show && @choice_auto_t % 60 == 0
      process_auto_cd_choice(@choice_auto_index) if @choice_auto_t == 0
    else
      @choice_auto_t += 1
      process_auto_cd_choice_ok if @choice_auto_t == 0
    end
  end
  #--------------------------------------------------------------------------
  # ● 选择倒计时选项
  #--------------------------------------------------------------------------
  def process_auto_cd_choice(i)
    @choice_auto_show = false
    @choice_auto_ok = true

    #update_size; refresh; update_placement # 重置大小的重绘
    redraw_item(@choice_auto_index) # 单纯重绘

    Sound.play_cursor
    select(i)
    self.top_row = i - (page_row_max - 1) / 2
    @choice_auto_t = -60
    @cursor_fix = true
    @func_key_freeze = true
  end
  #--------------------------------------------------------------------------
  # ● 决定倒计时选项
  #--------------------------------------------------------------------------
  def process_auto_cd_choice_ok
    @choice_auto_t = 0
    @choice_auto_ok = false
    @cursor_fix = false
    @func_key_freeze = false
    deactivate
    Sound.play_ok
    $game_message.method_choice_result.call(@choices_info[@choice_auto_index][:index])
    close
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
    # 0 代表取消无效，1 ~ size 代表取消时进入对应分支，size+1 代表进入取消专用分支
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
