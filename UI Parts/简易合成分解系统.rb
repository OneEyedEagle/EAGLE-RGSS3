#==============================================================================
# ■ 简易合成分解系统 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
$imported ||= {}
$imported["EAGLE-ItemEX"] = true
#==============================================================================
# - 2021.11.17.18
#==============================================================================
# - 本插件新增在菜单物品栏中触发的物品分解与合成系统
#--------------------------------------------------------------------------
# ○ 定义：物品标志字符
#--------------------------------------------------------------------------
# - 物品标志字符为本插件所使用的数据类型（字符串），用于传入指定物品的信息，格式为
#
#      物品数目 + 物品类型字符 + 物品ID
#
#   其中 物品数目 可以省略，默认取 1
#   其中 物品类型字符 用 i 代表物品，w 代表武器，a代表护甲
#                可以省略，默认取 i
#   其中 物品ID 为其在数据库中的ID
#
# - 示例：
#     5i1  代表 5 个 1 号物品
#     2w52 代表 2 个 52 号武器
#     a4   代表 1 个 4 号护甲
#     6    代表 1 个 6 号物品
#
#--------------------------------------------------------------------------
# ○ 物品分解
#--------------------------------------------------------------------------
# - 在 数据库-物品/武器/护甲 备注栏中填写下式来定义其分解公式（只能填写一次）
#
#      <break 物品标志字符>
#
#   其中 物品标志字符 可重复填入多组，用空格隔开
#
# - 示例：
#    1号物品备注栏 <break i2 2i3> 则分解成 1个2号物品 与 2个3号物品
#    2号武器备注栏 <break i1 w1> 则分解成 1个1号物品 与 1个1号武器
#
#--------------------------------------------------------------------------
# ○ 物品合成
#--------------------------------------------------------------------------
# - 在 数据库-物品/武器/护甲 备注栏中填写下式，
#   来定义当前物品为材料之一时的合成公式（可多个）
#
#      <compose 物品标志字符 to 物品标志字符>
#
#   其中 物品标志字符 均可重复填入多组，用空格隔开
#
# - 示例：
#    1号物品备注栏 <compose 3i1 i2 to i3> 则输入 3个1号物品 与 1个2号物品时，
#      将合成出 1个3号物品
#    5号物品备注栏 <compose i1 5 to i2 3i3 4> 则输入 1个1号物品 与 1个5号物品时，
#      将合成出 1个2号物品、3个3号物品与1个4号物品
#
# - 由于只读取全部合成材料的备注栏，因此请不要将合成公式写在合成产物的备注栏内
#
#--------------------------------------------------------------------------
# ○ 简易UI
#--------------------------------------------------------------------------
# - 本插件为菜单中的物品栏绑定了简单的按键交互，以进行物品合成与分解
#
# - 物品分解：
#  ·当 trigger_break? 返回true时（默认按下A键），将进入当前选中物品的分解模式
#  ·当按下确定键，将立即执行指定数量物品的分解，并退出分解模式
#  ·当按下上下方向键，将修改分解数量，最大为持有数，最小为0（0时将不会分解）
#  ·当按下取消键，将退出分解模式
#
# - 物品合成：
#  ·当 trigger_compose? 返回true时（默认按下S键），将进入合成模式，
#      并将1个当前物品加入材料列表中
#  ·当再次按下S键，若当前物品未在材料列表中，将其加入材料列表，
#      若已在材料列表中，且未到持有上限，且未到单种材料数目上限，则加入材料列表，
#      否则将其移出列表（若此时材料列表为空，则自动退出合成模式）
#  ·按下确定键，将判定合成，并清空材料列表，刷新物品栏，退出合成模式
#  ·按下取消键，将清空材料列表，退出合成模式
#
# - 局限：
#  ·每种合成材料的输入数目存在上限（值为 COMPOSE_ITEM_MAX）
#  ·合成材料的选择无法跨越类别
#    （供参考的修改方式：单列物品栏，只靠左右键动态切换类别，
#                       便可绕过默认下确认取消键切换类别，以保留当前的合成模式）
#
#==============================================================================

module ITEM_EX
#==============================================================================
# ○ 常量定义
#==============================================================================
  #--------------------------------------------------------------------------
  # ● 每种材料的最大数
  #--------------------------------------------------------------------------
  COMPOSE_ITEM_MAX = 3
  #--------------------------------------------------------------------------
  # ● 满足触发物品分解的条件？
  #--------------------------------------------------------------------------
  def self.trigger_break?
    Input.trigger?(:X)
  end
  #--------------------------------------------------------------------------
  # ● 满足触发物品合成的条件？
  #--------------------------------------------------------------------------
  def self.trigger_compose?
    Input.trigger?(:Y)
  end
  #--------------------------------------------------------------------------
  # ● UI - 分解模式下物品背景颜色
  #--------------------------------------------------------------------------
  COLOR_BG_BREAK = Color.new(255,100,100,130)
  #--------------------------------------------------------------------------
  # ● UI - 合成模式下物品背景颜色
  #--------------------------------------------------------------------------
  COLOR_BG_COMPOSE = Color.new(255,255,255,130)

#==============================================================================
# ○ Core
#==============================================================================
  #--------------------------------------------------------------------------
  # ● 物品分解
  #  返回： { item => num }
  #--------------------------------------------------------------------------
  def self.break_down(item)
    return if item.nil?
    item.note =~ /<break ?(.*?)>/mi
    return parse_item_list_str($1) if $1
    return {}
  end
  #--------------------------------------------------------------------------
  # ● 物品合成
  #  输入： { item => num }
  #  返回： { item => num }
  #--------------------------------------------------------------------------
  def self.compose(items)
    inputs = []; rules = {} # { array => hash }
    items.each do |item, n| # 在每个材料的备注栏中搜索规则
      next if n == 0
      item.note.scan(/<compose ?(.*?) ?to ?(.*?)>/mi).each do |params|
        array = parse_item_list_str(params[0], false)
        result = parse_item_list_str(params[1])
        rules[ sort_item_array(array) ] = result
      end
      n.times { inputs.push(get_item_str(item)) }
    end
    # inputs = [ "i1", "i1", "i1" ] # 其中数量拆开
    return rules[ sort_item_array(inputs) ] # { item => num } or nil
  end
  #--------------------------------------------------------------------------
  # ● 物品标志字符数组排序
  #--------------------------------------------------------------------------
  def self.sort_item_array(array)
    array.sort_by! { |e| [e[0], e.to_i] }
  end
  #--------------------------------------------------------------------------
  # ● 解析物品标志字符
  #--------------------------------------------------------------------------
  def self.parse_item_list_str(str, output_hash = true)
    items = output_hash ? {} : []
    str.split(" ").each do |s|
      s =~ /(\d+)?([iwa])?(\d+)/i
      num = $1.nil? ? 1 : $1.to_i
      type = $2.nil? ? 'i' : $2
      obj = get_item_obj(type, $3.to_i)
      if output_hash
        items[obj] ||= 0
        items[obj] += num
      else
        num.times { items.push(get_item_str(obj, 1)) }
      end
    end
    return items
  end
#==============================================================================
# ○ 通用
#==============================================================================
  #--------------------------------------------------------------------------
  # ● 由物品标志字符获取指定对象
  #--------------------------------------------------------------------------
  def self.get_item_obj(type, id)
    case type
    when 's'; obj = $data_skills[id]
    when 'i'; obj = $data_items[id]
    when 'w'; obj = $data_weapons[id]
    when 'a'; obj = $data_armors[id]
    end
    return obj
  end
  #--------------------------------------------------------------------------
  # ● 由指定对象获取物品标志字符
  #--------------------------------------------------------------------------
  def self.get_item_str(item, num = 1)
    _type = ""
    c = item.class
    _type += "s" if c == RPG::Skill
    _type += "i" if c == RPG::Item
    _type += "w" if c == RPG::Weapon
    _type += 'a' if c == RPG::Armor
    t = _type + item.id.to_s
    t = num.to_s + t if num != 1
    return t
  end
#==============================================================================
# ○ Scene
#==============================================================================
  #--------------------------------------------------------------------------
  # ● 绑定物品窗口
  #--------------------------------------------------------------------------
  def self.item_window=(w)
    @item_window = w
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def self.update
    f1 = $game_temp.item_break?
    f2 = $game_temp.item_compose?
    if @item_window.active && !f1 && !f2
      ITEM_EX.activate_break if trigger_break?
      ITEM_EX.process_compose if trigger_compose?
      return
    end
    return ITEM_EX.update_break if f1
    return ITEM_EX.process_compose if f2 && trigger_compose?
  end
  #--------------------------------------------------------------------------
  # ● 进入物品分解
  #--------------------------------------------------------------------------
  def self.activate_break
    item = @item_window.item
    items = ITEM_EX.break_down(item)
    return Sound.play_buzzer if items.empty?
    $game_temp.item_break_selected = item
    $game_temp.item_break_num = 1
    @item_window.deactivate
    @item_window.redraw_current_item
    Sound.play_ok
  end
  #--------------------------------------------------------------------------
  # ● 更新物品分解
  #--------------------------------------------------------------------------
  def self.update_break
    item = $game_temp.item_break_selected
    if Input.trigger?(:C)
      Sound.play_ok
      process_break
    elsif Input.trigger?(:B)
      Sound.play_cancel
      finish_break
    elsif Input.trigger?(:UP) || trigger_break?
      Sound.play_cursor
      change_break_num(+1)
    elsif Input.trigger?(:DOWN)
      Sound.play_cursor
      change_break_num(-1)
    end
  end
  #--------------------------------------------------------------------------
  # ● 修改物品分解数量
  #--------------------------------------------------------------------------
  def self.change_break_num(v)
    item = $game_temp.item_break_selected
    n = $game_temp.item_break_num
    max = $game_party.item_number(item)
    n2 = n + v
    n2 = max if n2 < 1
    n2 = 1 if n2 > max
    $game_temp.item_break_num = n2
    @item_window.redraw_current_item
  end
  #--------------------------------------------------------------------------
  # ● 结束物品分解
  #--------------------------------------------------------------------------
  def self.finish_break
    $game_temp.item_break_selected = nil
    @item_window.activate.refresh
  end
  #--------------------------------------------------------------------------
  # ● 处理物品分解
  #--------------------------------------------------------------------------
  def self.process_break
    item = $game_temp.item_break_selected
    items = ITEM_EX.break_down(item)
    return if items.empty?
    num = $game_temp.item_break_num
    return finish_break if num == 0
    index = @item_window.index
    $game_party.gain_item(item, -num)
    items.each { |i, c| $game_party.gain_item(i, c * num) }
    finish_break
    @item_window.index = index
  end
  #--------------------------------------------------------------------------
  # ● 处理物品合成
  #--------------------------------------------------------------------------
  def self.process_compose
    item = @item_window.item
    n = $game_temp.selected_item_num(item)
    if n > 0
      if n < COMPOSE_ITEM_MAX && n < $game_party.item_number(item)
        $game_temp.item_compose_selected[item] += 1
      else
        $game_temp.item_compose_selected.delete(item)
        process_compose_cancel if $game_temp.item_compose_selected.empty?
      end
    else
      $game_temp.item_compose_selected[item] = 1
    end
    @item_window.redraw_current_item
    Sound.play_cursor
  end
  #--------------------------------------------------------------------------
  # ● 物品合成确认
  #--------------------------------------------------------------------------
  def self.process_compose_ok
    items = ITEM_EX.compose($game_temp.item_compose_selected)
    if items
      $game_temp.item_compose_selected.each do |i, c|
        $game_party.gain_item(i, -c)
      end
      items.each { |i, c| $game_party.gain_item(i, c) }
    else
      Sound.play_buzzer
    end
    process_compose_cancel
  end
  #--------------------------------------------------------------------------
  # ● 物品合成取消
  #--------------------------------------------------------------------------
  def self.process_compose_cancel
    $game_temp.item_compose_selected.clear
    @item_window.refresh
    @item_window.activate
  end
end
#==============================================================================
# ○ Game_Temp
#==============================================================================
class Game_Temp
  attr_accessor  :item_break_selected, :item_break_num
  attr_accessor  :item_compose_selected
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  alias eagle_item_ex_init initialize
  def initialize
    eagle_item_ex_init
    @item_break_selected = nil
    @item_break_num = 0
    @item_compose_selected = {}
  end
  #--------------------------------------------------------------------------
  # ● 处于分解模式？
  #--------------------------------------------------------------------------
  def item_break?
    @item_break_selected != nil
  end
  #--------------------------------------------------------------------------
  # ● 处于合成模式？
  #--------------------------------------------------------------------------
  def item_compose?
    !@item_compose_selected.empty?
  end
  #--------------------------------------------------------------------------
  # ● 获取指定材料数目
  #--------------------------------------------------------------------------
  def selected_item_num(item)
    @item_compose_selected[item] || 0
  end
end
#==============================================================================
# ○ Window_ItemList
#==============================================================================
class Window_ItemList < Window_Selectable
  #--------------------------------------------------------------------------
  # ● 绘制项目
  #--------------------------------------------------------------------------
  alias eagle_item_ex_draw_item draw_item
  def draw_item(index)
    item = @data[index]
    if item
      c = nil
      c = ITEM_EX::COLOR_BG_BREAK if $game_temp.item_break_selected == item
      c = ITEM_EX::COLOR_BG_COMPOSE if $game_temp.selected_item_num(item) > 0
      if c
        rect = item_rect(index)
        contents.gradient_fill_rect(rect, Color.new(0,0,0,0), c)
      end
    end
    eagle_item_ex_draw_item(index)
  end
  #--------------------------------------------------------------------------
  # ● 绘制物品个数
  #--------------------------------------------------------------------------
  alias eagle_item_ex_draw_item_number draw_item_number
  def draw_item_number(rect, item)
    if $game_temp.item_break? && $game_temp.item_break_selected == item
      n = $game_temp.item_break_num
      t = sprintf("%2d - %d", $game_party.item_number(item), n)
      draw_text(rect, t, 2)
      return
    end
    if $game_temp.item_compose?
      n = $game_temp.selected_item_num(item)
      if n > 0
        t = sprintf("%d / %2d", n, $game_party.item_number(item))
        draw_text(rect, t, 2)
        return
      end
    end
    eagle_item_ex_draw_item_number(rect, item)
  end
end
#==============================================================================
# ○ Scene_Item
#==============================================================================
class Scene_Item < Scene_ItemBase
  #--------------------------------------------------------------------------
  # ● 开始
  #--------------------------------------------------------------------------
  alias eagle_item_ex_start start
  def start
    eagle_item_ex_start
    ITEM_EX.item_window = @item_window
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
    ITEM_EX.update
  end
  #--------------------------------------------------------------------------
  # ● 物品“确定”
  #--------------------------------------------------------------------------
  alias eagle_item_ex_on_item_ok on_item_ok
  def on_item_ok
    if $game_temp.item_compose?
      ITEM_EX.process_compose_ok
    else
      eagle_item_ex_on_item_ok
    end
  end
  #--------------------------------------------------------------------------
  # ● 物品“取消”
  #--------------------------------------------------------------------------
  alias eagle_item_ex_on_item_cancel on_item_cancel
  def on_item_cancel
    if $game_temp.item_compose?
      ITEM_EX.process_compose_cancel
    else
      eagle_item_ex_on_item_cancel
    end
  end
end
