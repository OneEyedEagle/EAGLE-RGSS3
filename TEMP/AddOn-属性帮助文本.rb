# TODO

module EQUIP_EX
  def self.get_attrs_help(attrs)
    attrs.collect { |e| attr_help(e) }
  end
  def self.attr_help(attr)
    if attr[0] == :ex
    end
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
  end
end
