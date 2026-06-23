#==============================================================================
# ■ 组件-位图绘制转义符文本 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
$imported ||= {}
$imported["EAGLE-DrawTextEX"] = "1.1.2"
#==============================================================================
# - 2026.6.24.0 扩展\c转义符
#==============================================================================
# - 本插件提供了在位图上绘制转义符文本的方法
#------------------------------------------------------------------------------
# 【使用举例】
#
=begin

d = Process_DrawTextEX.new(text[, params, bitmap]) # ①
# 可用 d.width 与 d.height 获取文字占据的宽度和高度
# d.bind_bitmap(bitmap[, dispose_old]) # ②（可选）
d.run   # ③
# 可用 d.escapes 读取其中未生效的转义符及其参数文本串 # ④（可选）

=end
# 
# --------------
# 【关于①】新建了一个文本绘制处理对象（但还没绘制）。
#
#  - 其中 text 为带有转义符的文本字符串。
#
#   可用转义符包括默认对话框中的绘制类转义符，如 \i、\v。
#   注意，在脚本的字符串中编写时，需要用 \\ 替换 \（换行符仍然写为\n）。
#
#    ※ 扩展的转义符：
#
#      \c → 可以 \c[数字] 使用默认索引颜色，
#            可以 \c[r数字g数字b数字a数字] 直接编写颜色，
#            其中 rgba 四个参数最少需设置一个，未设置的取默认值 255 。
#
#    ※ 额外新增的转义符：
#
#      \ln → 在当前行底部绘制横线，同时进行换行
#
#      \lb[text] → 为 text 文本绘制矩形背景（该绘制无法跨行）。
#                  若使用了【组件-形状绘制2】，则改为绘制圆角矩形。
#
#      \lc[n] → 将后续的 \lb 的矩形颜色更改为 n 号文字颜色。
#               若使用了【组件-通用方法汇总】，也可以 \lc[r数字g数字b数字a数字]。
#
#  - 其中 params 为绘制的控制参数组（见 initialize 方法注释）。
#
#  - 其中 bitmap 为需要将文本绘制在其上的位图对象。
#
# --------------
# 【关于②】（可选）绑定需要绘制文本的位图。
#
#  - 其中 dispose_old 传入 true 时，将释放初始化时用的位图。
#
# --------------
# 【关于③】真正进行绘制。
#
# --------------
# 【关于④】（可选）获取其中未解析的转义符。
#
#  - 其中返回的Hash内容为 { :sym => "params" }
#
#==============================================================================

class Process_DrawTextEX
  attr_reader :text, :info, :escapes
  #--------------------------------------------------------------------------
  # ● 初始化
  #  params
  #   :font_size → 绘制初始的文字大小
  #   :font_color → 指定初始的绘制颜色 Color.new
  #   :x0 → 指定每行的向右偏移值
  #   :y0 → 指定首行的向下偏移值
  #   :w → 规定最大行宽，若超出则会进行自动换行
  #   :lhd → 在换行时，与下一行的间隔距离
  #   :trans → 是否半透明
  #   :ali → 行内对齐方式（0左对齐，1居中，2右对齐）
  #--------------------------------------------------------------------------
  def initialize(text, params = {}, bitmap = nil)
    @text = convert_escape_characters(text)
    @bitmap = bitmap || Cache.empty_bitmap
    @params = params
    @params[:font_size] ||= @bitmap.font.size
    @params[:font_color] ||= text_color(0)
    @params[:x0] ||= 0
    @params[:y0] ||= 0
    @params[:w] ||= nil
    @params[:lhd] ||= 0
    @params[:trans] ||= false
    @params[:ali] ||= 0

    @info = {}
    @info[:w] = [] # line_index => width
    @info[:h] = [] # line_index => height
    @info[:rects] = [] # line_index => rect范围
    @escapes = {}

    @info[:labels] = {}  # line_index => [[rect, c]]
    @label_cur = nil
    @label_color = text_color(0)

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
  # ●（外部调用）获取文字总占用的宽度和高度
  #--------------------------------------------------------------------------
  def width
    @info[:w].max
  end
  def height
    r = @info[:h].inject(0) { |s, v| s += v }
    r = r + (@info[:h].size - 1) * @params[:lhd] + @params[:y0]
    r + @info[:h_add]
  end

  #--------------------------------------------------------------------------
  # ● 进行控制符的事前变换
  #--------------------------------------------------------------------------
  #   在实际绘制前、将控制符替换为实际的内容。
  #   为了减少歧异，文字「\」会被首先替换为转义符（\e）。
  def convert_escape_characters(text)
    result = text.to_s.clone
    result.gsub!(/\\n/)           { "\n" }
    result.gsub!(/\\/)            { "\e" }
    result.gsub!(/\e\e/)          { "\\" }
    result.gsub!(/\eV\[(\d+)\]/i) { $game_variables[$1.to_i] }
    result.gsub!(/\eV\[(\d+)\]/i) { $game_variables[$1.to_i] }
    result.gsub!(/\eN\[(\d+)\]/i) { actor_name($1.to_i) }
    result.gsub!(/\eP\[(\d+)\]/i) { party_member_name($1.to_i) }
    result.gsub!(/\eG/i)          { Vocab::currency_unit }
    result.gsub!(/\eLB\[(.*?)\]/i){ "\eLA "+$1+" \eLD" }
    result
  end
  # 获取第 n 号角色的名字
  def actor_name(n)
    actor = n >= 1 ? $game_actors[n] : nil
    actor ? actor.name : ""
  end
  # 获取第 n 号队伍成员的名字
  def party_member_name(n)
    actor = n >= 1 ? $game_party.members[n - 1] : nil
    actor ? actor.name : ""
  end

  #--------------------------------------------------------------------------
  # ● 绘制
  #--------------------------------------------------------------------------
  def run(flag_draw = true)
    text = @text.clone
    pos = { :line => -1, :x0 => @params[:x0], :x => 0,
      :y0 => @params[:y0], :y => 0,
      :w => 0, :h => 0, :flag_draw => flag_draw }
    pos[:y_new] = pos[:y0]
    @info[:h_add] = 0
    @bitmap.font.size = @params[:font_size]
    change_color(@params[:font_color], !@params[:trans])
    process_new_line(pos)
    process_character(text.slice!(0, 1), text, pos) until text.empty?
  end

  #--------------------------------------------------------------------------
  # ● 处理换行
  #--------------------------------------------------------------------------
  def process_new_line(pos)
    pos[:line] += 1
    pos[:x_new] = @params[:x0] || pos[:x0]
    pos[:x] = pos[:x_new]
    pos[:y_new] = pos[:y_new] + pos[:h]
    pos[:y_new] += @params[:lhd] if pos[:line] > 0
    pos[:y] = pos[:y_new]
    if pos[:flag_draw]
      pos[:w] = @info[:w][pos[:line]]  # 提取下一行的宽高
      pos[:h] = @info[:h][pos[:line]]
      if @params[:ali] == 1     # 居中
        pos[:x] += (self.width_pre - pos[:w]) / 2
      elsif @params[:ali] == 2  # 右对齐
        pos[:x] += (self.width_pre - pos[:w])
      end
      pos[:x_new_start] = pos[:x]  # 存储下一行的开头位置
    else  # 预绘制时，计算每一行的宽高
      pos[:w] = 0
      pos[:h] = 0
      @info[:w][pos[:line]] = 0
      @info[:h][pos[:line]] = 0
      # 存储当前行的矩形
      @info[:rects][pos[:line]] = Rect.new(pos[:x], pos[:y], pos[:w], pos[:h])
    end
    process_draw_labels(pos) if pos[:flag_draw]  # 换行后，先绘制当前行的label
  end

  # 获取预设文字宽度
  def width_pre
    return @params[:w] if @params[:w]
    return self.width
  end

  # 处理自动换行
  def process_auto_new_line(pos, w)
    return if @label_cur  # 如果有标签，则不能自动换行
    if @params[:w] && pos[:x] + w > pos[:x_new] + @params[:w]
      process_new_line(pos)
      pos[:h] = 0
    end
  end

  #--------------------------------------------------------------------------
  # ● 绘制指定行的标签底纹
  #--------------------------------------------------------------------------
  def process_draw_labels(pos)
    line = pos[:line]
    return if line < 0 or @info[:labels][line] == nil
    dx = 0
    w = @info[:w][line]
    if @params[:ali] == 1     # 居中
      dx += (self.width_pre - w) / 2
    elsif @params[:ali] == 2  # 右对齐
      dx += (self.width_pre - w)
    end
    @info[:labels][line].each do |ps|
      r = ps[0]; c = ps[1]
      c.alpha = 150
      # 由于x0/y0可能变化，这里需要使用实时的值来绘制
      _x = pos[:x0] + dx + r.x
      # 由于预先绘制时存在一些不变化y的情况，这样要用实时的y来绘制
      _y = pos[:y] + @info[:h][line] - r.height
      if $imported["EAGLE-UtilsDrawing2"]
        # 绘制圆角矩形
        @bitmap.fill_rounded_rect(_x, _y, r.width, r.height, 4, c)
      else
        # 绘制普通矩形
        @bitmap.fill_rect(_x, _y, r.width, r.height, c)
      end
    end
  end

  #--------------------------------------------------------------------------
  # ● 文字的处理
  #--------------------------------------------------------------------------
  #  c    : 文字
  #  text : 绘制处理中的字符串缓存（字符串可能会被修改）
  #  pos  : 绘制位置 {:x, :y, :new_x, :height}
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

  # 处理普通文字
  def process_normal_character(c, pos)
    r = @bitmap.text_size(c); w = r.width; h = r.height
    process_draw_before(pos[:x], pos[:y], w, h, pos)
    @bitmap.draw_text(pos[:x], pos[:y], w * 2, h, c) if pos[:flag_draw]
    process_draw_after(pos[:x], pos[:y], w, h, pos)
  end

  # 绘制前
  def process_draw_before(x, y, w, h, pos)
    process_auto_new_line(pos, w)
    pos[:y] = pos[:y_new] + pos[:h] - h if pos[:h] > h
  end
  # 绘制后
  def process_draw_after(x, y, w, h, pos)
    pos[:x] += w
    pos[:y] = pos[:y_new]
    pos[:w] += w
    pos[:h] = h if pos[:h] < h
    if !pos[:flag_draw]
      @info[:w][pos[:line]] = pos[:w]
      @info[:h][pos[:line]] = pos[:h]
      @info[:rects][pos[:line]].width = pos[:w]
      @info[:rects][pos[:line]].height = pos[:h]
    end
  end

  # 处理控制符指定的图标绘制
  def process_draw_icon(icon_index, pos)
    w = 24; h = 24
    process_draw_before(pos[:x], pos[:y], w, h, pos)
    draw_icon(@bitmap, icon_index, pos[:x], pos[:y], !@params[:trans]) if pos[:flag_draw]
    process_draw_after(pos[:x], pos[:y], w, h, pos)
  end
  # 绘制图标
  #    enabled : 有效的标志。false 的时候使用半透明效果绘制
  def draw_icon(bitmap, icon_index, x, y, enabled = true)
    _bitmap = Cache.system("Iconset")
    rect = Rect.new(icon_index % 16 * 24, icon_index / 16 * 24, 24, 24)
    bitmap.blt(x, y, _bitmap, rect, enabled ? 255 : 120)
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
      c = text_color_ex(obtain_escape_param_string(text))
      change_color(c, !@params[:trans])
    when 'I';    process_draw_icon(obtain_escape_param(text), pos)
    when '{';    make_font_bigger
    when '}';    make_font_smaller
    when 'LN';   process_new_line_with_line(text, pos)
    when 'LC';   process_label_color(obtain_escape_param_string(text))
    when 'LA';   process_label1(text, pos)
    when 'LD';   process_label2(text, pos)
    else;        @escapes[code] = obtain_escape_param_string(text)
    end
  end
  # 获取控制符的实际形式（这个方法会破坏原始数据）
  def obtain_escape_code(text)
    text.slice!(/^[\$\.\|\^!><\{\}\\]|^[A-Z]+/i)
  end
  # 获取控制符的参数（这个方法会破坏原始数据）
  def obtain_escape_param(text)
    text.slice!(/^\[\d+\]/)[/\d+/].to_i rescue 0
  end
  # 获取控制符的参数（这个方法会破坏原始数据）
  def obtain_escape_param_string(text)
    text.slice!(/^\[.*?\]/)[1...-1] || "" rescue ""
  end
  
  # 解析字符串参数
  def parse_param(param_hash, param_text)
    param_text = param_text.downcase rescue ""
    while(param_text != "")
      param_text.slice!(/ */)
      t = param_text.slice!(/^[a-z]+/)
      param_text.slice!(/ */)
      if param_text[0] == '='
        param_text[0] = ''
        param_text.slice!(/ */)
      end
      if param_text[0] == "$"
        param_text[0] = ''
        next param_hash[t.to_sym] = nil
      end
      param_hash[t.to_sym] = (param_text.slice!(/^\-?\d+/)).to_i
    end
    param_hash
  end

  # 更改内容绘制颜色
  #     enabled : 有效的标志。false 的时候使用半透明效果绘制
  def change_color(color, enabled = true)
    @bitmap.font.color.set(color)
    @bitmap.font.color.alpha = 120 unless enabled
  end

  # 获取文字颜色（扩展）
  def text_color_ex(t)
    if $imported["EAGLE-CommonMethods"] 
      if ['r', 'g', 'b', 'a'].any? { |c| t.include?(c) }
        h = parse_param({}, t)
        h[:r] ||= 255
        h[:g] ||= 255
        h[:b] ||= 255
        h[:a] ||= 255
        return Color.new(h[:r], h[:g], h[:b], h[:a])
      end
    end
    text_color(t.to_i)
  end
  # 获取文字颜色
  #    n : 文字颜色编号（0..31）
  def text_color(n)
    Cache.system("Window").get_pixel(64 + (n % 8) * 8, 96 + (n / 8) * 8)
  end

  # 放大字体尺寸
  def make_font_bigger
    @bitmap.font.size += 4 if @bitmap.font.size < 64
  end
  # 缩小字体尺寸
  def make_font_smaller
    @bitmap.font.size -= 4 if @bitmap.font.size > 16
  end

  # 底部绘制横线并换行
  def process_new_line_with_line(text, pos)
    dy = 4 + @params[:lhd]
    if pos[:flag_draw]
      _x = pos[:x_new_start]
      _y = pos[:y] + pos[:h]
      _w = pos[:x] - _x
      @bitmap.fill_rect(_x, _y+dy, _w, 1, Color.new(255,255,255,150))
      dy += 1 + 4
    else
      @info[:h_add] += dy + 1 + 4
    end
    pos[:y_new] += dy
    process_new_line(pos)
  end

  # 绘制标签
  def process_label1(text, pos)
    if pos[:flag_draw]
      # 在实际绘制时，赋值以阻止自动换行
      @label_cur = true
    else
      if @label_cur == nil 
        @label_cur = Rect.new(pos[:x] - pos[:x0], pos[:y] - pos[:y0], 0, pos[:h])
      end
    end
  end
  def process_label2(text, pos)
    if pos[:flag_draw]
    else
      if @label_cur
        @label_cur.width = pos[:x] - pos[:x0] - @label_cur.x
        @label_cur.height = [pos[:h], @label_cur.height].max
        @info[:labels][pos[:line]] ||= []
        @info[:labels][pos[:line]] << [@label_cur, @label_color]
      end
    end
    @label_cur = nil
  end
  # 标签颜色
  def process_label_color(t)
    @label_color = text_color_ex(t)
  end
end
