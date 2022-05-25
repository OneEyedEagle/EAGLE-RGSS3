#==============================================================================
# ■ 组件-位图绘制指示文本 by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【组件-位图绘制转义符文本 by老鹰】与
#  【组件-形状绘制 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-DrawHintText"] = "1.0.0"
#==============================================================================
# - 2022.5.24.23
#==============================================================================
# - 本插件提供了在位图上绘制指示型文本的方法
# - 指示型文本示例：
#        __文本__       __文本__
#       /                       \
#      ○                         ○
#-----------------------------------------------------------------------------
# - 为指定精灵创建一个位图，并绘制指示型文本
#
#     EAGLE.draw_hint_text(sprite, text, params1 = {}, params2 = {})
#
#   其中 sprite 为一个不含有bitmap的精灵，在执行后将拥有一个bitmap
#   其中 text 为需要显示的文本的字符串
#   其中 params1 为参数Hash，具体见方法注释
#   其中 params2 为【组件-位图绘制转义符文本 by老鹰】的参数Hash
#
# - 在绘制完成后，sprite 的显示原点将定位在 指示圆点 处，同时坐标移动到传入的:x, :y处
#
# - 示例：
#
#    事件脚本中测试使用，触发后将在1号事件上显示“指示牌”，按下确定键后结束显示
=begin
e = $game_map.events[1]
x = e.screen_x
y = e.screen_y - 16
s1 = Sprite.new
ps1 = { :x => x, :y => y,
 :dx => 40, :dy => 30 }
t = "指示牌"
EAGLE.draw_hint_text(s1, t, ps1)
Fiber.yield until Input.trigger?(:C)
=end
#
#==============================================================================
module EAGLE
  #--------------------------------------------------------------------------
  # ● 绘制
  #  params1  # 指示线绘制
  #   :x 和 :y   → 指示点的屏幕坐标，也为精灵的显示原点
  #   :dx 和 :dy → 文字底部横线 与 指示圆点 连线的一端的偏移坐标（以指示点坐标为始）
  #   :line      → 连线的宽度
  #   :padding   → 位图四周的留空像素值
  #   :dlr       → 文字区域的左右留空像素值
  #   :dud       → 文字区域的上下留空像素值
  #
  #  params2  # 文字绘制
  #   :font_size → 绘制初始的文字大小
  #   :font_color → 指定初始的绘制颜色 Color.new
  #   :x0 → 指定每行的向右偏移值
  #   :y0 → 指定首行的向下偏移值
  #   :w → 规定最大行宽，若超出则会进行自动换行
  #   :lhd → 在换行时，与下一行的间隔距离
  #--------------------------------------------------------------------------
  def self.draw_hint_text(sprite, text, params1 = {}, params2 = {})
    params1 = params1
    params2 = params2

    params1[:x] ||= 0
    params1[:y] ||= 0
    params1[:dx] ||= 0
    params1[:dy] ||= 0
    params1[:line] ||= 2
    params1[:padding] ||= 4
    params1[:dlr] ||= 4
    params1[:dud] ||= 2

    proc_draw_text = Process_DrawTextEX.new(text, params2)
    params1[:text_w] = proc_draw_text.width  # 文字的宽高
    params1[:text_h] = proc_draw_text.height

    line = params1[:line]  # 线宽度
    border = params1[:padding]  # 位图四周的留空
    border_text_lr = params1[:dlr]  # 文字区域的左右留空
    border_text_ud = params1[:dud]  # 文字区域的上下留空
    dw = params1[:dx].abs  # 斜线占据的宽高
    dh = params1[:dy].abs

    x0 = y0 = 0  # 文字的起始绘制位置
    x_p0 = y_p0 = 0  # 指示点在位图里的位置
    x_p2 = y_p2 = 0  # 直线远端的坐标偏移量
    # 计算位图宽高，各个绘制的位置
    w = border * 2 + dw + border_text_lr * 2 + params1[:text_w]
    if params1[:dx] >= 0  # 文字显示在右侧
      x0 = border + dw + border_text_lr
      x_p0 = border
      x_p2 = border_text_lr * 2 + params1[:text_w]
    else  # 文字显示在左侧
      x0 = border + border_text_lr
      x_p0 = w - border
      x_p2 = - (border_text_lr * 2 + params1[:text_w] )
    end
    h = 0
    if params1[:dy] >= 0  # 文字显示在下侧
      h = border * 2 + [dh, border_text_ud * 2 + params1[:text_h]].max
      y0 = border + [(dh - border_text_ud * 2 - params1[:text_h]), 0].max
      y_p0 = border
    else  # 文字显示在上侧
      h = border * 2 + dh + border_text_ud * 2 + params1[:text_h]
      y0 = border + border_text_ud
      y_p0 = h - border
    end

    # 绘制文本
    sprite.bitmap = Bitmap.new(w, h)
    params2[:x0] = x0
    params2[:y0] = y0
    proc_draw_text.bind_bitmap(sprite.bitmap)
    proc_draw_text.run

    # 绘制指示点处的圆
    EAGLE.Circle(sprite.bitmap, x_p0, y_p0, line, true, Color.new(255,255,255))

    # 绘制指示点与文本底部线的连线
    x_p1 = x_p0 + params1[:dx]
    y_p1 = y_p0 + params1[:dy]
    EAGLE.DDALine(sprite.bitmap, x_p0, y_p0, x_p1, y_p1, line, "1", Color.new(255,255,255))

    # 绘制文字底部的横线
    x_p2 += x_p1
    y_p2 += y_p1
    EAGLE.DDALine(sprite.bitmap, x_p1, y_p1, x_p2, y_p2, line, "1", Color.new(255,255,255))

    # 调整位置
    sprite.x = params1[:x]
    sprite.y = params1[:y]
    # 调整显示原点到指示点处
    sprite.ox = x_p0
    sprite.oy = y_p0
  end
end
