#==============================================================================
# ■ 角色头顶显示图标 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
# - 2020.3.26.22 优化
#==============================================================================
# - 本插件新增了在地图上角色头顶显示指定图标的功能（仿气泡）
#--------------------------------------------------------------------------
# - 在 RGSS3 中，可以给 Game_CharacterBase类的 @balloon_id 变量赋值，
#   用于在地图角色的头顶显示动态气泡
# - 类似的，本插件为 Game_Character类新增了 @pop_icon 变量，
#   为其赋值能在一段时间内，在角色头顶显示图标
# - 示例：
#    $game_player.pop_icon = 1
#      → 在玩家头顶显示 1 号图标，持续 MAX_POP_FRAME 帧
#   若设置为 0，则消除图标
#==============================================================================
module POP_ICON
  #--------------------------------------------------------------------------
  # ● 【常量】当该序号的开关开启时，不显示图标
  #--------------------------------------------------------------------------
  S_ID_NO_POP = 1
  #--------------------------------------------------------------------------
  # ● 【常量】一次激活后，最长的显示帧数
  #  若设置为 nil，则不会自动消失
  #--------------------------------------------------------------------------
  MAX_SHOW_FRAME = 10
  #--------------------------------------------------------------------------
  # ● 【常量】最大循环帧数
  #--------------------------------------------------------------------------
  MAX_LOOP_FRAME = 60
  #--------------------------------------------------------------------------
  # ● 按照当前循环的帧序号进行重绘
  #  frame 的取值为 0 ~ MAX_LOOP_FRAME-1
  #--------------------------------------------------------------------------
  def self.draw_pop_icon(sprite_chara, sprite_icon, icon_id, frame)
    # 设置基础位置
    sprite_icon.x = sprite_chara.x
    sprite_icon.y = sprite_chara.y - sprite_chara.height
    sprite_icon.z = sprite_chara.z + 200

    # 在第一帧时，新建位图并绘制图标
    if frame == 0
      sprite_icon.visible = true
      sprite_icon.bitmap ||= Bitmap.new(24, 24)
      sprite_icon.bitmap.clear
      sprite_icon.ox = 12
      sprite_icon.oy = 24
      draw_icon(sprite_icon.bitmap, icon_id, 0, 0)
      sprite_icon.opacity = 255
    end

    case frame
    when 1..29
      sprite_icon.opacity -= 6
      sprite_icon.y += (frame/4)
    when 30..59
      sprite_icon.opacity += 6
      sprite_icon.y += ((29-(frame-29))/4)
    end
  end
  #--------------------------------------------------------------------------
  # ● 绘制图标
  #     enabled : 有效的标志。false 的时候使用半透明效果绘制
  #--------------------------------------------------------------------------
  def self.draw_icon(bitmap, icon_index, x, y, enabled = true)
    bitmap_ = Cache.system("Iconset")
    rect = Rect.new(icon_index % 16 * 24, icon_index / 16 * 24, 24, 24)
    bitmap.blt(x, y, bitmap_, rect, enabled ? 255 : 120)
  end
end
#=============================================================================
# ○ Game_Character
#=============================================================================
class Game_Character
  attr_accessor :pop_icon
  #--------------------------------------------------------------------------
  # ● 初始化公有成员变量
  #--------------------------------------------------------------------------
  alias eagle_popicon_init initialize
  def initialize
    @pop_icon = 0
    eagle_popicon_init
  end
end
#=============================================================================
# ○ Sprite_Character
#=============================================================================
class Sprite_Character < Sprite_Base
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  alias eagle_popicon_dispose dispose
  def dispose
    eagle_popicon_dispose
    if @popicon_sprite
      @popicon_sprite.bitmap.dispose
      @popicon_sprite.dispose
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新画面
  #--------------------------------------------------------------------------
  alias eagle_popicon_update update
  def update
    eagle_popicon_update
    update_popicon
  end
  #--------------------------------------------------------------------------
  # ● 更新图标pop
  #--------------------------------------------------------------------------
  def update_popicon
    if $game_switches[POP_ICON::S_ID_NO_POP]
      end_popicon if @pop_icon != 0
      return
    end
    flag_continue_show = false
    if @character.pop_icon > 0
      if @character.pop_icon == @pop_icon # 若与当前显示一致，则继续显示
        @character.pop_icon = -1
        flag_continue_show = true
      else
        reset_popicon
      end
    else
      return end_popicon if @character.pop_icon == 0
    end
    if @pop_icon > 0
      if !flag_continue_show && POP_ICON::MAX_SHOW_FRAME &&
         @popicon_count > POP_ICON::MAX_SHOW_FRAME
        return end_popicon
      end
      c = @popicon_count % POP_ICON::MAX_LOOP_FRAME
      POP_ICON.draw_pop_icon(self, @popicon_sprite, @pop_icon, c)
      @popicon_sprite.update
      @popicon_count += 1
    end
  end
  #--------------------------------------------------------------------------
  # ● 重置图标pop
  #--------------------------------------------------------------------------
  def reset_popicon
    @pop_icon = @character.pop_icon
    @character.pop_icon = -1 # 在显示中，置为-1
    @popicon_sprite ||= Sprite.new(viewport)
    @popicon_count = 0
  end
  #--------------------------------------------------------------------------
  # ● 释放图标pop
  #--------------------------------------------------------------------------
  def end_popicon
    @popicon_sprite.visible = false if @popicon_sprite
    @pop_icon = 0
    @character.pop_icon = 0
  end
end
