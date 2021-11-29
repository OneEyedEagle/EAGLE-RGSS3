class Spriteset_Map
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
end
