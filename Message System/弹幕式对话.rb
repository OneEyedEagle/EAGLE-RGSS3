#==============================================================================
# ■ 弹幕式对话 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【组件-通用方法汇总 by老鹰】与
#   【组件-位图绘制转义符文本 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-MessageDanmaku"] = true
#==============================================================================
# - 2022.2.12.14
#==============================================================================
# - 本插件新增了在屏幕上显示滚动弹幕的文本系统
#---------------------------------------------------------------------------
# 【UI介绍】
#
# - 在屏幕上，显示像B站那样的弹幕文字
#   本系统全局更新，开启菜单等操作均不会暂停更新
#
#---------------------------------------------------------------------------
# 【添加弹幕：征用滚动文本】
#
# - 当 S_ID_SCROLL_TEXT 号开关开启时，
#   事件的【显示滚动文本】将被替换为本脚本的【新增弹幕】
#
# - 具体编写格式如下：
#
#   每一行的文本都会被识别为一条弹幕
#   每一行开头编写 [参数的标签组合] 可以为该条弹幕设置参数
#
#   其中 参数的标签组合 可以为以下语句的任意组合，用空格分隔
#         等号左右可以添加冗余空格
#
#      y=数字 → 设置弹幕在屏幕上的y位置
#                 （若不填写，则会显示在随机y位置）
#
#      yf=数字 → 设置弹幕在屏幕上的y位置（屏幕比例）
#                   数字 为 0~1 之间的浮点数，为屏幕中的显示比例
#                 （将覆盖 y=数字 的设置）
#
#      dir=类型 → 设置弹幕的移动类型
#                   类型 替换为 lr 则为从屏幕左边移动到右边
#                        替换为 rl 则为从屏幕右边移动到左边【默认】
#                        替换为 c 则为显示在屏幕中央
#
#      v=数字 → 当 dir=lr 或 rl 时，弹幕在每帧里移动的像素值（最小值为1）
#
#      t=数字 → 当 dir=c 时，弹幕的停留时间帧数
#
#      w=数字 → 在弹幕显示前，等待的时间帧数
#
#      n=数字 → 弹幕的重复显示次数（默认1）（最小值为1）
#                （用于同一时间出现多条相同内容的弹幕）
#
#      bg=数字 → 设置背景的类型
#                  数字 替换为 0 则为透明背景【默认】
#                       替换为 1 则为暗色背景
#
#      font=数字 → 弹幕文字的大小
#
#      z=数字 → 弹幕精灵的z值
#
#      opa=数字 → 弹幕的不透明度（默认255）
#
# - 特别的，可以使用 {{eval}} 来进行一次脚本结果的替换
#     其中可用 s 代表开关组，即 s[1] 代表1号开关的状态
#         可用 v 代表变量组，即 v[2] 获取2号变量的值
#         可用 es 代表当前地图的事件组，即 es[1] 获取1号事件的Game_Event对象
#
#   比如：[v={{rand(5)}}]测试弹幕 → 生成一个速度为 1~4 的“测试弹幕”弹幕
#   比如：测试弹幕x{{v[5]}} → （5号变量值为10）生成一个“测试弹幕x10”弹幕
#
# - 示例1：
#     事件指令【显示滚动文本】中，填入 =begin 和 =end 之间的内容
=begin
[dir=lr v=3 yf=0.2]测试用文本
[dir=c n=5]这也是测试
=end
#     在0.2的屏幕高度处的显示一条弹幕“测试用文本”，并且从左往右每帧移动3像素，
#     在屏幕中间的随机y位置显示一条弹幕“这也是测试”，并且显示预设的帧数
#
# - 示例2：
=begin
[dir=rl v=2 n={{rand(5)}}]\c[{{rand(18)}}]前方高能！
=end
#     在屏幕随机高度处显示1~4条弹幕“前方高能！”，从右往左移动
#
#---------------------------------------------------------------------------
# 【添加弹幕：全局脚本】
#
# - 利用脚本新增弹幕（可以在任意位置调用）
#
#     $game_message.add_danmaku(data)
#
#   其中 data 为上述参数的Hash，和上述一致，但键值为符号类型，值为数字或字符串
#          如： { :text => "测试用文本", :dir => :lr, :v => 2 }
#
# - 示例1：
#     $game_message.add_danmaku({:text=>"测试用文本",:dir=>:lr,:v=>3,:yf=>0.3})
#     $game_message.add_danmaku({:text=>"这也是测试", :dir=>:c, :n=>5})
#
# - 示例2：
#     c = rand(18)
#     data = { :text => "\\c[#{c}]前方高能！", :n => rand(5)+1, :v => 2 }
#     $game_message.add_danmaku(data)
#
#---------------------------------------------------------------------------
# 【设置弹幕：全局脚本】
#
# - 利用脚本对弹幕进行整体设置
#
#     $game_message.set_danmaku(sym, v)
#
#   当前可用的设置参数有：
#
#     :opa → 设置全部弹幕的不透明度（优先级低于弹幕自己的opa=数字）
#
# - 示例1：
#     $game_message.set_danmaku(:opa, 150)
#
#==============================================================================
module MESSAGE_DANMAKU
  #--------------------------------------------------------------------------
  # ● 【常量】当该开关开启时，【显示滚动文本】将被替换为新增弹幕
  # 推荐给该开关命名为：滚动文本→弹幕
  #--------------------------------------------------------------------------
  S_ID_SCROLL_TEXT = 26
  #--------------------------------------------------------------------------
  # ● 【常量】弹幕文本的字体名称
  #--------------------------------------------------------------------------
  TEXT_NAME = "黑体" # Font.default_name

  #--------------------------------------------------------------------------
  # ● 处理参数
  #--------------------------------------------------------------------------
  def self.process_data(data)
    #data[:text]
    # 预设参数
    #data[:y] # 位置，未传入则取随机数
    #data[:yf] # 浮点数位置（覆盖data[:y]）
    data[:dir] ||= :rl # 从右往左
    data[:v] ||= 1 # 移动速度
    data[:t] ||= 180 # 当dir为c时，显示的等待时间
    data[:n] ||= 1 # 重复次数
    data[:w] ||= 0 # 显示前的等待帧数
    data[:bg] ||= 0 # 背景的类型
    data[:font] ||= 20 # 弹幕文字大小
    data[:z] ||= 200
    #data[:opa]
    # 参数格式
    data[:y] = data[:y].to_i if data[:y]
    data[:yf] = data[:yf].to_f if data[:yf]
    data[:dir] = data[:dir].to_sym
    data[:v] = data[:v].to_i
    data[:v] = 1 if data[:v] <= 0
    data[:t] = data[:t].to_i
    data[:n] = data[:n].to_i
    data[:n] = 1 if data[:n] <= 0
    data[:w] = data[:w].to_i
    data[:bg] = data[:bg].to_i
    data[:font] = data[:font].to_i
    data[:z] = data[:z].to_i
    data[:opa] = data[:opa].to_i if data[:opa]
  end
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  @sprites = []
  def self.init
    @sprites = []
  end
  #--------------------------------------------------------------------------
  # ● 更新（在Scene_Base中）
  #--------------------------------------------------------------------------
  def self.update
    @sprites.each { |s| s.update }
    update_new
    update_dispose
  end
  #--------------------------------------------------------------------------
  # ● 新增一个弹幕
  #--------------------------------------------------------------------------
  def self.update_new
    return if $game_message.eagle_danmaku.size == 0
    data = $game_message.eagle_danmaku.shift
    data[:n].times do
      s = get_sprite
      s.bind(data)
    end
    @count_dispose = 0
  end
  #--------------------------------------------------------------------------
  # ● 获取一个可用的精灵
  #--------------------------------------------------------------------------
  def self.get_sprite
    @sprites.each { |s| return s if s.finish? }
    s = Sprite_Danmaku.new(nil)
    @sprites.push(s)
    return s
  end
  #--------------------------------------------------------------------------
  # ● 更新释放
  #--------------------------------------------------------------------------
  @count_dispose = 0  # 释放倒计时
  TIME_DISPOSE = 600  # 在该帧数内未生成新弹幕时，释放一次冗余精灵
  def self.update_dispose
    @count_dispose += 1
    return if @count_dispose < TIME_DISPOSE
    @sprites.delete_if { |s| f = s.finish?; s.dispose if f; f }
  end
end
#===============================================================================
# ○ DataManager
#===============================================================================
class << DataManager
  alias eagle_danmaku_init init
  def init
    eagle_danmaku_init
    MESSAGE_DANMAKU.init
  end
end
#===============================================================================
# ○ Scene_Base
#===============================================================================
class Scene_Base
  #--------------------------------------------------------------------------
  # ● 基础更新
  #--------------------------------------------------------------------------
  alias eagle_danmaku_update_basic update_basic
  def update_basic
    eagle_danmaku_update_basic
    MESSAGE_DANMAKU.update
  end
end
#===============================================================================
# ○ Game_Message
#===============================================================================
class Game_Message
  attr_accessor  :eagle_danmaku, :danmaku_params
  #--------------------------------------------------------------------------
  # ● 清除
  #--------------------------------------------------------------------------
  alias eagle_message_danmaku_clear clear
  def clear
    eagle_message_danmaku_clear
    clear_danmaku
  end
  #--------------------------------------------------------------------------
  # ● 重置
  #--------------------------------------------------------------------------
  def clear_danmaku
    @eagle_danmaku = []
    @danmaku_params ||= {}
  end
  #--------------------------------------------------------------------------
  # ● 新增弹幕
  #--------------------------------------------------------------------------
  def add_danmaku(data)
    return if data[:text] == nil || data[:text] == ""
    MESSAGE_DANMAKU.process_data(data)
    @eagle_danmaku.push(data)
  end
  #--------------------------------------------------------------------------
  # ● 设置弹幕（整体参数）
  #--------------------------------------------------------------------------
  def set_danmaku(sym, v)
    @danmaku_params[sym] = v
  end
end
#===============================================================================
# ○ Sprite_Danmaku
#===============================================================================
class Sprite_Danmaku < Sprite
  include MESSAGE_DANMAKU
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(viewport)
    super(viewport)
    @data = nil
    @fiber = nil
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    self.bitmap.dispose if self.bitmap
    super
  end
  #--------------------------------------------------------------------------
  # ● 完成？
  #--------------------------------------------------------------------------
  def finish?
    @fiber == nil
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    #super
    @fiber.resume if @fiber
  end
  #--------------------------------------------------------------------------
  # ● 开始
  #--------------------------------------------------------------------------
  def bind(data)
    @data = data
    @fiber = Fiber.new { fiber_main }
  end
  #--------------------------------------------------------------------------
  # ● 更新fiber
  #--------------------------------------------------------------------------
  def fiber_main
    @data[:w].times { Fiber.yield }
    redraw
    reset_position
    while true
      case @data[:dir]
      when :rl
        self.x -= @data[:v]
        break if self.x < 0
      when :lr
        self.x += @data[:v]
        break if self.x > Graphics.width
      when :c
        @data[:c_t] += 1
        break if @data[:c_t] > @data[:t]
      end
      Fiber.yield
    end
    self.bitmap.dispose
    @fiber = nil
  end
  #--------------------------------------------------------------------------
  # ● 重绘
  #--------------------------------------------------------------------------
  def redraw
    t = @data[:text]
    ps = { :font_size=>@data[:font], :x0=>4, :y0=>4, :lhd=>4 }
    b = Bitmap.new(32, 32)
    b.font.name = TEXT_NAME
    b.font.size = @data[:font]
    d = Process_DrawTextEX.new(t, ps, b)
    d.run(false)
    # 生成位图
    self.bitmap = Bitmap.new(d.width+8, d.height+4)
    self.bitmap.font.name = TEXT_NAME
    # 绘制背景
    if @data[:bg] == 1
      bitmap.fill_rect(0, 0, bitmap.width, bitmap.height, Color.new(0,0,0,150))
    end
    d.bind_bitmap(self.bitmap, true)
    d.run(true)
  end
  #--------------------------------------------------------------------------
  # ● 重置初始位置
  #--------------------------------------------------------------------------
  def reset_position
    case @data[:dir]
    when :rl
      self.ox = self.width
      self.oy = self.height / 2
      self.x = Graphics.width + self.ox
    when :lr
      self.ox = 0
      self.oy = self.height / 2
      self.x = 0 - self.width
    when :c
      self.ox = self.width / 2
      self.oy = self.height / 2
      self.x = Graphics.width / 2
      @data[:c_t] = 0
    end
    self.y = @data[:y] || rand(Graphics.height)
    self.y = @data[:yf] * Graphics.height if @data[:yf]
    self.z = @data[:z]
    if $game_message.danmaku_params[:opa]
      self.opacity = $game_message.danmaku_params[:opa].to_i
    end
    self.opactiy = @data[:opa] if @data[:opa]
  end
end

#===============================================================================
# ○ 征用滚动文本
#===============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 显示滚动文字
  #--------------------------------------------------------------------------
  alias eagle_message_danmaku_command_105 command_105
  def command_105
    return call_danmaku if $game_switches[MESSAGE_DANMAKU::S_ID_SCROLL_TEXT]
    eagle_message_danmaku_command_105
  end
  #--------------------------------------------------------------------------
  # ● 写入弹幕
  #--------------------------------------------------------------------------
  def call_danmaku
    ensure_fin = @list[@index].parameters[1]
    # 每一行为弹幕文本，开头【】内写参数
    while next_event_code == 405
      @index += 1
      t = @list[@index].parameters[0].dup
      t_tag = ""
      t.gsub!(/\{\{(.*?)\}\}/) { EAGLE_COMMON.eagle_eval($1) }
      t.gsub!(/^\[(.*?)\]/) { t_tag = $1; "" }
      data = EAGLE_COMMON.parse_tags(t_tag)
      data[:text] = t
      $game_message.add_danmaku(data)
    end
    Fiber.yield
  end
end
