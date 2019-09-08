#==============================================================================
# ■ 技能目标扩展 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
#  - 在技能/物品的备注栏中填写，可自定义其使用目标数组
#   <target>...</target>
#   - 标签对之间的内容会被eval，然后作为技能使用目标数组返回
#【eval字符串中可用变量】
#  skill/item - 本技能/物品的实例 $data_skills/$data_items
#  a - 技能使用者  as - 技能使用者的队友实例数组  bs - 技能使用者的敌人实例数组
#  s - 全局开关数组  v - 全局变量数组
#  - 本设置优先级高于默认目标数组生成
#【注】为整合Add-On实时选择敌人，设置扩展目标的技能，其数据库-效果范围最好选择 无
#==============================================================================
# - 2018.3.6.17
#==============================================================================
module EAGLE
  # 用于获取需要eval的字符串的正则
  TARGET_EX_REGEXP = /<target>(.*?)<\/target>/m
end

class Game_Action
  #--------------------------------------------------------------------------
  # ● 生成目标数组（battler的实例数组）
  #--------------------------------------------------------------------------
  alias eagle_target_ex_make_targets make_targets
  def make_targets
    # item - 技能物品实例 subject - 技能使用者
    item.note =~ EAGLE::TARGET_EX_REGEXP
    item = skill = self.item
    a = subject
    as = friends_unit.members
    bs = opponents_unit.members
    s = $game_switches
    v = $game_variables
    return [eval($1)].flatten.compact if $1
    eagle_target_ex_make_targets
  end
end

class Game_Action
  #--------------------------------------------------------------------------
  # ● 生成目标数组
  # （在 Scene_Battle#use_item 中调用，获取真实的应用技能的目标数组）
  #--------------------------------------------------------------------------
  def make_targets
    if !forcing && subject.confusion?
      [confusion_target]
    elsif item.for_opponent?
      targets_for_opponents
    elsif item.for_friend?
      targets_for_friends
    else
      []
    end
  end
  #--------------------------------------------------------------------------
  # ● 混乱时的目标
  #--------------------------------------------------------------------------
  def confusion_target
    case subject.confusion_level
    when 1
      opponents_unit.random_target
    when 2
      if rand(2) == 0
        opponents_unit.random_target
      else
        friends_unit.random_target
      end
    else
      friends_unit.random_target
    end
  end
  #--------------------------------------------------------------------------
  # ● 目标为敌人
  #--------------------------------------------------------------------------
  def targets_for_opponents
    if item.for_random?
      Array.new(item.number_of_targets) { opponents_unit.random_target }
    elsif item.for_one?
      num = 1 + (attack? ? subject.atk_times_add.to_i : 0)
      if @target_index < 0
        [opponents_unit.random_target] * num
      else
        [opponents_unit.smooth_target(@target_index)] * num
      end
    else
      opponents_unit.alive_members
    end
  end
  #--------------------------------------------------------------------------
  # ● 目标为队友
  #--------------------------------------------------------------------------
  def targets_for_friends
    if item.for_user?
      [subject]
    elsif item.for_dead_friend?
      if item.for_one?
        [friends_unit.smooth_dead_target(@target_index)]
      else
        friends_unit.dead_members
      end
    elsif item.for_friend?
      if item.for_one?
        [friends_unit.smooth_target(@target_index)]
      else
        friends_unit.alive_members
      end
    end
  end
end

class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # ● 开始选择队友
  #--------------------------------------------------------------------------
  def select_actor_selection
    @actor_window.refresh
    @actor_window.show.activate
  end
  #--------------------------------------------------------------------------
  # ● 角色“确定”
  #--------------------------------------------------------------------------
  def on_actor_ok
    BattleManager.actor.input.target_index = @actor_window.index
    @actor_window.hide
    @skill_window.hide
    @item_window.hide
    next_command
  end
  #--------------------------------------------------------------------------
  # ● 角色“取消”
  #--------------------------------------------------------------------------
  def on_actor_cancel
    @actor_window.hide
    case @actor_command_window.current_symbol
    when :skill
      @skill_window.activate
    when :item
      @item_window.activate
    end
  end
  #--------------------------------------------------------------------------
  # ● 开始选择敌人
  #--------------------------------------------------------------------------
  def select_enemy_selection
    @enemy_window.refresh
    @enemy_window.show.activate
  end
  #--------------------------------------------------------------------------
  # ● 敌人“确定”
  #--------------------------------------------------------------------------
  def on_enemy_ok
    BattleManager.actor.input.target_index = @enemy_window.enemy.index
    @enemy_window.hide
    @skill_window.hide
    @item_window.hide
    next_command
  end
  #--------------------------------------------------------------------------
  # ● 敌人“取消”
  #--------------------------------------------------------------------------
  def on_enemy_cancel
    @enemy_window.hide
    case @actor_command_window.current_symbol
    when :attack
      @actor_command_window.activate
    when :skill
      @skill_window.activate
    when :item
      @item_window.activate
    end
  end
end
