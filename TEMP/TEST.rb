# 敌人信息展示
module EAGLE
  def self.draw_enemy_info(sprite, game_enemy)
  end
end

class Scene_Battle
  #--------------------------------------------------------------------------
  # ● 开始选择敌人
  #--------------------------------------------------------------------------
  def select_enemy_selection
    @enemy_window.refresh
    @enemy_window.show.activate

    @enemy_info_window
  end
end
