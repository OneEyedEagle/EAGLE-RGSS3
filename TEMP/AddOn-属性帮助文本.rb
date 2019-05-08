# TODO

module EQUIP_EX
  HELP_CODE = {
    11 => "属性抗性",
    12 => "弱化抗性",
    13 => "状态抗性",
    14 => "状态免疫",
    21 => "普通能力",
    22 => "添加能力",
    23 => "特殊能力",
    31 => "附带属性",
    32 => "附带状态",
    33 => "攻击速度",
    34 => "添加攻击次数",
    41 => "添加技能类型",
    42 => "禁用技能类型",
    43 => "添加技能",
    44 => "禁用技能",
    51 => "可装备武器类型",
    52 => "可装备护甲类型",
    53 => "固定装备",
    54 => "禁用装备",
    55 => "装备风格",
    61 => "添加行动次数",
    62 => "特殊标志",
    63 => "消失效果",
    64 => "队伍能力"
  }
  # 基础能力
  HELP_PARAMS = {
    0 => "\\c[17]最大HP",
    1 => "\\c[16]最大MP",
    2 => "\\c[20]物攻",
    3 => "\\c[21]物防",
    4 => "\\c[30]魔攻",
    5 => "\\c[31]魔防",
    6 => "\\c[14]敏捷",
    7 => "\\c[17]幸运"
  }
  # 添加能力
  HELP_XPARAMS = {
    0 => "物理命中几率：",
    1 => "物理闪避几率：",
    2 => "必杀几率:",
    3 => "必杀闪避几率：",
    4 => "魔法闪避几率：",
    5 => "魔法反射几率：",
    6 => "物理反击几率：",
    7 => "体力值再生速度：",
    8 => "魔力值再生速度：",
    9 => "特技值再生速度："
  }
  # 特殊能力
  HELP_SPARAMS = {
    0 => "受到攻击的几率",
    1 => "防御效果比率",
    2 => "恢复效果比率",
    3 => "药理知识",
    4 => "MP消费率",
    5 => "TP消耗率",
    6 => "物理伤害加成",
    7 => "魔法伤害加成",
    8 => "地形伤害加成",
    9 => "经验获得加成"
  }

  def self.get_attrs_help(attrs)
    attrs.collect { |e| attr_help(e) }
  end
  def self.attr_help(attr)
    return attr_help_ex(attr) if attr[0] == :ex
    if attr.size == 3

    end
    id = PARAMS_TO_ID[attr[0]] if attr[0].is_a?(Symbol)
    t = ""
    case id
    when 0; t = ""
    when 1; t = ""
    end
    return t
  end
  def self.attr_value_s(value)
    return "0" if value == 0
    prefix = value > 0 ? "+ " : "- "
    v_ = value.abs
    return sprintf("%s%d\%", prefix, v_ * 100)  if v_ < 1
    return sprintf("%s%d", prefix, v_)
  end

  def self.attr_help_ex(attr_ex)
    case attr[1]
    when :lv
      t = ""
    end
    return t
  end
end
