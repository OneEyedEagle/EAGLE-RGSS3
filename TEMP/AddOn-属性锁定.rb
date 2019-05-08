# AddOn - 属性锁定
$imported ||= {}
$imported["EAGLE-EquipEXLock"] = true

# - 设置装备的扩展属性的锁定与解锁接口

module EQUIP_EX
  # 设置默认的锁定属性数目
  ATTRS_LOCK_COUNT = 4
  # 设置无法被锁定的属性
  #   有对应同名方法的属性，请填入其符号（如 :mhp 和 :def）
  #   数据库中的特性，请填入字符串 "code_data" （如 "22_0" 代表物理命中几率）
  #   对于扩展属性，请填入 :ex_sym ，其中sym替换成扩展的符号 （如 :ex_lv）
  ATTRS_UNLOCKABLE = []
  #--------------------------------------------------------------------------
  # ○【封装】生成附加属性实例并返回
  # （在 new_ex 方法内部使用）
  #--------------------------------------------------------------------------
  class << self; alias eagle_attr_lock_new_data new_data_equip_ex; end
  def self.new_data_equip_ex(item, id_ex, attrs)
    attrs_2, attrs_lock = attrs_lock(item, attrs)
    data = eagle_attr_lock_new_data(item, id_ex, attrs_2)
    data.attrs_lock = attrs_lock
    data
  end
  #--------------------------------------------------------------------------
  # ○ 依据设置的规则，将部分属性进行锁定
  #  返回：未锁定的attr数组、锁定的attr数组
  #--------------------------------------------------------------------------
  def self.attrs_lock(item, attrs)
    attrs_t = attrs.dup; attrs_lock = []
    # 预处理
    if $imported["EAGLE-EquipEXRule"]
      a = array.find { |a| a[0] == :ex && a[1] == :lv }
      @lv = a[2] if a
    end
    lock_syms, unlock_syms, lock_count = get_lock_infos(item)
    # 去除必定锁定的与必定不锁定的
    attrs_t.each_with_index do |attr, i|
      sym = get_attr_sym(attr)
      if lock_syms.include?(sym)
        attrs_lock.push(attr)
        attrs_t[i] = nil
      elsif unlock_syms.include?(sym)
        attrs_t[i] = nil
      end
    end
    attrs_t.compact!
    # 若仍然有剩余，则进行随机锁定
    while !attrs_t.empty?
      break if lock_count == 0
      i = rand(attrs_t.size)
      attrs_lock.push(attrs_t[i])
      attrs_t.delete_at(i)
      lock_count -= 1
    end
    return attrs_t, attrs_lock
  end

  def self.get_attr_sym(attr)
    return sprintf("ex-%s", attr[1]).to_sym if attr[0] == :ex # 扩展
    return sprintf("%d_%d", attr[0], attr[1]) if attr.size == 3 # 特性
    return attr[0]  # 属性
  end

  def self.get_lock_infos(item)
    # <exl n-v {cond}> - 当cond为true时，设置总共锁定的属性条数为v
    # <exl sym {cond}> - 当eval(cond)为true时，必定锁定属性sym；为false时，必定不锁定；为nil时，无变更
    s = $game_switches; v = $game_variables
    lock_syms = []; unlock_syms = ATTRS_UNLOCKABLE.dup
    lock_count = ATTRS_LOCK_COUNT
    item.note.scan(/<exl (.*?) \{(.*?)\}>/).each do |param|
      if param[0].include?("n-") && (param[1].nil? || eval(param[1]) == true)
        lock_count = param[0][2..-1].to_i # 随机锁定属性的数目
        next
      end
      f = param[1] ? eval(param[1]) : nil
      next if f.nil?
      if param[0] =~ /ex\-|\_/ # 扩展 与 特性
        f ? lock_syms.push(param[0]) : unlock_syms.push(param[0])
      else # 属性
        f ? lock_syms.push(param[0].to_sym) : unlock_syms.push(param[0].to_sym)
      end
    end
    return lock_syms, unlock_syms, lock_count
  end
#=============================================================================
# ○ 存储附加属性的数据类
#=============================================================================
class Data_Equip_EX
  attr_reader   :attrs_lock
  #--------------------------------------------------------------------------
  # ○ 解锁一个属性
  #--------------------------------------------------------------------------
  def unlock(sym = nil)
    return if @attrs_lock.nil? || @attrs_lock.empty?
    add( @attrs_lock.shift )
  end
end
end # end of EQUIP_EX


module EQUIP_EX
  def self.attrs_help(attrs)
    helps = []
  end
end
