#==============================================================================
# ■ 对话日志 by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【组件-位图绘制转义符文本 by老鹰】之下
#==============================================================================
# - 2020.8.2.15 新增LOG标题文字
#==============================================================================
$imported ||= {}
$imported["EAGLE-MessageLog"] = true
#==============================================================================
# - 本插件新增了对 $game_message 的对话文本的记录
#------------------------------------------------------------------------------
# 【使用】
#
#    在地图上时，按下 Q 键即可开启对话日志界面（注意此时地图将被暂停）
#
#    在对话日志界面，再次按下 Q 键即可关闭，并继续之前的地图事件
#
# 【注意】
#
#    对话日志将被存储到存档文件中，因此请不要将 LOG_MAX_NUM 设置过大
#
# 【扩展】
#
#   ·已经兼容【对话框扩展 by老鹰】及其AddOn
#   ·若想在地图以外的场景中调用，可在对应场景的update中增加 MSG_LOG.call_scene?
#
#==============================================================================
module MSG_LOG
  #--------------------------------------------------------------------------
  # ● 呼叫日志？
  #--------------------------------------------------------------------------
  def self.call_scene?
    call if Input.trigger?(:L)
  end
  #--------------------------------------------------------------------------
  # ● 关闭日志？
  #--------------------------------------------------------------------------
  def self.close_scene?
    Input.trigger?(:L) || Input.trigger?(:B)
  end

  #--------------------------------------------------------------------------
  # ○【常量】对于独立的取消分支，显示的日志文本
  #--------------------------------------------------------------------------
  LOG_CHOICE_CANCEL = "（取消）"
  #--------------------------------------------------------------------------
  # ○【常量】最大存储的日志条数
  #--------------------------------------------------------------------------
  LOG_MAX_NUM = 100
  #--------------------------------------------------------------------------
  # ○【常量】每次读取的日志条数
  #--------------------------------------------------------------------------
  LOG_READ_NUM = 10
  #--------------------------------------------------------------------------
  # ○【常量】左侧留空宽度
  #--------------------------------------------------------------------------
  OFFSET_X = 60
  #--------------------------------------------------------------------------
  # ○【常量】显示于底部的最新的对话日志，所能到达的最顶端的y值
  #--------------------------------------------------------------------------
  UP_LIMIT_Y = 4
  #--------------------------------------------------------------------------
  # ○【常量】显示于顶部的最旧的对话日志，所能到达的最底端的y值
  #--------------------------------------------------------------------------
  DOWN_LIMIT_Y = 26

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
    sprite.bitmap.font.size = 64
    sprite.bitmap.font.color = Color.new(255,255,255,10)
    sprite.bitmap.draw_text(0,0,sprite.width,64, "LOG", 0)
    sprite.angle = -90
    sprite.x = Graphics.width + 48
    sprite.y = 0
  end
  #--------------------------------------------------------------------------
  # ● 设置按键提示精灵
  #--------------------------------------------------------------------------
  def self.set_sprite_hint(sprite)
    sprite.bitmap = Bitmap.new(Graphics.width, 24)
    sprite.bitmap.font.size = 14

    sprite.bitmap.draw_text(0, 2, sprite.width, sprite.height,
      "上/下方向键 - 浏览 | Q键/取消键 - 退出", 1)
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
    sprite.bitmap.font.size = 14

    sprite.bitmap.draw_text(0, 0, sprite.width, sprite.height,
      "- 再次按下 下方向键 读取更多日志 -", 1)
    sprite.bitmap.fill_rect(0, sprite.height-4, sprite.width, 1,
      Color.new(255,255,255,120))

    sprite.oy = sprite.height
    sprite.opacity = 0
  end

  #--------------------------------------------------------------------------
  # ● 获取日志数组
  #--------------------------------------------------------------------------
  def self.logs
    $game_system.msg_log ||= []
    $game_system.msg_log
  end
  #--------------------------------------------------------------------------
  # ● 新增日志
  #--------------------------------------------------------------------------
  def self.new_log(text, ex_params = {})
    d = Data.new(text, ex_params)
    logs.unshift(d)
    logs.pop if logs.size > LOG_MAX_NUM
  end
#===============================================================================
# ○ 文本数据
#===============================================================================
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
  # ● 绘制到精灵上
  #--------------------------------------------------------------------------
  def draw(s) # sprite
    # 绘制主体文本（位于中心偏右位置）
    params = { :font_size => 16, :x0 => 90, :lhd => 2 }
    params[:w] = Graphics.width - OFFSET_X * 2
    height_add = 12 # 额外增加的高度
    d = MSG_LOG_DrawTextEX.new(@text, params)
    s.bitmap = Bitmap.new(Graphics.width, d.height + height_add)
    d.bind_bitmap(s.bitmap, true)
    d.run

    # 绘制额外文本（放置于左侧头部）
    if @ex[:name]
      s.bitmap.font.color = text_color(17)
      s.bitmap.draw_text(0,0,params[:x0],params[:font_size], @ex[:name], 1)
    end
    if @ex[:choice]
      s.bitmap.font.color = text_color(16)
      s.bitmap.draw_text(0,0,params[:x0],params[:font_size], "选择 >> ", 2)
    end
    if @ex[:num_input]
      s.bitmap.font.color = text_color(16)
      s.bitmap.draw_text(0,0,params[:x0],params[:font_size], "输入 >> ", 2)
    end
    if @ex[:item_choice]
      s.bitmap.font.color = text_color(16)
      s.bitmap.draw_text(0,0,params[:x0],params[:font_size], "物品 >> ", 2)
    end

    # 绘制底部分割线
    w = d.width + params[:x0]
    s.bitmap.fill_rect(0, s.height - height_add + 4,
      Graphics.width - OFFSET_X * 2, 1, Color.new(255,255,255,80))
  end
end

  #--------------------------------------------------------------------------
  # ● 由 game_message 新增日志
  #--------------------------------------------------------------------------
  def self.add(msg)
    return if msg != $game_message
    add_text(msg) if msg.has_text?
    add_choice(msg) if msg.choice?
    add_num_input(msg) if msg.num_input?
    add_item_choice(msg) if msg.item_choice?
  end
  #--------------------------------------------------------------------------
  # ● 新增文本日志
  #--------------------------------------------------------------------------
  def self.add_text(msg)
    if $imported["EAGLE-MessageEX"]
      params = {}
      t = msg.eagle_text
      if $imported["EAGLE-MsgKeywordInfo"]
        t.gsub!(/\\key\[(.*?)\]/i) { $1 }
      end
      params[:name] = msg.name_params[:name] if msg.name?
      new_log(t, params)
      return
    end
    new_log(msg.all_text)
  end
  #--------------------------------------------------------------------------
  # ● 新增选项结果日志
  #--------------------------------------------------------------------------
  def self.add_choice(msg)
    t = msg.choice_result_text
    new_log(t, { :choice => true })
  end
  #--------------------------------------------------------------------------
  # ● 新增数值输入日志
  #--------------------------------------------------------------------------
  def self.add_num_input(msg)
    v = $game_variables[msg.num_input_variable_id]
    t = v.to_s
    if $imported["EAGLE-NumberInputEX"]
      t = msg.numinput_pattern.clone
      num = sprintf("%0#{t.count("*")}d", v)
      index = 0; i = 0
      t.each_char do |c|
        if c == "*"
          t[i] = num[index]
          index += 1
        end
        i += 1
      end
    end
    new_log(t, { :num_input => true })
  end
  #--------------------------------------------------------------------------
  # ● 新增物品选择日志
  #--------------------------------------------------------------------------
  def self.add_item_choice(msg)
    v = $game_variables[msg.item_choice_variable_id]
    return if v <= 0
    t = msg.keyitem_result_text
    new_log(t, { :item_choice => true })
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
#===============================================================================
# ○ UI
#===============================================================================
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
  end
  #--------------------------------------------------------------------------
  # ● UI-释放
  #--------------------------------------------------------------------------
  def ui_dispose
    @sprites.each { |s| s.dispose }
    instance_variables.each do |varname|
      ivar = instance_variable_get(varname)
      if ivar.is_a?(Sprite)
        ivar.bitmap.dispose
        ivar.dispose
      end
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
  # ● UI-更新
  #--------------------------------------------------------------------------
  def ui_update
    while true
      update_basic
      ui_update_speed
      ui_update_pos
      ui_update_hint_more
      ui_update_new if @sprite_more.opacity == 255 && Input.trigger?(:DOWN)
      break if close_scene?
    end
  end
  #--------------------------------------------------------------------------
  # ● UI-更新文本精灵位置
  #--------------------------------------------------------------------------
  def ui_update_pos
    @sprites.each { |s| s.move_xy(0, @speed) }
  end
  #--------------------------------------------------------------------------
  # ● UI-更新提示读取精灵
  #--------------------------------------------------------------------------
  def ui_update_hint_more
    @sprite_more.y = @sprites[-1].y - @sprites[-1].oy
    @sprite_more.opacity = 255 * (@sprite_more.y + 0) / 24
    @sprite_more.opacity = 0 if @log_index >= logs.size-1
  end
  #--------------------------------------------------------------------------
  # ● UI-更新移动速度
  #--------------------------------------------------------------------------
  def ui_update_speed
    if Input.trigger?(:UP)
      @speed = -1
    elsif Input.trigger?(:DOWN)
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
      update_basic # 绘制一个后，等待一帧，防止明显卡顿
      i_start += 1
    end
    @log_index = i_end
  end
  #--------------------------------------------------------------------------
  # ● UI-创建1个文本精灵
  #--------------------------------------------------------------------------
  def new_sprite(data)
    s = Sprite_MsgLog.new(@viewport)
    data.draw(s)
    if @sprites[-1]
      s.set_xy(0, @sprites[-1].y - @sprites[-1].oy - s.height)
    else
      s.set_xy(0, UP_LIMIT_Y)
    end
    s.set_xy(OFFSET_X, nil)
    s
  end
end
#===============================================================================
# ○ 文本绘制
#===============================================================================
class MSG_LOG_DrawTextEX < Process_DrawTextEX
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
class Sprite_MsgLog < Sprite
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
end # end of MODULE
#===============================================================================
# ○ Game_System
#===============================================================================
class Game_System
  attr_accessor :msg_log
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  alias eagle_msg_log_initialize initialize
  def initialize
    eagle_msg_log_initialize
    @msg_log = [] # 新的放置于头部
  end
end
#===============================================================================
# ○ Game_Message
#===============================================================================
class Game_Message
  attr_accessor :choice_result_text
  attr_accessor :keyitem_result_text
  #--------------------------------------------------------------------------
  # ● 清除
  #--------------------------------------------------------------------------
  alias eagle_text_review_clear clear
  def clear
    MSG_LOG.add(self) if @texts
    eagle_text_review_clear
    @choice_result_text = ""
    @keyitem_result_text = ""
  end
end
#===============================================================================
# ○ Window_ChoiceList
#===============================================================================
class Window_ChoiceList
  #--------------------------------------------------------------------------
  # ● 调用“确定”的处理方法
  #--------------------------------------------------------------------------
  alias eagle_msg_log_call_ok_handler call_ok_handler
  def call_ok_handler
    $game_message.choice_result_text = $game_message.choices[index]
    if $imported["EAGLE-ChoiceEX"]
      $game_message.choice_result_text = @choices_info[index][:text]
    end
    eagle_msg_log_call_ok_handler
  end
  #--------------------------------------------------------------------------
  # ● 调用“取消”的处理方法
  #--------------------------------------------------------------------------
  alias eagle_msg_log_call_cancel_handler call_cancel_handler
  def call_cancel_handler
    i_ = $game_message.choice_cancel_type - 1
    $game_message.choice_result_text = $game_message.choices[i_]
    if $imported["EAGLE-ChoiceEX"]
      t = ""
      if $game_message.choice_cancel_i_w < 0  # 取消分支为独立分支
        t = MSG_LOG::LOG_CHOICE_CANCEL
      else
        t = @choices_info[$game_message.choice_cancel_i_w][:text]
      end
      $game_message.choice_result_text = t
    end
    eagle_msg_log_call_cancel_handler
  end
end
#===============================================================================
# ○ Window_KeyItem
#===============================================================================
class Window_KeyItem
  #--------------------------------------------------------------------------
  # ● 确定时的处理
  #--------------------------------------------------------------------------
  alias eagle_msg_log_on_ok on_ok
  def on_ok
    if item
      $game_message.keyitem_result_text = "\\i[#{item.icon_index}]#{item.name}"
    end
    eagle_msg_log_on_ok
  end
end

#===============================================================================
# ○ Scene_Map
#===============================================================================
class Scene_Map < Scene_Base
  attr_reader :message_window
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  alias eagle_msg_log_update update
  def update
    eagle_msg_log_update
    MSG_LOG.call_scene?
  end
end
