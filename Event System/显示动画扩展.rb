#==============================================================================
# ■ 显示动画扩展 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
$imported ||= {}
$imported["EAGLE-AnimEX"] = true
#==============================================================================
# - 2020.2.12.21
#==============================================================================
# - 本插件扩展了显示动画的脚本指令
#--------------------------------------------------------------------------
# - 在屏幕上的像素坐标 (x,y) 处显示 anim_id 序号的动画
#    并返回显示该动画所用的精灵 s
#     s = ANIM_EX.screen(anim_id, x, y)
#
# - 在 event_id 号事件上显示 anim_id 序号的动画
#    并返回显示该动画所用的精灵 s
#     s = ANIM_EX.event(anim_id, event_id)
#
# - 在地图上的网格坐标 (x,y) 处 anim_id 序号的动画
#    并返回显示该动画所用的精灵 s
#     s = ANIM_EX.map(anim_id, x, y)
#
# - 获取地图上全部事件（含玩家）的精灵的数组
#     ss = ANIM_EX.all_chara_sprites
#
# - 停止全部扩展显示的动画
#     ANIM_EX.stop_all
#
# - Sprite_Base 类新增方法一览：
#     .stop_animation  → 中止当前动画
#     .bind_eval(frame_index, eval_string)  → 为下一次显示动画绑定执行脚本
#                          在第 frame_index 帧时执行 eval(eval_string)
#     .bind_evals(evals_hash)  → 为下一次显示动画绑定执行脚本
#                          evals_hash 为帧序号到执行脚本的映射
#                          evals_hash = { frame_index => eval_string }
#==============================================================================

module ANIM_EX
  #--------------------------------------------------------------------------
  # ● 在屏幕显示动画
  #--------------------------------------------------------------------------
  def self.screen(anim_id, x, y)
    s = empty_sprite
    s.bind_screen(x, y)
    s.eagle_start_animation(anim_id)
    s
  end
  #--------------------------------------------------------------------------
  # ● 在事件上显示动画
  #  event_id 为 0 时为玩家，正数为当前地图事件（同事件-显示动画）
  #--------------------------------------------------------------------------
  def self.event(anim_id, event_id)
    return if !SceneManager.scene_is?(Scene_Map)
    s = empty_sprite
    c = nil
    case event_id
    when 0; c = $game_player
    else; c = $game_map.events[event_id] rescue nil
    end
    s.bind_character(c) if c
    s.eagle_start_animation(anim_id)
    s
  end
  #--------------------------------------------------------------------------
  # ● 在地图指定位置显示动画
  #  x/y 为地图上的坐标
  #--------------------------------------------------------------------------
  def self.map(anim_id, x, y)
    s = empty_sprite
    s.bind_map(x, y)
    s.eagle_start_animation(anim_id)
    s
  end
  #--------------------------------------------------------------------------
  # ● 显示动画的精灵
  #--------------------------------------------------------------------------
  @@sprites = []
  #--------------------------------------------------------------------------
  # ● 获取一个闲置精灵
  #--------------------------------------------------------------------------
  def self.empty_sprite
    i = @@sprites.index { |s| !s.animation? }
    return @@sprites[i].reset if i
    s = Sprite_EagleBase.new
    @@sprites.push(s)
    return s
  end
  #--------------------------------------------------------------------------
  # ● 更新动画
  #--------------------------------------------------------------------------
  def self.update
    @@sprites.each { |s| s.update if s.animation? }
  end
  #--------------------------------------------------------------------------
  # ● 停止全部动画
  #--------------------------------------------------------------------------
  def self.stop_all
    @@sprites.each { |s| s.stop_animation if s.animation? }
  end
  #--------------------------------------------------------------------------
  # ● 获取全部事件的精灵
  #--------------------------------------------------------------------------
  def self.all_chara_sprites
    return [] if !SceneManager.scene_is?(Scene_Map)
    return SceneManager.scene.spriteset.character_sprites
  end
end
#=============================================================================
# ○ Sprite_Base
#=============================================================================
class Sprite_Base < Sprite
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  alias eagle_anim_ex_init initialize
  def initialize(viewport = nil)
    eagle_anim_ex_init(viewport)
    @eagle_binds = {} # frame_index => eval
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）更新动画
  #--------------------------------------------------------------------------
  def update_animation
    return unless animation?
    @ani_duration -= 1
    if @ani_duration % @ani_rate == 0
      if @ani_duration > 0
        frame_index = @animation.frame_max
        frame_index -= (@ani_duration + @ani_rate - 1) / @ani_rate
        animation_set_sprites(@animation.frames[frame_index])
        apply_frame_evals(frame_index)
        @animation.timings.each do |timing|
          animation_process_timing(timing) if timing.frame == frame_index
        end
      else
        end_animation
      end
    end
  end
  #--------------------------------------------------------------------------
  # ○ 执行第 frame_index 帧时的额外脚本
  #--------------------------------------------------------------------------
  def apply_frame_evals(frame_index)
    if @eagle_binds[frame_index]
      s = $game_switches; v = $game_variables
      e = $game_map.events
      eval( @eagle_binds[frame_index] )
    end
  end
  #--------------------------------------------------------------------------
  # ○ 中止动画
  #--------------------------------------------------------------------------
  def stop_animation
    @ani_duration = 0 # 剩余动画时间（帧）
    end_animation
  end
  #--------------------------------------------------------------------------
  # ● 结束动画
  #--------------------------------------------------------------------------
  alias eagle_anim_ex_end_animation end_animation
  def end_animation
    eagle_anim_ex_end_animation
    @eagle_binds.clear
  end
  #--------------------------------------------------------------------------
  # ○ 绑定脚本执行
  #--------------------------------------------------------------------------
  def bind_eval(frame_count, eval_string)
    @eagle_binds[frame_count] = eval_string
  end
  #--------------------------------------------------------------------------
  # ○ 绑定脚本执行
  #--------------------------------------------------------------------------
  def bind_evals(hash)
    @eagle_binds.merge!(hash)
  end
end
#=============================================================================
# ○ Sprite_EagleBase
#=============================================================================
class Sprite_EagleBase < Sprite_Base
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #     character : Game_Character
  #--------------------------------------------------------------------------
  def initialize(viewport = nil)
    super(viewport)
    self.ox = 16
    self.oy = 32
    reset
  end
  #--------------------------------------------------------------------------
  # ● 重置绑定
  #--------------------------------------------------------------------------
  def reset
    @character = nil
    @map_x = @map_y = nil
    stop_animation
    self
  end
  #--------------------------------------------------------------------------
  # ● 绑定显示到屏幕
  #--------------------------------------------------------------------------
  def bind_screen(x, y)
    self.x = x
    self.y = y
    update_position
  end
  #--------------------------------------------------------------------------
  # ● 绑定显示在事件上
  #--------------------------------------------------------------------------
  def bind_character(character)
    @character = character
    update_position
  end
  #--------------------------------------------------------------------------
  # ● 绑定显示在地图上
  #--------------------------------------------------------------------------
  def bind_map(map_x, map_y)
    @map_x = map_x
    @map_y = map_y
    update_position
  end
  #--------------------------------------------------------------------------
  # ● 更新画面
  #--------------------------------------------------------------------------
  def update
    super
    update_position
  end
  #--------------------------------------------------------------------------
  # ● 更新位置
  #--------------------------------------------------------------------------
  def update_position
    if @character
      self.x = @character.screen_x
      self.y = @character.screen_y
      self.z = @character.screen_z
      return
    end
    if @map_x
      if $imported["EAGLE-PixelMove"]
        x_, e_ = PIXEL_MOVE.rgss2unit(@map_x)
        self.x = PIXEL_MOVE.unit2pixel($game_map.adjust_x(x_))
        y_, e_ = PIXEL_MOVE.rgss2unit(@map_y)
        self.y = PIXEL_MOVE.unit2pixel($game_map.adjust_y(y_))
        return
      end
      self.x = $game_map.adjust_x(@map_x) * 32 + 16
      self.y = $game_map.adjust_y(@map_y) * 32 + 32
      return
    end
  end
  #--------------------------------------------------------------------------
  # ● 显示动画
  #--------------------------------------------------------------------------
  def eagle_start_animation(anim_id)
    animation = $data_animations[anim_id]
    start_animation(animation)
  end
end
#=============================================================================
# ○ Scene_Base
#=============================================================================
class Scene_Base
  #--------------------------------------------------------------------------
  # ● 更新画面（基础）
  #--------------------------------------------------------------------------
  alias eagle_anim_ex_update_basic update_basic
  def update_basic
    eagle_anim_ex_update_basic
    ANIM_EX.update
  end
end
#=============================================================================
# ○ Scene_Map
#=============================================================================
class Spriteset_Map; attr_reader :character_sprites ; end
class Scene_Map < Scene_Base; attr_reader :spriteset; end
