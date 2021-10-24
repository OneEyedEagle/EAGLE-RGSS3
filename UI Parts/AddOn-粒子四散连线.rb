#==============================================================================
# ■ Add-On 粒子四散连线 by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【粒子发射器V2 by老鹰】与【组件-形状绘制 by老鹰】之下
#==============================================================================
# - 2021.10.24.11
#==============================================================================
# - 本插件新增了四散移动、自动连线的粒子模板
#----------------------------------------------------------------------------
# - 具体效果：
#
#    在背景处，显示一定数目的随机移动的粒子，
#    当粒子之间的距离小于一定值时，将自动绘制连线。
#
# - 已经支持的插件一览：
#
#    任务列表 by 老鹰
#
#    词条系统（文字版） by 老鹰
#
#    对话日志 by 老鹰
#
#    事件记录日志 by 老鹰
#
#    快捷功能界面 by 老鹰
#
#==============================================================================

module PARTICLE
  #--------------------------------------------------------------------------
  # ○ 唯一名称
  #--------------------------------------------------------------------------
  TEMPLATE_UI_BG_NAME = "背景粒子连线"
  #--------------------------------------------------------------------------
  # ○ 参数
  #--------------------------------------------------------------------------
  TEMPLATE_UI_BG_PARAMS = {
  # 点的位图
    :bitmap => Bitmap.new(3, 3),
  # 点的颜色
    :color => Color.new(60,60,60,150),
  # 点的总数目
    :total => 25,
  # 绘制的连线的颜色（不透明度会自动按照距离修改）
    :color_line => Color.new(100,100,100),
  # 能够连线的最大距离（x的差值的平方+y的差值的平方）
    :d_max => 10000,
  # 连线颜色不透明度增加到255的最小距离（x的差值的平方+y的差值的平方）
  #  在 :d_min ~ :d_max 的距离之间，不透明度从 255 线性减小至 0
    :d_min => 3000,
  }
end

#==============================================================================
# ■ 在脚本中预设粒子模板
#==============================================================================
class << PARTICLE
  #--------------------------------------------------------------------------
  # ○ 绑定
  #--------------------------------------------------------------------------
  alias eagle_particle_ui_bg_init init
  def init
    eagle_particle_ui_bg_init

    # 预设模板
    #  全屏随机显示细小方块，并且相互连线
    f = ParticleTemplate_DrawLines.new
    ps = PARTICLE::TEMPLATE_UI_BG_PARAMS

    # 绘制点
    ps[:bitmap].fill_rect(ps[:bitmap].rect, ps[:color])
    # 传入位图，粒子会随机选一个
    f.params[:bitmaps].push(ps[:bitmap])
    # 粒子的生成区域（全屏）
    f.params[:pos_rect] = Rect.new(0, 0, Graphics.width, Graphics.height)
    # 粒子的总数目
    f.params[:total] = ps[:total]
    # 初速度方向（角度）
    f.params[:theta] = VarValue.new(0, 360)
    # 初速度值（标量）
    f.params[:speed] = VarValue.new(2, 1)
    # 存在时间（-1为不自动消失）
    f.params[:life] = -1
    # 设置为一次性生成全部粒子
    f.flag_start_once = true

    setup(PARTICLE::TEMPLATE_UI_BG_NAME, f)
  end
  #--------------------------------------------------------------------------
  # ○ 开始
  #--------------------------------------------------------------------------
  def ui_bg_start(z)
    n = PARTICLE::TEMPLATE_UI_BG_NAME
    f = PARTICLE.emitters[n].template
    f.params[:z] = z + 1
    PARTICLE.start(n)
    PARTICLE.apply(n) { |s| s.z = z + 1 }
  end
  #--------------------------------------------------------------------------
  # ○ 结束
  #--------------------------------------------------------------------------
  def ui_bg_finish
    PARTICLE.dispose(PARTICLE::TEMPLATE_UI_BG_NAME)
  end
end

#==============================================================================
# ■ 粒子模板类 - 连线
#==============================================================================
class ParticleTemplate_DrawLines < ParticleTemplate_ReboundBox
  def init_settings
    super
    @params[:rebound_box] = Rect.new(0, 0, Graphics.width, Graphics.height)
  end
  def start
    super
    @params[:bg] ||= Sprite.new
    @params[:bg].bitmap ||= Bitmap.new(Graphics.width, Graphics.height)
    @params[:bg].bitmap.clear
    @params[:bg].z = @params[:z]
  end
  def dispose
    super
    if @params[:bg]
      @params[:bg].bitmap.dispose
      @params[:bg].dispose
      @params[:bg] = nil
    end
  end
  def update(all_particles)
    super
    return if @params[:bg] == nil
    @params[:bg].bitmap.clear
    ps = PARTICLE::TEMPLATE_UI_BG_PARAMS
    all_particles.each do |s1|
      all_particles.each do |s2|
        d = (s1.x - s2.x)**2 + (s1.y - s2.y)**2
        d_max = ps[:d_max]
        next if d >= d_max
        d_min = ps[:d_min]
        c = ps[:color_line]
        c.alpha = (d_max - d) * 1.0 / (d_max - d_min) * 255
        EAGLE.DDALine(@params[:bg].bitmap, s1.x,s1.y, s2.x, s2.y, 1, "1", c)
      end
    end
  end
end

#===============================================================================
# □ 任务列表
#===============================================================================
if $imported["EAGLE-QuestList"]
class << QUEST
  #--------------------------------------------------------------------------
  # ○ 列表UI-初始化
  #--------------------------------------------------------------------------
  alias eagle_particle_ui_bg_ui_list_init ui_list_init
  def ui_list_init
    eagle_particle_ui_bg_ui_list_init
    PARTICLE.ui_bg_start(@sprite_bg.z + 1)
  end
  #--------------------------------------------------------------------------
  # ○ 列表UI-释放
  #--------------------------------------------------------------------------
  alias eagle_particle_ui_bg_ui_list_dispose ui_list_dispose
  def ui_list_dispose
    eagle_particle_ui_bg_ui_list_dispose
    PARTICLE.ui_bg_finish
  end
end
end

#===============================================================================
# □ 词条系统（文字版）
#===============================================================================
if $imported["EAGLE-Dictionary"]
class << DICT
  #--------------------------------------------------------------------------
  # ● 生成精灵
  #--------------------------------------------------------------------------
  alias eagle_particle_ui_bg_init_sprites init_sprites
  def init_sprites
    eagle_particle_ui_bg_init_sprites
    PARTICLE.ui_bg_start(@sprite_bg.z + 1)
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  alias eagle_particle_ui_bg_dispose dispose
  def dispose
    eagle_particle_ui_bg_dispose
    PARTICLE.ui_bg_finish
  end
end
end

#===============================================================================
# □ 对话日志
#===============================================================================
if $imported["EAGLE-MessageLog"]
class << MSG_LOG
  #--------------------------------------------------------------------------
  # ● UI-初始化
  #--------------------------------------------------------------------------
  alias eagle_particle_ui_bg_ui_init ui_init
  def ui_init
    eagle_particle_ui_bg_ui_init
    PARTICLE.ui_bg_start(@sprite_bg.z + 1)
  end
  #--------------------------------------------------------------------------
  # ● UI-释放
  #--------------------------------------------------------------------------
  alias eagle_particle_ui_bg_ui_dispose ui_dispose
  def ui_dispose
    eagle_particle_ui_bg_ui_dispose
    PARTICLE.ui_bg_finish
  end
end
end

#===============================================================================
# □ 事件记录日志
#===============================================================================
if $imported["EAGLE-EventLog"]
class << EVENT_LOG
  #--------------------------------------------------------------------------
  # ● UI-初始化
  #--------------------------------------------------------------------------
  alias eagle_particle_ui_bg_ui_init ui_init
  def ui_init
    eagle_particle_ui_bg_ui_init
    PARTICLE.ui_bg_start(@sprite_bg.z + 1)
  end
  #--------------------------------------------------------------------------
  # ● UI-释放
  #--------------------------------------------------------------------------
  alias eagle_particle_ui_bg_ui_dispose ui_dispose
  def ui_dispose
    eagle_particle_ui_bg_ui_dispose
    PARTICLE.ui_bg_finish
  end
end
end

#===============================================================================
# □ 快捷功能界面
#===============================================================================
if $imported["EAGLE-EventToolbar"]
class << TOOLBAR
  #--------------------------------------------------------------------------
  # ● UI-初始化
  #--------------------------------------------------------------------------
  alias eagle_particle_ui_bg_ui_init ui_init
  def ui_init
    eagle_particle_ui_bg_ui_init
    PARTICLE.ui_bg_start(@sprite_bg.z + 1)
  end
  #--------------------------------------------------------------------------
  # ● UI-释放
  #--------------------------------------------------------------------------
  alias eagle_particle_ui_bg_ui_dispose ui_dispose
  def ui_dispose
    eagle_particle_ui_bg_ui_dispose
    PARTICLE.ui_bg_finish
  end
end
end
