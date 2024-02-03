#==============================================================================
# ■ Add-On2 兼容HiKiMo的SRPG by 老鹰
# ※ 本插件需要放置在【对话框扩展 by老鹰】之下
#==============================================================================
# - HiKiMo的SRPG 汉化版可以在 https://rpg.blue/thread-479957-1-1.html 找到
#=============================================================================
# - 2021.2.11.17 更新
#=============================================================================

class Window_EagleMessage
  #--------------------------------------------------------------------------
  # ● 获取pop的弹出对象（需要有x、y、width、height方法）
  #--------------------------------------------------------------------------
  alias eagle_hikimo_srpg_get_pop_obj eagle_get_pop_obj
  def eagle_get_pop_obj
    return eagle_get_pop_obj_hikimosrpg if SceneManager.scene_is?(Scene_SrpgMap)
    eagle_hikimo_srpg_get_pop_obj
  end
  #--------------------------------------------------------------------------
  # ○ 兼容HiKiMo的SRPG战斗场景
  #--------------------------------------------------------------------------
  def eagle_get_pop_obj_hikimosrpg
    pop_params[:type] = :map_chara
    id = pop_params[:id]
    if id == 0 # 当前事件
      return $game_srpgmap.events[game_message.event_id]
    elsif id > 0 # 第id号事件
      chara = $game_srpgmap.events[id]
      chara ||= $game_srpgmap.events[game_message.event_id]
      return chara
    elsif id < 0 # 队伍中数据库id号角色（不存在则取队长）
      id = id.abs
      $game_srpgmap.actor_events.each do |a|
        return a if a.battler.id == id
      end
      return nil
    end
  end
  #--------------------------------------------------------------------------
  # ● 获取pop对象的精灵（用于计算偏移值）
  #--------------------------------------------------------------------------
  alias eagle_hikimo_srpg_get_pop_sprite eagle_get_pop_sprite
  def eagle_get_pop_sprite
    return eagle_get_pop_sprite_hikimosrpg if SceneManager.scene_is?(Scene_SrpgMap)
    eagle_hikimo_srpg_get_pop_sprite
  end
  #--------------------------------------------------------------------------
  # ○ 兼容HiKiMo的SRPG战斗场景
  #--------------------------------------------------------------------------
  def eagle_get_pop_sprite_hikimosrpg
    SceneManager.scene.spriteset.character_sprites.each do |s|
      return s if s.character == @eagle_pop_obj
    end
    SceneManager.scene.spriteset.actor_event_sprites.each do |s|
      next if s.nil?
      return s if s.character == @eagle_pop_obj
    end
    return nil
  end
end
class Game_SrpgInterpreter
  #--------------------------------------------------------------------------
  # ● 显示文字
  #--------------------------------------------------------------------------
  alias eagle_hikimo_srpg_command_101 command_101
  def command_101
    $game_message.event_id = @event_id
    eagle_hikimo_srpg_command_101
  end
end
class Spriteset_SrpgMap
  attr_reader :character_sprites
  attr_reader :actor_event_sprites
end
class Scene_SrpgMap < Scene_Base
  attr_reader :spriteset
end
#=============================================================================
# ○ Scene_SrpgMap
#=============================================================================
class Scene_SrpgMap < Scene_Base
  attr_reader :spriteset, :message_window
if EAGLE_MSG_EX_COMPAT_MODE == true
  alias eagle_message_ex_compa_mode_update_all_windows update_all_windows
  alias eagle_message_ex_compa_mode_dispose_all_windows dispose_all_windows
  include MESSAGE_EX::COMPA_MODE
  #--------------------------------------------------------------------------
  # ● 生成信息窗口
  #--------------------------------------------------------------------------
  def create_message_window
    @msg_windows = [Window_Message.new, Window_EagleMessage.new]
    @message_window = @msg_windows[0]
  end
else
  #--------------------------------------------------------------------------
  # ● 生成信息窗口
  #--------------------------------------------------------------------------
  def create_message_window
    @message_window = Window_EagleMessage.new
  end
end
end
