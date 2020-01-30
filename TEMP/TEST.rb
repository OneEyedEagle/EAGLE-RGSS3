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
    @popicon_sprite.blend_type = 1

    @popicon_count = 0
    @popicon_max = 20 # 激活一次后显示的持续帧数

    @popicon_flash_count = 0
  end
  #--------------------------------------------------------------------------
  # ● 更新图标pop
  #--------------------------------------------------------------------------
  def update_popicon
    reset_popicon if @character.pop_icon > 0
    if @pop_icon > 0
      return end_popicon if @popicon_count == @popicon_max

      if @popicon_flash_count == 10
        @popicon_sprite.flash(Color.new(255,0,0,255), 20)
      end

      @popicon_sprite.x = x
      @popicon_sprite.y = y - height
      @popicon_sprite.z = z + 200
      @popicon_sprite.update

      @popicon_count += 1
      @popicon_flash_count += 1
      @popicon_flash_count %= 60
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
