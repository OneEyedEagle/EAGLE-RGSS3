#=============================================================================
# ■ 装备附加属性-核心  by 老鹰（http://oneeyedeagle.lofter.com/）
#=============================================================================
$imported ||= {}
$imported["EAGLE-EquipEXCore"] = true
#=============================================================================
# - 2019.4.28.10 修复已装备不会被判定持有的bug
#=============================================================================
# - 本插件新增了一组处理装备附加属性的核心方法
# - 本插件已为 $data_weapons 与 $data_armors 编写了绑定，可以适用于该两类
#--------------------------------------------------------------------------
# ○ 操作流程
#--------------------------------------------------------------------------
# - 生成一个含有指定信息的附加属性实例，并返回它的序号
#     id_ex = EQUIP_EX.new_ex(item, attrs)
#
# - 为指定装备item追加一个id_ex号的附加属性，并返回附加后的装备item_ex
#     item_ex = EQUIP_EX.get_equip(item, id_ex)
#
# -【可选/节约存储空间】删去不再需要的指定装备的附加属性
#    （已判定是否持有相同附加属性的装备，若仍然持有，则不会删除）
#     EQUIP_EX.delete_ex(item_ex)
#
#--------------------------------------------------------------------------
# ○ attrs 附加属性数组解析
#--------------------------------------------------------------------------
# - 新增一个属性调整：
#     [sym/id, value] → [属性符号/属性ID, 属性增减值]
#   · 具体 属性符号/属性ID 可见 PARAMS_TO_ID 常量，与默认八维数据保持一致
#
# - 新增一个特性：
#     [code, data_id, value] → [代码, 数据ID, 值]
#   · 该特性为数据库中右上角“特性”窗内容
#   · code 可以参照 Game_BattlerBase类 开头的 常量（特性）列表中的值
#   · data_id 为第一个下拉选择框的选项所对应的id
#     （部分从1开始，部分从0开始，推荐利用 p item.features 对照查看理解）
#   · value 为部分项所带有的第二个数值输入框的值
#     （若数据库中为百分数，此处需手动转换为 0.0~1.0 范围内，且会强制保留2位小数）
#
# - 示例：
#     attrs = [ [:mhp, +5], [:luk, -1], [22, 0, -0.1] ]
#    → 附加属性组：最大生命值+5，幸运-1，物理命中几率-10%
#
#--------------------------------------------------------------------------
# ○ 可能问题
#--------------------------------------------------------------------------
# - 当需要进行装备实例的排序时，请调用其 id_o 方法获取装备在数据库中的 id
#--------------------------------------------------------------------------
# ○ 核心
#--------------------------------------------------------------------------
# - 对于每一个存档，为每一件装备新增了一个存储它专用的附加属性实例的hash
# - 将装备的id进行了扩展，变更为 数据库id_d+附加属性实例的id_ex
#   （如：数据库id为11的武器，其追加的附加属性实例id为23，则结合附加属性数量上限，
#         该自定义武器最后的id为11023）
# - 已为默认 Game_Party 中获取持有武器护甲实例的方法编写新的排序规则，
#   确保具有相同原型的装备会排放在一起
#=============================================================================
module EQUIP_EX
  #--------------------------------------------------------------------------
  # ○ 常量：与存档文件相对应的附加属性的文件
  #  其中 %d 将被替换成存档文件的ID号（从1开始）
  #--------------------------------------------------------------------------
  FILE_NAME = "Saves/Equip_EXs_%02d.rvdata2"
  #--------------------------------------------------------------------------
  # ○ 常量：每个装备的附加属性的存储数目上限的位数
  #--------------------------------------------------------------------------
  #（推荐：该位数 ≥ 游戏装备数量上限的位数，不然可能出现错位BUG）
  EX_MAX_DIGIT = 3
  #--------------------------------------------------------------------------
  # ○ 常量：每次生成新的附加属性实例前，是否检索并利用具有相同attrs实例的id_ex？
  #  当设置为true时，相同的附加属性（顺序忽略）将返回相同的id_ex
  #  但当装备所对应的附加属性数组中的实例数目较大时，检索可能消耗较多资源
  #--------------------------------------------------------------------------
  EX_SINGLE_OBJ = true
  #--------------------------------------------------------------------------
  # ○ 常量：属性与对应ID
  #--------------------------------------------------------------------------
  PARAMS_TO_ID = {
    :mhp => 0, :mmp => 1, :atk => 2, :def => 3,
    :mat => 4, :mdf => 5, :agi => 6, :luk => 7
  }
  #--------------------------------------------------------------------------
  # ○ 获取属性在数组中的ID
  #--------------------------------------------------------------------------
  def self.get_param_id(param)
    param.is_a?(Symbol) ? PARAMS_TO_ID[param] : param
  end
  #--------------------------------------------------------------------------
  # ○ 获取物品的类型符号
  #  返回nil - 该item不可以进行附加属性设置
  #--------------------------------------------------------------------------
  def self.get_sym(item)
    return :weapon if item.class == RPG::Weapon
    return :armor  if item.class == RPG::Armor
    return nil
  end
  #--------------------------------------------------------------------------
  # ○ 指定附加属性的装备存在？
  #--------------------------------------------------------------------------
  def self.exist_equip_ex?(item)
    return $game_party.weapon_ids.include?(item.id) if item.class == RPG::Weapon
    return $game_party.armor_ids.include?(item.id) if item.class == RPG::Armor
    return true
  end

  #--------------------------------------------------------------------------
  # ○ 尝试为指定装备增加附加属性
  #  返回：装备实例
  #--------------------------------------------------------------------------
  def self.get_equip(item, id_ex)
    return item if !can_ex?(item)
    ex = get_ex(item, id_ex)
    return item if ex.nil?
    item_ = item.dup
    item_.eagle_ex = ex
    item_
  end
  #--------------------------------------------------------------------------
  # ○ 指定物品能够附加扩展？
  #--------------------------------------------------------------------------
  def self.can_ex?(item)
    get_sym(item) != nil
  end
  #--------------------------------------------------------------------------
  # ○ 获取指定序号的附加属性实例
  #--------------------------------------------------------------------------
  def self.get_ex(item, id_ex)
    @equips_exs.bind(item)
    @equips_exs[id_ex]
  end
  #--------------------------------------------------------------------------
  # ○ 生成指定装备可用的附加属性实例
  #  返回：附加属性实例的序号id_ex
  #--------------------------------------------------------------------------
  def self.new_ex(item, attrs = [])
    return 0 if attrs.empty?
    # 强制将小数类型的value转换成2位小数
    attrs.each_with_index do |a, i|
      attrs[i][-1] = a[-1].round(2) if a[-1].abs < 1
    end
    @equips_exs.bind(item)
    if EX_SINGLE_OBJ
      id_ex = @equips_exs.find(attrs)
      return id_ex if id_ex
    end
    id_ex = @equips_exs.new_id_ex
    return 0 if id_ex <= 0
    @equips_exs[id_ex] = Data_Equip_EX.new(id_ex, attrs)
    id_ex
  end
  #--------------------------------------------------------------------------
  # ○ 查找指定装备中有指定属性的附加属性实例的id_ex
  #  返回：附加属性实例的序号id_ex（未找到时返回nil）
  #--------------------------------------------------------------------------
  def self.find_ex(item, attrs = [])
    @equips_exs.bind(item)
    return @equips_exs.find(attrs)
  end
  #--------------------------------------------------------------------------
  # ○ 删去装备所含有的附加属性
  #--------------------------------------------------------------------------
  def self.delete_ex(item)
    return if exist_equip_ex?(item)
    id_d, id_ex = get_equip_ids(item.id)
    return if id_ex == 0
    @equips_exs.bind(item)
    @equips_exs.delete(id_ex)
  end

  #--------------------------------------------------------------------------
  # ○ 获取含有附加属性的装备的扩展序号
  #（若设置上限位数为3，则当默认装备id为2，附加属性id为1，则新装备id为2001）
  #  id_d：数据库中装备的序号id_d
  #  id_ex：附加属性实例的序号id_ex
  #--------------------------------------------------------------------------
  def self.get_equip_id(id_d, id_ex)
    id = sprintf("%d%0#{EX_MAX_DIGIT}d", id_d, id_ex)
    id.to_i
  end
  #--------------------------------------------------------------------------
  # ○ 分解装备的扩展序号
  #  id：含有附加属性的装备的扩展序号
  #  返回：数据库中装备的序号id_d、附加属性实例的序号id_ex
  #--------------------------------------------------------------------------
  def self.get_equip_ids(id)
    # 若小于数据库上限，则说明不含有附加属性
    return id, 0 if id < 10**EX_MAX_DIGIT
    # 当id大于数据库上限时，后面部分为该装备内的独立数据索引
    id_s = id.to_s
    # 获得额外属性的索引id
    id_ex = (id_s[-EX_MAX_DIGIT..-1]).to_i
    id_s[-EX_MAX_DIGIT..-1] = ''
    # 获得数据库中的id
    id_d = id_s.to_i
    return id_d, id_ex
  end
#=============================================================================
# ○ 文件管理
#=============================================================================
  #--------------------------------------------------------------------------
  # ○ 数据初始化
  #--------------------------------------------------------------------------
  def self.init
    @equips_exs = Equips_EXs.new
  end
  #--------------------------------------------------------------------------
  # ○ 获取指定存档序号对应的附加属性文件名称
  #--------------------------------------------------------------------------
  def self.get_exs_filename(index)
    sprintf(FILE_NAME, index+1)
  end
  #--------------------------------------------------------------------------
  # ○ 存储附加属性文件
  #--------------------------------------------------------------------------
  def self.save_equip_exs(index)
    File.open(get_exs_filename(index), "wb") do |file|
      Marshal.dump(@equips_exs, file)
    end
  end
  #--------------------------------------------------------------------------
  # ○ 读取附加属性文件
  #--------------------------------------------------------------------------
  def self.load_equip_exs(index)
    File.open(get_exs_filename(index), "rb") do |file|
      @equips_exs = Marshal.load(file)
    end rescue init
  end
#=============================================================================
# ○ 管理所有类的装备的附加属性的类
#=============================================================================
class Equips_EXs
  #--------------------------------------------------------------------------
  # ○ 初始化
  #--------------------------------------------------------------------------
  def initialize
    @data = {} # 物品类型 => Equips_EX
    @item_class = nil # 当前绑定的物品类型
  end
  #--------------------------------------------------------------------------
  # ○【必须】绑定物品实例
  #--------------------------------------------------------------------------
  def bind(item)
    return if item.nil?
    @item_class = EQUIP_EX.get_sym(item)
    return if @item_class == nil
    @data[@item_class] ||= Equips_EX.new
    data.bind(item)
  end
  #--------------------------------------------------------------------------
  # ○ 绑定成功？
  #--------------------------------------------------------------------------
  def bind?
    @item_class != nil
  end
  #--------------------------------------------------------------------------
  # ○ 处理对应列表的内容
  #--------------------------------------------------------------------------
  def data
    @data[@item_class]
  end
  def new_id_ex
    data.new_id_ex
  end
  def delete(id_ex)
    data.delete(id_ex) if bind?
  end
  def find(attrs)
    data.find(attrs)
  end
  def [](i)
    data[i]
  end
  def []=(i, v)
    data[i] = v if bind?
  end
end
#=============================================================================
# ○ 管理某一类装备的全部附加属性的类
#=============================================================================
class Equips_EX
  #--------------------------------------------------------------------------
  # ○ 初始化
  #--------------------------------------------------------------------------
  def initialize
    @data = {} # 物品id => Data_Equip_EX的数组（0号位置保留）
    @valid_ids = {} # 物品id => 全部可以覆盖的位置
    @item_id = 0
  end
  #--------------------------------------------------------------------------
  # ○【必须】绑定物品实例
  #--------------------------------------------------------------------------
  def bind(item)
    return @item_id = 0 if item.nil?
    @item_id = item.id
    @data[@item_id] ||= [nil] # 0号位置保留为nil
    @valid_ids[@item_id] ||= []
  end
  #--------------------------------------------------------------------------
  # ○ 内容简写
  #--------------------------------------------------------------------------
  def data; @data[@item_id]; end # 获取当前物品所对应的Data_Equip_EX数组
  def data=(v); @data[@item_id] = v; end
  def valid_ids; @valid_ids[@item_id]; end
  #--------------------------------------------------------------------------
  # ○ 获取一个新的可添加位置
  #--------------------------------------------------------------------------
  def new_id_ex
    if valid_ids.empty?
      s = data.size
      if s >= 10**EQUIP_EX::EX_MAX_DIGIT
        p "【警告】当前#{@item_id}号装备的附加属性类型数量大于预设上限！无法生成！"
        return 0
      end
      return s
    end
    valid_ids.shift
  end
  #--------------------------------------------------------------------------
  # ○ 删除指定位置
  #--------------------------------------------------------------------------
  def delete(id)
    valid_ids.push(id)
  end
  #--------------------------------------------------------------------------
  # ○ 查找具有相同attrs的附加属性实例所在位置
  #  返回 nil 代表未找到相同的
  #--------------------------------------------------------------------------
  def find(attrs)
    return 0 if attrs.empty?
    data.each { |d| return d.id if d == attrs }
    return nil
  end
  #--------------------------------------------------------------------------
  # ○ 读取
  #--------------------------------------------------------------------------
  def [](id)
    data[id] || nil
  end
  #--------------------------------------------------------------------------
  # ○ 覆盖
  #--------------------------------------------------------------------------
  def []=(id, v)
    data[id] = v
  end
end
#=============================================================================
# ○ 存储附加属性的数据类
#=============================================================================
class Data_Equip_EX
  attr_accessor :id
  attr_reader   :attrs, :features, :params
  #--------------------------------------------------------------------------
  # ○ 初始化
  #--------------------------------------------------------------------------
  def initialize(id, attrs = [])
    @id = id # 0无效，为保留项
    @attrs = attrs
    @features = []
    @params = [0,0,0,0,0,0,0,0]
    @attrs.each { |a| parse(a) }
  end
  #--------------------------------------------------------------------------
  # ○ 比较
  #--------------------------------------------------------------------------
  def ==(attrs)
    @attrs.sort_by(&:hash) == attrs.sort_by(&:hash)
  end
  #--------------------------------------------------------------------------
  # ○ 添加一个新attr
  #  属性：[sym/id, value]
  #  特性：[code, data_id, value]
  #--------------------------------------------------------------------------
  def add(attr)
    @attrs.push(attr)
    parse(attr)
  end
  #--------------------------------------------------------------------------
  # ○ 解析attr数组项
  #--------------------------------------------------------------------------
  def parse(attr)
    return add_feature(attr[0], attr[1], attr[2]) if attr.size == 3
    @params[EQUIP_EX.get_param_id(attr[0])] += attr[1] if attr.size == 2
  end
  #--------------------------------------------------------------------------
  # ○ 新增特性
  #--------------------------------------------------------------------------
  def add_feature(code, data_id, value)
    @features.push(RPG::BaseItem::Feature.new(code, data_id, value))
  end
  #--------------------------------------------------------------------------
  # ○ 设置属性方法
  # （按序）mhp, mmp, atk, def, mat, mdf, agi, luk
  #--------------------------------------------------------------------------
  EQUIP_EX::PARAMS_TO_ID.each do |sym_, id_|
    define_method sym_ do
      @params[id_]
    end
    define_method "#{sym_}=" do |v|
      @params[id_] = v
    end
  end
end
end # end of module EQUIP_EX
#=============================================================================
# ● DataManager
#=============================================================================
class << DataManager
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  alias eagle_equip_ex_init  init
  def init
    eagle_equip_ex_init
    EQUIP_EX.init
    bind
  end
  #--------------------------------------------------------------------------
  # ○ 绑定新的读取方法
  #--------------------------------------------------------------------------
  def bind
    def $data_weapons.[](id)
      id_d, id_ex = EQUIP_EX.get_equip_ids(id)
      item = Array.instance_method(:[]).bind(self).call(id_d)
      EQUIP_EX.get_equip(item, id_ex)
    end
    def $data_armors.[](id)
      id_d, id_ex = EQUIP_EX.get_equip_ids(id)
      item = Array.instance_method(:[]).bind(self).call(id_d)
      EQUIP_EX.get_equip(item, id_ex)
    end
  end
  #--------------------------------------------------------------------------
  # ● 存档
  #--------------------------------------------------------------------------
  alias eagle_equip_ex_save_game save_game
  def save_game(index)
    eagle_equip_ex_save_game(index)
    EQUIP_EX.save_equip_exs(index)
  end
  #--------------------------------------------------------------------------
  # ● 读取
  #--------------------------------------------------------------------------
  alias eagle_equip_ex_load_game load_game
  def load_game(index)
    eagle_equip_ex_load_game(index)
    EQUIP_EX.load_equip_exs(index)
  end
end
#=============================================================================
# ● RPG::EquipItem
#=============================================================================
class RPG::EquipItem < RPG::BaseItem
  attr_reader  :eagle_ex
  #--------------------------------------------------------------------------
  # ○ 设置附加属性
  #--------------------------------------------------------------------------
  def eagle_ex=(obj)
    @eagle_ex = obj # 绑定Equip_EX的实例，用于读取额外属性
    @eagle_id = EQUIP_EX.get_equip_id(self.id_o, @eagle_ex.id) # 扩展ID
  end
  #--------------------------------------------------------------------------
  # ● 获取ID
  #--------------------------------------------------------------------------
  alias id_o id
  def id
    @eagle_id ? @eagle_id : id_o
  end
  #--------------------------------------------------------------------------
  # ○ 获取附加特性
  #--------------------------------------------------------------------------
  alias features_o features
  def features_ex
    @eagle_ex ? @eagle_ex.features : []
  end
  #--------------------------------------------------------------------------
  # ● 获取特性
  #--------------------------------------------------------------------------
  def features
    features_o + features_ex
  end
  #--------------------------------------------------------------------------
  # ○ 获取附加属性
  #--------------------------------------------------------------------------
  alias params_o params
  def params_ex
    @eagle_ex ? @eagle_ex.params : []
  end
  #--------------------------------------------------------------------------
  # ● 获取属性
  #--------------------------------------------------------------------------
  def params
    return params_o if params_ex.empty?
    params_o.map.with_index { |e, i| e + params_ex[i] }
  end
end
#=============================================================================
# ● Game_Party
#=============================================================================
class Game_Party < Game_Unit
  #--------------------------------------------------------------------------
  # ○ 获取所持有的武器类别的全部id（含已装备的）
  #--------------------------------------------------------------------------
  def weapon_ids
    @weapons.keys + members.collect {|a| a.weapons.collect {|e| e.id }}.flatten
  end
  #--------------------------------------------------------------------------
  # ○ 获取所持有的护甲类别的全部id（含已装备的）
  #--------------------------------------------------------------------------
  def armor_ids
    @armors.keys + members.collect {|a| a.armors.collect {|e| e.id }}.flatten
  end
  #--------------------------------------------------------------------------
  # ●（覆盖）获取武器实例的数组
  #--------------------------------------------------------------------------
  def weapons
    max = 10**EQUIP_EX::EX_MAX_DIGIT
    ids = @weapons.keys.sort_by {|id| id > max ? id / max : id }
    ids.collect {|id| $data_weapons[id] }
  end
  #--------------------------------------------------------------------------
  # ●（覆盖）获取护甲实例的数组
  #--------------------------------------------------------------------------
  def armors
    max = 10**EQUIP_EX::EX_MAX_DIGIT
    ids = @armors.keys.sort_by {|id| id > max ? id / max : id }
    ids.collect {|id| $data_armors[id] }
  end
end
