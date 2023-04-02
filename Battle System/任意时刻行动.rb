#==============================================================================
# ■ 任意时刻行动 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
#==============================================================================
$imported ||= {}
$imported["EAGLE-ActionEX"] = "1.0.0"
#=============================================================================
# - 2023.4.3.0
#=============================================================================
# - 本插件新增了在任意时刻都能强制战斗行动的全局脚本
# ※ 本插件兼容【SideView100】，请置于其下
#-----------------------------------------------------------------------------
# 【使用】
#
# - 利用全局脚本在任意时刻、任意角色对任意角色触发指定技能（无消耗），并等待执行结束
#
#     BattleManager.play_skill(subject, targets, item, ins=false)
#
#  - 其中 subject 为动作主体
#
#     可以为 Game_Battler 类的对象（单个人）
#       比如 $game_party.members[0] 为我方队伍中的首位角色
#            $game_actors[1] 为数据库中的 1 号角色
#       比如 $game_troop.members[0] 为敌方队伍中的1号索引角色
#
#     可以为 类型+位序 的字符串
#       比如 "a2" 代表我方队伍中数据库ID为2的角色
#       比如 "m1" 代表我方队伍的第2个
#       比如 "e0" 代表敌方队伍的第1个
#       如果对应位序没有角色，则取首位；如果位序为 -1，则取随机一人
#
#  - 其中 targets 为动作客体的数组 
#
#     可以为 Game_Battler 类的对象的数组
#        比如 $game_party.members 为我方全体
#            [ $game_party.members[0] ] 为我方队伍中的首位角色
#        比如 $game_troop.members 为敌方全体
#
#     可以为 类型+位序 的字符串
#       比如 "a1" 代表我方队伍中数据库ID为1的角色
#       比如 "m0" 代表我方队伍的第1个
#       比如 "e0e1" 代表敌方队伍的第1个、第2个
#       如果对应位序没有角色，则跳过；如果位序为 -1，则取全员
#
#  - 其中 item 为技能/物品的实例对象
#
#     比如 $data_skills[5] 为 5号技能
#     比如 $data_items[1] 为 1号物品
#
#  - 其中 ins 为布尔值，true代表立即执行，false代表放入行动序列末尾
#       若不传入，则为放于末尾，按调用顺序依次执行
#
#-------------------------------------------------------------------
# 【示例】
#
# 1. 我方第二个角色使用59号技能攻击敌方全体
#
#  BattleManager.play_skill("a1", $game_troop.members, "s59")
#
# 2. 
#
#-------------------------------------------------------------------
# 【高级】
#
# - 本插件增加了一些方法，用于方便进行判定：
#
#  battler.skill?(skill)  
#    → 是否学习了skill技能？ 
#         传入的 skill 为数字时，代表其在数据库中的ID
#         传入的 skill 为字符串时，代表其在数据库中的名称
#
#=============================================================================

module BattleManager
  #--------------------------------------------------------------------------
  # ● 核心：实时处理行动
  #--------------------------------------------------------------------------
  def self.play_skill(subject, targets, item, ins = false)
    # 入栈
    @eagle_actions ||= []
    d = [subject, targets, item]
    ins ? @eagle_actions.unshift(d) : @eagle_actions.push(d)
    # 如果已经有正在执行的线程，则当前方法结束
    return if @eagle_processing == true
    @eagle_processing = true
    scene = SceneManager.scene 
    cur_subject = scene.subject  # 暂存当前角色
    cur_targets = scene.targets
    # 挂起玩家操作
    flag_actor_command = scene.actor_command_window.active
    scene.actor_command_window.deactivate
    # 循环直到栈清空
    while true
      break if @eagle_actions.empty?
      d = @eagle_actions.shift
      subject = eagle_get_subject(d[0]) 
      targets = eagle_get_targets(d[1])
      item = eagle_get_item(d[2])
      i = Game_BaseItem.new
      i.object = item
      
      # 替换当前角色
      scene.subject = subject
      scene.targets = targets 
      scene.subject_item = item
      # 新增行动，防止因为找不到角色的当前技能而报错
      subject.add_action_ex(i)
      # 新增行动前处理
      scene.process_before_use_item
      # 处理行动
      if defined?(SideView)  # 兼容 Sideview100
        raw_play_skill_sv(scene, subject, targets, item)
      else
        raw_play_skill(scene, subject, targets, item)
      end
      # 新增行动后处理
      scene.process_after_use_item
      # 移除之前新增的行动
      subject.delete_action_ex(i)
      # 复原当前角色
      scene.subject = cur_subject
      scene.targets = cur_targets
      scene.subject_item = cur_subject.current_action.item rescue nil
    end
    # 复原玩家的操作
    scene.actor_command_window.activate if flag_actor_command
    # 结束线程，回到之前的逻辑
    @eagle_processing = false
  end
  #--------------------------------------------------------------------------
  # ● 额外战斗行动（原始）
  #--------------------------------------------------------------------------
  def self.raw_play_skill(scene, subject, targets, item)
    # 显示技能使用
    scene.log_window.display_use_item(subject, item)
    # 处理消耗
    subject.use_item(item)
    # 刷新状态栏
    scene.refresh_status
    # 显示动画
    if !$imported["YEA-BattleEngine"]  
      # 在YEA战斗系统中，显示单个动画位于invoke_item方法内
      scene.show_animation(targets, item.animation_id)
    end
    # 应用伤害
    targets.each {|tar| item.repeats.times { scene.invoke_item(tar, item) } }
    # 处理行动结束
    scene.process_action_end 
    # 消除日志
    scene.log_window.wait_and_clear
  end
  #--------------------------------------------------------------------------
  # ● 额外战斗行动（原始）（Sideview100方法）
  #--------------------------------------------------------------------------
  def self.raw_play_skill_sv(scene, subject, targets, item)
    # 显示技能使用
    scene.display_item(item)
    # 处理消耗
    subject.use_item(item)
    # 刷新状态栏
    scene.refresh_status
    # sideview中设置替伤
    scene.set_substitute(item)
    # sideview中执行动作
    item.repeats.times { scene.play_sideview(targets, item) }
    # sideview中动作结束的处理
    scene.end_reaction(item)
    # sideview中关闭显示技能名称
    scene.display_end_item
  end
  #--------------------------------------------------------------------------
  # ● 获取技能使用者
  # str = Game_Battler 或者 "m5" 或者 "e4"
  #--------------------------------------------------------------------------
  def self.eagle_get_subject(str)
    if str.is_a?(String)
      id = str[1..-1].to_i
      if str[0] == 'a'
        a = $game_party.members.select { |_m| _m.id == id }[0]
        return a || $game_party.members[0]
      elsif str[0] == 'm'
        id = rand($game_party.members.size) if id == -1
        return $game_party.members[id] || $game_party.members[0]
      elsif str[0] == 'e'
        id = rand($game_troop.members.size) if id == -1
        return $game_troop.members[id] || $game_troop.members[0]
      end
    else
      return str
    end
  end
  #--------------------------------------------------------------------------
  # ● 获取技能目标
  # str = [Game_Battler] 或者 "m5" 或者 "e4e5"
  #--------------------------------------------------------------------------
  def self.eagle_get_targets(str)
    if str.is_a?(String)
      ts = []
      while text != ""
        t = text.slice!(/^[A-Z]+/i)
        id = text.slice!(/^\d+/).to_i rescue 0
        if t == 'm'
          ts = ts + $game_party.members if id == -1
          ts.push($game_party.members[id] || nil) if id >= 0
        elsif t == 'a'
          a = $game_party.members.select { |_m| _m.id == id }[0]
          return ts.push(a)
        elsif str[0] == 'e'
          ts = ts + $game_troop.members if id == -1
          ts.push($game_troop.members[id] || nil) if id >= 0
        end
      end
      return ts.conpact
    elsif !str.is_a?(Array)
      return [str]
    else
      return str
    end
  end
  #--------------------------------------------------------------------------
  # ● 获取技能/物品
  # str = $data_skills[id] 或者 $data_items[id] 或者 "s5" 或者 "i2"
  #--------------------------------------------------------------------------
  def self.eagle_get_item(str)
    if str.is_a?(String)
      id = str[1..-1].to_i
      if str[0] == 'i'
        return $data_items[id]
      elsif str[0] == 's'
        return $data_skills[id]
      end
    else
      return str
    end
  end
  #--------------------------------------------------------------------------
  # ● 时机扩展
  #--------------------------------------------------------------------------
  class << self
    alias eagle_battler_action_ex_input_start input_start
    alias eagle_battler_action_ex_turn_start turn_start
    alias eagle_battler_action_ex_battle_start battle_start
  end
  #--------------------------------------------------------
  # 回合开始前（指令输入前）
  def self.input_start
    if SceneManager.scene.flag_process_turn_start != true
      SceneManager.scene.flag_process_turn_start = true
      SceneManager.scene.process_before_turn_start
    end
    return eagle_battler_action_ex_input_start
  end
  #--------------------------------------------------------
  # 回合开始后（指令输入后，全部角色行动前）
  def self.turn_start
    eagle_battler_action_ex_turn_start
    SceneManager.scene.process_after_turn_start
  end
  #--------------------------------------------------------
  # 战斗开始
  def self.battle_start
    eagle_battler_action_ex_battle_start
    SceneManager.scene.process_after_battle_start
  end
end
#==============================================================================
# ○ Game_Battler
#==============================================================================
class Game_Battler
  #--------------------------------------------------------------------------
  # ● 额外战斗行动
  #--------------------------------------------------------------------------
  def add_action_ex(base_item)
    action = Game_Action.new(self, true)
    action.set_skill(base_item.object.id) if base_item.is_skill?
    action.set_item(base_item.object.id) if base_item.is_item?
    @actions.unshift(action)
  end
  #--------------------------------------------------------------------------
  # ● 删除额外行动
  #--------------------------------------------------------------------------
  def delete_action_ex(base_item)
    @actions.shift if @actions[0] && @actions[0].item.id == base_item.object.id
  end
  #--------------------------------------------------------------------------
  # ● 获取技能实例的数组
  #--------------------------------------------------------------------------
  def skills
    []
  end
  #--------------------------------------------------------------------------
  # ● 判定技能是否存在
  #--------------------------------------------------------------------------
  def skill?(skill)
    skills.each do |s| 
      return true if skill.is_a?(Integer) && s.id == skill
      return true if skill.is_a?(String) && s.name == skill
    end
    return false
  end
end
#==============================================================================
# ○ Game_Enemy
#==============================================================================
class Game_Enemy
  #--------------------------------------------------------------------------
  # ● 获取技能实例的数组
  #--------------------------------------------------------------------------
  def skills
    action_skills = enemy.actions.collect {|a| a.skill_id }
    (action_skills | added_skills).sort.collect {|id| $data_skills[id] }
  end
end
#==============================================================================
# ○ Scene_Battle
#==============================================================================
class Scene_Battle < Scene_Base
  attr_accessor  :subject, :targets, :subject_item,  :flag_process_turn_start
  attr_reader    :actor_command_window, :log_window
  #--------------------------------------------------------------------------
  # ● 执行战斗行动
  #--------------------------------------------------------------------------
  alias eagle_battler_action_ex_execute_action execute_action
  def execute_action
    process_before_use_item
    eagle_battler_action_ex_execute_action
    process_after_use_item
  end  
  #--------------------------------------------------------------------------
  # ● 回合结束
  #--------------------------------------------------------------------------
  alias eagle_battler_action_ex_turn_end turn_end
  def turn_end
    @flag_process_turn_start = false
    process_before_turn_end
    eagle_battler_action_ex_turn_end
  end
#==============================================================================
# ○ 以下方法可以别名编写
#==============================================================================
  #--------------------------------------------------------------------------
  # ● 战斗开始后的处理
  # （注意：状态窗口在回合开始前才会打开）
  #--------------------------------------------------------------------------
  def process_after_battle_start
  end
  #--------------------------------------------------------------------------
  # ● 回合开始前的处理
  # （指令输入前）
  #--------------------------------------------------------------------------
  def process_before_turn_start
    #BattleManager.play_skill("a1", $game_troop.members, "s59")
  end
  #--------------------------------------------------------------------------
  # ● 回合开始后的处理
  # （指令输入后，所有角色行动前）
  #--------------------------------------------------------------------------
  def process_after_turn_start
  end
  #--------------------------------------------------------------------------
  # ● 回合结束前的处理
  # （所有角色行动后）
  #--------------------------------------------------------------------------
  def process_before_turn_end
  end
  #--------------------------------------------------------------------------
  # ● 行动开始前的处理
  #  此时 @subject 为当前行动的角色
  #  获取当前角色即将使用的技能 @subject_item
  #--------------------------------------------------------------------------
  def process_before_use_item
  end
  #--------------------------------------------------------------------------
  # ● 行动结束后的处理
  #  此时 @subject 为当前行动的角色
  #  获取当前角色使用完的技能 @subject_item
  #  获取行动结果 @subject.result
  #--------------------------------------------------------------------------
  def process_after_use_item
    #if @subject_item && @subject_item.id == 59
    #  BattleManager.play_skill(@subject, @targets, "s59") if rand > 0.7
    #end
  end
end
