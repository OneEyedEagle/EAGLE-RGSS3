# 状态层数

# 战斗中部分时机执行内容

#地图上的物品掉落
#物品获得提示

=begin
if self.bitmap
  n = 0
  d = 2
  o = 5
  dir = :LR
  s = :S
  Unravel_Bitmap.new(self.x, self.y, self.bitmap.clone, 0, 0, self.width,
    self.height, n, d, o, dir, s)
end


#--------------------------------------------------------------------------
# ● 更新远景图
#--------------------------------------------------------------------------
def update_parallax
  if @parallax_name != $game_map.parallax_name
    @parallax_name = $game_map.parallax_name
    @parallax.bitmap.dispose if @parallax.bitmap
    @parallax.bitmap = Cache.parallax(@parallax_name)
    Graphics.frame_reset
  end
  @parallax.ox = $game_map.display_x * 32 #$game_map.parallax_ox(@parallax.bitmap)
  @parallax.oy = $game_map.display_y * 32 #$game_map.parallax_oy(@parallax.bitmap)
end
=end

a = [1,2,3]
b = [1,3,5]
p a|b
