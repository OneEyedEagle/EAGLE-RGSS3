#==============================================================================
# ■ Add-On2 兼容鼠标 by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【鼠标扩展 by老鹰】以及各个被兼容脚本之下
#==============================================================================
# - 2024.2.3.14
#==============================================================================
# - 本插件对【对话框扩展 by老鹰】及其AddOn进行了简单的鼠标操作兼容
#==============================================================================

#===============================================================================
# ○ 兼容【对话框扩展 by老鹰】
# 1. 在文字显示完毕、等待按键时，按鼠标左键等同于按空格键继续对话
# 2. 在文字显示中途时，鼠标在对话框内部时，按鼠标左键可以快速显示剩余对话
#===============================================================================
if $imported["EAGLE-MessageEX"]
class Window_EagleMessage
  #--------------------------------------------------------------------------
  # ● 等待按键时，按键继续的处理
  #--------------------------------------------------------------------------
  alias eagle_mouse_ex_process_input_pause_key process_input_pause_key
  def process_input_pause_key
    if MOUSE_EX.up?(:ML)
      return @flag_input_loop = false 
    end
    eagle_mouse_ex_process_input_pause_key
  end
  #--------------------------------------------------------------------------
  # ● 监听“确定”键的按下，更新快进的标志
  #--------------------------------------------------------------------------
  alias eagle_mouse_ex_update_show_fast update_show_fast
  def update_show_fast
    eagle_mouse_ex_update_show_fast
    @show_fast = true if mouse_in? && MOUSE_EX.up?(:ML)
  end
end 
end 

#===============================================================================
# ○ 兼容【Add-On 选择框扩展 by老鹰】
# 1. 鼠标必须停留在选项上，才能按鼠标左键来选择该选项
#===============================================================================
if $imported["EAGLE-ChoiceEX"]
class Window_EagleChoiceList
  #--------------------------------------------------------------------------
  # ● 重置
  #--------------------------------------------------------------------------
  alias eagle_mouse_ex_reset eagle_reset
  def eagle_reset
    eagle_mouse_ex_reset
    @flag_mouse_in_win_when_ok = true  # 鼠标必须在选项内，才能按鼠标左键确定
  end
end
end

#===============================================================================
# ○ 兼容【Add-On 数值输入框扩展 by老鹰】
# 1. 鼠标移动到各个数字上时，可以选中对应数字进行修改
# 2. 当使用RGD时，鼠标滚轮可以用来变更当前选中的数字
#===============================================================================
if $imported["EAGLE-NumberInputEX"]
class Window_EagleNumberInput
  #--------------------------------------------------------------------------
  # ● 处理数字的更改
  #--------------------------------------------------------------------------
  alias eagle_mouse_ex_process_digit_change process_digit_change
  def process_digit_change
    eagle_mouse_ex_process_digit_change
    return unless active
    if MOUSE_EX.scroll_up? || MOUSE_EX.scroll_down?
      Sound.play_cursor
      n = @numbers[@index]
      n = (n + 1) % 10 if MOUSE_EX.scroll_up?
      n = (n + 9) % 10 if MOUSE_EX.scroll_down?
      @numbers[@index] = n
      refresh
    end
  end
  #--------------------------------------------------------------------------
  # ● 处理光标的移动
  #--------------------------------------------------------------------------
  alias eagle_mouse_ex_process_cursor_move process_cursor_move
  def process_cursor_move
    eagle_mouse_ex_process_cursor_move
    return unless active
    last_index = @index
    @numbers_rect.each do |i, r|
      _r = r.dup
      _r.x += self.x + standard_padding; _r.y += self.y + standard_padding
      break @index = i if MOUSE_EX.in?(_r)
    end
    Sound.play_cursor if @index != last_index
  end
  #--------------------------------------------------------------------------
  # ● “确定”和“取消”的处理
  #--------------------------------------------------------------------------
  alias eagle_mouse_ex_process_handling process_handling
  def process_handling
    eagle_mouse_ex_process_handling
    return unless active
    return process_ok     if MOUSE_EX.up?(:ML)
    return process_cancel if MOUSE_EX.up?(:MR)
  end
end
end

#==============================================================================
# ○ 兼容【Add-On 并行对话 by老鹰】
# 1. 现在对于需要按键继续的并行对话，在对话框内点击鼠标左键也能同样继续
#==============================================================================
if $imported["EAGLE-MessagePara"]
class Window_EagleMessage_Para < Window_EagleMessage
  #--------------------------------------------------------------------------
  # ● 处理等待时按键继续
  #--------------------------------------------------------------------------
  alias eagle_mouse_ex_msg_para_process_input_pause_key process_input_pause_key
  def process_input_pause_key
    if mouse_in? && MOUSE_EX.up?(:ML)
      return true 
    end
    eagle_mouse_ex_msg_para_process_input_pause_key
  end
end
end
