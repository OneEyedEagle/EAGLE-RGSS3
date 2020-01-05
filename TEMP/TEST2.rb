class Game_CharacterBase
  attr_accessor :balloon_id_ex
  #--------------------------------------------------------------------------
  # ● 初始化公有成员变量
  #--------------------------------------------------------------------------
  alias eagle_balloon_ex_init_public_members init_public_members
  def init_public_members
    eagle_balloon_ex_init_public_members
    @balloon_id_ex = 0
  end
end

class Sprite_Character < Sprite_Base
  frame_index = 0
  count = max_count
  def update_balloon_ex
    return if @balloon_id_ex == 0
    count -= 1
    if count == 0
      count = max_count
      if frame_index == max_frame
        if @character.balloon_id_ex != @balloon_id
          @balloon_id = @character.balloon_id_ex
          return
        end
        frame_index = 0
      end
      @balloon_sprite.x = x
      @balloon_sprite.y = y - height
      @balloon_sprite.z = z + 200
      sx = frame_index * 32
      sy = (@balloon_id - 1) * 32
      @balloon_sprite.src_rect.set(sx, sy, 32, 32)
      frame_index += 1
    end
  end
end
