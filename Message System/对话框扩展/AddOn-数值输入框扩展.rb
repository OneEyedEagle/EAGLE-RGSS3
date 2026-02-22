#==============================================================================
# ■ Add-On 数值输入框扩展 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【鹰式对话框扩展 V2.0】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-NumberInputEX"] = "2.2.0"
#=============================================================================
# - 2026.2.22.11 随对话框更新
#=============================================================================
# 【使用：设置数字样式】
#
# - 利用 事件脚本 设置下一次数值输入的模式：
#
#      $game_message.set_numinput_t(str) 
#
#   其中 str 为字符串，用 * 代表可以变更的数字，用 \n 进行换行，可增加其余文本。
#
#   注意：设置后，编辑器中设置的最大位数将无效。
#
#     ---------------------------------------------------------------------
#  ？ 示例
#
#     $game_message.set_numinput_t("**时**分")
#
#     → 下一次数值输入时，将显示 00时00分 ，并对其中的四个0进行切换
#
#------------------------------------------------------------------------------
# 【使用：设置数字上下限】
#
# - 利用 事件脚本 设置下一次数值输入的限制：
#
#  1. 设置某一位的最大值最小值：
#
#     $game_message.set_numinput_limit(index, min, max)
#
#    其中 index 为从 0 开始计数的数字位数，如 8010 中，数字 1 的 index 值为 2
#    其中 min/max 为最小值和最大值，若传入 nil，则为无限制，可输入 0~9
#
#  2. 设置多位的最大值最小值：
#
#     $game_message.set_numinput_mlimit(index1, index2, min, max)
#
#    如 index1 = 2, index2 = 3，则将设置 8010 中的 10 两位数字的最大值最小值
#
#     ---------------------------------------------------------------------
#  ？ 示例
#
#    1. 在事件脚本中编写：
#       $game_message.set_numinput_t("**时**分")
#       $game_message.set_numinput_mlimit(0,1,0,23)
#       $game_message.set_numinput_mlimit(2,3,0,59)
#
#    2. 设置事件指令：数值输入（1号变量）（任意位数）
#
#    → 开始数值输入时，将显示 00时00分
#        且第一位和第二位的输入范围是 00 ~ 23
#        且第三位和第四位的输入范围是 00 ~ 59
#      当确认后，如输入结果 12时31分，1号变量将存储数字 1231 
#
#------------------------------------------------------------------------------
module MESSAGE_EX
#╔════════════════════════════════════════╗
# A■ 数值输入框设置                                                \NUMINPUT ■
#  ────────────────────────────────────────

#  ● \numinput[param]

#     ---------------------------------------------------------------------
#  ◇ 预设参数         ▼ [param]“参数串”一览（字母+数字组合）
  NUMINPUT_PARAMS_INIT = {

    :o  => 7,     # 窗口的原点类型（对应小键盘九宫格 | 默认值为7 左上角）
    :x  => nil,   # 窗口的显示位置（屏幕坐标）
    :y  => nil,
    :do => 0,     # 窗口的显示位置（覆盖 :x 和 :y 的设置）
                  #  * 0 → 嵌入对话框，此时 :o 锁定为 7，:opa 锁定为 0
                  #  * 1~9 → 对话框外边界的九宫格位置
                  #  * -1~-9 → 屏幕外框的九宫格位置
                  #（当对话框关闭时，0~9 的显示位置无效）
    :dx => 0,     # 窗口位置的左右偏移值（正数往右、负数往左）
    :dy => 0,     # 窗口位置的上下偏移值（正数往下、负数往上）
    :opa => 255,  # 背景的不透明度（文字的不透明度固定为255）
    :skin => nil, # 窗口皮肤（默认取对话框皮肤）
                  #  * 具体见 INDEX_TO_WINDOWSKIN 
  }
#╚════════════════════════════════════════╝

#==============================================================================
#                                 × 设定完毕 × 
#==============================================================================
end

#==============================================================================
# ○ Game_Message
#==============================================================================
class Game_Message
  attr_accessor :numinput_pattern
  attr_accessor :numinput_params, :numinput_limits
  #--------------------------------------------------------------------------
  # ● 新增 numinput 的参数hash
  #--------------------------------------------------------------------------
  alias eagle_numinput_ex_params eagle_params
  def eagle_params
    eagle_numinput_ex_params + [:numinput]
  end
  #--------------------------------------------------------------------------
  # ● 清除
  #--------------------------------------------------------------------------
  alias eagle_numinput_ex_clear clear
  def clear
    eagle_numinput_ex_clear
    @numinput_pattern = "" # 数值输入的模式字符串（其中*代表数字，其余为绘制内容）
    @numinput_limits = {}
  end
  #--------------------------------------------------------------------------
  # ● 设置数值字符串
  #--------------------------------------------------------------------------
  def set_numinput_t(str)
    @numinput_pattern = str
  end
  #--------------------------------------------------------------------------
  # ● 设置数值界限
  #--------------------------------------------------------------------------
  def set_numinput_limit(index, min = 0, max = 9)
    @numinput_limits[index] = [min, max]
  end
  def set_numinput_mlimit(index1, index2, min = 0, max = nil)
    @numinput_limits[ [index1, index2] ] = [min, max]
  end
end
class Window_EagleMessage
  #--------------------------------------------------------------------------
  # ● \numinput   #--------------------------------------------------------------------------
  def eagle_text_control_numinput(param = "")
    parse_param(game_message.numinput_params, param, :do)
  end
end

#==============================================================================
# ○ Window_EagleNumberInput
#==============================================================================
class Window_EagleNumberInput < Window_Base
  def numinput_params; $game_message.numinput_params; end
  def text_color(n); MESSAGE_EX.text_color(n, self.windowskin); end
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize(message_window)
    @message_window = message_window
    @numbers = []
    @numbers_rect = {} # number_index => Rect 从左到右，从上到下
    super(0, 0, 0, 0)
    @number = 0
    @digits_max = 1
    @index = 0
    self.openness = 0
    deactivate
  end

  #--------------------------------------------------------------------------
  # ● 开始输入的处理
  #--------------------------------------------------------------------------
  def start
    pre_draw
    update_size
    create_contents
    update_placement
    update_params_ex
    refresh
    @index = 0
    hide
    #open
    #activate
  end

  # 预处理
  def pre_draw
    @numbers_rect.clear; @numbers.clear
    # 获取位数
    @number = $game_variables[$game_message.num_input_variable_id]
    @number = [[@number, 0].max, 10 ** @digits_max - 1].min
    if $game_message.numinput_pattern.empty?
      $game_message.numinput_pattern = "*" * $game_message.num_input_digits_max
    end
    @digits_max = $game_message.numinput_pattern.count("*")

    # 计算窗口的最大宽高
    @width_max = 0; @height_max = 0
    _x = 0; _y = 0; _w = 0; _h = 0; _index = 0
    $game_message.numinput_pattern.each_char do |c|
      if c == "\n"
        _y += _h; _h = 0; next
      end
      is_number = c == "*"
      rect = text_size(is_number ? '0' : c)
      _h = [rect.height, line_height, _h].max
      @height_max = [@height_max, _h].max
      if is_number
        place = 10 ** (@digits_max - 1 - _index)
        v = @number / place % 10
        @numbers.push(v)
        _w = [rect.width, 20].max
        @numbers_rect[_index] = Rect.new(_x, _y, _w, _h)
        _index += 1
      else
        _w = rect.width
      end
      _x += _w
      @width_max = [@width_max, _x].max
    end
  end

  # 更新窗口宽高
  def update_size
    self.width = @width_max + padding * 2
    self.height = @height_max + padding * 2

    # 处理嵌入的特殊情况
    @flag_in_msg_window = @message_window.child_window_embed_in? && numinput_params[:do] == 0
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
      if d > 0
        if @message_window.eagle_add_h_by_child_window?
          $game_message.child_window_h_des = d # 扩展对话框的高度
        else
          @flag_in_msg_window = false
        end
      end
    end
    self.width = new_w if @flag_in_msg_window
  end

  # 更新窗口位置
  def update_placement
    self.x = (Graphics.width - width) / 2
    if @message_window.y >= Graphics.height / 2
      self.y = @message_window.y - height - 8
    else
      self.y = @message_window.y + @message_window.height + 8
    end

    self.x = numinput_params[:x] if numinput_params[:x]
    self.y = numinput_params[:y] if numinput_params[:y]
    o = numinput_params[:o]
    if (d_o = numinput_params[:do]) < 0 # 相对于屏幕
      MESSAGE_EX.reset_xy_dorigin(self, nil, d_o)
    elsif @message_window.open?
      if d_o == 0 # 嵌入对话框
        if @flag_in_msg_window
          self.x = @message_window.eagle_charas_x0 - standard_padding
          self.y = @message_window.eagle_charas_y0 + @message_window.eagle_charas_h
          self.y -= standard_padding if @message_window.eagle_charas_h == 0
          o = 7
        end
      else
        MESSAGE_EX.reset_xy_dorigin(self, @message_window, d_o)
      end
    end
    MESSAGE_EX.reset_xy_origin(self, o)
    self.x += numinput_params[:dx]
    self.y += numinput_params[:dy]
    self.z = @message_window.z + 10
  end

  # 更新其他属性
  def update_params_ex
    skin = @message_window.get_cur_windowskin_index(numinput_params[:skin])
    self.windowskin = MESSAGE_EX.windowskin(skin)
    self.opacity = self.back_opacity = numinput_params[:opa]
    self.contents_opacity = 255

    if @flag_in_msg_window # 如果嵌入，则不执行打开
      self.opacity = 0
      self.openness = 255
    end
  end

  #--------------------------------------------------------------------------
  # ● 刷新
  #--------------------------------------------------------------------------
  def refresh
    check_limits
    contents.clear
    reset_font_settings
    _x = 0; _y = 0; _w = 0; _h = 0; _index = 0
    $game_message.numinput_pattern.each_char do |c|
      if c == "\n"
        _y += _h; _h = 0
        next
      end
      is_number = c == "*"
      _c = is_number ? @numbers[_index].to_s : c
      rect = text_size(_c)
      if is_number
        rect.width = [rect.width, 20].max
        _index += 1
      end
      rect.height = [rect.height, line_height, _h].max
      draw_text(_x+1,_y,rect.width+2,rect.height, _c, 1)
      _x += rect.width
      _h = rect.height
    end
  end

  # 检查上下限
  # { [index, index2] => [min, max], index => [min, max] }
  def check_limits
    $game_message.numinput_limits.each do |k, v|
      if k.is_a?(Integer)
        _v = @numbers[k]
        _v = v[0] if v[0] && v[0] > v
        _v = v[1] if v[1] && v[1] < v
        @numbers[k] = _v
      elsif k.is_a?(Array)
        i = k[0]; v_str = ""
        while(i <= k[1])
          v_str += @numbers[i].to_s
          i += 1
        end
        _v = v_str.to_i
        _v = v[0] if v[0] && v[0] > _v
        _v = v[1] if v[1] && v[1] < _v
        i2 = k[0]
        while(i2 <= k[1])
          place = 10 ** (i - 1 - i2)
          @numbers[i2] = _v / place % 10
          i2 += 1
        end
      end
    end
  end

  # 重置字体设置
  def reset_font_settings
    change_color(text_color(MESSAGE_EX::DEFAULT_COLOR_INDEX))
  end
  
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
    process_cursor_move
    update_cursor
    process_digit_change
    process_handling
    update_placement if @message_window.open? && numinput_params[:do] == 0
  end

  # 设置当前选中的项
  def process_cursor_move
    return unless active
    last_index = @index
    cursor_right(Input.trigger?(:RIGHT)) if Input.repeat?(:RIGHT)
    cursor_left (Input.trigger?(:LEFT))  if Input.repeat?(:LEFT)
    Sound.play_cursor if @index != last_index
  end
  # 光标向右移动
  #     wrap : 允许循环
  def cursor_right(wrap)
    if @index < @digits_max - 1 || wrap
      @index = (@index + 1) % @digits_max
    end
  end
  # 光标向左移动
  #     wrap : 允许循环
  def cursor_left(wrap)
    if @index > 0 || wrap
      @index = (@index + @digits_max - 1) % @digits_max
    end
  end
  # 更新光标
  def update_cursor
    cursor_rect.set(item_rect(@index)) if item_rect(@index)
  end
  # 获取项目的绘制矩形
  def item_rect(index)
    @numbers_rect[index]
  end

  # 处理数字的改变
  def process_digit_change
    return unless active
    if Input.repeat?(:UP) || Input.repeat?(:DOWN)
      Sound.play_cursor
      n = @numbers[@index]
      n = (n + 1) % 10 if Input.repeat?(:UP)
      n = (n + 9) % 10 if Input.repeat?(:DOWN)
      @numbers[@index] = n
      refresh
    end
  end

  # “确定”和“取消”的处理
  def process_handling
    return unless active
    return process_ok     if Input.trigger?(:C)
    return process_cancel if Input.trigger?(:B)
  end
  # 按下确定键时的处理
  def process_ok
    Sound.play_ok
    v = @numbers.inject("") {|s, v| s += "#{v}" }.to_i
    $game_variables[$game_message.num_input_variable_id] = v
    deactivate
    close
  end
  # 按下取消键时的处理
  def process_cancel
  end
end
