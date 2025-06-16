#==============================================================================
# ■ 游戏运行倍速切换  by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
#==============================================================================
$imported ||= {}
$imported["EAGLE-SpeedUp"] = "1.1.2"
#==============================================================================
# - 2025.5.25.12 倍率未变时，提示文本不显示
#==============================================================================
# - 新增在地图、战斗场景中，按下指定键后按顺序变更游戏运行倍速
#
# - 每一次Scene切换，都会将速率重置为它上一次保存的运行倍速
#
# 【兼容】
#
# - 对于其它的需要允许切换倍速的Scene场景，只需在该 Scene 中添加：
=begin
def update_speed_up?
  return true
end
=end
#==============================================================================
module EAGLE; end
module EAGLE::SpeedUp
  #--------------------------------------------------------------------------
  # ●【设置】定义变更按键
  #--------------------------------------------------------------------------
  def self.key
    :CTRL
  end
  #--------------------------------------------------------------------------
  # ● 【设置】定义倍率数组
  #--------------------------------------------------------------------------
  TIMES = [1, 2, 4]
  #--------------------------------------------------------------------------
  # ● 改变倍率
  #--------------------------------------------------------------------------
  def self.change_index(i = nil)
    last_index = @index
    if i.nil?
      @index += 1
      @index = 0 if @index >= TIMES.size
    else
      @index = i.to_i
    end
    @count = 0
    redraw_hint if last_index != @index
  end
  #--------------------------------------------------------------------------
  # ● 获取当前倍率
  #--------------------------------------------------------------------------
  def self.current
    TIMES[@index]
  end
  def self.index
    @index
  end
  #--------------------------------------------------------------------------
  # ● 重置
  #--------------------------------------------------------------------------
  def self.reset_index
    return if @index == 0
    change_index(0)
  end
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  class << self; attr_accessor :count, :index; end
  def self.init
    @index = 0
    @count = 0
    @sprite_hint = Sprite.new
    @sprite_hint.z = 380
    @sprite_hint.bitmap = Bitmap.new(Graphics.width, Graphics.height)
    @sprite_hint.bitmap.font.size = 81
  end
  #--------------------------------------------------------------------------
  # ● 重绘提示文本
  #--------------------------------------------------------------------------
  def self.redraw_hint
    @sprite_hint.bitmap.clear
    @sprite_hint.bitmap.draw_text(@sprite_hint.bitmap.rect, "#{TIMES[@index]}×", 1)
    @sprite_hint.opacity = 200
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def self.ui_update
    @sprite_hint.opacity -= 2
  end
  #--------------------------------------------------------------------------
  # ● 提示文本显隐
  #--------------------------------------------------------------------------
  def self.ui_hide
    @sprite_hint.visible = false
  end
  def self.ui_show
    @sprite_hint.visible = true
  end
end

class << Graphics
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  alias eagle_speed_up_update update
  def update
    v = EAGLE::SpeedUp.current
    EAGLE::SpeedUp.count += 1
    return if EAGLE::SpeedUp.count < v
    EAGLE::SpeedUp.count -= v
    eagle_speed_up_update
  end
end

class Game_System
  attr_accessor  :scene2speedup  # scene_class => speed up index
end

class << SceneManager
  #--------------------------------------------------------------------------
  # ● 开始
  #--------------------------------------------------------------------------
  alias eagle_speed_up_run run
  def run
    EAGLE::SpeedUp.init
    eagle_speed_up_run
  end
  #--------------------------------------------------------------------------
  # ● 截图
  #--------------------------------------------------------------------------
  alias eagle_speed_up_snapshot_for_background snapshot_for_background
  def snapshot_for_background
    EAGLE::SpeedUp.ui_hide
    eagle_speed_up_snapshot_for_background
    EAGLE::SpeedUp.ui_show
  end
end

class Scene_Base
  #--------------------------------------------------------------------------
  # ● 开始后处理
  #--------------------------------------------------------------------------
  alias eagle_speed_up_post_start post_start
  def post_start
    eagle_speed_up_post_start
    $game_system.scene2speedup ||= {}
    i = $game_system.scene2speedup[self.class]
    if i
      EAGLE::SpeedUp.change_index(i) 
    else
      EAGLE::SpeedUp.reset_index
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新画面（基础）
  #--------------------------------------------------------------------------
  alias eagle_speed_up_update_basic update_basic
  def update_basic
    if update_speed_up? && Input.trigger?(EAGLE::SpeedUp.key)
      Sound.play_cursor
      EAGLE::SpeedUp.change_index
    end
    EAGLE::SpeedUp.ui_update
    eagle_speed_up_update_basic
  end
  #--------------------------------------------------------------------------
  # ● 允许更新快进？
  #--------------------------------------------------------------------------
  def update_speed_up?
    false
  end
  #--------------------------------------------------------------------------
  # ● 结束前处理
  #--------------------------------------------------------------------------
  alias eagle_speed_up_pre_terminate pre_terminate
  def pre_terminate
    eagle_speed_up_pre_terminate
    $game_system.scene2speedup ||= {}
    $game_system.scene2speedup[self.class] = EAGLE::SpeedUp.index
  end
end

class Scene_Map < Scene_Base
  #--------------------------------------------------------------------------
  # ● 允许更新快进？
  #--------------------------------------------------------------------------
  def update_speed_up?
    true
  end
end
class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # ● 允许更新快进？
  #--------------------------------------------------------------------------
  def update_speed_up?
    true
  end
end
