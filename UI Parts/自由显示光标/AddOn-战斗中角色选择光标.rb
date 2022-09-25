#==============================================================================
# ■ Add-On 战斗中角色选择光标 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【自由显示光标 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-Cursor-Battler"] = "1.0.0"
#=============================================================================
# - 2022.9.25.16
#=============================================================================
# - 本插件新增：在战斗中进行角色/敌人选择时，显示一个动态光标
#-----------------------------------------------------------------------------
# - 具体请自行搜索并修改 CURSOR.set_sprite 方法的参数
#=============================================================================

module CURSOR
  #--------------------------------------------------------------------------
  # ●【常量】光标的参数（详见 利用全局脚本定位光标 中的 ps参数）
  #--------------------------------------------------------------------------
  BATTLER_CURSOR_PARAMS = {
    :d => 6,
  }
end

class Window_BattleActor < Window_BattleStatus
  #--------------------------------------------------------------------------
  # ● 调用帮助窗口的更新方法
  #--------------------------------------------------------------------------
  def call_update_help
    super
    ss = SceneManager.scene.spriteset.actor_sprites
    ss.each do |s|
      if s.battler == $game_party.members[index] 
        # 光标移动到当前选中的我方队员
        ps = CURSOR::BATTLER_CURSOR_PARAMS.dup
        ps[:text] = s.battler.name
        CURSOR.set_sprite("战斗角色", s, ps)
        break
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 隐藏
  #--------------------------------------------------------------------------
  alias eagle_cursor_hide hide 
  def hide
    CURSOR.reset("战斗角色")
    eagle_cursor_hide
  end
end

class Window_BattleEnemy < Window_Selectable
  #--------------------------------------------------------------------------
  # ● 调用帮助窗口的更新方法
  #--------------------------------------------------------------------------
  def call_update_help
    super
    ss = SceneManager.scene.spriteset.enemy_sprites
    ss.each do |s|
      if s.battler == enemy
        # 光标移动到当前选中的敌人
        ps = CURSOR::BATTLER_CURSOR_PARAMS.dup
        ps[:text] = s.battler.name
        CURSOR.set_sprite("战斗角色", s, ps)
        break
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 隐藏
  #--------------------------------------------------------------------------
  alias eagle_cursor_hide hide 
  def hide
    CURSOR.reset("战斗角色")
    eagle_cursor_hide
  end
end

class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # ● 开始后处理
  #--------------------------------------------------------------------------
  alias eagle_cursor_post_start post_start
  def post_start
    eagle_cursor_post_start
    CURSOR.new("战斗角色")
  end
  #--------------------------------------------------------------------------
  # ● 结束前处理
  #--------------------------------------------------------------------------
  alias eagle_cursor_pre_terminate pre_terminate
  def pre_terminate
    CURSOR.delete("战斗角色")
    eagle_cursor_pre_terminate
  end
end
