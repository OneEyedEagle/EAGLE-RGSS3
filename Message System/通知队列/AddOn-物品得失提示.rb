#==============================================================================
# ■ Add-On 物品得失提示 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【通知队列 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-MessageHint-GetItem"] = "1.0.3"
#==============================================================================
# - 2024.12.3.2 删去更换装备时的物品得失提示
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
  # 【常量】当该ID号的全局开关开启时，启用物品得失提示
  # 若为 0，则为一直开启状态
  #--------------------------------------------------------------------------
  DEF_FUNC_ITEM = 0
  #--------------------------------------------------------------------------
  # ●【常量】当启用物品得失提示时，所显示的提示文本
  # 其中 <icon> 将替换为对应物品的图标id，<name> 将替换为对应物品的名称
  #      <v> 将替换为获得/失去的数量
  #--------------------------------------------------------------------------
  # 获得物品时
  ITEM_GAIN_TEXT = "获得 \\i[<icon>]<name> x <v>"
  # 失去物品时
  ITEM_LOSE_TEXT = "失去 \\i[<icon>]<name> x <v>"
  #--------------------------------------------------------------------------
  # 【常量】当该ID号的全局开关开启时，启用金钱得失提示
  # 若为 0，则为一直开启状态
  #--------------------------------------------------------------------------
  DEF_FUNC_GOLD = 0
  #--------------------------------------------------------------------------
  # ●【常量】当启用金钱得失提示时，所显示的提示文本
  # 其中 <G> 将替换为数据库-用语中设置的金钱的货币单位
  #      <v> 将替换为获得/失去的数量
  #--------------------------------------------------------------------------
  # 获得金钱时
  GOLD_GAIN_TEXT = "获得 <v> <G>"
  # 失去金钱时
  GOLD_LOSE_TEXT = "失去 <v> <G>"
  #--------------------------------------------------------------------------
  # 【常量】当该ID号的全局开关开启时，启用入队离队提示
  # 若为 0，则为一直开启状态
  #--------------------------------------------------------------------------
  DEF_FUNC_PARTY = 0
  #--------------------------------------------------------------------------
  # ●【常量】当启用入队离队提示时，所显示的提示文本
  # 其中 <name> 将替换为对应角色的姓名
  #--------------------------------------------------------------------------
  # 角色入队时
  PARTY_IN_TEXT  = "<name> 入队"
  # 角色离队时
  PARTY_OUT_TEXT = "<name> 离队"

end  # 不要删
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
      t = MESSAGE_HINT::PARTY_IN_TEXT.dup
      t.gsub! ( /<name>/ ) { actor.name }
      ps[:text] = t
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
      t = MESSAGE_HINT::PARTY_OUT_TEXT.dup
      t.gsub! ( /<name>/ ) { actor.name }
      ps[:text] = t
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
      t = amount>0 ? MESSAGE_HINT::GOLD_GAIN_TEXT : MESSAGE_HINT::GOLD_LOSE_TEXT
      t = t.dup
      t.gsub! ( /<v>/ ) { amount.abs }
      t.gsub! ( /<G>/ ) { Vocab.currency_unit }
      ps[:text] = t
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
      t = amount>0 ? MESSAGE_HINT::ITEM_GAIN_TEXT : MESSAGE_HINT::ITEM_LOSE_TEXT
      t = t.dup
      t.gsub! ( /<icon>/ ) { item.icon_index }
      t.gsub! ( /<name>/ ) { item.name }
      t.gsub! ( /<v>/ )    { amount.abs }
      ps[:text] = t
      MESSAGE_HINT.add(ps, MESSAGE_HINT::DEF_FUNC_ID)
    end
  end
  #--------------------------------------------------------------------------
  # ● 无物品得失提示的减少物品
  #     include_equip : 是否包括装备
  #--------------------------------------------------------------------------
  def eagle_message_hint_lose_item(item, amount, include_equip = false)
    eagle_message_hint_gain_item(item, -amount, include_equip)
  end
end

class Game_Actor
  #--------------------------------------------------------------------------
  # ● 交换物品
  #     new_item : 取出的物品
  #     old_item : 放入的物品
  #--------------------------------------------------------------------------
  def trade_item_with_party(new_item, old_item)
    return false if new_item && !$game_party.has_item?(new_item)
    $game_party.eagle_message_hint_gain_item(old_item, 1)
    $game_party.eagle_message_hint_lose_item(new_item, 1)
    return true
  end
end
