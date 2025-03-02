#==============================================================================
# ■ 技能条件及效果扩展 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
#==============================================================================
$imported ||= {}
$imported["EAGLE-SkillCondEX"] = "1.0.1"
#==============================================================================
# - 2025.2.27.23 
#==============================================================================
# - 本插件新增了技能使用条件扩展及使用前后执行脚本的扩展
#-----------------------------------------------------------------------------
# 【设置：技能使用条件扩展】
#
# - 在 数据库-技能 的备注栏中填写：
#
#     <cond> ... </cond>
#
#   其中 ... 替换为代表技能使用条件的脚本，在 eval 后返回 false 则代表不满足条件
#   可以用 s 代表开关，v 代表变量，a 代表技能使用者
#
# - 比如：
#
#     <cond>a.hp > a.mhp*0.5</cond>  → 使用者的hp在一半以上时，才能使用该技能
#     <cond>s[1] and a.luk>10</cond> → 1号开关开启且使用者的幸运大于10，才能使用
#
#-----------------------------------------------
# 【设置：技能效果扩展】
#
# 1. 在技能使用前执行的脚本：
#
#     <eval1> ... </eval1>
#
#   其中 ... 替换为技能使用时执行的脚本，可用 a 代表技能使用者
#
#   注意：该脚本执行时机为角色开始使用该技能时，还未生成技能释放目标。
#
# 2.1 在技能对目标使用前执行的脚本：
#
#     <eval2> ... </eval2>
#
#   其中 ... 替换为技能使用时执行的脚本，可用 a 代表技能使用者， b 代表技能目标
#
#   注意：如果有多个目标，则会分别对各个目标执行一次该脚本。
#
# 2.2 在技能对目标使用后执行的脚本：
#
#     <eval3> ... </eval3>
#
#   其中 ... 替换为技能使用时执行的脚本，可用 a 代表技能使用者， b 代表技能目标
#                                           r 代表技能结果 Game_ActionResult
#   
#   注意：如果有多个目标，则会分别对各个目标执行一次该脚本。
#
# 3. 在技能使用完成后执行的脚本：
#
#     <eval4> ... </eval4>
#
#   其中 ... 替换为技能使用时执行的脚本，可用 a 代表技能使用者
#
#   注意：该脚本执行时机为角色使用完技能后，所有目标已经处理完成。
#
#==============================================================================

class Game_BattlerBase
  #--------------------------------------------------------------------------
  # ● 检查技能的使用条件
  #--------------------------------------------------------------------------
  alias eagle_skill_cond_ex_skill_conditions_met? skill_conditions_met?
  def skill_conditions_met?(skill)
    eagle_skill_cond_ex_skill_conditions_met?(skill) && \
    skill_conditions_met_ex?(skill)
  end
  #--------------------------------------------------------------------------
  # ● 检查技能的使用条件（扩展）
  #--------------------------------------------------------------------------
  def skill_conditions_met_ex?(skill)
    s = $game_switches; v = $game_variables; a = self; b = nil
    skill.note.scan(/<cond>(.*?)<\/cond>/).each do |cond|
      return false if eval(cond[0]) == false
    end
    return true
  end
end

class Game_Battler < Game_BattlerBase
  #--------------------------------------------------------------------------
  # ● 技能使用前执行脚本
  #--------------------------------------------------------------------------
  def process_item_eval1(item)
    s = $game_switches; v = $game_variables; a = self; b = nil
    item.note.scan(/<eval1>(.*?)<\/eval1>/).each { |cond| eval(cond[0]) }
  end
  #--------------------------------------------------------------------------
  # ● 技能对目标（自己）使用前执行脚本
  #--------------------------------------------------------------------------
  def process_item_eval2(item, user)
    s = $game_switches; v = $game_variables; a = user; b = self
    item.note.scan(/<eval2>(.*?)<\/eval2>/).each { |cond| eval(cond[0]) }
  end
  #--------------------------------------------------------------------------
  # ● 技能对目标（自己）使用后执行脚本
  #--------------------------------------------------------------------------
  def process_item_eval3(item, user)
    s = $game_switches; v = $game_variables; a = user; b = self
    r = @result
    item.note.scan(/<eval3>(.*?)<\/eval3>/).each { |cond| eval(cond[0]) }
  end
  #--------------------------------------------------------------------------
  # ● 技能使用完成后执行脚本
  #--------------------------------------------------------------------------
  def process_item_eval4(item)
    s = $game_switches; v = $game_variables; a = self; b = nil
    item.note.scan(/<eval4>(.*?)<\/eval4>/).each { |cond| eval(cond[0]) }
  end
  #--------------------------------------------------------------------------
  # ● 技能／使用物品
  #--------------------------------------------------------------------------
  alias eagle_skill_cond_ex_use_item use_item
  def use_item(item)
    eagle_skill_cond_ex_use_item(item)
    process_item_eval1(item)
  end
end

class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # ● 发动技能／物品
  #--------------------------------------------------------------------------
  alias eagle_skill_cond_ex_invoke_item invoke_item
  def invoke_item(target, item)
    # 技能对目标使用前
    target.process_item_eval2(item, @subject)
    eagle_skill_cond_ex_invoke_item(target, item)
    # 技能对目标使用后
    target.process_item_eval3(item, @subject)
  end
  #--------------------------------------------------------------------------
  # ● 使用技能／物品
  #--------------------------------------------------------------------------
  alias eagle_skill_cond_ex_use_item use_item
  def use_item
    item = @subject.current_action.item
    eagle_skill_cond_ex_use_item
    @subject.process_item_eval4(item)
  end
  
  if $imported["EAGLE-ActionEX"]
    #------------------------------------------------------------------------
    # ● 如果使用了【任意时刻行动 by老鹰】
    #  因为其新增的行动未使用 Scene_Battle#use_item 方法，
    #  故在它自己的方法中新增对技能使用完成后的处理
    #------------------------------------------------------------------------
    alias eagle_skill_cond_ex_process_after_use_item process_after_use_item
    def process_after_use_item
      eagle_skill_cond_ex_process_after_use_item
      @subject.process_item_eval4(@subject_item) if @subject_item
    end
  end
end
