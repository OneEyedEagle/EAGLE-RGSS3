#==============================================================================
# ■ 粒子发射器V2 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
$imported ||= {}
$imported["EAGLE-Particle"] = true
#==============================================================================
# - 2022.1.17.22 修复F12崩溃的BUG
#==============================================================================
# - 本插件新增了一个发射粒子的系统
#------------------------------------------------------------------------------
# 【原理说明】
#
# - 对于想要的粒子特效，需要设置一个它专属的粒子生成模板，
#   再把这个模板放入一个生成器中，进行自动更新与生成
#
#------------------------------------------------------------------------------
# 【设置粒子模板】
#
# - 利用默认的粒子模板类 ParticleTemplate ，创建它的实例对象，再设置相关参数
#
=begin

# 创建一个粒子模板的实例
f = ParticleTemplate.new

# 依据 init_settings 方法里罗列的相关参数，进行自己的设计
#  比如预设：屏幕上随机出现红色小像素块

# 先定义可以用的位图，注意，全部粒子共用！
b = Bitmap.new(3, 3)
b.fill_rect(b.rect, Color.new(255,0,0,255))
f.params[:bitmaps].push(b)  # 可以传入多个，粒子会随机选一个

# 然后定义出现位置，会取这个矩形区域内的随机点
f.params[:pos_rect] = Rect.new(0, 0, Graphics.width, Graphics.height)

# 再定义粒子怎么运动
#  定义初始的运动，此处角度为-360~360度，速度为 1~3
f.params[:theta] = VarValue.new(0, 360) # 初速度方向（角度）
f.params[:speed] = VarValue.new(2, 1) # 初速度值（标量）

# VarValue 是本插件新增的一个工具类，用于生成一个随机数
# 比如 VarValue.new(1, 5) 调用它的 v 方法时，会返回 1-5 ~ 1+5 之间的一个随机小数

# 最后定义粒子的存在时间，单位为帧，此处为 3s ~ 7s
f.parmas[:life] = VarValue.new(300, 120)

=end
#
#------------------------------------------------------------------------------
# 【绑定粒子模板】
#
# - 当创建好粒子模板后，还需要将它绑定到全局变量中，方便后续调用。
#    注意：粒子模板不会写入存档！
#
=begin

# 接上
# 将编写好的粒子模板放入全局变量中
# 此处还需要设置它的唯一名称，还可以设置它的viewport
id = "测试"
vp = nil  # 如果不传入，或者传入nil，就是全屏幕的默认视口
PARTICLE.setup(id, f, vp)

=end
#
#  当然，你也可以预先在脚本中写完这些，只要最后写入了PARTICLE模块即可。
#  在本脚本最后，就把这个模板放到了 PARTICLE#init 方法中，当游戏开启时，预设也完成了。
#
#------------------------------------------------------------------------------
# 【控制粒子模板】
#
# - 当绑定好粒子模板，就可以使用简单的脚本指令对其进行控制了。
#
=begin

# 启动指定的粒子模板（开始工作，生成粒子）
PARTICLE.start("测试")

# 冻结粒子模板（粒子不再运动，不生成新的）
PARTICLE.freeze("测试")
# 重新激活粒子模板（继续生成）
PARTICLE.awake("测试")

# 显示粒子模板的全部粒子
PARTICLE.show("测试")
# 隐藏粒子模板的全部粒子
PARTICLE.hide("测试")

# 结束粒子模板（不再生成新的粒子，旧粒子继续更新）
PARTICLE.finish("测试")

# 完全结束（先调用finish，再强制清空全部粒子）
PARTICLE.dispose("测试")


#【高级】对全部粒子精灵应用代码块
#  比如对 "测试" 中的全部精灵，将其z值设置为 300
PARTICLE.apply("测试") { |s| s.z = 300 }

=end
#
#------------------------------------------------------------------------------
# 【修改】
#
# - 当预设好粒子模板后，它并不是写死的，你也可以对其进行修改
#
=begin

# 首先获取指定的粒子模板
# 比如获取之前预设的
f = PARTICLE.emitters["测试"].template

# 修改方法和最初设置时的一致
# 比如设置粒子总数为 50
f.params[:total] = 50

# 注意，这个为引用赋值，并不需要重新保存写入

=end
#
#==============================================================================

module PARTICLE
  #--------------------------------------------------------------------------
  # ● 初始化（绑定于DataManager.run）
  # 【可重载进行预设粒子模板】
  #--------------------------------------------------------------------------
  def self.init
    @emitters = {} # { id => emitter }
    Particle_Emitter.reset
  end
  #--------------------------------------------------------------------------
  # ● 更新（绑定于Graphics#update）
  #--------------------------------------------------------------------------
  def self.update
    @emitters.each { |k, v| v.update }
  end
  #--------------------------------------------------------------------------
  # ● 发射器处理接口
  #--------------------------------------------------------------------------
  class << self; attr_reader :emitters; end
  #--------------------------------------------------------------------------
  # ● 设置指定id发射器的粒子模板
  #--------------------------------------------------------------------------
  def self.setup(id, template, viewport = nil)
    if @emitters[id]
      @emitters[id].template = template
      @emitters[id].viewport = viewport if viewport
    else
      @emitters[id] = Particle_Emitter.new(id, template, viewport)
    end
  end
  #--------------------------------------------------------------------------
  # ● 指定id发射器开始工作（产生新粒子）/ 暂停工作（不产生新粒子）
  #--------------------------------------------------------------------------
  def self.start(id)
    if @emitters[id]
      return if @emitters[id].running?
      @emitters[id].start
    end
  end
  def self.finish(id)
    @emitters[id].finish if @emitters[id]
  end
  #--------------------------------------------------------------------------
  # ● 指定id发射器还在工作？（可能还有粒子在更新，也可能还在生成新粒子）
  #--------------------------------------------------------------------------
  def self.running?(id)
    return @emitters[id].running? if @emitters[id]
    return false
  end
  #--------------------------------------------------------------------------
  # ● 指定id发射器已完成工作？
  #--------------------------------------------------------------------------
  def self.finish?(id)
    return @emitters[id].finish? if @emitters[id]
    return true
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
  #--------------------------------------------------------------------------
  # ● 指定id发射器释放（会首先调用 finish 方法）
  #--------------------------------------------------------------------------
  def self.dispose(id)
    @emitters[id].dispose if @emitters[id]
  end
  #--------------------------------------------------------------------------
  # ● 指定id发射器的全部粒子，应用代码块
  #--------------------------------------------------------------------------
  def self.apply(id) # block
    return if @emitters[id].nil?
    return if !block_given?
    @emitters[id].particles.each do |s|
      yield s
    end
  end
end
#=============================================================================
# ■ 绑定
#=============================================================================
if RUBY_VERSION[0..2] == "1.8"  # 兼容VX
#--------------------------------------------------------------------------
# ● VX初始化
#--------------------------------------------------------------------------
PARTICLE.init
class Scene_Base
  #--------------------------------------------------------------------------
  # ● VX截图隐藏
  #--------------------------------------------------------------------------
  alias eagle_particle_snapshot_for_background snapshot_for_background
  def snapshot_for_background
    PARTICLE.emitters.each { |k, v| v.hide }
    eagle_particle_snapshot_for_background
    PARTICLE.emitters.each { |k, v| v.show }
  end
end
else  # VA
#--------------------------------------------------------------------------
# ● VA初始化
#--------------------------------------------------------------------------
class << SceneManager
  alias eagle_particle_run run
  def run
    PARTICLE.init
    eagle_particle_run
  end
  #--------------------------------------------------------------------------
  # ● VA截图隐藏
  #--------------------------------------------------------------------------
  alias eagle_particle_snapshot_for_background snapshot_for_background
  def snapshot_for_background
    PARTICLE.emitters.each { |k, v| v.hide }
    eagle_particle_snapshot_for_background
    PARTICLE.emitters.each { |k, v| v.show }
  end
end
end  # END OF VX/VA
#==============================================================================
# ■ Graphics
#==============================================================================
class << Graphics
  alias eagle_particle_update update
  def update
    eagle_particle_update
    PARTICLE.update
  end
end

#==============================================================================
# ■ 粒子发射器类
#==============================================================================
class Particle_Emitter
  attr_accessor :template, :viewport
  attr_reader   :particles
  #--------------------------------------------------------------------------
  # ● 防止F12出错
  #--------------------------------------------------------------------------
  @@particles_fin = []  # 存储已经结束更新的粒子
  def self.reset
    @@particles_fin = []
  end
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
    @template.start
  end
  #--------------------------------------------------------------------------
  # ● 在工作？
  #--------------------------------------------------------------------------
  def running?
    @active || !@particles.empty?
  end
  #--------------------------------------------------------------------------
  # ● 结束工作（不再产生新粒子）
  #--------------------------------------------------------------------------
  def finish
    @active = false
    @template.finish
  end
  def finish?
    @active == false && @particles.empty?
  end
  #--------------------------------------------------------------------------
  # ● 冻结（停止更新） / 唤醒（继续更新）
  #--------------------------------------------------------------------------
  def freeze
    @freeze = true
    @template.freeze
  end
  def awake
    @freeze = false
    @template.awake
  end
  #--------------------------------------------------------------------------
  # ● 显示 / 隐藏
  #--------------------------------------------------------------------------
  def show
    @particles.each { |s| s.visible = true }
    @template.show
  end
  def hide
    @particles.each { |s| s.visible = false }
    @template.hide
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    finish
    @particles.each { |s| s.finish; @@particles_fin.push(s) }
    @particles.clear
    @template.dispose
    @viewport = nil
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    return if @freeze
    # 对于一次性的，完全生成并暂停
    if @active && @template.flag_start_once
      @template.get_total_num.times { add_particle }
      finish
    end
    if @active && @particles.size < @template.get_total_num &&
      (@frame_count += 1) >= @template.get_new_wait
      @frame_count = 0
      @template.get_new_num_once.times { add_particle }
    end
    @particles.each do |t|
      if t.fin?
        @@particles_fin.push(t)
        next t.finish
      end
      # 计算粒子的更新间隔
      next if (t.wait_count += 1) < @template.get_update_wait
      t.wait_count = 0
      t.update
    end
    @particles.delete_if { |t| t.fin? }
    @template.update(@particles)
  end
  #--------------------------------------------------------------------------
  # ● 由粒子模板新增一个粒子
  #--------------------------------------------------------------------------
  def add_particle
    if @@particles_fin.empty?
      s = Sprite_Particle.new(self)
    else
      s = @@particles_fin.shift
      s.start(self)
    end
    @particles.push(s) if s
  end
end

#==============================================================================
# ■ 单个粒子精灵
#==============================================================================
class Sprite_Particle < Sprite
  attr_reader   :params
  attr_accessor :wait_count
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(emitter)
    super(emitter.viewport)
    start(emitter)
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    self.viewport = nil
    self.bitmap.dispose if self.bitmap
    super
  end
  #--------------------------------------------------------------------------
  # ● 启动
  #--------------------------------------------------------------------------
  def start(emitter)
    self.viewport = emitter.viewport
    @emitter  = emitter
    @params   = { :life => 0 } # 还会存在的时间
    @wait_count = 0  # 更新等待用计数（emitter内使用）
    @emitter.template.start_particle(self)
    update
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
    @emitter.template.update_particle(self)
  end
  #--------------------------------------------------------------------------
  # ● 结束？
  #--------------------------------------------------------------------------
  def fin?
    @params[:life] == 0
  end
  #--------------------------------------------------------------------------
  # ● 结束
  #--------------------------------------------------------------------------
  def finish
    @emitter.template.finish_particle(self)
  end
end

#==============================================================================
# ■ 矩形
#==============================================================================
class Rect
  #--------------------------------------------------------------------------
  # ● 当前矩形在rect1的外部？
  #--------------------------------------------------------------------------
  def out?(rect1)
    return true if self.x > rect1.x + rect1.width ||
      self.x + self.width < rect1.x ||
      self.y > rect1.y + rect1.height ||
      self.y + self.height < rect1.y
    return false
  end
  #--------------------------------------------------------------------------
  # ● 当前矩形与rect1相交？
  #--------------------------------------------------------------------------
  def intersect?(rect1)
    return false if out?(rect1)
    return false if in?(rect1)
    return true
  end
  #--------------------------------------------------------------------------
  # ● 当前矩形在rect1的内部？（完全包围）
  #--------------------------------------------------------------------------
  def in?(rect1)
    if self.x >= rect1.x && self.x + self.width <= rect1.x + rect1.width &&
       self.y >= rect1.y && self.y + self.height <= rect1.y + rect1.height
      return true
    end
    return false
  end
  #--------------------------------------------------------------------------
  # ● 随机取一点
  #--------------------------------------------------------------------------
  def rand_pos
    return x + rand(width), y + rand(height)
  end
end

#==============================================================================
# ■ 二维向量
#==============================================================================
class Vector # 注意 在互相赋值时 要使用dup方法 否则为指针传递！
  attr_accessor :x, :y
  def initialize(x = 0, y = 0)
    @x = x; @y = y
  end
  #--------------------------------------------------------------------------
  # ● 向量加法
  #--------------------------------------------------------------------------
  def +(vector)
    @x += vector.x; @y += vector.y
    self
  end
  #--------------------------------------------------------------------------
  # ● 向量乘以值
  #--------------------------------------------------------------------------
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
# ■ 范围随机量
#==============================================================================
class RangeValue
  attr_writer :v1, :v2
  def initialize(v1, v2)
    @v1 = v1
    @v2 = v2
  end
  #--------------------------------------------------------------------------
  # ● 取值
  #--------------------------------------------------------------------------
  # v1 到 v2 之间的随机小数
  def v
    @v1 + rand * (@v2 - @v1).abs
  end
end

#==============================================================================
# ■ 前后范围随机量
#==============================================================================
class VarValue
  attr_writer :v, :var
  def initialize(v, var=0)
    @v = v
    @var = var
  end
  #--------------------------------------------------------------------------
  # ● 取值
  #--------------------------------------------------------------------------
  # v-var ~ v+var 中的随机小数
  def v
    @v + (rand * 2 - 1) * @var
  end
end

#==============================================================================
# ■ 粒子模板类
#==============================================================================
class ParticleTemplate
  attr_accessor   :params, :flag_start_once, :flag_dispose_bitmap
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize
    @particle = nil    # 当前正在处理的粒子实例
    @params = {}       # 参数Hash
    init_template
    init_settings
  end
  #--------------------------------------------------------------------------
  # ● 初始化模板的参数
  #--------------------------------------------------------------------------
  def init_template
    @flag_start_once = false # 一次性生成全部粒子？
    @flag_dispose_bitmap  = false # 释放位图？
    @params[:total] = 20   # 粒子总数
    # 以下变量均可以传入 VarValue类型 或 数值 或 字符串（会先被eval求值）
    @params[:new_wait] = 30   # 生成一波粒子后的等待帧数
    @params[:new_per_frame] = VarValue.new(3, 2)  # 每次生成的粒子数目
  end
  #--------------------------------------------------------------------------
  # ● 初始化粒子的动态参数
  #--------------------------------------------------------------------------
  def init_settings
    @params[:bitmaps]  = []               # 位图对象数组
    @params[:pos_rect] = Rect.new(0,0,0,0)  # 粒子生成区域（窗口）
    @params[:force]    = Vector.new(0,0)    # 作用力（加速度）Vector
    # 以下变量均可以传入 VarValue类型 或 数值 或 字符串（会先被eval求值）
    @params[:update_wait]   = 2    # 粒子每次更新后的的等待帧数
    @params[:life] = VarValue.new(180, 120) # 存在时间（若为负数，则一直存在）
    @params[:theta] = VarValue.new(0, 0) # 初速度方向（角度）
    @params[:speed] = VarValue.new(0, 0) # 初速度值（标量）
    @params[:start_opa] = VarValue.new(255, 0) # 开始时透明度
    @params[:end_opa] = VarValue.new(0, 0)  # 结束时透明度
    @params[:start_angle] = VarValue.new(0, 0) # 开始时角度
    @params[:angle] = VarValue.new(0, 0) # 每一次更新时的旋转角度
    @params[:start_zoom] = VarValue.new(1.0, 0) # 开始时的缩放值
    @params[:end_zoom] = VarValue.new(1.0, 0) # 结束时的缩放值
    @params[:z]    = 1    # 粒子的z值
  end

  #--------------------------------------------------------------------------
  # ● 发射器调用对应方法时，将调用下述方法
  #--------------------------------------------------------------------------
  def start
  end
  def finish
  end
  def freeze
  end
  def awake
  end
  def show
  end
  def hide
  end
  def dispose
    @params[:bitmaps].each { |b| b.dispose }
    @params[:bitmaps].clear
  end
  #--------------------------------------------------------------------------
  # ● 全部粒子更新完成后，发射器将调用模板的该方法
  # all_particles = [Sprite_Particle, Sprite_Particle...]
  #--------------------------------------------------------------------------
  def update(all_particles)
  end

  #--------------------------------------------------------------------------
  # ● 获取数值
  #--------------------------------------------------------------------------
  def get_value(value)
    return value.v if value.is_a?(RangeValue)
    return value.v if value.is_a?(VarValue)
    return eval(value) if value.is_a?(String)
    return value
  end
  #--------------------------------------------------------------------------
  # ● 粒子的总数
  #--------------------------------------------------------------------------
  def get_total_num
    @params[:total]
  end
  #--------------------------------------------------------------------------
  # ● 每次生成粒子后，等待时间
  #--------------------------------------------------------------------------
  def get_new_wait
    get_value(@params[:new_wait])
  end
  #--------------------------------------------------------------------------
  # ● 返回每一次生成粒子时需要生成的数目
  #--------------------------------------------------------------------------
  def get_new_num_once
    get_value(@params[:new_per_frame]).to_i
  end
  #--------------------------------------------------------------------------
  # ● 粒子更新一次后的等待时间
  #--------------------------------------------------------------------------
  def get_update_wait
    get_value(@params[:update_wait])
  end

  #--------------------------------------------------------------------------
  # ● 粒子开始
  #--------------------------------------------------------------------------
  def start_particle(particle)
    @particle = particle
    init_life
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
  def update_particle(particle)
    @particle = particle
    update_life
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
  def finish_particle(particle)
    @particle = particle
    @particle.bitmap.dispose if @flag_dispose_bitmap
    @particle.bitmap = nil
    @particle.opacity = 0
  end

  #--------------------------------------------------------------------------
  # ● 生命周期初值与每次更新
  #--------------------------------------------------------------------------
  def init_life
    @particle.params[:life] = get_value(@params[:life]).to_i  # 必须为整数
  end
  def update_life
    return if @particle.params[:life] < 0
    @particle.params[:life] -= 1  # 生命周期减一
  end
  #--------------------------------------------------------------------------
  # ● 位图初值与每次更新
  #--------------------------------------------------------------------------
  def init_bitmap
    @particle.bitmap = get_bitmap
    @particle.ox = @particle.width / 2
    @particle.oy = @particle.height / 2
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
    r = @params[:pos_rect]  # 在该矩形内随机一个位置
    v = Vector.new(r.x, r.y) + Vector.new(rand(r.width), rand(r.height))
    # （屏幕坐标）初始显示位置
    @particle.params[:pos] = v
    # 移动中所产生的偏移值
    @particle.params[:pos_offset] = Vector.new
  end
  def update_xy
    @particle.x = @particle.params[:pos].x + @particle.params[:pos_offset].x
    @particle.y = @particle.params[:pos].y + @particle.params[:pos_offset].y
  end
  #--------------------------------------------------------------------------
  # ● 移动速度初值与每次更新
  #--------------------------------------------------------------------------
  def init_speed
    theta = get_value(@params[:theta])
    x = Math.cos(theta * Math::PI / 180.0)
    y = Math.sin(theta * Math::PI / 180.0)
    @particle.params[:dir] = Vector.new(x, y) * get_value(@params[:speed])
  end
  def update_speed
    # 计算下一帧的移动位置
    @particle.params[:pos_offset] += @particle.params[:dir]
    # 计算下一帧的速度
    @particle.params[:dir] += @params[:force]
  end
  #--------------------------------------------------------------------------
  # ● 不透明度初值与每次更新
  #--------------------------------------------------------------------------
  def init_opa
    @particle.opacity = get_value(@params[:start_opa])
    @particle.params[:opa_delta] =
      (@params[:end_opa].v - @particle.opacity) / @particle.params[:life]
  end
  def update_opa
    @particle.opacity += @particle.params[:opa_delta]
  end
  #--------------------------------------------------------------------------
  # ● 角度初值与每次更新
  #--------------------------------------------------------------------------
  def init_angle
    @particle.angle = get_value(@params[:start_angle])
    @particle.params[:angle_delta] = get_value(@params[:angle]) # 每帧旋转度数
  end
  def update_angle
    @particle.angle += @particle.params[:angle_delta]
  end
  #--------------------------------------------------------------------------
  # ● 缩放初值与每次更新
  #--------------------------------------------------------------------------
  def init_zoom
    @particle.zoom_x = @particle.zoom_y = get_value(@params[:start_zoom])
    @particle.params[:zoom_delta] =
    (get_value(@params[:end_zoom]) - @particle.zoom_x) / @particle.params[:life]
  end
  def update_zoom
    @particle.zoom_x += @particle.params[:zoom_delta]
    @particle.zoom_y += @particle.params[:zoom_delta]
  end
  #--------------------------------------------------------------------------
  # ● 其它初值与每次更新
  #--------------------------------------------------------------------------
  def init_others
    @particle.z = get_value(@params[:z])
  end
  def update_others
  end
end

#==============================================================================
# ■ 粒子模板类 - 单点引力场
#==============================================================================
class ParticleTemplate_Single_Gravity < ParticleTemplate
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
    @particle.params[:dir].x += @params[:gravity] * dx * 1.0 / r
    @particle.params[:dir].y += @params[:gravity] * dy * 1.0 / r
  end
end

#==============================================================================
# ■ 粒子模板类 - 绑定在地图上
#==============================================================================
class ParticleTemplate_OnMap < ParticleTemplate
  attr_accessor   :flag_no_when_out
  def init_settings
    super
    @flag_no_when_out  = true   # 出屏幕后不再生成新粒子？
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
    @particle.params[:pos_map] = Vector.new(_x, _y)
  end
  def update_xy
    _x = (@particle.params[:pos_map].x - $game_map.display_x) * 32
    _y = (@particle.params[:pos_map].y - $game_map.display_y) * 32
    super
    @particle.x += _x
    @particle.y += _y
  end
end

#==============================================================================
# ■ 粒子模板类 - 绑定在玩家脚底
#==============================================================================
class ParticleTemplate_OnPlayerFoot < ParticleTemplate_OnMap
  attr_accessor  :flag_use_last_xy
  def init_settings
    @flag_use_last_xy = false  # 使用玩家移动前的坐标，若为false，则为当前坐标
    super
    @params[:z] = 0
    @params[:pos_rect] = Rect.new(8, 26, 16, 6)  # 在基础地图格子位置上的偏移值
  end
  #--------------------------------------------------------------------------
  # ● 粒子的总数
  #--------------------------------------------------------------------------
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
# ■ 粒子模板类 - 坐标位图一一对应
#==============================================================================
class ParticleTemplate_BitmapNoDup < ParticleTemplate
  def init_settings
    super
    @params[:xys] = []  # 坐标集合Vector
    # 注意：需要保证 @xys元素个数 和 @bitmaps元素个数 相同
  end
  #--------------------------------------------------------------------------
  # ● 粒子初始位置
  #--------------------------------------------------------------------------
  def init_xy
    # （屏幕坐标）初始显示位置
    @particle.params[:pos] = @params[:xys].shift
    # 移动中所产生的偏移值
    @particle.params[:pos_offset] = Vector.new
  end
  #--------------------------------------------------------------------------
  # ● 返回一个位图对象
  #--------------------------------------------------------------------------
  def get_bitmap
    return Cache.empty_bitmap if @params[:bitmaps].empty?
    return @params[:bitmaps].shift
  end
end

#==============================================================================
# ■ 粒子模板类 - 单反弹盒
#==============================================================================
class ParticleTemplate_ReboundBox < ParticleTemplate
  def init_settings
    super
    @params[:rebound_box]  = Rect.new(0, 0, 1, 1) # 反弹盒范围（粒子到边界时反弹）
    @params[:rebound_factor] = -1.0   # 反弹因子，速度的改变因子（乘法）
  end
  def update_speed
    last_dx = @particle.params[:pos_offset].x
    last_dy = @particle.params[:pos_offset].y
    super
    box = @params[:rebound_box]
    new_x = @particle.params[:pos].x + @particle.params[:pos_offset].x
    new_y = @particle.params[:pos].y + @particle.params[:pos_offset].y
    if new_x <= box.x or new_x >= box.x + box.width
      @particle.params[:pos_offset].x = last_dx
      @particle.params[:dir].x *= @params[:rebound_factor]
    end
    if new_y <= box.y or new_y >= box.y + box.height
      @particle.params[:pos_offset].y = last_dy
      @particle.params[:dir].y *= @params[:rebound_factor]
    end
  end
end

#==============================================================================
# ■ 在脚本中预设粒子模板
#==============================================================================
class << PARTICLE
  alias eagle_particle_init init
  def init
    eagle_particle_init

    # 预设模板
    #  全屏随机显示红色的细小方块
    f = ParticleTemplate.new
    b = Bitmap.new(3, 3)
    b.fill_rect(b.rect, Color.new(255,0,0,255))
    f.params[:bitmaps].push(b)  # 可以传入多个，粒子会随机选一个
    f.params[:pos_rect] = Rect.new(0, 0, Graphics.width, Graphics.height)
    f.params[:theta] = VarValue.new(0, 360) # 初速度方向（角度）
    f.params[:speed] = VarValue.new(2, 1) # 初速度值（标量）
    f.params[:life] = VarValue.new(300, 120) # 存在时间
    setup("测试", f)  # 这个粒子模板的名称为 "测试"
    #  需要启用时，使用全局脚本 PARTICLE.start("测试")

  end
end
