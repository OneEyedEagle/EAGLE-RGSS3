#==============================================================================
# ■ 粒子模板-归位类 by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【粒子系统V3 by老鹰】与【组件-缓动函数 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-PT-Moveto"] = "3.0.0"
#==============================================================================
# - 2023.4.30.13 重构，方便扩展多样化的模板 
#==============================================================================
# - 本插件新增了使粒子从当前位置向指定位置缓动移动的模板
#------------------------------------------------------------------------------
# 【高级】
#
# - PT_Moveto 类的可设置参数，请见 init_settings 方法中的注释
#
#==============================================================================
class PT_Moveto < ParticleTemplate
  #--------------------------------------------------------------------------
  # ● 初始化粒子的动态参数
  #--------------------------------------------------------------------------
  def init_settings
    super
    # 移动后的坐标数组
    @params[:xys] = []
    # 从 @params[:xys] 中获取一个xy的方式（0随机 1正序 -1倒序）
    @params[:xys_type] = 0
    # 移动后的角度
    @params[:angle] = 0
    # 移动后的不透明度
    @params[:opacity] = 255
    # 移动后的缩放
    @params[:zoom] = 1.0
    # 所使用的缓动函数 
    @params[:move_type] = "easeInSine"
    # 所耗帧数（若为0，则取粒子的:life-1）
    @params[:t] = 0
    # 移动结束时执行脚本
    @params[:eval_pt] = ""
  end
  #--------------------------------------------------------------------------
  # ● 释放粒子的动态参数
  #--------------------------------------------------------------------------
  def dispose_settings
    super
  end
  #--------------------------------------------------------------------------
  # ● 粒子开始
  #--------------------------------------------------------------------------
  def start_particle
    super
    init_xy
    init_move
    init_others
  end
  #--------------------------------------------------------------------------
  # ● 粒子更新
  #--------------------------------------------------------------------------
  def update_particle
    super
    update_xy
    update_move
    update_others
  end
  #--------------------------------------------------------------------------
  # ● 粒子结束
  #--------------------------------------------------------------------------
  def finish_particle
    super
  end

  #--------------------------------------------------------------------------
  # ● 显示位置初值与每次更新
  #--------------------------------------------------------------------------
  def init_xy
    if particle_from_sprite?(@particle)
      v = Vector.new(@particle.x+@particle.ox, @particle.y+@particle.oy)
    else
      r = Rect.new(0,0,Graphics.width,Graphics.height)  # 屏幕内随机位置
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
  # ● 位置终值与每次更新
  #--------------------------------------------------------------------------
  def init_move
    # 获取最终位置
    @params[:xys_backup] = @params[:xys] if @params[:xys_backup] == nil
    @params[:xys] = @params[:xys_backup] if @params[:xys].empty?
    case @params[:xys_type]
    when 0  # 随机
      i = rand(@params[:xys].size)
      xy = @params[:xys][i]
      @params[:xys].delete_at(i)
    when 1  # 正序
      xy = @params[:xys].shift
    when -1 # 倒序
      xy = @params[:xys].pop
    end
    xy = [rand(Graphics.width), rand(Graphics.height)] if xy.nil?
    @particle.eparams[:pos_des] = v2 = Vector.new(xy[0], xy[1])
    
    # 计算位置差值
    v1 = @particle.eparams[:pos]
    @particle.eparams[:pos_d] = Vector.new(v2.x - v1.x, v2.y - v1.y)
    
    # 获取移动时间
    @particle.eparams[:t] = @params[:t]
    @particle.eparams[:t] = @particle.eparams[:life]-1 if @params[:t] == 0
    @particle.eparams[:c] = 0
    
    # 计算其它属性
    @particle.eparams[:angle] = @particle.angle
    @particle.eparams[:angle_des] = @params[:angle]
    @particle.eparams[:angle_d] = @particle.eparams[:angle_des] - @particle.angle
    
    @particle.eparams[:opacity] = @particle.opacity
    @particle.eparams[:opacity_des] = @params[:opacity]
    @particle.eparams[:opacity_d] = @particle.eparams[:opacity_des] - @particle.opacity

    @particle.eparams[:zoom] = @particle.zoom_x
    @particle.eparams[:zoom_des] = @params[:zoom]
    @particle.eparams[:zoom_d] = @particle.eparams[:zoom_des] - @particle.zoom_x
    
    @particle.eparams[:flag_fin] = false
  end 
  def update_move
    return if @particle.eparams[:flag_fin] == true
    return finish_move if @particle.eparams[:c] >= @particle.eparams[:t]
    t = (@particle.eparams[:c]+1) * 1.0 / @particle.eparams[:t]
    v = EasingFuction.call(@params[:move_type], t)
    @particle.eparams[:pos_offset].x = @particle.eparams[:pos_d].x * v
    @particle.eparams[:pos_offset].y = @particle.eparams[:pos_d].y * v
    
    @particle.angle = @particle.eparams[:angle] + @particle.eparams[:angle_d] * v
    @particle.opacity = @particle.eparams[:opacity] + @particle.eparams[:opacity_d] * v
    @particle.zoom_x = @particle.zoom_y = @particle.eparams[:zoom] + @particle.eparams[:zoom_d] * v
    @particle.eparams[:c] += 1
  end
  def finish_move
    return if @particle.eparams[:flag_fin] == true
    @particle.eparams[:flag_fin] = true
    @particle.eparams[:pos].x = @particle.eparams[:pos_des].x
    @particle.eparams[:pos].y = @particle.eparams[:pos_des].y
    @particle.eparams[:pos_offset].x = 0
    @particle.eparams[:pos_offset].y = 0
    @particle.angle = @particle.eparams[:angle_des]
    @particle.opacity = @particle.eparams[:opacity_des]
    @particle.zoom_x = @particle.zoom_y = @particle.eparams[:zoom_des]
    run_eval(@params[:eval_pt])
  end 
  #--------------------------------------------------------------------------
  # ● 其它初值与每次更新
  #--------------------------------------------------------------------------
  def init_others
  end
  def update_others
  end
end 
