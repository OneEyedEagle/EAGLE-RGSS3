#==============================================================================
# ■ 敌人行动扩展 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
#=============================================================================
$imported ||= {}
$imported["EAGLE-EnemyActionEX"] = "1.1.0"
#==============================================================================
# - 2026.8.17.22 重写注释
#==============================================================================
#
# - 默认的敌人行动模式中，仅最高优先级及优先级小于2的行动有概率生效。
# - 本插件尝试引入全新的敌人行动模式。
#
#------------------------------------------------
# 【修改：敌人行动模式】
#
#  1. 去除不满足执行条件的行动；
#
#  2. 将全部剩余行动依据优先级由大到小排序；
#
#  3. 优先级最大的行动被选中概率为 20% ，最小的行动被选中概率为 100%，
#     中间行动的概率按等差数列排序；
#
#  4. 从优先级最大的行动开始，依次判定其是否被选中：
#     如果判定成功，则确定其为敌人行动，结束；
#     如果判定失败，则优先级-1，继续判定其它行动。
#
# - 例子：
#
#    1. 初始全部行动及其优先级：
#     （假定全部行动均满足条件，格式为【技能-优先级-选中概率】）
#      【攻击-4】【防御-3】【火球-6】【治疗-4】
#
#    2. 计算各个行动的概率，并按优先级由大到小排序：
#      【火球-6-70%】【攻击-4-80%】【治疗-4-90%】【防御-3-100%】
#      （注：若优先级相同，则排序后顺序可能不定）
#
#    3. 逐个行动判定是否执行，最后必有一个作为敌人的行动。
#
#------------------------------------------------
# 【新增：设置敌人行动】
#
# - 在 数据库-敌人 的备注中填写：
#
#     <action: skill_id rating {cond}>
#
#   其中 skill_id 为技能ID
#        rating   为该行动的优先级
#        cond     为该行动的生效条件，true 时有效
#                 可用缩写一览：
#                    a 为该敌人，as 为所有敌人的数组，bs 为所有我方的数组。
#                    s 为开关数组，v 为变量数组。
#
#------------------------------------------------
# 【新增：指定敌人行动的目标】
#
# - 在 数据库-敌人 的备注中填写：
#
#     <action target: skill_id {target}>
#
#   其中 skill_id 为技能ID
#        target   为目标数组（可用缩写同上）
#
# - 注意：
#
#  1. 所有使用对应技能的行动，都会被直接指定为对应设置的目标。
#
#  2. 原 数据库-技能 中设置的 效果范围 在该行动中无效。
#
#==============================================================================

module EAGLE
  #--------------------------------------------------------------------------
  # ● 备注栏匹配
  #--------------------------------------------------------------------------
  # - 匹配：新增敌人行动
  # <Action: skill_id, rating, eval_cond>
  REGEXP_ENEMY_ACTION_EX = /<(?i:action): ?(\d+)[ ,]*(\d+)[ ,]*\{(.*?)\}>/
  # - 匹配：指定行动目标
  # <Action Target: skill_id, eval_target>
  REGEXP_ENEMY_ACTION_TARGET = /<(?i:action target): ?(\d+)[ ,]*\{(.*?)\}>/
end

class RPG::Enemy::Action
  attr_accessor :targets # 默认nil
end

class Game_Enemy < Game_Battler
  #--------------------------------------------------------------------------
  # ● 获取敌人的全部Enemy::Action
  #--------------------------------------------------------------------------
  def all_actions
    a = self
    as = friends_unit.members
    bs = opponents_unit.members
    s = $game_switches
    v = $game_variables
    array = enemy.note.scan(EAGLE::REGEXP_ENEMY_ACTION_EX).collect do |param|
      next if param[2] != "" && eval(param[2]) == false
      t = RPG::Enemy::Action.new
      t.skill_id = param[0].to_i
      t.rating = param[1].to_i
      t
    end
    array = array.compact + enemy.actions
    enemy.note.scan(EAGLE::REGEXP_ENEMY_ACTION_TARGET).each do |param|
      array.each do |action|
        next if action.skill_id != param[0].to_i
        action.targets = [eval(param[1])].flatten.compact
      end
    end
    array
  end
  #--------------------------------------------------------------------------
  # ● 生成战斗行动
  #--------------------------------------------------------------------------
  def make_actions
    super
    return if @actions.empty?
    action_list = all_actions.select {|a| action_valid?(a) }
    return if action_list.empty?
    action_list.sort! { |a, b| b.rating <=> a.rating }
    d_rating = action_list[0].rating - action_list[-1].rating
    d_p = (100 - 20) * 1.0 / d_rating
    p0 = 20
    @actions.each do |action|
      temp_list = action_list.dup
      temp_count = -1
      temp_action = nil
      temp_rating = 11
      while temp_action.nil?
        t = temp_list.shift
        if temp_rating != t.rating
          temp_rating = t.rating 
          temp_count += 1
        end
        #p [$data_skills[t.skill_id].name, p0 + d_p * temp_count]
        temp_action = t if rand < (p0 + d_p * temp_count) / 100
      end
      action.set_enemy_action(temp_action)
      if $BTEST
        p self.name + "→" + $data_skills[temp_action.skill_id].name
      end
    end
  end
end

class Game_Action
  #--------------------------------------------------------------------------
  # ● 设置敌人的战斗行动
  #     action : RPG::Enemy::Action
  #--------------------------------------------------------------------------
  def set_enemy_action(action)
    if action
      @enemy_action = action
      set_skill(action.skill_id)
    else
      @enemy_action = nil
      clear
    end
  end
  #--------------------------------------------------------------------------
  # ● 生成目标数组（battler的实例数组）
  #--------------------------------------------------------------------------
  alias eagle_enemy_action_make_targets make_targets
  def make_targets
    return @enemy_action.targets if @enemy_action && @enemy_action.targets
    eagle_enemy_action_make_targets
  end
end
