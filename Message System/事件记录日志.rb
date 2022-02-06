#==============================================================================
# ■ 事件记录日志 by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【组件-位图绘制转义符文本 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-EventLog"] = true
#==============================================================================
# - 2022.2.1.23 允许设置初始颜色
#==============================================================================
# - 本插件新增了通过脚本写入的事件日志
#------------------------------------------------------------------------------
# 【使用】
#
#    在地图上时，按下 W 键即可开启对话日志界面（注意此时地图将被暂停）
#
#    在日志界面，再次按下 W 键即可关闭，并继续之前的地图事件
#
#----------------------------------------------------------------------------
# 【新增日志】
#
#    在脚本（含事件脚本）中，利用该语句写入一段日志
#
#       EVENT_LOG.add(text, name, params)
#
#    其中 text 为可含有转义符的字符串，其中转义符的 \ 需要写成 \\，但是换行依然为 \n
#    其中 name 为显示在左侧的名称，其中转义符的 \ 需要写成 \\，可省略
#    其中 params 为可能的扩展设置的Hash，可省略
#
#----------------------------------------------------------------------------
# 【示例】
#    事件脚本中编写：
#  （请注意，由于框的宽度限制而造成的字符串换行，同样会被识别为换行！）
#  （=begin和=end之间的内容，可以直接复制粘贴到事件脚本框中）
=begin
n = "星历1年4月5日"
t = "全城庆典开幕\n"
t += "萨克逊城主与菲利克斯副城主便装出行，"
t += "与城中居民一同欢庆"
EVENT_LOG.add(t, n)
=end
#
=begin
n = "星历1年5月5日"
t = "全城庆典顺利落幕\n"
t += "萨克逊城主发表感谢致辞，"
t += "并称将与各位居民共同发掘奇迹之城的新潜力"
EVENT_LOG.add(t, n)
=end
#
#----------------------------------------------------------------------------
# 【滚动文本】
#
#    当 S_ID 对应的开关开启时，将覆盖默认的滚动文本框指令
#      即滚动文本框的内容会被存入 事件日志
#      同时我们约定，第一行文本必定为 名称name。
#
#    在滚动文本框中，正常编写转义符即可。
#
#----------------------------------------------------------------------------
# 【注意】
#
#    日志将被存储到存档文件中，因此请不要将 LOG_MAX_NUM 设置过大
#
#----------------------------------------------------------------------------
# 【扩展】
#
#   ·若想在地图以外的场景中调用，可在对应场景的update中增加 EVENT_LOG.call_scene?
#
#==============================================================================
module EVENT_LOG
  #--------------------------------------------------------------------------
  # ● 呼叫日志？
  #--------------------------------------------------------------------------
  def self.call_scene?
    # 如果使用了【快捷功能界面 by老鹰】，则不要占用按键
    return if $imported["EAGLE-EventToolbar"]
    call if Input.trigger?(:R)
  end
  #--------------------------------------------------------------------------
  # ● 关闭日志？
  #--------------------------------------------------------------------------
  def self.close_scene?
    Input.trigger?(:R) || Input.trigger?(:B)
  end

  #--------------------------------------------------------------------------
  # ○【常量】当该序号的开关开启时，事件指令-显示滚动文字将被替换为存入事件日志记录
  #--------------------------------------------------------------------------
  S_ID = 20

  #--------------------------------------------------------------------------
  # ○【常量】最大存储的日志条数
  #  nil 时为不设置上限
  #--------------------------------------------------------------------------
  LOG_MAX_NUM = nil
  #--------------------------------------------------------------------------
  # ○【常量】每次读取的日志条数
  #--------------------------------------------------------------------------
  LOG_READ_NUM = 10
  #--------------------------------------------------------------------------
  # ○【常量】日志绘制后的等待帧数（防止连续绘制多个造成卡顿）
  #--------------------------------------------------------------------------
  WAIT_COUNT = 2
  #--------------------------------------------------------------------------
  # ○【常量】左侧留空宽度
  #--------------------------------------------------------------------------
  OFFSET_X = 10
  #--------------------------------------------------------------------------
  # ○【常量】OFFSET_X偏移后，中心线的X位置
  #--------------------------------------------------------------------------
  LINE_X = 130
  #--------------------------------------------------------------------------
  # ○【常量】相邻文本块的y方向间距
  #--------------------------------------------------------------------------
  OFFSET_BETWEEN = 12

  #--------------------------------------------------------------------------
  # ○【常量】提示文本的字体大小
  #--------------------------------------------------------------------------
  HINT_FONT_SIZE = 14
  #--------------------------------------------------------------------------
  # ○【常量】日志文本的字体大小
  #--------------------------------------------------------------------------
  LOG_FONT_SIZE = 16
  #--------------------------------------------------------------------------
  # ○【常量】日志文本的字体颜色
  #--------------------------------------------------------------------------
  LOG_FONT_COLOR = Color.new(255,255,255,255)

  #--------------------------------------------------------------------------
  # ○【常量】显示于底部的最新的对话日志，所能到达的最顶端的y值
  #--------------------------------------------------------------------------
  UP_LIMIT_Y = 4
  #--------------------------------------------------------------------------
  # ○【常量】显示于顶部的最旧的对话日志，所能到达的最底端的y值
  #--------------------------------------------------------------------------
  DOWN_LIMIT_Y = Graphics.height / 2 - 24

  #--------------------------------------------------------------------------
  # ● 新增日志
  #--------------------------------------------------------------------------
  def self.add(text, name = "", params = {})
    params[:name] = name
    d = Data.new(text, params)
    logs.unshift(d)
    logs.pop if LOG_MAX_NUM && logs.size > LOG_MAX_NUM
  end
  #--------------------------------------------------------------------------
  # ● 获取日志数组
  #--------------------------------------------------------------------------
  def self.logs
    $game_system.event_log ||= []
    $game_system.event_log
  end
  #--------------------------------------------------------------------------
  # ● 数据存储类
  #--------------------------------------------------------------------------
  class Data
    #--------------------------------------------------------------------------
    # ● 初始化
    #--------------------------------------------------------------------------
    def initialize(text, ex_params = {})
      @text = text
      @ex = ex_params
    end
    #--------------------------------------------------------------------------
    # ● 获取文字颜色
    #     n : 文字颜色编号（0..31）
    #--------------------------------------------------------------------------
    def text_color(n)
      Cache.system("Window").get_pixel(64 + (n % 8) * 8, 96 + (n / 8) * 8)
    end
    #--------------------------------------------------------------------------
    # ● 绘制
    #--------------------------------------------------------------------------
    def draw(s)
      # 绘制主体文本（位于中心偏右位置）
      params = { :font_size => LOG_FONT_SIZE, :x0 => LINE_X + 20, :lhd => 2 }
      params[:font_color] = LOG_FONT_COLOR
      params[:w] = Graphics.width - OFFSET_X * 2 - params[:x0]
      height_add = 0 # 额外增加的高度

      d = EVENT_LOG_DrawTextEX.new(@text, params)
      s.bitmap = Bitmap.new(Graphics.width, d.height + height_add)
      d.bind_bitmap(s.bitmap, true)
      d.run

      # 绘制左侧标题内容
      if @ex[:name]
        params2 = { :font_size => LOG_FONT_SIZE, :lhd => 2,
         :font_color => text_color(16), :w => LINE_X }
        d2 = EVENT_LOG_DrawTextEX.new(@ex[:name], params2)
        d2.bind_bitmap(s.bitmap, true)
        d2.run(false)
        params2[:x0] = (params2[:w] - d2.width) / 2
        params2[:y0] = (s.height - d2.height) / 2
        d2.run
        #s.bitmap.font.color = text_color(16)
        #s.bitmap.draw_text(0, 0, LINE_X, s.height, @ex[:name], 1)
      end

      # 绘制位于中间线上的点
      _x = LINE_X
      _y = s.height / 2
      c = text_color(17)
      [ [0,-2],[-1,-1],[-2,0],[-1,1],[0,2],[1,1],[2,0],[1,-1] ].each do |xy|
        s.bitmap.set_pixel(_x + xy[0], _y + xy[1], c)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 设置背景精灵
  #--------------------------------------------------------------------------
  def self.set_sprite_bg(sprite)
    sprite.bitmap = Bitmap.new(Graphics.width, Graphics.height)
    sprite.bitmap.fill_rect(0, 0, sprite.width, sprite.height,
      Color.new(0,0,0,200))
  end
  #--------------------------------------------------------------------------
  # ● 设置LOG标题精灵
  #--------------------------------------------------------------------------
  def self.set_sprite_info(sprite)
    sprite.zoom_x = sprite.zoom_y = 3.0
    sprite.bitmap = Bitmap.new(Graphics.height, Graphics.height)
    sprite.bitmap.font.size = 48
    sprite.bitmap.font.color = Color.new(255,255,255,10)
    sprite.bitmap.draw_text(0,0,sprite.width,64, "EVENTS", 0)
    sprite.angle = -90
    sprite.x = Graphics.width + 48
    sprite.y = 0
  end
  #--------------------------------------------------------------------------
  # ● 设置按键提示精灵
  #--------------------------------------------------------------------------
  def self.set_sprite_hint(sprite)
    sprite.bitmap = Bitmap.new(Graphics.width, 24)
    sprite.bitmap.font.size = HINT_FONT_SIZE

    sprite.bitmap.draw_text(0, 2, sprite.width, sprite.height,
      "上/下方向键 - 浏览 | W键/取消键 - 退出", 1)
    sprite.bitmap.fill_rect(0, 0, sprite.width, 1,
      Color.new(255,255,255,120))

    sprite.oy = sprite.height
    sprite.y = Graphics.height
  end
  #--------------------------------------------------------------------------
  # ● 设置读取更多日志提示精灵
  #--------------------------------------------------------------------------
  def self.set_sprite_more(sprite)
    sprite.bitmap = Bitmap.new(Graphics.width, 24)
    sprite.bitmap.font.size = HINT_FONT_SIZE

    sprite.bitmap.draw_text(0, 0, sprite.width, sprite.height,
      "- 再次按下 上方向键 读取更多日志 -", 1)
    sprite.bitmap.fill_rect(0, sprite.height-4, sprite.width, 1,
      Color.new(255,255,255,120))

    sprite.oy = sprite.height
    sprite.opacity = 0
  end

  #--------------------------------------------------------------------------
  # ● 呼叫UI，并执行至结束
  #--------------------------------------------------------------------------
  def self.call
    return if logs.size == 0
    ui_init
    ui_update
    ui_dispose
  end
  #--------------------------------------------------------------------------
  # ● UI控制类
  #--------------------------------------------------------------------------
  class << self
    #--------------------------------------------------------------------------
    # ● UI-初始化
    #--------------------------------------------------------------------------
    def ui_init
      @log_index = -1 # 上一次绘制到的log的序号（已经绘制完的最后一个）
      @sprites = [] # 0 => 存放初始的, 1..-1 => 之后读取加入的

      # 当前移动速度
      @speed = 0
      # 速度逐渐归零用的计数 每@d_speed帧后速度绝对值减一
      @d_speed = @d_speed_count = 10
      # 速度累加用计数 每@ad_speed帧后如果依旧按住同一个键，速度绝对值加一
      @ad_speed = @ad_speed_count = 6
      # 上一帧按下的按键
      @last_key = nil

      ui_init_sprites
      ui_update_new
    end
    #--------------------------------------------------------------------------
    # ● UI-初始化精灵
    #--------------------------------------------------------------------------
    def ui_init_sprites
      @sprite_bg = Sprite.new
      @sprite_bg.z = 250
      set_sprite_bg(@sprite_bg)

      @sprite_bg_info = Sprite.new
      @sprite_bg_info.z = @sprite_bg.z + 1
      set_sprite_info(@sprite_bg_info)

      @sprite_more = Sprite.new
      @sprite_more.z = @sprite_bg.z + 20
      set_sprite_more(@sprite_more)

      @sprite_hint = Sprite.new
      @sprite_hint.z = @sprite_bg.z + 20
      set_sprite_hint(@sprite_hint)

      @viewport = Viewport.new(0,0,Graphics.width, Graphics.height-24)
      @viewport.z = @sprite_bg.z + 10

      @sprite_line = Sprite.new(@viewport)
      @sprite_line.x = OFFSET_X + LINE_X
    end
    #--------------------------------------------------------------------------
    # ● UI-释放
    #--------------------------------------------------------------------------
    def ui_dispose
      @sprites.each { |s| s.dispose }
      instance_variables.each do |varname|
        ivar = instance_variable_get(varname)
        if ivar.is_a?(Sprite)
          ivar.bitmap.dispose if ivar.bitmap
          ivar.dispose
        end
      end
    end
    #--------------------------------------------------------------------------
    # ● UI-更新
    #--------------------------------------------------------------------------
    def ui_update
      while true
        update_basic
        ui_update_speed
        ui_update_pos
        ui_update_line
        ui_update_hint_more
        ui_update_new if @sprite_more.opacity == 255 && Input.trigger?(:UP)
        break if close_scene?
      end
    end
    #--------------------------------------------------------------------------
    # ● UI-等待1帧
    #--------------------------------------------------------------------------
    def update_basic
      Graphics.update
      Input.update
    end
    #--------------------------------------------------------------------------
    # ● UI-更新文本精灵位置
    #--------------------------------------------------------------------------
    def ui_update_pos
      @sprites.each { |s| s.move_xy(0, @speed) }
    end
    #--------------------------------------------------------------------------
    # ● UI-更新竖直线精灵
    #--------------------------------------------------------------------------
    def ui_update_line
      y1 = @sprites[0].y - @sprites[0].oy  + @sprites[0].height / 2
      if y1 < Graphics.height
        # 直线底部与最新的文本精灵的中点对齐
        @sprite_line.y = y1
        @sprite_line.oy = @sprite_line.height
        return
      end
      y2 = @sprites[-1].y - @sprites[-1].oy + @sprites[-1].height / 2
      if y2 > 0
        @sprite_line.y = y2
        @sprite_line.oy = 0
        return
      end
      @sprite_line.y = 0
      @sprite_line.oy = 0
    end
    #--------------------------------------------------------------------------
    # ● UI-更新提示读取精灵
    #--------------------------------------------------------------------------
    def ui_update_hint_more
      @sprite_more.y = @sprites[-1].y - @sprites[-1].oy
      @sprite_more.opacity = 255 * (@sprite_more.y + 0) / DOWN_LIMIT_Y
      @sprite_more.opacity = 0 if @log_index >= logs.size-1
    end
    #--------------------------------------------------------------------------
    # ● UI-更新移动速度
    #--------------------------------------------------------------------------
    def ui_update_speed
      if Input.trigger?(:DOWN)
        @speed = -1
      elsif Input.trigger?(:UP)
        @speed = +1
      end
      if @sprites[0].y - @sprites[0].oy + @speed < UP_LIMIT_Y
        @speed = 0
        d = UP_LIMIT_Y - (@sprites[0].y - @sprites[0].oy)
        @sprites.each { |s| s.move_xy(0, d) }
      end
      if @sprites[-1].y - @sprites[-1].oy + @speed > DOWN_LIMIT_Y
        @speed = 0
        d = DOWN_LIMIT_Y - (@sprites[-1].y - @sprites[-1].oy)
        @sprites.each { |s| s.move_xy(0, d) }
      end
      ui_update_speed_change if @speed != 0
    end
    #--------------------------------------------------------------------------
    # ● UI-更新移动速度的变更
    #--------------------------------------------------------------------------
    def ui_update_speed_change
      if Input.press?(:DOWN)
        if @last_key == :DOWN
          @ad_speed_count -= 1
          if @ad_speed_count <= 0
            @ad_speed_count = @ad_speed
            @speed -= 1
          end
        else
          @ad_speed_count = @ad_speed
        end
        @last_key = :DOWN
      elsif Input.press?(:UP)
        if @last_key == :UP
          @ad_speed_count -= 1
          if @ad_speed_count <= 0
            @ad_speed_count = @ad_speed
            @speed += 1
          end
        else
          @ad_speed_count = @ad_speed
        end
        @last_key = :UP
      else
        return if (@d_speed_count -= 1) > 0
        @d_speed_count = @d_speed
        @speed += (@speed > 0 ? -1 : 1)
      end
    end
    #--------------------------------------------------------------------------
    # ● UI-新生成一组文本精灵
    #--------------------------------------------------------------------------
    def ui_update_new # 新生成的精灵都会叠在上面
      @sprite_more.opacity = 0

      i_start = @log_index + 1
      i_end = @log_index + LOG_READ_NUM
      i_end = logs.size - 1 if i_end >= logs.size
      while( i_start <= i_end )
        data = logs[i_start]
        s = new_sprite(data)
        @sprites.push(s)
        WAIT_COUNT.times { update_basic }
        i_start += 1
      end
      @log_index = i_end
      ui_redraw_line
      ui_update_line
    end
    #--------------------------------------------------------------------------
    # ● UI-创建1个文本精灵
    #--------------------------------------------------------------------------
    def new_sprite(data)
      s = Sprite_EventLog.new(@viewport)
      data.draw(s)
      if @sprites[-1]
        s.set_xy(0, @sprites[-1].y - @sprites[-1].oy - s.height - OFFSET_BETWEEN)
      else
        y0 = (Graphics.height - s.height) / 2 # UP_LIMIT_Y
        s.set_xy(0, y0)
      end
      s.set_xy(OFFSET_X, nil)
      s
    end
    #--------------------------------------------------------------------------
    # ● UI-重绘竖直线
    #--------------------------------------------------------------------------
    def ui_redraw_line
      h = @sprites[0].y - @sprites[0].oy + @sprites[0].height/2
      h = h - @sprites[-1].y + @sprites[-1].oy - @sprites[-1].height/2
      h = [h, Graphics.height].min
      return if @sprite_line.bitmap && h == @sprite_line.height
      return if h == 0
      @sprite_line.bitmap.dispose if @sprite_line.bitmap
      @sprite_line.bitmap = Bitmap.new(1, h)
      @sprite_line.bitmap.fill_rect(Rect.new(0, 0, 1, h), Color.new(255,255,255,100))
    end
  end
  #===============================================================================
  # ○ 文本绘制
  #===============================================================================
  class EVENT_LOG_DrawTextEX < Process_DrawTextEX
    #--------------------------------------------------------------------------
    # ● 获取控制符的实际形式（这个方法会破坏原始数据）
    #--------------------------------------------------------------------------
    def obtain_escape_code(text)
      text.slice!(/^[\$\.\|\^!><\{\}\\]|^[\d\w]+/i)
    end
    #--------------------------------------------------------------------------
    # ● 获取控制符的参数（这个方法会破坏原始数据）
    #--------------------------------------------------------------------------
    def obtain_escape_param(text)
      text.slice!(/^\[\d+\]/)[/\d+/].to_i rescue 0
    end
    #--------------------------------------------------------------------------
    # ● 获取控制符的参数（变量参数字符串形式）（这个方法会破坏原始数据）
    #--------------------------------------------------------------------------
    def obtain_escape_param_string(text)
      text.slice!(/^\[[\|\$\-\d\w]+\]/)[1..-2] rescue ""
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
      else
        obtain_escape_param_string(text)
      end
    end
  end
  #===============================================================================
  # ○ 文本精灵
  #===============================================================================
  class Sprite_EventLog < Sprite
    #--------------------------------------------------------------------------
    # ● 设置坐标（动态更改显示原点，保证正常显示）
    #--------------------------------------------------------------------------
    def set_xy(_x, _y)
      if _x
        if _x <= 0
          self.ox = -x
          self.x = 0
        elsif _x > Graphics.width
          self.ox = Graphics.width - _x
          self.x = Graphics.width
        else
          self.ox = 0
          self.x = _x
        end
      end
      if _y
        if _y <= 0
          self.oy = -_y
          self.y = 0
        elsif _y > Graphics.height
          self.oy = Graphics.height - _y
          self.y = Graphics.height
        else
          self.oy = 0
          self.y = _y
        end
      end
    end
    #--------------------------------------------------------------------------
    # ● 移动
    #--------------------------------------------------------------------------
    def move_xy(dx = 0, dy = 0)
      _x = self.x - self.ox + dx
      _y = self.y - self.oy + dy
      set_xy(_x, _y)
    end
  end
end
#===============================================================================
# ○ Game_System
#===============================================================================
class Game_System
  attr_accessor :event_log
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  alias eagle_event_log_initialize initialize
  def initialize
    eagle_event_log_initialize
    @event_log = [] # 新的放置于头部
  end
end
#===============================================================================
# ○ Game_Interpreter
#===============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 显示滚动文字
  #--------------------------------------------------------------------------
  alias eagle_event_log_command_105 command_105
  def command_105
    return call_event_log if $game_switches[EVENT_LOG::S_ID]
    eagle_event_log_command_105
  end
  #--------------------------------------------------------------------------
  # ● 写入事件日志
  #--------------------------------------------------------------------------
  def call_event_log
    # 约定：第一行固定为名称
    n = ""
    if next_event_code == 405
      @index += 1
      n += @list[@index].parameters[0]
    end
    t = ""
    while next_event_code == 405
      @index += 1
      t += @list[@index].parameters[0]
      t += "\n"
    end
    EVENT_LOG.add(t, n)
  end
end
#===============================================================================
# ○ Scene_Map
#===============================================================================
class Scene_Map < Scene_Base
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  alias eagle_event_log_update update
  def update
    eagle_event_log_update
    EVENT_LOG.call_scene?
  end
end
