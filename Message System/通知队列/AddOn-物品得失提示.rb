#==============================================================================
# ■ Add-On 物品得失提示 by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【通知队列 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-MessageHint-GetItem"] = "1.0.1"
#==============================================================================
# - 2022.2.27.17
#==============================================================================
# - 本插件基于【通知队列】，新增了自动处理的物品得失提示。
#   具体设置请见【通知队列】脚本中的注释。
#==============================================================================
module MESSAGE_HINT
  #--------------------------------------------------------------------------
  # ●【常量】物品得失等所使用的队列ID
  #--------------------------------------------------------------------------
  DEF_FUNC_ID = "EAGLE-物品获得提示"
  #--------------------------------------------------------------------------
  # ●【常量】设置物品得失提示所用的队列
  #--------------------------------------------------------------------------
  PARAMS[DEF_FUNC_ID] = {
    # 1 代表使用纯色背景
    "HINT_BG_TYPE" => 1,
    "HINT_BG1_COLOR" => Color.new(0,0,0, 150),
    "HINT_BG1_PADDING" => 4,

    "HINT_FONT_SIZE" => Font.default_size,
    "HINT_FONT_COLOR" => Color.new(255,255,255, 255),
    "HINT_TEXT_W_ADD_L" => 4,
    "HINT_TEXT_W_ADD_R" => 30,

    "HINT_OX" => 1,
    "HINT_OY" => 0.5,
    "HINT_X" => Graphics.width,
    "HINT_Y" => Graphics.height - 150,
    # 新的显示在 X,Y 处，旧的向上移动
    "HINT_POS_TYPE" => 0,
    "HINT_IN_TYPE" => 1,

    "HINT_DX_IN" => 50,
    "HINT_DY_IN" => 0,
    "HINT_DX_OUT" => 50,
    "HINT_DY_OUT" => 0,
  }
  #--------------------------------------------------------------------------
  # 【常量】当该开关开启时，启用物品得失提示
  # 若为 0，则为一直开启状态
  #--------------------------------------------------------------------------
  DEF_FUNC_ITEM = 0
  #--------------------------------------------------------------------------
  # 【常量】当该开关开启时，启用金钱得失提示
  # 若为 0，则为一直开启状态
  #--------------------------------------------------------------------------
  DEF_FUNC_GOLD = 0
  #--------------------------------------------------------------------------
  # 【常量】当该开关开启时，启用入队离队提示
  # 若为 0，则为一直开启状态
  #--------------------------------------------------------------------------
  DEF_FUNC_PARTY = 0
end
#===============================================================================
# ○ Game_Party
#===============================================================================
class Game_Party < Game_Unit
  #--------------------------------------------------------------------------
  # ● 角色入队
  #--------------------------------------------------------------------------
  alias eagle_message_hint_add_actor add_actor
  def add_actor(actor_id)
    eagle_message_hint_add_actor(actor_id)
    # 以下为新增内容
    sid = MESSAGE_HINT::DEF_FUNC_PARTY
    if sid == 0 || $game_switches[sid] == true
      ps = {}
      actor = $data_actors[actor_id]
      ps[:text] = "#{actor.name} 入队"
      MESSAGE_HINT.add(ps, MESSAGE_HINT::DEF_FUNC_ID)
    end
  end
  #--------------------------------------------------------------------------
  # ● 角色离队
  #--------------------------------------------------------------------------
  alias eagle_message_hint_remove_actor remove_actor
  def remove_actor(actor_id)
    eagle_message_hint_remove_actor(actor_id)
    # 以下为新增内容
    sid = MESSAGE_HINT::DEF_FUNC_PARTY
    if sid == 0 || $game_switches[sid] == true
      ps = {}
      actor = $data_actors[actor_id]
      ps[:text] = "#{actor.name} 离队"
      MESSAGE_HINT.add(ps, MESSAGE_HINT::DEF_FUNC_ID)
    end
  end
  #--------------------------------------------------------------------------
  # ● 增加／减少持有金钱
  #--------------------------------------------------------------------------
  alias eagle_message_hint_gain_gold gain_gold
  def gain_gold(amount)
    eagle_message_hint_gain_gold(amount)
    # 以下为新增内容
    sid = MESSAGE_HINT::DEF_FUNC_GOLD
    if sid == 0 || $game_switches[sid] == true
      ps = {}
      t = amount > 0 ? "获得" : "失去"
      ps[:text] = "#{t} #{amount.abs}#{Vocab.currency_unit}"
      MESSAGE_HINT.add(ps, MESSAGE_HINT::DEF_FUNC_ID)
    end
  end
  #--------------------------------------------------------------------------
  # ● 增加／减少物品
  #     include_equip : 是否包括装备
  #--------------------------------------------------------------------------
  alias eagle_message_hint_gain_item gain_item
  def gain_item(item, amount, include_equip = false)
    container = item_container(item.class)
    return unless container
    eagle_message_hint_gain_item(item, amount, include_equip)
    # 以下为新增内容
    sid = MESSAGE_HINT::DEF_FUNC_ITEM
    if sid == 0 || $game_switches[sid] == true
      ps = {}
      t = amount > 0 ? "获得" : "失去"
      ps[:text] = "#{t} \\i[#{item.icon_index}]#{item.name} x #{amount.abs}"
      MESSAGE_HINT.add(ps, MESSAGE_HINT::DEF_FUNC_ID)
    end
  end
end
