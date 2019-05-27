#==============================================================================
# ■ 简单粒子系统-发散式 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
$imported ||= {}
$imported["EAGLE-Particle"] = true
#==============================================================================
# - 2019.4.3.15
#==============================================================================
# - 本插件新增了一个管理发散式粒子特效的系统
# - 使用流程：
#    1.【可选】继承 Particle_Template类，实现自己的 粒子模板类
#    2. 生成一个 Particle_Template类或是其子类的实例p_t，并设置各种参数
#    3. 通过调用
#         ParticleManager.setup(id, p_t[, vp])
#       将该实例存为id号的可用粒子模板，其中vp为粒子显示的viewport，可省略
#    4. 管理粒子：
#         ParticleManager.start(id)  → 启动id号的粒子模板（开始工作，生成粒子）
#         ParticleManager.finish(id) → 结束id号的粒子模板（不再生成粒子）
#         ParticleManager.freeze(id) → 冻结id号的粒子模板的更新（不再运动）
#         ParticleManager.awake(id)  → 继续id号的粒子模板的更新
#         ParticleManager.show(id)   → 显示id号的粒子模板的全部粒子
#         ParticleManager.hide(id)   → 隐藏id号的粒子模板的全部粒子
#    5. 管理模板：
#         ParticleManager.emitters[id].template → 获取指定id号的粒子模板的实例
#==============================================================================

module ParticleManager
  #--------------------------------------------------------------------------
  # ● 发射器处理接口
  #--------------------------------------------------------------------------
  class << self; attr_reader :emitters; end
  #--------------------------------------------------------------------------
  # ● 初始化（绑定于DataManager.run）
  # 【可重载进行预设粒子模板】
  #--------------------------------------------------------------------------
  def self.init
    @emitters = {} # { id => emitter }
  end
  #--------------------------------------------------------------------------
  # ● 更新（绑定于Graphics#update）
  #--------------------------------------------------------------------------
  def self.update
    @emitters.each { |k, v| v.update }
  end
  #--------------------------------------------------------------------------
  # ● 设置指定id发射器的粒子模板
  #--------------------------------------------------------------------------
  def self.setup(id, template, viewport = nil)
    if @emitters[id]
      @emitters[id].template = template
    else
      @emitters[id] = Particle_Emitter.new(id, template, viewport)
    end
  end
  #--------------------------------------------------------------------------
  # ● 指定id发射器开始工作（产生新粒子）/ 暂停工作（不产生新粒子）
  #--------------------------------------------------------------------------
  def self.start(id)
    @emitters[id].start if @emitters[id]
  end
  def self.finish(id)
    @emitters[id].finish if @emitters[id]
  end
  #--------------------------------------------------------------------------
  # ● 指定id发射器冻结（不再更新）/ 继续更新
  #--------------------------------------------------------------------------
  def self.freeze(id)
    @emitters[id].freeze if @emitters[id]
  end
  def self.awake(id)
    @emitters[id].awake if @emitters[id]
  end
  #--------------------------------------------------------------------------
  # ● 指定id发射器显示/隐藏
  #--------------------------------------------------------------------------
  def self.show(id)
    @emitters[id].show if @emitters[id]
  end
  def self.hide(id)
    @emitters[id].hide if @emitters[id]
  end
end
#==============================================================================
# ■ 绑定
#==============================================================================
class << SceneManager
  alias eagle_particle_run run
  def run
    ParticleManager.init
    eagle_particle_run
  end
  alias eagle_particle_snapshot_for_background snapshot_for_background
  def snapshot_for_background
    ParticleManager.emitters.each { |k, v| v.hide }
    eagle_particle_snapshot_for_background
    ParticleManager.emitters.each { |k, v| v.show }
  end
end
class << Graphics
  alias eagle_particle_update update
  def update
    eagle_particle_update
    ParticleManager.update
  end
end

#==============================================================================
# ■ 向量工具类
#==============================================================================
class Vector # 注意 在互相赋值时 要使用dup方法 否则为指针传递！
  attr_accessor :x, :y
  def initialize(x = 0, y = 0)
    @x = x; @y = y
  end
  def +(vector)
    @x += vector.x; @y += vector.y
    self
  end
  def *(value)
    @x *= value; @y *= value
    self
  end
  #--------------------------------------------------------------------------
  # ● 当前向量终点在rect中？
  #--------------------------------------------------------------------------
  def in_rect?(rect)
    rect.x < x && rect.x+rect.width > x && rect.y < y && rect.y+rect.height > y
  end
end
#==============================================================================
# ■ 粒子发射器类
#==============================================================================
class Particle_Emitter
  attr_accessor :template
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(id, template, viewport = nil)
    @id = id
    @template = template
    @viewport = viewport
    @particles = []   # 存储全部更新中的粒子
    @active = false   # 是否在生成新粒子？
    @freeze = false   # 是否暂停更新？
    @frame_count = 0  # 粒子生成时等待计数用
  end
  #--------------------------------------------------------------------------
  # ● 开始工作（可新绑定一个粒子模板）
  #--------------------------------------------------------------------------
  def start(template = nil)
    @template = template if template
    @active = true
    @freeze = false
  end
  #--------------------------------------------------------------------------
  # ● 结束工作（不再产生新粒子）
  #--------------------------------------------------------------------------
  def finish
    @active = false
  end
  #--------------------------------------------------------------------------
  # ● 冻结（停止更新） / 唤醒（继续更新）
  #--------------------------------------------------------------------------
  def freeze
    @freeze = true
    @active = false
  end
  def awake
    @freeze = false
    @active = true
  end
  #--------------------------------------------------------------------------
  # ● 显示 / 隐藏
  #--------------------------------------------------------------------------
  def show
    @particles.each { |s| s.visible = true }
  end
  def hide
    @particles.each { |s| s.visible = false }
  end
  #--------------------------------------------------------------------------
  # ● 由粒子模板新增一个粒子
  #--------------------------------------------------------------------------
  def add_particle
    t = Sprite_Particle.new(self, @viewport)
    # 将新生成粒子绑定于模板，便于获取和粒子本身有关的参数
    @template.setup(t)
    t.z = @template.z
    t.bitmap = @template.bitmap
    t.ox = t.width / 2
    t.oy = t.height / 2
    t.win_pos_init = @template.xy
    t.pos_init_offset = @template.xy_offset
    # 计算初始方向向量
    t.dir = @template.dir
    # 计算实际速度
    t.dir *= @template.speed
    # 计算生命周期
    t.life  = @template.life
    # 计算初始颜色
    c = @template.start_color
    t.color = c
    e = @template.end_color
    # 计算颜色差值
    d = Color.new(0,0,0,0)
    d.red   = (c.red - e.red) / t.life
    d.green = (c.green - e.green) / t.life
    d.blue  = (c.blue - e.blue) / t.life
    d.alpha = (c.alpha - e.alpha) / t.life
    t.color_delta = d
    # 计算透明度
    t.opacity   = @template.start_opa
    t.opa_delta = (@template.end_opa - t.opacity) / t.life
    # 计算初始角度
    t.angle = @template.angle_init
    # 计算每帧旋转度数
    t.angle_delta = @template.angle
    # 计算缩放值
    t.zoom_x = t.zoom_y = @template.start_zoom
    t.zoom_delta = (@template.end_zoom - t.zoom_x) / t.life
    # 预更新并加入更新粒子池
    t.update
    @particles.push(t)
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    return if @freeze
    # 对于一次性的，完全生成并暂停
    if @active && @template.for_once
      @template.total.times { add_particle }
      finish
    end
    if @active && @particles.size < @template.total &&
      (@frame_count += 1) >= @template.new_wait
      @frame_count = 0
      @template.new_particles_count.times { add_particle }
    end
    @particles.each do |t|
      next t.dispose if t.life <= 0
      # 计算粒子的更新间隔
      next if (t.wait_count += 1) < @template.par_wait
      t.wait_count = 0
      t.update
    end
    @particles.delete_if { |t| t.disposed? }
  end
end
#==============================================================================
# ■ 单个粒子精灵
#==============================================================================
class Sprite_Particle < Sprite
  attr_accessor :win_pos_init
  attr_accessor :pos_init_offset
  attr_accessor :move_offset
  attr_accessor :map_grid_init
  attr_accessor :dir
  attr_accessor :life
  attr_accessor :color_delta, :opa_delta, :angle_delta, :zoom_delta
  attr_accessor :wait_count
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(emitter, viewport = nil)
    super(viewport)
    @emitter  = emitter
    @win_pos_init  = Vector.new   # （窗口）基础显示位置
    @map_grid_init = Vector.new   # （地图格子）基础所处位置
    @pos_init_offset = Vector.new # 在基础显示位置上的偏移值
    @move_offset   = Vector.new   # 移动中所产生的偏移值
    @dir      = Vector.new   # x和y方向上的速度
    @life     = 0            # 还会存在的时间
    @color_delta = Color.new(0,0,0) # 颜色变更值
    @opa_delta   = 0     # 透明度变更值
    @angle_delta = 0     # 旋转角度变更值
    @zoom_delta  = 0.0   # 缩放的变更值
    @wait_count  = 0     # 更新等待用计数（emitter内使用）
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
    # 将当前粒子绑定于模板，便于获取和粒子本身有关的参数
    @emitter.template.setup(self)
    # 计算新地址
    self.x = @win_pos_init.x + @pos_init_offset.x + @move_offset.x
    self.y = @win_pos_init.y + @pos_init_offset.y + @move_offset.y
    @move_offset += @dir
    # 应用全局力 计算新速度
    g = @emitter.template.global_force
    @dir += g
    # 计算新颜色
    self.color.red   += @color_delta.red
    self.color.green += @color_delta.green
    self.color.blue  += @color_delta.blue
    self.color.alpha += @color_delta.alpha
    # 计算透明度
    self.opacity += @opa_delta
    # 计算缩放度
    self.zoom_x += @zoom_delta
    self.zoom_y += @zoom_delta
    # 计算角度
    self.angle += @angle_delta
    # 生命周期减一
    @life -= 1
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    self.bitmap.dispose if @emitter.template.bitmap_dispose
    super
  end
end
#==============================================================================
# ■ 粒子模板类
#==============================================================================
class Particle_Template
  attr_accessor   :bitmaps
  attr_accessor   :global_force
  attr_accessor   :pos_rect, :z, :par_wait, :new_wait
  attr_accessor   :angle_init, :angle_init_var
  attr_accessor   :theta, :theta_var
  attr_accessor   :speed, :speed_var
  attr_accessor   :life,  :life_var
  attr_accessor   :total
  attr_accessor   :per_frame, :per_frame_var
  attr_accessor   :start_color, :start_color_var
  attr_accessor   :end_color, :end_color_var
  attr_accessor   :start_opa, :start_opa_var
  attr_accessor   :end_opa, :end_opa_var
  attr_accessor   :angle, :angle_var
  attr_accessor   :start_zoom, :start_zoom_var
  attr_accessor   :end_zoom, :end_zoom_var

  attr_accessor   :for_once, :bitmap_dispose
  #--------------------------------------------------------------------------
  # ● 初始化全部可调参数的默认值
  #  便于子类继承后直接修改参数值
  #--------------------------------------------------------------------------
  def initialize
    @particle = nil    # 当前正在处理的粒子实例
    # 参数均留出接口 在初始化后可以调整
    # 后缀为 _var 的变量均为在基础值上的左右偏移量
    @bitmaps         = []                 # 位图对象数组
    @global_force    = Vector.new(0,0)    # 作用力（加速度）Vector
    @pos_rect        = Rect.new(0,0,0,0)  # 粒子生成区域（窗口）
    @z               = 1    # 粒子的z值
    @par_wait        = 2    # 粒子的更新间隔
    @theta           = 0    # 初速度方向（角度）
    @theta_var       = 0
    @speed           = 0    # 初速度值（标量）
    @speed_var       = 0
    @life            = 180  # 存在时间
    @life_var        = 120
    @total           = 20   # 粒子总数限制
    @new_wait        = 30   # 生成一波粒子后等待间隔的帧数
    @per_frame       = 3    # 每个间隔生成粒子数目
    @per_frame_var   = 2
    @start_color     = Color.new(255,255,255,0) # 开始时颜色
    @start_color_var = Color.new(0,0,0,0)
    @end_color       = Color.new(255,255,255,0) # 结束时颜色
    @end_color_var   = Color.new(0,0,0,0)
    @start_opa       = 255  # 开始时透明度
    @start_opa_var   = 0
    @end_opa         = 0    # 结束时透明度
    @end_opa_var     = 0
    @angle_init      = 0    # 开始时角度
    @angle_init_var  = 0
    @angle           = 0    # 每一次更新时的旋转角度
    @angle_var       = 0
    @start_zoom      = 1.00 # 开始时的缩放值
    @start_zoom_var  = 0.0
    @end_zoom        = 1.00 # 结束时的缩放值
    @end_zoom_var    = 0.0

    # 特殊功能参数
    @for_once        = false # 一次性启动？
    @bitmap_dispose  = false # 释放位图？
  end
  #--------------------------------------------------------------------------
  # ● 计算抖动后获得一个范围内的随机值
  #--------------------------------------------------------------------------
  def calc_with_var(value, variation)
    value + (rand * 2 - 1) * variation
  end
  #--------------------------------------------------------------------------
  # ● 在调用下列方法前必须先设置当前粒子
  #--------------------------------------------------------------------------
  def setup(particle)
    @particle = particle
  end
  #--------------------------------------------------------------------------
  # ● 返回全局作用力（Vector）
  #--------------------------------------------------------------------------
  def global_force
    @global_force
  end
  #--------------------------------------------------------------------------
  # ● 返回一个随机的位图对象
  #--------------------------------------------------------------------------
  def bitmap
    b = @bitmaps[ rand(@bitmaps.size) ]
    return b if b
    return Cache.empty_bitmap
  end
  #--------------------------------------------------------------------------
  # ● 返回区域的左上角作为粒子基础位置（Vector）
  #--------------------------------------------------------------------------
  def xy
    Vector.new(@pos_rect.x, @pos_rect.y)
  end
  #--------------------------------------------------------------------------
  # ● 返回区域中的一个随机点作为粒子初始时offset位置（Vector）
  #--------------------------------------------------------------------------
  def xy_offset
    Vector.new(rand(@pos_rect.width), rand(@pos_rect.height))
  end
  #--------------------------------------------------------------------------
  # ● 返回一个由随机初始角度得出的初始移动方向向量（Vector）
  #--------------------------------------------------------------------------
  def dir
    theta = calc_with_var(@theta, @theta_var)
    x = Math.cos(theta * Math::PI / 180.0)
    y = Math.sin(theta * Math::PI / 180.0)
    Vector.new(x, y)
  end
  #--------------------------------------------------------------------------
  # ● 返回随机的初始速度（int标量）
  #--------------------------------------------------------------------------
  def speed
    calc_with_var(@speed, @speed_var)
  end
  #--------------------------------------------------------------------------
  # ● 返回每一次生成粒子时需要生成的数目
  #--------------------------------------------------------------------------
  def new_particles_count
    calc_with_var(@per_frame, @per_frame_var).to_i
  end
  #--------------------------------------------------------------------------
  # ● 返回随机的粒子存在时间
  #--------------------------------------------------------------------------
  def life
    calc_with_var(@life, @life_var)
  end
  #--------------------------------------------------------------------------
  # ● 返回随机的粒子初始颜色
  #--------------------------------------------------------------------------
  def start_color
    r = calc_with_var(@start_color.red, @start_color_var.red)
    g = calc_with_var(@start_color.green, @start_color_var.green)
    b = calc_with_var(@start_color.blue, @start_color_var.blue)
    a = calc_with_var(@start_color.alpha, @start_color_var.alpha)
    Color.new(r, g, b, a)
  end
  #--------------------------------------------------------------------------
  # ● 返回随机的粒子最终颜色
  #--------------------------------------------------------------------------
  def end_color
    r = calc_with_var(@end_color.red, @end_color_var.red)
    g = calc_with_var(@end_color.green, @end_color_var.green)
    b = calc_with_var(@end_color.blue, @end_color_var.blue)
    a = calc_with_var(@start_color.alpha, @start_color_var.alpha)
    Color.new(r, g, b, a)
  end
  #--------------------------------------------------------------------------
  # ● 返回随机的粒子初始透明度
  #--------------------------------------------------------------------------
  def start_opa
    calc_with_var(@start_opa, @start_opa_var)
  end
  #--------------------------------------------------------------------------
  # ● 返回随机的粒子最终透明度
  #--------------------------------------------------------------------------
  def end_opa
    calc_with_var(@end_opa, @end_opa_var)
  end
  #--------------------------------------------------------------------------
  # ● 返回初始时的角度
  #--------------------------------------------------------------------------
  def angle_init
    calc_with_var(@angle_init, @angle_init_var)
  end
  #--------------------------------------------------------------------------
  # ● 返回初始预设的每次更新的旋转角度
  #--------------------------------------------------------------------------
  def angle
    calc_with_var(@angle, @angle_var)
  end
  #--------------------------------------------------------------------------
  # ● 返回随机的粒子开始时缩放值
  #--------------------------------------------------------------------------
  def start_zoom
    calc_with_var(@start_zoom, @start_zoom_var)
  end
  #--------------------------------------------------------------------------
  # ● 返回随机的粒子结束时缩放值
  #--------------------------------------------------------------------------
  def end_zoom
    calc_with_var(@end_zoom, @end_zoom_var)
  end
end
