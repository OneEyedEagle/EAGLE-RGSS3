#==============================================================================
# ■ Add-On 跳过对话 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【对话框扩展 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-MessageSkip"] = "1.1.1"
#==============================================================================
# - 2024.10.20.17 修复在兼容模式中无法消失的bug
#==============================================================================
# - 本插件为对话框新增了对话跳过的UI
#----------------------------------------------------------------------------
# 【使用】
#
#    长按空格，会显示一个按键提示精灵，具体可在下列常量中设置。
#
#    按住一段时间后，将启用对话的自动跳过。
#
# 【注意】
#
#    对话框原本的快进设置 MESSAGE_EX.force_close? 失效，以该插件的设置为准。
#
#    该跳过会直接忽略掉全部的等待类的转义符。
#
#    在绘制一定量文字后，将等待1帧并刷新显示，防止出现卡死情况。
#
#==============================================================================
module MESSAGE_EX
  #--------------------------------------------------------------------------
  # ○【常量】当事件未执行，且持续该帧数未开启对话框时，阻止对话跳过UI的显示
  #--------------------------------------------------------------------------
  SKIP_COUNT_SHOW_MAX = 60

  #--------------------------------------------------------------------------
  # ○【常量】长按该键持续一定帧数后，启用对话跳过功能
  #--------------------------------------------------------------------------
  SKIP_KEY = :C  # 确定键（z键、空格）
  #--------------------------------------------------------------------------
  # ○【常量】所需的按键持续帧数
  #--------------------------------------------------------------------------
  SKIP_COUNT_MAX = 60
  #--------------------------------------------------------------------------
  # ○【常量】按键持续计数的初值（负数是为了确保不过于频繁响应对话的按键继续）
  #--------------------------------------------------------------------------
  SKIP_COUNT_MIN = -20

  #--------------------------------------------------------------------------
  # ○【常量】精灵中央显示的文本
  #--------------------------------------------------------------------------
  SKIP_HINT_TEXT = "跳过"

  #--------------------------------------------------------------------------
  # ○【常量】精灵的显示原点类型
  #
  #  按九宫格小键盘，将精灵的显示原点分成了9个类型（4个顶点，4个边中点，中心点）
  #   1代表左下角为原点，5代表中心点为原点，9代表右上角为原点
  #--------------------------------------------------------------------------
  SKIP_SHOW_O  = 5
  #--------------------------------------------------------------------------
  # ○【常量】精灵的显示位置类型
  #
  #   1~ 9 代表在对话框的对应位置，如1代表在对话框的左下角，5代表对话框中心
  #  -1~-9 代表在屏幕对应位置，如-1代表在屏幕左下角，5代表在屏幕中心
  #--------------------------------------------------------------------------
  SKIP_SHOW_DO_MSG = -5  # 对话框开启时，快进精灵的显示位置
  SKIP_SHOW_DO_WIN = -5  # 对话框关闭时，快进精灵的显示位置

  #--------------------------------------------------------------------------
  # ○【常量】精灵的x坐标增量
  #--------------------------------------------------------------------------
  SKIP_SHOW_DX = 0
  #--------------------------------------------------------------------------
  # ○【常量】精灵的y坐标增量
  #--------------------------------------------------------------------------
  SKIP_SHOW_DY = 100

  #--------------------------------------------------------------------------
  # ○【常量】精灵位图的宽度
  #--------------------------------------------------------------------------
  SKIP_SPRITE_W = 60
  #--------------------------------------------------------------------------
  # ○【常量】精灵位图的高度
  #--------------------------------------------------------------------------
  SKIP_SPRITE_H = 40

  #--------------------------------------------------------------------------
  # ○【常量】精灵的z值增加量（以对话框的z值为初始值）
  #--------------------------------------------------------------------------
  SKIP_SPRITE_Z = +20

  #--------------------------------------------------------------------------
  # ○ 屏蔽掉对话框原本的设置
  #--------------------------------------------------------------------------
  def self.force_close?
    false
  end
end

#=============================================================================
# ○ Window_EagleMessage
#=============================================================================
class Window_EagleMessage
  #--------------------------------------------------------------------------
  # ● 生成所有子窗口
  #  在此方法里生成精灵，阻止了继承对话框的窗口获得该功能
  #--------------------------------------------------------------------------
  alias eagle_skip_dialog_create_all_windows create_all_windows
  def create_all_windows
    eagle_skip_dialog_create_all_windows
    @sprite_skip = Sprite_EagleMsgSkip.new(self)
  end
  #--------------------------------------------------------------------------
  # ● 释放所有窗口
  #--------------------------------------------------------------------------
  alias eagle_skip_dialog_dispose_all_windows dispose_all_windows
  def dispose_all_windows
    @sprite_skip.dispose
    eagle_skip_dialog_dispose_all_windows
  end
  #--------------------------------------------------------------------------
  # ● 更新所有窗口
  #--------------------------------------------------------------------------
  alias eagle_skip_dialog_update_all_windows update_all_windows
  def update_all_windows
    eagle_skip_dialog_update_all_windows
    @sprite_skip.update
    force_close if @sprite_skip && @sprite_skip.active?
  end
  #--------------------------------------------------------------------------
  # ● 兼容模式中，切换到其它对话框时的处理
  #--------------------------------------------------------------------------
  alias eagle_skip_dialog_before_switch process_before_switch_to_other_message
  def process_before_switch_to_other_message
    eagle_skip_dialog_before_switch
    @sprite_skip.deactivate 
  end
end

#=============================================================================
# ○ SKIP精灵
#=============================================================================
class Sprite_EagleMsgSkip < Sprite
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(window_bind)
    super(nil)
    bind_window(window_bind)
    deactivate
    init_bitmap
  end
  def bind_window(window_bind); @window_bind = window_bind; end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    self.bitmap.dispose
    @temp_bitmap.dispose
    super
  end
  #--------------------------------------------------------------------------
  # ● 初始化位图
  #--------------------------------------------------------------------------
  def init_bitmap
    self.bitmap = Bitmap.new(MESSAGE_EX::SKIP_SPRITE_W,
      MESSAGE_EX::SKIP_SPRITE_H)
    self.bitmap.font.color = Color.new(255,255,255,150)
    self.bitmap.font.shadow = false
    self.bitmap.font.outline = false
    # 用于复制反色文字
    @temp_bitmap = Bitmap.new(self.width, self.height)
    @temp_bitmap.font.color = Color.new(0,0,0,255)
    @temp_bitmap.font.shadow = false
    @temp_bitmap.font.outline = false
    t = MESSAGE_EX::SKIP_HINT_TEXT
    @temp_bitmap.draw_text(0, 0, self.width, self.height, t, 1)
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    update_show
    update_count if show?
    update_when_visible if self.visible
  end
  #--------------------------------------------------------------------------
  # ● 更新UI显示计数
  #--------------------------------------------------------------------------
  def update_show
    return @count_show = 0 if @window_bind.openness > 0
    return if $game_map.interpreter.running?
    @count_show += 1
    # 当该计数到一定值时，阻止呼叫快进（对话框打开则重置为0）
    deactivate if @count_show == MESSAGE_EX::SKIP_COUNT_SHOW_MAX
  end
  #--------------------------------------------------------------------------
  # ● 满足UI出现的条件？
  #--------------------------------------------------------------------------
  def show?
    @count_show < MESSAGE_EX::SKIP_COUNT_SHOW_MAX
  end
  #--------------------------------------------------------------------------
  # ● 更新计数
  #--------------------------------------------------------------------------
  def update_count
    if Input.press?(MESSAGE_EX::SKIP_KEY)
      @count += 1
    else
      @count -= 3
    end
    @count = count_max if @count > count_max
    @count = count_min if @count < count_min
    activate if @count > 0
    deactivate if @count <= count_min
  end
  #--------------------------------------------------------------------------
  # ● 可见时更新
  #--------------------------------------------------------------------------
  def update_when_visible
    redraw if @count_last != @count
    update_position
  end
  #--------------------------------------------------------------------------
  # ● 更新位置
  #--------------------------------------------------------------------------
  def update_position
    MESSAGE_EX.reset_sprite_oxy(self, MESSAGE_EX::SKIP_SHOW_O)
    if @window_bind.openness == 255
      MESSAGE_EX.reset_xy_dorigin(self, @window_bind, MESSAGE_EX::SKIP_SHOW_DO_MSG)
    else
      MESSAGE_EX.reset_xy_dorigin(self, @window_bind, MESSAGE_EX::SKIP_SHOW_DO_WIN)
    end
    self.x += MESSAGE_EX::SKIP_SHOW_DX
    self.y += MESSAGE_EX::SKIP_SHOW_DY
    self.z = @window_bind.z + MESSAGE_EX::SKIP_SPRITE_Z
  end
  #--------------------------------------------------------------------------
  # ● 激活显示
  #--------------------------------------------------------------------------
  def activate
    self.visible = true
  end
  #--------------------------------------------------------------------------
  # ● 隐藏
  #--------------------------------------------------------------------------
  def deactivate
    @count = count_min
    @count_last = @count - 1
    self.visible = false
    @count_show = MESSAGE_EX::SKIP_COUNT_SHOW_MAX
  end
  #--------------------------------------------------------------------------
  # ● 满足跳过对话的条件？
  #--------------------------------------------------------------------------
  def active?
    @count >= count_max
  end
  #--------------------------------------------------------------------------
  # ● 计数上下限
  #--------------------------------------------------------------------------
  def count_min; MESSAGE_EX::SKIP_COUNT_MIN; end
  def count_max; MESSAGE_EX::SKIP_COUNT_MAX; end
  #--------------------------------------------------------------------------
  # ● 计数比例
  #--------------------------------------------------------------------------
  def count_rate
    @count * 1.0 / count_max
  end
  #--------------------------------------------------------------------------
  # ● 重绘
  #--------------------------------------------------------------------------
  def redraw
    @count_last = @count
    b = self.bitmap
    b.clear
    b.fill_rect(0, 0, self.width, self.height, Color.new(255,255,255,150))
    _y = self.height*(1-count_rate)
    r = Rect.new(1, 1, self.width-2, _y-2)
    b.fill_rect(r, Color.new(0,0,0,150))
    # 绘制正色文字
    t = MESSAGE_EX::SKIP_HINT_TEXT
    b.draw_text(0, 0, self.width, self.height, t, 1)
    # 绘制反色文字
    r2 = Rect.new(0, _y, self.width, self.height)
    b.blt(0, _y, @temp_bitmap, r2)
  end
end
