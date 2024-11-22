#==============================================================================
# ■ 技能多段伤害 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
#==============================================================================
$imported ||= {}
$imported["EAGLE-SkillDamageEX"] = "1.0.2"
#==============================================================================
# - 2023.9.8.23 
#==============================================================================
# - 新增跟随动画进行伤害结算，指定动画某一帧结算指定技能公式
#----------------------------------------------------------------------------
# ● 设置
#----------------------------------------------------------------------------
# - 在 数据库-技能/物品 备注栏中填写
#   （其中 n 为动画帧的序号，与 数据库-动画 中的一致，从 1 开始）
#
#   <frame n: type, element_id, {formula}, variance, critical>
#     → 在动画第n帧时结算 formula 公式（使用效果与当前技能一致）
#
#   <frame n: self>
#     → 在动画第n帧时结算当前技能的公式（包含使用效果）
#
#   <frame n: s1> 或 <frame n: s 1>
#     → 在动画第n帧时结算1号技能的数据库中的公式（包含使用效果）
#
#   <frame n: i2> 或 <frame n: i 2>
#     → 在动画第n帧时结算2号物品的数据库中的公式（包含使用效果）
#
# - 若无任何设置，则会在动画的最后一帧结算原始伤害公式（若无动画则立即结算）
#
#----------------------------------------------------------------------------
# ● 警告
#----------------------------------------------------------------------------
#   数据库-技能/物品-“使用”栏-“连续次数”属性将无效，
#   如果它被设置了 1 以外的值，可能出现不明的伤害处理BUG
#----------------------------------------------------------------------------
# ● 兼容
#----------------------------------------------------------------------------
# 1. 为了让伤害结算与动画同步，本插件覆盖了 Scene_Battle#wait_for_animation 方法，
#   如需调用原方法，请使用别名方法 Scene_Battle#eagle_wait_for_animation。
#
# 2. 新增 显示动画+对目标应用物品 的方法
#   如在原始脚本中，新增
#      show_animation(targets, anim_id)
#      targets.each {|target| item.repeats.times{invoke_item(target, item)}}
#   可达成目的（因为默认 invoke_item 方法中包含了 wait_for_animation），
#   那在使用本插件后，需要在这两句后再加上
#      eagle_wait_for_animation
#   来等待 伤害计算与动画显示 的结束。
#
# 3. 默认 Window_BattleLog 的 wait 方法，会使显示动画与伤害处理不同步，
#     因此本插件最后选择移除了战斗日志的等待，请选用并行处理的战斗日志
#
# 4. 本插件最好与带有 伤害POPUP 的插件共同使用
#     （如 YEA - Ace Battle Engine，将本插件置于其下即可）
#==============================================================================
module EAGLE; end
#==============================================================================
# ○【设置部分】
#==============================================================================
module EAGLE::SkillDamage_EX
  #--------------------------------------------------------------------------
  # ●【常量】含有“免疫战斗不能”的状态的ID
  #  - 不推荐设置成原数据库中的10号状态，推荐复制10号状态到另一位置，并设置其ID
  #  - 填入 0 代表在技能结算期间，不阻止被攻击者的死亡
  #--------------------------------------------------------------------------
  STATE_IMMUNE_DIE = 0
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
  REGEXP_SKILL_SET = /([si]) ?(\d+)>/i
  #--------------------------------------------------------------------------
  # ● 读取技能/物品的多段伤害
  #--------------------------------------------------------------------------
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
end
#==============================================================================
# ○ 伤害处理类
#==============================================================================
class Process_AnimDamage
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize
    clear
  end
  #--------------------------------------------------------------------------
  # ● 重置
  #--------------------------------------------------------------------------
  def clear
    @subject = nil; @object = nil
    @items ||= {}; @items.clear
    @frame = 0; @frame_max = 0
  end
  #--------------------------------------------------------------------------
  # ● 已经没有动画显示？
  #--------------------------------------------------------------------------
  def finish?
    @frame_max == @frame
  end
  #--------------------------------------------------------------------------
  # ● 设置
  #--------------------------------------------------------------------------
  def set(subject, obj, frame_to_item, frame_max)
    @subject = subject # 攻击者
    @object = obj # 被攻击者（动画显示于其上）
    @items = frame_to_item # frame_index => item
    @frame = 0
    @frame_max = frame_max
    @object.add_state(EAGLE::SkillDamage_EX::STATE_IMMUNE_DIE) # 附加不死
    apply_item_effects(0)
  end
  #--------------------------------------------------------------------------
  # ● 处理下一帧
  #--------------------------------------------------------------------------
  def add_frame
    return if finish?
    @frame += 1
    apply_item_effects(@frame)
  end
  #--------------------------------------------------------------------------
  # ● 应用指定帧的技能/物品效果
  #--------------------------------------------------------------------------
  def apply_item_effects(frame)
    item = @items[frame]
    if item
      @object.item_apply(@subject, item)
      SceneManager.scene.log_window.display_action_results(@object, item)
    end
    end_apply_item_effects if finish?
  end
  #--------------------------------------------------------------------------
  # ● 结束应用
  #--------------------------------------------------------------------------
  def end_apply_item_effects
    @object.remove_state(EAGLE::SkillDamage_EX::STATE_IMMUNE_DIE) # 移除不死
    # @object.result.clear  # 没必要clear，等战斗者 on_action_end 时统一清空
    if $imported["YEA-BattleEngine"]
      SceneManager.scene.perform_collapse_check(@object)
    else
      @object.refresh
    end
    clear
  end
end
#==============================================================================
# ○ Game_Battler
#==============================================================================
class Game_Battler < Game_BattlerBase
  attr_accessor :process_anim_damage
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  alias eagle_skill_damage_ex_init initialize
  def initialize
    @process_anim_damage = Process_AnimDamage.new
    eagle_skill_damage_ex_init
  end
  #--------------------------------------------------------------------------
  # ● 新增技能/物品应用
  #--------------------------------------------------------------------------
  def add_item_apply(subject, item, anim_id = nil)
    frame_to_item = EAGLE::SkillDamage_EX.load_item_anim_damage(item)
    anim_id ||= item.animation_id
    frame_max = $data_animations[anim_id].frame_max rescue 0
    # 如果未找到设置或无动画，加入伤害判定
    frame_to_item[frame_max] = item if frame_max == 0 || frame_to_item.empty?
    @process_anim_damage.set(subject, self, frame_to_item, frame_max)
  end
end
#==============================================================================
# ○ Sprite_Battler
#==============================================================================
class Sprite_Battler < Sprite_Base
  #--------------------------------------------------------------------------
  # ● 设置动画的精灵
  #     frame : 帧数据（RPG::Animation::Frame）
  #--------------------------------------------------------------------------
  def animation_set_sprites(frame)
    super(frame)
    battler.process_anim_damage.add_frame
  end
end

#==============================================================================
# ○ Scene_Battle
#==============================================================================
class Scene_Battle < Scene_Base
  attr_reader  :log_window
  #--------------------------------------------------------------------------
  # ● 等待动画显示的结束
  #--------------------------------------------------------------------------
  alias eagle_wait_for_animation wait_for_animation
  def wait_for_animation
  end
  #--------------------------------------------------------------------------
  # ● 使用物品
  #--------------------------------------------------------------------------
  alias eagle_skill_damage_ex_use_item use_item
  def use_item
    eagle_skill_damage_ex_use_item
    eagle_wait_for_animation
  end
  #--------------------------------------------------------------------------
  # ● 发动技能／物品
  #--------------------------------------------------------------------------
  alias eagle_skill_damage_ex_invoke_item invoke_item
  def invoke_item(target, item)
    eagle_skill_damage_ex_invoke_item(target, item)
    if $imported["YEA-BattleEngine"]
    else
      # 对于默认战斗系统，此处增加额外的等待
      eagle_wait_for_animation
    end
  end
  #--------------------------------------------------------------------------
  # ●（覆盖）处理攻击动画
  # （新增双持角色第二次攻击）
  #--------------------------------------------------------------------------
  def show_attack_animation(targets)
    anim_id = @subject.atk_animation_id1 rescue 0
    show_normal_animation(targets, anim_id, false)
    # 检查是否为双持角色
    anim_id2 = @subject.atk_animation_id2 rescue 0
    if anim_id2 > 0
      item = @subject.current_action.item
      # 直接处理双持角色的第一次攻击
      targets.each { |t| t.add_item_apply(@subject, item, anim_id) }
      eagle_wait_for_animation
      # 处理第二次攻击
      show_normal_animation(targets, anim_id2, true)
    end
    # 之后由 apply_item_effects 进行伤害判定，在 use_item 中等待动画
  end
  #--------------------------------------------------------------------------
  # ●（覆盖）应用技能／物品效果
  # （修改为：在精灵显示动画时执行战斗者的item_apply方法）
  #--------------------------------------------------------------------------
  def apply_item_effects(target, item)
    anim_id = item.animation_id
    if item.animation_id < 0 # 显示普通攻击动画
      anim_id = @subject.atk_animation_id1 rescue 0
      # 如果双持，在 show_attack_animation 时已完成第一次攻击，此时处理第二次攻击
      anim_id2 = @subject.atk_animation_id2 rescue 0
      anim_id = anim_id2 if anim_id2 > 0
    end
    target.add_item_apply(@subject, item, anim_id)
  end
end

#==============================================================================
# ○ Window_BattleLog
#==============================================================================
class Window_BattleLog < Window_Selectable
  #--------------------------------------------------------------------------
  # ● 等待
  #--------------------------------------------------------------------------
  def wait
  end
  #--------------------------------------------------------------------------
  # ● 等待效果执行的结束
  #--------------------------------------------------------------------------
  def wait_for_effect
  end
  #--------------------------------------------------------------------------
  # ● 等待并清除
  #    进行显示信息的最短等待，并在等待结束后清除信息。
  #--------------------------------------------------------------------------
  def wait_and_clear
    clear
  end
end
