#==============================================================================
# ■ Add-On 滚动文本框扩展 by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【对话框扩展 by老鹰 2019.8.25.13】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-ScrollTextEX"] = true
#=============================================================================
# - 2020.4.8.14 修改并行称呼
#==============================================================================
# - 完全覆盖默认的滚动文本指令，现在拥有与 对话框扩展 中的对话框相同的描绘方式
# - 关于转义符：
#     使用方式与 对话框扩展 中的保持一致
# - 关于标签对：
#     在标签对中的内容，将会被按照标签对的作用进行统一处理
# - 由于效率问题，本插件暂不支持翻页
#------------------------------------------------------------------------------
# ● 转义符及其变量列表
#------------------------------------------------------------------------------
# - 控制类
#
#  \font[param] → 单个文字绘制的属性（同 对话框扩展）
#
#  \win[param] → 背景窗口的相关设置
#  （窗口属性相关）
#    opa → 窗口的不透明度
#    o → 窗口打开时的显示原点所在位置的类型（九宫格）（默认7左上角）
#    x/y/w/h → 窗口打开时的坐标与实际宽高
#    skin → 窗口所用皮肤的index（同 对话框扩展）
#  （文字摆放相关）
#    xo 与 yo → 第一个文字的绘制位置（窗口contents的左上角为原点）
#    cdx → 下一个字的横轴偏移量（负数为往左，正数为往右）（默认1，朝右侧前进一个文字）
#    cdy → 下一个字的纵轴偏移量（负数为往上，正数为往下）（默认0，与前一个字高度对齐）
#    ck → 设置缩减的字符间距值（默认0）
#    ldx → 下一行的横轴偏移量（负数为往左，正数为往右）（默认0，与上一行行首对齐）
#    ldy → 下一行的纵轴偏移量（负数为往上，正数为往下）（默认1，朝下侧移动一行）
#    lh → 标准行高（默认24）
#    lhd → 行间距（默认0）
#  （文字显示相关）
#    cwi → 单个文字绘制完成后的等待帧数（最小值0）
#    cwo → 单个文字开始移出后的等待帧数（最小值0）
#    cfast → 是否允许快进显示
#
#  \pause[param] → 等待按键精灵的属性（同 对话框扩展）
#
#  \pos[param] -【重置】直接指定下一个文字的绘制位置
#    x/y → 直接指定x/y像素坐标值（窗口内部绘制区域的左上角为(0, 0)）
#    c/l → 直接指定行号/列号（从1开始）
#         （行高为窗口的 line_height，列宽为窗口的 font.size）
#    dx/dy → x/y方向增加一个像素偏移值
#    dc/dl → c/l行列增加一个偏移值
#
#  \wait[param] → 设置等待（同 对话框扩展）
#
# - 利用脚本为指定的控制类转义符设置变量的值
#
#        MESSAGE_EX.set_scroll_params(sym, str)
#
#   其中 sym 为转义符的名称，需要传入 Symbol类型，比如 \win 转义符对应为 :win
#   其中 str 为变量参数字符串，同默认，为 String类型，如 "o5x320y100w300h200"
#------------------------------------------------------------------------------
# - 文本特效类
#     此项同 对话框扩展 中的全部内容
#----------------------------------------------------------------------------
# - 扩展类
#     此项同 对话框扩展 中的全部内容
#------------------------------------------------------------------------------
# ● 标签对列表
#------------------------------------------------------------------------------
# - 文本替换类
#  <if {cond}>...</cond> → 如果eval(cond)返回true，则绘制标签对内部内容，否则跳过
#                         可用 s 代替 $game_switches，用 v 代替 $game_variables
#
# - 控制类
#  <para>...</para> → 需要并行绘制的文本
#                     当主绘制进程绘制到 <para> 时，标签对中的文本将同步开始绘制，
#                     同时主进程继续绘制 </para> 后面的内容
#
#  <rb>...</rb> → 需要执行的脚本，当文字绘制到该标签对时才会执行
#                 可用 s 代替 $game_switches，用 v 代替 $game_variables
#                 可用 cs 代替 已绘制的文字精灵数组（按绘制顺序排列）
#                 （Sprite_EagleCharacter_ScrollText 的实例的数组）
#                 可用 win 代替本窗口
#
#  <pic sym>...</pic> → 显示指定图片
#                   其中 sym 替换成 当前图片的唯一标识符
#                      在 rb 标签对中，可用 pics[sym] 获取该图片的精灵（Sprite类）
#                   其中 ... 替换成 精灵参数字符串|图片名称|位图参数字符串
#         精灵参数字符串可用变量一览：
#            o → 设置图片的显示原点（默认7）（九宫格小键盘位置）
#            x/y → 设置图片原点的坐标（窗口左上角为(0,0)原点）
#            z → 图片显示z值的增量（默认-1，显示在文字之下）
#            a → 显示的不透明度（默认255）
#            m → 是否开启水平镜像翻转（默认false）
#         图片名称：
#            图片放置于 Graphics/Pictures 目录下，可省略后缀名
#         位图参数字符串可用变量一览：（可省略）
#            x/y/w/h → 图片中需要显示的矩形区域范围（默认取整张图片）
#
#     示例： <pic 1>x10y10|foo</pic> → 在滚动文本框内的(10,10)处显示foo图片
#==============================================================================

#==============================================================================
# ○ 【设置部分】
#==============================================================================
module MESSAGE_EX
  #--------------------------------------------------------------------------
  # ● 【设置】定义转义符各参数的预设值
  # （对于bool型变量，0与false等价，1与true等价）
  #--------------------------------------------------------------------------
  SCROLL_PARAMS_INIT = {
    # \win[]
    :win => {
      # 窗口自身相关
      :opa => 255, # 窗口的不透明度
      :o => 7, # 窗口位置的显示原点类型
      :x => 0, # 窗口打开时所在位置
      :y => 0,
      :w => Graphics.width, # 窗口打开时大小
      :h => Graphics.height,
      :skin => 0, # 皮肤index
      # 文字绘制属性
      :xo => 0, # 第一个文字的绘制位置
      :yo => 0,
      :cdx => 1, # 默认下一个字的横轴偏移量（负数为往左侧移动相应单位，正数为往右）
      :cdy => 0, # 默认下一个字的纵轴偏移量（负数为往上侧移动相应单位，正数为往下）
      :ck => 0, # 缩减的字符间距值（默认0）
      :ldx => 0, # 默认下一行的横轴偏移量（负数为往左，正数为往右）
      :ldy => 1, # 默认下一行的纵轴偏移量（负数为往上，正数为往下）
      :lh => 24, # 标准行高
      :lhd => 0, # 行间距
      :cwi => 7, # 绘制一个字完成后的等待帧数
      :cwo => 0, # 单个文字开始移出后的等待帧数（最小值0）
      :cfast => 1, # 是否允许快进显示
    }, # :win
    # \pos[]
    :pos => {
      :x => nil, :dx => nil, # 下一个文字的x值 / 相对上一个文字的x偏移增值
      :y => nil, :dy => nil, #
      :l => nil, :dl => nil, # 下一个文字所在列号 / 相对上一个文字的列数偏移增值
      :c => nil, :dc => nil, # 下一个文字所在行号 / 相对上一个文字的行数偏移增值
    }, # :pos
    # \font[]
    :font => {
      :size => Font.default_size, # 字体大小
      :i => Font.default_italic, # 斜体绘制
      :b => Font.default_bold, # 加粗绘制
      :s => Font.default_shadow, # 阴影
      :ca => 255, # 不透明度
      :o => Font.default_outline, # 描边
      :or => Font.default_out_color.red,
      :og => Font.default_out_color.green,
      :ob => Font.default_out_color.blue,
      :oa => Font.default_out_color.alpha,
      :p => 0, # 底纹
      :pc => 8, # 底纹颜色index
      :l => 0, # 外发光
      :lc => 16, # 外发光颜色index
      :d => 0, # 删除线
      :dc => 8, # 删除线颜色index
      :u => 0, # 下划线
      :uc => 8, # 下划线颜色index
    }, # :font
    # \pause[]
    :pause => {
      :pause => 0,  # 源位图index
      :o => 4,  # 自身的显示原点类型
      :do => 0,  # 相对于对话框的显示位置（九宫格小键盘）（0时为在文末）
      :dx => 0,  # xy偏移值
      :dy => 0,
      :t => 7, # 每两帧之间的等待帧数
      :v => 1,  # 是否显示
    }, # :pause
    # 设置默认启用的文字特效
    :charas => { :cin => "", :cout => "" },
    # 设置额外转义符
    :ex => {
      # 渐变色绘制
      :cg => "",
    },
  }
  #--------------------------------------------------------------------------
  # ● 【设置】定义文字特效类转义符各参数的初始值
  #  默认与 对话框扩展 中的保持一致，但此处预设将覆盖对话框中预设
  #--------------------------------------------------------------------------
  ST_CIN_PARAMS_INIT = {
  # \cin[]
  }
  ST_COUT_PARAMS_INIT = {
  # \cout[]
  }
  ST_CSIN_PARAMS_INIT = {
  }
  ST_CWAVE_PARAMS_INIT = {
  # \cwave[]
  }
  ST_CSWING_PARAMS_INIT = {
  # \cswing[]
  }
  ST_CSHAKE_PARAMS_INIT = {
  # \cshake[]
  }
  ST_CFLASH_PARAMS_INIT = {
  # \cflash[]
  }
  ST_CMIRROR_PARAMS_INIT = {}
  ST_CU_PARAMS_INIT = {
  # \cu[]
  }
end

#==============================================================================
# ○ 读取设置
#==============================================================================
module MESSAGE_EX
  #--------------------------------------------------------------------------
  # ● 获取指定文字特效类转义符的基础设置
  #--------------------------------------------------------------------------
  def self.get_default_cparams_st(param_sym)
    MESSAGE_EX.const_get("ST_#{param_sym.to_s.upcase}_PARAMS_INIT".to_sym) rescue {}
  end
  #--------------------------------------------------------------------------
  # ● 设置参数
  #--------------------------------------------------------------------------
  def self.set_scroll_params(sym, str)
    MESSAGE_EX.parse_param($game_message.scroll_params[sym], str)
  end
end

#==============================================================================
# ○ Game_Message
#==============================================================================
class Game_Message
  attr_accessor :scroll_params
  #--------------------------------------------------------------------------
  # ● 获取全部可保存params的符号的数组
  #--------------------------------------------------------------------------
  alias eagle_scrolltext_ex_params eagle_params
  def eagle_params
    eagle_scrolltext_ex_params + [:scroll]
  end
end

#==============================================================================
# ○ Window_ScrollText
#==============================================================================
class Window_ScrollText < Window_Base
  include MESSAGE_EX::CHARA_EFFECTS
  attr_reader :eagle_chara_viewport
  #--------------------------------------------------------------------------
  # ● 参数组
  #--------------------------------------------------------------------------
  def params; $game_message.scroll_params; end
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize
    super(0, 0, Graphics.width, Graphics.height)
    @eagle_chara_viewport = Viewport.new # 文字精灵的显示区域
    @eagle_chara_viewport.z = self.z + 1
    @eagle_sprite_pause = Sprite_EaglePauseTag.new(self) # 初始化等待按键的精灵
    @eagle_sprite_pause.z = self.z + 10
    @eagle_chara_sprites = []
    @last_chara_sprite = nil
    @eagle_fibers = {} # 存储并行绘制的线程 id => fiber
    @eagle_fibers_params = {} # 存储待处理的并行绘制 id => text
    @eagle_last_fiber_id = 0 # 并行线程id计数
    @eagle_rbs = {} # 存储需要执行的脚本 id => string
    @eagle_rb_count = 0 # 脚本记录计数
    @eagle_pics = {} # 存储显示的图片精灵 sym => Sprite

    self.arrows_visible = false
    self.openness = 0
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  alias eagle_scroll_ex_dispose dispose
  def dispose
    eagle_scroll_ex_dispose
    @eagle_chara_viewport.dispose
  end
  #--------------------------------------------------------------------------
  # ● 重新生成适合全部文字的位图
  #--------------------------------------------------------------------------
  def recreate_contents_for_charas
    w = @eagle_charas_w; h = @eagle_charas_h
    return if w < eagle_charas_max_w && h < eagle_charas_max_h
    f = self.contents.font.dup
    self.contents.dispose
    self.contents = Bitmap.new(w, h)
    self.contents.font = f
  end

  #--------------------------------------------------------------------------
  # ● 打开窗口并等待窗口开启完成
  #--------------------------------------------------------------------------
  def open_and_wait
    eagle_change_windowskin(win_params[:skin])
    self.move(win_params[:x], win_params[:y], win_params[:w], win_params[:h])
    self.opacity = win_params[:opa]
    MESSAGE_EX.reset_xy_origin(self, win_params[:o])
    return self.openness = 0 if self.opacity == 0
    open
    Fiber.yield until open?
  end
  #--------------------------------------------------------------------------
  # ● 关闭窗口并等待关闭完成
  #--------------------------------------------------------------------------
  def close_and_wait
    @eagle_last_fiber_id = 0
    chara_sprites_move_out
    @eagle_pics.each { |sym, s| s.bitmap.dispose; s.dispose }
    @eagle_pics.clear
    close
    Fiber.yield until close?
  end
  #--------------------------------------------------------------------------
  # ● 移出全部文字
  #--------------------------------------------------------------------------
  def chara_sprites_move_out
    @eagle_chara_sprites.each do |c|
      c.move_out
      c.update if !c.disposed?
      win_params[:cwo].times { Fiber.yield }
    end
    @eagle_chara_sprites.clear # 文字池接管更新
  end

  #--------------------------------------------------------------------------
  # ● 更新画面
  #--------------------------------------------------------------------------
  def update
    super
    update_eagle_sprites
    update_eagle_fibers
    if @fiber
      @fiber.resume
    elsif $game_message.scroll_mode && $game_message.has_text?
      @fiber = Fiber.new { fiber_main }
      @fiber.resume
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新全部精灵
  #--------------------------------------------------------------------------
  def update_eagle_sprites
    @eagle_sprite_pause.update if @eagle_sprite_pause.visible
    @eagle_chara_sprites.each { |c| c.update if !c.disposed? }
  end
  #--------------------------------------------------------------------------
  # ● 更新并行线程
  #--------------------------------------------------------------------------
  def update_eagle_fibers
    @eagle_fibers.each { |id, fiber| fiber.resume }
  end

  #--------------------------------------------------------------------------
  # ● 主绘制的逻辑
  #--------------------------------------------------------------------------
  def fiber_main
    open_and_wait
    text, pos = pre_process_all_text
    process_all_text(text, pos)
    after_process_all_text
    close_and_wait
    @fiber = nil
  end
  #--------------------------------------------------------------------------
  # ● 等待
  #--------------------------------------------------------------------------
  def wait(duration)
    duration.times { Fiber.yield }
  end
  #--------------------------------------------------------------------------
  # ● 主绘制前的预处理
  #--------------------------------------------------------------------------
  def pre_process_all_text
    # 重置
    @eagle_charas_w = @eagle_charas_h = 0
    reset_font_settings
    clear_flags
    # 获取最终绘制文本
    text = convert_escape_characters($game_message.all_text)
    text = pre_process_tags(text)
    t = MESSAGE_EX::SCROLL_PARAMS_INIT.keys.inject("") { |s, k| s + "\e#{k}" }
    # 获取初始绘制参数
    pos = { :x_line => win_params[:xo], :y_line => win_params[:yo] }
    pos[:x] = pos[:x_line]; pos[:y] = pos[:y_line]
    return t + text, pos
  end

  def eagle_new_page # TODO
    @eagle_pages = []
  end
  #--------------------------------------------------------------------------
  # ● 重置字体设置
  #--------------------------------------------------------------------------
  def reset_font_settings
    change_color(normal_color)
    self.contents.font.color.alpha = font_params[:ca]
    font_params[:c] = 0
  end
  #--------------------------------------------------------------------------
  # ● 预处理标签对
  #--------------------------------------------------------------------------
  def pre_process_tags(text)
    # 条件判断标签对
    s = $game_switches; v = $game_variables
    text.gsub!(/<if ?{(.*?)}>(.*?)<\/if>/) { eval($1) == true ? $2 : "" }
    # 图片标签对
    text.gsub!(/<pic (.*?)>(.*?)<\/pic>/) {
      sym = $1
      @eagle_pics[$1] = $2
      "\epic[#{sym}]"
    }
    # 脚本标签对
    text.gsub!(/<rb>(.*?)<\/rb>/) {
      @eagle_rb_count += 1
      @eagle_rbs[@eagle_rb_count] = $1
      "\erbl[#{@eagle_rb_count}]"
    }
    # 如果发现并行绘制标签对，则创建线程，并替换成转义符来启动并行绘制
    text.gsub!(/<para>(.*?)<\/para>/) {
      @eagle_last_fiber_id += 1
      @eagle_fibers_params[@eagle_last_fiber_id] = $1
      "\epara[#{@eagle_last_fiber_id}]"
    }
    text
  end

  #--------------------------------------------------------------------------
  # ● 处理指定内容的绘制
  #--------------------------------------------------------------------------
  def process_all_text(text, pos)
    return if text.nil?
    process_character(text.slice!(0, 1), text, pos) until text.empty?
  end
  #--------------------------------------------------------------------------
  # ● 文字区域的左上角位置（屏幕坐标系）
  #--------------------------------------------------------------------------
  def eagle_charas_x0
    self.x + standard_padding
  end
  def eagle_charas_y0
    self.y + standard_padding
  end
  #--------------------------------------------------------------------------
  # ● 计算可供文字显示的区域的宽度和高度
  #--------------------------------------------------------------------------
  def eagle_charas_max_w
    self.width - standard_padding * 2
  end
  def eagle_charas_max_h
    self.height - standard_padding * 2
  end
  #--------------------------------------------------------------------------
  # ● 文字可视区域左上点在文字区域中的坐标
  #--------------------------------------------------------------------------
  def eagle_charas_ox; self.ox; end
  def eagle_charas_oy; self.oy; end
  #--------------------------------------------------------------------------
  # ● 文字的标准宽度高度
  #--------------------------------------------------------------------------
  def eagle_standard_cw
    contents.font.size - win_params[:ck]
  end
  def eagle_standard_ch
    line_height - win_params[:lhd]
  end
  #--------------------------------------------------------------------------
  # ● 获取行高
  #--------------------------------------------------------------------------
  def line_height
    win_params[:lh]
  end
  #--------------------------------------------------------------------------
  # ● 重置绘制位置
  #--------------------------------------------------------------------------
  def eagle_reset_draw_pos(pos) # 在绘制前的位置处理
    return if pos_params.nil?
    pos[:x] = pos_params[:x] if pos_params[:x]
    pos[:y] = pos_params[:y] if pos_params[:y]
    pos[:x] = (pos_params[:l]-1) * eagle_standard_cw if pos_params[:l]
    pos[:y] = (pos_params[:c]-1) * eagle_standard_ch if pos_params[:c]
    pos[:x] += pos_params[:dx] if pos_params[:dx]
    pos[:y] += pos_params[:dy] if pos_params[:dy]
    pos[:x] += (pos_params[:dl] * eagle_standard_cw) if pos_params[:dl]
    pos[:y] += (pos_params[:dc] * eagle_standard_ch) if pos_params[:dc]
    params.delete(:pos)
  end
  #--------------------------------------------------------------------------
  # ● 普通文字的处理（覆盖）
  #--------------------------------------------------------------------------
  def process_normal_character(c, pos)
    eagle_reset_draw_pos(pos)
    c_rect = text_size(c); c_w = c_rect.width; c_h = c_rect.height
    s = eagle_new_chara_sprite(pos[:x], pos[:y], c_w, c_h)
    s.eagle_font.draw(s.bitmap, 0, 0, c_w, c_h, c, 0)
    eagle_process_draw_end(c_w, c_h, pos)
  end
  #--------------------------------------------------------------------------
  # ● 处理控制符指定的图标绘制（覆盖）
  #--------------------------------------------------------------------------
  def process_draw_icon(icon_index, pos)
    eagle_reset_draw_pos(pos)
    s = eagle_new_chara_sprite(pos[:x], pos[:y], 24, 24)
    s.eagle_font.draw_icon(s.bitmap, 0, 0, icon_index)
    eagle_process_draw_end(24, 24, pos)
  end
  #--------------------------------------------------------------------------
  # ● （封装）生成一个新的文字精灵
  #--------------------------------------------------------------------------
  def eagle_new_chara_sprite(c_x, c_y, c_w, c_h)
    f = Font_EagleCharacter.new(font_params)
    f.set_param(:skin, win_params[:skin])
    f.set_param(:cg, ex_params[:cg])

    s = Sprite_EagleCharacter_ScrollText.new(self, f, c_x, c_y, c_w, c_h,
      @eagle_chara_viewport)
    s.start_effects(params[:charas])
    s.update
    @eagle_chara_sprites.push(s)
    s
  end
  #--------------------------------------------------------------------------
  # ● 绘制完成时的处理
  #--------------------------------------------------------------------------
  def eagle_process_draw_end(c_w, c_h, pos)
    # 存储行首位置
    pos[:first_chara_sprite] = @eagle_chara_sprites[-1] if pos[:first_chara_sprite].nil?
    # 存储当前所占用宽高
    @eagle_charas_w = pos[:x] + c_w if pos[:x] + c_w > @eagle_charas_w
    @eagle_charas_h = pos[:y] + c_h if pos[:y] + c_h > @eagle_charas_h
    # 处理下一次绘制的参数
    pos[:x] += ((c_w - win_params[:ck]) * win_params[:cdx])
    pos[:y] += ((c_h - win_params[:ck]) * win_params[:cdy])
    return if show_fast? # 如果是立即显示，则不更新
    eagle_process_draw_update
    wait_for_one_character
  end
  #--------------------------------------------------------------------------
  # ● 绘制完成时的更新
  #--------------------------------------------------------------------------
  def eagle_process_draw_update
    # 设置文字显示区域的矩形（屏幕坐标）
    @eagle_chara_viewport.rect.set(eagle_charas_x0, eagle_charas_y0,
      eagle_charas_max_w, eagle_charas_max_h)
    # 确保最后绘制的文字在视图区域内
    ensure_character_visible
  end
  #--------------------------------------------------------------------------
  # ● 确保最后绘制完成的文字在视图内
  #--------------------------------------------------------------------------
  def ensure_character_visible
    c = @eagle_chara_sprites[-1]
    self.ox = 0 if c._x < self.ox
    d = c._x + c.width - @eagle_chara_viewport.rect.width
    self.ox = d if d > 0
    self.oy = 0 if c._y < self.oy
    d = c._y + c.height - @eagle_chara_viewport.rect.height
    self.oy = d if d > 0
  end
  #--------------------------------------------------------------------------
  # ● 换行文字的处理
  #--------------------------------------------------------------------------
  def process_new_line(text, pos)
    @line_show_fast = false
    if pos[:first_chara_sprite] # 如果存储了行首文字，则以它为基准
      x_ = pos[:first_chara_sprite]._x
      y_ = pos[:first_chara_sprite]._y
    else # 否则，以初始定下的行首位置为基准
      x_ = pos[:x_line]
      y_ = pos[:y_line]
    end
    pos[:x] = x_ + eagle_standard_cw * win_params[:ldx]
    pos[:y] = y_ + eagle_standard_ch * win_params[:ldy]
    pos[:x_line] = pos[:x]
    pos[:y_line] = pos[:y]
    pos[:first_chara_sprite] = nil
  end

  #--------------------------------------------------------------------------
  # ● 输出一个字符后的等待
  #--------------------------------------------------------------------------
  def wait_for_one_character
    win_params[:cwi].times do
      return if show_fast?
      update_show_fast if win_params[:cfast]
      Fiber.yield
    end
  end
  #--------------------------------------------------------------------------
  # ● 清除标志
  #--------------------------------------------------------------------------
  def clear_flags
    @show_fast = false          # 快进的标志
    @line_show_fast = false     # 行单位快进的标志
  end
  #--------------------------------------------------------------------------
  # ● 处于快进显示？
  #--------------------------------------------------------------------------
  def show_fast?
    @show_fast || @line_show_fast
  end
  #--------------------------------------------------------------------------
  # ● 监听“确定”键的按下，更新快进的标志
  #--------------------------------------------------------------------------
  def update_show_fast
    @show_fast = true if Input.trigger?(:C)
  end

  #--------------------------------------------------------------------------
  # ● 全部绘制完成后的处理
  #--------------------------------------------------------------------------
  def after_process_all_text
    input_pause
    $game_message.clear
  end
  #--------------------------------------------------------------------------
  # ● 处理输入等待
  #--------------------------------------------------------------------------
  def input_pause
    eagle_process_draw_update
    @eagle_sprite_pause.bind_last_chara(@eagle_chara_sprites[-1])
    @eagle_sprite_pause.show
    process_input_pause
    @eagle_sprite_pause.hide
  end
  #--------------------------------------------------------------------------
  # ● 执行输入等待
  #--------------------------------------------------------------------------
  def process_input_pause
    ox_des = [self.ox, @eagle_charas_w - @eagle_chara_viewport.rect.width].max
    oy_des = self.oy
    recreate_contents_for_charas
    d_oxy = 1; last_input = nil; last_input_c = 0
    self.arrows_visible = true
    while true
      Fiber.yield
      break if Input.trigger?(:B) || Input.trigger?(:C)
      # 处理文本滚动
      if Input.press?(:UP)
        self.oy -= d_oxy
        self.oy = 0 if self.oy < 0
      elsif Input.press?(:DOWN)
        self.oy += d_oxy
        self.oy = oy_des if self.oy > oy_des
      elsif Input.press?(:LEFT)
        self.ox -= d_oxy
        self.ox = 0 if self.ox < 0
      elsif Input.press?(:RIGHT)
        self.ox += d_oxy
        self.ox = ox_des if self.ox > ox_des
      end
      if last_input == Input.dir4
        last_input_c += 1
        d_oxy += 1 if last_input_c % 10 == 0
      else
        d_oxy = 1
        last_input_c = 0
      end
      last_input = Input.dir4
    end
    self.arrows_visible = false
    Input.update
  end

  #--------------------------------------------------------------------------
  # ● 控制符的处理
  #     code : 控制符的实际形式（比如“\C[1]”是“C”）
  #     text : 绘制处理中的字符串缓存（字符串可能会被修改）
  #     pos  : 绘制位置 {:x, :y, :new_x, :height}
  #--------------------------------------------------------------------------
  def process_escape_character(code, text, pos)
    case code.upcase
    when '.'; wait(15)
    when '|'; wait(60)
    when '!'; input_pause
    when '>'; @line_show_fast = true
    when '<'; @line_show_fast = false
    when 'PARA'; eagle_activate_fiber(obtain_escape_param(text), pos)
    when 'PAGE'; eagle_new_page
    when 'C'
      font_params[:c] = obtain_escape_param(text)
      change_color(text_color(font_params[:c]))
    else
      temp_code = code.downcase
      m_c = ("eagle_text_control_" + temp_code).to_sym
      m_e = ("eagle_chara_effect_" + temp_code).to_sym
      if respond_to?(m_c)
        param = obtain_escape_param_string(text)
        method(m_c).call(param)
      elsif respond_to?(m_e)
        param = obtain_escape_param_string(text)
        # 当只传入 0 时，代表关闭该特效
        return eagle_chara_effect_clear(temp_code.to_sym) if param == '0'
        params[:charas][temp_code.to_sym] = param
        method(m_e).call(param)
      else
        super
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 获取控制符的实际形式（这个方法会破坏原始数据）
  #--------------------------------------------------------------------------
  def obtain_escape_code(text)
    text.slice!(/^[\$\.\|\^!><\{\}\\]|^[A-Z]+/i)
  end
  #--------------------------------------------------------------------------
  # ● 获取控制符的参数（字符串形式）（这个方法会破坏原始数据）
  #--------------------------------------------------------------------------
  def obtain_escape_param_string(text)
    text.slice!(/^\[[\$\-\d\w]+\]/)[/[\$\-\d\w]+/] rescue ""
  end
  #--------------------------------------------------------------------------
  # ● 清除暂存的指定文字特效
  #--------------------------------------------------------------------------
  def eagle_chara_effect_clear(code_sym)
    params[:charas].delete(code_sym)
    default_params = MESSAGE_EX.get_default_params(:scroll)[:charas]
    params[:charas] = default_params[code_sym] if default_params[code_sym]
  end

  #--------------------------------------------------------------------------
  # ● 激活并行绘制
  #--------------------------------------------------------------------------
  def eagle_activate_fiber(id, pos)
    pos_ = { :x => pos[:x], :y => pos[:y] }
    @eagle_fibers[id] = Fiber.new { eagle_fiber_main(id, pos_) }
    @eagle_fibers[id].resume
  end
  #--------------------------------------------------------------------------
  # ● 并行绘制的逻辑
  #--------------------------------------------------------------------------
  def eagle_fiber_main(id, pos)
    process_all_text(@eagle_fibers_params[id], pos)
    @eagle_fibers.delete(id)
  end

  #--------------------------------------------------------------------------
  # ● 解析字符串参数
  #--------------------------------------------------------------------------
  def parse_param(param_hash, param_text, default_type = "default")
    MESSAGE_EX.parse_param(param_hash, param_text, default_type)
  end
  #--------------------------------------------------------------------------
  # ● 设置font参数
  #--------------------------------------------------------------------------
  def font_params; params[:font]; end
  def eagle_text_control_font(param = "")
    parse_param(params[:font], param, :size)
    MESSAGE_EX.apply_font_params(self.contents.font, params[:font])
    change_color(text_color(font_params[:c]))
  end
  #--------------------------------------------------------------------------
  # ● 放大字体尺寸（覆盖）
  #--------------------------------------------------------------------------
  def make_font_bigger
    contents.font.size += 4 if contents.font.size <= 64
    font_params[:size] = contents.font.size
  end
  #--------------------------------------------------------------------------
  # ● 缩小字体尺寸（覆盖）
  #--------------------------------------------------------------------------
  def make_font_smaller
    contents.font.size -= 4 if contents.font.size >= 16
    font_params[:size] = contents.font.size
  end
  #--------------------------------------------------------------------------
  # ● 更改内容绘制颜色（覆盖）
  #     enabled : 有效的标志。false 的时候使用半透明效果绘制
  #--------------------------------------------------------------------------
  def change_color(color, enabled = true)
    super(color, enabled)
    font_params[:ca] = self.contents.font.color.alpha
  end
  #--------------------------------------------------------------------------
  # ● 设置win参数
  #--------------------------------------------------------------------------
  def win_params; params[:win]; end
  def eagle_text_control_win(param = "")
    parse_param(params[:win], param, :default)
    eagle_change_windowskin(win_params[:skin])
  end
  #--------------------------------------------------------------------------
  # ● 变更窗口皮肤
  #--------------------------------------------------------------------------
  def eagle_change_windowskin(index)
    return if @last_windowskin_index == index
    @last_windowskin_index = index
    self.windowskin = MESSAGE_EX.windowskin(index)
    change_color(text_color(0))
  end
  #--------------------------------------------------------------------------
  # ● 设置pos参数
  #--------------------------------------------------------------------------
  def pos_params; params[:pos]; end
  def eagle_text_control_pos(param = "")
    params[:pos] = {}
    parse_param(params[:pos], param, :default)
  end
  #--------------------------------------------------------------------------
  # ● 设置pause参数
  #--------------------------------------------------------------------------
  def pause_params; params[:pause]; end
  def eagle_text_control_pause(param = "")
    parse_param(params[:pause], param, :pause)
    @eagle_sprite_pause.reset
  end
  #--------------------------------------------------------------------------
  # ● 设置wait参数
  #--------------------------------------------------------------------------
  def eagle_text_control_wait(param = '0')
    h = {}
    h[:t] = 0 # 等待帧数
    parse_param(h, param, :t)
    wait(h[:t])
  end
  #--------------------------------------------------------------------------
  # ● 设置pic参数
  #--------------------------------------------------------------------------
  def eagle_text_control_pic(param = '0')
    sym = param
    return if @eagle_pics[sym].nil?
    params = @eagle_pics[sym].split('|')
    @eagle_pics.delete(sym)
    pic_bitmap = Cache.picture(params[1]) rescue return
    h = { :o => 7, :x => 0, :y => 0, :z => -1, :m => 0, :a => 255 }
    parse_param(h, params[0], :o)
    h2 = { :x => 0, :y => 0, :w => pic_bitmap.width, :h => pic_bitmap.height }
    parse_param(h2, params[2], :x) if params[2]

    s = Sprite.new(@eagle_chara_viewport)
    s.x = h[:x]; s.y = h[:y]; s.z = h[:z]; s.opacity = h[:a]
    s.mirror = h[:m] != 0
    s.bitmap = Bitmap.new(h2[:w], h2[:h])
    s.bitmap.blt(0, 0, pic_bitmap, Rect.new(h2[:x], h2[:y], h2[:w], h2[:h]))
    @eagle_pics[sym] = s
  end
  #--------------------------------------------------------------------------
  # ● 设置rbl脚本参数
  #--------------------------------------------------------------------------
  def eagle_text_control_rbl(param = '0')
    cs = @eagle_chara_sprites
    pics = @eagle_pics
    win = self
    s = $game_switches; v = $game_variables
    eval(@eagle_rbs[param.to_i])
  end
  #--------------------------------------------------------------------------
  # ● 设置cg参数 / 渐变绘制预定
  #--------------------------------------------------------------------------
  def ex_params; params[:ex]; end
  if defined?(Sion_GradientText)
  def eagle_text_control_cg(param = '0')
    ex_params[:cg].clear
    ex_params[:cg] = param if param != '' && param != '0'
  end
  end
end

#==============================================================================
# ○ 单个文字的精灵
#==============================================================================
class Sprite_EagleCharacter_ScrollText < Sprite_EagleCharacter
  #--------------------------------------------------------------------------
  # ● 初始化特效的默认参数
  #--------------------------------------------------------------------------
  def init_effect_params(sym)
    @params[sym] = MESSAGE_EX.get_default_params(sym).dup
    @params[sym].merge!(MESSAGE_EX.get_default_cparams_st(sym))
  end
end
