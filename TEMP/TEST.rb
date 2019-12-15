module ITEM_EX
  def self.break_down(item)
    item.note =~ /<break ?(.*?)>/mi
    return parse_item_list_str($1)
  end

  def self.compose(items) # {item => num}
    inputs = []; rules = {} # array => array
    items.each do |item, n|
      item.note.scan(/<compose ?(.*?) ?to ?(.*?)>/mi).each do |params|
        array = parse_item_list_str(params[0], false)
        result = parse_item_list_str(params[1])
        rules[ sort_item_array(array) ] = result
      end
      n.times { inputs.push(get_item_str(item)) }
    end
    return rules[ sort_item_array(inputs) ]
  end

  def self.sort_item_array(array)
    array.sort_by! { |e| [e[0], e.to_i] }
  end

  def self.parse_item_list_str(str, output_hash = true)
    items = output_hash ? [] : {} # item => num
    str.split(" ").each do |s|
      s =~ /(\d+)?([iwa])?(\d+)/i
      num = $1.nil? 1 : $1.to_i
      type = $2.nil? 'i' : $2
      obj = get_item_obj(type, $3.to_i)
      if output_hash
        items[obj] ||= 0
        items[obj] += num
      else
        items.push(get_item_str(obj))
      end
    end
    return items
  end
  #--------------------------------------------------------------------------
  # ● 由类型字符串获取指定对象
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
  # ● 由指定对象获取类型字符串
  #--------------------------------------------------------------------------
  def self.get_item_str(item)
    type = ''
    case item.class
    when RPG::Skill; type = 's'
    when RPG::Item;  type = 'i'
    when RPG::Weapon;type = 'w'
    when RPG::Armor; type = 'a'
    end
    return type + item.id.to_s
  end
end

class Game_Temp
  attr_accessor :item_compose_selected
  # 初始化对象
  alias eagle_item_ex_init initialize
  def initialize
    eagle_item_ex_init
    @item_compose_selected = []
  end
end

class Window_ItemList < Window_Selectable
  # 绘制项目
  alias eagle_item_ex_draw_item draw_item
  def draw_item(index)
    item = @data[index]
    if item
      if $game_temp.item_compose_selected.include?(item)
        rect = item_rect(index)
        rect.width -= 4
        contents.fill_rect(rect, Color.new(0,0,0))
      end
      eagle_item_ex_draw_item(index)
    end
  end
end

class Scene_Item < Scene_ItemBase
  def process_breakdown
    return if !@item_window.active?
    item = @item_window.item
    items = ITEM_EX.break_down(item)
    return if items.empty?
    $game_party.gain_item(item, -1)
    items.each { |i, c| $game_party.gain_item(i, c) }
    @item_window.unselect
    @item_window.refresh
  end

  def process_compose
    return if !@item_window.active?
    $game_temp.item_compose_selected.clear
    @item_compose_mode = true
  end
  def process_compose_end
    $game_temp.item_compose_selected.clear
    @item_compose_mode = false
  end

  # 物品“确定”
  alias eagle_item_ex_on_item_ok on_item_ok
  def on_item_ok
    if @item_compose_mode == true
      item = @item_window.item
      if $game_temp.item_compose_selected.include?(item)
        $game_temp.item_compose_selected.delete(item)
      else
        $game_temp.item_compose_selected.push(item)
      end
    else
      eagle_item_ex_on_item_ok
    end
  end
  # 物品“取消”
  alias eagle_item_ex_on_item_cancel on_item_cancel
  def on_item_cancel
    if @item_compose_mode == true
      process_compose_end
    else
      eagle_item_ex_on_item_cancel
    end
  end

end
