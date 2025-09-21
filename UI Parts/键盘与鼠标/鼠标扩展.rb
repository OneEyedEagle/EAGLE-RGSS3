#==============================================================================
# ■ 鼠标扩展 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【按键扩展 by老鹰】之下
#    或 将 MOUSE_EX 模块中的方法修改为使用你自己的鼠标系统
# ※ 本插件部分功能需要 RGD(> 1.5.0) 才能正常使用
#==============================================================================
$imported ||= {}
$imported["EAGLE-MouseEX"] = "1.2.1"
#=============================================================================
# - 2025.8.30.10 新增鼠标拖动的判定
#=============================================================================
# - 本插件新增了一系列鼠标控制的方法
# - 按照 ○ 标志，请逐项阅读各项的注释，并对标记了【常量】的项进行必要的修改
#=============================================================================
module MOUSE_EX
#===============================================================================
# ○ 鼠标按键判定
#===============================================================================
#  以下方法中的 key 传入：
#
#    :ML → 鼠标左键
#    :MM → 鼠标中键
#    :MR → 鼠标右键
#
#  1. 鼠标按键由未按下变成按下？
#
#      MOUSE_EX.down?(key)
#
#  2. 鼠标按键由按下变成未按下？（且按下的时间帧在 c1 和 c2 之间）
#
#      MOUSE_EX.up?(key, c1=RELEASE_C1, c2=RELEASE_C2)
#
#  3. 鼠标按键按下至少c帧？
#
#      MOUSE_EX.press?(key, c=PRESS_C)
#
#  4. 将鼠标直接定位到游戏屏幕内的(x,y)处
#
#      MOUSE_EX.set_to(x, y)
#
  #--------------------------------------------------------------------------
  # ● 判定鼠标按键是否从未按下变成按下
  #--------------------------------------------------------------------------
  def self.down?(key)
    INPUT_EX.down?(key)
  end
  #--------------------------------------------------------------------------
  # ● 判定鼠标按键是否从按下变成未按下
  #  当已按下的帧数不在 c1 和 c2 之间（包含两端）时，则仍然返回 false
  #--------------------------------------------------------------------------
  # 【常量】默认的按下的最小帧数
  RELEASE_C1 = 1
  #----------------------------------
  # 【常量】默认的按下的最大帧数
  RELEASE_C2 = 20
  #----------------------------------
  def self.up?(key, c1=RELEASE_C1, c2=RELEASE_C2)
    INPUT_EX.up?(key, c1, c2)
  end
  #--------------------------------------------------------------------------
  # ● 判定鼠标按键是否按下 c 帧
  #--------------------------------------------------------------------------
  # 【常量】默认需要至少按下的帧数
  PRESS_C = 10
  #----------------------------------
  def self.press?(key, c=PRESS_C)
    INPUT_EX.press?(key, c)
  end
  #--------------------------------------------------------------------------
  # ● 将鼠标直接定位到(x,y)处（屏幕真实坐标）
  #--------------------------------------------------------------------------
  def self.set_to(x, y)
    INPUT_EX.set_mouse(x, y)
  end
end

#===============================================================================
# ○ 鼠标位置判定
#===============================================================================
#  1. 获取鼠标坐标
#
#      MOUSE_EX.x  和  MOUSE_EX.y
#
#  2. 判定鼠标是否在矩形区域内（游戏窗口内的矩形，不考虑 viewport）
#
#      MOUSE_EX.in?(r)
#
#     其中 r 是Rect.new，如果不传入，则判定鼠标是否在游戏窗口内
#
#     如： MOUSE_EX.in? → 返回鼠标是否在游戏窗口内
#
#  3.1 为 Sprite 类增加了实例方法，判定鼠标是否在该精灵的位图内部
#     精灵区域为实际显示在游戏窗口内的位置（即考虑精灵所在的viewport）
#
#      sprite.mouse_in?(_visible=true, _pixel=true)
#
#     如果_visible传入 true，则会首先检查精灵的 visible：
#       visible为false 或 opacity为0 则直接返回 false
#     如果_pixel传入 true，则会判定所在位置的像素：
#       如果在颜色像素上则返回 true，在透明像素上返回 false
#
#  3.2 为 Window 类增加了实例方法，判定鼠标是否在该窗口内部
#
#      window.mouse_in?(_visible=true, _in_contents=true)
#
#     如果_visible传入 true，则会首先检查窗口的 visible、opacity、openness
#     如果_in_contents传入 true，则必须要在contents内部，在边框处不算
#
#  4. 判定鼠标在矩形区域内的位置（九宫格）（游戏窗口内的矩形，不考虑 viewport）
#     将rect按小键盘数字键划分为9块，再判定鼠标位于哪一块中，并返回对应数字
#
#      MOUSE_EX.pos_num(rect=nil, dw=nil, dh=nil)
#
#     其中 rect 是Rect.new，如果不传入，则自动设置为整个游戏窗口
#          dw 为左右侧147和369的块的宽度，若不传入，则对rect宽度进行三等分
#          dh 为上下侧123和789的块的高度，若不传入，则对rect高度进行三等分
#     如果鼠标不在 rect 区域内，则返回 0
#
module MOUSE_EX
  #--------------------------------------------------------------------------
  # ● 获取鼠标的坐标
  #--------------------------------------------------------------------------
  def self.x;  INPUT_EX.mouse_x;  end
  def self.y;  INPUT_EX.mouse_y;  end
  #--------------------------------------------------------------------------
  # ● 鼠标位于矩形内？（rect为屏幕真实坐标，不受 viewport 等的影响）
  #  若不传入矩形或传入 nil，则返回鼠标是否在游戏窗口内
  #--------------------------------------------------------------------------
  def self.in?(rect = nil)
    _x = MOUSE_EX.x; _y = MOUSE_EX.y
    if rect.nil?
      return false if _x > Graphics.width || _y > Graphics.height
      return true
    end
    return false if _x < rect.x || _x > rect.x + rect.width
    return false if _y < rect.y || _y > rect.y + rect.height
    return true
  end
  #--------------------------------------------------------------------------
  # ● 鼠标位于矩形九宫格内的位置（rect为屏幕真实坐标，不受 viewport 等的影响）
  #  将rect按小键盘数字键划分为9块，再判定鼠标位于哪一块中，并返回对应数字
  #  若不传入矩形或传入 nil，则以整个游戏窗口为rect进行判定
  #   dw 为左右侧147和369的块的宽度，若不传入，则对rect宽度进行三等分
  #   dh 为上下侧123和789的块的高度，若不传入，则对rect高度进行三等分
  #--------------------------------------------------------------------------
  def self.pos_num(rect = nil, dw = nil, dh = nil)
    _x = MOUSE_EX.x; _y = MOUSE_EX.y
    rect = Rect.new(0, 0, Graphics.width, Graphics.height) if rect.nil?
    x0 = rect.x
    y0 = rect.y
    x3 = rect.x + rect.width
    y3 = rect.y + rect.height
    return 0 if _x < x0 || _x >= x3 || _y < y0 || _y >= y3
    if dw == nil
      x1 = rect.x + rect.width * 1.0 / 3
      x2 = rect.x + rect.width * 2.0 / 3
    else 
      x1 = rect.x + dw 
      x2 = rect.x + rect.width - dw
    end
    if dh == nil 
      y1 = rect.y + rect.height * 1.0 / 3
      y2 = rect.y + rect.height * 2.0 / 3
    else 
      y1 = rect.y + dh
      y2 = rect.y + rect.height - dh
    end
    if x0 <= _x && _x < x1 # 147
      return 7 if y0 <= _y && _y < y1
      return 1 if y2 <= _y && _y < y3
      return 4
    elsif x2 < _x && _x < x3 # 369
      return 9 if y0 <= _y && _y < y1
      return 3 if y2 <= _y && _y < y3
      return 6
    else # 258
      return 8 if y0 <= _y && _y < y1
      return 2 if y2 <= _y && _y < y3
      return 5
    end
  end
end
class Sprite
  #--------------------------------------------------------------------------
  # ● 该精灵的bitmap包含了鼠标？
  #  增加了对所在像素是否透明的判定
  #--------------------------------------------------------------------------
  def mouse_in?(_visible = true, _pixel = true)
    return false if _visible && (self.visible == false || self.opacity == 0)
    return false unless self.bitmap
    return false if self.bitmap.disposed?
    # 计算出鼠标相对于实际位图的坐标 左上原点
    rx = MOUSE_EX.x - (self.x - self.ox)
    ry = MOUSE_EX.y - (self.y - self.oy)
    if viewport
      rx = rx - self.viewport.rect.x + self.viewport.ox
      ry = ry - self.viewport.rect.y + self.viewport.oy
    end
    # 边界判定  src_rect - 该矩形内的位图为精灵 (0,0) 处显示位图
    return false if rx < 0 || ry < 0 || rx > width || ry > height
    return self.bitmap.get_pixel(rx, ry).alpha != 0 if _pixel
    return true
  end
end
class Window_Base
  #--------------------------------------------------------------------------
  # ● 该窗口包含了鼠标？
  #--------------------------------------------------------------------------
  def mouse_in?(_visible = true, _in_contents = true)
    return false if _visible && (!visible || openness < 255 || (opacity == 0 and contents_opacity == 0))
    return false if disposed?
    rx = MOUSE_EX.x - self.x 
    ry = MOUSE_EX.y - self.y 
    if viewport
      rx = rx - self.viewport.rect.x + self.viewport.ox
      ry = ry - self.viewport.rect.y + self.viewport.oy
    end
    # 边界判定
    if _in_contents  # 边框不算
      return false if rx < standard_padding || rx > width - standard_padding
      return false if ry < standard_padding || ry > height - standard_padding
    else # 边框也可以
      return false if rx < 0 || rx > width 
      return false if ry < 0 || ry > height 
    end
    return true
  end
end

#===============================================================================
# ○ 鼠标拖动判定
#===============================================================================
# - 鼠标按住某个键后，自动开始拖动状态，此时可用以下方法判定：
#
#     boolean = MOUSE_EX.drag?  → 是否处于拖动状态
#
#     sym = MOUSE_EX.drag_key   → 触发拖动状态的鼠标按键
#
#     v   = MOUSE_EX.drag_count → 拖动状态的已持续帧数
#
#     dx, dy = MOUSE_EX.drag_dxy       → 与上一帧位置相比，鼠标的x、y增加量
#
#     dx, dy = MOUSE_EX.drag_dxy_total → 与拖动开始时相比，鼠标的x、y增加量
#
#   当松开按键，将立即结束拖动状态。
#
#   在拖动状态下，如果再按住另一个键，不会重复生效。
#
# - 当鼠标移动速度过快时，可能出现跟不上的情况。
#
module MOUSE_EX
               # [key, count, init xy, last xy, cur - last, cur - init]
  @params_drag = [nil,   0,     0,0,     0,0,       0,0,       0,0]
  def self.update_drag
    if @params_drag[0] == nil
      keys = [:ML, :MM, :MR]
      keys.each do |key|
        break @params_drag = [key, 0, x,y, x,y, 0,0, 0,0] if down?(key)
      end
      return
    end
    return @params_drag[0] = nil if !in? or up?(@params_drag[0],1,0)
    # count 
    @params_drag[1] += 1
    # cur - init
    @params_drag[8] = x - @params_drag[2]; @params_drag[9] = y - @params_drag[3]
    # cur - last
    @params_drag[6] = x - @params_drag[4]; @params_drag[7] = y - @params_drag[5]
    # last xy
    @params_drag[4] = x; @params_drag[5] = y
  end
  def self.drag?
    return false if @params_drag[0] == nil 
    return true
  end
  def self.drag_key
    return @params_drag[0]
  end
  def self.drag_count
    return @params_drag[1]
  end
  def self.drag_dxy
    return @params_drag[6], @params_drag[7]
  end
  def self.drag_dxy_total
    return @params_drag[8], @params_drag[9]
  end
end
class << INPUT_EX
  alias eagle_mouse_ex_update_mouse update_mouse
  def update_mouse
    eagle_mouse_ex_update_mouse
    MOUSE_EX.update_drag
  end
end

#===============================================================================
# ○ 鼠标滚轮
#===============================================================================
#  此功能利用了 RGD（> 1.5.0）中 Mouse 模块的API，默认RGSS中无法使用
module MOUSE_EX
  #--------------------------------------------------------------------------
  # ● 鼠标向上滚动？
  #--------------------------------------------------------------------------
  def self.scroll_up?
    return Mouse.scroll > 0 if $RGD
    return false 
  end
  #--------------------------------------------------------------------------
  # ● 鼠标向下滚动？
  #--------------------------------------------------------------------------
  def self.scroll_down?
    return Mouse.scroll < 0 if $RGD
    return false 
  end
end

#===============================================================================
# ○ 鼠标触发事件
#===============================================================================
class Sprite_Character < Sprite_Base
  #--------------------------------------------------------------------------
  # ● 更新其它内容
  #--------------------------------------------------------------------------
  alias eagle_mouse_ex_update_other update_other
  def update_other
    eagle_mouse_ex_update_other
    # 当事件执行时，不判定
    return if $game_map.interpreter.running?
    # 当鼠标移动到事件上，且按下左键时，触发它
    if MOUSE_EX.up?(:ML) && @character.is_a?(Game_Event) && mouse_in?(true, false)
      @character.start
      # 被触发的事件朝向玩家
      @character.turn_to_character($game_player)
      # 玩家朝向被触发的事件
      $game_player.turn_to_character(@character)
      # 计算了被触发事件与玩家之间的距离
      d = @character.distance_to_character($game_player)
      # 可传入变量中，然后在事件指令里判定距离，如果过大则提示太远并中止事件执行
      #$game_variables[1] = d
    end
  end
end
class Game_Character
  #--------------------------------------------------------------------------
  # ● 朝向指定角色
  #--------------------------------------------------------------------------
  def turn_to_character(character)
    dx = (self.x - character.x)
    dy = (self.y - character.y)
    if dx.abs > dy.abs
      dx < 0 ? set_direction(6) : set_direction(4)
    else
      dy < 0 ? set_direction(2) : set_direction(8)
    end
  end
  #--------------------------------------------------------------------------
  # ● 计算与指定角色之间的距离
  #--------------------------------------------------------------------------
  def distance_to_character(character)
    dx = (self.x - character.x).abs
    dy = (self.y - character.y).abs
    return dx + dy
  end
end

#===============================================================================
# ○ 鼠标兼容选择窗口
#===============================================================================
class Window_Selectable < Window_Base
  attr_accessor  :flag_mouse_in_win_when_ok
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #-------------------------------------------------------------------------
  alias eagle_mouse_init initialize
  def initialize(x, y, width, height)
    # 新增一个标记，用于处理鼠标按左键确定的逻辑：
    #   该标记为 true 时，鼠标必须在窗口内，按确定键才执行 process_ok ，
    #         如果鼠标按左键时在窗口外，则为触发 unselect 方法，即取消光标
    #   该标记为 false 时，鼠标按左键必定触发当前选项的 process_ok
    @flag_mouse_in_win_when_ok = false
    # 新增一个标记，用于处理鼠标移动到选项上进行选择时，是否考虑选项的可见性
    #   该标记为 true 时，选项必须可见，才能被鼠标选择
    #   该标记为 false 时，哪怕选项在窗口外，也能被鼠标选择，并将该选项自动移入窗口
    @flag_mouse_select_when_visible = true
    # 新增一个标识，用于处理鼠标移出窗口时，是否将光标移除
    #   该标记为 true 时，鼠标移出窗口时，执行一次 unselect，下次移入前不会重复执行
    #   该标记为 false 时，不管鼠标在哪里，窗口光标都正常处于选择中
    @flag_mouse_unselect_when_out = false
    # 新增一个标识，用于隐藏RGSS的窗口光标
    @flag_no_cursor = false
    # 新增一个标识，用于判定鼠标滚轮是否需要在窗口内部，才能触发切换选项
    @flag_mouse_scroll_in_win = false
    
    # 存储上一帧鼠标位置
    @last_mouse_x = 0
    @last_mouse_y = 0
    
    eagle_mouse_init(x, y, width, height)
  end
  #--------------------------------------------------------------------------
  # ● 处理光标的移动
  #--------------------------------------------------------------------------
  #alias eagle_mouse_process_cursor_move process_cursor_move
  def process_cursor_move
    return unless cursor_movable?
    last_index = @index
    cursor_down (Input.trigger?(:DOWN))  if Input.repeat?(:DOWN)
    cursor_up   (Input.trigger?(:UP))    if Input.repeat?(:UP)
    cursor_right(Input.trigger?(:RIGHT)) if Input.repeat?(:RIGHT)
    cursor_left (Input.trigger?(:LEFT))  if Input.repeat?(:LEFT)
    cursor_pagedown   if !handle?(:pagedown) && Input.trigger?(:R)
    cursor_pageup     if !handle?(:pageup)   && Input.trigger?(:L)
    # 新增鼠标滚轮
    f = mouse_in?
    if !@flag_mouse_scroll_in_win || (@flag_mouse_scroll_in_win && f)
      cursor_up   (true) if MOUSE_EX.scroll_up?
      cursor_down (true) if MOUSE_EX.scroll_down?
    end
    # 新增鼠标选择
    process_eagle_mouse_selection if f
    return unselect if @flag_mouse_unselect_when_out && @index >= 0 && !f
    Sound.play_cursor if @index != last_index
  end
  #--------------------------------------------------------------------------
  # ● 处理鼠标选择光标
  #--------------------------------------------------------------------------
  def process_eagle_mouse_selection
    # 如果鼠标没发生移动，则不重复处理
    return if MOUSE_EX.x == @last_mouse_x && @last_mouse_y == MOUSE_EX.y
    @last_mouse_x = MOUSE_EX.x; @last_mouse_y = MOUSE_EX.y
    # 逐个选项查看是否被鼠标选中
    item_max.times do |i|
      r = item_rect_for_text(i)
      if @flag_mouse_select_when_visible  # 选项必须位于窗口中，才能被鼠标选择
        next if r.x - self.ox < 0 || r.y - self.oy < 0 
        next if r.x - self.ox + r.width > self.width-standard_padding*2
        next if r.y - self.oy + r.height > self.height-standard_padding*2
      end
      # 计算选项的RGSS全局坐标
      r.x += self.x - self.ox + standard_padding
      r.y += self.y - self.oy + standard_padding
      break select(i) if MOUSE_EX.in?(r)
    end
  end
  #--------------------------------------------------------------------------
  # ● 解除项目的选择
  #--------------------------------------------------------------------------
  def unselect
    return if @index == -1  # 不要重复处理
    self.index = -1
  end
  #--------------------------------------------------------------------------
  # ● “确定”和“取消”的处理
  #--------------------------------------------------------------------------
  alias eagle_mouse_process_handling process_handling
  def process_handling
    process_mouse_handling
    eagle_mouse_process_handling
  end
  #--------------------------------------------------------------------------
  # ● 处理鼠标按键
  #--------------------------------------------------------------------------
  def process_mouse_handling
    return unless open? && active
    if @flag_mouse_in_win_when_ok 
      f = mouse_in?(false)
      if MOUSE_EX.up?(:ML)
        if !f # 如果鼠标在窗口外，则无任何动作
          #unselect # 或取消光标选择
        else  # 如果鼠标在窗口内，则触发确定
          process_ok if ok_enabled? 
        end
      end
    else
      if MOUSE_EX.up?(:ML)
        process_ok if ok_enabled? 
      end
    end
    if MOUSE_EX.up?(:MR)
      process_cancel if cancel_enabled?
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新光标
  #--------------------------------------------------------------------------
  alias eagle_mouse_update_cursor update_cursor
  def update_cursor
    return cursor_rect.empty if @flag_no_cursor
    eagle_mouse_update_cursor
  end
end

#===============================================================================
# ○ 地图上用鼠标右键打开菜单
#===============================================================================
class Scene_Map
  #--------------------------------------------------------------------------
  # ● 监听取消键的按下。如果菜单可用且地图上没有事件在运行，则打开菜单界面。
  #--------------------------------------------------------------------------
  alias eagle_mouse_ex_update_call_menu update_call_menu
  def update_call_menu
    if $game_system.menu_disabled || $game_map.interpreter.running?
      @menu_calling = false
    else
      @menu_calling ||= Input.trigger?(:B)
      @menu_calling = true if MOUSE_EX.up?(:MR)  # 新增
      call_menu if @menu_calling && !$game_player.moving?
    end
  end
end

#===============================================================================
# ○ 在Scene中立即把鼠标定位至指令框
#===============================================================================
module MOUSE_EX
  #--------------------------------------------------------------------------
  # ● 将鼠标移动到指定的指令窗口内
  #--------------------------------------------------------------------------
  def self.to_command_window(w)
    return if w.nil?
    # 该窗口需要已激活
    return if w.active == false 
    # 把鼠标移动到窗口当前选项上
    if w.index >= 0
      r = w.cursor_rect
      _x = w.x + w.standard_padding + r.x + r.width / 2
      _y = w.y + w.standard_padding + r.y + r.height / 2
      set_to(_x, _y)
    end
  end
end
#--------------------------------------------------------------------------
# ● 打开标题时
#--------------------------------------------------------------------------
class Scene_Title
  #--------------------------------------------------------------------------
  # ● 开始后处理
  #--------------------------------------------------------------------------
  alias eagle_mouse_ex_post_start post_start
  def post_start
    eagle_mouse_ex_post_start
    MOUSE_EX.to_command_window(@command_window)
  end
end
#--------------------------------------------------------------------------
# ● 打开菜单时
#--------------------------------------------------------------------------
#~ class Scene_Menu
#~   #--------------------------------------------------------------------------
#~   # ● 开始后处理
#~   #--------------------------------------------------------------------------
#~   alias eagle_mouse_ex_post_start post_start
#~   def post_start
#~     eagle_mouse_ex_post_start
#~     MOUSE_EX.to_command_window(@command_window)
#~   end
#~ end
#--------------------------------------------------------------------------
# ● 打开游戏结束界面时
#--------------------------------------------------------------------------
class Scene_End
  #--------------------------------------------------------------------------
  # ● 开始后处理
  #--------------------------------------------------------------------------
  alias eagle_mouse_ex_post_start post_start
  def post_start
    eagle_mouse_ex_post_start
    MOUSE_EX.to_command_window(@command_window)
  end
end

#===============================================================================
# ○ 兼容默认对话框
#===============================================================================
class Window_Message
  #--------------------------------------------------------------------------
  # ● 监听“确定”键的按下，更新快进的标志
  #--------------------------------------------------------------------------
  alias eagle_mouse_ex_update_show_fast update_show_fast
  def update_show_fast
    eagle_mouse_ex_update_show_fast
    @show_fast = true if MOUSE_EX.up?(:ML)
  end
  #--------------------------------------------------------------------------
  # ● 处理输入等待
  #--------------------------------------------------------------------------
  alias eagle_mouse_ex_input_pause input_pause
  def input_pause
    self.pause = true
    wait(10)
    Fiber.yield until Input.trigger?(:B) || Input.trigger?(:C) || 
      MOUSE_EX.up?(:ML) || MOUSE_EX.up?(:MR)
    Input.update
    self.pause = false
  end
end
