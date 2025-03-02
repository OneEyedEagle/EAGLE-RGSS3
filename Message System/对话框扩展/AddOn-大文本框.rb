#==============================================================================
# ■ Add-On 大文本框 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【对话框扩展 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-MessageBox"] = "1.3.1"
#=============================================================================
# - 2025.2.8.21 
#==============================================================================
# - 本插件新增的大文本框，有以下几个新特性：
#
# ·与【对话框扩展】中的对话框具有相同的文字描绘模式，即可以使用其中的全部文字特效
#
# ·删去文本自动对齐，新增 \pos 转义符用于直接定位文字绘制的位置
#
# ·新增自动换行，当绘制到窗口右侧时，将自动换行
#
# ·新增分页符，支持在相邻页之间切换（确定键下一页，取消键上一页）
#
# ·新增标签对，用于处理更高级的内容
#
#------------------------------------------------------------------------------
# ● 使用方式
#------------------------------------------------------------------------------
# - 当指定开关开启时，将用大文本框替换默认的滚动文本指令
#
#   当大文本框被关闭时，将同时关闭开关
#   如果下一个滚动文本指令仍然想替换成大文本框，请再次手动打开开关
#
# - 关于转义符：使用方式与【对话框扩展】中的保持一致
#
# - 关于标签对：在标签对中的内容，将会按照标签对的作用进行统一处理
#
#------------------------------------------------------------------------------
# ● 转义符及其变量列表
#------------------------------------------------------------------------------
# - 绘制类
#
#     此项同【对话框扩展】中的全部内容
#
#----------------------------------------------------------------------------
# - 控制类
#
#  \c[id] → 扩展了颜色更改（同【对话框扩展】）
#
#  \font[param] → 单个文字绘制的属性（同【对话框扩展】）
#
#  \win[param] → 背景窗口的相关设置
#
#  （窗口属性相关）
#    opa → 窗口的不透明度
#    o → 窗口打开时的显示原点所在位置的类型（九宫格）（默认7左上角）
#    x/y/w/h → 窗口打开时的坐标与实际宽高
#    do → 窗口显示位置类型（同【对话框扩展】）
#    z → 窗口所处z值
#    skin → 窗口所用皮肤的index（同【对话框扩展】）
#
#  （文字摆放相关）
#    xo 与 yo → 第一个文字的绘制位置（窗口contents的左上角为原点）
#    cdx → 下一个字的横轴偏移量（负数往左，正数往右）（默认1，朝右侧前进一个文字）
#    cdy → 下一个字的纵轴偏移量（负数往上，正数往下）（默认0，与前一个字高度对齐）
#    ck  → 设置缩减的字符间距值（默认0）
#    ldx → 下一行的横轴偏移量（负数往左，正数往右）（默认0，与上一行行首对齐）
#    ldy → 下一行的纵轴偏移量（负数往上，正数往下）（默认1，朝下侧移动一行）
#    lh  → 标准行高（默认24）
#    lhd → 行间距（默认0）
#    lx  → 当文字的 x 大于该值时，将进行换行（默认0，不会自动换行）
#          注意：该值不是屏幕坐标，而是窗口内坐标，左侧还有不计入的留空
#
#  （文字显示相关）
#    cwi → 单个文字绘制完成后的等待帧数（最小值0）
#    cwo → 单个文字开始移出后的等待帧数（最小值0）
#    cfast → 是否允许快进显示
#
#  \pause[param] → 等待按键精灵的属性（同【对话框扩展】）
#
#  \pos[param] -【重置】直接指定下一个文字的绘制位置
#
#    x/y → 直接指定x/y像素坐标值（窗口内部绘制区域的左上角为(0, 0)）
#    c/l → 直接指定行号/列号（从1开始）
#         （行高为窗口的 line_height，列宽为窗口的 font.size）
#    dx/dy → x/y方向增加一个像素偏移值
#    dc/dl → c/l行列增加一个偏移值
#
#  \wait[param] → 设置等待（同【对话框扩展】）
#
#----------------------------------------------------------------------------
# - 文本特效类
#
#     此项同【对话框扩展】中的全部内容
#
#----------------------------------------------------------------------------
# - 扩展类
#
#     此项同【对话框扩展】中的全部内容
#
#------------------------------------------------------------------------------
# ● 标签对列表
#------------------------------------------------------------------------------
#
# 【注意】以下的标签对，若遇到允许脚本编写的，均可以做以下简写
#
#    用 s 代替 $game_switches
#    用 v 代替 $game_variables
#    用 cs 代替 已绘制的文字精灵数组（按绘制顺序排列）
#    用 win 代替 当前文本框窗口
#
#----------------------------------------------------------------------------
# - 文本替换类
#
#  <if {cond}>...</if> → 如果eval(cond)返回true，则绘制...内容，否则跳过
#
#----------------------------------------------------------------------------
# - 控制类
#
#  <page> → 分页符（大小写不限）（前后的换行符将被忽略）
#
#  <para>...</para> → 需要并行绘制的文本
#                     当主绘制进程绘制到 <para> 时，标签对中的文本将同步开始绘制，
#                     同时主进程继续绘制 </para> 后面的内容
#
#  <rb>...</rb> → 需要执行的脚本，当文字绘制到该标签对时才会执行
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
#
#==============================================================================

#==============================================================================
# ○ 【设置部分】
#==============================================================================
module MESSAGE_EX
  #--------------------------------------------------------------------------
  # ● 【设置】当该ID号开关打开时，事件指令-滚动文本 将被作为大文本框
  # 推荐给该开关命名为：滚动文本→大文本框
  #--------------------------------------------------------------------------
  S_ID_SCROLL_TEXT_TO_BOX = 18
  #--------------------------------------------------------------------------
  # ● 【设置】定义转义符各参数的预设值
  # （对于bool型变量，0与false等价，1与true等价）
  #--------------------------------------------------------------------------
  BOX_PARAMS_INIT = {
    # \font[]
    :font => {
      :size => 16, #Font.default_size, # 字体大小
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

    # \win[]
    :win => {
      # 窗口自身相关
      :opa => 0, # 窗口的不透明度
      :w => Graphics.width - 60, # 窗口打开时大小
      :h => Graphics.height - 40,
      :o => 5, # 窗口位置的显示原点类型
      :x => 0, # 窗口打开时所在位置
      :y => 0,
      :do => -5, # 相对于屏幕的显示位置原点类型（覆盖xy）
      :z => 500,
      :skin => 0, # 皮肤index
      # 文字绘制属性
      :xo => 0, # 每页的第一个文字的绘制位置
      :yo => 0,
      :cdx => 1, # 默认下一个字的横轴偏移量（负数为往左侧移动相应单位，正数为往右）
      :cdy => 0, # 默认下一个字的纵轴偏移量（负数为往上侧移动相应单位，正数为往下）
      :ck => 0, # 缩减的字符间距值（默认0）
      :ldx => 0, # 默认下一行的横轴偏移量（负数为往左，正数为往右）
      :ldy => 1, # 默认下一行的纵轴偏移量（负数为往上，正数为往下）
      :lh => 24, # 标准行高
      :lhd => 0, # 行间距
      :lx => 0, # 当文字的 x + w 大于该值时，将进行换行
      # 文字显示
      :cwi => 1, # 绘制一个字完成后的等待帧数
      :cwo => 0, # 单个文字开始移出后的等待帧数（最小值0）
      :cfast => 1, # 是否允许快进显示
    }, # :win

    # \pause[]
    :pause => {
      :id => 0,  # 源位图index
      :o => 4,  # 自身的显示原点类型
      :do => 0,  # 相对于对话框的显示位置（九宫格小键盘）（0时在文末）
      :dx => 0,  # xy偏移值
      :dy => 0,
      :t => 7, # 每两帧之间的等待帧数
      :v => 1,  # 是否显示
    }, # :pause

    # \pos[]
    :pos => {
      :x => nil, :dx => nil, # 下一个文字的x值 / 相对上一个文字的x偏移增值
      :y => nil, :dy => nil, #
      :l => nil, :dl => nil, # 下一个文字所在列号 / 相对上一个文字的列数偏移增值
      :c => nil, :dc => nil, # 下一个文字所在行号 / 相对上一个文字的行数偏移增值
    }, # :pos

    # 设置默认启用的文字特效
    #  注意：特效的默认参数与 对话框扩展 中保持一致
    :chara => { :cin => "", :cout => "" },

    # 设置额外转义符的默认启用参数
    :ex => {
      # 渐变色绘制
      :cg => "",
    },

  } # end of BOX_PARAMS_INIT
  #--------------------------------------------------------------------------
  # ●【常量】提示文本的字体大小
  #--------------------------------------------------------------------------
  HINT_FONT_SIZE = 14
  #--------------------------------------------------------------------------
  # ● 【设置】绘制提示精灵
  #--------------------------------------------------------------------------
  def self.draw_message_box_hints(s, fs = {})
    s.bitmap ||= Bitmap.new(Graphics.width, 24)
    s.bitmap.clear
    s.bitmap.font.size = HINT_FONT_SIZE

    # 绘制长横线
    s.bitmap.fill_rect(0, 0, s.width, 1,
      Color.new(255,255,255,120))

    # 绘制 取消键-上一页
    d = 20
    if fs[:f_prev]
      s.bitmap.draw_text(0+d, 2, s.width, s.height, "取消键 - 上一页", 0)
    end

    # 绘制 确定键-下一页
    if fs[:f_next]
      s.bitmap.draw_text(0, 2, s.width-d, s.height, "确定键 - 下一页", 2)
    end

    # 绘制 确定键-返回
    if fs[:f_end]
      s.bitmap.draw_text(0, 2, s.width-d, s.height, "确定键 - 结束浏览", 2)
    end

    # 绘制 方向键-移动
    if fs[:f_move]
      s.bitmap.draw_text(0, 2, s.width, s.height, "方向键 - 移动查看", 1)
    end

    # 设置摆放位置
    s.oy = s.height
    s.y = Graphics.height
  end
end

#==============================================================================
# ○ Game_Message
#==============================================================================
class Game_Message
  attr_accessor :box_params, :box_texts
  #--------------------------------------------------------------------------
  # ● 获取全部可保存params的符号的数组
  #--------------------------------------------------------------------------
  alias eagle_message_box_params eagle_params
  def eagle_params
    eagle_message_box_params + [:box]
  end
  #--------------------------------------------------------------------------
  # ● 清除
  #--------------------------------------------------------------------------
  alias eagle_message_box_clear clear
  def clear
    eagle_message_box_clear
    @box_texts = []
  end
  #--------------------------------------------------------------------------
  # ● 新增文本
  #--------------------------------------------------------------------------
  def add_box_text(t)
    @box_texts.push(t)
  end
  #--------------------------------------------------------------------------
  # ● 获取包括换行符的所有内容
  #--------------------------------------------------------------------------
  def all_box_text
    @box_texts.inject("") {|r, text| r += text + "\n" }
  end
end

#==============================================================================
# ○ Window_EagleMessage_Box
#==============================================================================
class Window_EagleMessage_Box < Window_Base
  include MESSAGE_EX::CHARA_EFFECTS
  attr_reader :eagle_chara_viewport
  #--------------------------------------------------------------------------
  # ● 参数组
  #--------------------------------------------------------------------------
  def params; $game_message.box_params; end
  #--------------------------------------------------------------------------
  # ● 获取文字颜色
  #     n : 文字颜色编号（0..31）
  #--------------------------------------------------------------------------
  def text_color(n)
    MESSAGE_EX.text_color(n, self.windowskin)
  end
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize
    super(0, 0, Graphics.width, Graphics.height)
    @eagle_chara_viewport = Viewport.new # 文字精灵的显示区域
    @eagle_chara_viewport.z = self.z + 1
    @eagle_sprite_pause = Sprite_EaglePauseTag.new(self) # 初始化等待按键的精灵
    @eagle_sprite_pause.z = self.z + 10

    @eagle_fibers = {} # 存储并行绘制的线程 id => fiber
    @eagle_fibers_params = {} # 存储待处理的并行绘制 id => text
    @eagle_last_fiber_id = 0 # 并行线程id计数
    @eagle_rbs = {} # 存储需要执行的脚本 id => string
    @eagle_rb_count = 0 # 脚本记录计数

    @page_index = 0
    @flag_change_page = false # 是否允许切换页
    @eagle_chara_sprites = {}
    @eagle_pics = {} # 存储显示的图片精灵 sym => Sprite

    init_sprite_hint
    self.arrows_visible = false
    self.openness = 0
    eagle_reset_z
  end
  #--------------------------------------------------------------------------
  # ● 初始化提示精灵
  #--------------------------------------------------------------------------
  def init_sprite_hint
    @sprite_hint = Sprite.new
    @sprite_hint.visible = false
  end
  #--------------------------------------------------------------------------
  # ● 重设z值
  #--------------------------------------------------------------------------
  def eagle_reset_z
    self.z = win_params[:z] if win_params[:z] > 0
    @eagle_chara_viewport.z = self.z + 1
    @eagle_sprite_pause.z = self.z + 2
    @sprite_hint.z = self.z + 10
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    super
    @eagle_chara_viewport.dispose
    @eagle_sprite_pause.dispose
    @eagle_chara_sprites.each { |i, ss| ss.each { |sym, s| s.move_out }}
    @eagle_chara_sprites.clear
    @eagle_pics.each { |i, ss| ss.each { |sym, s| s.bitmap.dispose; s.dispose }}
    @eagle_pics.clear
    dispose_sprite_hint
  end
  #--------------------------------------------------------------------------
  # ● 释放提示精灵
  #--------------------------------------------------------------------------
  def dispose_sprite_hint
    @sprite_hint.bitmap.dispose if @sprite_hint.bitmap
    @sprite_hint.dispose
  end

  #--------------------------------------------------------------------------
  # ● 打开窗口并等待窗口开启完成
  #--------------------------------------------------------------------------
  def open_and_wait
    eagle_change_windowskin(win_params[:skin])
    self.opacity = win_params[:opa]
    self.move(win_params[:x], win_params[:y], win_params[:w], win_params[:h])
    eagle_set_charas_viewport
    MESSAGE_EX.reset_xy_dorigin(self, nil, win_params[:do]) if win_params[:do] < 0
    MESSAGE_EX.reset_xy_origin(self, win_params[:o])
    return self.openness = 0 if self.opacity == 0
    open
    Fiber.yield until open?
  end
  #--------------------------------------------------------------------------
  # ● 关闭窗口并等待关闭完成
  #--------------------------------------------------------------------------
  def close_and_wait
    chara_sprites_move_out
    @eagle_pics.each { |i, ss| ss.each { |sym, s| s.bitmap.dispose; s.dispose }}
    @eagle_pics.clear
    close
    Fiber.yield until close?
  end
  #--------------------------------------------------------------------------
  # ● 移出全部文字
  #--------------------------------------------------------------------------
  def chara_sprites_move_out
    @eagle_chara_sprites.each do |i, cs|
      cs.each do |c|
        c.move_out2  # 调用不由文字池接管的移出方法
        c.update if !c.disposed?
        win_params[:cwo].times { Fiber.yield } if i == @page_index
      end
    end
    # 等待全部文字移出完成
    loop do 
      Fiber.yield
      flag = true
      @eagle_chara_sprites.each do |i, cs|
        break flag = false if cs.any? { |c| !c.finish? }
      end
      break if flag == true
    end
    @eagle_chara_sprites.each { |i, cs| cs.each { |c| c.dispose }; cs.clear }
    @eagle_chara_sprites.clear
  end

  #--------------------------------------------------------------------------
  # ● 更新画面
  #--------------------------------------------------------------------------
  def update
    super
    update_eagle_sprites
    update_sprite_hint
    update_eagle_fibers
    update_fiber_main
  end
  #--------------------------------------------------------------------------
  # ● 更新全部精灵
  #--------------------------------------------------------------------------
  def update_eagle_sprites
    @eagle_sprite_pause.update if @eagle_sprite_pause.visible
    @eagle_chara_sprites.each { |i, cs| cs.each { |c| c.update if !c.disposed? } }
  end
  #--------------------------------------------------------------------------
  # ● 更新提示精灵
  #--------------------------------------------------------------------------
  def update_sprite_hint
    @sprite_hint.update
  end
  #--------------------------------------------------------------------------
  # ● 更新并行线程
  #--------------------------------------------------------------------------
  def update_eagle_fibers
    @eagle_fibers.each { |id, fiber| fiber.resume }
  end
  #--------------------------------------------------------------------------
  # ● 更新主线程
  #--------------------------------------------------------------------------
  def update_fiber_main
    return @fiber.resume if @fiber
    if $game_message.box_texts.size > 0
      @fiber = Fiber.new { fiber_main }
      @fiber.resume
    end
  end
  #--------------------------------------------------------------------------
  # ● 主绘制的逻辑
  #--------------------------------------------------------------------------
  def fiber_main
    open_and_wait
    texts = pre_process_all_text($game_message.all_box_text)
    @page_index = 0
    @page_num = texts.size # 总页数

    loop do
      @flags_hints = {}  # 存储当前页的提示精灵状态
      if !@eagle_chara_sprites.has_key?(@page_index)
        pos = pre_process_params
        process_all_text(texts[@page_index], pos)
        Fiber.yield until !eagle_any_fiber?
      end
      if @page_index > 0 # 存在前一页
        @flags_hints[:f_prev] = true
      end
      if @page_index == texts.size - 1 # 当前为最后一页
        @flags_hints[:f_end] = true
      else
        @flags_hints[:f_next] = true
      end
      @flag_change_page = true # 允许切换页
      input_pause
      @flag_change_page = false
      break if @page_index >= texts.size # 结束
    end

    close_and_wait
    $game_message.clear
    $game_switches[MESSAGE_EX::S_ID_SCROLL_TEXT_TO_BOX] = false
    @fiber = nil
  end
  #--------------------------------------------------------------------------
  # ● 获取全部绘制文本
  #--------------------------------------------------------------------------
  def pre_process_all_text(text)
    text = convert_escape_characters(text)
    text = pre_process_tags(text)
    t = MESSAGE_EX::BOX_PARAMS_INIT.keys.inject("") { |s, k| s + "\e#{k}" }
    text = t + text
    texts = text.split(/<page>/im) # 数组每项代表一页的文本
    texts.each do |t|  # 删去前后的换行
      t.chomp!
      t.sub!(/^\n/) { "" }
    end
    texts.delete_if { |t| t.empty? }  # 删去空页
    return texts
  end
  #--------------------------------------------------------------------------
  # ● 预处理标签对
  #--------------------------------------------------------------------------
  def pre_process_tags(text)
    # 条件判断标签对
    text.gsub!(/<if ?{(.*?)}>(.*?)<\/if>/m) { eagle_eval($1) == true ? $2 : "" }
    # 图片标签对
    text.gsub!(/<pic (.*?)>(.*?)<\/pic>/m) {
      sym = $1
      self.pics[$1] = $2
      "\epic2[#{sym}]"
    }
    # 脚本标签对
    text.gsub!(/<rb>(.*?)<\/rb>/m) {
      @eagle_rb_count += 1
      @eagle_rbs[@eagle_rb_count] = $1
      "\erbl[#{@eagle_rb_count}]"
    }
    # 如果发现并行绘制标签对，则创建线程，并替换成转义符来启动并行绘制
    text.gsub!(/<para>(.*?)<\/para>/m) {
      @eagle_last_fiber_id += 1
      @eagle_fibers_params[@eagle_last_fiber_id] = $1
      "\epara[#{@eagle_last_fiber_id}]"
    }
    text
  end
  #--------------------------------------------------------------------------
  # ● 获取初始绘制参数
  #--------------------------------------------------------------------------
  def pre_process_params
    # 重置绘制
    @eagle_charas_w = @eagle_charas_h = 0
    reset_font_settings
    clear_flags
    # 重置文字、图片
    self.charas = []
    self.pics = {}

    # 获取初始绘制参数
    pos = { :x_line => win_params[:xo], :y_line => win_params[:yo] }
    pos[:x] = pos[:x_line]; pos[:y] = pos[:y_line]
    return pos
  end
  #--------------------------------------------------------------------------
  # ● 重置字体设置
  #--------------------------------------------------------------------------
  def reset_font_settings
    change_color(text_color(font_params[:c]))
    self.contents.font.color.alpha = font_params[:ca]
  end

  #--------------------------------------------------------------------------
  # ● 处理指定内容的绘制
  #--------------------------------------------------------------------------
  def process_all_text(text, pos)
    return if text.nil?
    process_character(text.slice!(0, 1), text, pos) until text.empty?
  end
  #--------------------------------------------------------------------------
  # ● 获取当前页的全部文字精灵、图片精灵的数组
  #--------------------------------------------------------------------------
  def charas; @eagle_chara_sprites[@page_index]; end
  def charas=(v); @eagle_chara_sprites[@page_index] = v; end
  def pics; @eagle_pics[@page_index]; end
  def pics=(v); @eagle_pics[@page_index] = v; end
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
  # ● 更新正在移入移出文字的显示区域的显示原点
  #--------------------------------------------------------------------------
  def update_moving_charas_oxy
    self.charas.each { |c|
      c.reset_window_oxy(self.ox, self.oy) if c.move_updating?
    }
  end
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
  # ● 设置文字显示区域的矩形（屏幕坐标）
  #--------------------------------------------------------------------------
  def eagle_set_charas_viewport
    @eagle_chara_viewport.rect.set(eagle_charas_x0, eagle_charas_y0,
      eagle_charas_max_w, eagle_charas_max_h)
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
    eagle_process_draw_start(c_w, c_h, pos)
    s = eagle_new_chara_sprite(pos[:x], pos[:y], c_w, c_h)
    s.eagle_font.draw(s.bitmap, 0, 0, c_w, c_h, c, 0)
    eagle_process_draw_end(c_w, c_h, pos)
  end
  #--------------------------------------------------------------------------
  # ● 处理控制符指定的图标绘制（覆盖）
  #--------------------------------------------------------------------------
  def process_draw_icon(icon_index, pos)
    eagle_reset_draw_pos(pos)
    eagle_process_draw_start(24, 24, pos)
    s = eagle_new_chara_sprite(pos[:x], pos[:y], 24, 24)
    s.eagle_font.draw_icon(s.bitmap, 0, 0, icon_index)
    eagle_process_draw_end(24, 24, pos)
  end
  #--------------------------------------------------------------------------
  # ● 处理控制符指定的图片绘制
  #--------------------------------------------------------------------------
  def process_draw_pic(text, pos)
    param = text.slice!(/^\[.*?\]/)[1..-2]
    params = param.split('|') # [filename, param_str]
    _bitmap = Cache.picture(MESSAGE_EX.get_pic_file(params[0])) rescue return
    h = {}
    parse_param(h, params[1], :opa) if params[1]
    h[:w] ||= _bitmap.width
    h[:h] ||= _bitmap.height
    h[:opa] ||= 255

    eagle_process_draw_start(h[:w], h[:h], pos)
    if @flag_draw
      s = eagle_new_chara_sprite(pos[:x], pos[:y], h[:w], h[:h])
      s.eagle_font.draw_pic(s.bitmap, _bitmap, h)
    end
    eagle_process_draw_end(h[:w], h[:h], pos)
  end
  #--------------------------------------------------------------------------
  # ● （封装）生成一个新的文字精灵
  #--------------------------------------------------------------------------
  def eagle_new_chara_sprite(c_x, c_y, c_w, c_h)
    f = Font_EagleCharacter.new(font_params)
    f.set_param(:skin, win_params[:skin])
    f.set_param(:cg, ex_params[:cg])

    s = Sprite_EagleCharacter_MessageBox.new(self, f, c_x, c_y, c_w, c_h,
      @eagle_chara_viewport)
    s.start_effects(params[:chara])
    s.update
    self.charas.push(s)
    s
  end
  #--------------------------------------------------------------------------
  # ● 绘制开始前的处理
  #--------------------------------------------------------------------------
  def eagle_process_draw_start(c_w, c_h, pos)
    if win_params[:lx] > 0  # 处理自动换行
      process_new_line("", pos) if pos[:x] + c_w > win_params[:lx]
    end
  end
  #--------------------------------------------------------------------------
  # ● 绘制完成时的处理
  #--------------------------------------------------------------------------
  def eagle_process_draw_end(c_w, c_h, pos)
    # 存储行首文字
    pos[:first_chara_s] = self.charas[-1] if pos[:first_chara_s].nil?
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
    ensure_character_visible(self.charas[-1], true)
  end
  #--------------------------------------------------------------------------
  # ● 确保最后绘制完成的文字在视图内
  #--------------------------------------------------------------------------
  def ensure_character_visible(c, no_anim = false)
    return if c.nil?
    ox_1 = self.ox
    ox_d = 0
    ox_d = c._x - self.ox if c._x < self.ox
    d = c._x + c.width - @eagle_chara_viewport.rect.width - self.ox
    ox_d = d if d > 0

    oy_1 = self.oy
    oy_d = 0
    oy_d = c._y - self.oy if c._y < self.oy
    d = c._y + c.height - @eagle_chara_viewport.rect.height - self.oy
    oy_d = d if d > 0

    if !no_anim && (ox_d != 0 || oy_d != 0)
      # 因为是在新行的首字符绘制完成后调用该方法，因此先把这个字符隐藏了
      c.visible = false
      t = MESSAGE_EX::CHARAS_SCROLL_OUT_FRAME
      (t+1).times do |i|
        per = i * 1.0 / t
        per = MESSAGE_EX.ease_value(:msg_xywh, per)
        self.ox = ox_1 + ox_d * per if ox_d != 0
        self.oy = oy_1 + oy_d * per if oy_d != 0
        update_moving_charas_oxy
        Fiber.yield
      end
      c.visible = true
    end
    self.ox = ox_1 + ox_d
    self.oy = oy_1 + oy_d
    update_moving_charas_oxy # 保证文字跟着contents一起移动
  end
  #--------------------------------------------------------------------------
  # ● 换行文字的处理
  #--------------------------------------------------------------------------
  def process_new_line(text, pos)
    @line_show_fast = false
    if pos[:first_chara_s] # 如果存储了上一行的行首文字，则以它为基准
      x_ = pos[:first_chara_s]._x
      y_ = pos[:first_chara_s]._y
    else # 否则，以初始定下的行首位置为基准
      x_ = pos[:x_line]
      y_ = pos[:y_line]
    end
    pos[:x] = x_ + eagle_standard_cw * win_params[:ldx]
    pos[:y] = y_ + eagle_standard_ch * win_params[:ldy]
    pos[:x_line] = pos[:x]
    pos[:y_line] = pos[:y]
    pos[:first_chara_s] = nil
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
    @line_show_fast = true if Input.trigger?(:C)
  end

  #--------------------------------------------------------------------------
  # ● 处理输入等待
  #--------------------------------------------------------------------------
  def input_pause
    eagle_process_draw_update
    @eagle_sprite_pause.bind_last_chara(self.charas[-1])
    @eagle_sprite_pause.show
    process_input_pause
    @eagle_sprite_pause.hide
  end
  #--------------------------------------------------------------------------
  # ● 执行输入等待
  #--------------------------------------------------------------------------
  def process_input_pause
    recreate_contents_for_charas
    fm = $imported["EAGLE-MouseEX"] != nil
    ox_des = [self.ox, @eagle_charas_w - @eagle_chara_viewport.rect.width].max
    oy_des = self.oy
    if ox_des != 0 || oy_des != 0 # 允许移动
      self.arrows_visible = true
      @flags_hints[:f_move] = true
    end
    show_sprite_hint
    d_oxy = 1; last_input = nil; last_input_c = 0
    while true
      Fiber.yield
      break if check_input_pause?
      mouse_pos = MOUSE_EX.pos_num(nil, 40, 40) if fm 
      cur_input = 0
      if @flags_hints[:f_move]
        _ox = self.ox; _oy = self.oy
        # 处理文本滚动
        if Input.press?(:UP) || (fm && mouse_pos == 8)
          cur_input = 8
          self.oy -= d_oxy
          self.oy = 0 if self.oy < 0
        elsif Input.press?(:DOWN) || (fm && mouse_pos == 2)
          cur_input = 2
          self.oy += d_oxy
          self.oy = oy_des if self.oy > oy_des
        elsif Input.press?(:LEFT) || (fm && mouse_pos == 4)
          cur_input = 4
          self.ox -= d_oxy
          self.ox = 0 if self.ox < 0
        elsif Input.press?(:RIGHT) || (fm && mouse_pos == 6)
          cur_input = 6
          self.ox += d_oxy
          self.ox = ox_des if self.ox > ox_des
        end
        if last_input == cur_input
          last_input_c += 1
          d_oxy += 1 if last_input_c % 10 == 0
        else
          d_oxy = 1
          last_input_c = 0
        end
        last_input = cur_input
        update_moving_charas_oxy if _ox != self.ox || _oy != self.oy
      end
    end
    self.arrows_visible = false
    Input.update
    hide_sprite_hint
  end
  #--------------------------------------------------------------------------
  # ● 检查输入等待的按键
  #--------------------------------------------------------------------------
  def check_input_pause?
    if @flag_change_page
      if input_pause_key_ok?
        next_page
        return true
      end
      if @flags_hints[:f_prev] && input_pause_key_cancel?
        prev_page
        return true
      end
    else
      return true if input_pause_key_ok? || input_pause_key_cancel?
    end
    return false
  end
  def input_pause_key_ok?
    return true if $imported["EAGLE-MouseEX"] && MOUSE_EX.up?(:ML)
    Input.trigger?(:C)
  end
  def input_pause_key_cancel?
    return true if $imported["EAGLE-MouseEX"] && MOUSE_EX.up?(:MR)
    Input.trigger?(:B)
  end
  #--------------------------------------------------------------------------
  # ● 执行切页
  #--------------------------------------------------------------------------
  def next_page
    page_move_out
    @page_index += 1
    page_move_in if @eagle_chara_sprites.has_key?(@page_index)
  end
  def prev_page
    page_move_out
    @page_index -= 1
    page_move_in
  end
  #--------------------------------------------------------------------------
  # ● 整页移入移出
  #--------------------------------------------------------------------------
  def page_move_in
    self.charas.each { |c| c.move_in }
  end
  def page_move_out
    self.charas.each { |c| c.move_out_temp }
  end
  #--------------------------------------------------------------------------
  # ● 显示提示精灵
  #--------------------------------------------------------------------------
  def show_sprite_hint
    MESSAGE_EX.draw_message_box_hints(@sprite_hint, @flags_hints)
    @sprite_hint.visible = true
  end
  #--------------------------------------------------------------------------
  # ● 隐藏提示精灵
  #--------------------------------------------------------------------------
  def hide_sprite_hint
    @sprite_hint.visible = false
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
    when "PIC"; process_draw_pic(text, pos)
    when 'PARA'; eagle_activate_fiber(obtain_escape_param(text), pos)
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
        params[:chara][temp_code.to_sym] = param
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
    params[:chara].delete(code_sym)
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
  # ● 还存在并行绘制？
  #--------------------------------------------------------------------------
  def eagle_any_fiber?
    !@eagle_fibers.empty?
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
    eagle_set_charas_viewport
    eagle_change_windowskin(win_params[:skin])
    eagle_reset_z
  end
  #--------------------------------------------------------------------------
  # ● 变更窗口皮肤
  #--------------------------------------------------------------------------
  def eagle_change_windowskin(index)
    return if @last_windowskin_index == index
    @last_windowskin_index = index
    self.windowskin = MESSAGE_EX.windowskin(index)
    change_color(text_color(font_params[:c]))
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
    parse_param(pause_params, param, :id)
    @eagle_sprite_pause.reset
  end
  #--------------------------------------------------------------------------
  # ● 设置wait参数
  #--------------------------------------------------------------------------
  def eagle_text_control_wait(param = '0')
    wait(param.to_i)
  end
  #--------------------------------------------------------------------------
  # ● 等待
  #--------------------------------------------------------------------------
  def wait(duration)
    duration.times { Fiber.yield }
  end
  #--------------------------------------------------------------------------
  # ● 设置pic2参数
  #--------------------------------------------------------------------------
  def eagle_text_control_pic2(param = '0')
    sym = param
    return if self.pics[sym].nil?
    params = self.pics[sym].split('|') # 精灵参数字符串|图片名称|位图参数字符串

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
    self.pics[sym] = s
  end
  #--------------------------------------------------------------------------
  # ● 应用rbl脚本
  #--------------------------------------------------------------------------
  def eagle_text_control_rbl(param = '0')
    eagle_eval(@eagle_rbs[param.to_i])
    @eagle_rbs.delete(param.to_i)
  end
  #--------------------------------------------------------------------------
  # ● eval
  #--------------------------------------------------------------------------
  def eagle_eval(t)
    cs = self.charas
    pics = self.pics
    win = self
    s = $game_switches; v = $game_variables
    eval(t)
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
class Sprite_EagleCharacter_MessageBox < Sprite_EagleCharacter
  #--------------------------------------------------------------------------
  # ● 初始化特效的默认参数
  #--------------------------------------------------------------------------
  def init_effect_params(sym)
    MESSAGE_EX.get_default_params(sym)
  end
  #--------------------------------------------------------------------------
  # ● 执行移出（外部调用的方法）
  #--------------------------------------------------------------------------
  def move_out2
    finish_effects # 先结束全部特效
    finish if !in_viewport? # 若精灵在视图外，则会直接结束
    if !finish?
      process_move_out  # 处理移出模式
    end
    free_from_msg  # 不再受限于对话框内，但位置保持不变
    #MESSAGE_EX.charapool_push(self) # 不由文字池接管
  end
end

#===============================================================================
# ○ 征用滚动文本
#===============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 显示滚动文字
  #--------------------------------------------------------------------------
  alias eagle_message_box_command_105 command_105
  def command_105
    return call_message_box if $game_switches[MESSAGE_EX::S_ID_SCROLL_TEXT_TO_BOX]
    eagle_message_box_command_105
  end
  #--------------------------------------------------------------------------
  # ● 写入大文本框
  #--------------------------------------------------------------------------
  def call_message_box
    Fiber.yield while $game_message.visible
    # $game_message.scroll_speed = @params[0]
    # $game_message.scroll_no_fast = @params[1]
    number_box = @params[0]
    flag_box = @params[1]
    while next_event_code == 405
      @index += 1
      $game_message.add_box_text(@list[@index].parameters[0])
    end
    Fiber.yield while $game_switches[MESSAGE_EX::S_ID_SCROLL_TEXT_TO_BOX]
  end
end

#===============================================================================
# ○ Scene_Map
#===============================================================================
class Scene_Map < Scene_Base
  #--------------------------------------------------------------------------
  # ● 生成滚动文字窗口
  #--------------------------------------------------------------------------
  alias eagle_message_box_scroll_window create_scroll_text_window
  def create_scroll_text_window
    eagle_message_box_scroll_window
    @eagle_message_box_window = Window_EagleMessage_Box.new
  end
end
#===============================================================================
# ○ Scene_Battle
#===============================================================================
class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # ● 生成滚动文字窗口
  #--------------------------------------------------------------------------
  alias eagle_message_box_scroll_window create_scroll_text_window
  def create_scroll_text_window
    eagle_message_box_scroll_window
    @eagle_message_box_window = Window_EagleMessage_Box.new
  end
end
