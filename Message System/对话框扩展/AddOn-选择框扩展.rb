#encoding:utf-8
$imported ||= {}
$imported["EAGLE-ChoiceEX"] = "2.0.1"  # 2025.12.6.12
=begin
===============================================================================

    ┌--------------------------------------------------------------------┐
    ┆            ,""--..                                                 ┆
    ┆          ㄏ       `.                                               ┆
    ┆       _ノ ㄏō       \                                              ┆
    ┆      / ´             y                                             ┆
    ┆      \J==ノ  　 by.老鹰 (https://github.com/OneEyedEagle/EAGLE-RGSS3)
    └--------------------------------------------------------------------┘
    
     ■ 选择框扩展 Ver 2.0 【鹰式对话框扩展 Add-On】
     
       本插件需要放置在 鹰式对话框扩展 Ver 2.0 之下，才能正常使用。
       
     =====================================================================
        -                                                             -
     
     ▼ 优化：选择时存档 ·=================================================

       在默认VA中，选项的实现使用了 Proc 类，而该类无法被序列化存储，
       也因此，当选择框开启时，如果执行存档指令，将出现存储失败、存档被删除。

       在本插件中，调整了选项的实现，现在可以在选择框开启时进行存储。

       特别的，哪怕【鹰式对话框扩展】开启了兼容默认而未启用，
         本插件同样也对默认的选择框进行了优化，保证在选择框开启时能正常存档。

       注意，哪怕在选项时成功存档，但读档后还是可能跳过当前指令（即选择框），
         因此推荐使用【快速存读档 by 老鹰】，其中对读档后的对话框进行了优化，
         保证读档后能重新显示存档时所在的对话框和选择框。

     =====================================================================
        -                                                             -
     
     更新历史
     ----------------------------------------------------------------------
     - 2025.12.6.12 V2.0.1 修复 cdx 和 cdy 未使光标偏移的bug
     ----------------------------------------------------------------------
     - 2025.8.26.23 V2.0.0 优化注释
     ----------------------------------------------------------------------
     
=end

#==============================================================================
#                                 ■ 设定列表 ■ 
#==============================================================================
module MESSAGE_EX
#╭────────────────────────────────────────╮
#                                  - 基础设置 -
# -────────────────────────────────────────-
# 1▍ 选择框默认位置
# -────────────────────────────────────────-
#     在默认VA中，选择框位置与对话框相关，而 鹰式对话框扩展 中对话框初始位置未知，
#     因此本插件将选择框的默认位置改成了：显示原点o=7，初始位置为屏幕居中偏下。

# -────────────────────────────────────────-
# 2▍ 选择支自动合并
# -────────────────────────────────────────-
#     在本插件中，相邻且同级的 选择支处理 指令将自动合并。
#       若不想自动合并，可在选项之间插入 注释 。
#
#     但注意，合并后只保留最后一个选择支指令中的 取消 分支，
#       其他选择支的取消分支无效。

# -────────────────────────────────────────-
# 3▍ 选择支文字颜色
# -────────────────────────────────────────-
#  ◇ 选择支文字的默认颜色
#     具体可设置内容同【鹰式对话框扩展】中的“文字颜色扩展\C[id]”

  CHOICE_DEFAULT_COLOR_ID = 0

# -────────────────────────────────────────-
# 4▍ 选择支名称
# -────────────────────────────────────────-
#     在选择支中增加下述内容，以设置该选择支的名称：
#
#       n{name} 或 N{name} → 设置选择支名称为name（name中不可包含符号} ）
#
#  ◇ 设置了名称的选择支在被选择一次后，再次显示时的文字默认颜色
#     具体可设置内容同【鹰式对话框扩展】中的“文字颜色扩展\C[id]”

  CHOICE_CHOSEN_COLOR_ID = 4

#     特别的，编写 {*name} 将使该选项变成一次性的，即选择一次后不再出现。
#     但你可以通过脚本 $game_system.eagle_choices.delete(name) 来重置。
#
#  ◇ 脚本：判定某名称的选项是否被选择过
#
#     >>  $game_system.choice_read?(name)
#
#     其中 name 为选项的名称，为字符串类型。
#     返回 true 代表选择过该名称的选项，返回 false 代表未选择过。
#
#  ？ 示例
#
#     选项内容：这个一个测试选项n{*测试选项}
#        → 选择该选择支后，再次打开选项框时，该选择支将不再显示。
#        → 脚本 $game_system.choice_read?("测试选项") 将返回 true 。

# -────────────────────────────────────────-
# 5▍ 选择支出现条件
# -────────────────────────────────────────-
#     在选择支内容中增加下述内容，来设置该选择支的出现条件：
#
#       if{string} 或 IF{string} → 设置该选择支出现的条件
#                                 （当条件不满足时，该选择支隐藏）
#
#       en{string} 或 EN{string} → 设置该选择支能够被选择的条件
#                                 （当条件不满足时，该选择支无法确定）
#
#       cl{string} 或 CL{string} → 设置该选择支作为取消项时的条件
#                                 （如果条件满足，则会覆盖编辑器中设置的取消项）
#                                 （如果有多个选择支满足，则最下面的将作为取消项）
#  ◇ 关于其中的 string
#
#       eval(string) 后返回的true/false用于判定。
#       可用下列缩写进行简写：s 代替 $game_switches ， v 代替 $game_variables 。
#
#  ？ 示例
#
#     选项内容Aif{v[1]>0}
#        → 该选择支只有在1号变量值大于0时显示
#     选项内容Ben{s[2]}
#        → 该选择支只有在2号开关开启时才能选择，否则提示禁止音效
#     选项内容Ccl{true}
#        → 该选择支设定为取消分支（覆盖编辑器中设置的取消分支）
#
# -────────────────────────────────────────-
# 6▍ 选择支文本中可用的扩展转义符
# -────────────────────────────────────────-
#     在选择支文本中可以使用以下的来自【鹰式对话框扩展】的转义符：
#       >> 可用 \c[i] 与 \i[i] 转义符
#       >> 可用 \f[param] 来设置 font 相关参数（同 \font 转义符）
#       >> 可用 文本替换类 转义符（换行符无效）
#       >> 可用 文本特效类 转义符
#
# -────────────────────────────────────────-
# 6▍ 选择支其它设置
# -────────────────────────────────────────-
#     在选择支文本中增加下述内容，来修改其它功能：
#
#       ex{params} 或 EX{params}
#
#  · param    ▼ 设定参数（字母+数字）：
#              （选择支排版）
#                 ali → 【快捷】设置该选择支的对齐方式（覆盖选择框的设置）
#              （选择支替换）
#                 ri  → 当前选择支替换成事件中 ri 号选择支
#                     （事件中第一个选择支的序号为0，未显示的选择支也要计算）
#                     （取消分支的序号固定为全部选择支数量+1）
#                     （ri=-1 时将替换为无效选择支，不可选择）
#                 rt  → 在 rt 秒后，当前选择支将按 ri 设置进行替换
#              （文本替换）
#                 hn  → hn=1时，若设置了en{}且条件不满足，则选择支显示为？？？
#
#  ◇ hn=1且en{}为false时，选择支显示为该文本

  CHOICE_TEXT_EN_HN = "？？？"

#  ？ 示例
#
#     选项内容ex{ali1}
#        → 该选择支居中对齐绘制。
#     选项内容ex{ri1rt6}
#        → 在6s后，该选择支将变更为事件中的1号选择支，选择后触发对应选择支的分歧。
#     选项内容en{false}ex{hn1}
#        → 选项文本显示为“？？？”，且不可选择。

# -────────────────────────────────────────-
# 7▍ 选择支中插入脚本
# -────────────────────────────────────────-
#     在选择支文本中使用下述文本，将在绘制前调用 Ruby 脚本，并绘制返回值：
#
#       rb{string} 或 RB{string}
#
#  ◇ 关于其中的 string
#
#       eval(string) 后返回的值将作为文本进行绘制。
#       其中可用 s 代替 $game_switches   v 代替 $game_variables 。
#
#  ？ 示例
#
#     选项内容为：“这是一句测试用选项，看看变量的值：rb{v[1]+v[2]}”
#     其中 rb{v[1]+v[2]} 将替换为 1号变量和 2 号变量的和。
  
#╰────────────────────────────────────────╯

#  ·                              ······                              ·

#╭────────────────────────────────────────╮
#                                - 转义符设置 -

# -────────────────────────────────────────-
# A▍ 选择框设置                                                       \CHOICE ■
# -────────────────────────────────────────-

#  ● \choice[param]

#     ---------------------------------------------------------------------
#  ◇ 预设参数          ▼ [param]“参数串”一览（字母+数字组合）

  CHOICE_PARAMS_INIT = {
    :i     => -1,      # 【快捷】【重置】选择框光标初始所在的选择支
                      #  * 从0开始，-1代表初始不选择（按选择框中实际显示）
#  ·窗口属性
    :opa   => 255,    # 选择框的背景不透明度（默认255）
                      #  * 嵌入时背景不透明度固定为 0
    :skin  => nil,    # 窗口皮肤序号（见下方[预设]）（nil时跟随对话框）
    :w     => 0,      # 选择框内容的宽度（默认0自动适配）
                      #  * do=0嵌入时，该设置无效
                      #  * 选择框宽度一定大于全部选项的宽度
#  ·窗口位置
    :o     => 7,      # 显示原点（对应小键盘九宫格 | 默认值为7 左上角）
                      #  * 嵌入时显示原点固定为 7左上角
    :x     => nil,    # 所在屏幕坐标（x,y）（默认nil不设置）
    :y     => nil,
    :do    => 9,      # 显示位置类型（设置后x、y将无效）
                      #  * 0 = 嵌入
                      #  * 1~9 = 对话框外边界的九宫格位置，对话框关闭时无效
                      #  * -1~-9 = 屏幕外框的九宫格位置
                      #  * 其它值 = 无效
    :dx    => 0,      # 选择框的x/y方向的坐标增加量
    :dy    => 0,      #  * 在上述设置定下位置后，再进行位置微调
#  ·行列数
    :h     => 0,      # 选择框的显示行数（默认0自动适配）
    :col   => 1,      # 选择框的列数（默认1）
    :cwd   => 4,      # 每行之间的间距
    :lhd   => 4,      # 每列之间的间距
#  ·调整字符宽高
    :fdw   => 1,      # 计算宽度时，每个字符的宽度增量（默认0）
    :fdh   => 4,      # 计算高度时，每个字符的高度增量（默认0）
                      # * 由于字体计算宽高时可能存在误差，因此增加手工调整
                      # * 如果发现文字超出了光标范围，可以试试调整这两个数值
                      # * fdw 会增大光标的宽度，fdh会增大光标的高度。
#  ·调整选项偏移
    :cdx   => 2,      # 选项绘制时，整体的x方向偏移增量
    :cdy   => 2,      # 选项绘制时，整体的y方向偏移增量
#  ·选择支属性
    :cd    => 0,      # 设置倒计时秒数，倒计时结束时将自动选择取消项
                      # * 必须设置了有效的 取消 分支
                      # * 若使用【计时器扩展 by老鹰】，则占用 :choice_cd 标志符
    :ali   => 0,      # 全部选项文本的对齐方式
                      # * 0=左对齐，1=居中，2=右对齐；默认0 左对齐
    :cit   => 0,      # 选项移入时，字与字的间隔帧数
#  ·特殊
    # 文字绘制预设
    # （具体见【鹰式对话框扩展】中的 FONT_PARAMS_INIT，各个选择支将独立处理）
    :font => {},
    # 文字特效预设
    # （例如填入 :cin => "1" 则启用默认的文字移入效果）
    :charas => {},
  }
#     ---------------------------------------------------------------------
#  ◇ 选择框的最大显示行数

  CHOICE_LINE_MAX = 12
   
#     ---------------------------------------------------------------------
#  ◇ 不存在任何选项时，为避免报错而出现的选项

  CHOICE_TEXT_NO = "（……）"

#     ---------------------------------------------------------------------
#  ◇ do=0嵌入对话框时，选择框宽度是否重置为对话框的文字宽度

  CHOICE_WIDTH_TO_MSG_CHARAS = false

#     ---------------------------------------------------------------------
#  ◇ 是否仅处理当前选中的选择支的文字移出

  CHOICE_CHOSEN_FOR_COUT = true

#     ---------------------------------------------------------------------
#  ◇ 用脚本设置选择框
#
#     >> $game_message.choice_params[sym] = value
#
#     其中 sym 为 CHOICE_PARAMS_INIT 中的键，而 value 为对应的数值（或nil）
#
#  ？ 示例
#
#     $game_message.choice_params[:i] = 1 
#        → 下一次选项框的光标默认在第二个选择支
#
#╰────────────────────────────────────────╯

#  ×                              ······                              ×

#==============================================================================
#                                 × 设定完毕 × 
#==============================================================================
end

#=============================================================================
# ○ Game_System
#=============================================================================
class Game_System
  attr_accessor  :eagle_choices  # 已经看过的选择支的名称数组
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
  #--------------------------------------------------------------------------
  # ● 获取主参数组（方便子窗口修改成自己的game_message）
  #--------------------------------------------------------------------------
  def game_message;   @message_window.game_message;   end
  def choice_params;  game_message.choice_params;     end
  #--------------------------------------------------------------------------
  # ● 获取文字颜色
  #     n : 文字颜色编号（0..31）
  #--------------------------------------------------------------------------
  def text_color(n); MESSAGE_EX.text_color(n, self.windowskin); end
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
    # 重置字体大小
    @message_window.eagle_text_control_font
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
    game_message.choices.each_with_index do |text, index|
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
    choice = @choices_info.find{|i, e| e[:i_e] == game_message.choice_cancel_i_e}
    game_message.choice_cancel_i_w = choice[0] if choice
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
    game_message.choice_cancel_i_e = i_e if $1 && eval($1) == true
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
    w, h = MESSAGE_EX.calculate_text_wh(@message_window.contents, text,
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
      @win_info[:line_h][i] = choice_params[:cdy] + v # 每一行的高度
    end
    n_col.times do |j|
      v = 0 
      n_line.times do |i|
        ci = i * n_col + j
        break if ci >= n
        w_ = @choices_info[ci][:width]
        v = w_ if w_ > v
      end
      @win_info[:col_w][j] = choice_params[:cdx] + v # 每一列的宽度
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
          game_message.child_window_w_des = d # 扩展对话框的宽度
        else
          @flag_in_msg_window = false
        end
      else # 宽度 = 文字区域宽度
        if MESSAGE_EX::CHOICE_WIDTH_TO_MSG_CHARAS
          new_w = win_w + standard_padding * 2 - choice_params[:dx]
        end
      end
      win_h = @message_window.height - standard_padding * 2
      charas_h = @message_window.eagle_charas_y0 - @message_window.y - standard_padding +
        @message_window.eagle_charas_h - @message_window.eagle_charas_oy
      self_h = self.height - (charas_h > 0 ? 1 : 2) * standard_padding
      d = self_h - (win_h - charas_h)
      if d > 0  # 对话框剩余高度不足，没法直接嵌入
        if @message_window.eagle_add_h_by_child_window?  # 可以增加对话框高度？
          game_message.child_window_h_des = d # 扩展对话框的高度
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
  # ● 获取指令相关属性
  #--------------------------------------------------------------------------
  def command_name(index);      @choices_info[index][:text];   end
  def command_enabled?(index);  @choices_info[index][:enable]; end
  def command_chosen?(index);   @choices_info[index][:read];   end

  #--------------------------------------------------------------------------
  # ● 获取行高
  #--------------------------------------------------------------------------
  def line_height
    @max_line_h # game_message.font_params[:size] + 4
  end
  #--------------------------------------------------------------------------
  # ● 获取项目的绘制矩形
  #--------------------------------------------------------------------------
  def item_rect(index)
    rect = Rect.new
    begin
      i_line = index / col_max # 行号
      i_col = index % col_max # 列号
      rect.width = @win_info[:col_w][i_col] # 计算出的所需宽度
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
        rect.y = index * (@max_line_h + spacing_line)
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
    #  ※ 往右偏移导致的新增宽度，不应计入文字居中显示的范畴
    dw = rect.width - @choices_info[index][:width] - choice_params[:cdx]
    case @choices_info[index][:extra][:ali] || choice_params[:ali]
    when 0; x_ = 0
    when 1; x_ = dw / 2
    when 2; x_ = dw
    end
    #  ※ 往下偏移导致的新增高度，不应计入文字居中显示的范畴
    s.draw_text_ex(x_ + choice_params[:cdx], choice_params[:cdy],
      rect.height - choice_params[:cdy], command_name(index))
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
      process_choice(game_message.choices[i_e_old].dup, i_e_old, i_w, false)
      @choices_info[i_w][:enable] = false
      @list[i_w][:enabled] = false # 修改 add_command 中的数据
      redraw_item(i_w)
      @choices[i_w].dispose_timer # 防止二次倒计时
    else
      process_choice(game_message.choices[i_e_new].dup, i_e_new, i_w, false)
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
    game_message.choice_cancel_i_e >= 0 &&  # 设置了取消分支
    (game_message.choice_cancel_i_w < 0 ||  # 取消分支为独立分支
    @choices_info[game_message.choice_cancel_i_w][:enable]) # 取消分支可选
  end
  #--------------------------------------------------------------------------
  # ● 调用“确定”的处理方法
  #--------------------------------------------------------------------------
  def call_ok_handler
    @choices[index].set_confirmed(true)
    if @choices_info[index][:name]
      $game_system.choice_read(@choices_info[index][:name])
    end
    game_message.choice_result = @choices_info[index][:i_e]
    close
  end
  #--------------------------------------------------------------------------
  # ● 调用“取消”的处理方法
  #--------------------------------------------------------------------------
  def call_cancel_handler
    game_message.choice_result = game_message.choice_cancel_i_e
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
    # 每个选择支单独存一个文字绘制参数组
    @font_params = @choice_window.game_message.font_params.dup
    @font_params.merge!(choice_params[:font])
    @ex_params = {}
    @active = false # 是否开始移入
    @visible = false # 是否可见
    @enabled = true
    @chosen = false
    @confirmed = false
    @timer = nil
  end
  #--------------------------------------------------------------------------
  # ● 绑定
  #--------------------------------------------------------------------------
  def message_window; @choice_window.message_window; end
  def choice_params;  @choice_window.choice_params;  end
  def z;              @choice_window.z + 10;         end
  #--------------------------------------------------------------------------
  # ● 设置文字的绘制矩形（相对于选项窗口的左上角）
  #--------------------------------------------------------------------------
  def set_xywh(x = nil, y = nil, w = nil, h = nil)
    @chara_dwin_rect.x = x if x
    @chara_dwin_rect.y = y if y
    @chara_dwin_rect.width = w if w
    @chara_dwin_rect.height = h if h
  end
  def set_rect(rect); @chara_dwin_rect = rect; end
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
  end
  #--------------------------------------------------------------------------
  # ● 设置选项的已经被选择过的状态
  #--------------------------------------------------------------------------
  def set_chosen(bool)
    @chosen = bool
  end
  #--------------------------------------------------------------------------
  # ● 设置选项本次被选择的状态
  #--------------------------------------------------------------------------
  def set_confirmed(bool)
    @confirmed = bool
  end
  #--------------------------------------------------------------------------
  # ● 全部移出
  #--------------------------------------------------------------------------
  def move_out
    @fiber = nil
    if MESSAGE_EX::CHOICE_CHOSEN_FOR_COUT
      @charas.each { |s| s.opacity = 0 if !@confirmed or !s.visible }
    else
      @charas.each { |s| s.opacity = 0 if !s.visible }
    end
    @charas.each { |s| s.move_out }
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
    c = MESSAGE_EX::CHOICE_DEFAULT_COLOR_ID
    c = MESSAGE_EX::CHOICE_CHOSEN_COLOR_ID if @chosen
    @font_params[:c] = c
    @font_params[:ca] = 255
    @font_params[:ca] = 120 if !@enabled
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
    f.set_param(:ex_cg, @ex_params[:cg]) if defined?(Sion_GradientText)

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
      reset_font_settings if param == 0
    when 'FONT'
      param = message_window.obtain_escape_param_string(text)
      MESSAGE_EX.parse_param(@font_params, param, :size)
    when 'I'
      process_draw_icon(message_window.obtain_escape_param(text), pos)
      process_draw_success(pos)
    when 'CG'  # 渐变绘制预定
      @ex_params[:cg].clear
      @ex_params[:cg] = param if param != '' && param != '0'
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
