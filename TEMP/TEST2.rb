# 多背包系统

#【使用方法】

#  $game_party.change_bag("背包名称")
#
#    → 切换成 "背包名称" 的对应背包

#  $game_party.change_bag
#
#    → 切换回默认背包

#=============================================================================
# ■ Data_Bags
#=============================================================================
class Data_Bags
  attr_accessor  :gold, :last_item, :items, :weapons, :armors
  def initialize
    @gold = 0
    @last_item = Game_BaseItem.new
    @items = {}
    @weapons = {}
    @armors = {}
  end
  def items_objects
    @items.keys.sort.collect {|id| $data_items[id] }
  end
  def weapons_objects
    @weapons.keys.sort.collect {|id| $data_weapons[id] }
  end
  def armors_objects
    @armors.keys.sort.collect {|id| $data_armors[id] }
  end
end
#=============================================================================
# ■ Game_Party
#=============================================================================
class Game_Party < Game_Unit
  #--------------------------------------------------------------------------
  # ● 初始化所有物品列表
  #--------------------------------------------------------------------------
  alias eagle_multi_bags_init_all_items init_all_items
  def init_all_items
    eagle_multi_bags_init_all_items
    @bags = {}
    @current_bag_name = nil
  end
  #--------------------------------------------------------------------------
  # ● 切换背包
  #--------------------------------------------------------------------------
  def change_bag(bag_name = nil)
    @current_bag_name = bag_name
    @bags[@current_bag_name] ||= Data_Bags.new if bag_name
  end
  #--------------------------------------------------------------------------
  # ● 获取物品类对应的容器实例
  #--------------------------------------------------------------------------
  alias eagle_multi_bags_item_container item_container
  def item_container(item_class)
    if @current_bag_name and @bags[@current_bag_name]
      b = @bags[@current_bag_name] 
      return b.items   if item_class == RPG::Item
      return b.weapons if item_class == RPG::Weapon
      return b.armors  if item_class == RPG::Armor
      return nil
    end
    eagle_multi_bags_item_container(item_class)
  end
  #--------------------------------------------------------------------------
  # ● 获取物品实例的数组 
  #--------------------------------------------------------------------------
  alias eagle_multi_bags_items items
  def items
    return @bags[@current_bag_name].items_objects if @current_bag_name
    eagle_multi_bags_items
  end
  #--------------------------------------------------------------------------
  # ● 获取武器实例的数组 
  #--------------------------------------------------------------------------
  alias eagle_multi_bags_weapons weapons
  def weapons
    return @bags[@current_bag_name].weapons_objects if @current_bag_name
    eagle_multi_bags_weapons
  end
  #--------------------------------------------------------------------------
  # ● 获取护甲实例的数组 
  #--------------------------------------------------------------------------
  alias eagle_multi_bags_armors armors
  def armors
    return @bags[@current_bag_name].armors_objects if @current_bag_name
    eagle_multi_bags_armors
  end
  #--------------------------------------------------------------------------
  # ● 获取持有金钱
  #--------------------------------------------------------------------------
  def gold 
    return @bags[@current_bag_name].gold if @current_bag_name
    @gold 
  end
  #--------------------------------------------------------------------------
  # ● 增加／减少持有金钱
  #--------------------------------------------------------------------------
  alias eagle_multi_bags_gain_gold gain_gold
  def gain_gold(amount)
    if @current_bag_name
      v = @bags[@current_bag_name].gold
      @bags[@current_bag_name].gold = [[v + amount, 0].max, max_gold].min
      return 
    end
    eagle_multi_bags_gain_gold(amount)
  end
end