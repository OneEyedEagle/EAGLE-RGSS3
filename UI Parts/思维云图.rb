#==============================================================================
# ■ 思维云图 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【组件-通用方法汇总 by老鹰】、
#     【组件-位图绘制转义符文本 by老鹰】、【组件-形状绘制 by老鹰】之下
# ※ 本插件推荐与【事件互动扩展 by老鹰】共同使用
#==============================================================================
$imported ||= {}
$imported["EAGLE-ThinkBar"] = "1.0.3"
#==============================================================================
# - 2023.5.14.23 无思考词时，不再打开界面
#==============================================================================
# - 本插件新增了效仿《十三机兵防卫圈》的思维云图系统（简化版）
#------------------------------------------------------------------------------
# 【UI】
#
# - 在地图上时，当 THINKBAR.call? 返回 true 时（默认为按下 SHIFT 键），
#     （如果使用了【按键输入扩展 by老鹰】，则改为 TAB 键）
#     将打开 思维云图 界面，此时地图不会暂停，其余事件正常更新
#
# - 按下确定键触发思考词时，将执行对应绑定的事件，执行方式与 玩家按键触发 一致，
#     即挂起玩家移动、等待执行结束
#
# - 若中途有事件因接触玩家而触发，则会强制关闭UI
#
#------------------------------------------------------------------------------
# 【新增思考词：执行事件指令-注释】
#
# - 在事件指令-注释中，编写该样式文本（需作为行首）
#
#       思考|tag字符串|文本
#
#    其中 思考 为固定的识别文本，不可缺少
#    其中 tag字符串 可以为以下类型文本的任意组合，用空格分隔（也可不写）：
#
#       eid=触发该思考词时，执行的事件的id（若不填或填入0，则取当前事件）
#          （执行方式与 玩家按键触发 一致，即只执行满足触发条件的最大序号的页）
#
#       mid=所执行事件的所在地图ID（若不填，则取当前地图）
#          （当执行其它地图上的事件时，指令的 本事件 都会变成当前地图的同ID事件！）
#
#       sym=当使用【事件互动扩展 by老鹰】时，
#           触发思考词时，将在eid号事件的当前页中搜索sym互动类型并执行
#
#       bind=数字（在UI中会将该思考词与该数字序号的事件连线）
#          （当数字为 0 时，代表在UI中会把eid号事件与该思考词连线）
#
#    其中 文本 为思考词的文本，可以用 \n 来进行换行
#       需要保证同一时间各个思考词不完全相同
#
# 【注意】
#
# - 若 EventInteractEX_WORD_AS_SYM 为 true 且不填写 sym= 项，则把思考词作为互动类型
#
# - 所有思考词都会与玩家连线，而 bind=数字 可以额外设置一个事件与其连线
#
# - 当思考词被执行过一次后，将自动删除
#
# 【示例】
#
#    思考||自我反省
#       → 新增一条“自我反省”的思考，执行该思考时将触发该注释的所在事件
#
#
#    思考|eid=5 bind=5 sym=反省|帮他反省
#       → 新增一条“帮他反省”的思考，UI里与5号事件连线，
#          执行该思考时，将触发5号事件当前页中的“反省”互动
#          （若未使用【事件互动扩展 by老鹰】，则依然为触发5号事件）
#
#------------------------------------------------------------------------------
# 【新增思考词：玩家附近的事件-首行注释】
#
# - 当事件页的第一条指令为注释，且其中包含下述类型的文本时，
#   将在玩家开启 思维云图 界面时，自动追加绑定在该事件上的思考
#
#      <思考 tag字符串>
#
#    其中 思考 为固定的识别文本，不可缺少
#    其中 tag字符串 与【新增思考词：执行事件指令-注释】中一致
#       但新增下列参数：
#
#       t=思考词文本【必须】（若不填，则不会增加思考词）
#
# 【注意】
#
# - 该方式新增的思考词会自动绑定所在事件，当然你也可以覆盖设置eid=数字和bind=数字
#
# - 当玩家与事件的距离小于等于指定值时，才会查找事件是否设置了思考词
#
# 【示例】
#
#    <思考 t=自我反省>
#       → 当玩家与写了这条注释的事件之间的距离小于指定值时，
#            玩家开启UI时将会新增一条“自我反省”的思考，
#            执行该思考时将触发该事件
#          （若使用了【事件互动扩展 by老鹰】，则改为触发该事件中的“自我反省”互动）
#
#==============================================================================
module THINKBAR
#=============================================================================
# ■ 常量设置
#=============================================================================
  #--------------------------------------------------------------------------
  # ● 开启/关闭UI
  #--------------------------------------------------------------------------
  def self.call?
    if $imported["EAGLE-InputEX"]
      return Input_EX.trigger?(:TAB)
    end
    Input.trigger?(:A)
  end

  #--------------------------------------------------------------------------
  # ○【常量】事件指令-注释 中新增思考的文本
  #--------------------------------------------------------------------------
  COMMENT_THINKBAR = /^思考 *?\| *?(.*?) *?\| *?(.*)/mi
  #--------------------------------------------------------------------------
  # ○【常量】事件页首行注释中，用于检索是否存在思考词的匹配
  #--------------------------------------------------------------------------
  COMMENT_THINKBAR_EVENT = /<思考 *(.*?)>/m

  #--------------------------------------------------------------------------
  # ○【常量】（使用了【事件互动扩展 by老鹰】时）
  # 若为 true，则将思考词作为互动类型查找，若当前页未找到对应互动，则不执行任何内容
  # 若为 false，则指定 sym=0 时，才会查找与思考词一致的互动，否则执行整页
  # 注意：若指定 sym=任意文本，则仅会查找 任意文本 的互动类型并执行
  #--------------------------------------------------------------------------
  EventInteractEX_WORD_AS_SYM = true
  #--------------------------------------------------------------------------
  # ○【常量】检测半径
  #--------------------------------------------------------------------------
  # 当玩家与事件距离小于等于该值时，检索事件页中设置的思考词
  #--------------------------------------------------------------------------
  SEARCH_RANGE = 3
  #--------------------------------------------------------------------------
  # 如果不想把激活距离设置为固定值，可以修改该项为变量序号
  #   该序号的变量的值如果大于0，则会被读取作为距离值
  #   该序号设置为 0 时，依然取 SEARCH_RANGE 设置的固定值
  #--------------------------------------------------------------------------
  V_ID_SEARCH_RANGE = 0

  #--------------------------------------------------------------------------
  # ● 设置增加思考时的提示（t 为思考词文本）
  # （仅利用注释、全局脚本增加思考词时出现，自动索引事件时不会提示）
  #--------------------------------------------------------------------------
  def self.show_hint(t)
    if $imported["EAGLE-MessageHint"]
      ps = { :text => "新增思考 | #{t}" }
      MESSAGE_HINT.add(ps, "居中偏上")
      return
    end
  end

#=============================================================================
# ■ UI绘制部分
#=============================================================================
  #--------------------------------------------------------------------------
  # ○【常量】玩家与思考词连线的颜色
  #--------------------------------------------------------------------------
  COLOR_LINE_PLAYER = Color.new(200,100,100, 160)
  #--------------------------------------------------------------------------
  # ○【常量】事件与思考词连线的颜色
  #--------------------------------------------------------------------------
  COLOR_LINE_EVENT = Color.new(200,200,200, 160)
  #--------------------------------------------------------------------------
  # ○【常量】提示文本的字体大小
  #--------------------------------------------------------------------------
  HINT_FONT_SIZE = 14

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
    sprite.bitmap.draw_text(0,0,sprite.width,64, "THINK", 0)
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
      "左/右方向键 - 切换 | 确定键 - 执行 | 取消键 - 退出", 1)
    sprite.bitmap.fill_rect(0, 0, sprite.width, 1,
      Color.new(255,255,255,120))

    sprite.oy = sprite.height
    sprite.y = Graphics.height
  end

#=============================================================================
# ■ 控制部分
#=============================================================================
  #--------------------------------------------------------------------------
  # ● 初始化（在 spriteset 里调用）
  #--------------------------------------------------------------------------
  def self.init
    @flag_active = false
  end
  #--------------------------------------------------------------------------
  # ● 更新（在 spriteset 里调用）
  #--------------------------------------------------------------------------
  def self.update
    if active?
      deactivate if $game_map.interpreter.running?
      return
    end
    return if $game_map.interpreter.running?
    @flag_active = true if call?
  end
  #--------------------------------------------------------------------------
  # ● 开启中？
  #--------------------------------------------------------------------------
  def self.active?
    @flag_active == true
  end
  #--------------------------------------------------------------------------
  # ● 关闭
  #--------------------------------------------------------------------------
  def self.deactivate
    @flag_active = false
  end
  #--------------------------------------------------------------------------
  # ● 获取检测半径
  #--------------------------------------------------------------------------
  def self.get_search_range
    v = $game_variables[V_ID_SEARCH_RANGE]
    return v if v > 0
    return SEARCH_RANGE
  end
  #--------------------------------------------------------------------------
  # ● 判定事件是否可以提取思考词
  #--------------------------------------------------------------------------
  def self.check_event_near(event)
    return [] if !event.eagle_word?  # 排除已经暂时消除或空白页
    
    d = (event.x - $game_player.x).abs + (event.y - $game_player.y).abs
    if $imported["EAGLE-PixelMove"]
      d = (event.rgss_x - $game_player.rgss_x).abs + \
        (event.rgss_y - $game_player.rgss_y).abs
    end
    return [] if d > THINKBAR.get_search_range  # 查询的范围

    t = EAGLE_COMMON.event_comment_head(event.list)
    rs = []
    t.scan(THINKBAR::COMMENT_THINKBAR_EVENT).each do |ps|
      h = EAGLE_COMMON.parse_tags(ps[0].lstrip)
      next if h[:t] == nil
      h[:mid] ||= $game_map.map_id
      h[:eid] ||= event.id
      h[:bind] ||= event.id
      rs.push(h)
    end
    return rs
  end
end
#=============================================================================
# ■ Spriteset_ThinkBar
#=============================================================================
class Spriteset_ThinkBar
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize
    THINKBAR.init
    @sprites = []
    @fiber = nil
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    @sprites.each { |s| s.dispose }
    @sprites = []
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    @sprites.each { |s| s.update }
    THINKBAR.update
    @fiber.resume if @fiber
    return if !THINKBAR.active?
    activate if @fiber == nil
  end

  #--------------------------------------------------------------------------
  # ● UI-初始化精灵
  #--------------------------------------------------------------------------
  def ui_init_sprites
    @sprite_bg = Sprite.new
    @sprite_bg.z = 250
    THINKBAR.set_sprite_bg(@sprite_bg)

    @sprite_bg_info = Sprite.new
    @sprite_bg_info.z = @sprite_bg.z + 1
    THINKBAR.set_sprite_info(@sprite_bg_info)

    @sprite_hint = Sprite.new
    @sprite_hint.z = @sprite_bg.z + 20
    THINKBAR.set_sprite_hint(@sprite_hint)

    @sprite_lines = Sprite.new
    @sprite_lines.z = @sprite_bg.z + 5
    @sprite_lines.bitmap = Bitmap.new(Graphics.width, Graphics.height)
  end
  #--------------------------------------------------------------------------
  # ● UI-释放
  #--------------------------------------------------------------------------
  def ui_dispose
    instance_variables.each do |varname|
      ivar = instance_variable_get(varname)
      if ivar.is_a?(Sprite)
        ivar.bitmap.dispose if ivar.bitmap
        ivar.dispose
      end
    end
  end

  #--------------------------------------------------------------------------
  # ● 开启
  #--------------------------------------------------------------------------
  def activate
    @fiber = Fiber.new { fiber_main }
  end
  #--------------------------------------------------------------------------
  # ● 主线程
  #--------------------------------------------------------------------------
  def fiber_main
    @flag_break = false
    init_words
    # 如果没有词语，则关闭
    if @words.size == 0
      THINKBAR.deactivate
      return @fiber = nil
    end
    ui_init_sprites
    init_sprites
    move_in
    update_selection(1)
    loop do
      break if @flag_break == true
      Fiber.yield
      break if !THINKBAR.active?
      update_key
    end
    move_out
    ui_dispose
    @fiber = nil
  end

  #--------------------------------------------------------------------------
  # ● 初始化思考词
  #--------------------------------------------------------------------------
  def init_words
    @words = $game_player.eagle_words.dup
    # 增加此刻玩家周围的事件的词语
    $game_map.events.each do |id, e|
      words_params = THINKBAR.check_event_near(e)
      words_params.each do |_ps|
        next if _ps[:t] == nil
        _ps[:__t__] = _ps[:t].dup # 用于显示和呼叫思考词
        # 加上事件id，确保不会和已有思考词发生冲突
        _ps[:t] = _ps[:t] + "#{_ps[:eid]}"
        @words[_ps[:t]] = _ps
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 初始化精灵
  #--------------------------------------------------------------------------
  def init_sprites
    @sprites.each { |s| s.dispose }
    @sprites.clear
    id = 0
    @words.each do |w, ps|
      s = Sprite_ThinkBar_Word.new(nil, w, id, ps)
      s.z = @sprite_bg.z + 10
      s.opacity = 120
      @sprites.push(s)
      id += 1
    end
    @index = -1
  end
  #--------------------------------------------------------------------------
  # ● 等待精灵移动结束
  #--------------------------------------------------------------------------
  def wait_for_move
    Fiber.yield while @sprites.any? { |s| s.moving? }
  end
  #--------------------------------------------------------------------------
  # ● 移入
  #--------------------------------------------------------------------------
  def move_in
    @sprites.each do |s|
      x2, y2 = rand_point_in_screen(s)
      x1, y1 = calc_point_out_of_screen(x2, y2)
      s.set_xy(x1, y1)
      s.goto(x2, y2)
    end
    wait_for_move
  end
  #--------------------------------------------------------------------------
  # ● 移出
  #--------------------------------------------------------------------------
  def move_out
    20.times do
      @sprites.each do |s|
        s.opacity -= 15
      end
      @sprite_bg.opacity -= 15
      @sprite_bg_info.opacity -= 15
      @sprite_hint.opacity -= 15
      @sprite_lines.opacity -= 15
      Fiber.yield
    end
  end
  #--------------------------------------------------------------------------
  # ● 获得一个屏幕里的随机位置
  #--------------------------------------------------------------------------
  def rand_point_in_screen(s)
    x0 = Graphics.width / 2 # $game_player.screen_x
    y0 = Graphics.height / 2 + 32 # $game_player.screen_y
    n = @sprites.size
    r = 80 + n * 5
    angle = (360.0 * s.id / n - 90) / 180 * Math::PI
    x2 = x0 + r * Math.cos(angle)
    y2 = y0 + r * Math.sin(angle)
    return x2, y2
  end
  #--------------------------------------------------------------------------
  # ● 计算一个屏幕外的随机位置
  #--------------------------------------------------------------------------
  def calc_point_out_of_screen(x_in_screen, y_in_screen)
    x1 = 0
    if x_in_screen < Graphics.width / 2
      x1 = 0 - rand(200)
    else
      x1 = rand(200) + Graphics.width
    end
    y1 = 0
    if y_in_screen < Graphics.height / 2
      y1 = 0 - rand(200)
    else
      y1 = rand(200) + Graphics.height
    end
    return x1, y1
  end

  #--------------------------------------------------------------------------
  # ● 更新按键
  #--------------------------------------------------------------------------
  def update_key
    update_next
    update_prev
    update_confirm
    update_cancel
  end
  #--------------------------------------------------------------------------
  # ● 下一个
  #--------------------------------------------------------------------------
  def update_next
    update_selection(1) if Input.trigger?(:RIGHT)
  end
  #--------------------------------------------------------------------------
  # ● 上一个
  #--------------------------------------------------------------------------
  def update_prev
    update_selection(-1)  if Input.trigger?(:LEFT)
  end
  #--------------------------------------------------------------------------
  # ● 更新选择
  #--------------------------------------------------------------------------
  def update_selection(d = 0)
    return if @sprites.size == 0
    last_index = @index
    @index = @index + d
    @index = 0 if @index >= @sprites.size
    @index = @sprites.size - 1 if @index < 0
    return if last_index == @index
    @sprite_lines.bitmap.clear
    if @index >= 0  # 当前选中的
      s = @sprites[@index]
      s.opacity = 255
      x0 = s.x; y0 = s.y - s.oy / 2

      # 连接玩家
      x2 = $game_player.screen_x
      y2 = $game_player.screen_y - 16
      c = THINKBAR::COLOR_LINE_PLAYER
      EAGLE.DDALine(@sprite_lines.bitmap, x0, y0, x2, y2, 3, "0011", c)

      # 连接绑定的事件
      if s.bind_eid && e = $game_map.events[s.bind_eid]
        c = THINKBAR::COLOR_LINE_EVENT
        EAGLE.DDALine(@sprite_lines.bitmap, x0, y0, e.screen_x, e.screen_y-16,
          3, "0011", c )
      end

      # 绘制背景的圆
      c = THINKBAR::COLOR_LINE_PLAYER
      EAGLE.Circle(@sprite_lines.bitmap, x0, y0, 50, false, c)
    end
    if last_index >= 0  # 上一个被选中的
      s = @sprites[last_index]
      s.opacity = 120
    end
    wait_for_move
  end
  #--------------------------------------------------------------------------
  # ● 更新确定
  #--------------------------------------------------------------------------
  def update_confirm
    return if !Input.trigger?(:C)
    return Sound.play_buzzer if @index < 0
    Input.update
    THINKBAR.deactivate
    @flag_break = true

    s = @sprites[@index]
    ps = @words[s.t]

    mid = ps[:mid].to_i
    eid = ps[:eid].to_i
    pid = ps[:pid] ? ps[:pid].to_i : nil

    # 读取其它地图中的
    if mid != $game_map.map_id
      map = EAGLE_COMMON.get_map_data(mid)
      event_data = map.events[eid] rescue return
      event = Game_Event.new(mid, event_data)
      page = nil
      if pid == nil || pid == 0
        page = event.find_proper_page
      else
        page = event.event.pages[pid-1] rescue return
      end
      $game_player.eagle_delete_word(s.t)
      $game_map.eagle_thinkbar_run(page.list, eid, s.sym)
      return
    end

    # 读取本地图中的
    $game_player.eagle_delete_word(s.t)
    e = $game_map.events[eid]
    return e.start_ex(s.sym) if s.sym
    e.start
  end
  #--------------------------------------------------------------------------
  # ● 更新取消
  #--------------------------------------------------------------------------
  def update_cancel
    return if !(Input.trigger?(:B) || THINKBAR.call?)
    Input.update
    THINKBAR.deactivate
    @flag_break = true
  end
end
#=============================================================================
# ■ Sprite_ThinkBar_Word
#=============================================================================
class Sprite_ThinkBar_Word < Sprite
  attr_reader  :id, :t, :bind_eid, :sym
  #--------------------------------------------------------------------------
  # ●【常量】背景字母
  #--------------------------------------------------------------------------
  CS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(viewport, t, id, params)
    super(viewport)
    @t = t
    @id = id
    @bind_eid = params[:bind].to_i || nil
    @sym = get_sym(params)

    # 位图的最小宽高
    w = 96
    h = 96
    # 文字周围的留白
    padding = 4

    # 创建位图，此时确保了位图宽高一定大于文字区域
    ps = { :x0 => 0, :y0 => 0 }
    d = Process_DrawTextEX.new(params[:__t__].dup, ps)
    w = [w, d.width + padding * 2].max
    h = [h, d.height + padding * 2].max
    self.bitmap = Bitmap.new(w, h)

    # 绘制背景的字母
    _size = self.bitmap.font.size
    self.bitmap.font.size = 96
    self.bitmap.font.color.alpha = 50
    self.bitmap.font.outline = false
    self.bitmap.font.shadow = false
    self.bitmap.draw_text(0, 0, w, h, CS[id], 1)
    self.bitmap.font.size = _size
    self.bitmap.font.color.alpha = 255
    self.bitmap.font.outline = true
    self.bitmap.font.shadow = true

    # 绘制背景的矩形
    y0 = (h - d.height) / 2
    self.bitmap.fill_rect(Rect.new(0,y0-padding,w,d.height+padding*2),
      Color.new(0,0,0,80))

    # 绘制思考词
    d.bind_bitmap(self.bitmap)
    ps[:x0] = (w - d.width) / 2
    ps[:y0] = y0
    d.run

    # 为了方便后续处理，确保底部中点为显示原点
    self.ox = self.width / 2
    self.oy = self.height
    init_params
  end
  #--------------------------------------------------------------------------
  # ● 获得实际的互动类型
  #--------------------------------------------------------------------------
  def get_sym(ps)
    return nil if !$imported["EAGLE-EventInteractEX"]
    sym = nil
    if THINKBAR::EventInteractEX_WORD_AS_SYM
      sym = ps[:__t__]
      sym = ps[:sym] if ps[:sym]
      return sym
    else
      sym = ps[:sym] if ps[:sym]
      sym = ps[:__t__] if ps[:sym] == "0"
    end
    return sym
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    self.bitmap.dispose
    super
  end
  #--------------------------------------------------------------------------
  # ● 初始化参数
  #--------------------------------------------------------------------------
  def init_params
    @type = :wait
    @x0 = @dx = 0
    @y0 = @dy = 0
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
    case @type
    when :goto
      if @ps_move[:i] > @ps_move[:t]
        @type = :wait
        return
      end
      v = ease_value(@ps_move[:i] * 1.0 / @ps_move[:t])
      @x0 = @ps_move[:x0] + @ps_move[:dx] * v
      @y0 = @ps_move[:y0] + @ps_move[:dy] * v
      @ps_move[:i] += 1
    when :wait
    end
    self.x = @x0 + @dx
    self.y = @y0 + @dy
  end
  #--------------------------------------------------------------------------
  # ● 直接指定位置
  #--------------------------------------------------------------------------
  def set_xy(_x, _y)
    @x0 = _x if _x
    @y0 = _y if _y
  end
  #--------------------------------------------------------------------------
  # ● 指定目标移动位置
  #--------------------------------------------------------------------------
  def goto(des_x, des_y)
    @ps_move = {}
    @ps_move[:x0] = @x0
    @ps_move[:x1] = des_x
    @ps_move[:dx] = @ps_move[:x1] - @ps_move[:x0]
    @ps_move[:y0] = @y0
    @ps_move[:y1] = des_y
    @ps_move[:dy] = @ps_move[:y1] - @ps_move[:y0]
    @ps_move[:i] = 0
    @ps_move[:t] = 20
    @type = :goto
  end
  #--------------------------------------------------------------------------
  # ● 缓动函数
  #--------------------------------------------------------------------------
  def ease_value(v)
    1 - 2**(-10 * v)
  end
  #--------------------------------------------------------------------------
  # ● 正在移动？
  #--------------------------------------------------------------------------
  def moving?
    @type != :wait
  end
end
#=============================================================================
# ■ Spriteset_Map
#=============================================================================
class Spriteset_Map
  #--------------------------------------------------------------------------
  # ● 生成人物精灵
  #--------------------------------------------------------------------------
  alias eagle_thinkbar_create_characters create_characters
  def create_characters
    eagle_thinkbar_create_characters
    @spriteset_thinkbar = Spriteset_ThinkBar.new
  end
  #--------------------------------------------------------------------------
  # ● 更新人物精灵
  #--------------------------------------------------------------------------
  alias eagle_thinkbar_update_characters update_characters
  def update_characters
    eagle_thinkbar_update_characters
    @spriteset_thinkbar.update
  end
  #--------------------------------------------------------------------------
  # ● 释放人物精灵
  #--------------------------------------------------------------------------
  alias eagle_thinkbar_dispose_characters dispose_characters
  def dispose_characters
    eagle_thinkbar_dispose_characters
    @spriteset_thinkbar.dispose
  end
end
#=============================================================================
# ■ Game_Map
#=============================================================================
class Game_Map
  #--------------------------------------------------------------------------
  # ● 执行思考词的特殊事件
  #--------------------------------------------------------------------------
  def eagle_thinkbar_run(list, event_id, sym = nil)
    @interpreter.setup(list, event_id)
    if $imported["EAGLE-EventInteractEX"]
      @interpreter.event_interact_search(sym) if sym
    end
  end
end
#=============================================================================
# ■ Scene_Map
#=============================================================================
class Scene_Map
  #--------------------------------------------------------------------------
  # ● 监听取消键的按下。如果菜单可用且地图上没有事件在运行，则打开菜单界面。
  #--------------------------------------------------------------------------
  alias eagle_thinkbar_update_call_menu update_call_menu
  def update_call_menu
    return if THINKBAR.active?
    eagle_thinkbar_update_call_menu
  end
end
#=============================================================================
# ■ Game_Player
#=============================================================================
class Game_Player
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  alias eagle_thinkbar_initialize initialize
  def initialize
    eagle_thinkbar_initialize
    @eagle_think_words = {}
    # word => { :mid => v, :eid => v, :sym=> "", :cond => "" }
  end
  #--------------------------------------------------------------------------
  # ● 获取当前全部思考词
  #--------------------------------------------------------------------------
  def eagle_words
    @eagle_think_words
  end
  #--------------------------------------------------------------------------
  # ● 增加思考词
  #--------------------------------------------------------------------------
  def eagle_add_word(t, ps)
    @eagle_think_words[t] = ps
    THINKBAR.show_hint(t)
  end
  #--------------------------------------------------------------------------
  # ● 删去思考词
  #--------------------------------------------------------------------------
  def eagle_delete_word(t)
    @eagle_think_words.delete(t)
  end
  #--------------------------------------------------------------------------
  # ● 判定是否可以移动
  #--------------------------------------------------------------------------
  alias eagle_thinkbar_movable? movable?
  def movable?
    return false if THINKBAR.active?
    eagle_thinkbar_movable?
  end
end
#===============================================================================
# ○ Game_Interpreter
#===============================================================================
class Game_Event
  #--------------------------------------------------------------------------
  # ● 可以触发思考词？
  #--------------------------------------------------------------------------
  def eagle_word?
    @erased == false && @page != nil && @transparent == false
  end
end
#===============================================================================
# ○ Game_Interpreter
#===============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 添加注释
  #--------------------------------------------------------------------------
  alias eagle_thinkbar_command_108 command_108
  def command_108
    eagle_thinkbar_command_108
    t = @comments.inject { |t, v| t = t + "\n" + v }
    t.scan(THINKBAR::COMMENT_THINKBAR).each do |v|
      ps = v[0].lstrip.rstrip  # tags string  # 去除前后空格
      ps = EAGLE_COMMON.parse_tags(ps)
      t = v[1]
      ps[:t] = t
      ps[:__t__] = ps[:t].dup # 用于显示和呼叫思考词
      ps[:mid] ||= @map_id
      ps[:eid] ||= @event_id
      ps[:eid] = @event_id if ps[:eid] == "0"
      ps[:bind] = ps[:eid] if ps[:bind] == "0"
      $game_player.eagle_add_word(t, ps)
    end
  end
end
