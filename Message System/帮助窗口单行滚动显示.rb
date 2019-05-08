#===============================================================================
# ○ 帮助窗口单行滚动显示  by老鹰
#  注：本脚本只修改了默认的 帮助窗口，且只在单行文本下生效
#===============================================================================
class Window_Help < Window_Base
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  alias eagle_auto_scroll_init initialize
  def initialize(line_number = 2)
    @line_number = line_number
    eagle_auto_scroll_init(line_number)
    @d = 0
  end
  #--------------------------------------------------------------------------
  # ● 设置内容
  #--------------------------------------------------------------------------
  def set_text(text)
    return if text == @text
    @text = text
    if @line_number == 1 && text != ""
      width = text.scan(/(\e|\\)*i\[\d+\]/m).inject(0) { |sum, id| sum += 24 }
      _text = text.gsub(/(\e|\\)*\w+\[\d+\]/m, "")
      @width = text_size(_text).width + width
      contents.dispose
      self.contents = Bitmap.new(@width, contents_height)
      init_scroll
    end
    reset_scroll
    refresh
  end
  #--------------------------------------------------------------------------
  # ● 初始化滚动
  #--------------------------------------------------------------------------
  def init_scroll
    @d = @width - self.width + 2 * standard_padding
    @wait = 80 # frames of waiting when starting or ending
    @speed = 5 # moving 1 pixel within @speed frames
  end
  #--------------------------------------------------------------------------
  # ● 重置滚动
  #--------------------------------------------------------------------------
  def reset_scroll
    self.ox = 0
    @_wait = @wait
    @_speed = @speed
  end
  #--------------------------------------------------------------------------
  # ● 更新滚动
  #--------------------------------------------------------------------------
  def update_scroll
    if @_wait > 0
      return @_wait -= 1
    else
      return reset_scroll if self.ox > @d
      return @_speed -= 1 if @_speed > 0
      self.ox += 1
      return if self.ox <= @d
      @_wait = @wait
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
    update_scroll if @line_number == 1 && @d > 0
  end
end
