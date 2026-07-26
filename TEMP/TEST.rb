帮助框扩展


可以绑定一个对象，显示到这个对象上
窗口、精灵、鼠标

可以绑定子文本框，用于显示更多解释说明文本
当主文本框关闭，子文本框一起关闭

module HELP_EX
end

class Window_EagleHelp < Window_Base
  # 初始化
  def initialize(line_number = 2)
    super(0, 0, Graphics.width - 80, fitting_height(line_number))
  end

  # 设置内容
  def set_text(text)
    if text != @text
      @text = text
      refresh
    end
  end
  # 清除
  def clear
    set_text("")
  end

  # 设置物品
  #     item : 技能、物品等
  def set_item(item)
    set_text(item ? item.description : "")
  end

  # 刷新
  def refresh
    contents.clear
    draw_text_ex(4, 0, @text)
  end
end
