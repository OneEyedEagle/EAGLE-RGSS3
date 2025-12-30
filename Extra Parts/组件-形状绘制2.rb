#=============================================================================
# ■ 组件-形状绘制2 from DeepSeek
#                  edited by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
#=============================================================================
$imported ||= {}
$imported["EAGLE-UtilsDrawing2"] = "1.0.0"
#=============================================================================
# - 2025.12.22.13 
#=============================================================================
# - 本插件提供了一部分Bitmap类中直接使用的形状绘制的方法
# - 本插件已经兼容RPG Maker VX
#----------------------------------------------------------------------------
#  以下方法的共用参数释义：
#
#     bitmap → 绘制在该位图上
#     color  → 所用颜色 Color.new(r, g, b, a) （可不填，默认白色）
#
# 【可用方法一览】
#
#  1. 绘制从 (x1, y1) 到 (x2, y2) 的直线
#
#   bitmap.draw_line(x1, y1, x2, y2[, color])
#
#  2. 绘制从 (x1, y1) 到 (x2, y2) 的虚线
#     其中 dash_length 为实线段长度，gap_length 为虚线段长度
#
#   bitmap.draw_dashed_line(x1, y1, x2, y2, color, dash_length=4, gap_length=4)
#
#  3. 绘制 (x1, y1) 到 (x2, y2) 的带箭头的线
#
#   bitmap.draw_arrow_line(x1, y1, x2, y2, color, arrow_size = 6)
#
#  4. 绘制贝塞尔曲线（二次）
#
#   bitmap.draw_bezier_curve(x1, y1, x2, y2, cx, cy, color, segments = 20)
#
#  5. 绘制圆的轮廓
#
#   bitmap.draw_circle(cx, cy, radius, color)
#
#  6. 填充圆形区域
#
#   bitmap.fill_circle(cx, cy, radius, color)
#
#  7. 绘制矩形的轮廓
#
#   draw_rect(x, y, width, height, color)
#
#  8. 绘制圆角矩形的轮廓
#
#   draw_rounded_rect(x, y, width, height, radius, color)
#
#  9. 绘制圆弧
#
#   draw_circle_arc(cx, cy, radius, start_angle, end_angle, color)
#
#  10. 绘制三角形的轮廓
#
#   draw_triangle(x1, y1, x2, y2, x3, y3, color)
#
#  11. 填充三角形区域
#
#   fill_triangle(x1, y1, x2, y2, x3, y3, color)
#
#  12. 绘制多边形的轮廓
#
#   draw_polygon(points, color)
#
#  13. 填充多边形的区域
#
#   fill_polygon(points, color)
#
#=============================================================================

class Bitmap
  #--------------------------------------------------------------------------
  # * 检查坐标是否在边界内
  #--------------------------------------------------------------------------
  def in_bounds?(x, y)
    x >= 0 && x < self.width && y >= 0 && y < self.height
  end
  
  #--------------------------------------------------------------------------
  # * 绘制直线（Bresenham算法）
  #--------------------------------------------------------------------------
  def draw_line(x1, y1, x2, y2, color=Color.new(255,255,255))
    # 确保起点和终点的整数坐标
    x1, y1 = x1.to_i, y1.to_i
    x2, y2 = x2.to_i, y2.to_i
    
    # 使用Bresenham直线算法
    dx = (x2 - x1).abs
    dy = (y2 - y1).abs
    
    # 确定步进方向
    sx = x1 < x2 ? 1 : -1
    sy = y1 < y2 ? 1 : -1
    
    err = dx - dy
    
    loop do
      # 绘制当前像素（确保在边界内）
      set_pixel(x1, y1, color) if in_bounds?(x1, y1)
      
      # 到达终点
      break if x1 == x2 && y1 == y2
      
      e2 = 2 * err
      
      if e2 > -dy
        err -= dy
        x1 += sx
      end
      
      if e2 < dx
        err += dx
        y1 += sy
      end
    end
  end
  
  #--------------------------------------------------------------------------
  # * 绘制虚线
  #--------------------------------------------------------------------------
  def draw_dashed_line(x1, y1, x2, y2, color=Color.new(255,255,255), 
                       dash_length = 4, gap_length = 4)
    # 计算线段总长度和方向
    dx = x2 - x1
    dy = y2 - y1
    length = Math.sqrt(dx * dx + dy * dy)
    
    # 单位向量
    ux = dx / length
    uy = dy / length
    
    # 绘制虚线
    current_length = 0
    while current_length < length
      # 线段的起始和结束
      seg_start = current_length
      seg_end = [current_length + dash_length, length].min
      
      # 计算实际坐标
      sx1 = x1 + ux * seg_start
      sy1 = y1 + uy * seg_start
      sx2 = x1 + ux * seg_end
      sy2 = y1 + uy * seg_end
      
      # 绘制实线段
      draw_line(sx1.to_i, sy1.to_i, sx2.to_i, sy2.to_i, color)
      
      # 移动到下一段
      current_length = seg_end + gap_length
    end
  end
  
  #--------------------------------------------------------------------------
  # * 绘制带箭头的线
  #--------------------------------------------------------------------------
  def draw_arrow_line(x1, y1, x2, y2, color, arrow_size = 6)
    # 绘制主线段
    draw_line(x1, y1, x2, y2, color)
    
    # 计算箭头方向
    dx = x2 - x1
    dy = y2 - y1
    angle = Math.atan2(dy, dx)
    
    # 箭头角度
    arrow_angle1 = angle + Math::PI - Math::PI / 6
    arrow_angle2 = angle + Math::PI + Math::PI / 6
    
    # 计算箭头顶点
    ax1 = x2 + arrow_size * Math.cos(arrow_angle1)
    ay1 = y2 + arrow_size * Math.sin(arrow_angle1)
    ax2 = x2 + arrow_size * Math.cos(arrow_angle2)
    ay2 = y2 + arrow_size * Math.sin(arrow_angle2)
    
    # 绘制箭头
    draw_line(x2, y2, ax1.to_i, ay1.to_i, color)
    draw_line(x2, y2, ax2.to_i, ay2.to_i, color)
  end
  
  #--------------------------------------------------------------------------
  # * 绘制贝塞尔曲线（二次）
  #--------------------------------------------------------------------------
  def draw_bezier_curve(x1, y1, x2, y2, cx, cy, color, segments = 20)
    # 二次贝塞尔曲线公式: B(t) = (1-t)²P₀ + 2(1-t)tP₁ + t²P₂
    segments.times do |i|
      t1 = i.to_f / segments
      t2 = (i + 1).to_f / segments
      
      # 计算点
      px1 = (1 - t1) * (1 - t1) * x1 + 2 * (1 - t1) * t1 * cx + t1 * t1 * x2
      py1 = (1 - t1) * (1 - t1) * y1 + 2 * (1 - t1) * t1 * cy + t1 * t1 * y2
      
      px2 = (1 - t2) * (1 - t2) * x1 + 2 * (1 - t2) * t2 * cx + t2 * t2 * x2
      py2 = (1 - t2) * (1 - t2) * y1 + 2 * (1 - t2) * t2 * cy + t2 * t2 * y2
      
      # 绘制线段
      draw_line(px1.to_i, py1.to_i, px2.to_i, py2.to_i, color)
    end
  end
  
  #--------------------------------------------------------------------------
  # * 绘制圆形轮廓（中点圆算法）
  #--------------------------------------------------------------------------
  def draw_circle(cx, cy, radius, color)
    cx, cy, radius = cx.to_i, cy.to_i, radius.to_i
    
    x = radius
    y = 0
    err = 0
    
    while x >= y
      # 绘制8个对称点
      draw_circle_points(cx, cy, x, y, color)
      
      y += 1
      err += 1 + 2 * y
      
      if 2 * (err - x) + 1 > 0
        x -= 1
        err += 1 - 2 * x
      end
    end
  end
  
  #--------------------------------------------------------------------------
  # * 绘制圆形的8个对称点
  #--------------------------------------------------------------------------
  def draw_circle_points(cx, cy, x, y, color)
    # 八个对称点
    points = [
      [cx + x, cy + y], [cx - x, cy + y],
      [cx + x, cy - y], [cx - x, cy - y],
      [cx + y, cy + x], [cx - y, cy + x],
      [cx + y, cy - x], [cx - y, cy - x]
    ]
    
    points.each do |px, py|
      set_pixel(px, py, color) if in_bounds?(px, py)
    end
  end
  
  #--------------------------------------------------------------------------
  # * 填充圆形（扫描线填充）
  #--------------------------------------------------------------------------
  def fill_circle(cx, cy, radius, color)
    cx, cy, radius = cx.to_i, cy.to_i, radius.to_i
    
    # 确保半径为正
    return if radius <= 0
    
    # 扫描线填充
    (-radius..radius).each do |y|
      # 计算当前扫描线的x范围
      x_span = Math.sqrt(radius * radius - y * y).to_i
      next if x_span <= 0
      
      # 绘制水平线
      x1 = cx - x_span
      x2 = cx + x_span
      
      # 确保在边界内
      x1 = 0 if x1 < 0
      x2 = width - 1 if x2 >= width
      y_pos = cy + y
      
      # 绘制扫描线
      if y_pos >= 0 && y_pos < height
        fill_rect(x1, y_pos, x2 - x1 + 1, 1, color)
      end
    end
  end
  
  #--------------------------------------------------------------------------
  # * 绘制矩形轮廓
  #--------------------------------------------------------------------------
  def draw_rect(x, y, width, height, color)
    x, y = x.to_i, y.to_i
    width, height = width.to_i, height.to_i
    
    # 上边
    fill_rect(x, y, width, 1, color) if height > 0
    # 下边
    fill_rect(x, y + height - 1, width, 1, color) if height > 0
    # 左边
    fill_rect(x, y, 1, height, color) if width > 0
    # 右边
    fill_rect(x + width - 1, y, 1, height, color) if width > 0
  end
  
  #--------------------------------------------------------------------------
  # * 绘制带圆角的矩形
  #--------------------------------------------------------------------------
  def draw_rounded_rect(x, y, width, height, radius, color)
    x, y = x.to_i, y.to_i
    width, height = width.to_i, height.to_i
    radius = radius.to_i
    
    # 限制圆角半径不超过矩形尺寸的一半
    radius = [radius, width / 2, height / 2].min
    
    # 绘制四个圆角
    draw_circle_arc(x + radius, y + radius, radius, 180, 270, color)  # 左上
    draw_circle_arc(x + width - radius, y + radius, radius, 270, 360, color)  # 右上
    draw_circle_arc(x + width - radius, y + height - radius, radius, 0, 90, color)  # 右下
    draw_circle_arc(x + radius, y + height - radius, radius, 90, 180, color)  # 左下
    
    # 绘制四条直线
    # 上边
    fill_rect(x + radius, y, width - 2 * radius, 1, color) if width > 2 * radius
    # 下边
    fill_rect(x + radius, y + height - 1, width - 2 * radius, 1, color) if width > 2 * radius
    # 左边
    fill_rect(x, y + radius, 1, height - 2 * radius, color) if height > 2 * radius
    # 右边
    fill_rect(x + width - 1, y + radius, 1, height - 2 * radius, color) if height > 2 * radius
  end
  
  #--------------------------------------------------------------------------
  # * 绘制圆弧
  #--------------------------------------------------------------------------
  def draw_circle_arc(cx, cy, radius, start_angle, end_angle, color)
    cx, cy, radius = cx.to_i, cy.to_i, radius.to_i
    
    # 角度转弧度
    start_rad = start_angle * Math::PI / 180
    end_rad = end_angle * Math::PI / 180
    
    # 确保结束角度大于起始角度
    if end_rad < start_rad
      end_rad += 2 * Math::PI
    end
    
    # 步长根据半径调整
    step = 1.0 / radius
    
    # 绘制圆弧
    theta = start_rad
    while theta <= end_rad
      x = (cx + radius * Math.cos(theta)).to_i
      y = (cy + radius * Math.sin(theta)).to_i
      
      set_pixel(x, y, color) if in_bounds?(x, y)
      
      theta += step
    end
  end
  
  #--------------------------------------------------------------------------
  # * 绘制三角形
  #--------------------------------------------------------------------------
  def draw_triangle(x1, y1, x2, y2, x3, y3, color)
    points = [[x1, y1], [x2, y2], [x3, y3]]
    draw_polygon(points, color)
  end
  
  #--------------------------------------------------------------------------
  # * 填充三角形
  #--------------------------------------------------------------------------
  def fill_triangle(x1, y1, x2, y2, x3, y3, color)
    points = [[x1, y1], [x2, y2], [x3, y3]]
    fill_polygon(points, color)
  end
  
  #--------------------------------------------------------------------------
  # * 绘制多边形轮廓
  #--------------------------------------------------------------------------
  def draw_polygon(points, color)
    return if points.size < 2
    
    # 绘制多边形的每条边
    points.each_with_index do |point, i|
      next_point = points[(i + 1) % points.size]
      draw_line(point[0], point[1], next_point[0], next_point[1], color)
    end
  end
  
  #--------------------------------------------------------------------------
  # * 填充多边形（扫描线算法）
  #--------------------------------------------------------------------------
  def fill_polygon(points, color)
    return if points.size < 3
    
    # 找到多边形的边界
    min_y = points.map { |p| p[1].to_i }.min
    max_y = points.map { |p| p[1].to_i }.max
    
    # 对每条扫描线处理
    min_y.upto(max_y) do |scan_y|
      intersections = []
      
      # 检查每条边与扫描线的交点
      points.each_with_index do |point, i|
        next_point = points[(i + 1) % points.size]
        x1, y1 = point[0].to_i, point[1].to_i
        x2, y2 = next_point[0].to_i, next_point[1].to_i
        
        # 确保y1 <= y2
        if y1 > y2
          x1, x2 = x2, x1
          y1, y2 = y2, y1
        end
        
        # 检查扫描线是否与边相交
        if scan_y >= y1 && scan_y <= y2
          # 排除水平线
          if y1 != y2
            # 计算交点x坐标
            x_intersect = x1 + (scan_y - y1) * (x2 - x1).to_f / (y2 - y1)
            intersections << x_intersect
          end
        end
      end
      
      # 排序交点
      intersections.sort!
      #old = intersections.dup
      
      # 老鹰修改：两两匹配后，如果数字相同，说明是顶点
      _temp = []
      (0...intersections.size).step(2) do |i|
        x_start = intersections[i]
        if i + 1 >= intersections.size  # 奇数个的情况，保留最后一个
          _temp << x_start
          break
        end
        x_end = intersections[i + 1]
        if x_start == x_end  # 可能是顶点的情况
          i = points.index{ |xy| xy[0] == x_start and xy[1] == scan_y }
          if i == nil  # 没找到对应的顶点
            _temp << x_start
            _temp << x_end
            next
          end
          # 检查相邻的两个顶点
          xy1 = points[(i + 1) % points.size]
          xy2 = points[(i - 1) % points.size]
          # 如果另外两个顶点都高于scan_y，则这个顶点可以取两次，自身填充
          if xy1[1] > scan_y and xy2[1] > scan_y
            _temp << x_start
            _temp << x_end
          elsif xy1[1] < scan_y and xy2[1] < scan_y
            # 如果另外两个顶点都低于 scan_y，则这个顶点取 0 次，不填充
          else
            # 如果一个高，一个低，则取 1 次，需要与另一个顶点配对
            _temp << x_start
          end
          next
        end
        _temp << x_start
        _temp << x_end
      end
      intersections = _temp
      
      #p "#{old} → #{intersections}"
      
      # 成对填充
      (0...intersections.size).step(2) do |i|
        break if i + 1 >= intersections.size
        
        x_start = intersections[i].ceil
        x_end = intersections[i + 1].floor
        
        # 确保在边界内
        x_start = 0 if x_start < 0
        x_end = self.width - 1 if x_end >= self.width
        
        # 绘制扫描线段
        if scan_y >= 0 && scan_y < self.height && x_end >= x_start
          fill_rect(x_start, scan_y, x_end - x_start + 1, 1, color)
        end
      end
    end
  end
end
