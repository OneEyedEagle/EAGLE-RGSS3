module BATTLER_MSG
  def self.init
  end
  def self.add()
  end
  def self.exist?()
  end
  def self.clear
  end
  class Msg
    def initialize()
    end
    def equal?()
    end
  end
end
class Game_Battler
  def msg(sym)
  end
end
class Scene_Battle
  #--------------------------------------------------------------------------
  # ● 获取敌我双方的全部参战角色
  #--------------------------------------------------------------------------
  def all_battle_members
    $game_party.members + $game_troop.members
  end
  #--------------------------------------------------------------------------
  # ● 执行战斗行动
  #--------------------------------------------------------------------------
  def execute_action
    @subject.sprite_effect_type = :whiten
    use_item
    @log_window.wait_and_clear
  end
  #--------------------------------------------------------------------------
  # ● 使用技能／物品
  #--------------------------------------------------------------------------
  def use_item
    item = @subject.current_action.item
    @log_window.display_use_item(@subject, item)
    @subject.use_item(item)
    refresh_status
    targets = @subject.current_action.make_targets.compact
    show_animation(targets, item.animation_id)
    targets.each {|target| item.repeats.times { invoke_item(target, item) } }
  end
  #--------------------------------------------------------------------------
  # ● 发动技能／物品
  #--------------------------------------------------------------------------
  def invoke_item(target, item)
    if rand < target.item_cnt(@subject, item)
      invoke_counter_attack(target, item)
    elsif rand < target.item_mrf(@subject, item)
      invoke_magic_reflection(target, item)
    else
      apply_item_effects(apply_substitute(target, item), item)
    end
    @subject.last_target_index = target.index
  end
  #--------------------------------------------------------------------------
  # ● 应用技能／物品效果
  #--------------------------------------------------------------------------
  def apply_item_effects(target, item)
    target.item_apply(@subject, item)
    refresh_status
    @log_window.display_action_results(target, item)
  end
  #--------------------------------------------------------------------------
  # ● 发动反击
  #--------------------------------------------------------------------------
  def invoke_counter_attack(target, item)
    @log_window.display_counter(target, item)
    attack_skill = $data_skills[target.attack_skill_id]
    @subject.item_apply(target, attack_skill)
    refresh_status
    @log_window.display_action_results(@subject, attack_skill)
  end
  #--------------------------------------------------------------------------
  # ● 发动反射魔法攻击
  #--------------------------------------------------------------------------
  def invoke_magic_reflection(target, item)
    @log_window.display_reflection(target, item)
    apply_item_effects(@subject, item)
  end
end
