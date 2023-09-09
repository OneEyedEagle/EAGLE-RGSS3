#==============================================================================
# ■ 游戏运行倍速切换  by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
#==============================================================================
$imported ||= {}
$imported["EAGLE-SpeedUp"] = "1.0.0"
#==============================================================================
# - 2019.3.21.10
#==============================================================================
# - 新增在地图、战斗场景中，按下指定键后按顺序变更游戏运行倍速
# - 每一次Scene切换，都会将速率重置为 1 倍
# - 高级：
#     对于其它的需要允许切换倍速的Scene场景，
#     只需添加返回 true 的 update_speed_up? 方法
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
  TIMES = [1, 1.5, 2]
  #--------------------------------------------------------------------------
  # ● 改变倍率
  #--------------------------------------------------------------------------
  def self.change_index
    @index += 1
    @index = 0 if @index >= TIMES.size
    @count = 0
    redraw_hint
  end
  #--------------------------------------------------------------------------
  # ● 重置
  #--------------------------------------------------------------------------
  def self.reset_index
    return if @index == 0
    @index = 0
    @count = 0
    redraw_hint
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
    @sprite_hint.opacity -= 1
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
    v = EAGLE::SpeedUp::TIMES[EAGLE::SpeedUp::index]
    EAGLE::SpeedUp.count += 1
    return if EAGLE::SpeedUp.count < v
    EAGLE::SpeedUp.count -= v
    eagle_speed_up_update
  end
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
  # ● 结束处理
  #--------------------------------------------------------------------------
  alias eagle_speed_up_terminate terminate
  def terminate
    EAGLE::SpeedUp.reset_index
    eagle_speed_up_terminate
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
