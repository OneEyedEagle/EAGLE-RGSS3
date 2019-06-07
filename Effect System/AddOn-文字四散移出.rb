#==============================================================================
# ■ Add-On 文字四散移出 by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【Add-On 部分粒子模板 by老鹰】之下
#==============================================================================
# - 2019.6.7.12 重写
#==============================================================================
# - 本插件为 文字精灵组的粒子化 实现了一个简单便捷的调用接口
#----------------------------------------------------------------------------
# - 若使用了【对话框扩展 by老鹰】，将本插件置于其下，可为其增加 \pout 转义符，
#   对话文本将调用预设粒子模板，来进行文字移出（覆盖 \cout 效果）
#      type -【默认】设置选用的粒子移出类型（0为取消）
#      其余见 ParticleManager#pout_set_template 方法中 params 所取的值
#----------------------------------------------------------------------------
# - 若使用了【Add-On 选择框扩展 by老鹰】，将本插件置于其下，同样可为
#   选择支新增 \pout 转义符，具体同上
#----------------------------------------------------------------------------
# - 若使用了【Add-On 滚动文本框扩展 by老鹰】，将本插件置于其下，同样可为其
#   新增 \pout 转义符，具体同上
#==============================================================================

#==============================================================================
# ○ ParticleManager
#==============================================================================
module ParticleManager
  #--------------------------------------------------------------------------
  # ● 设置文字粒子移出的模板
  #  f 为粒子模板
  #  params 为变量参数的hash（一般由 pout 转义符获得）
  #--------------------------------------------------------------------------
  def self.pout_set_template(f, params)
    # v - 每帧移动像素值
    f.speed = params[:v] || 2
    # vd - 每帧移动像素值的随机增减量
    f.speed_var = params[:vd] || 1
    # t - opacity减为0前的持续运动时间（帧）
    f.life = params[:t] || 40
    # td - 持续时间的随机增减量
    f.life_var = params[:td] || 20
    # a - 初始运动朝向角度（270为竖直向上方向）（0~360）
    f.theta = params[:a] || 270
    # ad - 初始朝向角度的随机增减量
    f.theta_var = params[:ad] || 90
    # va - 每帧旋转的角度
    f.angle = params[:va] || 0
    # vad - 旋转角度的随机增减量
    f.angle_var = params[:vad] || 3

    # 依据type变量，来进行额外的自定义设置
    case params[:type]
    when 1 # 无变更
    when 2 # 下坠
      f.global_force = Vector.new(0, 2)
    end
  end
  #--------------------------------------------------------------------------
  # ● 启用文字粒子
  #--------------------------------------------------------------------------
  def self.pout(sym, charas, params)
    if ParticleManager.emitters[sym]
      f = ParticleManager.emitters[sym].template
    else
      f = Particle_Template_BitmapNoDup.new
    end
    # 一次性生成完
    f.for_once = true
    # 结束后释放位图
    f.bitmap_dispose = true
    # 设置显示端口
    if ParticleManager.emitters[sym]
      vp = ParticleManager.emitters[sym].viewport
    else
      vp = Viewport.new
    end
    vp.z = 1000
    vp.add_fast_layer(1, 0) if $RGD # 整合RGD加速
    # 初始化
    ParticleManager.setup(sym, f, vp)
    # 设置模板属性
    pout_set_template(f, params)
    # 将文字精灵的拷贝放入模板
    f.total = charas.size
    f.bitmaps = charas.collect { |s| s.bitmap.dup }
    f.xys = charas.collect { |s| Vector.new(s.x + s.width/2, s.y + s.height/2) }
    # 发射器开始工作
    ParticleManager.start(sym)
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
class Window_Message
  #--------------------------------------------------------------------------
  # ● 移出全部文字精灵
  #--------------------------------------------------------------------------
  alias eagle_particle_out_sprites_move_out eagle_message_sprites_move_out
  def eagle_message_sprites_move_out
    if game_message.pout_params[:type] && game_message.pout_params[:type] > 0
      if win_params[:cwo] > 0
        @eagle_chara_sprites.each do |s|
          next if s.finish?
          ParticleManager.pout(:msg_charas, [s], game_message.pout_params)
          s.opacity = 0
          win_params[:cwo].times { Fiber.yield }
        end
      else
        charas = @eagle_chara_sprites.select { |s| !s.finish? }
        ParticleManager.pout(:msg_charas, charas, game_message.pout_params)
      end
      @eagle_chara_sprites.each { |s| s.opacity = 0; s.move_out }
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
# ○ 整合 AddOn 滚动文本框扩展
#==============================================================================
if $imported["EAGLE-ScrollTextEX"]
module MESSAGE_EX; SCROLL_PARAMS_INIT[:pout] = {}; end
class Window_ScrollText < Window_Base
  #--------------------------------------------------------------------------
  # ● 移出全部文字精灵
  #--------------------------------------------------------------------------
  alias eagle_particle_out_charas_move_out chara_sprites_move_out
  def chara_sprites_move_out
    if pout_params[:type] && pout_params[:type] > 0
      if win_params[:cwo] > 0
        @eagle_chara_sprites.each do |s|
          next if s.finish?
          s.opacity = 0
          ParticleManager.pout(:st_charas, [s], pout_params)
          win_params[:cwo].times { Fiber.yield }
        end
      else
        charas = @eagle_chara_sprites.select { |s| !s.finish? }
        ParticleManager.pout(:st_charas, charas, pout_params)
      end
      @eagle_chara_sprites.each { |s| s.opacity = 0; s.move_out }
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
      ParticleManager.pout("choice_#{@i_w}".to_sym, charas, @pout_params)
      @charas.each { |s| s.opacity = 0 }
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
