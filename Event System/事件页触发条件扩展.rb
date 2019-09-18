#=============================================================================
# ■ 事件页触发条件扩展 by 老鹰（http://oneeyedeagle.lofter.com/）
#=============================================================================
$imported ||= {}
$imported["EAGLE-EventCondEX"] = true
#=============================================================================
# - 2019.9.18.15 修改注释
#=============================================================================
# - 本插件对事件页的出现条件进行了扩展，并新增了事件的独立变量（与独立开关一致）
#----------------------------------------------------------------------------
# ○ 事件的独立变量
#----------------------------------------------------------------------------
# - 获取 map_id序号 的地图的 evnet_id序号 的事件的 v_id序号的独立变量的值：
#     $game_self_varialbes[ [map_id, evnet_id, v_id] ]
#
# - 操作独立变量的值：
#     $game_self_varialbes[ [map_id, evnet_id, v_id] ] = value
#
# - 在 事件脚本框 中，可用 @map_id 获取当前地图id，用 @evnet_id 获取当前事件id
#
# - 示例：（在 事件脚本框 中填写）
#     key = [@map_id, @evnet_id, 5]
#     $game_self_varialbes[key] += 4 # 当前事件的5号独立变量的值加5
#
#----------------------------------------------------------------------------
# ○ 新增事件页的触发条件
#----------------------------------------------------------------------------
# - 事件页的第一个指令为 注释 时，在其中按下述格式填入事件页的追加条件
#  （若一个 注释 窗口写不下，可以拆分成多个相邻的 注释 指令）
#     <cond>...</cond>
#
#   其中...替换成需要满足的条件的脚本字符串
#   当 eval(...) 返回false时认为未满足条件
#     可用 se 获取当前事件对象（如 se.id 为事件id，se.name 为事件名称）
#     可用 s 代替 $game_switches，用 v 代替 $game_variables
#     可用 p 代替 $game_player，用 m 代替 $game_party.members
#     可用 e 代替 $game_map.events 或 $game_troop.members
#     可用 ss[A] 代表当前事件的 A 号独立开关的值
#     可用 sv[1] 代表当前事件的 1 号独立变量的值
#
# - 多个条件之间按照出现的先后顺序依次判定，若已经有false，则之后的不再判定
#
# - 示例：
#     <cond>s[1] || s[2]</cond> → 1号或2号开关开启时，本事件页条件达成
#     <cond>v[1] == 2</cond><cond>s[5]==false</cond>
#        → 先判定1号变量是否为1，再判定5号开关是否关闭
#=============================================================================

#=============================================================================
# ■ 读取部分
#=============================================================================
module EAGLE
  #--------------------------------------------------------------------------
  # ● 读取事件页开头的注释组
  #--------------------------------------------------------------------------
  def self.event_comment_head(command_list)
    return "" if command_list.nil? || command_list.empty?
    t = ""; index = 0
    while command_list[index].code == 108 || command_list[index].code == 408
      t += command_list[index].parameters[0]
      index += 1
    end
    t
  end
end
#=============================================================================
# ■ Game_SelfVariables
#=============================================================================
class << DataManager
  #--------------------------------------------------------------------------
  # ● 生成各种游戏对象
  #--------------------------------------------------------------------------
  alias eagle_event_sv_create_game_objects create_game_objects
  def create_game_objects
    eagle_event_sv_create_game_objects
    $game_self_varialbes = Game_SelfVariables.new
  end
  #--------------------------------------------------------------------------
  # ● 生成存档内容
  #--------------------------------------------------------------------------
  alias eagle_event_sv_make_save_contents make_save_contents
  def make_save_contents
    contents = eagle_event_sv_make_save_contents
    contents[:self_variables] = $game_self_varialbes
    contents
  end
  #--------------------------------------------------------------------------
  # ● 展开存档内容
  #--------------------------------------------------------------------------
  alias eagle_event_sv_extract_save_contents extract_save_contents
  def extract_save_contents(contents)
    eagle_event_sv_extract_save_contents(contents)
    $game_self_varialbes = contents[:self_variables]
  end
end
#=============================================================================
# ■ Game_SelfVariables
#=============================================================================
class Game_SelfVariables < Game_SelfSwitches
  #--------------------------------------------------------------------------
  # ● 读取变量值
  #--------------------------------------------------------------------------
  def [](key)
    # [map_id, event_id, v_id] => value
    @data[key] || 0
  end
end
#=============================================================================
# ■ Game_Event
#=============================================================================
class Game_Event
  #--------------------------------------------------------------------------
  # ● 事件页满足触发条件？
  #--------------------------------------------------------------------------
  alias eagle_event_cond_met conditions_met?
  def conditions_met?(page)
    return false if !eagle_event_cond_met(page)
    text = EAGLE.event_comment_head( page.list )
    se = @event
    p = $game_player
    m = $game_party.members
    e = $game_map.events if SceneManager.scene_is?(Scene_Map)
    e = $game_troop.members if SceneManager.scene_is?(Scene_Battle)
    s = $game_switches; v = $game_variables
    text.gsub!( /ss\[([ABCD])\]/ ) { "ss[[#{@map_id},#{@event.id},\"#{$1}\"]]" }
    ss = $game_self_switches
    text.gsub!( /sv\[(\d+)\]/ ) { "sv[[#{@map_id},#{@event.id},#{$1}]]" }
    sv = $game_self_varialbes
    text.scan(/<cond>(.*?)<\/cond>/).each do |cond|
      return false if eval(cond[0]) == false
    end
    return true
  end
end
