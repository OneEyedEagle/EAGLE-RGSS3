#==============================================================================
# ■ 战斗日志美化 by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【组件-位图绘制转义符文本 by老鹰】之下
#==============================================================================
# - 2020.7.3.13
#==============================================================================
$imported ||= {}
$imported["EAGLE-BattleLog"] = true
#==============================================================================
# - 本插件覆盖了默认的战斗日志，并实现了单行文本的精灵队列
# - 本插件中的战斗日志为并行更新，不再等待显示与全部清除
#==============================================================================

class Window_BattleLog < Window_Selectable
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize
    super(0, 0, Graphics.width, fitting_height(1))
    self.opacity = 0
    @lines = [] # 存储sprite block对象的数组
    @index = 0  # 插入的新文本块的位置
    @shift_count = 0 # 消除第一行的等待用计数
  end
  #--------------------------------------------------------------------------
  # ● 最多同时存在的文本行数
  #--------------------------------------------------------------------------
  def max_line_number
    4
  end
  #--------------------------------------------------------------------------
  # ● 每隔指定帧数自动消去首行
  #--------------------------------------------------------------------------
  def auto_shift_frame
    150
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
    hide
    return if @lines.empty?
    @lines.each { |item| item.update }
    @shift_count += 1
    shift_text if @index >= max_line_number || @shift_count > auto_shift_frame
    dispose_text if @lines[0].state == :fin
  end
  #--------------------------------------------------------------------------
  # ● 添加文本块
  #--------------------------------------------------------------------------
  def add_text(text)
    return if text == ""
    @lines.push(Window_Batterlog_Block.new(self, text, @lines.size))
    @index += 1
  end
  #--------------------------------------------------------------------------
  # ● 标记首行为移出状态
  #--------------------------------------------------------------------------
  def shift_text
    return if @lines.empty?
    @lines[0].state = :moveout if @lines[0].state == :movein
  end
  #--------------------------------------------------------------------------
  # ● 首行移出，其余行上移
  #--------------------------------------------------------------------------
  def dispose_text
    @shift_count = 0
    @index -= 1
    @lines.each { |item| item.index -= 1 }
    @lines.shift.dispose
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    super
    @lines.each { |item| item.dispose }
  end
  #--------------------------------------------------------------------------
  # ● 清除
  #--------------------------------------------------------------------------
  def clear
  end
  #--------------------------------------------------------------------------
  # ● 全部清除（移出）
  #--------------------------------------------------------------------------
  def clear_all
    @lines.each { |item| item.state = :moveout }
  end
  #--------------------------------------------------------------------------
  # ● 获取数据行数
  #--------------------------------------------------------------------------
  def line_number
    @lines.size
  end
  #--------------------------------------------------------------------------
  # ● 删除一行文字
  #--------------------------------------------------------------------------
  def back_one
    shift_text
  end
  #--------------------------------------------------------------------------
  # ● 返回指定行
  #--------------------------------------------------------------------------
  def back_to(line_number)
  end
  #--------------------------------------------------------------------------
  # ● 替换文字
  #    替换最后一段文字。
  #--------------------------------------------------------------------------
  def replace_text(text)
    add_text(text)
  end
  #--------------------------------------------------------------------------
  # ● 获取最下行的文字
  #--------------------------------------------------------------------------
  def last_text
    @lines.empty? ? "" : @lines[-1].text
  end
  #--------------------------------------------------------------------------
  # ● 刷新
  #--------------------------------------------------------------------------
  def refresh
  end
  #--------------------------------------------------------------------------
  # ● 等待
  #--------------------------------------------------------------------------
  def wait
  end
  #--------------------------------------------------------------------------
  # ● 等待效果执行的结束
  #--------------------------------------------------------------------------
  def wait_for_effect
  end
  #--------------------------------------------------------------------------
  # ● 等待并清除
  #    进行显示信息的最短等待，并在等待结束后清除信息。
  #--------------------------------------------------------------------------
  def wait_and_clear
    clear
  end
  #--------------------------------------------------------------------------
  # ● 显示伤害
  #--------------------------------------------------------------------------
  def display_damage(target, item)
    if target.result.missed
      display_miss(target, item)
    elsif target.result.evaded
      display_evasion(target, item)
    else
      return if defined?(SideView)
      display_hp_damage(target, item)
      display_mp_damage(target, item)
      display_tp_damage(target, item)
    end
  end
end

class Window_Batterlog_Block < Sprite
  attr_accessor :index, :state
  attr_reader :text
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(window, text, index)
    super(window.viewport)
    @text = text
    @index = index  # 用于记录本文本框处于哪个位置 自动依据位置调整y值
    @state = :movein
    self.bitmap = Bitmap.new(Graphics.width, line_height)
    self.x = -50
    self.y = get_y
    self.opacity = 0
    refresh
  end
  #--------------------------------------------------------------------------
  # ● 行高
  #--------------------------------------------------------------------------
  def line_height
    Font.default_size + 4
  end
  #--------------------------------------------------------------------------
  # ● 刷新重绘
  #--------------------------------------------------------------------------
  def refresh
    self.bitmap.clear
    draw_background
    draw_text
  end
  #--------------------------------------------------------------------------
  # ● 绘制背景
  #--------------------------------------------------------------------------
  def draw_background
    self.bitmap.gradient_fill_rect(self.bitmap.rect,
      Color.new(0,0,0,64), Color.new(0,0,0,10))
  end
  #--------------------------------------------------------------------------
  # ● 绘制文本
  #--------------------------------------------------------------------------
  def draw_text
    reset_font_settings
    d = Process_DrawTextEX.new(@text, {:x => [24], :y => [2]}, self.bitmap)
    d.run
  end
  #--------------------------------------------------------------------------
  # ● 重置文本参数
  #--------------------------------------------------------------------------
  def reset_font_settings
    self.bitmap.font.color = Color.new(255,255,255)
    self.bitmap.font.size = Font.default_size
    self.bitmap.font.bold = false
    self.bitmap.font.italic = false
    self.bitmap.font.outline = false
  end
  #--------------------------------------------------------------------------
  # ● 获取目的Y值
  #--------------------------------------------------------------------------
  def get_y
    @index = 0 if @index < 0
    @index * line_height + 10
  end
  #--------------------------------------------------------------------------
  # ● 更新Y值
  #--------------------------------------------------------------------------
  def update_y
    self.y -= 2 if self.y > get_y
  end
  #--------------------------------------------------------------------------
  # ● 更新X值和透明度
  #--------------------------------------------------------------------------
  def update_x_and_opacity #初始化与退出时有用
    case @state
    when :movein
      self.opacity += 26
      self.x += 4 if self.x < 0
    when :moveout
      self.opacity -= 26
      self.x -= 4 if self.opacity > 0
      @state = :fin if self.opacity <= 0
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
    update_x_and_opacity
    update_y
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    self.bitmap.dispose
    super
  end
end
