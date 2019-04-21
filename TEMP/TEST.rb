# 装备数据库的最大值（数字全部置换为9时）的位数
#（扩展装备会比该值大1，用于区分）
#（比如数据库上限69，自动调整后为99，位数是2，则扩展装备的id从100开始）
#（因此该位数务必比游戏最终定下的装备数量大一些，不然可能会打乱扩展装备）
#（默认数据库上限999）
DATABASE_MAX_DIGIT = 3

def a.[](id)
  max_id = self.size
  return Array.instance_method(:[]).bind(self).call(id) if id < max_id
  # 当id大于数据库上限时，后面部分为该装备内的独立数据索引
  id_s = id.to_s
  # 获得id位数，裁剪出数据库内的索引id
  # 获得item内的额外属性索引id部分
  # 将额外的属性添加入原始物品中
end
