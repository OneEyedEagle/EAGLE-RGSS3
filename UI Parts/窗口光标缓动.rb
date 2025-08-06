#==============================================================================
# ■ 窗口光标缓动 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
#==============================================================================
$imported ||= {}
$imported["EAGLE-WinCursorEase"] = "1.0.0"
#==============================================================================
# - 2025.7.31.22 修复窗口每帧激活时，光标错位的bug
#==============================================================================
# - 本插件新增了窗口光标的缓动移动。
#==============================================================================

module EAGLE 
  #--------------------------------------------------------------------------
  # ● 常量：光标每次移动所需时间（单位：帧）
  #-------------------------------------------------------------------------
  WIN_CURSOR_MOVE_TIME = 20
  #--------------------------------------------------------------------------
  # ● 函数：光标移动使用的缓动函数
  #  x 为 当前移动计时 ÷ 总移动时间 的小数（0~1）
  #  返回为该时刻的 移动距离/总距离 的比值
  #  若直接返回 x，则为直线移动
  #-------------------------------------------------------------------------
  def self.cursor_dynamic_ease(x)
    1 - 2**(-10 * x)
  end
end

class Window_Selectable
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #-------------------------------------------------------------------------
  alias eagle_dynamic_cursor_initialize initialize 
  def initialize(x, y, width, height)
    eagle_dynamic_cursor_initialize(x, y, width, height)
    @cursor_c = @cursor_t = 0
  end
  #--------------------------------------------------------------------------
  # ● 更新光标
  #--------------------------------------------------------------------------
  def update_cursor
    last = @cursor_des
    if @cursor_all
      #cursor_rect.set(0, 0, contents.width, row_max * item_height)
      @cursor_des = Rect.new(0, 0, contents.width, row_max * item_height)
      self.top_row = 0
    elsif @index < 0
      #cursor_rect.empty
      @cursor_des = Rect.new(0,0,0,0)
    else
      ensure_cursor_visible
      #cursor_rect.set(item_rect(@index))
      @cursor_des = item_rect(@index)
    end
    if last && last.x == @cursor_des.x && last.y == @cursor_des.y 
      if last.width == @cursor_des.width && last.height == @cursor_des.height
        return 
      end
    end
    @cursor_c = @cursor_t = EAGLE::WIN_CURSOR_MOVE_TIME
    @cursor_ease = {}
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  alias eagle_dynamic_cursor_update update 
  def update 
    eagle_dynamic_cursor_update
    update_cursor_dynamic
  end
  #--------------------------------------------------------------------------
  # ● 动态更新光标
  #--------------------------------------------------------------------------
  def update_cursor_dynamic
    return if @cursor_c == 0
    if @cursor_c == @cursor_t
      r = cursor_rect
      @cursor_ease[:x0] = r.x 
      @cursor_ease[:x1] = @cursor_des.x 
      @cursor_ease[:dx] = @cursor_ease[:x1] -  @cursor_ease[:x0]
      @cursor_ease[:y0] = r.y 
      @cursor_ease[:y1] = @cursor_des.y 
      @cursor_ease[:dy] = @cursor_ease[:y1] -  @cursor_ease[:y0]
      @cursor_ease[:w0] = r.width
      @cursor_ease[:w1] = @cursor_des.width 
      @cursor_ease[:dw] = @cursor_ease[:w1] -  @cursor_ease[:w0]
      @cursor_ease[:h0] = r.height  
      @cursor_ease[:h1] = @cursor_des.height 
      @cursor_ease[:dh] = @cursor_ease[:h1] -  @cursor_ease[:h0]
    end 
    @cursor_c -= 1
    if @cursor_c == 0
      x = @cursor_ease[:x1]
      y = @cursor_ease[:y1]
      w = @cursor_ease[:w1]
      h = @cursor_ease[:h1]
    else
      v = (@cursor_t - @cursor_c) * 1.0 / @cursor_t
      v = EAGLE.cursor_dynamic_ease(v)
      x = @cursor_ease[:x0] + v * @cursor_ease[:dx]
      y = @cursor_ease[:y0] + v * @cursor_ease[:dy]
      w = @cursor_ease[:w0] + v * @cursor_ease[:dw]
      h = @cursor_ease[:h0] + v * @cursor_ease[:dh]
    end
    cursor_rect.set(x,y,w,h)
    cursor_rect.empty if w == 0 && h == 0
  end
end
