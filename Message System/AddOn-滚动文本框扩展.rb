#==============================================================================
# ■ Add-On 滚动文本框扩展 by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【对话框扩展 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-ScrollTextEX"] = true
#=============================================================================
# - 2019.6.5.11 文字精灵调用独立Font对象
#==============================================================================
# - 完全覆盖默认的滚动文本指令，现在拥有与 对话框扩展 中的对话框相同的描绘方式
# - 关于转义符：
#     使用方式与 对话框扩展 中的保持一致
# - 关于标签对：
#     在标签对中的内容，将会被按照标签对的作用进行统一处理
# - 由于效率问题，本插件暂不支持翻页或滚动
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
#    skin → 窗口所用皮肤的index（同 对话框扩展）
#  （文字摆放相关）
#    xo 与 yo → 第一个文字的绘制位置
#    cdx → 下一个字的横轴偏移量（负数为往左，正数为往右）（默认1，朝右侧前进一个文字）
#    cdy → 下一个字的纵轴偏移量（负数为往上，正数为往下）（默认0，与前一个字高度对齐）
#    ck → 设置缩减的字符间距值（默认0）
#    ldx → 下一行的横轴偏移量（负数为往左，正数为往右）（默认0，与上一行行首对齐）
#    ldy → 下一行的纵轴偏移量（负数为往上，正数为往下）（默认1，朝下侧移动一行）
#    lh → 设置增加的行间距值（默认0）
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
#  \pic[param] -【重置】在指定位置绘制指定图片
#    id → 指定需要绘制的图片的id（见【设置】中自定义）
#    o → 设置图片的显示原点（默认7）（九宫格小键盘位置）
#    x/y → 设置图片原点的显示位置（描绘的第一个字的左上角为(0,0)原点）
#------------------------------------------------------------------------------
# - 文本特效类
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
      :skin => 0, # 皮肤index
      # 文字绘制属性
      :xo => 0, # 第一个文字的绘制位置
      :yo => 0,
      :cdx => 1, # 默认下一个字的横轴偏移量（负数为往左侧移动相应单位，正数为往右）
      :cdy => 0, # 默认下一个字的纵轴偏移量（负数为往上侧移动相应单位，正数为往下）
      :ck => 0, # 缩减的字符间距值（默认0）
      :ldx => 0, # 默认下一行的横轴偏移量（负数为往左，正数为往右）
      :ldy => 1, # 默认下一行的纵轴偏移量（负数为往上，正数为往下）
      :lh => 0, # 增加的行间距值
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
      :t => 10, # 每两帧之间的等待帧数
      :v => 1,  # 是否显示
    }, # :pause
    # 设置默认的文字特效
    :charas => { :cin => "", :cout => "" },
  }
  #--------------------------------------------------------------------------
  # ● 【设置】定义文字特效类转义符各参数的初始值
  #--------------------------------------------------------------------------
  ST_CIN_PARAMS_INIT = {
  # \cin[]
    :t => 15, # 移入所用帧数
    :vx => 0,  # 每vxt帧x的增量
    :vxt => 1,
    :vy => 0,  # 每vyt帧y的增量
    :vyt => 1,
    :vz => 0,  # 每vzt帧zoom的增量
    :vzt => 1,
    :va => 0,  # 每帧角度增量
  }
  ST_COUT_PARAMS_INIT = {
  # \cout[]
    :t => 15, # 移出所用帧数
    :vx => 0,  # 每vxt帧x的增量
    :vxt => 1,
    :vy => 0,  # 每vyt帧y的增量
    :vyt => 1,
    :vz => 0,  # 每vzt帧zoom的增量
    :vzt => 1,
    :va => 0,  # 每帧角度增量
  }
  ST_CSIN_PARAMS_INIT = {
    :a => 2, # 幅度
    :l => 2, # 频度
    :s => 240, # 速度
    :p => 0, # 相位
  }
  ST_CWAVE_PARAMS_INIT = {
  # \cwave[]
    :h  => 2,  # Y方向上的最大偏移值
    :t  => 4,  # 移动一像素所耗帧数
    :vy => -1, # 起始速度的Y方向分量（正数向下）
  }
  ST_CSHAKE_PARAMS_INIT = {
  # \cshake[]
    :l => 3,  # 距离所在原点的最大偏移量（左右上下）
    :r => 3,
    :u => 3,
    :d => 3,
    :vx  => 0,  # x的初始移动方向（0为随机方向）
    :vxt => 1,  # x方向移动一像素所耗帧数
    :vy  => 0,  # y的初始移动方向（0为随机方向）
    :vyt => 1,  # y方向移动一像素所耗帧数
  }
  ST_CFLASH_PARAMS_INIT = {
  # \cflash[]
    :r => 255, # 闪烁颜色RGBA
    :g => 255,
    :b => 255,
    :a => 255,
    :d => 60,  # 闪烁帧数
    :t => 60,  # 闪烁后的等待时间
  }
  ST_CMIRROR_PARAMS_INIT = {}
  ST_CU_PARAMS_INIT = {
  # \cu[]
    :t => 10, # 每两次消散之间的时间间隔
    :n => 20, # 消散的粒子总数
    :d =>  2, # 消散的粒子的大小（直径/边长）
    :o =>  1, # 透明度变更量的最小值
    :s =>  0, # 粒子的形状类型
    :dir => 4, # 消散方向类型
  }
  #--------------------------------------------------------------------------
  # ● 【设置】定义\pic转义符中的id与对应图片
  # （均位于 Graphics/Pictures 目录下）
  #--------------------------------------------------------------------------
  ID_TO_PICS = {
    # id => pic_name,
    0 => "",
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
  #--------------------------------------------------------------------------
  # ● 参数组
  #--------------------------------------------------------------------------
  def params; $game_message.scroll_params; end
  #--------------------------------------------------------------------------
  # ● 获取字体对象
  #--------------------------------------------------------------------------
  def font
    self.contents.font
  end
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize
    super(0, 0, Graphics.width, Graphics.height)
    @eagle_chara_sprites = []
    @last_chara_sprite = nil
    @eagle_sprite_pause = Sprite_EaglePauseTag.new(self) # 初始化等待按键的精灵
    @eagle_sprite_pause.z = self.z + 5
    @eagle_threads = {} # 存储其余的绘制线程 id => fiber
    @eagle_threads_params = {} # 存储待处理的并行绘制 id => text
    @eagle_last_thread_id = 0 # 并行线程id计数

    self.arrows_visible = false
    self.openness = 0
  end
  #--------------------------------------------------------------------------
  # ● 打开窗口并等待窗口开启完成
  #--------------------------------------------------------------------------
  def open_and_wait
    self.opacity = win_params[:opa]
    return self.openness = 0 if self.opacity == 0
    open
    Fiber.yield until open?
  end
  #--------------------------------------------------------------------------
  # ● 关闭窗口并等待关闭完成
  #--------------------------------------------------------------------------
  def close_and_wait
    @eagle_last_thread_id = 0
    chara_sprites_move_out
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
    update_eagle_params
    update_eagle_sprites
    update_eagle_threads
    if @fiber
      @fiber.resume
    elsif $game_message.scroll_mode && $game_message.has_text?
      @fiber = Fiber.new { fiber_main }
      @fiber.resume
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新参数效果
  #--------------------------------------------------------------------------
  def update_eagle_params
    eagle_change_windowskin(win_params[:skin])
  end
  #--------------------------------------------------------------------------
  # ● 更新全部文字精灵
  #--------------------------------------------------------------------------
  def update_eagle_sprites
    @eagle_sprite_pause.update if @eagle_sprite_pause.visible
    @eagle_chara_sprites.each { |c| c.update }
  end
  #--------------------------------------------------------------------------
  # ● 更新并行线程
  #--------------------------------------------------------------------------
  def update_eagle_threads
    @eagle_threads.each { |id, thread| thread.resume }
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
  # ● 主绘制前的预处理
  #--------------------------------------------------------------------------
  def pre_process_all_text
    # 预设置
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
  #--------------------------------------------------------------------------
  # ● 清除标志
  #--------------------------------------------------------------------------
  def clear_flags
    @show_fast = false          # 快进的标志
    @line_show_fast = false     # 行单位快进的标志
  end
  #--------------------------------------------------------------------------
  # ● 预处理TAGS
  #--------------------------------------------------------------------------
  def pre_process_tags(text)
    # 如果发现条件判断标签对，则检查
    s = $game_switches; v = $game_variables
    text.gsub!(/<if ?{(.*?)}>(.*?)<\/if>/) { eval($1) == true ? $2 : "" }
    # 如果发现并行绘制标签对，则创建线程，并替换成转义符来启动并行绘制
    text.gsub!(/<para>(.*?)<\/para>/) {
      @eagle_last_thread_id += 1
      @eagle_threads_params[@eagle_last_thread_id] = $1
      "\epara[#{@eagle_last_thread_id}]"
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
  # ● 文字的标准宽度高度
  #--------------------------------------------------------------------------
  def eagle_standard_cw
    contents.font.size - win_params[:ck]
  end
  def eagle_standard_ch
    line_height
  end
  #--------------------------------------------------------------------------
  # ● 获取行高
  #--------------------------------------------------------------------------
  def line_height
    24 + win_params[:lh]
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
    s = eagle_new_chara_sprite(c, pos[:x], pos[:y], c_w, c_h)
    eagle_draw_extra_background(s.bitmap, 0, 0, c_w, c_h, c, 0)
    eagle_draw_char(s.bitmap, 0, 0, c_w, c_h, c, 0)
    eagle_draw_extra_foreground(s.bitmap)
    eagle_process_draw_end(c_w, c_h, pos)
  end
  #--------------------------------------------------------------------------
  # ● 处理控制符指定的图标绘制（覆盖）
  #--------------------------------------------------------------------------
  def process_draw_icon(icon_index, pos)
    eagle_reset_draw_pos(pos)
    s = eagle_new_chara_sprite(' ', pos[:x], pos[:y], 24, 24)
    _bitmap = Cache.system("Iconset")
    rect = Rect.new(icon_index % 16 * 24, icon_index / 16 * 24, 24, 24)
    eagle_draw_extra_background(s.bitmap, 0, 0, 24, 24, ' ', 0)
    s.bitmap.blt(0, 0, _bitmap, rect, 255)
    eagle_draw_extra_foreground(s.bitmap)
    eagle_process_draw_end(24, 24, pos)
  end
  #--------------------------------------------------------------------------
  # ● （封装）生成一个新的文字精灵
  #--------------------------------------------------------------------------
  def eagle_new_chara_sprite(c, c_x, c_y, c_w, c_h)
    s = Sprite_EagleCharacter_ScrollText.new(self, c, c_x, c_y, c_w, c_h)
    s.start_effects(params[:charas])
    s.update
    @eagle_chara_sprites.push(s)
    s
  end
  #--------------------------------------------------------------------------
  # ● （封装）绘制文字
  #--------------------------------------------------------------------------
  def eagle_draw_char(bitmap, x, y, w, h, c, align = 0)
    bitmap.draw_text(x, y, w * 2, h, c, align)
  end
  #--------------------------------------------------------------------------
  # ● 绘制背景额外内容
  #--------------------------------------------------------------------------
  def eagle_draw_extra_background(bitmap, x, y, w, h, c, align)
    if font_params[:p] > 0 # 底纹
      color = text_color(font_params[:pc])
      case font_params[:p]
      when 1 # 边框
        bitmap.fill_rect(x, y, w, h, color)
        bitmap.clear_rect(x+1, y+1, w-2, h-2)
      when 2 # 纯色方块
        bitmap.fill_rect(x, y, w, h, color)
      end
    end
    if font_params[:l] # 外发光
      color = bitmap.font.color.dup
      bitmap.font.color = text_color(font_params[:lc])
      bitmap.draw_text(x, y, w, h, c, align)
      bitmap.blur
      bitmap.font.color = color
    end
  end
  #--------------------------------------------------------------------------
  # ● 绘制前景额外内容
  #--------------------------------------------------------------------------
  def eagle_draw_extra_foreground(bitmap)
    if font_params[:d] # 绘制删除线
      c = text_color(font_params[:dc])
      bitmap.fill_rect(0, bitmap.height/2 - 1, bitmap.width, 1, c)
    end
    if font_params[:u] # 绘制下划线
      c = text_color(font_params[:uc])
      bitmap.fill_rect(0, bitmap.height - 1, bitmap.width, 1, c)
    end
  end
  #--------------------------------------------------------------------------
  # ● 绘制完成时的处理
  #--------------------------------------------------------------------------
  def eagle_process_draw_end(c_w, c_h, pos)
    # 存储行首位置
    pos[:first_chara_sprite] = @eagle_chara_sprites[-1] if pos[:first_chara_sprite].nil?
    # pause精灵重置位置
    pos[:last_chara_sprite] = @eagle_chara_sprites[-1]
    @eagle_sprite_pause.bind_last_chara(pos[:last_chara_sprite])
    # 处理下一次绘制的参数
    pos[:x] += ((c_w - win_params[:ck]) * win_params[:cdx])
    pos[:y] += ((c_h - win_params[:ck]) * win_params[:cdy])
    return if show_fast? # 如果是立即显示，则不更新
    wait_for_one_character
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
    pos[:x] = x_ + (contents.font.size + win_params[:lh]) * win_params[:ldx]
    pos[:y] = y_ + eagle_standard_ch * win_params[:ldy]
    pos[:x_line] = pos[:x]
    pos[:y_line] = pos[:y]
    pos[:first_chara_sprite] = nil
  end
  #--------------------------------------------------------------------------
  # ● 等待
  #--------------------------------------------------------------------------
  def wait(duration)
    duration.times { Fiber.yield }
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
    @eagle_sprite_pause.show
    wait(10)
    Fiber.yield until Input.trigger?(:B) || Input.trigger?(:C)
    Input.update
    @eagle_sprite_pause.hide
  end

  #--------------------------------------------------------------------------
  # ● 激活并行绘制
  #--------------------------------------------------------------------------
  def eagle_activate_thread(id, pos)
    pos_ = { :x => pos[:x], :y => pos[:y] }
    pos_[:last_chara_sprite] = pos[:last_chara_sprite]
    @eagle_threads[id] = Fiber.new { eagle_thread_main(id, pos_) }
    @eagle_threads[id].resume
  end
  #--------------------------------------------------------------------------
  # ● 并行绘制的逻辑
  #--------------------------------------------------------------------------
  def eagle_thread_main(id, pos)
    process_all_text(@eagle_threads_params[id], pos)
    @eagle_threads.delete(id)
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
    when 'PARA'; eagle_activate_thread(obtain_escape_param(text), pos)
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

    self.contents.font.size = font_params[:size]
    self.contents.font.italic = MESSAGE_EX.check_bool(font_params[:i])
    self.contents.font.bold = MESSAGE_EX.check_bool(font_params[:b])
    self.contents.font.shadow = MESSAGE_EX.check_bool(font_params[:s])
    self.contents.font.color.alpha = font_params[:ca]
    self.contents.font.outline = MESSAGE_EX.check_bool(font_params[:o])
    self.contents.font.out_color.set(font_params[:or],
      font_params[:og],font_params[:ob],
      font_params[:oa])
    params[:font][:l] = MESSAGE_EX.check_bool(font_params[:l])
    params[:font][:d] = MESSAGE_EX.check_bool(font_params[:d])
    params[:font][:u] = MESSAGE_EX.check_bool(font_params[:u])
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
    h = { :id => nil, :x => 0, :y => 0, :o => 7 }
    parse_param(h, param, :id)
    return if h[:id].nil?
    pic_name = MESSAGE_EX::ID_TO_PICS[:id]
    return if pic_name.nil?
    pic_bitmap = Cache.pictures(pic_name) rescue return
    rect = Rect.new(h[:x], h[:y], pic_bitmap.width, pic_bitmap.height)
    MESSAGE_EX.reset_xy_origin(rect, h[:o])
    self.contents.blt(rect.x, rect.y, pic_bitmap, pic_bitmap.rect)
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
    @params[sym] = MESSAGE_EX.get_default_cparams_st(sym).dup # 初始化
  end
end
#==============================================================================
# ○ 事件解释器
#==============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 显示滚动文字
  #--------------------------------------------------------------------------
  def command_105
    Fiber.yield while $game_message.visible
    $game_message.scroll_mode = true
    $game_message.scroll_speed = @params[0]
    $game_message.scroll_no_fast = @params[1]
    while next_event_code == 405
      @index += 1
      $game_message.add(@list[@index].parameters[0])
    end
    wait_for_message
  end
end
