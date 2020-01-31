#==============================================================================
# ■ 角色头顶显示图标 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
# - 2020.1.31.13
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
#==============================================================================
module POP_ICON
  #--------------------------------------------------------------------------
  # ● 【常量】持续显示帧数
  #--------------------------------------------------------------------------
  MAX_POP_FRAME = 20
end
#=============================================================================
# ○ Game_Message
#=============================================================================
class Game_Character
  attr_accessor :pop_icon
  #--------------------------------------------------------------------------
  # ● 初始化公有成员变量
  #--------------------------------------------------------------------------
  alias eagle_popicon_init initialize
  def initialize
    eagle_popicon_init
    @pop_icon = 0
  end
end
#=============================================================================
# ○ Game_Message
#=============================================================================
class Sprite_Character < Sprite_Base
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #     character : Game_Character
  #--------------------------------------------------------------------------
  alias eagle_popicon_init initialize
  def initialize(viewport, character = nil)
    @pop_icon = 0
    eagle_popicon_init(viewport, character)
    @popicon_sprite = ::Sprite.new(viewport)
    @popicon_sprite.bitmap = Bitmap.new(24, 24)
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  alias eagle_popicon_dispose dispose
  def dispose
    eagle_popicon_dispose
    @popicon_sprite.bitmap.dispose
    @popicon_sprite.dispose
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
  # ● 绘制图标
  #     enabled : 有效的标志。false 的时候使用半透明效果绘制
  #--------------------------------------------------------------------------
  def draw_icon(bitmap, icon_index, x, y, enabled = true)
    bitmap_ = Cache.system("Iconset")
    rect = Rect.new(icon_index % 16 * 24, icon_index / 16 * 24, 24, 24)
    bitmap.blt(x, y, bitmap_, rect, enabled ? 255 : 120)
  end
  #--------------------------------------------------------------------------
  # ● 重置图标pop
  #--------------------------------------------------------------------------
  def reset_popicon
    # 若与当前显示的一致，则继续显示
    if @character.pop_icon == @pop_icon
      @character.pop_icon = 0
      @popicon_count = 0 if @popicon_count == @popicon_max
      return
    end
    @pop_icon = @character.pop_icon
    @character.pop_icon = 0

    @popicon_sprite.bitmap.clear
    @popicon_sprite.ox = 12
    @popicon_sprite.oy = 24
    draw_icon(@popicon_sprite.bitmap, @pop_icon, 0, 0)

    @popicon_count = 0
    @popicon_max = POP_ICON::MAX_POP_FRAME # 激活一次后显示的帧数
  end
  #--------------------------------------------------------------------------
  # ● 更新图标pop
  #--------------------------------------------------------------------------
  def update_popicon
    reset_popicon if @character.pop_icon > 0
    if @pop_icon > 0
      return end_popicon if @popicon_count == @popicon_max
      # 此处可以加入在第 @popicon_count 帧的额外处理

      @popicon_sprite.x = x
      @popicon_sprite.y = y - height
      @popicon_sprite.z = z + 200
      @popicon_sprite.update
      @popicon_count += 1
    end
  end
  #--------------------------------------------------------------------------
  # ● 释放图标pop
  #--------------------------------------------------------------------------
  def end_popicon
    @popicon_sprite.bitmap.clear
    @pop_icon = 0
  end
end
