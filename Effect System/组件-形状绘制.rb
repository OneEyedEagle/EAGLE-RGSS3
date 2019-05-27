#=============================================================================
# ■ 组件-形状绘制 by 老鹰（http://oneeyedeagle.lofter.com/）
#=============================================================================
$imported ||= {}
$imported["EAGLE-Utils"] = true
#=============================================================================
# - 2019.5.25.15 新增圆弧、扇形绘制
#=============================================================================
# - 本插件提供了一部分全局通用的关于形状绘制的脚本工具
#----------------------------------------------------------------------------
# 【通用参数】
#   bitmap → 绘制在该位图上
#   fill → 是否填充内部（默认false不填充）
#   color → 绘制/填充所用颜色 Color.new(r, g, b, a) （可不填，默认白色）
#----------------------------------------------------------------------------
# - 绘制任意两点间的线段：
#
#      EAGLE.DDALine(bitmap, x0, y0, x1, y1[, d, type, color])
#
# 【参数】
#   x0, y0 → 以位图左上角为原点，线段起始点的坐标
#   x1, y1 → 以位图左上角为原点，线段终止点的坐标
#   d → 线段的宽度（水平或垂直的延展，未进行反走样处理）（可不填，默认1）
#   type → 线段类型的字符串，由0和1组成，0代表当前位置不绘制，1代表绘制
#           如 "01" 将会进行一次不绘制一次绘制的循环判定（可不填，默认 "1"）
#----------------------------------------------------------------------------
# - 绘制指定大小的圆：
#
#     EAGLE.Circle(bitmap, cx, cy, r[, fill, color])
#
# 【参数】
#   cx, cy → 圆心的坐标（位图左上角为原点）
#   r → 圆的半径
#----------------------------------------------------------------------------
# - 绘制指定角度范围的圆弧：
#
#     EAGLE.Arc(bitmap, cx, cy, r, a1, a2[, fill, color])
#
# 【参数】
#   cx, cy → 圆心的坐标（位图左上角为原点）
#   r → 圆的半径
#   a1，a2 → （水平向右位置为0角度，顺时针）圆弧起始角度、结束角度（角度制0~360）
#----------------------------------------------------------------------------
# - 绘制指定角度范围的扇形：
#
#     EAGLE.Pie(bitmap, cx, cy, r, a1, a2[, fill, color])
#
# 【参数】
#   cx, cy → 圆心的坐标（位图左上角为原点）
#   r → 圆的半径
#   a1，a2 → （水平向右位置为0角度，顺时针）圆弧起始角度、结束角度（角度制0~360）
#=============================================================================

module EAGLE
  #--------------------------------------------------------------------------
  # ○ 绘制指定类型的线段
  #  type - 由0和1构成的字符串（1代表当前位需要绘制，0代表不绘制，循环判定）
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
  #--------------------------------------------------------------------------
  # ○ 绘制圆弧轮廓
  # （以x正方向（水平向右）为起点，顺时针）
  # （a1 a2为起始、终止角度）
  # 算法来源：https://en.wikipedia.org/wiki/Midpoint_circle_algorithm
  #--------------------------------------------------------------------------
  def self.Arc(bitmap, cx, cy, r, a1, a2, fill = false,
    color = Color.new(255,255,255))
    return false if a1 >= a2
    # 存储四个象限中的选取范围（小斜率、大斜率）
    # 第一、三象限最大范围为 0 ～ 正无穷
    # 第二、四象限最大范围为 负无穷 ～ 0
    scopes = { 1 => [-1, -1], 2 => [1, 1], 3 => [-1, -1], 4 => [1, 1] }
    area1 = (a1 + 360) % 360 / 90 + 1
    area2 = (a2 + 360) % 360 / 90 + 1
    area2 = 4 if a2 == 360
    scopes[area1][0] = Math.tan(a1 / 180.0 * Math::PI)
    scopes[area2][1] = Math.tan(a2 / 180.0 * Math::PI)
    while true
      scopes[area2][0] = (area2.even? ? nil : 0) if area2 > area1
      break if area2 == area1
      area2 -= 1
      scopes[area2][1] = (area2.even? ? 0 : nil) # 用nil代表无穷
    end
    arc_circle(bitmap, cx, cy, r, scopes, color, fill)
  end
  # BresenHam算法绘制圆
  def self.arc_circle(bitmap, cx, cy, r, scopes, color, fill)
    x = 0; y = r; d = 3 - 2 * r
    while( x < y )
      arc_circle_point(bitmap, cx, cy, x, y, scopes, color, fill)
      if d < 0
        d = d + 4 * x + 6
      else
        d = d + 4 * (x - y) + 10
        y -= 1
      end
      x += 1
    end
    arc_circle_point(bitmap, cx, cy, x, y, color, fill) if x == y
  end
  # 绘制圆上的指定点
  def self.arc_circle_point(bitmap, cx, cy, x, y, scopes, color, fill)
    [ [cx+x, cy+y], [cx-x, cy+y], [cx+x, cy-y], [cx-x, cy-y],
      [cx+y, cy+x], [cx-y, cy+x], [cx+y, cy-x], [cx-y, cy-x] ].each do |xy|
      if in_arc?(scopes, xy[0] - cx, xy[1] - cy)
        if fill # 暴力方法：绘制更粗的线段来完全覆盖
          #BresenHam(bitmap, cx, cy, xy[0], xy[1], color)
          DDALine(bitmap, cx, cy, xy[0], xy[1], 1, "1", color)
        else
          bitmap.set_pixel(xy[0], xy[1], color)
        end
      end
    end
  end
  # 指定点在圆弧上？（圆点为原点）
  def self.in_arc?(scopes, x, y)
    area_id = get_area_id(x, y)
    k = (x == 0 ? nil : y * 1.0 / x)
    return scopes[area_id].include?(nil) if k.nil?
    return (scopes[area_id][0].nil? || scopes[area_id][0] <= k) &&
      (scopes[area_id][1].nil? || k <= scopes[area_id][1])
  end
  # 获取指定点所在象限（圆点为原点）
  def self.get_area_id(x, y)
    if x >= 0
      return 1 if y >= 0
      return 4
    else
      return 2 if y >= 0
      return 3
    end
  end
  #--------------------------------------------------------------------------
  # ○ 绘制扇形
  #--------------------------------------------------------------------------
  def self.Pie(bitmap, cx, cy, r, a1, a2, fill = false,
    color = Color.new(255,255,255))
    # 预处理
    if a1 > a2
      a1_t = a1
      a1 = a2
      a2 = a1_t
    end
    # 绘制圆弧
    Arc(bitmap, cx, cy, r, a1, a2, false, color)
    # 绘制边界线
    BresenHam(bitmap, cx, cy,
      cx + ((r+1) * Math::cos(a1 * Math::PI / 180.0)).to_i,
      cy + ((r+1) * Math::sin(a1 * Math::PI / 180.0)).to_i, color)
    BresenHam(bitmap, cx, cy,
      cx + ((r+1) * Math::cos(a2 * Math::PI / 180.0)).to_i,
      cy + ((r+1) * Math::sin(a2 * Math::PI / 180.0)).to_i, color)
    return if fill == false
    # 选取合适的填充中心点：确保最大限度覆盖
    if a1 == 0 && a2 > 180 || a2 == 360 # 特殊情况，防止无法正确填充
      x_ = cx - r / 2
      y_ = cy
    else
      x_ = (cx + Math::cos((a1+a2) / 360.0 * Math::PI) * r / 2).to_i
      y_ = (cy + Math::sin((a1+a2) / 360.0 * Math::PI) * r / 2).to_i
    end
    pie_fill(bitmap, x_, y_, color)
  end
  # 填充扇形的透明区域
  def self.pie_fill(bitmap, xo, yo, color)
    array = [ [xo, yo] ]
    until array.empty?
      pos = array.shift
      next if bitmap.get_pixel(pos[0], pos[1]).alpha != 0
      pos_w = pie_find_x_border(bitmap, pos[0], pos[1], 4)
      pos_e = pie_find_x_border(bitmap, pos[0], pos[1], 6)
      BresenHam(bitmap, pos_w[0], pos_w[1], pos_e[0], pos_e[1], color)
      dir = (pos_w[1] > yo ? 2 : 8)
      xl = pos_w[0] + (pos_e[0] - pos_w[0]) / 2
      pos_y = pie_get_next_y(bitmap, xl, pos_e[0], pos_w[1], dir)
      array.push(pos_y) if pos_y
      if pos_w[1] == yo
        pos_y = pie_get_next_y(bitmap, xl, pos_e[0], pos_w[1], 2)
        array.push(pos_y) if pos_y
      end
    end
  end
  # 查找相邻行的可供迭代的起始位置
  def self.pie_get_next_y(bitmap, xl, xr, y, dir)
    while xl < xr
      pos_ = find_neighbor_pos(bitmap, xl, y, dir)
      return pos_ if bitmap.get_pixel(pos_[0], pos_[1]).alpha == 0
      xl += 1
    end
    return nil
  end
  # 找到当前行的不透明边界
  def self.pie_find_x_border(bitmap, x, y, dir)
    pos = find_neighbor_pos(bitmap, x, y, dir)
    while bitmap.get_pixel(pos[0], pos[1]).alpha == 0
      pos_ = find_neighbor_pos(bitmap, pos[0], pos[1], dir)
      break if pos_[0] == pos[0] && pos_[1] == pos[1] # 位图边界
      pos = pos_
    end
    return pos
  end
  # 找到相邻像素位置
  def self.find_neighbor_pos(bitmap, x, y, dir)
    case dir
    when 2; y = y + 1 > bitmap.height-1 ? bitmap.height-1 : y+1
    when 4; x = x - 1 < 0 ? 0 : x-1
    when 6; x = x + 1 > bitmap.width-1 ? bitmap.width-1 : x+1
    when 8; y = y - 1 < 0 ? 0 : y-1
    end
    return [x, y]
  end
end # end of EAGLE
