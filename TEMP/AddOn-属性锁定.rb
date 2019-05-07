# AddOn - 属性锁定
$imported ||= {}
$imported["EAGLE-EquipEXLock"] = true

# - 设置装备的扩展属性的锁定与解锁接口
# - 设置初始锁定的attr项的数目
# - 设置不会被锁定的项
# - 随机出锁定数组
module EQUIP_EX
  #--------------------------------------------------------------------------
  # ○【封装】生成附加属性实例并返回
  # （在 new_ex 方法内部使用）
  #--------------------------------------------------------------------------
  alias eagle_attr_lock_new_data new_data_equip_ex
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
    attrs_2 = []
    attrs_lock = []
    return attrs_2, attrs_lock
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
