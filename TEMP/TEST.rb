# 事件的便捷指令

#------------------------------------------------------------------------------
# 【朝向指定角色】
#
#  | 默认脚本中有事件朝向指定角色的设计，但事件指令中就无了，
#  | 此处增加了一些方便调用的脚本或事件脚本，来利用这个功能。
#
# - 预先说明：
#
#  以下的 event_id 均为【组件-通用方法汇总 by老鹰】中的 get_chara 方法的参数，
#  即：
#
#    若 event_id 为 0，则为事件脚本执行时的所在事件的id
#    若 event_id 为正整数，则为当前地图上的对应事件的id
#    若 event_id 为负整数，则为玩家队伍中，数据库序号为该数绝对值的角色
#                         若对应id号的角色不在队伍中，则取队长
#
# - Game_Character 类：
#
#    event.face_to(event_id)  → 朝向对应角色
#    event.back_to(event_id)  → 背向对应角色
#
# - 事件脚本：
#
#    face_to(event_id)  → 当前事件朝向对应角色
#    back_to(event_id)  → 当前事件背向对应角色
#
#    player_face_to(event_id)  → 玩家朝向对应角色
#                                （event_id为0，则为玩家朝向当前事件）
#    player_back_to(event_id)  → 玩家背向对应角色
#                                （event_id为0，则为玩家背向当前事件）
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# 【地图卷动扩展】
#
#  | 默认事件指令中的地图卷动，需要自己去编辑器地图中数距离，很耿直
#  | 此处增加了方便调用的事件脚本，来便捷进行地图卷动。
#
# - 预先说明：
#
#  以下的 event_id 均为【组件-通用方法汇总 by老鹰】中的 get_chara 方法的参数，
#  具体同上。
#
# - 事件脚本：
#
#    scroll_to_xy(x2, y2, speed = 4, x_first = true)
#
#          → 地图卷动至以（x2, y2）为中心的位置
#             其中 (x2, y2) 为地图编辑器中显示的坐标，
#                  speed 为卷动速度，同事件指令中显示的速度，传入前面的数字，
#                  x_first 为 true 时，代表先进行x方向的移动，再进行y方向的移动，
#                          为 false 时，则为先进行y反向的移动，再进行x方向移动
#
#    scroll_to_event(event_id, speed = 4, x_first = true)
#
#          → 地图卷动至以event_id序号角色为中心的位置
#


#=============================================================================
# ■ Game_Character
#=============================================================================
class Game_Character
  #--------------------------------------------------------------------------
  # ● 朝向指定角色
  #--------------------------------------------------------------------------
  def face_to(event_id)
    e = EAGLE_COMMON.get_chara(nil, event_id)
    turn_toward_character(e)
  end
  #--------------------------------------------------------------------------
  # ● 背向指定角色
  #--------------------------------------------------------------------------
  def back_to(event_id)
    e = EAGLE_COMMON.get_chara(nil, event_id)
    turn_away_from_character(e)
  end
end
#=============================================================================
# ■ Game_Interpreter
#=============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 当前事件朝向指定角色
  #--------------------------------------------------------------------------
  def face_to(event_id)
    e = $game_map.events[@event_id]
    e.face_to(event_id)
  end
  #--------------------------------------------------------------------------
  # ● 当前事件背向指定角色
  #--------------------------------------------------------------------------
  def back_to(event_id)
    e = $game_map.events[@event_id]
    e.back_to(event_id)
  end
  #--------------------------------------------------------------------------
  # ● 玩家朝向指定角色
  #--------------------------------------------------------------------------
  def player_face_to(event_id = 0)
    if event_id == 0
      event_id = @event_id
    end
    $game_player.face_to(event_id)
  end
  #--------------------------------------------------------------------------
  # ● 玩家背向指定角色
  #--------------------------------------------------------------------------
  def player_back_to(event_id = 0)
    if event_id == 0
      event_id = @event_id
    end
    $game_player.back_to(event_id)
  end

  #--------------------------------------------------------------------------
  # ● 地图卷动至指定位置
  #--------------------------------------------------------------------------
  def scroll_to_xy(x2, y2, speed = 4, x_first = true)
    wait_until_scroll
    x1 = $game_map.display_x + $game_map.screen_tile_x / 2
    y1 = $game_map.display_y + $game_map.screen_tile_y / 2

    x_move = Proc.new {
      dx = x2 - x1
      dir = dx > 0 ? 6 : 4
      distance = dx.abs
      $game_map.start_scroll(dir, distance, speed)
      wait_until_scroll
    }
    y_move = Proc.new {
      dy = y2 - y1
      dir = dy > 0 ? 2 : 8
      distance = dy.abs
      $game_map.start_scroll(dir, distance, speed)
      wait_until_scroll
    }

    if x_first  # 先移动 x
      x_move.call
      y_move.call
    else
      y_move.call
      x_move.call
    end
  end
  #--------------------------------------------------------------------------
  # ● 地图卷动至指定角色处
  #--------------------------------------------------------------------------
  def scroll_to_event(event_id, speed = 4, x_first = true)
    e = EAGLE_COMMON.get_chara(nil, event_id)
    x2 = e.x
    y2 = e.y
    if $imported["EAGLE-PixelMove"]
      x2 = e.rgss_x
      y2 = e.rgss_y
    end
    scroll_to_xy(x2, y2, speed, x_first)
  end
  #--------------------------------------------------------------------------
  # ● 等待地图卷动结束
  #--------------------------------------------------------------------------
  def wait_until_scroll
    Fiber.yield while $game_map.scrolling?
  end
end
