#=============================================================================
# ■ Add-On 属性随机规则  by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【装备附加属性-核心 by老鹰】之下
#=============================================================================
$imported ||= {}
$imported["EAGLE-EquipEXRule"] = true
#=============================================================================
# - 2019.5.7.17 新增随机品质
#=============================================================================
# - 本插件依据装备备注栏中设置的规则，生成随机的attrs数组
# - 生成的 attrs 数组可用于 装备附加属性-核心 by老鹰 中生成附加属性实例
#--------------------------------------------------------------------------
# ○ 设置规则
#--------------------------------------------------------------------------
#   在数据库武器/护甲的备注栏中按格式填写下列规则：
#   （有先后读取顺序，且出于规则的唯一性，后读入的同类型规则会覆盖先读入的）
#
# - 设置品质规则
#   （只会缩放附加属性、特性，而不会缩放VA数据库中装备的属性特性）
#   （若未设置该类型下的任意项，将取品质@lv为0）
#       <exr lvt t_id {cond}> → 当满足cond条件时，用t_id号的品质模板覆盖当前设置
#       <exr lv lv_id {prob}> → 直接指定lv_id号品质的概率因子prob（eval字符串）
#    · cond 解析：被eval后返回的布尔值为true时，该项才会生效
#        可以用 s 代替 $game_switches，可以用 v 代替 $game_variables
#
# - 设置数目规则
#       <exr c max {value}> → 设置总共随机属性有value个（最多max个）
#                           （若未设置该项，将取通用设置）
#    · value 解析：被eval后返回的值将作为该项的值
#        可以用 rand 来获取 0~1 的随机小数
#        可以用 rand(i) 来获取 0~i-1 的随机正整数
#        可以用 s 代替 $game_switches，可以用 v 代替 $game_variables
#        可以用 @lv 来获取当前装备定下的品质等级
#
# - 设置数据库属性特性规则
#       <exr t id {cond}> → 当满足cond条件时，用id号模板的规则覆盖当前的对应项
#       <exr sym prob {value}> → 添加一个属性sym的 [prob, value] 规则
#       <exr id_id prob {value}> → 添加一个特性id_id的 [prob, value] 规则
#    · sym 解析：Data_Equip_EX类中含有相同名称的方法的字符串
#        已经处理默认的八维属性 mhp, mmp, atk, def, mat, mdf, agi, luk
#    · prob 解析：概率因子，代表该项被随机选中的概率因子，全部因子之和为分母
#        若 prob 的值为 0，则表示该条一定会被只选中一次（无视上限，不计算占用）
#    · id_id 解析：由特性的code与data_id合并而成，具体请参考 装备附加属性-核心
#    · value 解析：被eval后返回的值将作为该项的（同上一部分中的value）
#        若最终返回值为整数 0，则对应的属性会被自动删去（不计算占用）
#
# - 设置扩展规则
#       <exr ex-sym prob {value_s}> → 添加一个概率因子为prob的扩展sym规则
#    · 若该规则被随机中，会将 [:ex, :sym, v] 放入attrs数组
#       其中 v = EQUIP_EX.ex_attr_value(:sym, value_s)，可alias该方法进行自定义
#    · 默认 v = eval(value_s)
#--------------------------------------------------------------------------
# ○ 应用规则
#--------------------------------------------------------------------------
# - 依据item备注栏中所设置规则，生成attrs数组
#   若传入 uniq 的值为 true，则返回的attrs数组中不会有重复属性（默认true）
#     attrs = EQUIP_EX.new_attrs(item, uniq=true)
#
# - 示例：
#     在1号武器装备的备注栏中填写：
#       <exr c 2 {2}><exr t 1 {true}>
#       <exr atk 1 {1+rand(2)}><exr 22_0 2 {-0.2}>
#    → 设置属性数目为2、读取1号模板的设置覆盖当前、
#      覆盖设置atk的因子为1值为1+rand(2)、覆盖设置命中率因子为2值为-0.2
#    → 在调用 attrs = EQUIP_EX.new_attrs($data_weapons[1]) 后的可能返回组合：
#       [[:atk, 1], [22, 0, -0.2]] 或 [[22, 0, -0.2], [:atk, 2]]
#--------------------------------------------------------------------------
# ○ 特别说明
#--------------------------------------------------------------------------
# - 由于并没做多余判定，所以item只要是有note方法（数据库中有备注栏）的对象即可
#=============================================================================
module EQUIP_EX
  #--------------------------------------------------------------------------
  # ○ 常量：品质预设
  #--------------------------------------------------------------------------
  LEVELS = {
    # 0为默认的品质 - 无
    0 => {
      :name => "%s", # %s将替换成装备的数据库名称
      :s_pp => 1, # 正数属性的缩放倍率
      :s_pf => 1, # 正数特性的缩放倍率
      :s_np => 1, # 负数属性的缩放倍率
      :s_nf => 1, # 负数特性的缩放倍率
    }
  }
  LEVELS[1] = {
    :name => "%s·残次", # broken
    :s_pp => 0.8, :s_pf => 0.8,
  }
  LEVELS[2] = {
    :name => "%s·普通", # common
    :s_pp => 1.0, :s_pf => 1.0,
  }
  LEVELS[3] = {
    :name => "%s·精制", # rare
    :s_pp => 1.5, :s_pf => 1.5,
  }
  LEVELS[4] = {
    :name => "%s·传奇", # legendary
    :s_pp => 3, :s_pf => 3,
  }
  #--------------------------------------------------------------------------
  # ○ 常量：品质随机规则模板
  #--------------------------------------------------------------------------
  LEVEL_TEMPLATE = {} # 模板id => {品质id => 概率因子string}
  LEVEL_TEMPLATE[0] = { 1 => "13", 2 => "23", 3 => "13", 4 => "1" }
  #--------------------------------------------------------------------------
  # ○ 常量：预设随机属性数目上限
  #--------------------------------------------------------------------------
  ATTRS_MAX = 4
  #--------------------------------------------------------------------------
  # ○ 常量：预设随机属性数目文本
  #--------------------------------------------------------------------------
  ATTRS_COUNT_TEXT = "4"
  #--------------------------------------------------------------------------
  # ○ 常量：数据库attr规则模板
  #--------------------------------------------------------------------------
  TEMPLATES = {}
  TEMPLATES[0] = { # 模板id
    :atk => [2, "2+rand(2)"], # sym => [概率因子（正整数）, eval值]
    "22_0" => [1, "-0.5*rand"], # code_id + '_' + data_id => [概率因子, eval值]
  }

  #--------------------------------------------------------------------------
  # ○ 基于物品note所含规则生成具有n条attr的数组
  #--------------------------------------------------------------------------
  def self.new_attrs(item, uniq = true)
    attrs_count, rule_hash, quality_hash = get_c_and_rules(item)
    return [] if rule_hash.empty?
    attrs = []; @lv = 0
    check_attr_lv(quality_hash, attrs) if !quality_hash.empty?
    check_attrs_prob_0(rule_hash, attrs) # 检查prob为0的项
    check_attrs_prob(attrs_count, rule_hash, attrs, uniq)
    attrs
  end
  #--------------------------------------------------------------------------
  # ○ 获取note中设置的随机属性规则
  #  返回：attrs的数目 与 随机规则hash 与 品质随机规则hash
  #--------------------------------------------------------------------------
  def self.get_c_and_rules(item)
    # <exr lv id {prob}> → 指定id号品质的概率因子
    # <exr lvt id {cond}> → 满足cond条件时，读取id号品质随机模板
    # <exr t 1 {cond}> → 当满足cond条件时，用1号模板的规则覆盖当前的对应项
    # <exr sym 1 {value}> → 添加一个对属性sym的 [1, value] 规则
    # <exr id_id 1 {value}> → 添加一个特性id_id的 [1, value] 规则
    s = $game_switches; v = $game_variables
    hash_ = {}; hash_q = {};
    attrs_count = eval(ATTRS_COUNT_TEXT); attrs_max = ATTRS_MAX
    item.note.scan(/<exr (.*?) (\d+) \{(.*?)\}>/).each do |param|
      if param[0] == "c" # 设置数目
        attrs_max = param[1].to_i
        attrs_count = eval(param[2])
      elsif param[0] == "lv" # 指定品质的概率因子
        hash_q[param[1].to_i] = eval(param[2])
      elsif param[0] == "lvt" # 指定品质模板
        next if eval(param[2]) == false
        h = LEVEL_TEMPLATE[param[1].to_i] || {}
        h.each { |k, v_s| hash_q[k.to_i] = eval(v_s).to_i }
      elsif param[0] == "t" # 套用模板
        next if eval(param[2]) == false
        h = TEMPLATES[param[1].to_i] || {}
        hash_.merge!(h) # 新模板对应项覆盖原本hash
      elsif param[0] =~ /ex\-|\_/  # 扩展 与 特性
        hash_[param[0]] = [param[1].to_i, param[2]]
      else # 属性
        hash_[param[0].to_sym] = [param[1].to_i, param[2]]
      end
    end
    attrs_count = attrs_max if attrs_count > attrs_max
    return attrs_count, hash_, hash_q
  end
  #--------------------------------------------------------------------------
  # ○ 将品质attr添加到attrs数组中
  #--------------------------------------------------------------------------
  def self.check_attr_lv(quality_hash, attrs)
    @lv = rand_key(quality_hash)
    attrs.push( [:ex, :lv, @lv] )
  end
  #--------------------------------------------------------------------------
  # ○ 将rule_hash中全部prob为0的attr添加到结果数组attrs中
  #--------------------------------------------------------------------------
  def self.check_attrs_prob_0(rule_hash, attrs)
    h = rule_hash.select { |k, v| v[0] == 0 }
    h.each do |k, v|
      attr = new_attr(k, rule_hash[k][1])
      next if attr.empty?
      attrs.push(attr)
      rule_hash.delete(k)
    end
  end
  #--------------------------------------------------------------------------
  # ○ 补足attrs数组的空余随机属性
  #  输入： t - 属性条数   uniq - 不允许重复属性
  #--------------------------------------------------------------------------
  def self.check_attrs_prob(t, rule_hash, attrs, uniq = true)
    c = 0
    loop do
      break if c >= t
      key = rand_key_rule_hash(rule_hash)
      attr = new_attr(key, rule_hash[key][1])
      if attr.empty?
        break if rule_hash.empty?
        next
      end
      attrs.push(attr)
      if uniq
        rule_hash.delete(key)
        break if rule_hash.empty?
      end
      c += 1
    end
  end
  #--------------------------------------------------------------------------
  # ○ 由规则key与值生成有效的attr数组
  #  返回：attr数组
  #--------------------------------------------------------------------------
  def self.new_attr(key, value_s)
    s = $game_switches; v = $game_variables
    if key.is_a?(Symbol) # 含有同名方法的属性
      value = eval(value_s)
      return [] if value == 0
      return [key, value]
    end
    if key.include?("_") # 特性
      value = eval(value_s)
      return [] if value == 0
      ts = key.split(/_/)
      return [ts[0].to_i, ts[1].to_i, value]
    end
    if key.include?("ex-") # 扩展
      sym = key[3..-1].to_sym
      v = ex_attr_value(sym, value_s)
      return [:ex, sym, v]
    end
    []
  end
  #--------------------------------------------------------------------------
  # ○ 由扩展符号与其value字符串返回它有效的数据（扩展用）
  #  返回：对应扩展类型有效的数据（默认为eval后数据）
  #--------------------------------------------------------------------------
  def self.ex_attr_value(ex_sym, value_s)
    s = $game_switches; v = $game_variables
    eval(value_s)
  end
  #--------------------------------------------------------------------------
  # ○ 由概率因子随机返回对应的一个key
  #--------------------------------------------------------------------------
  def self.rand_key(hash)
    s = hash.values.inject(0) {|s, v| s += v }; r = rand(s)
    hash.each {|k, v| return k if (r -= v) < 0 }
  end
  #--------------------------------------------------------------------------
  # ○ 由概率因子随机返回规则hash中的一个key
  #--------------------------------------------------------------------------
  def self.rand_key_rule_hash(rule_hash)
    s = rule_hash.values.inject(0) {|s, v| s += v[0] }; r = rand(s)
    rule_hash.each {|k, v| return k if (r -= v[0]) < 0 }
  end
  #--------------------------------------------------------------------------
  # ○ 读取品质相关信息hash
  #--------------------------------------------------------------------------
  def self.get_lv_info(id)
    LEVELS[0].merge(LEVELS[id] || {})
  end
#=============================================================================
# ○ 存储附加属性的数据类
#=============================================================================
class Data_Equip_EX
  attr_reader   :level
  #--------------------------------------------------------------------------
  # ○ 初始化
  #--------------------------------------------------------------------------
  alias eagle_random_quality_init initialize
  def initialize(id, attrs)
    @level = 0
    eagle_random_quality_init(id, attrs)
  end
  #--------------------------------------------------------------------------
  # ○ 存在品质？
  #--------------------------------------------------------------------------
  def level?
    @level > 0
  end
  #--------------------------------------------------------------------------
  # ○ 获取品质相关信息hash
  #--------------------------------------------------------------------------
  def level_info
    EQUIP_EX.get_lv_info(@level)
  end
  #--------------------------------------------------------------------------
  # ○ 解析扩展attr数组项（扩展用）
  #--------------------------------------------------------------------------
  alias eagle_random_quality_parse_ex parse_ex
  def parse_ex(attr)
    # [:ex, :lv, lv_id]
    return @level = attr[2] if attr[1] == :lv
    eagle_random_quality_parse_ex(attr)
  end
  #--------------------------------------------------------------------------
  # ○ 获取特性数组
  #--------------------------------------------------------------------------
  alias eagle_random_quality_features features
  def features
    f = eagle_random_quality_features
    return f if !level?
    h = level_info
    f.collect { |d_f|
      v = d_f.value
      v = v > 0 ? (h[:s_pf] * v).round(2) : (h[:s_nf] * v).round(2)
      RPG::BaseItem::Feature.new(d_f.code, d_f.data_id, v)
    }
  end
  #--------------------------------------------------------------------------
  # ○ 获取属性数组
  #--------------------------------------------------------------------------
  alias eagle_random_quality_params params
  def params
    a = eagle_random_quality_params
    return a if !level?
    h = level_info
    a.collect { |e| e > 0 ? (h[:s_pp] * e).round : (h[:s_np] * e).round }
  end
end
end # end of EQUIP_EX
#=============================================================================
# ● RPG::EquipItem
#=============================================================================
class RPG::EquipItem < RPG::BaseItem
  #--------------------------------------------------------------------------
  # ○ 显示名称
  #--------------------------------------------------------------------------
  alias name_o name
  def name
    return name_o if @eagle_ex.nil? || !@eagle_ex.level?
    sprintf(@eagle_ex.level_info[:name], name_o)
  end
end
