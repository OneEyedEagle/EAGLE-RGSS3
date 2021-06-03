# 文本替换规则
#
#  替换优先级
module EAGLE
  def self.message_ex_replace(text)
    text
    text
  end
end
#=============================================================================
# ○ Game_Message
#=============================================================================
class Game_Message
end
class Window_EagleMessage
  #--------------------------------------------------------------------------
  # ● 替换转义符（此时依旧是 \\ 开头的转义符）
  #--------------------------------------------------------------------------
  alias eagle_text_replace_process_conv eagle_process_conv
  def eagle_process_conv(text)
    text = eagle_text_replace_process_conv(text)
    # 此处增加替换规则
    text
  end
end


# 弹幕式对话
# 将默认对话替换为滚动弹幕
