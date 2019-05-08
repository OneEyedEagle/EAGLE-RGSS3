#=============================================================================
# ■ Add-On 属性锁定  by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【装备附加属性-核心 by老鹰】之下
#=============================================================================
$imported ||= {}
$imported["EAGLE-EquipEXLock"] = true
#=============================================================================
# - 2019.5.8.15 初稿
#=============================================================================
# - 该插件用于设置装备的附加属性中属性的锁定，并提供了解锁接口
#--------------------------------------------------------------------------
# ○ 设置锁定规则
#--------------------------------------------------------------------------
#   在数据库武器/护甲的备注栏中按格式填写下列规则：
#   （有先后读取顺序，且出于规则的唯一性，后读入的同类型规则会覆盖先读入的）
#
# - 设置数目规则
#       <exl n-v {cond}> → 当eval(cond)为true时，设置总共随机锁定的属性条数为v
#    · cond 解析：被eval后返回的布尔值为true时，该项才会生效
#        可以用 s 代替 $game_switches，可以用 v 代替 $game_variables
#        可以用 @lv 来获取当前装备定下的品质等级
#
# - 设置锁定规则
#   （该规则不占用随机锁定属性的数目）
#       <exl sym {cond}> <exl code_data {cond}> <exl ex-sym {cond}>
#    → 当eval(cond)为true时，必定锁定；为false时，必定不锁定；为nil时，无变更
#    · sym 解析：Data_Equip_EX类中含有同名方法的字符串
#                如默认八维属性 mhp, mmp, atk, def, mat, mdf, agi, luk
#    · id_id 解析：由特性的code与data_id合并而成，具体请参考 装备附加属性-核心
#    · ex-sym 解析：扩展符号为sym的扩展属性
#--------------------------------------------------------------------------
# ○ 处理流程
#--------------------------------------------------------------------------
# 1. 去除附加属性中必定不会锁定的属性
# 2. 记录附加属性中必定锁定的属性
# 3. 在剩余的附加属性中，随机选择其中v条属性进行锁定（不重复选择）（不足时结束）
# 4. 将必定不会锁定的属性与剩余属性，作为附加属性实例的初始化输入
# 5. 将锁定的属性数组，存入生成的附加属性实例中
#--------------------------------------------------------------------------
# ○ 解锁接口
#--------------------------------------------------------------------------
# - 当获取到了装备的实例 equip 后（如 equip = $data_weapons[1]）
#   利用下述步骤进行属性的解锁
# 1. 获取装备所绑定的附加属性实例 → equip.eagle_ex
# 2. 调用它的解锁一个属性的方法 → equip.eagle_ex.unlock
#=============================================================================
module EQUIP_EX
  #--------------------------------------------------------------------------
  # ○ 常量：初始锁定的属性数目
  #--------------------------------------------------------------------------
  ATTRS_LOCK_COUNT = 4
  #--------------------------------------------------------------------------
  # ○ 常量：定义无法被锁定的属性
  #  - 对于有对应同名方法的属性，请填入符号（如基本属性 :mhp 和 :def）
  #  - 对于数据库中的特性，请填入字符串 "code_data" （如 "22_0" 代表物理命中几率）
  #  - 对于扩展属性，请填入字符串 "ex-sym" ，其中sym替换成扩展符号 （如 "ex-lv"）
  #--------------------------------------------------------------------------
  ATTRS_UNLOCKABLE = ["ex-lv"]
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
    attrs_t = attrs.dup; attrs_lock = []; attrs_unlock = []
    # 预处理
    if $imported["EAGLE-EquipEXRule"]
      a = attrs_t.find { |a| a[0] == :ex && a[1] == :lv }
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
        attrs_unlock.push(attr)
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
    return attrs_t + attrs_unlock, attrs_lock
  end
  #--------------------------------------------------------------------------
  # ○ 获取指定attr对应的sym
  #--------------------------------------------------------------------------
  def self.get_attr_sym(attr)
    return sprintf("ex-%s", attr[1]) if attr[0] == :ex # 扩展
    return sprintf("%d_%d", attr[0], attr[1]) if attr.size == 3 # 特性
    return attr[0]  # 属性
  end
  #--------------------------------------------------------------------------
  # ○ 获取指定物品的锁定相关信息
  #--------------------------------------------------------------------------
  def self.get_lock_infos(item)
    # <exl n-v {cond}> - 当cond为true时，设置总共锁定的属性条数为v
    # <exl sym {cond}> - 当eval(cond)为true时，必定锁定属性sym；
    #                    为false时，必定不锁定；为nil时，无变更
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
  attr_accessor   :attrs_lock
  #--------------------------------------------------------------------------
  # ○ 初始化
  #--------------------------------------------------------------------------
  alias eagle_attr_lock_init initialize
  def initialize(id, attrs = [])
    @attrs_lock = []
    eagle_attr_lock_init(id, attrs)
  end
  #--------------------------------------------------------------------------
  # ○ 解锁一个属性
  #--------------------------------------------------------------------------
  def unlock
    return if @attrs_lock.empty?
    add( @attrs_lock.shift )
  end
end
end # end of EQUIP_EX
