#==============================================================================
# ○ 文本临时重看系统  by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
$imported ||= {}
$imported["EAGLE-TextReview"] = true
#==============================================================================
# - 2019.4.15.19 再次整合 对话框扩展 插件
#==============================================================================
# - 本插件提供了一个完整的指定文本的临时重看系统
# - 注意：
#     本插件不进行文本的文件形式保存
#     故在游戏关闭重开、读档等操作后，会清空全部的缓存文本
#==============================================================================
module TextReview
  #--------------------------------------------------------------------------
  # ● 【设置】常量
  #--------------------------------------------------------------------------
  # 在地图上任意时刻按住该键，即可呼叫文本重看系统
  # （按上/下方向键进行浏览）
  KEY = :A
  # 最多临时存储的文本记录块数目
  #  设为 nil 时为无限制（警告：同时存储过多记录块会使UI开启时产生较严重的卡顿）
  NUM_LIMIT = 50
  # 每两个文本记录块窗口之间的间隔像素值
  OFFSET = 6
  #--------------------------------------------------------------------------
  # ● 新增文本记录
  # - params参数中可传入的键值
  #    :windowskin => string # 该文本块所使用的窗口皮肤文件名（默认为 "Window"）
  #    :tone => Tone.new(0,0,0) # 该文本块窗口皮肤的色调
  #    :alignment => int # 该文本块在屏幕里的对齐方式
  #                 0 - 左对齐（默认） 1 - 居中  2 - 右对齐
  #    :face => [string, int] # 需要绘制的脸图 [文件名, 索引0-7]
  #--------------------------------------------------------------------------
  def self.add(text = "", params = {})
    # 0 → end ：新 → 旧
    @data.unshift( TextReview_Data.new(text, params) )
    @data.pop if NUM_LIMIT && @data.size > NUM_LIMIT
  end
  #--------------------------------------------------------------------------
  # ● 重置
  #--------------------------------------------------------------------------
  def self.reset
    @data ||= []
    @data.clear
    ui_dispose
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def self.update
    return if @data.empty?
    return if !Input.trigger?(KEY)
    ui_init
    while(true)
      ui_wait
      ui_bg_update
      if Input.press?(KEY)
        case @state
        when :in;   @state = :wait if @speed == 0
        when :wait; ui_update_move
        else;       ui_move_in
        end
      else
        ui_move_out if @state != :out
        break if @blocks[0].y < -@blocks[0].height
      end
      ui_update_speed
    end # end of while
    ui_dispose
  end
class << self
  #--------------------------------------------------------------------------
  # ● UI-等待
  #--------------------------------------------------------------------------
  def ui_wait(duration = 1)
    duration.times { SceneManager.scene.update_basic }
  end
  #--------------------------------------------------------------------------
  # ● UI-初始化
  #--------------------------------------------------------------------------
  def ui_init
    @state = :init
    @data.each { |d| @blocks.push(Window_TextReview_Block.new(d)) }
    cur_y = offset = OFFSET # 此处设置每两个窗口之间的间隔
    @blocks.each_with_index { |b, i|
      cur_y -= (b.height + offset)
      b.y = cur_y
    }
    @speed = 0
    # 速度逐渐归零用的计数 每@d_speed帧后速度绝对值减一
    @d_speed = @d_speed_count = 12
    # 速度累加用计数 每@ad_speed帧后如果依旧按住同一个键，速度绝对值加一
    @ad_speed = @ad_speed_count = 4
    @last_key = nil

    @bg = Sprite.new
    @bg.z = 250
    @bg.bitmap = Bitmap.new(Graphics.width, Graphics.height)
    @bg.bitmap.gradient_fill_rect(@bg.bitmap.rect,
      Color.new(0,0,0,200), Color.new(0,0,0,20))
    @bg.opacity = 0
  end
  #--------------------------------------------------------------------------
  # ● UI-移入
  #--------------------------------------------------------------------------
  def ui_move_in
    @state = :in
    @speed = (Graphics.height / 2 - @blocks[0].height - @blocks[0].y ) / 30
  end
  #--------------------------------------------------------------------------
  # ● UI-更新背景
  #--------------------------------------------------------------------------
  def ui_bg_update
    @bg.opacity += 10 if @state == :in
    @bg.opacity -= 15 if @state == :out
  end
  #--------------------------------------------------------------------------
  # ● UI-更新速度递减
  #--------------------------------------------------------------------------
  def ui_update_speed
    @blocks.each { |b| b.y += @speed }
    return if @speed == 0
    return if (@d_speed_count -= 1) > 0
    @d_speed_count = @d_speed
    @speed += (@speed > 0 ? -1 : 1)
  end
  #--------------------------------------------------------------------------
  # ● UI-更新按键移动
  #--------------------------------------------------------------------------
  def ui_update_move
    @speed = -1 if Input.trigger?(:UP)
    @speed = +1 if Input.trigger?(:DOWN)
    if Input.press?(:UP)
      if @last_key == :UP
        @ad_speed_count -= 1
        if @ad_speed_count <= 0
          @ad_speed_count = @ad_speed
          @speed -= 1
        end
      else
        @ad_speed_count = @ad_speed
      end
      @last_key = :UP
    elsif Input.press?(:DOWN)
      if @last_key == :DOWN
        @ad_speed_count -= 1
        if @ad_speed_count <= 0
          @ad_speed_count = @ad_speed
          @speed += 1
        end
      else
        @ad_speed_count = @ad_speed
      end
      @last_key = :DOWN
    end
    @speed = 3  if @blocks[0].y < Graphics.height / 2 - @blocks[0].height
    @speed = -3 if @blocks[-1].y > Graphics.height / 2 + @blocks[-1].height
  end
  #--------------------------------------------------------------------------
  # ● UI-移出
  #--------------------------------------------------------------------------
  def ui_move_out
    @state = :out
    @speed = -9 - (@blocks[0].y + @blocks[0].height) / 70
  end
  #--------------------------------------------------------------------------
  # ● UI-释放
  #--------------------------------------------------------------------------
  def ui_dispose
    if @bg
      @bg.bitmap.dispose
      @bg.dispose
    end
    @blocks ||= []
    @blocks.each { |s| s.dispose if !s.disposed? }
    @blocks.clear
  end
end # end of self-class
end # end of module TextReview
#===============================================================================
# ○ Scene_Map
#===============================================================================
class Scene_Map < Scene_Base
  attr_reader :message_window
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  alias eagle_text_review_update update
  def update
    eagle_text_review_update
    TextReview.update
  end
end
#===============================================================================
# ○ SceneManager
#===============================================================================
class << SceneManager
  #--------------------------------------------------------------------------
  # ● 运行
  #--------------------------------------------------------------------------
  alias eagle_text_review_run run
  def run
    TextReview.reset
    eagle_text_review_run
  end
end
#===============================================================================
# ○ Game_System
#===============================================================================
class Game_System
  #--------------------------------------------------------------------------
  # ● 读档后的处理
  #--------------------------------------------------------------------------
  alias eagle_text_review_on_after_load on_after_load
  def on_after_load
    TextReview.reset
    eagle_text_review_on_after_load
  end
end
#===============================================================================
# ○ 存储单个文本块的数据
#===============================================================================
class TextReview_Data
  attr_reader :text, :params
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(text = "", params = {})
    @text = text
    message_window = SceneManager.scene.message_window rescue nil
    if message_window
      if $imported["EAGLE-MessageEX"]
        @text = message_window.eagle_process_conv(@text)
        @text = message_window.eagle_process_conv(@text)
        @text = message_window.eagle_process_rb(@text)
      end
      @text = message_window.convert_escape_characters(@text)
    end
    @params = params
  end
end # end of class Data
#===============================================================================
# ○ 单个文本块的窗口
#===============================================================================
class Window_TextReview_Block < Window_Base
  attr_accessor :speed
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(data)
    @data = data # TextReview_Data 的实例
    parse_window_params
    parse_draw_params
    super(0, 0, @window_width, @window_height)
    self.back_opacity = 255
    parse_setting_params
    refresh
  end
  #--------------------------------------------------------------------------
  # ● 行高
  #--------------------------------------------------------------------------
  def line_height
    24
  end
  #--------------------------------------------------------------------------
  # ● 获取描绘文本所需的矩形
  #--------------------------------------------------------------------------
  def get_text_rect
    _bitmap = Bitmap.new(1,1)
    _bitmap.font.size = Font.default_size
    line_widths = []
    line_heights = []
    @data.text.split(/\n/).each do |t|
      # 每一行计算宽度和高度
      _w = t.scan(/(\e|\\)*i\[\d+\]/m).inject(0) { |sum, id| sum += 24 }
      _t = t.gsub(/(\e|\\)*\w+\[.*?\]/m, "")
      _rect = _bitmap.text_size(_t)
      line_widths.push(_rect.width + _w)
      _h = [_rect.height, line_height].max
      line_heights.push(_h)
    end
    _bitmap.dispose
    width = line_widths.max || 0
    width = 24 if width < 24
    height = line_heights.inject(0) { |s, h| s += h }
    height = 24 if height < 24
    return Rect.new(0, 0, width, height)
  end
  #--------------------------------------------------------------------------
  # ● 分析窗口生成参数Hash
  #--------------------------------------------------------------------------
  def parse_window_params
    t = @data.params
    text_rect = get_text_rect
    @window_height = text_rect.height + standard_padding * 2
    @window_width = text_rect.width + standard_padding * 2
  end
  #--------------------------------------------------------------------------
  # ● 分析绘制相关参数Hash
  #--------------------------------------------------------------------------
  def parse_draw_params
    t = @data.params
    @flag_face = false
    if t[:face] && t[:face][0] != "" # t[:face] = [face_name, face_index]
      b = Cache.face(t[:face][0])
      if b.width == 96*4 && b.height == 96*2 # 只绘制默认规格的脸图
        @flag_face = true
        @window_height = 96 + standard_padding * 2
        @window_width += (96 + 8)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 分析设置参数Hash
  #--------------------------------------------------------------------------
  def parse_setting_params
    t = @data.params
    w_skin = t[:windowskin] ? t[:windowskin] : "Window"
    self.windowskin = Cache.system(w_skin)
    self.tone = t[:tone] ? t[:tone] : $game_system.window_tone
    self.z = 300
    alignment = t[:alignment] ? t[:alignment] : 0
    case alignment
    when 1; self.x = (Graphics.width - self.width) / 2
    when 2; self.x = Graphics.width - self.width
    else;   self.x = 0
    end
  end
  #--------------------------------------------------------------------------
  # ● 重绘
  #--------------------------------------------------------------------------
  def refresh
    contents.clear
    if @flag_face
      draw_face(@data.params[:face][0], @data.params[:face][1], 0, 0)
      text_x = 96 + 8
    else
      text_x = 0
    end
    draw_text_ex(text_x, 0, @data.text)
  end
end
#===============================================================================
# ○ Add-On 对话文本临时重看
# 将 事件指令-显示对话 放入临时文本重看系统
#===============================================================================
class Game_Message
  #--------------------------------------------------------------------------
  # ● 清除
  #--------------------------------------------------------------------------
  alias eagle_text_review_clear clear
  def clear
    if @texts && has_text?
      TextReview.add($game_message.all_text,
        {:face => [$game_message.face_name, $game_message.face_index]})
    end
    eagle_text_review_clear
  end
end
#===============================================================================
# ○ Add-On 整合对话框转义符扩展
#===============================================================================
class Window_TextReview_Block < Window_Base
  #--------------------------------------------------------------------------
  # ● 获取控制符的参数/字符串形式（这个方法会破坏原始数据）
  #--------------------------------------------------------------------------
  def obtain_escape_param_string(text)
    text.slice!(/^\[.*?\]/)[/[\d\w]+/] rescue ""
  end
  #--------------------------------------------------------------------------
  # ● 控制符的处理
  #     code : 控制符的实际形式（比如“\C[1]”是“C”）
  #     text : 绘制处理中的字符串缓存（字符串可能会被修改）
  #     pos  : 绘制位置 {:x, :y, :new_x, :height}
  #--------------------------------------------------------------------------
  def process_escape_character(code, text, pos)
    super(code, text, pos)
    obtain_escape_param_string(text)
  end
end
