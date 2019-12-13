#==============================================================================
# ■ 绘制渐变文字 by Sion
# 原贴地址：https://rpg.blue/forum.php?mod=viewthread&tid=335184&highlight=%E6%B8%90%E5%8F%98
#==============================================================================
# 绘制色彩渐变v1.1 更新取消了脚本基需求，脑残了 - -b
# 说明：文字中输入\u[颜色1,颜色2...] 就以渐变色绘制文字，结束渐变插入\u，大小写均可
# 插入文本框测试例子：\u[0,18,9,8]这是渐变文字\u渐变结束
class Window_Base
GRADUAL_SYM = 'U' #修改控制符，需大写。
#-
  alias_method :process_escape_character_NOgradual, :process_escape_character
  def process_escape_character(code, text, pos)
    code.upcase == GRADUAL_SYM ?
      obtain_gradual_param(text, pos) :
      process_escape_character_NOgradual(code, text, pos)
  end
  def obtain_gradual_param(text, pos)
    text = text.slice!(/^\[.*]/)
    if text
      pos[:colors] = []
      text.scan(/\d+/).each_with_index {|c, i| pos[:colors][i] = c.to_i}
      return if pos[:colors].size >= 2
    end
    pos[:colors] = nil
  end
  #
  alias_method :process_nomarl_character_NOgradual, :process_normal_character
  def process_normal_character(c, pos)
    pos[:colors] ?
      process_nomarl_character_gradual(c, pos) :
      process_nomarl_character_NOgradual(c, pos)
  end
  def process_nomarl_character_gradual(c, pos)
    text_width = text_size(c).width
    draw_text(pos[:x], pos[:y], text_width * 2, pos[:height], c)
    colors = pos[:colors].collect {|c| text_color(c)}
    csz = colors.size
    uy = pos[:y]
    l = (pos[:y] + pos[:height] - uy).fdiv(csz - 1)
    for x in pos[:x]...(pos[:x] + text_width)
      sy = uy
      colors.each_with_index {|c1, i|
        for y in sy.round...(sy + l).round
          c = contents.get_pixel(x, y)
          next if c.alpha == 0
          r = (y - sy) / l
          c2 = colors[i + 1]
          c.red *= calc_gradual_rgb(r, c1.red, c2.red)
          c.blue *= calc_gradual_rgb(r, c1.blue, c2.blue)
          c.green *= calc_gradual_rgb(r, c1.green, c2.green)
          contents.set_pixel(x, y, c)
        end
        break if i == csz - 2
        sy += l
      }
    end
    pos[:x] += text_width
  end
  def calc_gradual_rgb(r, v1,v2)
    (v2 > v1 ? (r * (v2-v1) + v1) : ((1-r) * (v1-v2) + v2)) / 255
  end
end

#==============================================================================
# ■ Add-On 模块扩展 by 老鹰
#==============================================================================
module Sion_GradientText
  #--------------------------------------------------------------------------
  # ● 绘制渐变文字
  # colors - 颜色实例or颜色索引号的数组（逐个由上至下绘制）
  #--------------------------------------------------------------------------
  def self.draw_text(bitmap, x, y, w, h, t, align, colors)
    bitmap.draw_text(x, y, w, h, t, align)
    rect_ = bitmap.text_size(t)
    text_width = rect_.width
    y = y + (h - rect_.height) / 2 # 替换为文字绘制的起始y值
    h = rect_.height # 替换为真正的文字高度
    case align
    when 0;
    when 1; x = x + (w - text_width) / 2
    when 2; x = x + w - text_width # 替换为文字绘制的起始x值
    end
    colors = colors.collect { |c| c.is_a?(Color) ? c : text_color(c) }
    csz = colors.size
    uy = y
    l = (y + h - uy).fdiv(csz - 1)
    for _x in x...(x + text_width)
      sy = uy
      colors.each_with_index {|c1, i|
        for _y in sy.round...(sy + l).round
          c = bitmap.get_pixel(_x, _y)
          next if c.alpha == 0
          r = (_y - sy) / l
          c2 = colors[i + 1]
          c.red *= calc_gradual_rgb(r, c1.red, c2.red)
          c.blue *= calc_gradual_rgb(r, c1.blue, c2.blue)
          c.green *= calc_gradual_rgb(r, c1.green, c2.green)
          bitmap.set_pixel(_x, _y, c)
        end
        break if i == csz - 2
        sy += l
      }
    end
  end
  def self.calc_gradual_rgb(r, v1, v2)
    (v2 > v1 ? (r * (v2-v1) + v1) : ((1-r) * (v1-v2) + v2)) / 255
  end
  #--------------------------------------------------------------------------
  # ● 获取文字颜色
  #     n : 文字颜色编号（0..31）
  #--------------------------------------------------------------------------
  def self.text_color(n)
    Cache.system("Window").get_pixel(64 + (n % 8) * 8, 96 + (n / 8) * 8)
  end
end
