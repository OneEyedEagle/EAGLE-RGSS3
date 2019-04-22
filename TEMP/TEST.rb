module EAGLE
module EQUIP_EX
  # 装备数据库的最大值（数字全部置换为9时）的位数
  #（扩展装备会比该值大1，用于区分）
  #（比如数据库上限69，自动调整后为99，位数是2，则扩展装备的id从100开始）
  #（因此该位数务必比游戏最终定下的装备数量大一些，不然可能会打乱扩展装备）
  #（默认数据库上限999）
  DATABASE_MAX_DIGIT = 3

  PARAMS = [:mhp, :mmp, :atk, :def, :mat, :mdf, :agi, :luk]

  # 生成一个新的附加属性，并返回其id
  # TODO: 处理hash的附加属性
  def self.new_equip_ex(array, id, hash)
    item = array[id].dup
    id_ex = @equips_ex.new_id
    ex = Equip_EX.new(id_ex)
    @equips_ex[id_ex] = ex
    item.eagle_ex = ex
    item
  end
  # 删去指定附加属性
  def self.delete_equip_ex(array, id)
    id1, id2 = get_equip_ex_ids(id)
    @equips_ex.delete(id2)
  end

  # 为指定装备附加属性，并返回其新ID
  def self.set_equip_ex(item, id_ex)

  end

  # 返回扩展装备
  def self.get_equip(item, id_ex)
    ex = get_equip_ex(id_ex)
    return item if ex.nil?
    # 将额外的属性添加入原始物品中
    item_ = item.dup
    item_.eagle_ex = ex
    item_
  end
  # 返回指定的扩展属性对象
  def self.get_equip_ex(id)
    @equips_ex[id] rescue nil
  end
  # 返回原始装备id与扩展属性id
  # TODO: 寻找有效的将物品原id与扩展属性id区分的方式
  def self.get_equip_ids(id)
    # 当id大于数据库上限时，后面部分为该装备内的独立数据索引
    id_s = id.to_s
    # 由数据库最大值，获得id的位数，裁剪出数据库内的索引id
    id1 = (id_s[0...DATABASE_MAX_DIGIT]).to_i
    # 获得额外属性的索引id
    id2 = (id_s[DATABASE_MAX_DIGIT..-1]).to_i
    return id1, id2
  end
  # 构建装备的新ID = 原始id + 扩展属性id
  def self.get_equip_id(id1, id2)
    sprintf("%.#{DATABASE_MAX_DIGIT}d", id1)
  end

  FILE_NAME = "Saves/Equips_EX.rvdata2"
  def self.init
    load_equip_ex rescue init_equip_ex
    # 覆盖原有的读取方法
    def $data_weapons.[](id)
      id1, id2 = EAGLE::EQUIP_EX.get_equip_ids(id)
      item = Array.instance_method(:[]).bind(self).call(id1)
      EAGLE::EQUIP_EX.get_equip(item, id2)
    end
    # 绑定Data_Equip_EX的实例，用于存储全部的额外属性数据
    #def $data_weapons.eagle_ex_array=(array);@eagle_ex_array = array; end
    #$data_weapons.eagle_ex_array = @equips_ex # 此处为引用
  end
  def self.init_equip_ex
    @equips_ex = Data_Equip_EX.new
    save_equip_ex
  end
  def self.save_equip_ex
    File.open(FILE_NAME, "wb") do |file|
      Marshal.dump(@equips_ex, file)
    end
  end
  def self.load_equip_ex
    File.open(FILE_NAME, "rb") do |file|
      @equips_ex = Marshal.load(file)
    end
  end

class Data_Equip_EX # 管理全部的额外属性
  def initialize
    @data = [nil] # Equip_EX的数组（0号位置保留）
    @valid_ids = [] # 全部可以覆盖的位置
  end
  def new_id # 返回一个能够添加额外属性的位置
    return @data.size if @valid_ids.empty?
    @valid_ids.shift
  end
  def delete(id)
    @valid_ids.push(id)
  end
  def [](id)
    @data[id] || nil
  end
  def []=(id, v)
    @data[id] = v
  end
end
class Equip_EX # 存储装备的额外属性的类
  attr_reader :features, :params
  def initialize(id)
    @id = 0 # 0无效，为保留项
    # RPG::BaseItem::Feature.new(code, data_id, value)
    @features = []
    # mhp, mmp, atk, def, mat, mdf, agi, luk
    @params = [0,0,0,0,0,0,0,0]
  end
  EAGLE::EQUIP_EX::PARAMS.each_with_index do |sym, i|
    define_method sym do |i|
      @params[i]
    end
    define_method "#{sym}=" do |i, v|
      @params[i] = v
    end
  end
end # end of class Equip_EX

end # end of module EQUIP_EX
end # end of module EAGLE

class << DataManager
  alias eagle_equip_ex_init  init
  def init
    EAGLE::EQUIP_EX.init
    eagle_equip_ex_init
  end
  alias eagle_equip_ex_save_game save_game
  def save_game(id)
    eagle_equip_ex_save_game(id)
    EAGLE::EQUIP_EX.save_equip_ex
  end
  alias eagle_equip_ex_load_game load_game
  def load_game(id)
    eagle_equip_ex_load_game(id)
    EAGLE::EQUIP_EX.init
  end
end

class RPG::EquipItem < RPG::BaseItem
  def eagle_ex=(obj)
    @eagle_ex = obj # 绑定Equip_EX的实例，用于读取额外属性
  end
  alias features_o features
  def features_ex
    @eagle_ex ? @eagle_ex.features : []
  end
  def features
    features_o + features_ex
  end
  alias params_o params
  def params_ex
    @eagle_ex ? @eagle_ex.params : []
  end
  def params
    return params_o if params_ex.empty?
    params_o.map.with_index { |e, i| e + params_ex[i] }
  end
end
