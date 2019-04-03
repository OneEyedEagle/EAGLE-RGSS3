#==============================================================================
# ■ Add-On 文字四散移出 by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【对话框扩展 by老鹰】与【Add-On 部分粒子模板 by老鹰】之下
#==============================================================================
# - 2019.4.3.20 完善
#==============================================================================
# - 本插件给 对话框扩展 中的对话框新增了\pout转义符，
#   可控制对话文本调用简单粒子系统来进行文字移出效果操作（覆盖\cout的效果）
#      type -【默认】设置选用的粒子移出类型（0为取消）
#      v - 每帧移动像素值
#      vd - 每帧移动像素值的随机增减量
#      t - opacity减为0前的持续运动时间（帧）
#      td - 持续时间的随机增减量
#      a - 初始运动朝向角度（270为竖直向上方向）（0~360）
#      ad - 初始朝向角度的随机增减量
#      va - 每帧旋转的角度
#      vad - 旋转角度的随机增减量
#==============================================================================

#==============================================================================
# ○ ParticleManager
#==============================================================================
class << ParticleManager
  alias eagle_particle_message_out_init init
  def init
    eagle_particle_message_out_init
    f = Particle_Template_BitmapNoDup.new
    f.for_once = true
    f.bitmap_dispose = true
    vp = Viewport.new
    vp.z = 100
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

      f.speed = game_message.pout_params[:v] || 2
      f.speed_var = game_message.pout_params[:vd] || 1
      f.life = game_message.pout_params[:t] || 40
      f.life_var = game_message.pout_params[:td] || 20
      f.theta = game_message.pout_params[:a] || 270
      f.theta_var = game_message.pout_params[:ad] || 90
      f.angle = game_message.pout_params[:va] || 0
      f.angle_var = game_message.pout_params[:vad] || 3

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
