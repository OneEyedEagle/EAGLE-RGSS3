#=============================================================================
# ■ 装备附加属性-随机规则  by 老鹰（http://oneeyedeagle.lofter.com/）
#=============================================================================
$imported ||= {}
$imported["EAGLE-EquipEXRule"] = true
#=============================================================================
# - 2019.4.27.0 新增attrs数目设置
#=============================================================================
# - 本插件依据装备备注栏中设置的规则，生成随机的attrs数组
# - 生成的 attrs 数组可用于 装备附加属性-核心 by老鹰 中生成附加属性实例
#--------------------------------------------------------------------------
# ○ 操作流程
#--------------------------------------------------------------------------
# - 设置通用规则模板
#     具体看 常量：通用规则模板 中的0号目标设置范例
#
# - 设置独立规则
#     在数据库备注栏中按格式填写（有先后读取顺序，最后的会覆盖之前的）：
#       <exr c max {value}> → 设置一次随机value个属性（最多max个）
#                           （若未设置该项，将取通用设置）
#       <exr t id {cond}> → 当满足cond条件时，用id号模板的规则覆盖当前的对应项
#       <exr sym prob {value}> → 添加一个属性sym的 [prob, value] 规则
#       <exr id_id prob {value}> → 添加一个特性id_id的 [prob, value] 规则
#    · cond 解析：被eval后返回的布尔值为true时，该项才会生效
#        可以用 s 代替 $game_switches，可以用 v 代替 $game_variables
#    · sym 解析：八维属性的字符串，依次为 mhp, mmp, atk, def, mat, mdf, agi, luk
#    · prob 解析：概率因子，代表该项被随机选中的概率因子，全部因子之和为分母
#    · value 解析：被eval后返回的值将作为该项的值
#        可以用 rand 来获取 0~1 的随机小数，可以用 rand(i) 来获取 0~i-1 的随机正整数
#        可以用 s 代替 $game_switches，可以用 v 代替 $game_variables
#    · id_id 解析：由特性的code与data_id合并而成，具体请参考 装备附加属性-核心
#
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
#
#--------------------------------------------------------------------------
# ○ 特别说明
#--------------------------------------------------------------------------
# - 由于并没做多余判定，所以item只要是有note方法（数据库中有备注栏）的对象即可
#=============================================================================
module EQUIP_EX
  #--------------------------------------------------------------------------
  # ○ 常量：通用属性数目上限
  #--------------------------------------------------------------------------
  ATTRS_MAX = 4
  #--------------------------------------------------------------------------
  # ○ 常量：通用属性数目文本
  #--------------------------------------------------------------------------
  ATTRS_COUNT_TEXT = "4"
  #--------------------------------------------------------------------------
  # ○ 常量：通用规则模板
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
    attrs_count, rule_hash = get_c_and_rules(item)
    return [] if rule_hash.empty?
    keys = rule_hash.keys.dup; values = rule_hash.values.collect { |e| e[0] }
    attrs = []; s = $game_switches; v = $game_variables
    attrs_count.times do
      key = rule_hash_rand_key(rule_hash)
      value_s = rule_hash[key][1]
      # 由规则的key与值的text生成一个有效的attr
      if key.is_a?(Symbol)
        attr = [key, eval(value_s)]
      elsif key.is_a?(String)
        ts = key.split(/_/)
        attr = [ts[0].to_i, ts[1].to_i, eval(value_s)]
      end
      attrs.push(attr)
      if uniq
        rule_hash.delete(key)
        break if rule_hash.empty?
      end
    end
    attrs
  end
  #--------------------------------------------------------------------------
  # ○ 获取note中设置的随机属性规则
  #  返回：attrs的数目 与 随机规则hash
  #--------------------------------------------------------------------------
  def self.get_c_and_rules(item)
    # <exr t 1 {cond}> → 当满足cond条件时，用1号模板的规则覆盖当前的对应项
    # <exr sym 1 {value}> → 添加一个对属性sym的 [1, value] 规则
    # <exr id_id 1 {value}> → 添加一个特性id_id的 [1, value] 规则
    hash_ = {}; s = $game_switches; v = $game_variables
    attrs_count = eval(ATTRS_COUNT_TEXT); attrs_max = ATTRS_MAX
    item.note.scan(/<exr (.*?) ?(\d+) ?\{(.*?)\}>/).each do |param|
      if param[0] == "s" # 设置数目
        attrs_max = param[1].to_i
        attrs_count = eval(param[2])
      elsif param[0] == "t" # 套用模板
        next if eval(param[2]) == false
        h = TEMPLATES[param[1].to_i] || {}
        hash_.merge!(h) # 新模板对应项覆盖原本hash
      elsif param[0].include?("_") # 特性
        hash_[param[0]] = [param[1].to_i, param[2]]
      else # 属性
        hash_[param[0].to_sym] = [param[1].to_i, param[2]]
      end
    end
    attrs_count = attrs_max if attrs_count > attrs_max
    return attrs_count, hash_
  end
  #--------------------------------------------------------------------------
  # ○ 由概率因子随机返回规则hash中的一个key
  #--------------------------------------------------------------------------
  def self.rule_hash_rand_key(hash_)
    s = hash_.values.inject(0) {|s, v| s += v[0] }; r = rand(s)
    hash_.each {|k, v| return k if (r -= v[0]) < 0 }
  end
end
