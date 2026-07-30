=begin
帮助框扩展


可以绑定一个对象，显示到这个对象上
窗口、精灵、鼠标

可以绑定子文本框，用于显示更多解释说明文本
当主文本框关闭，子文本框一起关闭
=end

module HELP_EX
end

class Window_EagleHelp < Window_Base
  # 初始化
  def initialize
    super(0, 0, 64, 64)
    @des_win_rect = Rect.new(0,0,64,64)
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
    params = { :font_size => 21, :x0 => 4, :y0 => 0, :w => nil }
    d = Process_DrawTextEX.new(@text, params)
    cw = d.width
    ch = d.height + standard_padding * 2
    if contents.width != cw or contents.height != ch
      contents.dispose
      self.contents = Bitmap.new(cw, ch)
      @des_win_rect.width = cw + standard_padding * 2
      @des_win_rect.height = ch + standard_padding * 2
      self.move(@des_win_rect.x, @des_win_rect.y, @des_win_rect.width, @des_win_rect.height)
    else
      contents.clear
    end
    d.bind_bitmap(contents, true)
    d.run
  end

  def update 
    super 
  end
end
