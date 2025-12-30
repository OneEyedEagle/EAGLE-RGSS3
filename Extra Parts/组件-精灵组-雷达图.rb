#==============================================================================
# ■ 组件-精灵组-雷达图 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【组件-形状绘制2 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-UtilsSpritesetRadar"] = "1.0.0"
#=============================================================================
# - 2025.12.22.23
#=============================================================================
# - 本插件新增了用于显示雷达图的精灵组
#-----------------------------------------------------------------------------
# 【使用方法】
#
#  1. 生成一个显示雷达图的空白精灵组
#
#    s = Spriteset_Radar.new
#
#  2. 初始化参数
#
#    s.reset(v, r, w, h, cx=nil, cy=nil)
#
#    其中 v 是雷达图的顶点数量，需要是大于 3 的正整数。
#         r 是雷达图中心点到最外圈的距离（像素值）。
#         w 和 h 是绘制雷达图的区域大小，请确保至少都比 2倍的r 大。
#         cx 和 cy 是雷达图中心点的坐标，如果不传入则取中心点。
#
#  3. 设置背景层（仅可以设置一个背景层）
#
#    ps_bg = {}
#        → 新建一个Hash参数。
#
#    ps_bg[:mins] = 数字 或 数字的数组
#        → 设置各个数据在中心位置所代表的最小值。
#           （如果为 数字，则所有数据共用该最小值，下同。）
#           （如果为 数组，则按数据顺序，如果数组长度不足，则重复取最后一个，下同。）
#
#    ps_bg[:maxs] = 数字 或 数字的数组
#        → 设置各个数据在最外围位置所代表的最大值。
#
#    ps_bg[:units]= 数字的数组
#        → 设置显示在背景里的同心多边形的位置。
#           数组中均为位置比例的百分数，0代表与中心处重合，100代表在最外圈上。
#
#    ps_bg[:unit_c] = Color.new 或 Color.new的数组
#        → 设置同心多边形的轮廓的颜色。
#           （如果为数组，则按 ps_bg[:units] 顺序，如果不足则重复取最后一个。）
#
#    ps_bg[:line_c] = Color.new 或 Color.new的数组
#        → 设置每条轴的颜色。
#
#    ps_bg[:names]  = 字符串 或 字符串的数组
#        → 设置各个数据的显示名称。
#
#    ps_bg[:name_r] = 数字 或 数字的数组
#        → 设置各个名称与中心点的距离。
#
#    ps_bg[:name_c] = Color.new 或 Color.new的数组
#        → 设置各个名称的颜色。
#
#    s.set_bg(ps_bg)
#        → 传入参数并绘制。
#
#  4. 设置数据层（可以设置多个数据层）
#
#    name = 字符串
#        → 设置该组数据的唯一标识符，之后可以用来对该数据层进行处理。
#
#    data = 数字的数组
#        → 设置一组需要画雷达图多边形的数据。
#           注意！数组长度需要与之前设置的 v 雷达图的顶点数量保持一致。
#
#    ps_data = {}
#        → 新建一个Hash参数。
#
#    ps_data[:vertex_r] = 数字 或 数字的数组
#        → 设置各个数据点的大小。
#
#    ps_data[:vertex_c] = Color.new 或 Color.new的数组
#        → 设置各个数据点的颜色。
#
#    ps_data[:fill_c]   = Color.new(100, 150, 255, 100)
#        → 设置填充颜色。
#
#    ps_data[:border_c] = Color.new(50, 100, 255)
#        → 设置轮廓颜色。
#
#    ps_data[:z] = 0
#        → 设置该数据层的z值增加量。
#           默认会额外 +5，以确保不与背景层显示在同一层。
#
#    s.set_data(name, data, ps_data)
#        → 传入参数并绘制。
#
#  5. 其它设置
#
#    s.set_position(x=nil, y=nil, z=100)
#        → 设置显示位置。
#
#  6. 显示期间
#
#    s.update
#        → 更新，暂无效果。
#
#    ps_bg = s.get_bg
#        → 获取背景层的参数组。
#    sprite_bg = s.get_bg_sprite
#        → 获取背景层的精灵。
#
#    ps_name = s.get_data(name)
#        → 获取指定name的数据层的参数组。
#    sprite_name = s.get_data_sprite(name)
#        → 获取指定name的数据层的精灵。
#    s.show_data(name)
#        → 显示指定name的数据层。
#    s.hide_data(name)
#        → 隐藏指定name的数据层。
#
#  7. 显示结束
#
#    s.dispose
#        → 释放。
#
#-----------------------------------------------------------------------------
# 【使用示例】
#
# - 显示 1 号角色的六维属性的雷达图
#
=begin

@spriteset = Spriteset_Radar.new
@spriteset.reset(6, 80, 500, 500)

ps_bg = { 
  :mins => 0,
  :maxs => 99,
  :names=> ["攻击", "防御", "魔攻", "魔防", "敏捷", "幸运"],
}
@spriteset.set_bg(ps_bg)

actor = $game_actors[1]
data = [actor.atk, actor.def, actor.mat, actor.mdf, actor.agi, actor.luk]
ps_data = {
  :vertex_c => Color.new(50, 100, 200),
  :fill_c => Color.new(100, 150, 255, 50),
  :border_c => Color.new(50, 100, 255, 200),
}
@spriteset.set_data("六维", data, ps_data)
    
@spriteset.set_position(100, 100, 100)

=end
#
#=============================================================================

class Spriteset_Radar
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize
    @x = 0
    @y = 0
    @z = 0
    @params_data = {}  # name => {}
    @sprites_data = {}  # name => Sprite
  end
  #--------------------------------------------------------------------------
  # ● 重置
  #--------------------------------------------------------------------------
  def reset(v, r, w, h, cx=nil, cy=nil)
    @v = v  # 端点的数量
    @r = r  # 轴的长度
    @width = w  # 位图的宽度
    @height = h # 位图的高度
    @cx = cx || @width / 2  # 雷达图的中心点位置
    @cy = cy || @height / 2
    calc_angles(@v)  # 依据端点数量计算各个端点的角度
  end
  #--------------------------------------------------------------------------
  # ● 计算角度
  #--------------------------------------------------------------------------
  def calc_angles(v)
    @angles = []  # 存储每个顶点的 [cos值, sin值]
    v.times do |i|
      if $imported["EAGLE-UtilsDrawing"]
        # 调整起始角度，使顶部为第一个属性
        angle = i * 360 / v - 90
        cos_v = EAGLE.cos(angle)
        sin_v = EAGLE.sin(angle)
      else
        angle = i * Math::PI * 2 / v - Math::PI / 2
        cos_v = Math.cos(angle)
        sin_v = Math.sin(angle)
      end
      @angles << [cos_v, sin_v]
    end
  end
  #--------------------------------------------------------------------------
  # ● 设置位置
  #--------------------------------------------------------------------------
  def set_position(x=nil, y=nil, z=100)
    @x = x if x
    @y = y if y
    @z = z if z
    if @sprite_bg
      @sprite_bg.x = @x
      @sprite_bg.y = @y
      @sprite_bg.z = @z
    end
    @sprites_data.each do |name, s|
      s.x = @x 
      s.y = @y 
      s.z = @z + 5 + @params_data[name][:params][:z] 
    end
  end
  #--------------------------------------------------------------------------
  # ● 获得指定数据的值
  #--------------------------------------------------------------------------
  def get_param_value(value, i)
    if value.is_a?(Array)
      if value[i] == nil
        return value[-1]
      else
        return value[i]
      end
    end
    return value
  end
  #--------------------------------------------------------------------------
  # ● 设置背景层
  #--------------------------------------------------------------------------
  def set_bg(ps_bg)
    @ps_bg ||= {}
    @ps_bg.merge!(ps_bg)
    
    # 各个数据中心点位置所代表的最小值
    @ps_bg[:mins] ||= [0]
    # 各个数据最外围位置所代表的最大值
    @ps_bg[:maxs] ||= [99]
    # 绘制同心多边形的轴长比例（百分数，由小到大）
    @ps_bg[:units]  ||= [25, 50, 75, 100]
    @ps_bg[:units].sort!
    # 同心多边形的颜色
    @ps_bg[:unit_c] ||= Color.new(150, 150, 150, 150)
    # 轴的颜色
    @ps_bg[:line_c] ||= Color.new(150, 150, 150, 150)
    # 各个数据的名称
    @ps_bg[:names]  ||= [""]
    # 名称与中心点的距离
    @ps_bg[:name_r] ||= @r + 20
    # 名称的颜色
    @ps_bg[:name_c] ||= Color.new(255, 255, 255)

    @sprite_bg ||= Sprite.new
    @sprite_bg.bitmap.dispose if @sprite_bg.bitmap
    @sprite_bg.bitmap ||= Bitmap.new(@width, @height)
    @sprite_bg.bitmap.clear 

    # 绘制同心多边形
    @ps_bg[:units].each_with_index do |unit, index|
      _points = []
      @v.times do |i|
        cos_v, sin_v = @angles[i]
        _x = @cx + @r * cos_v * unit * 1.0 / 100
        _y = @cy + @r * sin_v * unit * 1.0 / 100
        _points << [_x, _y]
      end
      @sprite_bg.bitmap.draw_polygon(_points, @ps_bg[:unit_c])
      # 绘制每个顶点的最长的轴线
      if index == @ps_bg[:units].size - 1
        _points.each_with_index do |xy, i|
          _line_c = get_param_value(@ps_bg[:line_c], i)
          @sprite_bg.bitmap.draw_line(@cx, @cy, xy[0].to_i, xy[1].to_i, _line_c)
        end
        @ps_bg[:points] = _points  # 存储最外围多边形的顶点的坐标
      end
    end

    # 绘制名称
    @v.times do |i|
      cos_v, sin_v = @angles[i]
      # 标签位置在雷达图外侧
      label_radius = get_param_value(@ps_bg[:name_r], i)
      _x = @cx + label_radius * cos_v
      _y = @cy + label_radius * sin_v
      
      # 根据位置调整文本对齐方式
      @sprite_bg.bitmap.font.color = get_param_value(@ps_bg[:name_c], i)
      t = get_param_value(@ps_bg[:names], i)
      _r = @sprite_bg.bitmap.text_size(t); _r.width += 10
      @sprite_bg.bitmap.draw_text(_x.to_i-_r.width/2, _y.to_i-_r.height/2, 
        _r.width, _r.height, t, 1)
    end
  end
  def get_bg
    @ps_bg
  end
  def get_bg_sprite
    @sprite_bg
  end
  #--------------------------------------------------------------------------
  # ● 设置数据层
  #--------------------------------------------------------------------------
  def set_data(name, data, ps)
    # 多边形的顶点的大小
    ps[:vertex_r] ||= 4
    # 多边形的顶点的颜色
    ps[:vertex_c] ||= Color.new(155, 155, 255)
    # 多边形的填充颜色
    ps[:fill_c]   ||= Color.new(100, 150, 255, 150)
    # 多边形的轮廓颜色
    ps[:border_c] ||= Color.new(100, 100, 255)
    # 当前层的z值增加量
    ps[:z] ||= 0

    @params_data[name] ||= {}
    @params_data[name][:data] = data
    @params_data[name][:params] = ps

    @sprites_data[name] ||= Sprite.new 
    @sprites_data[name].bitmap.dispose if @sprites_data[name].bitmap
    @sprites_data[name].bitmap ||= Bitmap.new(@width, @height)
    @sprites_data[name].bitmap.clear 

    # 计算每个数据在雷达图上的点
    points = []
    @v.times do |i|
      value = data[i]
      # 计算归一化值（0-1范围）
      min_value = get_param_value(@ps_bg[:mins], i)
      max_value = get_param_value(@ps_bg[:maxs], i)
      _v = (value.to_f - min_value) / max_value
      normalized_value = [[_v, 1.0].min, 0.0].max
      # 计算点在雷达图上的位置
      cos_v, sin_v = @angles[i]
      radius = @r * normalized_value
      _x = @cx + radius * cos_v
      _y = @cy + radius * sin_v
      points << [_x.to_i, _y.to_i]
    end
    @params_data[name][:points] = points  # 存储数据多边形的顶点
    
    # 绘制填充区域
    @sprites_data[name].bitmap.fill_polygon(points, ps[:fill_c])
    
    # 绘制边界线
    points.each_with_index do |point, i|
      next_point = points[(i + 1) % @v]
      @sprites_data[name].bitmap.draw_line(point[0], point[1], 
        next_point[0], next_point[1], ps[:border_c])
    end
    
    # 绘制顶点
    points.each_with_index do |point, i|
      _point_c = get_param_value(ps[:vertex_c], i)
      _point_r = get_param_value(ps[:vertex_r], i)
      @sprites_data[name].bitmap.fill_circle(point[0], point[1], 
        _point_r, _point_c)
    end
  end
  def get_data(name)
    @params_data[name]
  end
  def get_data_sprite(name)
    @sprites_data[name]
  end
  def show_data(name)
    @sprites_data[name].visible = true if @sprites_data[name]
  end
  def hide_data(name)
    @sprites_data[name].visible = false if @sprites_data[name]
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    if @sprite_bg
      @sprite_bg.bitmap.dispose 
      @sprite_bg.dispose 
    end
    @sprites_data.each do |name, s|
      s.bitmap.dispose 
      s.dispose
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
  end
end 
