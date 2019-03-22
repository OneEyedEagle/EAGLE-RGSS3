#==============================================================================
# ■ Add-on 文字散开移出 by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【对话框扩展 by老鹰】与【简单粒子系统-发散式 by老鹰】之下
#==============================================================================
# - 2019.3.22.21 完善ing
#==============================================================================
# - 本插件给 对话框扩展 中的对话框新增了\pout转义符，可控制对话文本调用简单粒子做移出
#      type -【默认】设置选用的粒子移出类型（0为取消）
# - 本插件的优先级高于原有的\cout转义符，即覆盖\cout效果
#==============================================================================

#==============================================================================
# ○ ParticleManager
#==============================================================================
class << ParticleManager
  alias eagle_particle_message_out_init init
  def init
    eagle_particle_message_out_init
    f = Particle_Template_BitmapNoDup.new
    f.speed = 2
    f.life = 40
    f.life_var = 20
    f.theta = 270
    f.theta_var = 90
    f.angle = 0
    f.angle_var = 3
    f.for_once = true
    f.bitmap_dispose = true
    vp = Viewport.new
    vp.add_fast_layer(1, 0) if $RGD
    ParticleManager.setup(:charas_out, f, vp)
  end
end
#==============================================================================
# ○ Game_Message
#==============================================================================
class Game_Message
  attr_accessor :pout_params
  #--------------------------------------------------------------------------
  # ● 获取全部可保存params的符号的数组
  #--------------------------------------------------------------------------
  alias eagle_particle_out_params eagle_params
  def eagle_params
    eagle_particle_out_params + [:pout]
  end
end
#==============================================================================
# ○ Window_Message
#==============================================================================
class Window_Message
  #--------------------------------------------------------------------------
  # ● 移出全部文字精灵
  #--------------------------------------------------------------------------
  alias eagle_particle_out_sprites_move_out eagle_message_sprites_move_out
  def eagle_message_sprites_move_out
    if game_message.pout_params[:type] && game_message.pout_params[:type] > 0
      f = ParticleManager.emitters[:charas_out].template
      bitmaps = []; xys = []
      @eagle_chara_sprites.each do |s|
        s.opacity = 0
        bitmaps.push(s.bitmap.dup)
        xys.push(Vector.new(s.x,s.y))
      end
      f.total = @eagle_chara_sprites.size
      f.bitmaps = bitmaps
      f.xys = xys
      ParticleManager.start(:charas_out)
    else
      eagle_particle_out_sprites_move_out
    end
  end
  #--------------------------------------------------------------------------
  # ● 设置pout参数
  #--------------------------------------------------------------------------
  def eagle_text_control_pout(param = '0')
    parse_param(game_message.pout_params, param, :type)
  end
end
