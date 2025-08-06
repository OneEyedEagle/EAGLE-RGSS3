#==============================================================================
# ■ 粒子模板-发射类 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【粒子系统V3 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-PT-Emitter"] = "3.0.0"
#==============================================================================
# - 2023.4.30.10 重构，方便扩展多样化的模板 
#==============================================================================
# - 本插件新增了一组从指定位置朝指定方向发射粒子的模板
#------------------------------------------------------------------------------
# 【高级】
#
# - PT_Emitter 类的可设置参数，请见 init_settings 方法中的注释
#
#==============================================================================
class PT_Emitter < ParticleTemplate
  #--------------------------------------------------------------------------
  # ● 初始化粒子的动态参数
  #--------------------------------------------------------------------------
  def init_settings
    super
    # 粒子所用的bitmap的数组（在数组中随机取一个）
    @params[:bitmaps] = [] 
    # 粒子生成的区域（在区域内随机一个点）（窗口坐标）
    @params[:pos_rect] = Rect.new(0,0,0,0)
    # 作用力（加速度）Vector
    @params[:force]    = Vector.new(0,0)
    
    # 以下变量均可以传入 VarValue类型 或 数值 或 字符串（会先用eval求值）
    @params[:theta] = VarValue.new(0, 0) # 初速度方向（角度）
    @params[:speed] = VarValue.new(0, 0) # 初速度值（标量）
    @params[:start_opa] = VarValue.new(255, 0) # 开始时透明度
    @params[:end_opa] = VarValue.new(0, 0)  # 结束时透明度
    @params[:start_angle] = VarValue.new(0, 0) # 开始时角度
    @params[:angle] = VarValue.new(0, 0) # 每一次更新时的旋转角度
    @params[:start_zoom] = VarValue.new(1.0, 0) # 开始时的缩放值
    @params[:end_zoom] = VarValue.new(1.0, 0) # 结束时的缩放值
  end
  #--------------------------------------------------------------------------
  # ● 释放粒子的动态参数
  #--------------------------------------------------------------------------
  def dispose_settings
    super
    @params[:bitmaps].each { |b| b.dispose }
    @params[:bitmaps].clear
  end
  #--------------------------------------------------------------------------
  # ● 粒子开始
  #--------------------------------------------------------------------------
  def start_particle
    super
    init_bitmap
    init_xy
    init_speed
    init_opa
    init_angle
    init_zoom
    init_others
  end
  #--------------------------------------------------------------------------
  # ● 粒子更新
  #--------------------------------------------------------------------------
  def update_particle
    super
    update_bitmap
    update_xy
    update_speed
    update_opa
    update_angle
    update_zoom
    update_others
  end
  #--------------------------------------------------------------------------
  # ● 粒子结束
  #--------------------------------------------------------------------------
  def finish_particle
    super
  end

  #--------------------------------------------------------------------------
  # ● 位图初值与每次更新
  #--------------------------------------------------------------------------
  def init_bitmap
    if particle_from_sprite?(@particle)
    else
      @particle.bitmap = get_bitmap if @particle.bitmap == nil
      @particle.ox = @particle.width / 2
      @particle.oy = @particle.height / 2
    end
  end
  def update_bitmap
  end
  #--------------------------------------------------------------------------
  # ● 获取一个位图作为初始值
  #--------------------------------------------------------------------------
  def get_bitmap
    b = @params[:bitmaps][ rand(@params[:bitmaps].size) ]
    return b || Cache.empty_bitmap
  end
  #--------------------------------------------------------------------------
  # ● 显示位置初值与每次更新
  #--------------------------------------------------------------------------
  def init_xy
    if particle_from_sprite?(@particle)
      v = Vector.new(@particle.x, @particle.y)
    else
      r = @params[:pos_rect]  # 在该矩形内随机一个位置
      v = Vector.new(r.x, r.y) + Vector.new(rand(r.width), rand(r.height))
    end
    # （屏幕坐标）初始显示位置
    @particle.eparams[:pos] = v
    # 移动中所产生的偏移值
    @particle.eparams[:pos_offset] = Vector.new
  end
  def update_xy
    @particle.x = @particle.eparams[:pos].x + @particle.eparams[:pos_offset].x
    @particle.y = @particle.eparams[:pos].y + @particle.eparams[:pos_offset].y
  end
  #--------------------------------------------------------------------------
  # ● 移动速度初值与每次更新
  #--------------------------------------------------------------------------
  def init_speed
    theta = get_value(@params[:theta])
    x = Math.cos(theta * Math::PI / 180.0)
    y = Math.sin(theta * Math::PI / 180.0)
    @particle.eparams[:dir] = Vector.new(x, y) * get_value(@params[:speed])
  end
  def update_speed
    # 计算下一帧的移动位置
    @particle.eparams[:pos_offset] += @particle.eparams[:dir]
    # 计算下一帧的速度
    @particle.eparams[:dir] += @params[:force]
  end
  #--------------------------------------------------------------------------
  # ● 不透明度初值与每次更新
  #--------------------------------------------------------------------------
  def init_opa
    if particle_from_sprite?(@particle)
    else
      @particle.opacity = get_value(@params[:start_opa])
    end
    @particle.eparams[:opa_delta] =
      (@params[:end_opa].v - @particle.opacity) / @particle.eparams[:life]
  end
  def update_opa
    @particle.opacity += @particle.eparams[:opa_delta]
  end
  #--------------------------------------------------------------------------
  # ● 角度初值与每次更新
  #--------------------------------------------------------------------------
  def init_angle
    if particle_from_sprite?(@particle)
    else
      @particle.angle = get_value(@params[:start_angle])
    end
    @particle.eparams[:angle_delta] = get_value(@params[:angle]) # 每帧旋转度数
  end
  def update_angle
    @particle.angle += @particle.eparams[:angle_delta]
  end
  #--------------------------------------------------------------------------
  # ● 缩放初值与每次更新
  #--------------------------------------------------------------------------
  def init_zoom
    if particle_from_sprite?(@particle)
    else
      @particle.zoom_x = @particle.zoom_y = get_value(@params[:start_zoom])
    end
    @particle.eparams[:zoom_delta] =
    (get_value(@params[:end_zoom]) - @particle.zoom_x) / @particle.eparams[:life]
  end
  def update_zoom
    @particle.zoom_x += @particle.eparams[:zoom_delta]
    @particle.zoom_y += @particle.eparams[:zoom_delta]
  end
  #--------------------------------------------------------------------------
  # ● 其它初值与每次更新
  #--------------------------------------------------------------------------
  def init_others
  end
  def update_others
  end
end

#==============================================================================
# ■ 粒子模板 - 发射类 - 单点引力场
#==============================================================================
class PT_Emitter_Single_Gravity < PT_Emitter
  def init_settings
    super
    @params[:center]  = Vector.new(0, 0) # 引力中心
    @params[:gravity] = 5                # 引力常量
  end
  def update_speed
    super
    dx = @params[:center].x - @particle.x
    dy = @params[:center].y - @particle.y
    dx = rand * 2 - 1 if dx.to_i == 0
    dy = rand * 2 - 1 if dy.to_i == 0
    r = Math.sqrt(dx * dx + dy * dy)
    @particle.eparams[:dir].x += @params[:gravity] * dx * 1.0 / r
    @particle.eparams[:dir].y += @params[:gravity] * dy * 1.0 / r
  end
end

#==============================================================================
# ■ 粒子模板 - 发射类 - 单点斥力场
#==============================================================================
class PT_Emitter_Single_Repulsion < PT_Emitter
  def init_settings
    super
    @params[:center]  = Vector.new(0, 0) # 斥力中心
    @params[:gravity] = 5                # 斥力常量
  end
  def update_speed
    super
    dx = @params[:center].x - @particle.x
    dy = @params[:center].y - @particle.y
    dx = rand * 2 - 1 if dx.to_i == 0
    dy = rand * 2 - 1 if dy.to_i == 0
    r = Math.sqrt(dx * dx + dy * dy)
    @particle.eparams[:dir].x -= @params[:gravity] * dx * 1.0 / r
    @particle.eparams[:dir].y -= @params[:gravity] * dy * 1.0 / r
  end
end

#==============================================================================
# ■ 粒子模板 - 发射类 - 绑定在地图上
#==============================================================================
class PT_Emitter_OnMap < PT_Emitter
  attr_accessor   :flag_no_when_out
  def init_settings
    super
    # 出屏幕后不再生成新粒子？
    @flag_no_when_out  = true 
    #  设置屏幕区域
    @params[:rect_window] = Rect.new(0,0,Graphics.width,Graphics.height)
    # （地图坐标）粒子所处地图格子位置
    #  x,y 为左上角格子位置， w,h 为矩形宽高（地图格子数）（右下角为 x+w-1,y+h-1）
    @params[:pos_map] = Rect.new(0,0,1,1)
    # 先在 :pos_map 划分出的矩形区域中取随机一格，
    # 再利用父类的 :pos_rect 作为更小的随机范围
    @params[:pos_rect] = Rect.new(0,0,32,32)
  end
  def get_total_num
    if @flag_no_when_out
      _x = (@params[:pos_map].x - $game_map.display_x) * 32
      _y = (@params[:pos_map].y - $game_map.display_y) * 32
      _w = @params[:pos_map].width * 32
      _h = @params[:pos_map].height * 32
      return 0 if Rect.new(_x, _y, _w, _h).out?(@params[:rect_window])
    end
    super
  end
  def init_xy
    super
    _x, _y = @params[:pos_map].rand_pos
    @particle.eparams[:pos_map] = Vector.new(_x, _y)
  end
  def update_xy
    _x = (@particle.eparams[:pos_map].x - $game_map.display_x) * 32
    _y = (@particle.eparams[:pos_map].y - $game_map.display_y) * 32
    super
    @particle.x += _x
    @particle.y += _y
  end
end

#==============================================================================
# ■ 粒子模板 - 发射类 - 绑定在玩家脚底
#==============================================================================
class PT_Emitter_OnPlayerFoot < PT_Emitter_OnMap
  attr_accessor  :flag_use_last_xy
  def init_settings
    @flag_use_last_xy = false  # 使用玩家移动前的坐标，若为false，则为当前坐标
    super
    @params[:z] = 0
    @params[:pos_rect] = Rect.new(8, 26, 16, 6)  # 在基础地图格子位置上的偏移值
  end
  def get_total_num
    @params[:total]
  end
  def init_xy
    super
    if @flag_use_last_xy
      @params[:pos_map].x = $game_player.last_x || 0
      @params[:pos_map].y = $game_player.last_y || 0
    else
      @params[:pos_map].x = $game_player.x || 0
      @params[:pos_map].y = $game_player.y || 0
    end
  end
end
class Game_Player
  attr_reader :last_x, :last_y
  #--------------------------------------------------------------------------
  # ● 移动一格
  #--------------------------------------------------------------------------
  alias eagle_particle_move_straight move_straight
  def move_straight(*params)
    @last_x = x; @last_y = y # 存储移动前的位置
    eagle_particle_move_straight(*params)
  end
end

#==============================================================================
# ■ 粒子模板 - 发射类 - 单反弹盒
#==============================================================================
class PT_Emitter_ReboundBox < PT_Emitter
  def init_settings
    super
    @params[:rebound_box]  = Rect.new(0, 0, 1, 1) # 反弹盒范围（粒子到边界时反弹）
    @params[:rebound_factor] = -1.0   # 反弹因子，速度的改变因子（乘法）
  end
  def update_speed
    last_dx = @particle.eparams[:pos_offset].x
    last_dy = @particle.eparams[:pos_offset].y
    super
    box = @params[:rebound_box]
    new_x = @particle.eparams[:pos].x + @particle.eparams[:pos_offset].x
    new_y = @particle.eparams[:pos].y + @particle.eparams[:pos_offset].y
    if new_x <= box.x or new_x >= box.x + box.width
      @particle.eparams[:pos_offset].x = last_dx
      @particle.eparams[:dir].x *= @params[:rebound_factor]
    end
    if new_y <= box.y or new_y >= box.y + box.height
      @particle.eparams[:pos_offset].y = last_dy
      @particle.eparams[:dir].y *= @params[:rebound_factor]
    end
  end
end
