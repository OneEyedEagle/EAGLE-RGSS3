#==============================================================================
# ■ Add-On 文字四散移出V2 by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【粒子发射器V2 by老鹰】之下
#==============================================================================
# - 2021.10.18.23 更新
#==============================================================================
# - 本插件为 文字精灵组的粒子化 实现了一个简单便捷的调用接口
#----------------------------------------------------------------------------
# ○ 若使用了【对话框扩展 by老鹰】，将本插件置于其下
#
# - 为对话框中增加 \pout 转义符，启用后，文本移出时将调用预设粒子模板
#
#   （注意：覆盖原本的 \cout 效果）
#
# - 具体参数一览：
#
#    （见 PARTICLE#pout_set_template 方法中传入的 params 的key值）
#
#    type →【默认】设置选用的粒子移出类型（0为关闭特效）
#    v → 文字每帧移动的像素值
#    vd → v的随机增减量（比如传入1时，v的最终值为v+-1）
#    t → 粒子的存在时间（帧）
#    td → 时间的随机增减量
#    a → 粒子的初始角度
#    ad → 角度的随机增减量
#    va → 每帧增加的角度值
#    vad → 每帧增加的角度值的随机增减量
#
# - 示例：
#
#    \pout[1] → 使用默认的设置，文字将向上随机移出
#    \pout[2] → 增加了一个向下的力，文字将向下掉落移出
#
# - 高级：
#
#    在 PARTICLE#pout_set_template 方法的最后，留有了针对 params[:type] 的判定，
#    比如传入值为 2 时，就是给粒子模板增加了一个向下的力。
#
#    可以通过增加自己的设定，来让这个转义符的效果更加多样。
#
#----------------------------------------------------------------------------
# ○ 若使用了【Add-On 选择框扩展 by老鹰】，将本插件置于其下
#
# - 为选择支新增了 \pout 转义符，具体同上
#
#----------------------------------------------------------------------------
# ○ 若使用了【Add-On 大文本框 by老鹰】，将本插件置于其下
#
# - 为大文本框新增了 \pout 转义符，具体同上
#
#==============================================================================

module PARTICLE
  #--------------------------------------------------------------------------
  # ● 设置文字粒子移出的模板
  #  f 为粒子模板
  #  params 为变量参数的hash（一般由 pout 转义符获得）
  #--------------------------------------------------------------------------
  def self.pout_set_template(f, params)
    # v - 每帧移动像素值
    f.params[:speed].v = params[:v] || 2
    # vd - 每帧移动像素值的随机增减量
    f.params[:speed].var = params[:vd] || 1
    # t - opacity减为0前的持续运动时间（帧）
    f.params[:life].v = params[:t] || 40
    # td - 持续时间的随机增减量
    f.params[:life].var = params[:td] || 20
    # a - 初始运动朝向角度（270为竖直向上方向）（0~360）
    f.params[:theta].v = params[:a] || 270
    # ad - 初始朝向角度的随机增减量
    f.params[:theta].var = params[:ad] || 90
    # va - 每帧旋转的角度
    f.params[:angle].v = params[:va] || 0
    # vad - 旋转角度的随机增减量
    f.params[:angle].var = params[:vad] || 3

    # 依据type变量，来进行额外的自定义设置
    case params[:type]
    when 1 # 无变更
    when 2 # 下坠
      f.params[:force] = Vector.new(0, 2)
    end
  end
  #--------------------------------------------------------------------------
  # ● 启用文字粒子
  #--------------------------------------------------------------------------
  def self.pout(sym, charas, params)
    if PARTICLE.emitters[sym]
      f = PARTICLE.emitters[sym].template
    else
      f = ParticleTemplate_BitmapNoDup.new
    end
    # 一次性生成完
    f.flag_start_once = true
    # 结束后释放位图
    f.flag_dispose_bitmap = true
    # 设置显示端口
    if PARTICLE.emitters[sym]
      vp = PARTICLE.emitters[sym].viewport
    else
      vp = Viewport.new
    end
    vp.z = 1000
    vp.add_fast_layer(1, 0) if $RGD # 整合RGD加速
    # 初始化
    PARTICLE.setup(sym, f, vp)
    # 设置模板属性
    pout_set_template(f, params)
    # 将文字精灵的拷贝放入模板
    f.params[:total] = charas.size
    f.params[:bitmaps] = charas.collect { |s| s.bitmap.dup }
    f.params[:xys] = charas.collect { |s|
      x = s.x + s.width/2; y = s.y + s.height/2
      if s.viewport
        x += s.viewport.rect.x
        y += s.viewport.rect.y
      end
      Vector.new(x, y)
    }
    # 发射器开始工作
    PARTICLE.start(sym)
  end
end

#==============================================================================
# ○ 整合 对话框扩展
#==============================================================================
if $imported["EAGLE-MessageEX"]
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
class Window_EagleMessage
  #--------------------------------------------------------------------------
  # ● 移出全部文字精灵
  #--------------------------------------------------------------------------
  alias eagle_particle_out_sprites_move_out eagle_message_sprites_move_out
  def eagle_message_sprites_move_out
    if game_message.pout_params[:type] && game_message.pout_params[:type] > 0
      if win_params[:cwo] > 0
        while(!@eagle_chara_sprites.empty?)
          c = eagle_take_out_a_chara
          ensure_character_visible(c)
          c.finish
          PARTICLE.pout(:msg_charas, [c], game_message.pout_params)
          win_params[:cwo].times { Fiber.yield }
        end
      else
        charas = @eagle_chara_sprites.select { |s| !s.finish? }
        charas.each { |s| s.finish }
        PARTICLE.pout(:msg_charas, charas, game_message.pout_params)
      end
      @eagle_chara_sprites.each { |s| s.move_out }
      @eagle_chara_sprites.clear
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
end

#==============================================================================
# ○ 整合 AddOn 大文本框
#==============================================================================
if $imported["EAGLE-MessageBox"]
module MESSAGE_EX; BOX_PARAMS_INIT[:pout] = {}; end
class Window_EagleMessage_Box < Window_Base
  #--------------------------------------------------------------------------
  # ● 移出全部文字精灵
  #--------------------------------------------------------------------------
  alias eagle_particle_out_charas_move_out chara_sprites_move_out
  def chara_sprites_move_out
    if pout_params[:type] && pout_params[:type] > 0
      if win_params[:cwo] > 0
        @eagle_chara_sprites.each do |s|
          next if s.finish?
          s.finish
          PARTICLE.pout(:st_charas, [s], pout_params)
          win_params[:cwo].times { Fiber.yield }
        end
      else
        charas = @eagle_chara_sprites.select { |s| !s.finish? }
        charas.each { |s| s.finish }
        PARTICLE.pout(:st_charas, charas, pout_params)
      end
      @eagle_chara_sprites.each { |s| s.move_out }
      @eagle_chara_sprites.clear
    else
      eagle_particle_out_charas_move_out
    end
  end
  #--------------------------------------------------------------------------
  # ● 设置pout参数
  #--------------------------------------------------------------------------
  def pout_params; params[:pout]; end
  def eagle_text_control_pout(param = '0')
    parse_param(params[:pout], param, :type)
  end
end
end

#==============================================================================
# ○ 整合 AddOn 选择框扩展
#==============================================================================
if $imported["EAGLE-ChoiceEX"]
class Spriteset_Choice
  attr_reader :pout_params
  #--------------------------------------------------------------------------
  # ● 移出
  #--------------------------------------------------------------------------
  alias eagle_particle_out_move_out move_out
  def move_out
    if @pout_params && pout_params[:type] > 0
      charas = @charas.select { |s| !s.finish? }
      charas.each { |s| s.finish }
      PARTICLE.pout("choice_#{@i_w}".to_sym, charas, @pout_params)
    end
    eagle_particle_out_move_out
  end
  #--------------------------------------------------------------------------
  # ● 控制符的处理
  #--------------------------------------------------------------------------
  alias eagle_particle_out_escape_chara process_escape_character
  def process_escape_character(code, text, pos)
    case code.upcase
    when 'POUT'
      @pout_params = { :type => 0 }
      MESSAGE_EX.parse_param(@pout_params,
        message_window.obtain_escape_param_string(text), :type)
    else
      eagle_particle_out_escape_chara(code, text, pos)
    end
  end
end
end
