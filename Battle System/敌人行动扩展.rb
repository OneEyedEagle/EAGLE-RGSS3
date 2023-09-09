#==============================================================================
# ■ 敌人行动扩展 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
#=============================================================================
$imported ||= {}
$imported["EAGLE-EnemyActionEX"] = "1.0.0"
#==============================================================================
# - 2018.3.9.13
#==============================================================================
# - 新增敌人行动指令扩展
# - 数据库-敌人备注栏填写 <Action: skill_id, rating, eval_cond>，可新增敌人行动
#     skill_id - 指定的技能id
#     rating - 该行动的优先级
#     eval_cond - （可选）被eval后返回真时，该行动才有效
# 【注】eval字符串中可用变量缩写
#   a - 该敌人的实例  as - 所有敌人实例数组  bs - 所有我方实例数组
#   s - 全局开关数组  v - 全局变量数组
#
# - 新增敌人行动释放目标直接指定
#   数据库-敌人备注栏填写 <Action Target: skill_id, eval_target>，可指定行动目标
#     skill_id - 所有满足该技能id的行动，都会被重新指定目标
#     eval_target - 被eval后返回目标实例数组（变量缩写见上）
#
# - 将敌人行动指令修改为
#  1、去除不满足执行条件的行动
#  2、将全部剩余行动依据优先级由大到小排序
#  3、优先级最小的行动被选中概率为100%，然后随着优先级增加，其被选中概率降低10%
#  4、由优先级最大的行动开始依次判定其选中概率，如果成功，则确定其为敌人行动
#
#  举例：（注：全部为满足执行条件的行动，格式为 技能-优先级-选中概率）
#    1、初始：【攻击-4】【防御-3】【火球-6】【治疗-4】
#    2、排序赋概率：【火球-6-70%】【攻击-4-80%】【治疗-4-90%】【防御-3-100%】
#      （注：若优先级相同，则排序后顺序可能不定）
#    3、逐个判定概率，最后必定有一个行动被选中作为当前敌人行动
#
# - 覆盖了 Game_Enemy#make_actions 方法与 Game_Action#set_enemy_action方法
#==============================================================================
module EAGLE
  # 数据库-敌人备注栏中填写，用于新增敌人行动
  # <Action: skill_id, rating, eval_cond>
  REGEXP_ENEMY_ACTION_EX = /<(?i:action): ?(\d+)[ ,]*(\d+)[ ,]*(.*)>/
  # 数据库-敌人备注栏中填写，用于指定其全部对应行动的目标
  # <Action Target: skill_id, eval_target>
  REGEXP_ENEMY_ACTION_TARGET = /<(?i:action target): ?(\d+)[ ,]*(.*)>/
end

class RPG::Enemy::Action
  attr_accessor :targets # 默认为nil
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
    p0 = 1 - 0.1 * (action_list.size - 1)
    @actions.each do |action|
      temp_list = action_list.dup
      temp_count = 0
      temp_action = nil
      while temp_action.nil?
        t = temp_list.shift
        temp_action = t if rand < p0 + 0.1 * temp_count
        temp_count += 1
      end
      action.set_enemy_action(temp_action)
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
