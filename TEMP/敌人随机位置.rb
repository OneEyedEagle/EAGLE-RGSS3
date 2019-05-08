# TODO 
# 敌人位置随机放置

class
  # 在敌群设置完成后处理敌人随机位置
  #--------------------------------------------------------------------------
  # ● 设置
  #--------------------------------------------------------------------------
  alias eagle_enemy_rand_position_setup setup
  def setup(troop_id)
    eagle_enemy_rand_position_setup(troop_id)
    rand_positions
  end

  # 不同敌人独立设置所处基础y值（图像底部中心为显示原点）
  # 读取敌人位图宽度，防止重叠放置
  def rand_positions
    members.each do |member|
      member.enemy
      bitmap = Cache.battler(member.battler_name)
      bitmap.width
    end
  end
end
