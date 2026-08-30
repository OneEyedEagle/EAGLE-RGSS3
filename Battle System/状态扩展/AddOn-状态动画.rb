#==============================================================================
# ■ Add-On 状态动画 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【状态扩展 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-StateEX-Anim"] = "1.0.2"
#==============================================================================
# - 2026.8.28.23 修复在事件中添加状态时报错的bug
#==============================================================================

module STATE_EX
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# △ 状态的动画                                   【RGSS状态和状态对象】
#
# - 在默认系统中，状态的附加、解除、持续都只有一句战斗日志播报，并不会播放动画。
#   该设置允许在【状态扩展】的 状态的伤害计算 中的各个时机处理伤害时，同步播放动画。
#
#-----------------设置方式-----------------
#
# - 在 数据库-状态 的备注中填写：
# 
#      <动画 类型 动画ID> 或 <anim 数字 数字>
#
#   其中 类型 为 整数，为该动画播放的对应时机的数字，
#                     0 → 状态持续存在时，循环播放（特别新增！）
#                    -1 → 状态被附加时  -2 → 状态被解除时
#                     1 → 行动结束时     2 → 回合结束时
#                   （其他可用类型请见 △ 状态的自动减少时机）
#    
#   其中 动画ID 为正整数，为 数据库-动画 中的ID。
#
#   如 <动画 -1 50>  → 在状态附加时同时播放 50 号动画。
#
#   如 <anim 0 50>  → 在状态持续时，一直循环播放 50 号动画。
#
#------------------------------------------------
# 【设置：循环播放的状态动画，每次播放后等待的帧数】
#
  ANIM_LOOP_WAIT = 60
#
#------------------注 意-------------------
#
#  1. 该状态动画与默认的角色动画互相独立，不会影响技能使用动画。
# 
#  2. 如果同ID的状态同时有多层或多个，其设置的动画只会播放一次。
#

#==============================================================================
#                                 × 帮助完毕 × 
#==============================================================================
  
  #--------------------------------------------------------------------------
  # ○【读取】数据库-状态 的备注栏
  #--------------------------------------------------------------------------
  # 读取状态的动画播放数组
  def self.read_note_anims(t)
    a = {}
    t.scan(/<(动画|anim) *:? *(-?\d+) *(\d+)>/i).each do |_t|
      a[$2.to_i] = $3.to_i
    end
    a
  end

  #--------------------------------------------------------------------------
  # ● 增加一个状态动画精灵
  #--------------------------------------------------------------------------
  # 仅显示一次
  def self.anim_add_for_once(object, state_id, anim_id, mirror=false)
    return if anim_any?(object, state_id, anim_id)
    s = anim_new(object)
    s.bind_state(state_id, anim_id, mirror, true)
    @sprites1 << s
  end
  
  # 循环显示（只要状态存在）
  def self.anim_add_loop(object, state_id, anim_id, mirror=false)
    return if anim_any?(object, state_id, anim_id)
    s = anim_new(object)
    s.bind_state(state_id, anim_id, mirror, false)
    @sprites1 << s
  end
  
  # 避免同一个状态显示重复动画
  def self.anim_any?(object, state_id, anim_id)
    return true if !SceneManager.scene_is?(Scene_Battle)
    @sprites1.any? { |s| s.check?(object, state_id, anim_id) } 
  end

  #--------------------------------------------------------------------------
  # ● 在 Spriteset_Battle 中的处理
  #--------------------------------------------------------------------------
  # 初始化
  def self.anim_init 
    @sprites1 = []
    @sprites2 = []
  end
  # 获取一个可用的状态动画精灵
  def self.anim_new(battler)
    if @sprites2[0]
      s = @sprites2.shift 
      s.bind(battler)
      s.bind_state(nil)
    else
      s = Sprite_StateAnim.new(battler)
    end
    return s
  end
  # 更新状态动画精灵数组
  def self.anim_update
    @sprites1.each { |s| s.update }
    @sprites2 << @sprites1.shift if @sprites1[0] and @sprites1[0].finish?
  end
  # 释放全部状态动画精灵
  def self.anim_dispose
    @sprites1.each { |s| s.dispose }
    @sprites2.each { |s| s.dispose }
  end
end

#==============================================================================
# ■ 数据库-状态类
#==============================================================================
class RPG::State
  attr_reader  :anims
  #--------------------------------------------------------------------------
  # ● 进入游戏时读取备注栏
  #--------------------------------------------------------------------------
  alias eagle_state_anim_reset_state_ex reset_state_ex
  def reset_state_ex
    eagle_state_anim_reset_state_ex
    # 时机 => 动画ID 
    #  其中 0 为状态持续时将始终播放的动画
    @anims = STATE_EX.read_note_anims(note)
  end
end

#==============================================================================
# ○ Spriteset_Battle
#==============================================================================
class Spriteset_Battle
  #--------------------------------------------------------------------------
  # ● 绑定状态动画精灵的初始化、更新、释放
  #--------------------------------------------------------------------------
  alias eagle_state_anim_init initialize
  def initialize
    STATE_EX.anim_init
    eagle_state_anim_init
  end
  alias eagle_state_anim_update update
  def update
    eagle_state_anim_update
    STATE_EX.anim_update
  end
  alias eagle_state_anim_dispose dispose
  def dispose
    eagle_state_anim_dispose
    STATE_EX.anim_dispose
  end
  #--------------------------------------------------------------------------
  # ● 获取指定战斗者的精灵
  #--------------------------------------------------------------------------
  def get_battler_sprite(battler)
    battler_sprites.each { |s| return s if s.battler == battler }
    return nil
  end
end

#==============================================================================
# ○ 播放状态动画的精灵
#==============================================================================
class Sprite_StateAnim < Sprite_Base
  #--------------------------------------------------------------------------
  # ● 绑定战斗者的精灵
  #--------------------------------------------------------------------------
  attr_reader   :battler
  def bind(battler)
    @sprite_battler = SceneManager.scene.spriteset.get_battler_sprite(battler)
    self.viewport = @sprite_battler.viewport
    @battler = battler
  end
  
  # 绑定状态播放
  def bind_state(state_id, anim_id=0, mirror=false, once=true)
    @state_id = state_id
    @state_anim_id = anim_id
    @state_anim_mirror = mirror
    @state_count = 0
    @flag_once = once
  end
  
  # 初始化对象
  def initialize(battler)
    super(nil)
    @battler = @state_id = nil
    bind(battler)
  end
  
  # 播放结束？
  def finish?
    @state_id == nil and !animation?
  end
  
  # 核对是否与已播放的动画相同
  def check?(battler, state_id, anim_id)
    @battler == battler and @state_id == state_id and @state_anim_id == anim_id
  end
  
  #--------------------------------------------------------------------------
  # ● 更新画面
  #--------------------------------------------------------------------------
  def update
    super
    if !animation? and @state_id 
      @state_count -= 1
      return if @state_count > 0
      @state_count = 0 if @state_count < 0
      if @battler.state?(@state_id)
        start_animation($data_animations[@state_anim_id], @state_anim_mirror)
      else
        @state_id = nil
      end
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 将动画的相关设置绑定到战斗者精灵上
  #--------------------------------------------------------------------------
  # 设置动画显示原点
  def set_animation_origin
    if @animation.position == 3
      if viewport == nil
        @ani_ox = Graphics.width / 2
        @ani_oy = Graphics.height / 2
      else
        @ani_ox = viewport.rect.width / 2
        @ani_oy = viewport.rect.height / 2
      end
    else
      s = @sprite_battler  # 此处修改了
      @ani_ox = s.x - s.ox + s.width / 2
      @ani_oy = s.y - s.oy + s.height / 2
      if @animation.position == 0
        @ani_oy -= s.height / 2
      elsif @animation.position == 2
        @ani_oy += s.height / 2
      end
    end
  end
  
  # 更新动画
  def update_animation
    return unless animation?
    @ani_duration -= 1
    if @ani_duration % @ani_rate == 0
      if @ani_duration > 0
        frame_index = @animation.frame_max
        frame_index -= (@ani_duration + @ani_rate - 1) / @ani_rate
        animation_set_sprites(@animation.frames[frame_index])
        @animation.timings.each do |timing|
          animation_process_timing(timing) if timing.frame == frame_index
        end
        process_when_frame(frame_index) # 新增
      else
        end_animation
        process_when_frame_finish # 新增
      end
    end
  end
  
  # 设置动画的精灵
  #   frame : 帧数据（RPG::Animation::Frame）
  def animation_set_sprites(frame)
    cell_data = frame.cell_data
    @ani_sprites.each_with_index do |sprite, i|
      next unless sprite
      pattern = cell_data[i, 0]
      if !pattern || pattern < 0
        sprite.visible = false
        next
      end
      sprite.bitmap = pattern < 100 ? @ani_bitmap1 : @ani_bitmap2
      sprite.visible = true
      sprite.src_rect.set(pattern % 5 * 192,
        pattern % 100 / 5 * 192, 192, 192)
      if @ani_mirror
        sprite.x = @ani_ox - cell_data[i, 1]
        sprite.y = @ani_oy + cell_data[i, 2]
        sprite.angle = (360 - cell_data[i, 4])
        sprite.mirror = (cell_data[i, 5] == 0)
      else
        sprite.x = @ani_ox + cell_data[i, 1]
        sprite.y = @ani_oy + cell_data[i, 2]
        sprite.angle = cell_data[i, 4]
        sprite.mirror = (cell_data[i, 5] == 1)
      end
      sprite.z = @sprite_battler.z + 300 + i  # 此处修改了
      sprite.ox = 96
      sprite.oy = 96
      sprite.zoom_x = cell_data[i, 3] / 100.0
      sprite.zoom_y = cell_data[i, 3] / 100.0
      sprite.opacity = cell_data[i, 6] * @sprite_battler.opacity / 255.0 # 此处修改了
      sprite.blend_type = cell_data[i, 7]
    end
  end
  
  # 声效(SE)和闪烁时机的处理
  #   timing : 时机（RPG::Animation::Timing）
  def animation_process_timing(timing)
    timing.se.play unless @ani_duplicated
    case timing.flash_scope
    when 1
      # 此处修改了
      @sprite_battler.flash(timing.flash_color, timing.flash_duration * @ani_rate)
    when 2
      if viewport && !@ani_duplicated
        viewport.flash(timing.flash_color, timing.flash_duration * @ani_rate)
      end
    when 3
      # 此处修改了
      @sprite_battler.flash(nil, timing.flash_duration * @ani_rate)
    end
  end

  #--------------------------------------------------------------------------
  # ● 新增方法
  #--------------------------------------------------------------------------
  # 动画第n帧时的处理
  def process_when_frame(index) # index 从0开始
  end
  
  # 动画结束时的处理
  def process_when_frame_finish
    @state_count = STATE_EX::ANIM_LOOP_WAIT # 两次播放间的等待
    @state_id = nil if @flag_once
  end
end

#==============================================================================
# ■ 注册状态动画
#==============================================================================
class STATE_EX::Data_StateEX
  # 处理指定时机的结算公式
  alias eagle_state_anim_process_timing_formula process_timing_formula
  def process_timing_formula(timing, flag_apply=true)
    v = eagle_state_anim_process_timing_formula(timing, flag_apply)

    anim_id = state.anims[timing] || 0
    STATE_EX.anim_add_for_once(@battler, state.id, anim_id) if anim_id > 0
    
    if timing = -1  # 状态附加时，注册持续播放的状态动画
      anim_id = state.anims[0] || 0
      STATE_EX.anim_add_loop(@battler, state.id, anim_id) if anim_id > 0
    end
    
    return v
  end
end 

class Game_Battler < Game_BattlerBase
  # 处理默认状态的伤害计算
  alias eagle_state_anim_process_state_timing_eval process_state_timing_eval
  def process_state_timing_eval(state, timing)
    eagle_state_anim_process_state_timing_eval(state, timing)

    anim_id = state.anims[timing] || 0
    STATE_EX.anim_add_for_once(self, state.id, anim_id) if anim_id > 0
    
    if timing = -1  # 状态附加时，注册持续播放的状态动画
      anim_id = state.anims[0] || 0
      STATE_EX.anim_add_loop(self, state.id, anim_id) if anim_id > 0
    end
  end
end 
