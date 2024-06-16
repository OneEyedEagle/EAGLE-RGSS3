#==============================================================================
# ■ Add-On 选择框扩展 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【对话框扩展 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-ChoiceEX"] = "1.2.2"
#=============================================================================
# - 2024.6.15.18 新增选择支文本在en为false时，替换为？？？的功能 
#==============================================================================
#------------------------------------------------------------------------------
# 【优化】
#------------------------------------------------------------------------------
# - 在默认VA中，选项的实现使用了 Proc 类，而该类无法被序列化存储
#   也因此，当选择框开启时，如果执行存档指令，将出现存储失败的结果
#
# - 在本插件中，调整了选项的实现，现在可以在选择框开启时同样进行存储
#   哪怕没有启用【对话框扩展】，也针对默认的选择框进行了优化，保证了选择时正常存储
#
# - 但注意，由于默认的事件指令执行逻辑，读档后可能发生跳过当前指令（选项）的问题，
#   因此推荐同步使用我的【快速存读档 by 老鹰】，其中针对选择框的存读档进行了优化，
#   保证了读档后能重新显示存档时的对话框和选择框
#
# - 在默认VA中，选择框位置与对话框相关，而【对话框扩展 by老鹰】中对话框初始位置未知，
#   因此本插件将选择框的默认位置改成了：显示原点o=7，初始位置为屏幕居中偏下
#
#------------------------------------------------------------------------------
# 【扩展：选项自动合并】
#------------------------------------------------------------------------------
# - 在本插件中，相邻且同级的 选择支处理 指令将自动合并
#   （若不想自动合并，可在之间插入 注释 指令）
#
# - 但注意，合并后只保留最后一个选项指令中的 取消 分支
#   （其他选项指令的取消分支将无效）
#
#------------------------------------------------------------------------------
# 【扩展：选项名称】
#------------------------------------------------------------------------------
# - 在选择支内容中增加下述内容，来对该选项设置其名称：
#
#     n{name} 或 N{name} → 设置该选择支的名称为name（任意字符，但不可包含符号 } ）
#
#   带有该名称设置的选项，被选择后，选项再次显示时，
#     选项文字将变更为脚本中设置的特殊颜色，来表示该选项已经被选择过
#
# - 特别的，在 {} 中的 name 头部添加符号 *，可以使得该选项变更为一次性
#     即选择一次后不再出现，除非删去 $game_system.eagle_choices 数组中的 "name"
#
# - 新增全局脚本，来判定某个带有名称的选项是否被选择过
#
#     $game_system.choice_read?(name)
#
#   其中 name 为选项的名称，为字符串类型
#   该脚本返回 true 代表选择过该名称的选项，否则返回 false
#
# - 示例：
#
#     选项内容：这个一个测试选项n{*测试选项}
#     选择该选项后，再次执行，该选项将不再显示
#     同时脚本调用 $game_system.choice_read?("测试选项") 将返回 true
#
#------------------------------------------------------------------------------
# 【扩展：选项出现条件】
#------------------------------------------------------------------------------
# - 在选择支内容中增加下述内容，来对该选项附加出现条件：
#
#     if{string} 或 IF{string} → 设置该选择支出现的条件（不满足时隐藏）
#     en{string} 或 EN{string} → 设置该选择支能够被选择的条件（不满足时无法选择）
#     cl{string} 或 CL{string} → 设置该选择支为取消项时的条件（按序逐个判定并覆盖）
#
# - 对 string 的解析：eval(string)后返回布尔值用于判定，可用下列缩写进行简写
#     s 代替 $game_switches   v 代替 $game_variables
#
# - 示例：
#     选项内容Aif{v[1]>0} → 该选择支只有在1号变量值大于0时显示
#     选项内容Ben{s[2]} → 该选择支只有在2号开关开启时才能选择，否则提示禁止音效
#     选项内容Ccl{true} → 该选择支设定为取消分支（覆盖默认取消分支的设置）
#
#------------------------------------------------------------------------------
# 【扩展：使用扩展转义符】
#------------------------------------------------------------------------------
# - 在选择支内容中使用【对话框扩展】的转义符：
#    可用 \c[i] 与 \i[i] 转义符
#    可用 \f[param] 来设置 font 相关参数（同 对话框扩展 中的 \font 转义符）
#    可用 文本替换类 转义符（换行转义符无效）
#    可用 文本特效类 转义符
#
#------------------------------------------------------------------------------
# 【扩展：附加功能】
#------------------------------------------------------------------------------
# - 在选择支内容中增加下述字样，来启用附加功能：
#
#     ex{params} 或 EX{params} → 对该条选择支进行附加功能的设置
#
# - 对 params 的解析：由 变量名 + 数字 构成（同 对话框扩展 中的变量参数字符串）
#
#   （选项排版）
#     ali → 【默认】设置该选择支的对齐方式（覆盖选择框的设置）
#   （选项替换）
#     ri → 设置该选项将替换成的目标选项（在事件列表中的序号）
#          （第一个选择支的序号为0，只关注事件列表中的选项顺序，未显示的选项也要考虑）
#          （取消分支的序号为最后一个，中途的取消分支请全部忽略）
#          （若传入 -1 则代表该选项将替换为无效选项，不可再被选择）
#     rt → 设置倒计时的秒数，在倒计时结束后，当前选项将替换成预设的ri号选择支
#   （文本替换）
#     hn → 当 hn 设置为 1时，若同时设置了 en{} ，且其判定返回 false，
#          则该选项文本将被替换为 CHOICE_TEXT_EN_HN（默认为 ？？？）
#
# - 示例：
#     选项内容ex{ali1} → 该选择支居中对齐绘制
#     选项内容ex{ri1rt6} → 在6s后，该选择支将变更为事件中的1号选择支，
#                          选择后触发1号选择支的分歧
#     选项内容en{false}ex{hn1} → 选项文本显示为“？？？”，且不可被选择
#
#------------------------------------------------------------------------------
# 【扩展：选项中插入脚本】
#------------------------------------------------------------------------------
# - 在选择支内容中使用下述文本，来调用 Ruby 脚本的输出：
#
#     rb{string} 或 RB{string} → eval(string) 的返回值将替换该内容
#
# - 对 string 的解析：可用下列缩写进行简写
#     s 代替 $game_switches   v 代替 $game_variables
#
# - 示例：
#     选项内容为：“这是一句测试用选项，看看变量的值：rb{v[1]+v[2]}”
#     其中 rb{v[1]+v[2]} 将替换为 1号变量和 2 号变量的和
#
# - 注意：
#     该功能优先级最高，将最优先进行一次替换，然后处理上述其他的功能内容
#
#------------------------------------------------------------------------------
# 【参数设置：在对话框中】
#------------------------------------------------------------------------------
# - 在对话框中利用转义符 \choice[param] 对选择框进行设置：
#   （对话框中需要执行到该转义符，设置才会生效，因此最好放置于对话框开头）
#
#     i → 【默认】【重置】设置选择框光标初始所在的选择支
#         （从0开始计数，-1代表不选择）（按实际显示顺序）
#
#   （窗口位置）
#     o → 选择框的显示原点类型（九宫格小键盘）（默认7）（嵌入时固定为7）
#     x/y → 直接指定选择框的坐标（默认nil）
#     do → 选择框的显示位置类型（覆盖x/y）（默认-10无效）
#          （0嵌入；1~9对话框外边界的九宫格位置；-1~-9屏幕外框的九宫格位置）
#          （当对话框关闭时，0~9的设置均无效）
#     dx/dy → x/y坐标的偏移增量（默认0）
#
#   （窗口属性）
#     opa → 选择框的背景不透明度（默认255）（文字内容不透明度固定为255）
#         （嵌入时不显示窗口背景）
#     skin → 选择框皮肤类型（默认取对话框皮肤）（见index → 窗口皮肤文件名 的映射）
#
#   （固定宽度）
#     w → 选择框内容的宽度（默认0自动适配）（嵌入时该设置无效）
#         （选择框的最终宽度，一定大于完整显示全部选项的所需宽度）
#
#   （选项行列）
#     h → 设置选择框的行数（默认0自动适配）
#     col → 设置选择框的列数（默认1）
#     lhd → 每行之间的间距增量（默认2）
#     cwd → 每列之间的间距增量（默认2）
#
#   （调整字体宽高）
#     fdw → 计算宽度时，每个字符的宽度增量（默认0）
#            由于字体计算宽高时可能存在误差，因此增加了这个手工调整
#     fdh → 计算高度时，每个字符的高度增量（默认0）
#
#   （调整选项偏移）
#     cdx → 选项绘制时，整体的x方向偏移增量
#     cdy → 选项绘制时，整体的y方向偏移增量
#
#   （选项属性）
#     cd  → 设置倒计时的秒数，倒计时结束时，自动选择取消选项
#          （必须有被设置为 取消 情况的分支；同时该分支的可选条件en{}需要为true）
#          （使用默认计时器；若有【计时器扩展 by老鹰】，则占用 :choice_cd 标志符）
#     ali → 选项文本的对齐方式（0左对齐，1居中，2右对齐）（默认0左对齐）
#     cit → 选项移入时，字与字的间隔帧数
#
#   （特殊）
#     charas → 定义预设开启的文字特效（文字特效转义符sym 到 变量参数字符串 的hash）
#              （只能在脚本中进行赋值）
#              （如：$game_message.choice_params[:charas][:cin] = "1"
#                    代表用 对话框扩展 中的预设参数设置选择支移入方式）
#
#------------------------------------------------------------------------------
# 【参数设置：在脚本中】
#------------------------------------------------------------------------------
# - 在脚本中利用 $game_message.choice_params[sym] = value 对上述的指定参数赋值
#   注意其中 sym 全部为 Symbol 类型，而 value 为数值类型（或nil）
#
# - 示例：
#     $game_message.choice_params[:i] = 1 # 下一次选项框的光标默认在第二个分支
#
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
    :opa => 255, # 背景不透明度
    :skin => nil, # 皮肤类型（nil时代表跟随对话框）
    # 窗口位置
    :o => 7, # 原点类型
    :x => nil,
    :y => nil,
    :do => 0, # 显示位置类型
    :dx => 0, # 设置选择框的坐标偏移增量
    :dy => 0,
    # 选项行列
    :h => 0,   # 显示行数
    :col => 1, # 显示列数
    :cwd => 4, # 列间距的增量
    :lhd => 4, # 行间距的增量
    # 窗口宽度
    :w => 0, # 直接指定宽度（若为0，则动态计算）
    # 调整宽高
    #   如果发现文字超出了光标范围，可以试试调整这两个数值
    #   fdw会增大光标计算时的宽度，fdh会增大高度
    :fdw => 1, # 自适应宽度时，每个字符的占位宽度增量
               #（增加这个手工调整，以消除字体宽度计算时可能的误差）
    :fdh => 4, # 自适应高度时，每个字符的高度增量
    # 调整选项偏移
    :cdx => 2,
    :cdy => 2,
    # 选项属性
    :cd => 0, # 倒计时结束后选择取消项（秒数）
    :ali => 0, # 选项对齐方式
    :cit => 0, # 文字显示的间隔帧数
    # 文字特效预设
    # （例如填入 :cin => "" 则启用默认的文字移入效果 ）
    :charas => { },
  }
  #--------------------------------------------------------------------------
  # ● 【常量】选择框的最大显示行数
  #--------------------------------------------------------------------------
  CHOICE_LINE_MAX = 12
  #--------------------------------------------------------------------------
  # ● 【常量】被选择过的带有名称的选择支，再次显示时的文字颜色
  #--------------------------------------------------------------------------
  CHOICE_CHOSEN_COLOR = 4
  #--------------------------------------------------------------------------
  # ● 【常量】不存在任何选项时，出现的额外选项的文本
  #--------------------------------------------------------------------------
  CHOICE_TEXT_NO = "（……）"
  #--------------------------------------------------------------------------
  # ● 【常量】en{}为false时，被替换成的文本
  #--------------------------------------------------------------------------
  CHOICE_TEXT_EN_HN = "？？？"
end
#==============================================================================
# ○ Game_Message
#==============================================================================
class Game_Message
  attr_accessor :choice_params, :choice_result
  attr_accessor :choice_cancel_i_e, :choice_cancel_i_w
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  alias eagle_choicelist_ex_init initialize
  def initialize
    eagle_choicelist_ex_init
    @choice_cancel_i_e = -1 # 取消分支的判别序号（事件中序号）
    @choice_cancel_i_w = -1 # 取消分支的序号（窗口中序号）
    @choice_result = -1     # 结果分支的序号（事件中序号）
  end
  #--------------------------------------------------------------------------
  # ● 获取全部可保存params的符号的数组
  #--------------------------------------------------------------------------
  alias eagle_choicelist_ex_params eagle_params
  def eagle_params
    eagle_choicelist_ex_params + [:choice]
  end
end
#=============================================================================
# ○ Game_System
#=============================================================================
class Game_System
  attr_reader  :eagle_choices  # 已经看过的选择支的名称数组
  #--------------------------------------------------------------------------
  # ● 指定名称的选择支是否已经看过？
  #--------------------------------------------------------------------------
  def choice_read?(name)
    @eagle_choices ||= []
    return @eagle_choices.include?(name)
  end
  #--------------------------------------------------------------------------
  # ● 保存已经看过的指定名称的选择支
  #--------------------------------------------------------------------------
  def choice_read(name)
    @eagle_choices ||= []
    return if choice_read?(name)
    return @eagle_choices.push(name)
  end
end
#==============================================================================
# ○ Window_EagleMessage
#==============================================================================
class Window_EagleMessage
  #--------------------------------------------------------------------------
  # ● 设置choice参数
  #--------------------------------------------------------------------------
  def eagle_text_control_choice(param = "")
    parse_param(game_message.choice_params, param, :i)
  end
end
#==============================================================================
# ○ Window_EagleChoiceList
#==============================================================================
class Window_EagleChoiceList < Window_Command
  attr_reader :message_window, :skin
  def choice_params; $game_message.choice_params; end
  #--------------------------------------------------------------------------
  # ● 获取文字颜色
  #     n : 文字颜色编号（0..31）
  #--------------------------------------------------------------------------
  def text_color(n)
    MESSAGE_EX.text_color(n, self.windowskin)
  end
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize(message_window)
    @message_window = message_window
    @choices = {} # 选择支的窗口序号 => 选择支精灵组
    @choices_info = {} # 选择支的窗口序号 => 信息组

    @choices_num = 0 # 存储总共显示出的选项数目
    @max_col_w = 1 # 最大的列宽
    @max_line_h = 1 # 最大的行高
    @max_line_show_num = 0 # 显示的行数
    @final_w = 0  # 计算出的内容宽高
    @final_h = 0
    @func_key_freeze = false # 冻结功能按键
    @skin = 0 # 当前所用窗口皮肤的index
    eagle_reset

    super(0, 0)
    self.openness = 0
    deactivate
  end
  #--------------------------------------------------------------------------
  # ● 重置
  #--------------------------------------------------------------------------
  def eagle_reset
    @choices.clear
    @choices_info.clear
    # 存储各行列的宽高
    @win_info = { :line_h => [], :col_w => [] } # 行号 => 高  列号 => 宽
    # 重置默认光标位置
    choice_params[:i] = MESSAGE_EX.get_default_params(:choice)[:i]
  end
  #--------------------------------------------------------------------------
  # ● 计算窗口内容的宽度
  #--------------------------------------------------------------------------
  def contents_width
    @final_w
  end
  #--------------------------------------------------------------------------
  # ● 计算窗口内容的高度
  #--------------------------------------------------------------------------
  def contents_height
    @final_h
  end
  #--------------------------------------------------------------------------
  # ● 获取列数
  #--------------------------------------------------------------------------
  def col_max
    v = choice_params[:col] || 1
    return v if v > 0
    return 1
  end
  #--------------------------------------------------------------------------
  # ● 获取列之间的间距宽度
  #--------------------------------------------------------------------------
  def spacing
    choice_params[:cwd] || 4
  end
  #--------------------------------------------------------------------------
  # ● 获取行之间的间距宽度
  #--------------------------------------------------------------------------
  def spacing_line
    choice_params[:lhd] || 4
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
    reset_choice_positions
    set_init_select
    self.cursor_rect.empty
    #open
    #activate
  end
  #--------------------------------------------------------------------------
  # ● 处理选项列表
  #--------------------------------------------------------------------------
  def process_choice_list
    i = 0 # 选择支的窗口序号
    $game_message.choices.each_with_index do |text, index|
      i += 1 if process_choice(text.dup, index, i, true)
    end
    # 如果不存在任一选项，则增加一个辅助选项
    if i == 0
      process_choice(MESSAGE_EX::CHOICE_TEXT_NO, -1, i, false)
      i += 1
    end
    @choices_num = i # 存储总共显示的选项数目
    # 查找取消分支的窗口序号
    #（若取消分支为独立分支，则不改变i_w的值，仍然为 -1）
    choice = @choices_info.find{|i, e| e[:i_e] == $game_message.choice_cancel_i_e}
    $game_message.choice_cancel_i_w = choice[0] if choice
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
    # 判定rb{}
    text.gsub!(/(?i:rb){(.*?)}/) { eval($1) }
    # 判定if{}
    text.gsub!(/(?i:if){(.*?)}/) { "" }
    return false if apply_if && $1 && eval($1) == false # 跳过该选项的增加
    # 初始化对应hash信息组
    @choices_info[i_w] = {}
    @choices_info[i_w][:i_e] = i_e # 存储该选择支在事件页里的序号
    # 判定en{}
    text.gsub!(/(?i:en){(.*?)}/) { "" }
    @choices_info[i_w][:enable] = $1.nil? || eval($1) == true # 可选状态
    # 判定n{}
    i_w_name = ""; i_w_flag = nil
    text.gsub!(/(?i:n){([*])?(.*?)}/) { i_w_flag = $1; i_w_name = $2; "" }
    if i_w_name != ""
      @choices_info[i_w][:name] = i_w_name
      i_w_read = $game_system.choice_read?(i_w_name)
      return false if i_w_flag == '*' && i_w_read
      @choices_info[i_w][:read] = i_w_read
    end
    # 判定cl{}
    text.gsub!(/(?i:cl){(.*?)}/) { "" }
    $game_message.choice_cancel_i_e = i_e if $1 && eval($1) == true
    # 判定ex{}
    @choices_info[i_w][:extra] = {}
    text.gsub!(/(?i:ex){(.*?)}/) { "" }
    MESSAGE_EX.parse_param(@choices_info[i_w][:extra], $1, :ali) if $1
    #  应用 hn 设置，直接覆盖选项文本
    if @choices_info[i_w][:extra][:hn] == 1 && !@choices_info[i_w][:enable]
      text = MESSAGE_EX::CHOICE_TEXT_EN_HN
    end
    # 存储绘制的原始文本（去除全部判定文本）
    @choices_info[i_w][:text] = text
    # 计算原始文本占用的绘制宽度
    w, h = MESSAGE_EX.calculate_text_wh(contents, text,
      choice_params[:fdw], choice_params[:fdh])
    @choices_info[i_w][:width] = w + choice_params[:fdw]
    @choices_info[i_w][:height] = h + choice_params[:fdh]
    return true # 成功设置一个需要显示的选项的信息
  end

  #--------------------------------------------------------------------------
  # ● 设置窗口大小
  #--------------------------------------------------------------------------
  def reset_size
    # 获取各行各列的宽高
    n      = @choices_num # 选项数目
    n_col  = col_max # 列数
    n_line = n / n_col + (n % n_col > 0 ? 1 : 0) # 行数
    n_line.times do |i|
      v = 0
      n_col.times do |j|
        ci = i * n_col + j
        break if ci >= n
        h_ = @choices_info[ci][:height]
        v = h_ if h_ > v
      end
      @win_info[:line_h][i] = v # 每一行的高度
    end
    n_col.times do |j|
      v = 0
      n_line.times do |i|
        ci = i * n_col + j
        break if ci >= n
        w_ = @choices_info[ci][:width]
        v = w_ if w_ > v
      end
      @win_info[:col_w][j] = v # 每一列的宽度
    end

    # 窗口高度
    @max_line_h = @win_info[:line_h].max
    @final_h = @win_info[:line_h].inject { |s, v| s = s+v+spacing_line }
    @max_line_show_num = @choices_num
    self.height = @final_h
    h = [choice_params[:h], MESSAGE_EX::CHOICE_LINE_MAX].min
    if h > 0
      @max_line_show_num = h
      self.height = h * @max_line_h + (h - 1) * spacing_line
    end
    self.height += standard_padding * 2
    # 窗口宽度
    @max_col_w = @win_info[:col_w].max
    @final_w = @win_info[:col_w].inject { |s, v| s = s+v+spacing }
    self.width = [choice_params[:w], @final_w].max + standard_padding * 2

    # 处理嵌入的特殊情况
    @flag_in_msg_window = @message_window.child_window_embed_in? && choice_params[:do] == 0
    new_w = self.width
    if @flag_in_msg_window
      # 嵌入时对话框所需宽度最小值（不含边界）
      width_min = self.width - standard_padding * 2
      # 对话框实际能提供的宽度（文字区域宽度）
      win_w = @message_window.eagle_charas_max_w
      d = width_min - win_w
      if d > 0
        if @message_window.eagle_add_w_by_child_window?
          $game_message.child_window_w_des = d # 扩展对话框的宽度
        else
          @flag_in_msg_window = false
        end
      else # 宽度 = 文字区域宽度
        new_w = win_w + standard_padding * 2
      end
      win_h = @message_window.height - standard_padding * 2
      charas_h = @message_window.eagle_charas_y0 - @message_window.y - standard_padding +
        @message_window.eagle_charas_h - @message_window.eagle_charas_oy
      self_h = self.height - (charas_h > 0 ? 1 : 2) * standard_padding
      d = self_h - (win_h - charas_h)
      if d > 0  # 对话框剩余高度不足，没法直接嵌入
        if @message_window.eagle_add_h_by_child_window?  # 可以增加对话框高度？
          $game_message.child_window_h_des = d # 扩展对话框的高度
        elsif win_h > self_h  # 可以通过滚动文字获得足够高度？
          d_empty = win_h - charas_h
          @message_window.oy += (self_h - d_empty)
        else  # 没法了，别嵌入了
          @flag_in_msg_window = false
        end
      end
    end
    self.width = new_w if @flag_in_msg_window

    self.z = @message_window.z + 10 # 在文字绘制之前设置，保证文字精灵的z值
    self.ox = self.oy = 0
  end
  #--------------------------------------------------------------------------
  # ● 更新下端边距
  #--------------------------------------------------------------------------
  def update_padding_bottom
    self.padding_bottom = padding
  end
  #--------------------------------------------------------------------------
  # ● 更新窗口的位置
  #--------------------------------------------------------------------------
  def update_placement
    self.x = (Graphics.width - width) / 2 # 默认位置
    self.y = Graphics.height - 100 - height

    self.x = choice_params[:x] if choice_params[:x]
    self.y = choice_params[:y] if choice_params[:y]
    o = choice_params[:o]
    if (d_o = choice_params[:do]) < 0 # 相对于屏幕
      MESSAGE_EX.reset_xy_dorigin(self, nil, d_o)
    elsif @message_window.open?
      if d_o == 0 # 嵌入对话框
        if @flag_in_msg_window
          self.x = @message_window.eagle_charas_x0 - standard_padding
          charas_h = @message_window.eagle_charas_h - @message_window.eagle_charas_oy
          self.y = @message_window.eagle_charas_y0 + charas_h
          self.y -= standard_padding if charas_h == 0
          o = 7
        end
      else
        MESSAGE_EX.reset_xy_dorigin(self, @message_window, d_o)
      end
    end
    MESSAGE_EX.reset_xy_origin(self, o)
    self.x += choice_params[:dx]
    self.y += choice_params[:dy]
  end
  #--------------------------------------------------------------------------
  # ● 设置其他属性
  #--------------------------------------------------------------------------
  def reset_params_ex
    @skin = @message_window.get_cur_windowskin_index(choice_params[:skin])
    self.windowskin = MESSAGE_EX.windowskin(@skin)
    self.opacity = self.back_opacity = choice_params[:opa]
    self.contents_opacity = 255

    if @flag_in_msg_window # 如果嵌入，则不执行打开
      self.opacity = 0
      self.openness = 255
    end

    if cancel_enabled? && choice_params[:cd] > 0
      count = choice_params[:cd] * 60
      if $imported["EAGLE-TimerEX"]
        p1 = { :text => "选择倒计时...", :icon => 280 }
        $game_timer[:choice_cd].start(count, p1)
      else
        $game_timer.start(count)
      end
    else
      choice_params[:cd] = 0
    end
  end
  #--------------------------------------------------------------------------
  # ● 设置初始选项位置
  #--------------------------------------------------------------------------
  def set_init_select
    i = choice_params[:i]
    return unselect if i < 0
    select(i)
  end

  #--------------------------------------------------------------------------
  # ● 生成指令列表
  #--------------------------------------------------------------------------
  def make_command_list
    @choices_info.each { |i, v| add_command(v[:text], :choice, v[:enable]) }
  end
  #--------------------------------------------------------------------------
  # ● 获取指令名称
  #--------------------------------------------------------------------------
  def command_name(index)
    @choices_info[index][:text]
  end
  #--------------------------------------------------------------------------
  # ● 获取指令的有效状态
  #--------------------------------------------------------------------------
  def command_enabled?(index)
    @choices_info[index][:enable]
  end
  #--------------------------------------------------------------------------
  # ● 指令之前被选择过？
  #--------------------------------------------------------------------------
  def command_chosen?(index)
    @choices_info[index][:read]
  end

  #--------------------------------------------------------------------------
  # ● 获取行高
  #--------------------------------------------------------------------------
  def line_height
    @max_line_h # $game_message.font_params[:size] + 4
  end
  #--------------------------------------------------------------------------
  # ● 获取项目的绘制矩形
  #--------------------------------------------------------------------------
  def item_rect(index)
    rect = Rect.new
    begin
      i_line = index / col_max # 行号
      i_col = index % col_max # 列号
      rect.width = @win_info[:col_w][i_col]  # 计算出的所需宽度
      real_w = (self.width-standard_padding * 2)/col_max-spacing # 实际可用宽度
      if real_w > @max_col_w
        # 选项可用宽度大于最大的文本宽度，则每一列的宽度都一致
        rect.width = real_w
        rect.x = real_w * i_col
      else
        rect.x = @win_info[:col_w][0...i_col].inject { |s, v| s = s+v+spacing } || 0
        rect.x += spacing if rect.x > 0
      end
      if @max_line_show_num == @choices_num # 如果行数与显示的一致
        rect.y = @win_info[:line_h][0...i_line].inject { |s, v| s = s+v+spacing_line } || 0
        rect.y += spacing_line if rect.y > 0
        rect.height = @win_info[:line_h][i_line]
      else # 此时，每个选项都是最大的行高
        rect.y = index * @max_line_h + index * spacing_line
        rect.height = @max_line_h
      end
    rescue
    end
    rect
  end
  #--------------------------------------------------------------------------
  # ● 绘制项目
  #--------------------------------------------------------------------------
  def draw_item(index)
    @choices[index].dispose if @choices[index]
    rect = item_rect(index)
    s = Spriteset_Choice.new(self, index)
    s.set_rect(rect)
    s.set_enabled(command_enabled?(index))
    s.set_chosen(command_chosen?(index))
    # 绘制选择支文本
    dw = rect.width - @choices_info[index][:width]
    case @choices_info[index][:extra][:ali] || choice_params[:ali]
    when 0; x_ = 0
    when 1; x_ = dw / 2
    when 2; x_ = dw
    end
    s.draw_text_ex(x_ + choice_params[:cdx], choice_params[:cdy],
      rect.height, command_name(index))
    # 设置计时器
    if @choices_info[index][:extra][:ri]
      t = @choices_info[index][:extra][:rt] || 5
      s.set_timer(:replace, t * 60, @choices_info[index][:extra][:ri])
    end
    s.update
    @choices[index] = s
  end
  #--------------------------------------------------------------------------
  # ● 重置全部选项的位置
  #--------------------------------------------------------------------------
  def reset_choice_positions
    item_max.times {|i| @choices[i].set_rect(item_rect(i)) }
  end
  #--------------------------------------------------------------------------
  # ● 更新光标
  #--------------------------------------------------------------------------
  def update_cursor
    super
    return if !self.active
    @choices.each do |i, s|
      r = item_rect(i)
      y_ = r.y - self.oy
      s.set_visible(y_ >= 0 && y_ + @choices_info[i][:height] < self.height)
      s.set_xywh( nil, y_ )
    end
  end
  #--------------------------------------------------------------------------
  # ● 设置顶行位置
  #--------------------------------------------------------------------------
  def top_row=(row)
    return if @max_line_show_num == @choices_num # 如果行数一致，则不用变动
    row = 0 if row < 0
    row = row_max - 1 if row > row_max - 1
    self.oy = row * item_height + row * spacing_line
  end
  #--------------------------------------------------------------------------
  # ● 获取顶行位置
  #--------------------------------------------------------------------------
  def top_row
    oy / item_height
  end
  #--------------------------------------------------------------------------
  # ● 获取一页內显示的行数
  #--------------------------------------------------------------------------
  def page_row_max
    (height - padding - padding_bottom) / item_height
  end

  #--------------------------------------------------------------------------
  # ● 用事件列表中i_e_new号选项分支替换窗口中i_w号选项
  #--------------------------------------------------------------------------
  def replace_choice(i_e_new, i_w)
    @choices[i_w].move_out
    if i_e_new < 0
      i_e_old = @choices_info[i_w][:i_e]
      process_choice($game_message.choices[i_e_old].dup, i_e_old, i_w, false)
      @choices_info[i_w][:enable] = false
      @list[i_w][:enabled] = false # 修改 add_command 中的数据
      redraw_item(i_w)
      @choices[i_w].dispose_timer # 防止二次倒计时
    else
      process_choice($game_message.choices[i_e_new].dup, i_e_new, i_w, false)
      redraw_item(i_w)
      reset_size; reset_choice_positions; update_placement
    end
    @choices[i_w].set_active(true)
    @choices[i_w].set_visible(true)
    select(self.index)
  end

  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
    update_placement if @message_window.open? && choice_params[:do] == 0
    @choices.each { |i, s| s.update }
    return if !self.active
    check_cd_auto if choice_params[:cd] > 0
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
  # ● “确定”和“取消”的处理
  #--------------------------------------------------------------------------
  def process_handling
    return if @func_key_freeze
    super
  end
  #--------------------------------------------------------------------------
  # ● 获取“取消处理”的有效状态
  #--------------------------------------------------------------------------
  def cancel_enabled?
    $game_message.choice_cancel_i_e >= 0 &&  # 设置了取消分支
    ($game_message.choice_cancel_i_w < 0 ||  # 取消分支为独立分支
    @choices_info[$game_message.choice_cancel_i_w][:enable]) # 取消分支可选
  end
  #--------------------------------------------------------------------------
  # ● 调用“确定”的处理方法
  #--------------------------------------------------------------------------
  def call_ok_handler
    if @choices_info[index][:name]
      $game_system.choice_read(@choices_info[index][:name])
    end
    $game_message.choice_result = @choices_info[index][:i_e]
    close
  end
  #--------------------------------------------------------------------------
  # ● 调用“取消”的处理方法
  #--------------------------------------------------------------------------
  def call_cancel_handler
    $game_message.choice_result = $game_message.choice_cancel_i_e
    close
  end
  #--------------------------------------------------------------------------
  # ● 激活
  #--------------------------------------------------------------------------
  def activate
    @choices.each { |i, s| s.set_active(true) }
    super
  end
  #--------------------------------------------------------------------------
  # ● 打开
  #--------------------------------------------------------------------------
  def open
    @choices.each { |i, s| s.set_visible(true) }
    super
  end
  #--------------------------------------------------------------------------
  # ● 关闭
  #--------------------------------------------------------------------------
  def close
    @choices.each { |i, s| s.move_out }
    eagle_reset
    if $imported["EAGLE-TimerEX"]
      $game_timer[:choice_cd].stop
    else
      $game_timer.stop
    end
    super
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    super
    @choices.each { |i, s| s.dispose }
    @choices.clear
  end
end
#==============================================================================
# ○ Spriteset_Choice
#==============================================================================
class Spriteset_Choice
  include MESSAGE_EX::CHARA_EFFECTS
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(choice_window, i_w)
    @choice_window = choice_window
    @i_w = i_w # 在选项窗口中的index
    @charas = []
    @chara_effect_params = choice_params[:charas].dup
    @chara_dwin_rect = nil
    @font = @choice_window.contents.font.dup # 每个选项存储独立的font对象
    @font_params = $game_message.font_params.dup # font转义符参数
    @active = false # 是否开始移入
    @visible = false # 是否可见
    @enabled = true
    @chosen = false
    @timer = nil
  end
  #--------------------------------------------------------------------------
  # ● 绑定
  #--------------------------------------------------------------------------
  def message_window
    @choice_window.message_window
  end
  def choice_params
    $game_message.choice_params
  end
  def z
    @choice_window.z + 10
  end
  #--------------------------------------------------------------------------
  # ● 设置文字的绘制矩形（相对于选项窗口的左上角）
  #--------------------------------------------------------------------------
  def set_xywh(x = nil, y = nil, w = nil, h = nil)
    @chara_dwin_rect.x = x if x
    @chara_dwin_rect.y = y if y
    @chara_dwin_rect.width = w if w
    @chara_dwin_rect.height = h if h
  end
  def set_rect(rect)
    @chara_dwin_rect = rect
  end
  #--------------------------------------------------------------------------
  # ● 绑定
  #--------------------------------------------------------------------------
  def eagle_charas_x0
    @choice_window.x + @choice_window.standard_padding + @chara_dwin_rect.x
  end
  def eagle_charas_y0
    @choice_window.y + @choice_window.standard_padding + @chara_dwin_rect.y
  end
  def eagle_charas_max_w
    self.width - standard_padding * 2
  end
  def eagle_charas_max_h
    0
  end
  def eagle_charas_ox; 0; end
  def eagle_charas_oy; 0; end
  #--------------------------------------------------------------------------
  # ● 设置倒计时激活状态
  #--------------------------------------------------------------------------
  def set_active(bool)
    @active = bool
  end
  #--------------------------------------------------------------------------
  # ● 设置文字的显示状态
  #--------------------------------------------------------------------------
  def set_visible(bool)
    @visible = bool
    @charas.each { |s| s.visible = bool }
    @timer_s.visible = bool if @timer_s
  end
  #--------------------------------------------------------------------------
  # ● 设置选项的可选状态
  #--------------------------------------------------------------------------
  def set_enabled(bool)
    @enabled = bool
    change_color(@font.color)
  end
  #--------------------------------------------------------------------------
  # ● 设置选项的已经被选择过的状态
  #--------------------------------------------------------------------------
  def set_chosen(bool)
    @chosen = bool
    change_color(@font.color)
  end
  #--------------------------------------------------------------------------
  # ● 全部移出
  #--------------------------------------------------------------------------
  def move_out
    @fiber = nil
    @charas.each { |s| s.opacity = 0 if !s.visible; s.move_out }
    @charas.clear
    dispose_timer
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    @fiber = nil
    @charas.each { |s| s.dispose }
    @charas.clear
    dispose_timer
  end

  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    return unless @active
    update_timer if @timer
    return unless @visible
    @fiber.resume if @fiber
    @charas.each { |s| s.update }
  end
  #--------------------------------------------------------------------------
  # ● 设置选项的计时器
  #--------------------------------------------------------------------------
  def set_timer(type, count, i_e_target)
    # [计数, 总计, 类型, 目标选项的事件中序号]
    @timer = [count+1, count, type, i_e_target]
    @timer_viewport = Viewport.new(@chara_dwin_rect)
    @timer_viewport.z = self.z - 1
    @timer_s = Sprite.new(@timer_viewport)
    @timer_s.opacity = 0
    @timer_s.bitmap = Bitmap.new(@chara_dwin_rect.width, @chara_dwin_rect.height)
    @timer_s.bitmap.fill_rect(@timer_s.bitmap.rect, Color.new(180,180,180,50))
  end
  #--------------------------------------------------------------------------
  # ● 更新计时器
  #--------------------------------------------------------------------------
  def update_timer
    @timer_viewport.rect.x = eagle_charas_x0
    @timer_viewport.rect.y = eagle_charas_y0
    @timer_viewport.rect.width = @timer_s.width * @timer[0] * 1.0 / @timer[1]
    @timer_s.opacity = @choice_window.openness
    return if (@timer[0] -= 1) > 0
    case @timer[2]
    when :replace
      @choice_window.replace_choice(@timer[3], @i_w)
    end
    dispose_timer
  end
  #--------------------------------------------------------------------------
  # ● 释放计时器
  #--------------------------------------------------------------------------
  def dispose_timer
    return if @timer.nil?
    @timer_viewport.dispose
    @timer_s.bitmap.dispose
    @timer_s.dispose
    @timer_s = nil
    @timer = nil
  end

  #--------------------------------------------------------------------------
  # ● 应用文本特效
  #--------------------------------------------------------------------------
  def start_effects(params)
    @charas.each { |s| s.start_effects(params) }
  end
  #--------------------------------------------------------------------------
  # ● 绘制
  #--------------------------------------------------------------------------
  def draw_text_ex(x, y, h, text)
    @fiber = Fiber.new {
      reset_font_settings
      text = message_window.convert_escape_characters(text)
      pos = {:x => x, :y => y, :height => h, :x_new => x}
      process_character(text.slice!(0, 1), text, pos) until text.empty?
      @fiber = nil
    }
  end
  #--------------------------------------------------------------------------
  # ● 重置字体设置
  #--------------------------------------------------------------------------
  def reset_font_settings
    c = MESSAGE_EX::DEFAULT_COLOR_INDEX
    c = MESSAGE_EX::CHOICE_CHOSEN_COLOR if @chosen
    @font_params[:c] = c
    @font_params[:ca] = 255
    change_color(@choice_window.text_color(@font_params[:c]))
  end
  #--------------------------------------------------------------------------
  # ● 更改内容绘制颜色
  #--------------------------------------------------------------------------
  def change_color(color)
    @font.color.set(color)
    if !@enabled
      @font.color.alpha = 120
      @font_params[:ca] = 120
    end
  end
  #--------------------------------------------------------------------------
  # ● 文字的处理
  #     c    : 文字
  #     text : 绘制处理中的字符串缓存（字符串可能会被修改）
  #     pos  : 绘制位置 {:x, :y, :new_x, :height}
  #--------------------------------------------------------------------------
  def process_character(c, text, pos)
    case c
    when "\r", "\f"   # 回车 # 翻页
      return
    when "\n" # 换行
      process_new_line(text, pos)
    when "\e"   # 控制符
      process_escape_character(message_window.obtain_escape_code(text), text, pos)
    else        # 普通文字
      process_normal_character(c, pos)
      process_draw_success(pos)
    end
  end
  #--------------------------------------------------------------------------
  # ● 处理换行文字
  #--------------------------------------------------------------------------
  def process_new_line(text, pos)
    pos[:x] = pos[:x_new]
    pos[:y] += pos[:height]
  end
  #--------------------------------------------------------------------------
  # ● 处理普通文字
  #--------------------------------------------------------------------------
  def process_normal_character(c, pos)
    c_rect = message_window.text_size(c)
    c_w = c_rect.width
    c_h = c_rect.height
    pos[:height] = c_h if c_h > pos[:height]
    c_y = pos[:y] + (pos[:height] - c_h - 1) / 2
    s = eagle_new_chara_sprite(pos[:x], c_y, c_w, c_h)
    s.eagle_font.draw(s.bitmap, 0, 0, c_w*2, c_h, c, 0)
    pos[:x] += c_w
  end
  #--------------------------------------------------------------------------
  # ● 处理控制符指定的图标绘制
  #--------------------------------------------------------------------------
  def process_draw_icon(icon_index, pos)
    c_w = c_h = 24
    pos[:height] = c_h if c_h > pos[:height]
    c_y = pos[:y] + (pos[:height] - c_h) / 2
    s = eagle_new_chara_sprite(pos[:x], c_y, c_w, c_h)
    s.eagle_font.draw_icon(s.bitmap, 0, 0, icon_index)
    pos[:x] += 24
  end
  #--------------------------------------------------------------------------
  # ● （封装）生成一个新的文字精灵
  #--------------------------------------------------------------------------
  def eagle_new_chara_sprite(c_x, c_y, c_w, c_h)
    f = Font_EagleCharacter.new(@font_params)
    f.set_param(:skin, @choice_window.skin)

    s = Sprite_EagleCharacter.new(self, f, c_x, c_y, c_w, c_h)
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
      param = message_window.obtain_escape_param(text)
      @font_params[:c] = param
      if param == 0
        reset_font_settings
      else
        change_color( @choice_window.text_color(param) )
      end
    when 'F'
      param = message_window.obtain_escape_param_string(text)
      MESSAGE_EX.parse_param(@font_params, param, :size)
      MESSAGE_EX.apply_font_params(@font, @font_params)
      change_color( @choice_window.text_color(@font_params[:c]) )
    when 'I'
      process_draw_icon(message_window.obtain_escape_param(text), pos)
      process_draw_success(pos)
    end
  end
  #--------------------------------------------------------------------------
  # ● 成功绘制后的处理
  #--------------------------------------------------------------------------
  def process_draw_success(pos)
    choice_params[:cit].times { Fiber.yield }
  end
end

#==============================================================================
# ○ Window_ChoiceList
#==============================================================================
class Window_ChoiceList < Window_Command
  #--------------------------------------------------------------------------
  # ● 调用“确定”的处理方法
  #--------------------------------------------------------------------------
  def call_ok_handler
    $game_message.choice_result = index
    close
  end
  #--------------------------------------------------------------------------
  # ● 调用“取消”的处理方法
  #--------------------------------------------------------------------------
  def call_cancel_handler
    $game_message.choice_result = $game_message.choice_cancel_type - 1
    close
  end
end

#==============================================================================
# ○ Game_Interpreter
#==============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 设置选项（旧版）
  #--------------------------------------------------------------------------
  def setup_choices_old(params)
    params[0].each {|s| $game_message.choices.push(s) }
    $game_message.choice_cancel_type = params[1]
    # 修改 不再使用Proc类
    wait_for_message
    # 应用选项结果
    eagle_choice_result($game_message.choice_result)
  end
  #--------------------------------------------------------------------------
  # ● 设置选项
  #--------------------------------------------------------------------------
  alias eagle_choicelist_ex_setup_choices setup_choices
  def setup_choices(params)
    if $game_message.eagle_message == false # 默认对话框，使用旧版
      return setup_choices_old(params)
    end
    cancel_index = eagle_merge_choices
    params = @list[@index].parameters
    params[0].each {|s| $game_message.choices.push(s) }
    # 设置取消分支的类型（事件中序号）
    #（对于params[1]）
    # 0 代表取消无效，1 ~ size 代表取消时进入对应分支，size+1 代表进入取消专用分支
    #（对于choice_cancel_i_e）
    # -1 代表无效，0 ~ size-1 代表对应分支，size代表取消分支
    #（对于choice_cancel_i_w）
    # -1 代表有独立取消分支，0 ~ win_size-1 代表对应窗口中分支
    $game_message.choice_cancel_i_e = params[1] - 1
    $game_message.choice_cancel_i_e = params[0].size if cancel_index >= 0
    $game_message.choice_cancel_i_w = -1 # 初始时取-1，在选项生成时重置
    $game_message.choice_result = -1 # 重置结果分支序号
    # 新增等待选择框结束
    wait_for_message
    # 应用选项结果
    eagle_choice_result($game_message.choice_result)
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
  alias eagle_choicelist_ex_command_403 command_403
  def command_403
    if $game_message.eagle_message == false # 默认对话框，使用旧版
      return eagle_choicelist_ex_command_403
    end
    command_skip if @branch[@indent] != $game_message.choice_cancel_i_e
  end
  def command_4031
    command_skip
  end
end
