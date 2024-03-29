#=============================================================================
# ■ 组件-形状绘制 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
#=============================================================================
$imported ||= {}
$imported["EAGLE-UtilsDrawing"] = "1.0.1"
#=============================================================================
# - 2021.5.19.0 修复绘制线时，传入float型坐标报错的bug
#=============================================================================
# - 本插件提供了一部分全局通用的关于形状绘制的脚本工具
# - 本插件已经兼容RPG Maker VX
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
    (epsl.to_i).times do
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
    scopes[area1][0] = tan(a1)
    scopes[area2][1] = tan(a2)
    while true
      scopes[area2][0] = (area2%2==0 ? nil : 0) if area2 > area1
      break if area2 == area1
      area2 -= 1
      scopes[area2][1] = (area2%2==0 ? 0 : nil) # 用nil代表无穷
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
    arc_circle_point(bitmap, cx, cy, x, y, scopes, color, fill) if x == y
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
    x >= 0 ? (y >= 0 ? 1 : 4) : (y >= 0 ? 2 : 3)
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
      cx + ((r+1) * cos(a1)).to_i, cy + ((r+1) * sin(a1)).to_i, color)
    BresenHam(bitmap, cx, cy,
      cx + ((r+1) * cos(a2)).to_i, cy + ((r+1) * sin(a2)).to_i, color)
    return if fill == false
    # 选取合适的填充中心点：确保最大限度覆盖
    if a1 == 0 && a2 > 180 || a2 == 360 # 特殊情况，防止无法正确填充
      x_ = cx - r / 2
      y_ = cy
    else
      x_ = (cx + cos((a1+a2) / 2) * r / 2).to_i
      y_ = (cy + sin((a1+a2) / 2) * r / 2).to_i
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
  #--------------------------------------------------------------------------
  # ○ Sin查表（0~450度角）
  #  来源：OpenCV
  #  (https://github.com/opencv/opencv/blob/3.4.6/modules/imgproc/src/drawing.cpp)
  #--------------------------------------------------------------------------
  SinTable = [
    0.0000000, 0.0174524, 0.0348995, 0.0523360, 0.0697565, 0.0871557,
    0.1045285, 0.1218693, 0.1391731, 0.1564345, 0.1736482, 0.1908090,
    0.2079117, 0.2249511, 0.2419219, 0.2588190, 0.2756374, 0.2923717,
    0.3090170, 0.3255682, 0.3420201, 0.3583679, 0.3746066, 0.3907311,
    0.4067366, 0.4226183, 0.4383711, 0.4539905, 0.4694716, 0.4848096,
    0.5000000, 0.5150381, 0.5299193, 0.5446390, 0.5591929, 0.5735764,
    0.5877853, 0.6018150, 0.6156615, 0.6293204, 0.6427876, 0.6560590,
    0.6691306, 0.6819984, 0.6946584, 0.7071068, 0.7193398, 0.7313537,
    0.7431448, 0.7547096, 0.7660444, 0.7771460, 0.7880108, 0.7986355,
    0.8090170, 0.8191520, 0.8290376, 0.8386706, 0.8480481, 0.8571673,
    0.8660254, 0.8746197, 0.8829476, 0.8910065, 0.8987940, 0.9063078,
    0.9135455, 0.9205049, 0.9271839, 0.9335804, 0.9396926, 0.9455186,
    0.9510565, 0.9563048, 0.9612617, 0.9659258, 0.9702957, 0.9743701,
    0.9781476, 0.9816272, 0.9848078, 0.9876883, 0.9902681, 0.9925462,
    0.9945219, 0.9961947, 0.9975641, 0.9986295, 0.9993908, 0.9998477,
    1.0000000, 0.9998477, 0.9993908, 0.9986295, 0.9975641, 0.9961947,
    0.9945219, 0.9925462, 0.9902681, 0.9876883, 0.9848078, 0.9816272,
    0.9781476, 0.9743701, 0.9702957, 0.9659258, 0.9612617, 0.9563048,
    0.9510565, 0.9455186, 0.9396926, 0.9335804, 0.9271839, 0.9205049,
    0.9135455, 0.9063078, 0.8987940, 0.8910065, 0.8829476, 0.8746197,
    0.8660254, 0.8571673, 0.8480481, 0.8386706, 0.8290376, 0.8191520,
    0.8090170, 0.7986355, 0.7880108, 0.7771460, 0.7660444, 0.7547096,
    0.7431448, 0.7313537, 0.7193398, 0.7071068, 0.6946584, 0.6819984,
    0.6691306, 0.6560590, 0.6427876, 0.6293204, 0.6156615, 0.6018150,
    0.5877853, 0.5735764, 0.5591929, 0.5446390, 0.5299193, 0.5150381,
    0.5000000, 0.4848096, 0.4694716, 0.4539905, 0.4383711, 0.4226183,
    0.4067366, 0.3907311, 0.3746066, 0.3583679, 0.3420201, 0.3255682,
    0.3090170, 0.2923717, 0.2756374, 0.2588190, 0.2419219, 0.2249511,
    0.2079117, 0.1908090, 0.1736482, 0.1564345, 0.1391731, 0.1218693,
    0.1045285, 0.0871557, 0.0697565, 0.0523360, 0.0348995, 0.0174524,
    0.0000000, -0.0174524, -0.0348995, -0.0523360, -0.0697565, -0.0871557,
    -0.1045285, -0.1218693, -0.1391731, -0.1564345, -0.1736482, -0.1908090,
    -0.2079117, -0.2249511, -0.2419219, -0.2588190, -0.2756374, -0.2923717,
    -0.3090170, -0.3255682, -0.3420201, -0.3583679, -0.3746066, -0.3907311,
    -0.4067366, -0.4226183, -0.4383711, -0.4539905, -0.4694716, -0.4848096,
    -0.5000000, -0.5150381, -0.5299193, -0.5446390, -0.5591929, -0.5735764,
    -0.5877853, -0.6018150, -0.6156615, -0.6293204, -0.6427876, -0.6560590,
    -0.6691306, -0.6819984, -0.6946584, -0.7071068, -0.7193398, -0.7313537,
    -0.7431448, -0.7547096, -0.7660444, -0.7771460, -0.7880108, -0.7986355,
    -0.8090170, -0.8191520, -0.8290376, -0.8386706, -0.8480481, -0.8571673,
    -0.8660254, -0.8746197, -0.8829476, -0.8910065, -0.8987940, -0.9063078,
    -0.9135455, -0.9205049, -0.9271839, -0.9335804, -0.9396926, -0.9455186,
    -0.9510565, -0.9563048, -0.9612617, -0.9659258, -0.9702957, -0.9743701,
    -0.9781476, -0.9816272, -0.9848078, -0.9876883, -0.9902681, -0.9925462,
    -0.9945219, -0.9961947, -0.9975641, -0.9986295, -0.9993908, -0.9998477,
    -1.0000000, -0.9998477, -0.9993908, -0.9986295, -0.9975641, -0.9961947,
    -0.9945219, -0.9925462, -0.9902681, -0.9876883, -0.9848078, -0.9816272,
    -0.9781476, -0.9743701, -0.9702957, -0.9659258, -0.9612617, -0.9563048,
    -0.9510565, -0.9455186, -0.9396926, -0.9335804, -0.9271839, -0.9205049,
    -0.9135455, -0.9063078, -0.8987940, -0.8910065, -0.8829476, -0.8746197,
    -0.8660254, -0.8571673, -0.8480481, -0.8386706, -0.8290376, -0.8191520,
    -0.8090170, -0.7986355, -0.7880108, -0.7771460, -0.7660444, -0.7547096,
    -0.7431448, -0.7313537, -0.7193398, -0.7071068, -0.6946584, -0.6819984,
    -0.6691306, -0.6560590, -0.6427876, -0.6293204, -0.6156615, -0.6018150,
    -0.5877853, -0.5735764, -0.5591929, -0.5446390, -0.5299193, -0.5150381,
    -0.5000000, -0.4848096, -0.4694716, -0.4539905, -0.4383711, -0.4226183,
    -0.4067366, -0.3907311, -0.3746066, -0.3583679, -0.3420201, -0.3255682,
    -0.3090170, -0.2923717, -0.2756374, -0.2588190, -0.2419219, -0.2249511,
    -0.2079117, -0.1908090, -0.1736482, -0.1564345, -0.1391731, -0.1218693,
    -0.1045285, -0.0871557, -0.0697565, -0.0523360, -0.0348995, -0.0174524,
    -0.0000000, 0.0174524, 0.0348995, 0.0523360, 0.0697565, 0.0871557,
    0.1045285, 0.1218693, 0.1391731, 0.1564345, 0.1736482, 0.1908090,
    0.2079117, 0.2249511, 0.2419219, 0.2588190, 0.2756374, 0.2923717,
    0.3090170, 0.3255682, 0.3420201, 0.3583679, 0.3746066, 0.3907311,
    0.4067366, 0.4226183, 0.4383711, 0.4539905, 0.4694716, 0.4848096,
    0.5000000, 0.5150381, 0.5299193, 0.5446390, 0.5591929, 0.5735764,
    0.5877853, 0.6018150, 0.6156615, 0.6293204, 0.6427876, 0.6560590,
    0.6691306, 0.6819984, 0.6946584, 0.7071068, 0.7193398, 0.7313537,
    0.7431448, 0.7547096, 0.7660444, 0.7771460, 0.7880108, 0.7986355,
    0.8090170, 0.8191520, 0.8290376, 0.8386706, 0.8480481, 0.8571673,
    0.8660254, 0.8746197, 0.8829476, 0.8910065, 0.8987940, 0.9063078,
    0.9135455, 0.9205049, 0.9271839, 0.9335804, 0.9396926, 0.9455186,
    0.9510565, 0.9563048, 0.9612617, 0.9659258, 0.9702957, 0.9743701,
    0.9781476, 0.9816272, 0.9848078, 0.9876883, 0.9902681, 0.9925462,
    0.9945219, 0.9961947, 0.9975641, 0.9986295, 0.9993908, 0.9998477,
    1.0000000
  ]
  def self.sin(angle)
    angle = (angle + 360) % 360
    return SinTable[angle]
  end
  def self.cos(angle)
    angle = (angle + 360) % 360
    return SinTable[450 - angle]
  end
  def self.tan(angle)
    return sin(angle) / cos(angle)
  end
end # end of EAGLE
