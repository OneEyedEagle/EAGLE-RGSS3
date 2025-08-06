#==============================================================================
# ■ 场景自由呼叫 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
$imported ||= {}
$imported["EAGLE-CallScene"] = "1.2.0"
#=============================================================================
# - 2025.7.29.23 
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
#      如：在地图上对话时呼叫菜单，再选择返回标题，会先回地图，再到标题
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
  def self.call_scene(scene)
    SceneManager.eagle_call(scene)
  end
  #--------------------------------------------------------------------------
  # ● 当前存在呼叫场景？
  #--------------------------------------------------------------------------
  def self.call_scene?
    SceneManager.eagle_scene != nil
  end
end
#==============================================================================
# ○ SceneManager
#==============================================================================
module SceneManager
  #--------------------------------------------------------------------------
  # ● 获取当前在自由呼叫的场景
  #--------------------------------------------------------------------------
  @eagle_scene = nil
  def self.eagle_scene
    @eagle_scene
  end
  #--------------------------------------------------------------------------
  # ● 创建场景
  #--------------------------------------------------------------------------
  def self.eagle_call(scene_class)
    if @eagle_scene
      # 如果已经自由呼叫了场景，则直接按原本的呼叫场景处理
      SceneManager.call(scene_class)
      return 
    end
    @eagle_scene = scene_class.new
  end
  #--------------------------------------------------------------------------
  # ● 更新预定的场景呼叫
  # 随 Scene_Base#update_basic 更新
  #--------------------------------------------------------------------------
  @flag_call_scene = false
  @eagle_scene_class_reserve = nil
  def self.update_call_scene
    if @eagle_scene && @flag_call_scene == false
      @flag_call_scene = true
      call_scene_before(@eagle_scene)
      SceneManager.eagle_save(@eagle_scene)
      call_scene_raw(@eagle_scene)
      SceneManager.eagle_load
      call_scene_after(@eagle_scene)
      @eagle_scene = nil
      @flag_call_scene = false
      if @eagle_scene_class_reserve
        # 如果有预定的场景，则在处理完自由呼叫后，直接跳转
        @scene = @eagle_scene_class_reserve.new
        @eagle_scene_class_reserve = nil
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 不结束当前场景的场景呼叫
  #  不可在 Fiber 控制中调用，否则将报错 double yield
  #--------------------------------------------------------------------------
  def self.call_scene_raw(scene)
    @scene = scene
    @stack = []
    SceneManager.scene.main while @scene && @eagle_scene
  end
  #--------------------------------------------------------------------------
  # ● 执行备份
  #--------------------------------------------------------------------------
  def self.eagle_save(scene)
    snapshot_for_background
    @eagle_old_scene = @scene
    @eagle_old_stack = @stack
    clear
  end
  #--------------------------------------------------------------------------
  # ● 读取备份
  #--------------------------------------------------------------------------
  def self.eagle_load
    @scene = @eagle_old_scene if @eagle_old_scene
    @stack = @eagle_old_stack if @eagle_old_stack
    @eagle_old_scene = nil
    @eagle_old_stack = nil
  end
  #--------------------------------------------------------------------------
  # ● 场景切换前的额外处理
  #--------------------------------------------------------------------------
  def self.call_scene_before(scene)
    Graphics.transition(10)
    if SceneManager.scene_is?(Scene_Map) && scene.class == Scene_Battle
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
    # 如果有预定场景，则不淡入冻结画面，避免显示旧场景
    if @eagle_scene_class_reserve
      # 去掉当前场景的淡出方法
      def @scene.perform_transition; end
    else
      Graphics.transition(10)
    end
  end

  #--------------------------------------------------------------------------
  # ● 直接切换某个场景
  #--------------------------------------------------------------------------
  def self.goto(scene_class)
    if @eagle_scene
      # 去掉当前自由呼叫场景的淡出方法
      def @eagle_scene.perform_transition; end
      # 冻结画面
      Graphics.freeze 
      # 先预定，在处理完自由呼叫场景后跳转
      @eagle_scene_class_reserve = scene_class
      @eagle_scene = nil
      return
    end
    @scene = scene_class.new
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
    SceneManager.update_call_scene
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
