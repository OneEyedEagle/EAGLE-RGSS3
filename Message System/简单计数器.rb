#==============================================================================
# ■ 简单计数器 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
$imported ||= {}
$imported["EAGLE-Counter"] = true
#=============================================================================
# - 2020.10.30.17 初始z值变更为300
#=============================================================================
# - 本插件提供了一组绑定于默认变量 $game_variables 的计数器
# - 在地图上时，指定的文本将显示于屏幕指定位置，当变量值变更时将自动重绘
# - 注意，在同一时间，一个变量只能绑定一个计数器
#-----------------------------------------------------------------------------
# - 创建一个新的计数器：
#
#      Counter.add(v_id[, params])
#
#   其中 v_id 为所绑定的默认变量的 id 号（从1开始，与数据库中一致）
#   其中 params 为存储额外参数的hash，可省略
#
#  【参数列表】
#   （精灵相关）
#     :x/:y/:z → 计数器精灵在屏幕中的显示位置
#     :ox/:oy  → 计数器精灵的显示原点
#   （位图相关）
#     :w/:h → 位图Bitmap的宽度和高度
#     :pic  → 所用的背景图片的名称（位于Graphics/System下）（覆盖:w/:h的设置）
#   （文本相关）
#     :text → 所绘制文本，其中 <v> 将会被替换成所绑定变量的值
#     :cx/:cy → 所绘制文本在位图Bitmap中的位置（以位图左上角为原点）
#     :size → 所绘制文本的文字大小
#
#  【文本】
#     利用和 Window_Base#draw_text_ex 相似的方法进行绘制
#     （由于默认字符串存储方式，请用 \\ 代替 \ 来写转义符）
#     可以使用 文本替换类 的转义符，如 \\v[id]、\\n[id] 等
#       若使用了【对话框扩展 by老鹰】，同样可以使用其中的 文本替换类 转义符
#     可以用 \\i[id] 绘制图标，用 \\c[i] 进行颜色变更
#     可以用 \n 换行
#
#  【示例】（1号变量值为 0 ，2号变量值为 "测试文本"）
#     Counter.add(1) → 以默认参数在地图上显示 "1号变量：0 "
#     Counter.add(2, { :y => 480-30, :text => "当前任务目标：<v>" })
#      → 在屏幕的x=0，y=450处显示 "当前任务目标：测试文本" 字样
#-----------------------------------------------------------------------------
# - 删除指定计数器：
#
#      Counter.delete(v_id)
#
#  【示例】
#     Counter.delete(1) → 删去1号变量的计数器
#-----------------------------------------------------------------------------
# - 显示指定计数器：
#
#      Counter.show(v_id)
#
#   若未传入 v_id 或传入 nil，则将显示全部已有的计数器
#-----------------------------------------------------------------------------
# - 隐藏指定计数器：
#
#      Counter.hide(v_id)
#
#   若未传入 v_id 或传入 nil，则将隐藏全部已有的计数器
#=============================================================================

module Counter
  #--------------------------------------------------------------------------
  # ● 新增计数器
  #--------------------------------------------------------------------------
  def self.add(v_id, params = {})
    params[:refresh] = true # 需要刷新的标志
    params[:visible] = true # 是否显示
    $game_system.counters[v_id] = params
  end
  #--------------------------------------------------------------------------
  # ● 设置计数器
  #--------------------------------------------------------------------------
  def self.set(v_id, params = {})
    return if $game_system.counters[v_id].nil?
    $game_system.counters[v_id].merge!(params)
    $game_system.counters[v_id][:refresh] = true # 需要刷新的标志
  end
  #--------------------------------------------------------------------------
  # ● 删除计数器
  #--------------------------------------------------------------------------
  def self.delete(v_id)
    $game_system.counters.delete(v_id)
  end
  #--------------------------------------------------------------------------
  # ● 显示
  #--------------------------------------------------------------------------
  def self.show(v_id = nil)
    if v_id
      return if $game_system.counters[v_id].nil?
      $game_system.counters[v_id][:visible] = true
    else
      $game_system.counters.each { |vid, params|
        $game_system.counters[vid][:visible] = true
      }
    end
  end
  #--------------------------------------------------------------------------
  # ● 隐藏
  #--------------------------------------------------------------------------
  def self.hide(v_id = nil)
    if v_id
      return if $game_system.counters[v_id].nil?
      $game_system.counters[v_id][:visible] = false
    else
      $game_system.counters.each { |vid, params|
        $game_system.counters[vid][:visible] = false
      }
    end
  end
end
#==============================================================================
# ○ Game_System
#==============================================================================
class Game_System
  #--------------------------------------------------------------------------
  # ● 读取
  #--------------------------------------------------------------------------
  def counters
    @counters ||= {}
    @counters
  end
end
#==============================================================================
# ○ Game_Variables
#==============================================================================
class Game_Variables
  #--------------------------------------------------------------------------
  # ● 设置变量（覆盖）
  #--------------------------------------------------------------------------
  def []=(variable_id, value)
    v_old = @data[variable_id]
    @data[variable_id] = value
    on_change
    on_change_different(variable_id) if v_old != value
  end
  #--------------------------------------------------------------------------
  # ● 变量改变时的操作
  #--------------------------------------------------------------------------
  def on_change_different(variable_id)
    if $game_system.counters[variable_id]
      $game_system.counters[variable_id][:refresh] = true
    end
  end
end
#==============================================================================
# ○ 计数器的精灵
#==============================================================================
class Sprite_Counter < Sprite
  attr_accessor :flag_update
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(viewport, v_id)
    super(viewport)
    @v_id = v_id
    @flag_update = false # 每帧重置为false，若更新结束依然为false，则需要删除
    refresh
  end
  #--------------------------------------------------------------------------
  # ● 参数
  #--------------------------------------------------------------------------
  def params
    $game_system.counters[@v_id]
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    self.bitmap.dispose
    super
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
    self.visible = params[:visible]
    refresh if params[:refresh]
  end
  #--------------------------------------------------------------------------
  # ● 重绘
  #--------------------------------------------------------------------------
  def refresh
    $game_system.counters[@v_id][:refresh] = false
    self.x  = params[:x] || 0
    self.y  = params[:y] || 0
    self.z  = params[:z] || 100
    self.ox = params[:ox] || 0
    self.oy = params[:oy] || 0
    redraw_bg
    redraw_contents
  end
  #--------------------------------------------------------------------------
  # ● 重绘背景
  #--------------------------------------------------------------------------
  def redraw_bg
    self.bitmap.dispose if self.bitmap
    if params[:pic]
      self.bitmap = Cache.system(params[:pic]).dup
    else
      w = params[:w] || 256
      h = params[:h] || 48
      self.bitmap = Bitmap.new(w, h)
    end
    self.bitmap.font.size = params[:size] if params[:size]
  end
  #--------------------------------------------------------------------------
  # ● 重绘内容
  #--------------------------------------------------------------------------
  def redraw_contents
    cx = params[:cx] || 0
    cy = params[:cy] || 0
    t  = params[:text].dup || "#{@v_id} 号变量：<v>"
    t.gsub!(/<v>/) { $game_variables[@v_id] }
    draw_text_ex(cx, cy, t)
  end
  #--------------------------------------------------------------------------
  # ● 绘制带有控制符的文本内容
  #--------------------------------------------------------------------------
  def draw_text_ex(x, y, text)
    s = SceneManager.scene
    text = s.message_window.convert_escape_characters(text) rescue return
    pos = {:x => x, :y => y, :new_x => x, :height => self.bitmap.font.size }
    process_character(text.slice!(0, 1), text, pos) until text.empty?
  end
  #--------------------------------------------------------------------------
  # ● 文字的处理
  #     c    : 文字
  #     text : 绘制处理中的字符串缓存（字符串可能会被修改）
  #     pos  : 绘制位置 {:x, :y, :new_x, :height}
  #--------------------------------------------------------------------------
  def process_character(c, text, pos)
    case c
    when "\r"   # 回车
      return
    when "\n"   # 换行
      process_new_line(text, pos)
    when "\e"   # 控制符
      code = SceneManager.scene.message_window.obtain_escape_code(text)
      process_escape_character(code, text, pos)
    else        # 普通文字
      process_normal_character(c, pos)
    end
  end
  #--------------------------------------------------------------------------
  # ● 处理普通文字
  #--------------------------------------------------------------------------
  def process_normal_character(c, pos)
    text_width = self.bitmap.text_size(c).width
    self.bitmap.draw_text(pos[:x], pos[:y], text_width * 2, pos[:height], c)
    pos[:x] += text_width
  end
  #--------------------------------------------------------------------------
  # ● 处理换行文字
  #--------------------------------------------------------------------------
  def process_new_line(text, pos)
    pos[:x] = pos[:new_x]
    pos[:y] += pos[:height]
    pos[:height] = self.bitmap.font.size
  end
  #--------------------------------------------------------------------------
  # ● 控制符的处理
  #     code : 控制符的实际形式（比如“\C[1]”是“C”）
  #     text : 绘制处理中的字符串缓存（字符串可能会被修改）
  #     pos  : 绘制位置 {:x, :y, :new_x, :height}
  #--------------------------------------------------------------------------
  def process_escape_character(code, text, pos)
    case code.upcase
    when 'C'
      param = SceneManager.scene.message_window.obtain_escape_param(text)
      change_color(SceneManager.scene.message_window.text_color(param))
    when 'I'
      param = SceneManager.scene.message_window.obtain_escape_param(text)
      process_draw_icon(param, pos)
    end
  end
  #--------------------------------------------------------------------------
  # ● 更改内容绘制颜色
  #     enabled : 有效的标志。false 的时候使用半透明效果绘制
  #--------------------------------------------------------------------------
  def change_color(color, enabled = true)
    self.bitmap.font.color.set(color)
    self.bitmap.font.color.alpha = 120 unless enabled
  end
  #--------------------------------------------------------------------------
  # ● 处理控制符指定的图标绘制
  #--------------------------------------------------------------------------
  def process_draw_icon(icon_index, pos)
    draw_icon(icon_index, pos[:x], pos[:y])
    pos[:x] += 24
  end
  #--------------------------------------------------------------------------
  # ● 绘制图标
  #     enabled : 有效的标志。false 的时候使用半透明效果绘制
  #--------------------------------------------------------------------------
  def draw_icon(icon_index, x, y, enabled = true)
    bitmap = Cache.system("Iconset")
    rect = Rect.new(icon_index % 16 * 24, icon_index / 16 * 24, 24, 24)
    self.bitmap.blt(x, y, bitmap, rect, enabled ? 255 : translucent_alpha)
  end
end
#==============================================================================
# ○ 计数器的精灵组
#==============================================================================
class Spriteset_Counters
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(viewport)
    @viewport = viewport
    @counters = {} # v_id => Sprite
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    @counters.each { |v_id, s| s.flag_update = false }
    $game_system.counters.each do |v_id, params|
      @counters[v_id] ||= Sprite_Counter.new(@viewport, v_id)
      @counters[v_id].update
      @counters[v_id].flag_update = true
    end
    return if @counters.empty?
    @counters.each { |v_id, s| s.dispose if s.flag_update == false }
    @counters.delete_if { |v_id, s| s.disposed? }
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    @counters.each { |v_id, s| s.dispose }
  end
end
#==============================================================================
# ○ Spriteset_Map
#==============================================================================
class Spriteset_Map
  attr_reader  :counters
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  alias eagle_counter_init initialize
  def initialize
    eagle_counter_init
    @counters = Spriteset_Counters.new(@viewport2)
  end
  #--------------------------------------------------------------------------
  # ● 释放计时器精灵
  #--------------------------------------------------------------------------
  alias eagle_counter_dispose_timer dispose_timer
  def dispose_timer
    eagle_counter_dispose_timer
    @counters.dispose
  end
  #--------------------------------------------------------------------------
  # ● 更新计时器精灵
  #--------------------------------------------------------------------------
  alias eagle_counter_update_timer update_timer
  def update_timer
    eagle_counter_update_timer
    @counters.update if @counters
  end
end
#==============================================================================
# ○ Scene_Map
#==============================================================================
class Scene_Map
  attr_reader :message_window
  #--------------------------------------------------------------------------
  # ● 生成信息窗口
  #--------------------------------------------------------------------------
  alias eagle_counter_create_message_window create_message_window
  def create_message_window
    eagle_counter_create_message_window
    @spriteset.counters.update
  end
end
