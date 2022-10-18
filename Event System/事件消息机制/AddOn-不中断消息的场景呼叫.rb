#==============================================================================
# ■ Add-On 不中断消息的场景呼叫 by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【事件消息机制 by老鹰】与【场景自由呼叫 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-EventMsgCallScene"] = "1.0.0"
#==============================================================================
# - 2022.10.18.22 
#==============================================================================
# - 本插件让消息中的场景呼叫不中止当前消息执行
#----------------------------------------------------------------------------
# 【原理】
#
#    由于呼叫 scene 会导致消息终止执行，进而影响原本的设计流程，
#    因此使用【场景自由呼叫 by老鹰】中的方法替换了原始的 SceneManager.call
#
#         EAGLE.call_scene(scene)   →  呼叫指定场景
#         Fiber.yield while EAGLE.call_scene?  → 等待场景处理结束
#
#==============================================================================

class Game_Interpreter_EagleMsg
  #--------------------------------------------------------------------------
  # ● 战斗的处理
  #--------------------------------------------------------------------------
  def command_301
    return if $game_party.in_battle
    if @params[0] == 0                      # 直接指定
      troop_id = @params[1]
    elsif @params[0] == 1                   # 变量指定
      troop_id = $game_variables[@params[1]]
    else                                    # 地图指定的敌群
      troop_id = $game_player.make_encounter_troop_id
    end
    if $data_troops[troop_id]
      BattleManager.setup(troop_id, @params[2], @params[3])
      BattleManager.event_proc = Proc.new {|n| @branch[@indent] = n }
      $game_player.make_encounter_count
      #SceneManager.call(Scene_Battle)     # EAGLE 注释
      EAGLE.call_scene(Scene_Battle)       # EAGLE 修改
      Fiber.yield while EAGLE.call_scene?  # EAGLE 修改
    end
    Fiber.yield
  end
  #--------------------------------------------------------------------------
  # ● 商店的处理
  #--------------------------------------------------------------------------
  def command_302
    return if $game_party.in_battle
    goods = [@params]
    while next_event_code == 605
      @index += 1
      goods.push(@list[@index].parameters)
    end
    #SceneManager.call(Scene_Shop)       # EAGLE 注释
    EAGLE.call_scene(Scene_Shop)         # EAGLE 修改
    #SceneManager.scene.prepare(goods, @params[4])  # EAGLE 注释
    SceneManager.eagle_scene.prepare(goods, @params[4])  # EAGLE 修改
    Fiber.yield while EAGLE.call_scene?  # EAGLE 修改
    Fiber.yield
  end
  #--------------------------------------------------------------------------
  # ● 名字输入的处理
  #--------------------------------------------------------------------------
  def command_303
    return if $game_party.in_battle
    if $data_actors[@params[0]]
      #SceneManager.call(Scene_Name)       # EAGLE 注释
      EAGLE.call_scene(Scene_Name)         # EAGLE 修改
      #SceneManager.scene.prepare(@params[0], @params[1])  # EAGLE 注释
      SceneManager.eagle_scene.prepare(@params[0], @params[1])  # EAGLE 修改
      Fiber.yield while EAGLE.call_scene?  # EAGLE 修改
      Fiber.yield
    end
  end
  #--------------------------------------------------------------------------
  # ● 打开菜单画面
  #--------------------------------------------------------------------------
  def command_351
    return if $game_party.in_battle
    #SceneManager.call(Scene_Menu)     # EAGLE 注释
    EAGLE.call_scene(Scene_Menu)       # EAGLE 修改
    Window_MenuCommand::init_command_position
    Fiber.yield while EAGLE.call_scene?  # EAGLE 修改
    Fiber.yield
  end
  #--------------------------------------------------------------------------
  # ● 打开存档画面
  #--------------------------------------------------------------------------
  def command_352
    return if $game_party.in_battle
    #SceneManager.call(Scene_Save)       # EAGLE 注释
    EAGLE.call_scene(Scene_Save)         # EAGLE 修改
    Fiber.yield while EAGLE.call_scene?  # EAGLE 修改
    Fiber.yield
  end
end
