#=============================================================================
# ■ 通用组件 by 老鹰（http://oneeyedeagle.lofter.com/）
#=============================================================================
$imported ||= {}
$imported["EAGLE-Utils"] = true
#=============================================================================
# - 2019.5.24.0
#=============================================================================
# - 本插件提供了一系列的全局通用脚本工具
#----------------------------------------------------------------------------
# - 绘制任意两点间的线段：
#
#      EAGLE.DDALine(bitmap, x0, y0, x1, y1[, d, type, c])
#
# 【参数】
#   bitmap → 将线段绘制在该位图上
#   x0, y0 → 以位图左上角为原点，线段起始点的坐标
#   x1, y1 → 以位图左上角为原点，线段终止点的坐标
#   d → 线段的宽度（水平或垂直的延展，未进行反走样处理）（可不填，默认1）
#   type → 线段类型的字符串，由0和1组成，0代表当前位置不绘制，1代表绘制
#           如 "01" 将会进行一次不绘制一次绘制的循环判定（可不填，默认 "1"）
#   c → 线段的颜色 Color.new(r, g, b, a) （可不填，默认纯白色）
#----------------------------------------------------------------------------
# - 绘制指定大小的圆：
#
#     EAGLE.Circle(bitmap, cx, cy, r[, fill, color])
#
# 【参数】
#   bitmap → 将圆绘制在该位图上
#   cx, cy → 以位图左上角为原点，圆心的坐标
#   r → 圆的半径
#   fill → 是否填充内部（默认不填充）
#   color → 圆的颜色（默认纯白色）
#=============================================================================

module EAGLE
  #--------------------------------------------------------------------------
  # ○ 绘制指定类型的线段
  #  type - 由0和1构成的字符串（其中1代表当前位像素绘制，0代表不绘制，将会循环判定）
  #         如 "1100" 将会在绘制两次后跳过两次
  #  算法来源：https://blog.csdn.net/Fitz1318/article/details/53914760
  #--------------------------------------------------------------------------
  def self.DDALine(bitmap, x0, y0, x1, y1, d = 1, type = "1",
    c = Color.new(255,255,255))
    dx = x1 - x0; dy = y1 - y0; x = x0; y = y0; t = 0; s = type.size
    epsl = (dx.abs > dy.abs ? dx.abs : dy.abs) # 取坐标中更大的差值为基准
    xIncre = dx * 1.0 / epsl; yIncre = dy * 1.0 / epsl # 计算坐标单次增量
    epsl.times do
      t = (t + 1) % s
      if type[t] != '0' # 0代表当前点不进行绘制
        if(y0 - y1 <= 0)
          d.times { |i| bitmap.set_pixel((x+0.5).to_i, (y+0.5+i/2).to_i, c) }
        else
          d.times { |i| bitmap.set_pixel((x+0.5+i/2).to_i, (y+0.5).to_i, c) }
        end
      end
      x += xIncre
      y += yIncre
    end
  end
  #--------------------------------------------------------------------------
  # ○ 绘制圆
  # 算法来源：https://www.amobbs.com/thread-5548127-2-1.html
  #--------------------------------------------------------------------------
  def self.Circle(bitmap, cx, cy, r, fill = false,
    color = Color.new(255,255,255))
    x = 0; y = r; d = 3 - 2 * r
    while( x < y )
      circle_point(bitmap, cx, cy, x, y, color, fill)
      if d < 0
        d = d + 4 * x + 6
      else
        d = d + 4 * (x - y) + 10
        y -= 1
      end
      x += 1
    end
    circle_point(bitmap, cx, cy, x, y, color, fill) if x == y
  end
  # 绘制圆上的一组八个对称点
  def self.circle_point(bitmap, cx, cy, x, y, color, fill)
    a1 = [ [cx+x, cy+y], [cx-x, cy+y] ]
    a2 = [ [cx+x, cy-y], [cx-x, cy-y] ]
    a3 = [ [cx+y, cy+x], [cx-y, cy+x] ]
    a4 = [ [cx+y, cy-x], [cx-y, cy-x] ]
    if fill
      [a1, a2, a3, a4].each do |a|
        self.BresenHam(bitmap, a[0][0], a[0][1], a[1][0], a[1][1], color)
      end
    else
      [a1, a2, a3, a4].each do |a|
        a.each { |xy| bitmap.set_pixel(xy[0], xy[1], color) }
      end
    end
  end
  # 绘制1像素宽的线段
  def self.BresenHam(bitmap, x1, y1, x2, y2, color = Color.new(255,255,255))
    dx = (x2 - x1).abs * 2; dy = (y2 - y1).abs * 2
    s1 = (x2 - x1 > 0) ? 1 : -1; s2 = (y2 - y1 > 0) ? 1 : -1
    interchange = 0
    if (dy > dx)
      temp = dx; dx = dy; dy = temp
      interchange = 1
    end
    x = x1; y = y1; e = dy - dx / 2
    (dx / 2).times do
      bitmap.set_pixel(x, y, color) # 此处进行画点 (x, y)
      while(e > 0)
        interchange == 1 ? x = x + s1 : y = y + s2
        e = e - dx
      end
      interchange == 1 ? y = y + s2 : x = x + s1
      e = e + dy
    end
  end
end
