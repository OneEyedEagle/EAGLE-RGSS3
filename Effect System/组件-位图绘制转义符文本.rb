#==============================================================================
# ■ 组件-位图绘制转义符文本 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
# - 2019.11.11.21
#==============================================================================
# - 本插件提供了在位图上绘制转义符文本的方法
#-----------------------------------------------------------------------------
# - 新建一个文本绘制处理对象（还未进行绘制）
#
#     d = Process_DrawTextEX.new(text[, params, bitmap])
#
#   其中 text 为带有转义符的文本字符串
#       params 为绘制的控制参数组（见 initialize 方法注释）
#       bitmap 为需要将文本绘制在其上的位图对象
#
# - 调用 d.width 与 d.height 可获得文本绘制总共所需的宽度和高度
# - 可利用 d.bind_bitmap(bitmap[, dispose_old]) 重新绑定需要绘制文本的位图对象
#   其中 dispose_old 传入 true 时，将释放旧位图
# - 利用 d.run 执行绘制
#==============================================================================

class Process_DrawTextEX
  attr_reader :text, :info
  #--------------------------------------------------------------------------
  # ● 初始化
  #  params
  #   :font_size → 绘制初始的文字大小
  #   :x → 每行起始x位置的数组，默认空数组，均取 0
  #   :y → 每行起始y位置的数组，默认空数组，均取 0
  #   :lhu → 文字上方增加的高度（每行文字默认底部对齐）
  #   :lhd → 在换行时，与下一行的间隔距离
  #--------------------------------------------------------------------------
  def initialize(text, params = {}, bitmap = nil)
    @text = convert_escape_characters(text)
    @bitmap = bitmap || Cache.empty_bitmap
    @params = params
    @params[:font_size] ||= @bitmap.font.size
    @params[:x] ||= [] # line_index => x
    @params[:y] ||= [] # line_index => y
    @params[:lhu] ||= 0
    @params[:lhd] ||= 0
    @info = {}
    @info[:w] ||= [] # line_index => width
    @info[:h] ||= [] # line_index => height
    run(false)
  end
  #--------------------------------------------------------------------------
  # ● 绑定位图
  #--------------------------------------------------------------------------
  def bind_bitmap(bitmap, dispose_old = true)
    @bitmap.dispose if @bitmap && dispose_old
    @bitmap = bitmap
  end
  #--------------------------------------------------------------------------
  # ● 获取总占用宽度
  #--------------------------------------------------------------------------
  def width
    @info[:w].inject(0) { |s, v| s += v }
  end
  #--------------------------------------------------------------------------
  # ● 获取总占用高度
  #--------------------------------------------------------------------------
  def height
    @info[:h].inject(0) { |s, v| s += v }
  end
  #--------------------------------------------------------------------------
  # ● 进行控制符的事前变换
  #    在实际绘制前、将控制符替换为实际的内容。
  #    为了减少歧异，文字「\」会被首先替换为转义符（\e）。
  #--------------------------------------------------------------------------
  def convert_escape_characters(text)
    result = text.to_s.clone
    result.gsub!(/\\/)            { "\e" }
    result.gsub!(/\e\e/)          { "\\" }
    result.gsub!(/\eV\[(\d+)\]/i) { $game_variables[$1.to_i] }
    result.gsub!(/\eV\[(\d+)\]/i) { $game_variables[$1.to_i] }
    result.gsub!(/\eN\[(\d+)\]/i) { actor_name($1.to_i) }
    result.gsub!(/\eP\[(\d+)\]/i) { party_member_name($1.to_i) }
    result.gsub!(/\eG/i)          { Vocab::currency_unit }
    result
  end
  #--------------------------------------------------------------------------
  # ● 获取第 n 号角色的名字
  #--------------------------------------------------------------------------
  def actor_name(n)
    actor = n >= 1 ? $game_actors[n] : nil
    actor ? actor.name : ""
  end
  #--------------------------------------------------------------------------
  # ● 获取第 n 号队伍成员的名字
  #--------------------------------------------------------------------------
  def party_member_name(n)
    actor = n >= 1 ? $game_party.members[n - 1] : nil
    actor ? actor.name : ""
  end
  #--------------------------------------------------------------------------
  # ● 绘制
  #--------------------------------------------------------------------------
  def run(flag_draw = true)
    text = @text.clone
    pos = { :line => -1, :x0 => 0, :x => 0, :y0 => 0, :y => 0,
      :w => 0, :h => 0, :flag_draw => flag_draw }
    @bitmap.font.size = @params[:font_size]
    process_new_line(pos)
    process_character(text.slice!(0, 1), text, pos) until text.empty?
  end
  #--------------------------------------------------------------------------
  # ● 处理换行文字
  #--------------------------------------------------------------------------
  def process_new_line(pos)
    pos[:line] += 1
    pos[:x0] = @params[:x][pos[:line]] || pos[:x0]
    pos[:x] = pos[:x0]
    pos[:y0] = @params[:y][pos[:line]] || (pos[:y0] + pos[:h])
    pos[:y0] += @params[:lhd] if pos[:line] > 0
    pos[:y] = pos[:y0]
    pos[:w] = 0
    pos[:h] = 0
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
      process_new_line(pos)
    when "\e"   # 控制符
      process_escape_character(obtain_escape_code(text), text, pos)
    else        # 普通文字
      process_normal_character(c, pos)
    end
  end
  #--------------------------------------------------------------------------
  # ● 处理普通文字
  #--------------------------------------------------------------------------
  def process_normal_character(c, pos)
    r = @bitmap.text_size(c); w = r.width; h = r.height + @params[:lhu]
    process_draw_before(pos[:x], pos[:y], w, h, pos)
    @bitmap.draw_text(pos[:x], pos[:y], w * 2, h * 2, c) if pos[:flag_draw]
    process_draw_after(pos[:x], pos[:y], w, h, pos)
  end
  #--------------------------------------------------------------------------
  # ● 绘制前
  #--------------------------------------------------------------------------
  def process_draw_before(x, y, w, h, pos)
    pos[:y] = pos[:y0] + pos[:h] - h if pos[:h] > h
  end
  #--------------------------------------------------------------------------
  # ● 绘制后
  #--------------------------------------------------------------------------
  def process_draw_after(x, y, w, h, pos)
    pos[:x] += w
    pos[:y] = pos[:y0]
    pos[:w] += w
    pos[:h] = h if pos[:h] < h
    @info[:w][pos[:line]] = pos[:w]
    @info[:h][pos[:line]] = pos[:h]
  end
  #--------------------------------------------------------------------------
  # ● 获取控制符的实际形式（这个方法会破坏原始数据）
  #--------------------------------------------------------------------------
  def obtain_escape_code(text)
    text.slice!(/^[\$\.\|\^!><\{\}\\]|^[A-Z]+/i)
  end
  #--------------------------------------------------------------------------
  # ● 获取控制符的参数（这个方法会破坏原始数据）
  #--------------------------------------------------------------------------
  def obtain_escape_param(text)
    text.slice!(/^\[\d+\]/)[/\d+/].to_i rescue 0
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
      change_color(text_color(obtain_escape_param(text)))
    when 'I'
      process_draw_icon(obtain_escape_param(text), pos)
    when '{'
      make_font_bigger
    when '}'
      make_font_smaller
    end
  end
  #--------------------------------------------------------------------------
  # ● 更改内容绘制颜色
  #     enabled : 有效的标志。false 的时候使用半透明效果绘制
  #--------------------------------------------------------------------------
  def change_color(color, enabled = true)
    @bitmap.font.color.set(color)
    @bitmap.font.color.alpha = 120 unless enabled
  end
  #--------------------------------------------------------------------------
  # ● 获取文字颜色
  #     n : 文字颜色编号（0..31）
  #--------------------------------------------------------------------------
  def text_color(n)
    Cache.system("Window").get_pixel(64 + (n % 8) * 8, 96 + (n / 8) * 8)
  end
  #--------------------------------------------------------------------------
  # ● 处理控制符指定的图标绘制
  #--------------------------------------------------------------------------
  def process_draw_icon(icon_index, pos)
    w = 24; h = 24
    process_draw_before(pos[:x], pos[:y], w, h, pos)
    draw_icon(@bitmap, icon_index, pos[:x], pos[:y]) if pos[:flag_draw]
    process_draw_after(pos[:x], pos[:y], w, h, pos)
  end
  #--------------------------------------------------------------------------
  # ● 绘制图标
  #     enabled : 有效的标志。false 的时候使用半透明效果绘制
  #--------------------------------------------------------------------------
  def draw_icon(bitmap, icon_index, x, y, enabled = true)
    _bitmap = Cache.system("Iconset")
    rect = Rect.new(icon_index % 16 * 24, icon_index / 16 * 24, 24, 24)
    bitmap.blt(x, y, _bitmap, rect, enabled ? 255 : 120)
  end
  #--------------------------------------------------------------------------
  # ● 放大字体尺寸
  #--------------------------------------------------------------------------
  def make_font_bigger
    @bitmap.font.size += 4 if @bitmap.font.size < 64
  end
  #--------------------------------------------------------------------------
  # ● 缩小字体尺寸
  #--------------------------------------------------------------------------
  def make_font_smaller
    @bitmap.font.size -= 4 if @bitmap.font.size > 16
  end
end
