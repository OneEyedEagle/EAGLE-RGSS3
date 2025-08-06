#==============================================================================
# ■ 粒子系统V3 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
#==============================================================================
$imported ||= {}
$imported["EAGLE-Particle"] = "3.1.0"
#==============================================================================
# - 2025.6.22.13 重新编写注释，并将粒子模板整合 
#==============================================================================
# - 本插件新增了一个能够随机发射精灵的粒子系统
#------------------------------------------------------------------------------
# 【原理说明】
#
# - 设置粒子生成模板，启用后将自动按照统一的处理方式生成大量精灵
#
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# 【使用步骤】
#
# <1> 设置粒子模板
#
# - 利用写好的粒子模板类，创建模板，并设置参数
#
=begin

# 创建一个发射粒子的模板
# 假设这个模板的作用是：在屏幕上随机位置出现随机移动的红色小像素块
f = PT_Emitter.new

# 先定义位图（注意：这个位图将由全部粒子共用！别释放了！）
b = Bitmap.new(3, 3)
b.fill_rect(b.rect, Color.new(255,0,0,255))
# 可以传入多个位图，生成新粒子时会随机从中选一个位图
f.params[:bitmaps].push(b)

# 然后定义出现位置，粒子将从这个矩形区域内随机选择一个点作为初始位置
f.params[:pos_rect] = Rect.new(0, 0, Graphics.width, Graphics.height)

# 再定义粒子的运动方式
#  定义初速度方向（角度）
f.params[:theta] = VarValue.new(0, 360)
#  定义初速度值
f.params[:speed] = VarValue.new(2, 1)

# VarValue 是本插件新增的一个工具类，用于从一个范围内生成一个随机数
# 比如 VarValue.new(1, 5) 调用它的 v 方法时，会返回 -4 ~ 6 之间的一个随机小数

# 最后定义粒子的存在时间，单位为帧，此处为 3s ~ 7s
f.parmas[:life] = VarValue.new(300, 120)

# 此外，还可以定义一下粒子所显示的视图
f.viewport = nil  # 如果不设置，或者nil，就是全屏幕的默认视口

=end
#
#-------------------------------------------------------
# <2> 绑定粒子模板
#
# - 当设置好你的粒子模板后，还需要将它进行绑定，这样它才能自动更新。
#   注意：粒子模板不会被保存到存档里！
#
=begin

# 绑定写好的粒子模板，同时设置它的名称，这里的模板名称是 "测试"
PARTICLE.setup("测试", f)

=end
#
# - 你也可以预先在脚本中写完这些，
#   比如把以上<1><2>中的预设脚本放到 PARTICLE#init 方法中，
#   这样当游戏启动/读档完成，预设也就完成了。
#
#-------------------------------------------------------
# <3> 控制粒子模板
#
# - 随后，你可以使用简单的脚本指令对这个模板进行控制，事件脚本中也可以使用。
#
=begin

# 启动指定的粒子模板（开始生成粒子）
PARTICLE.start("测试")

# 冻结粒子模板（已有粒子不再运动，同时不再生成新粒子）
PARTICLE.freeze("测试")
# 重新激活粒子模板（继续运动和生成新粒子）
PARTICLE.awake("测试")

# 显示全部粒子
PARTICLE.show("测试")
# 隐藏全部粒子
PARTICLE.hide("测试")

# 粒子模板结束工作（已有粒子继续更新，但不再生成新粒子）
PARTICLE.finish("测试")

# 强制结束工作（先调用finish，再强制清除全部粒子）
PARTICLE.dispose("测试")

# 对模板中的全部粒子应用代码块
#  比如将 "测试" 中的全部精灵z值设置为 300
PARTICLE.apply("测试") { |s| s.z = 300 }

=end
#
#-------------------------------------------------------
# <4> 动态修改粒子模板
#
# - 对于预先设置好的粒子模板，你仍然可以对其进行动态修改，并立刻影响到粒子的更新上
#
=begin

# 获取粒子模板，比如获取之前预设好的
f = PARTICLE.templates["测试"]

# 修改方法和预设时一致，比如修改粒子总数为 50
f.params[:total] = 50

# 注意：不需要重新绑定或启用了，这些更改后的设置将自动生效。

=end
#
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# 【粒子模板的可配置参数一览】
#
#  具体请见各粒子模板类的 init_template 方法 和 init_settings 方法。
#
#-------------------------------------------------------
# <1> 粒子模板 - 母版
#
#  所有粒子模板都继承自本类，因此，只要是粒子模板，这些都可以进行自定义。
#
=begin

#【是否一次性生成完成】
# → 若为 true 则一次性生成，之后结束工作，若想再次启用，请再调用 PARTICLE.start 。
# → 一般情况下，需要模板持续不断生成粒子，故默认 false 持续生成。
f.flag_start_once = false

#【是否自动释放位图】
# → 若为 true 则粒子生命结束时将释放它的位图。
# → 多个粒子可能共用位图，如果释放那粒子都不显示了，故默认 false 不自动释放。
f.flag_dispose_bitmap = false

#【将已有精灵用作粒子】
# → 如果你已经有了一些精灵（比如创建了一些图片精灵，想让它们四散），
#    那么可以将它们放入这个数组中，模板将优先从这里按正位顺序取出精灵进行粒子处理。
# → 注意：粒子处理过程中，不会调用它原本的 update 方法。
# → 注意：粒子处理结束后，不会自动释放它的位图或它本身，仅将它们移出粒子处理。
#      如果你想释放，请自己在 eval2 中添加 "cur.bitmap.dispose; cur.dispose"。
f.params[:sprites] = []

#【将已有位图作为粒子的位图】
# → 模板自己生成的粒子将从这个数组中随机选择一个作为位图。
# → 注意：全部粒子共用同一个位图，请不要中途释放它，否则都会缺少位图。
# → 如果是来自 params[:sprites] 的粒子，则不会改变它原本的位图。
f.params[:bitmaps] = []

#【设置粒子的初始屏幕位置】
# → 模板生成的粒子将在这个矩形区域内随机选择一个点作为粒子的初始位置。
# → 该坐标为全屏坐标，请自行处理视图等要素。
# → 如果是来自 params[:sprites] 的粒子，则不会改变它原本的位置。
f.params[:pos_rect] = Rect.new(0,0,0,0)

#【设置粒子的初始地图位置】
# → 如果你想将粒子放到地图上，随地图移动，那么需要设置这个参数
# → 该参数须传入 Rect 类（二维矩形），单位为地图网格，
#    其中 x,y 为左上角格子，w,h 为宽高，右下角格子为 (x+w-1,y+h-1)。
# → 默认传入 nil ，不绑定到地图上。
# → 若设置了该项，则 params[:pos_rect] 自动失效。
# → 如果是来自 params[:sprites] 的粒子，则该设置无效。
f.params[:pos_map] = nil # Rect.new(0,0,1,1)
#【设置地图格中的粒子生成区域】
# → 设置了 params[:pos_map] 时才生效
# → 首先在 :pos_map 划分出的矩形地图区域中随机取一格，
#    再用 :pos_grid 从该地图格中获取一小块范围，粒子将在这个小范围内生成。
# → 单位为 像素，默认取整个地图格子。
f.params[:pos_grid] = Rect.new(0,0,32,32)
#【是否在屏幕外时不更新】
# → 设置了 params[:pos_map] 时才生效
# → 出于性能考虑，当模板因为地图移动而位于屏幕区域外时，默认 true 不再生成新粒子。
f.flag_no_when_out = true
#【设置屏幕区域】
# → 设置了 params[:pos_map] 时才生效
# → 默认为游戏全屏，你可以依据自己的显示区域调整。
f.params[:rect_window] = Rect.new(0,0,Graphics.width,Graphics.height)

#【是否显示在玩家脚底位置】
# → 如果你想将粒子显示在玩家脚底位置，请传入 true 。
# → 若为 true，则 params[:pos_rect] 和 params[:pos_map] 均会自动失效。
# → 如果是来自 params[:sprites] 的粒子，则该设置无效。
f.flag_under_player = false
#【是否使用玩家移动前的位置】
# → 如果你想制作玩家移动后，在新位置生成粒子，则设置为 false 。
#    如果你想制作玩家移动后，在旧位置生成粒子，则设置为 true 。
f.flag_use_last_xy = false
#【设置玩家所在格子中的粒子生成区域】
# → 设置了 flag_under_player 时才生效。
# → 单位为 像素，默认为脚底区域。
f.params[:pos_player] = Rect.new(8, 26, 16, 6)

#【设置粒子的初始z值】
# → 在粒子开始运动时，将设置它的z值，运动期间不会重复设置。
# → 如果是来自 params[:sprites] 的粒子，则不会改变它原本的z值。
f.params[:z] = 数字
                          
#【设置在粒子生成后执行一次的代码】
# → 可以用 cur 代表当前粒子精灵
f.params[:eval1] = 字符串

#【设置在粒子结束前执行一次的代码】
# → 可以用 cur 代表当前粒子精灵
f.params[:eval2] = 字符串

（以下均可传入 数字 或 RangeValue 或 VarValue 或 eval后输出数字的字符串）

#【设置模板在同一时间最多存在的粒子数量】
# → 当数量不足时，会继续生成，当数量超过时，将暂停生成，直至旧粒子结束，总数小于。
f.params[:total] = 数字

#【设置模板在生成一批粒子后的等待时间】
# → 单位为 帧（默认RGSS中 1 秒为 60 帧）
f.params[:new_wait] = 数字
#【设置模板在生成一批粒子时的生成数量】
f.params[:new_per_wave] = 数字

#【设置粒子每次更新后的等待时间】
# → 单位为 帧
f.params[:update_wait] = 数字

#【设置粒子的存在时间】
# → 单位为 帧
f.params[:life] = 数字

=end
#
#-------------------------------------------------------
# <2> 粒子模板 - 发射类
#
#  该模板可以生成自动朝随机方向移动的粒子。
#
=begin

#【设置粒子移动的加速度】
# → 该参数须传入 Vector 类（二维向量类）
# → 右为 x 轴正方向，下为 y 轴正方向
f.params[:force] = Vector.new(0,0)

（以下均可传入 数字 或 RangeValue 或 VarValue 或 eval后输出数字的字符串）

#【设置粒子的初速度方向（角度）】
# → 单位为角度，正右为 0°位置，顺时针方向增加，一圈 360°
f.params[:theta] = VarValue.new(0, 0)
#【设置粒子的初速度值】
f.params[:speed] = VarValue.new(0, 0)

#【设置粒子的初始透明度】
f.params[:start_opa] = VarValue.new(255, 0)
#【设置粒子的最终透明度】
# → 依据粒子的存在时间，每帧透明度线性变化
f.params[:end_opa] = VarValue.new(0, 0)

#【设置粒子的初始旋转角度】
f.params[:start_angle] = VarValue.new(0, 0)
#【设置粒子每次更新后增加的旋转角度】
f.params[:angle] = VarValue.new(0, 0)

#【设置粒子的初始缩放倍率】
# → 默认 1.0 为 100% 缩放，2.0 为 200% 缩放，宽和高同比例缩放
f.params[:start_zoom] = VarValue.new(1.0, 0)
#【设置粒子的最终缩放倍率】
# → 依据粒子的存在时间，每帧缩放倍率线性变化
f.params[:end_zoom] = VarValue.new(1.0, 0)

=end
#
#-------------------------------------------------------
# <2> 粒子模板 - 发射类 - ①单点引力场
#
#  该模板增加了一个引力中心点，粒子会受到朝向中心点的引力，进而发生速度变化。
#
=begin

#【设置引力中心点的坐标】
# → 该参数须传入 Vector 类（二维向量类）。
# → 该坐标为全屏坐标，请自行处理视图等要素。
f.params[:center] = Vector.new(0, 0)
#【设置引力常量】
f.params[:gravity] = 5

=end
#
#-------------------------------------------------------
# <2> 粒子模板 - 发射类 - ②单点斥力场
#
#  与 ①单点引力场 相反，该模板增加了一个斥力中心点，粒子会受到远离该点的斥力。
#
=begin

#【设置斥力中心点的坐标】
f.params[:center] = Vector.new(0, 0)
#【设置斥力常量】
f.params[:gravity] = 5

=end
#
#-------------------------------------------------------
# <2> 粒子模板 - 发射类 - ③单反弹盒
#
#  该模板生成的粒子将在预设的反弹盒里移动，触碰边缘时将反弹。
#
=begin

#【设置反弹盒】
# → 单位为 像素，为全屏坐标。
f.params[:rebound_box]  = Rect.new(0, 0, 1, 1)
#【设置反弹因子】
# → 粒子运动到反弹盒边界时，其对应速度将乘以该因子。
#    上下边界将使 y 方向速度变化，左右边界将使 x 方向速度变化。
f.params[:rebound_factor] = -1.0

=end
#
#-------------------------------------------------------
# <3> 粒子模板 - 归位类
#
#  该模板可以将粒子朝指定位置移动（利用缓动函数）。
#
=begin

#【传入目的地坐标数组】
# → 其中每一项应为 [x,y] 的二维数字数组，为全屏像素坐标。
# → 粒子将朝该坐标直线移动。
f.params[:xys] = []
#【设置从目的地坐标数组中取出坐标的方式】
# → 0 为随机取出坐标，1 为正序取出坐标，-1 为逆序取出坐标，
#    这三种模式将保证每个坐标必定全被使用后，才重新循环取出。
# → 10 为完全随机取出坐标，不保证每个坐标都会被用到
f.params[:xys_type] = 0

#【设置移动结束后的旋转角度】
# → 将利用缓动函数，从粒子的初始旋转角度朝该旋转角度变化。
f.params[:angle] = 0

#【设置移动结束后的不透明度】
# → 将利用缓动函数，从粒子的初始不透明度朝该不透明度变化。
f.params[:opacity] = 255

#【设置移动结束后的缩放倍率】
# → 将利用缓动函数，从粒子的初始缩放倍率朝该缩放倍率变化。
f.params[:zoom] = 1.0

#【设置所使用的缓动函数】
# （需要前置【组件-缓动函数 by老鹰】）
f.params[:move_type] = "easeInSine"

#【设置移动所耗时间】
# → 单位为 帧
# → 若未设置或设置 0，则取粒子的存在时间-1。
f.params[:t] = 0

#【设置粒子移动结束时执行一次的代码】
f.params[:eval_pt] = ""

=end
#
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
    @templates[id].finish  if @templates[id]
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
# ■ 工具类：矩形
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
# ■ 工具类：二维向量
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
# ■ 工具类：范围随机量
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
# ■ 工具类：前后范围随机量
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
# ■ 粒子模板 - 母版
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
    # 如果 @params[:sprites] 中的精灵不够用，那么会自动生成新的精灵，
    #  且使用 @params[:bitmap] 中的随机一个位图
    @params[:bitmaps] = [] 
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
  attr_accessor :flag_no_when_out
  attr_accessor :flag_under_player, :flag_use_last_xy
  def init_settings
    @params[:life] = VarValue.new(180, 120) # 存在时间（若为负数，则一直存在）
    @params[:z]    = 1    # 粒子的z值
    
    # 粒子生成的区域（在区域内随机一个点）（窗口坐标）
    @params[:pos_rect] = Rect.new(0,0,Graphics.width,Graphics.height)
    
    # 粒子生成的区域（在区域内随机取一个地图格子）（地图坐标）
    #  x,y 为地图左上角格子位置， w,h 为矩形宽高（地图格子数）（右下角为 x+w-1,y+h-1）
    @params[:pos_map] = nil # Rect.new(0,0,1,1)
    # 粒子生成的区域（将在选定的地图格子中的该矩形区域内随机取一点）（单位为像素）
    @params[:pos_grid] = Rect.new(0,0,32,32)
    # 出屏幕显示区域后不再生成新粒子？
    @flag_no_when_out  = true
    # 设置屏幕显示区域
    @params[:rect_window] = Rect.new(0,0,Graphics.width,Graphics.height)
    
    # 粒子生成的区域是否定位在玩家脚底？
    @flag_under_player = false
    # 玩家所在格子中的粒子显示区域
    @params[:pos_player] = Rect.new(8, 26, 16, 6)
    # 是否使用玩家移动前的坐标，若为false，则为玩家当前坐标
    @flag_use_last_xy = false 
  end
  #--------------------------------------------------------------------------
  # ● 释放粒子的动态参数
  #--------------------------------------------------------------------------
  def dispose_settings
    @params[:bitmaps].each { |b| b.dispose }
    @params[:bitmaps].clear
  end
  #--------------------------------------------------------------------------
  # ● 粒子的总数
  #--------------------------------------------------------------------------
  def get_total_num
    if @params[:pos_map] and @flag_no_when_out
      _x = (@params[:pos_map].x - $game_map.display_x) * 32
      _y = (@params[:pos_map].y - $game_map.display_y) * 32
      _w = @params[:pos_map].width * 32
      _h = @params[:pos_map].height * 32
      return 0 if Rect.new(_x, _y, _w, _h).out?(@params[:rect_window])
    end
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
  def convert_particle(sprite, params = {})
    def sprite.eparams # 粒子系统专用的参数组
      @eparams
    end
    def sprite.eparams=(ps)
      @eparams = ps 
    end 
    sprite.eparams = { 
      :life => 0, # 还会存在的时间
      :wait_count => 0, # 更新等待用计数（emitter内使用）
      :reuse => params[:reuse] || true,  # 是否允许重复使用
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
    last_visible = s.visible; s.visible = false # 避免在位置初始化前就显示
    init_particle
    start_particle
    update_particle
    s.visible = last_visible
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
    when 0 # 模板生成的精灵
      sprite.opacity = 0
      sprite.bitmap.dispose if @flag_dispose_bitmap && sprite.bitmap 
      sprite.bitmap = nil
    when 1 # 外部传入的已存在精灵
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
  # ● 在开始前设置的参数
  #--------------------------------------------------------------------------
  def init_particle
    @particle.opacity = 255
  end
  #--------------------------------------------------------------------------
  # ● 粒子开始
  # @particle 为当前处理的粒子精灵
  #--------------------------------------------------------------------------
  def start_particle
    init_life
    init_bitmap
    init_xy
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
    update_bitmap
    update_xy
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
    @particle.eparams[:life] = get_value(@params[:life]).to_i # 必须为整数
  end
  def update_life
    return if @particle.eparams[:life] <= 0
    @particle.eparams[:life] -= 1  # 生命周期减一
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
    # 移动中所产生的偏移值
    @particle.eparams[:pos_offset] = Vector.new
    # 如果是来自外部的精灵，则不改变原位置
    if particle_from_sprite?(@particle)
      @particle.eparams[:pos] = Vector.new(@particle.x, @particle.y)
      @particle.eparams[:pos_map] = nil
      return 
    end
    # （屏幕坐标）初始显示位置
    r = @params[:pos_rect]  # 在该矩形内随机一个位置
    v = Vector.new(r.x, r.y) + Vector.new(rand(r.width), rand(r.height))
    @particle.eparams[:pos] = v
    # 如果设置了显示在地图上，初始化粒子所在地图的格子
    if @params[:pos_map]
      # 从地图区域中选择一格
      _x, _y = @params[:pos_map].rand_pos
      @particle.eparams[:pos_map] = Vector.new(_x, _y)
      # 从选出的地图格子中划出的一小块区域内随机一点
      r = @params[:pos_grid] 
      v = Vector.new(r.x, r.y) + Vector.new(rand(r.width), rand(r.height))
      @particle.eparams[:pos] = v
    end
    # 如果设置了显示在玩家脚底
    if @flag_under_player
      # 覆盖掉 @params[:pos_map] 的设置
      @params[:pos_map] = Vector.new(0,0)
      if @flag_use_last_xy
        @params[:pos_map].x = $game_player.last_x || 0
        @params[:pos_map].y = $game_player.last_y || 0
      else
        @params[:pos_map].x = $game_player.x || 0
        @params[:pos_map].y = $game_player.y || 0
      end
      r = @params[:pos_player]
      v = Vector.new(r.x, r.y) + Vector.new(rand(r.width), rand(r.height))
      @particle.eparams[:pos] = v
    end
  end
  def update_xy
    @particle.x = @particle.eparams[:pos].x + @particle.eparams[:pos_offset].x
    @particle.y = @particle.eparams[:pos].y + @particle.eparams[:pos_offset].y
    # 如果显示在地图上，额外增加基于地图的坐标偏移量
    if @particle.eparams[:pos_map]
      @particle.x += (@particle.eparams[:pos_map].x - $game_map.display_x) * 32
      @particle.y += (@particle.eparams[:pos_map].y - $game_map.display_y) * 32
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
# ■ 粒子模板 - 发射类
#==============================================================================
class PT_Emitter < ParticleTemplate
  #--------------------------------------------------------------------------
  # ● 初始化粒子的动态参数
  #--------------------------------------------------------------------------
  def init_settings
    super
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
  end
  #--------------------------------------------------------------------------
  # ● 粒子开始
  #--------------------------------------------------------------------------
  def start_particle
    super
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

#==============================================================================
# ■ 粒子模板 - 归位类
#==============================================================================
class PT_Moveto < ParticleTemplate
  #--------------------------------------------------------------------------
  # ● 初始化粒子的动态参数
  #--------------------------------------------------------------------------
  def init_settings
    super
    # 移动后的坐标数组
    @params[:xys] = []
    # 从 @params[:xys] 中获取一个xy的方式
    #  （0随机 1正序 -1倒序 且 每个坐标必定使用一次，再重新循环）
    #  （10随机 且 不保证每个坐标都能用一次）
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
  # ● 在开始前设置的参数
  #--------------------------------------------------------------------------
  def init_particle
    super
    if !particle_from_sprite?(@particle)
      @particle.zoom_x = @particle.zoom_y = 1.0
    end
  end
  #--------------------------------------------------------------------------
  # ● 粒子开始
  #--------------------------------------------------------------------------
  def start_particle
    super
    init_move
    init_others
  end
  #--------------------------------------------------------------------------
  # ● 粒子更新
  #--------------------------------------------------------------------------
  def update_particle
    super
    update_move
    update_others
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
    when 10 # 随机（不删除）
      i = rand(@params[:xys].size)
      xy = @params[:xys][i]
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
