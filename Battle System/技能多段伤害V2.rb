#==============================================================================
# ■ 技能多段伤害V2 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
#==============================================================================
$imported ||= {}
$imported["EAGLE-SkillDamageEX-V2"] = "2.0.0"
#==============================================================================
# - 2026.6.23.20 
#==============================================================================

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# ● 什么是 多段伤害
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#
#  1. 本插件新增了能结算技能伤害的动画，且与默认的战斗动画互相独立。
#
#  2. 在动画播放时，能够在指定帧结算伤害公式，增加一边播动画、一边受伤的打击感。
#
#  3. 同一角色在同一时刻可以显示多个技能伤害动画，并在全部动画播完后才死亡。
#
#  4. 动画播放可以并行处理，不再强制等待结束。

#------------------------------------------------
# 【设置】
#
# - 在 数据库-技能/物品 备注栏中填写：
#
#    （其中 n 为动画帧的序号，与 数据库-动画 中一致，从 1 开始）
#
#   <frame n: type, element_id, {formula}, variance, critical>
#
#       → 在动画第n帧时结算 formula 公式（使用效果与当前技能一致）
#
#   <frame n: self>
#
#       → 在动画第n帧时结算当前技能的公式（包含使用效果）
#
#   <frame n: s1> 或 <frame n: s 1>
#
#       → 在动画第n帧时结算1号技能的数据库中的公式（包含使用效果）
#
#   <frame n: i2> 或 <frame n: i 2>
#
#       → 在动画第n帧时结算2号物品的数据库中的公式（包含使用效果）
#
#------------------------------------------------
# 【注意】
#
#  1. 备注栏中若未设置，则会在动画中途结算伤害公式。
#
#  2. 若无动画，则会立即结算伤害公式。
#
#  3. 本插件不显示伤害数字POP，请同时使用其它能实时显示伤害数字的插件。
#    （如 YEA - Ace Battle Engine，将本插件置于其下即可）
#
#------------------------------------------------
# 【高级】
#
#  1. 为避免重复播放动画，本插件屏蔽了 Scene_Battle#show_animation ，
#     如果你的确需要调用它，请使用别名 eagle_show_animation ，参数不变。
#
#  2. 对于想要在任意时刻添加技能伤害动画的人：
#
#   ① 添加一个技能伤害动画，并自动播放、结算伤害，直至结束（不会暂停战斗）
#
#   SkillDamageEX.battler_anim_add(object, subject, item, anim_id=nil, mirror=false)
#
#     其中 object  为技能目标，Game_Battler 对象
#          subject 为技能使用者，Game_Battler 对象
#          item    为技能，$data_skills[n] 对象
#          anim_id 为动画ID，数字，若 nil 则为技能的动画
#          mirror  为动画是否镜像翻转，true 或 false
#
#   ② 指定角色是否还在播放技能伤害动画，若是，则返回 true
#
#   SkillDamageEX.battler_anim?(battler=nil)
#
#     其中 battler 为 Game_Battler 对象，
#                  若 nil 则判定全部战斗者，任一人在播放动画，就返回 true 。
#
#==============================================================================

module SkillDamageEX
  
  #--------------------------------------------------------------------------
  # ● 在新增当次行动的全部角色的伤害动画后，执行等待
  #  传入的 block 是等待一帧
  #--------------------------------------------------------------------------
  def self.wait_after_add_anime
    # 仅等待一些帧
    10.times {
      yield if block_given? # 调用传入的等待一帧
    }
    # 等待动画播完
    #while SkillDamageEX.battler_anim?
    #  yield if block_given? # 调用传入的等待一帧
    #end
  end
  
  #--------------------------------------------------------------------------
  # ● 备注栏匹配
  #--------------------------------------------------------------------------
  # - 匹配：基准
  #  <frame n: .>
  #   n - 指定的动画帧数（与 数据库-动画 中的帧序号保持一致）（1 ~ max）
  #       （若设置为 0，则会立即应用第 0 帧的伤害公式）
  #--------------------------------------------------------------------------
  REGEXP_SET = /<frame ?(\d+): ?(.*?)>/i
  #--------------------------------------------------------------------------
  # - 匹配：创建新的 RPG::UsableItem::Damage 对象并调用
  #  <frame n: type, element_id, {formula}, variance, critical>
  #   type - RPG::UsableItem::Damage 对象中的伤害类型ID （0 ~ 6）
  #   element_id - 属性类型ID
  #   formula - 技能公式（写在 {} 内）
  #   variance - 离散度（0 ~ 100）
  #   critical - 是否允许暴击（0 - 不允许，1 - 允许）
  #--------------------------------------------------------------------------
  REGEXP_DAMAGE_SET =
    /(\d)[ ,]*([-\d]+)[ ,]*\{(.*?)\}[ ,]*(\d+)[ ,]*(\d)/
  #--------------------------------------------------------------------------
  # - 匹配：调用自身的伤害公式
  #  <frame n: self>
  #--------------------------------------------------------------------------
  REGEXP_SELF_SET = /self/i
  #--------------------------------------------------------------------------
  # - 匹配：调用指定技能/物品的伤害公式
  #  <frame n: s 1> 1号技能
  #  <frame n: i1>  1号物品
  #--------------------------------------------------------------------------
  REGEXP_SKILL_SET = /([si]) ?(\d+)/i
  
  # 读取技能/物品备注栏
  def self.load_item_anim_damage(item)
    frame_to_item = {}
    item.note.scan(REGEXP_SET).each do |params|
      frame_index = params[0].to_i
      if params[1] =~ REGEXP_SELF_SET
        frame_to_item[frame_index] = item
      elsif params[1] =~ REGEXP_SKILL_SET
        object = $1 == 's' ? $data_skills : $data_items
        frame_to_item[frame_index] = object[$2.to_i]
      else
        params[1] =~ REGEXP_DAMAGE_SET
        damage = RPG::UsableItem::Damage.new
        damage.type = $1.to_i
        damage.element_id = $2.to_i
        damage.formula = $3
        damage.variance = $4.to_i
        damage.critical = $5.to_i == 0 ? false : true
        _item = item.dup; _item.damage = damage
        frame_to_item[frame_index] = _item
      end
    end
    frame_to_item
  end
  
  #--------------------------------------------------------------------------
  # ● 增加一个技能伤害精灵
  #--------------------------------------------------------------------------
  def self.battler_anim_add(object, subject, item, anim_id=nil, mirror=false)
    frame_to_item = SkillDamageEX.load_item_anim_damage(item)
    # 如果无动画，手动加一个伤害处理
    anim_id ||= item.animation_id
    frame_max = $data_animations[anim_id].frame_max rescue 0
    frame_to_item[0] = item if frame_max == 0 
    # 如果没有任何设置，手动加一个伤害处理
    frame_to_item[frame_max/2] = item if frame_to_item.empty?
    
    d = Process_AnimDamage.new
    d.set(subject, object, frame_to_item)
    s = new_sprite(object)
    s.bind_damage(d)
    s.start_animation($data_animations[anim_id], mirror)
    @sprites1 << s
  end
  
  #--------------------------------------------------------------------------
  # ● 正在处理指定战斗者的技能伤害精灵？
  #   nil - 还在处理任一战斗者的技能伤害精灵？
  #--------------------------------------------------------------------------
  def self.battler_anim?(battler=nil)
    if battler == nil
      return !@sprites1.empty?
    end
    return @sprites1.any? { |s| s.battler == battler }
  end

  #--------------------------------------------------------------------------
  # ● 在 Spriteset_Battle 中的处理
  #--------------------------------------------------------------------------
  # 初始化
  def self.init 
    @sprites1 = []
    @sprites2 = []
  end
  # 获取一个可用的技能伤害精灵
  def self.new_sprite(battler)
    if @sprites2[0]
      s = @sprites2.shift 
      s.bind(battler)
    else
      s = Sprite_SkillDamage.new(battler)
    end
    return s
  end
  # 更新技能伤害精灵数组
  def self.update
    @sprites1.each { |s| s.update }
    @sprites2 << @sprites1.shift if @sprites1[0] and !@sprites1[0].animation?
  end
  # 释放全部技能伤害精灵
  def self.dispose
    @sprites1.each { |s| s.dispose }
    @sprites2.each { |s| s.dispose }
  end

#==============================================================================
# ○ 伤害处理类
#==============================================================================
class Process_AnimDamage
  # 初始化对象
  def initialize
    clear
  end
  # 重置
  def clear
    @subject = nil; @object = nil
    @items ||= {}; @items.clear
  end
  # 设置
  def set(subject, obj, frame_to_item)
    @subject = subject # 攻击者
    @object = obj # 被攻击者（动画显示于其上）
    @items = frame_to_item # frame_index => item
    @frame = 0
    @object.add_death_resist_count
    apply_item_effects(0)
  end
  # 应用指定帧的技能/物品效果（进行伤害结算）
  def apply_item_effects(frame)
    item = @items[frame]
    if item
      @object.item_apply(@subject, item)
      SceneManager.scene.log_window.display_action_results(@object, item)
      after_item_apply(item)
    end
  end
  # （扩展用）进行额外处理
  #    此时 @subject 是技能使用者，@object 是被攻击者，item 是技能
  def after_item_apply(item)
  end
  # 结束
  def end_apply_item_effects
    @object.reduce_death_resist_count
    if $imported["YEA-BattleEngine"]
      SceneManager.scene.perform_collapse_check(@object)
    else
      @object.refresh
    end
  end
end

#==============================================================================
# ○ 进行伤害处理的精灵
#==============================================================================
class Sprite_SkillDamage < Sprite_Base
  #--------------------------------------------------------------------------
  # ● 绑定战斗者的精灵
  #--------------------------------------------------------------------------
  attr_reader   :battler
  def bind(battler)
    @sprite_battler = SceneManager.scene.spriteset.get_battler_sprite(battler)
    self.viewport = @sprite_battler.viewport
    @battler = battler
  end
  
  # 初始化对象
  def initialize(battler)
    super(nil)
    bind(battler)
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
      s = @sprite_battler  # 此处修改
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
      sprite.z = @sprite_battler.z + 300 + i  # 此处修改
      sprite.ox = 96
      sprite.oy = 96
      sprite.zoom_x = cell_data[i, 3] / 100.0
      sprite.zoom_y = cell_data[i, 3] / 100.0
      sprite.opacity = cell_data[i, 6] * @sprite_battler.opacity / 255.0 # 此处修改
      sprite.blend_type = cell_data[i, 7]
    end
  end
  
  # 声效(SE)和闪烁时机的处理
  #   timing : 时机（RPG::Animation::Timing）
  def animation_process_timing(timing)
    timing.se.play unless @ani_duplicated
    case timing.flash_scope
    when 1
      # 此处修改
      @sprite_battler.flash(timing.flash_color, timing.flash_duration * @ani_rate)
    when 2
      if viewport && !@ani_duplicated
        viewport.flash(timing.flash_color, timing.flash_duration * @ani_rate)
      end
    when 3
      # 此处修改
      @sprite_battler.flash(nil, timing.flash_duration * @ani_rate)
    end
  end

  #--------------------------------------------------------------------------
  # ● 绑定伤害处理类
  #--------------------------------------------------------------------------
  def bind_damage(damage_process)
    @process_anim_damage = damage_process
  end

  # 动画第n帧时的处理
  def process_when_frame(index) # index 从0开始
    @process_anim_damage.apply_item_effects(index+1)
  end
  
  # 动画结束时的处理
  def process_when_frame_finish
    @process_anim_damage.end_apply_item_effects
  end
end

end  # end of SkillDamageEX

#==============================================================================
# ○ Game_BattlerBase
#==============================================================================
class Game_BattlerBase
  #--------------------------------------------------------------------------
  # ● 获取普通攻击的动画 ID
  #--------------------------------------------------------------------------
  def atk_animation_id1
    1
  end
  #--------------------------------------------------------------------------
  # ● 处理免疫 战斗不能 的层数
  #  大于 0 时免疫
  #--------------------------------------------------------------------------
  def get_death_resist_count
    @death_resist_count ||= 0
    @death_resist_count
  end
  def add_death_resist_count
    @death_resist_count ||= 0
    @death_resist_count += 1
  end
  def reduce_death_resist_count
    @death_resist_count ||= 0
    @death_resist_count -= 1
  end
  #--------------------------------------------------------------------------
  # ● 判定状态是否免疫
  #--------------------------------------------------------------------------
  alias eagle_damage_ex_state_resist? state_resist?
  def state_resist?(state_id)
    return true if state_id == 1 and get_death_resist_count > 0
    eagle_damage_ex_state_resist?(state_id)
  end
end

#==============================================================================
# ○ Spriteset_Battle
#==============================================================================
class Spriteset_Battle
  #--------------------------------------------------------------------------
  # ● 绑定伤害动画精灵的初始化、更新、释放
  #--------------------------------------------------------------------------
  alias eagle_damage_ex_init initialize
  def initialize
    SkillDamageEX.init
    eagle_damage_ex_init
  end
  alias eagle_damage_ex_update update
  def update
    eagle_damage_ex_update
    SkillDamageEX.update
  end
  alias eagle_damage_ex_dispose dispose
  def dispose
    eagle_damage_ex_dispose
    SkillDamageEX.dispose
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
# ○ Scene_Battle
#==============================================================================
class Scene_Battle
  attr_reader :spriteset, :log_window
  #--------------------------------------------------------------------------
  # ● 将默认显示动画屏蔽
  #  如果想用默认的显示动画，请调用 eagle_show_animation(targets, animation_id)
  #--------------------------------------------------------------------------
  alias eagle_show_animation show_animation
  def show_animation(targets, animation_id)
  end
  #--------------------------------------------------------------------------
  # ● 使用技能／物品
  #--------------------------------------------------------------------------
  alias eagle_damage_ex_use_item use_item
  def use_item
    eagle_damage_ex_use_item
    SkillDamageEX.wait_after_add_anime { update_for_wait }
    refresh_status
  end
  #--------------------------------------------------------------------------
  # ● 应用技能／物品效果
  #--------------------------------------------------------------------------
  def apply_item_effects(target, item)
    anim_id = item.animation_id
    mirror = false
    if anim_id < 0
      # 普通攻击
      anim_id = @subject.atk_animation_id1
      # 双持
      if @subject.actor? and @subject.dual_wield?
        SkillDamageEX.battler_anim_add(target, @subject, item, anim_id, mirror)
        anim_id = @subject.atk_animation_id2
        mirror = true
      end
    end
    SkillDamageEX.battler_anim_add(target, @subject, item, anim_id, mirror)
  end
end
