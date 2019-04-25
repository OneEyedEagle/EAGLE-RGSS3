# 装备附加属性-随机规则
# 依据一定规则返回attrs数组
module EQUIP_EX
  # 通用规则模板
  TEMPLATES = {}
  TEMPLATES[0] = { # 模板id
    :atk => [2, "2+rand(1)"], # sym => [概率因子（正整数）, eval值]
    "22_0" => [1, "-0.5*rand"], # code_id + '_' + data_id => [概率因子, eval值]
  }

  # 基于指定装备的规则生成含有n条attr的数组
  def self.get_attrs(item, n = 1)
    rule_hash = get_rules(item)
    keys = rule_hash.keys; values = rule_hash.values.collect { |e| e[0] }
    attrs = []; s = $game_switches; v = $game_variables
    n.times do
      key = rand_key(keys, values)
      value_s = rule_hash[key][1]
      # 由规则的key与值的text生成一个有效的attr
      if key.is_a?(Symbol)
        attr = [key, eval(value_s)]
      elsif key.is_a?(String)
        key.split(/_/).each {|t| attr = [t[0].to_i, t[1].to_i, eval(value_s)] }
      end
      attrs.push(attr)
    end
    attrs
  end

  def self.get_rules(item)
    # 获取指定物品的随机属性规则hash
    # <exr t 1 {cond}> → 当满足cond条件时，用1号模板的规则覆盖当前的对应项
    # <exr sym 1 {value}> → 添加一个对属性sym的 [1, value] 规则
    # <exr id_id 1 {value}> → 添加一个特性id_id的 [1, value] 规则
    hash = {}; s = $game_switches; v = $game_variables
    item.note.scan(/<exr (.*?) ?(\d+) ?\{(.*?)\}>/).each do |param|
      if param[0] == "t" # 套用模板
        next if eval(param[2]) == false
        h = TEMPLATES[param[1].to_i] rescue {}
        hash.merge(h) # 新模板对应项覆盖原本hash
      elsif param[0].include?("_") # 特性
        hash[param[0]] = [param[1].to_i, param[2]]
      else # 属性
        hash[param[0].to_sym] = [param[1].to_i, param[2]]
      end
    end
    hash
  end

  def self.rand_key(keys = [], values = [])
    # 依据相对应的key与概率因子，随机返回一个key
    s = values.sum; r = rand(s); index = -1
    values.each_with_index { |v, i| break index = i if (r -= v) <= 0 }
    keys[index]
  end
end
