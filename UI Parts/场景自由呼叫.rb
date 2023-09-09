#==============================================================================
# ■ 场景自由呼叫 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
#==============================================================================
$imported ||= {}
$imported["EAGLE-CallScene"] = "1.1.0"
#=============================================================================
# - 2022.10.18.22 修复 double field 报错
#=============================================================================
# - 新增在任意时刻呼叫指定场景的方法
#
#               EAGLE.call_scene(scene)
#
#   其中 scene 替换成 Scene_Base 的子类的名称，如 Scene_Menu
#
# - 注意：
#
#  ·为了避免 double field 错误，将在下一帧时进行呼叫，因此请自己编写等待结束
#      如： Fiber.yield while EAGLE.call_scene?
#
#  ·在调用后、等待前，可以利用 SceneManager.eagle_scene 对场景进行处理
#
#  ·只暂停而不释放原场景，故请注意调整新场景中窗口等的z值，避免被原场景窗口等覆盖
#
#  ·当调用 SceneManager.return 时，将回到上一级场景，最终返回原场景并继续正常更新
#
#  ·当调用 SceneManager.goto(scene) 时，将同时舍弃呼出场景与原场景，并直接跳转
#      如：在地图上对话时呼叫菜单，再选择返回标题，最终只会剩下标题场景
#
#-----------------------------------------------------------------------------
# ○ 应用：仿AVG呼叫菜单
#-----------------------------------------------------------------------------
# - 新增 Scene_Map 上任意时刻按指定键呼叫菜单
#
# - 注意：
#
#  ·在对话期间同样能执行存档，但对话框z值较大（默认200），很可能盖过新场景的内容，
#     请注意手动调整所打开scene里各项的z值
#
#  ·默认脚本中选项的实现方式采用了无法保存的Proc类，故在选择框打开时将无法存档。
#     但若使用了其余修改了该实现方式的脚本，如【Add-On 选择框扩展 by老鹰】，
#     则同样能在选择框打开时存储，下次读取时将从再次执行选择框处开始。
#
#  ·默认脚本中，保存时会将当前执行事件的指令列表一并保存，
#     而读取时，不会应用任何新的事件指令修改，只会将之前保存的指令列表执行完。
#     但若当前地图有任何修改，在读取时，所有事件均会被重新读取，即位置、图像等重置。
#     因此请注意存档的允许时机。
#
#=============================================================================

module EAGLE
  #--------------------------------------------------------------------------
  # ● 【设置】是否满足随时开启菜单的条件？
  #--------------------------------------------------------------------------
  def self.check_avg_menu?
    false #Input.trigger?(:A) # SHIFT键
  end

  #--------------------------------------------------------------------------
  # ● 不结束当前场景的场景呼叫（预定）
  #--------------------------------------------------------------------------
  @reserve_scene = nil
  @flag_call_scene = false
  def self.call_scene(scene)
    @reserve_scene = scene
    SceneManager.eagle_call(scene)
  end
  #--------------------------------------------------------------------------
  # ● 更新预定的场景呼叫
  # 随 Scene_Base#update_basic 更新
  #--------------------------------------------------------------------------
  def self.update_call_scene
    if @reserve_scene && @flag_call_scene == false
      @flag_call_scene = true
      call_scene_raw(@reserve_scene)
      @reserve_scene = nil
      @flag_call_scene = false
    end
  end
  #--------------------------------------------------------------------------
  # ● 当前存在呼叫场景？
  #--------------------------------------------------------------------------
  def self.call_scene?
    @reserve_scene != nil
  end
  #--------------------------------------------------------------------------
  # ● 不结束当前场景的场景呼叫
  #  不可在 Fiber 控制中调用，否则将报错 double yield
  #--------------------------------------------------------------------------
  def self.call_scene_raw(scene)
    call_scene_before(scene)
    SceneManager.eagle_save(scene)
    SceneManager.scene.main while SceneManager.scene && SceneManager.eagle_scene
    SceneManager.eagle_load
    SceneManager.goto_reserve
    call_scene_after(scene)
  end
  #--------------------------------------------------------------------------
  # ● 场景切换前的额外处理
  #--------------------------------------------------------------------------
  def self.call_scene_before(scene)
    Graphics.transition(10)
    if SceneManager.scene_is?(Scene_Map) && scene == Scene_Battle
      Graphics.update
      Graphics.freeze
      BattleManager.save_bgm_and_bgs
      BattleManager.play_battle_bgm
      Sound.play_battle_start
    end
  end
  #--------------------------------------------------------------------------
  # ● 场景切换后的额外处理
  #--------------------------------------------------------------------------
  def self.call_scene_after(scene)
    Graphics.transition(10)
  end
end
#==============================================================================
# ○ SceneManager
#==============================================================================
module SceneManager
  #--------------------------------------------------------------------------
  # ● 创建场景
  #--------------------------------------------------------------------------
  def self.eagle_call(scene)
    @eagle_scene = scene_class.new
  end
  #--------------------------------------------------------------------------
  # ● 预定的场景
  #--------------------------------------------------------------------------
  def self.eagle_scene
    @eagle_scene
  end
  #--------------------------------------------------------------------------
  # ● 执行备份
  #--------------------------------------------------------------------------
  def self.eagle_save(scene_class)
    snapshot_for_background
    @eagle_old_scene = @scene
    @eagle_old_stack = @stack
    clear
    @scene = @eagle_scene
  end
  #--------------------------------------------------------------------------
  # ● 读取备份
  #--------------------------------------------------------------------------
  def self.eagle_load
    @scene = @eagle_old_scene if @eagle_old_scene
    @stack = @eagle_old_stack if @eagle_old_stack
    @eagle_old_scene = nil
    @eagle_old_stack = nil
    @eagle_scene = nil
  end
  #--------------------------------------------------------------------------
  # ● 直接切换某个场景（无过渡）
  #--------------------------------------------------------------------------
  def self.goto(scene_class)
    if @eagle_old_scene
      eagle_load
      @eagle_reserve_scene = scene_class
      return
    end
    @scene = scene_class.new
  end
  #--------------------------------------------------------------------------
  # ● 直接切换到预定场景（或只过渡）
  #--------------------------------------------------------------------------
  def self.goto_reserve
    if @eagle_reserve_scene
      goto(@eagle_reserve_scene)
    else
      Graphics.transition(1)
    end
    @eagle_reserve_scene = nil
  end
end

#==============================================================================
# ○ Scene_Base
#==============================================================================
class Scene_Base
  #--------------------------------------------------------------------------
  # ● 更新画面
  #--------------------------------------------------------------------------
  alias eagle_scene_base_call_scene_update_basic update_basic
  def update_basic
    EAGLE.update_call_scene
    eagle_scene_base_call_scene_update_basic
  end
end

#==============================================================================
# ○ Scene_Map
#==============================================================================
class Scene_Map
  #--------------------------------------------------------------------------
  # ● 更新画面
  #--------------------------------------------------------------------------
  alias eagle_message_tool_update update
  def update
    eagle_message_tool_update
    if EAGLE.check_avg_menu?
      Window_MenuCommand::init_command_position
      EAGLE.call_scene(Scene_Menu)
    end
  end
end
