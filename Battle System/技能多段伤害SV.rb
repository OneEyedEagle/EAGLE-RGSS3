#==============================================================================
# ■ 技能多段伤害SV by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【SideView套件】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-SV-SkillDamageEX"] = "1.0.1"
#==============================================================================
# - 2023.4.3.19 
#==============================================================================
# - 本插件新增独立的伤害结算，可以指定在技能后的某一帧结算指定技能公式
# - 本插件完全兼容 SideView，但对于其它战斗系统可能存在较多问题
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
# - 若无任何设置，则会在动画的最后一帧结算伤害公式（若无动画则立即结算）。
#
# - 若动画使用的是 普通攻击，则该设置无效。
#
#----------------------------------------------------------------------------
# ● 兼容
#----------------------------------------------------------------------------
# 1. 默认 Window_BattleLog 的 wait 方法，会使显示动画与伤害处理不同步，
#    因此本插件最后选择移除了战斗日志的等待，请选用并行处理的战斗日志。
#
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
  #--------------------------------------------------------------------------
  # ● 生成一个新的伤害结算
  #--------------------------------------------------------------------------
  @data = []
  def self.add(subject, objects, item, anim_id = nil)
    frame_to_item = load_item_anim_damage(item)
    anim_id ||= item.animation_id
    frame_max = $data_animations[anim_id].frame_max rescue 0
    # 如果未找到设置或无动画，加入伤害判定
    frame_to_item[frame_max] = item if frame_max == 0 || frame_to_item.empty?
    d = Process_AnimDamage.new
    d.set(subject, objects, frame_to_item, frame_max)
    @data.push(d)
  end
  #--------------------------------------------------------------------------
  # ● 更新（随Scene_Battle#update_basic）
  #--------------------------------------------------------------------------
  def self.update
    @data.delete_if { |d| d.finish? }
    @data.each { |d| d.add_frame }
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
    @count = 0; @ani_rate = 4   # 动画每4帧切帧
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
  def set(subject, targets, frame_to_item, frame_max)
    @subject = subject # 攻击者
    @objects = targets # 被攻击者
    @items = frame_to_item # frame_index => item
    @frame = 0
    @frame_max = frame_max
    @objects.each do |s|
      s.add_state(EAGLE::SkillDamage_EX::STATE_IMMUNE_DIE) # 附加不死
    end
    apply_item_effects(0)
  end
  #--------------------------------------------------------------------------
  # ● 处理下一帧
  #--------------------------------------------------------------------------
  def add_frame
    if @count % @ani_rate == 0
      @frame += 1
      apply_item_effects(@frame)
    end
    @count += 1
  end
  #--------------------------------------------------------------------------
  # ● 应用指定帧的技能/物品效果
  #--------------------------------------------------------------------------
  def apply_item_effects(frame)
    item = @items[frame]
    if item
      scene = SceneManager.scene
      @objects.each do |s|
        @subject.result.clear
        s.result.clear
        s.item_apply(@subject, item)
        s.sv.damage_action(@subject, item)
        scene.spriteset.set_damage_pop(s)
        scene.spriteset.set_damage_pop(@subject) if s != @subject
        scene.log_window.display_action_results(s, item)
        #p [frame, @subject.name, s.name, item.name]
      end
    end
    end_apply_item_effects if finish?
  end
  #--------------------------------------------------------------------------
  # ● 结束应用
  #--------------------------------------------------------------------------
  def end_apply_item_effects
    @objects.each do |s|
      s.remove_state(EAGLE::SkillDamage_EX::STATE_IMMUNE_DIE) # 移除不死
      if $imported["YEA-BattleEngine"]
        SceneManager.scene.perform_collapse_check(s)
      else
        s.refresh
      end
    end
    clear
  end
end
end # end of module

#==============================================================================
# ○ Scene_Battle
#==============================================================================
class Scene_Battle < Scene_Base
  attr_reader  :log_window
  #--------------------------------------------------------------------------
  # ● 更新画面（基础）
  #--------------------------------------------------------------------------
  alias eagle_skill_damage_ex_update_basic update_basic
  def update_basic
    eagle_skill_damage_ex_update_basic
    EAGLE::SkillDamage_EX.update
  end
  #--------------------------------------------------------------------------
  # ● 等待动画显示的结束
  #--------------------------------------------------------------------------
  alias eagle_wait_for_animation wait_for_animation
  def wait_for_animation
  end
  #--------------------------------------------------------------------------
  # ● 短时间等待（快进无效）
  #--------------------------------------------------------------------------
  def abs_wait_short
    #abs_wait(15)
  end
  #--------------------------------------------------------------------------
  # ● サイドビューアクション実行
  #--------------------------------------------------------------------------
  alias eagle_skill_damage_ex_play_sideview play_sideview
  def play_sideview(targets, item)
    @subject.result.flag_eagle_damage_ex = false
    eagle_skill_damage_ex_play_sideview(targets, item)
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）ダメージ戦闘アニメ処理
  #--------------------------------------------------------------------------
  def damage_anime(targets, target, item)
    @log_window.back_to(1) if @log_window.line_number == 5
    return if item.scope != 9 && item.scope != 10 && target.dead?
    @miss = false
    invoke_item(target,item)
    if target.result.missed
      target.sv.miss_action(@subject, item)
      return @miss = true
    elsif target.result.evaded or target.sv.counter_id != 0
      target.sv.evasion_action(@subject, item)
      return @miss = true
    elsif target.sv.reflection_id != 0
      N03.set_damage_anime_data(targets, target, [target.sv.reflection_id, false, false, true])
      target.sv.reflection_id = 0
      @reflection_data = [] if @reflection_data == nil
      return @reflection_data.push([N03.get_attack_anime_id(-3, @subject), false, false, true])
    end
    # 新增：如果已经有绑定伤害处理，则跳过此处的伤害处理
    return if @subject.result.flag_eagle_damage_ex
    target.sv.damage_action(@subject, item)
    N03.set_damage(@subject, -target.result.hp_drain, -target.result.mp_drain) if target != @subject
    @spriteset.set_damage_pop(target)
    if target != @subject && @subject.result.hp_damage != 0 or @subject.result.mp_damage != 0
      @spriteset.set_damage_pop(@subject) 
    end
    if @subject.sv.damage_anime_data != []
      N03.set_damage_anime_data(targets, target, @subject.sv.damage_anime_data)
    end
  end
  #--------------------------------------------------------------------------
  # ● 发动技能／物品
  #--------------------------------------------------------------------------
  alias eagle_skill_damage_ex_invoke_item invoke_item
  def invoke_item(target, item)
    eagle_skill_damage_ex_invoke_item(target, item)
    eagle_wait_for_animation 
  end
end
#==============================================================================
# ○ SideView
#==============================================================================
class SideView
  #--------------------------------------------------------------------------
  # ● （覆盖）データベース戦闘アニメ実行
  #--------------------------------------------------------------------------
  def battle_anime
    data = @action_data.dup
    targets = N03.get_targets(data[2], @battler)
    return if targets == []
    data[8] = !data[8] if @mirror
    @set_damage           = data[5]
    @damage_anime_data[0] = N03.get_attack_anime_id(data[1], @battler)
    @damage_anime_data[1] = data[8]
    @damage_anime_data[2] = data[7]
    @damage_anime_data[3] = data[6]
    @damage_anime_data[4] = data[9]
    @wait = N03.get_anime_time(@damage_anime_data[0]) - 2 if data[4]
    return if @set_damage
    for target in targets do display_anime(targets, target, data) end
    # 新增：绑定伤害处理
    anim_id = @damage_anime_data[0]
    item = @battler.current_action.item
    EAGLE::SkillDamage_EX.add(@battler, targets, item, anim_id)
    @battler.result.flag_eagle_damage_ex = true
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）ダメージアニメ
  #--------------------------------------------------------------------------
  def damage_anime(delay_time = 12)
    anim_id = N03.get_attack_anime_id(-3, @battler)
    wait_count = N03.get_anime_time(anim_id) - 2  # 记录一下动画的帧数 
    anime(anim_id, wait = false)  # 不再等待，确保伤害处理也能同步进行
    action_play
    @full_action.unshift("#{wait_count}")  # 2.增加等待动画
    @full_action.unshift("eval('@damage_anime_data = []
      @set_damage = true')")  # 1.开启伤害处理
  end
end

#==============================================================================
# ○ Game_ActionResult
#==============================================================================
class Game_ActionResult
  attr_accessor  :flag_eagle_damage_ex
end
#==============================================================================
# ○ Window_BattleLog
#==============================================================================
class Window_BattleLog < Window_Selectable
  #--------------------------------------------------------------------------
  # ● 去除等待，防止帧计数无法与动画同步
  #--------------------------------------------------------------------------
  def wait
  end
  def wait_for_effect
  end
  def wait_and_clear
    clear
  end
end
