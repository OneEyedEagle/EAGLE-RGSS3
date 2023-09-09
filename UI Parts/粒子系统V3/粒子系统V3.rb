#==============================================================================
# ■ 粒子系统V3 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
#==============================================================================
$imported ||= {}
$imported["EAGLE-Particle"] = "3.0.0"
#==============================================================================
# - 2023.4.30.10 重构，方便扩展多样化的模板 
#==============================================================================
# - 本插件新增了一个粒子系统
#------------------------------------------------------------------------------
# 【原理说明】
#
# - 对于想要的粒子特效，需要设置一个它专属的粒子生成模板，
#   再对这个模板进行自动更新，来生成各种各样的粒子精灵
#
#------------------------------------------------------------------------------
# 【1. 设置粒子模板】
#
# - 利用写好的粒子模板类，创建它的实例对象，再设置相关参数
#
=begin

# 创建一个粒子模板的实例
# 注意：该模板需使用【粒子模板-发射类 by老鹰】
f = PT_Emitter.new

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

# 此外，还可以定义一下粒子所显示的视图
f.viewport = nil  # 如果不设置，或者nil，就是全屏幕的默认视口

=end
#
#------------------------------------------------------------------------------
# 【2. 绑定粒子模板】
#
# - 当创建好粒子模板后，还需要将它绑定到全局变量中，方便后续调用。
#    注意：粒子模板不会写入存档！
#
=begin

# 接上
# 将编写好的粒子模板放入全局变量中，此处还需设置它的唯一名称
id = "测试"
PARTICLE.setup(id, f)

=end
#
#  当然，你也可以预先在脚本中写完这些，
#  比如把预设脚本放到 PARTICLE#init 方法中，当游戏启动，预设也完成了。
#
#------------------------------------------------------------------------------
# 【3. 控制粒子模板】
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
# 【4. 后续修改】
#
# - 对于设置好的粒子模板，它并不是写死的，你仍然可以对其进行修改
#
=begin

# 首先获取指定的粒子模板
# 比如获取之前预设好的
f = PARTICLE.templates["测试"]

# 修改方法和最初设置时的一致
# 比如设置粒子总数为 50
f.params[:total] = 50

# 注意，此处为引用赋值，并不需要重新保存写入了

=end
#
#------------------------------------------------------------------------------
# 【高级】
#
# - ParticleTemplate 类的可设置参数：
#   （以下参数一切模板通用）
#
#  .flag_start_once = true/false  →  一次性生成完全部粒子，之后不再生成新的
#  .flag_dispose_bitmap = true/false  → 粒子结束后释放bitmap？
#                  （一般情况多个粒子会共用bitmap，不推荐释放）
#
#  .params[:sprites] = []  → 传入可作为粒子的精灵的数组（不会调用它自身的update）
#                            （正序获取并加入粒子精灵）
# 
#  .params[:z] = 数字      → 粒子的 z 值（若为传入的精灵，则不会改变它原本的z值）
#
# （以下均可为 数字 或 RangeValue 或 VarValue 或 eval后为数字的字符串）
#  .params[:total] = 数字  → 同一时间可显示的粒子的最大数量
#  .params[:new_wait] = 数字  → 生成一波粒子后的等待帧数
#  .params[:new_per_wave] = 数字  → 每次同时生成的粒子数目
#  .params[:update_wait] = 数字  → 粒子每次更新后的等待帧数
#  .params[:life] = 数字     → 粒子的存在时间（帧）
#
#  .params[:eval1] = 字符串  → 粒子生成后执行的方法（可用 cur 代表当前粒子精灵）
#  .params[:eval2] = 字符串  → 粒子结束前执行的方法
#
#==============================================================================

module PARTICLE
  #--------------------------------------------------------------------------
  # ● 初始化（绑定于DataManager.run）
  # 【可重载进行预设粒子模板】
  #--------------------------------------------------------------------------
  def self.init
    @templates = {} # { id => template }
    @particles_fin = []
  end
  #--------------------------------------------------------------------------
  # ● 更新（绑定于Graphics#update）
  #--------------------------------------------------------------------------
  def self.update
    @templates.each { |k, v| v.update if v.update? }
  end
  #--------------------------------------------------------------------------
  # ● 模板处理接口
  #--------------------------------------------------------------------------
  class << self; attr_reader :templates, :particles_fin; end
  #--------------------------------------------------------------------------
  # ● 设置指定id的粒子模板
  #--------------------------------------------------------------------------
  def self.setup(id, template)
    @templates[id] = template
  end
  #--------------------------------------------------------------------------
  # ● 指定id模板开始工作（产生新粒子）/ 暂停工作（不产生新粒子）
  #--------------------------------------------------------------------------
  def self.start(id)
    if @templates[id]
      return if @templates[id].running?
      @templates[id].start
    end
  end
  def self.finish(id)
    @templates[id].finish if @templates[id]
  end
  #--------------------------------------------------------------------------
  # ● 指定id模板还在工作？（可能还有粒子在更新，也可能还在生成新粒子）
  #--------------------------------------------------------------------------
  def self.running?(id)
    return @templates[id].running? if @templates[id]
    return false
  end
  #--------------------------------------------------------------------------
  # ● 指定id模板已完成工作？
  #--------------------------------------------------------------------------
  def self.finish?(id)
    return @templates[id].finish? if @templates[id]
    return true
  end
  #--------------------------------------------------------------------------
  # ● 指定id模板冻结（不再更新）/ 继续更新
  #--------------------------------------------------------------------------
  def self.freeze(id)
    @templates[id].freeze if @templates[id]
  end
  def self.awake(id)
    @templates[id].awake if @templates[id]
  end
  #--------------------------------------------------------------------------
  # ● 指定id模板显示/隐藏
  #--------------------------------------------------------------------------
  def self.show(id)
    @templates[id].show if @templates[id]
  end
  def self.hide(id)
    @templates[id].hide if @templates[id]
  end
  #--------------------------------------------------------------------------
  # ● 指定id模板释放（会首先调用 finish 方法）
  #--------------------------------------------------------------------------
  def self.dispose(id)
    @templates[id].dispose if @templates[id]
  end
  #--------------------------------------------------------------------------
  # ● 指定id模板的全部粒子，应用代码块
  #--------------------------------------------------------------------------
  def self.apply(id) # block
    return if @templates[id].nil?
    return if !block_given?
    @templates[id].particles.each do |s|
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
    PARTICLE.templates.each { |k, v| v.hide }
    eagle_particle_snapshot_for_background
    PARTICLE.templates.each { |k, v| v.show }
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
    PARTICLE.templates.each { |k, v| v.hide }
    eagle_particle_snapshot_for_background
    PARTICLE.templates.each { |k, v| v.show }
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
  # ● 向量减法
  #--------------------------------------------------------------------------
  def -(vector)
    @x -= vector.x; @y -= vector.y
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
# ■ 粒子模板 - 母类
#==============================================================================
class ParticleTemplate
  attr_reader   :particles
  attr_accessor :viewport, :params
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(viewport = nil)
    @viewport = viewport
    @params = {}      # 参数Hash
    @particles = []   # 存储全部更新中的粒子
    @particle = nil   # 当前正在处理的粒子实例
    @active = false   # 是否在生成新粒子？
    @freeze = false   # 是否暂停更新？
    init_template
    init_settings
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    finish
    @particles.each { |t| delete_particle(t) }
    @particles.clear
    @particle = nil
    @viewport = nil
    dispose_settings
  end
  #--------------------------------------------------------------------------
  # ● 开始工作
  #--------------------------------------------------------------------------
  def start
    @active = true
    @freeze = false
  end
  #--------------------------------------------------------------------------
  # ● 在工作？
  #--------------------------------------------------------------------------
  def running?
    @active
  end
  #--------------------------------------------------------------------------
  # ● 结束工作（不再产生新粒子）
  #--------------------------------------------------------------------------
  def finish
    @active = false
  end
  def finish?
    @active == false && @particles.empty?
  end
  #--------------------------------------------------------------------------
  # ● 冻结（停止更新） / 唤醒（继续更新）
  #--------------------------------------------------------------------------
  def freeze
    @freeze = true
  end
  def awake
    @freeze = false
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
  # ● 获取数值
  #--------------------------------------------------------------------------
  def get_value(value)
    return value.v if value.is_a?(RangeValue)
    return value.v if value.is_a?(VarValue)
    return eval(value) if value.is_a?(String)
    return value
  end
  #--------------------------------------------------------------------------
  # ● 执行方法
  #--------------------------------------------------------------------------
  def run_eval(str)
    begin
      cur = @particle
      eval(str.to_s) if str 
    rescue
      p "在执行【粒子系统 by老鹰】中粒子绑定的脚本时发生错误！\n" 
      p $!
    end
  end

  #--------------------------------------------------------------------------
  # ● 初始化模板的参数
  #--------------------------------------------------------------------------
  attr_accessor :flag_start_once, :flag_dispose_bitmap
  def init_template
    @flag_start_once = false          # 一次性生成全部粒子？
    @flag_dispose_bitmap  = false     # 释放位图？
    # 将被用于作为粒子的精灵的数组（在粒子更新期间，不调用它自己的update方法）
    @params[:sprites] = []  
    @params[:total] = 20              # 粒子总数
    @params[:new_wait] = 30           # 生成一波粒子后的等待帧数
    @params[:new_wait_count] = 0      # （占用）粒子生成时等待计数用
    @params[:new_per_wave] = VarValue.new(3, 2)  # 每次生成的粒子数目
    @params[:update_wait]   = 2       # 粒子每次更新后的等待帧数
    @params[:eval1] = ""              # 粒子生成后执行的方法
    @params[:eval2] = ""              # 粒子结束前执行的方法
  end
  #--------------------------------------------------------------------------
  # ● 初始化粒子的动态参数
  #--------------------------------------------------------------------------
  def init_settings
    @params[:life] = VarValue.new(180, 120) # 存在时间（若为负数，则一直存在）
    @params[:z]    = 1    # 粒子的z值
  end
  #--------------------------------------------------------------------------
  # ● 释放粒子的动态参数
  #--------------------------------------------------------------------------
  def dispose_settings
  end
  #--------------------------------------------------------------------------
  # ● 粒子的总数
  #--------------------------------------------------------------------------
  def get_total_num
    get_value(@params[:total]).to_i
  end
  #--------------------------------------------------------------------------
  # ● 每次生成粒子后，等待时间
  #--------------------------------------------------------------------------
  def get_new_wait
    get_value(@params[:new_wait]).to_i
  end
  #--------------------------------------------------------------------------
  # ● 返回每一次生成粒子时需要生成的数目
  #--------------------------------------------------------------------------
  def get_new_num_once
    get_value(@params[:new_per_wave]).to_i
  end
  #--------------------------------------------------------------------------
  # ● 粒子更新一次后的等待时间
  #--------------------------------------------------------------------------
  def get_update_wait
    get_value(@params[:update_wait])
  end

  #--------------------------------------------------------------------------
  # ● 将指定精灵转化为允许粒子模板使用的格式
  #--------------------------------------------------------------------------
  def convert_particle(sprite, ps = {})
    def sprite.eparams 
      @eparams
    end
    def sprite.eparams=(ps)
      @eparams = ps 
    end 
    sprite.eparams = { 
      :life => 0, # 还会存在的时间
      :wait_count => 0, # 更新等待用计数（emitter内使用）
      :reuse => ps[:reuse] || true,  # 是否允许重复使用
    } 
  end
  #--------------------------------------------------------------------------
  # ● 获得一个可用于作为粒子的精灵
  #--------------------------------------------------------------------------
  def get_particle_sprite
    s = nil
    s = @params[:sprites].shift if !@params[:sprites].empty?
    if s 
      convert_particle(s)
      s.eparams[:type_from] = 1
      return s 
    end
    if PARTICLE.particles_fin.empty?
      s = Sprite.new 
    else
      s = PARTICLE.particles_fin.shift
    end
    convert_particle(s)
    s.eparams[:type_from] = 0
    s
  end
  def particle_from_sprite?(s)
    s.eparams[:type_from] == 1
  end
  #--------------------------------------------------------------------------
  # ● 由粒子模板新增一个粒子
  #--------------------------------------------------------------------------
  def add_particle
    s = get_particle_sprite
    s.viewport = @viewport
    @particle = s
    start_particle
    @particles.push(s)
    run_eval(@params[:eval1])
    @particle = nil
  end
  #--------------------------------------------------------------------------
  # ● 删去一个指定粒子
  #--------------------------------------------------------------------------
  def delete_particle(sprite)
    return if sprite.disposed?
    @particle = sprite
    sprite.viewport = nil
    run_eval(@params[:eval2])
    finish_particle
    @particle = nil
    case sprite.eparams[:type_from]
    when 0 # 来源为由模板生成的精灵
      sprite.opacity = 0
      sprite.bitmap.dispose if @flag_dispose_bitmap && sprite.bitmap 
      sprite.bitmap = nil
    when 1 # 来源为已经存在的精灵
      # 不进行任何处理，但是会从 @particles 中删去
      return
    end
    if sprite.eparams[:reuse] == true
      PARTICLE.particles_fin.push(sprite)
    else 
      sprite.dispose
    end
  end
  def delete_particle?(sprite)
    sprite.eparams[:life] == 0
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    update_old if !@particles.empty?
    update_new if @active
  end
  def update?
    @freeze != true
  end 
  #--------------------------------------------------------------------------
  # ● 更新现有粒子
  #--------------------------------------------------------------------------
  def update_old
    @particles.each do |t|
      # 计算粒子的更新间隔
      next if (t.eparams[:wait_count] += 1) < get_update_wait
      t.eparams[:wait_count] = 0
      @particle = t
      update_particle
    end
    @particles.delete_if { |t| 
      f = delete_particle?(t)
      delete_particle(t) if f
      f
    }
    @particle = nil
  end
  #--------------------------------------------------------------------------
  # ● 生成新粒子（@active为true时才执行，如果不想生成新的了，就调用finish）
  #--------------------------------------------------------------------------
  def update_new
    if @flag_start_once  # 一次性完全生成并暂停
      get_total_num.times { add_particle }
      finish
    end
    if @particles.size < get_total_num &&
      (@params[:new_wait_count] += 1) >= get_new_wait
      @params[:new_wait_count] = 0
      get_new_num_once.times { add_particle }
    end
  end 
  
  #--------------------------------------------------------------------------
  # ● 粒子开始
  # @particle 为当前处理的粒子精灵
  #--------------------------------------------------------------------------
  def start_particle
    init_life
    if particle_from_sprite?(@particle)  # 不改变精灵的z值
    else
      @particle.z = get_value(@params[:z])
    end
  end
  #--------------------------------------------------------------------------
  # ● 粒子更新
  # @particle 为当前处理的粒子精灵
  #--------------------------------------------------------------------------
  def update_particle
    update_life
  end
  #--------------------------------------------------------------------------
  # ● 粒子结束
  # @particle 为当前处理的粒子精灵
  #--------------------------------------------------------------------------
  def finish_particle
  end
  #--------------------------------------------------------------------------
  # ● 生命周期初值与每次更新
  #--------------------------------------------------------------------------
  def init_life
    @particle.eparams[:life] = get_value(@params[:life]).to_i  # 必须为整数
  end
  def update_life
    return if @particle.eparams[:life] <= 0
    @particle.eparams[:life] -= 1  # 生命周期减一
  end
end
