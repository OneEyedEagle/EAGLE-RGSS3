#==============================================================================
# ■ 计时器扩展 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
$imported ||= {}
$imported["EAGLE-TimerEX"] = true
#=============================================================================
# - 2019.6.2.11 新增控制
#=============================================================================
# - 本插件对计时器进行了扩展（但不改动默认计时器）
#-----------------------------------------------------------------------------
# - 创建一个新的计时器：
#     $game_timer[id].start(count[, params])
#  【参数】
#    id     → 该计时器的唯一标识符，推荐使用方便记忆的字符串、数字等
#    count  → 倒计时的总帧数（在默认系统中 1秒 = 60帧）
#    params → 【可选】扩展参数的Hash
#  【扩展参数】
#     :map  → 是否只在地图场景上进行更新
#     :sid  → 与 sid 号开关绑定；记录倒计时开始时开关状态，倒计时结束时反转开关
#     :eval → 当倒计时结束时，将会执行的脚本字符串
#     :icon → 显示在倒计时文本后面的图标的index
#     :text → 一句话的文本介绍，将会显示在倒计时文本下方
#
# - 示例：
#     $game_timer[1].start(5 * 60, {:sid => 2})
#   → 开始标识符为 1 的计时器，5s的倒计时结束后，2号开关取倒计时开始时它的反值
#
#     $game_timer["逃跑"].start(10 * 60, {:icon => 121, :eval => "v[1]+=1"})
#   → 开始标识符为 "逃跑" 的 10s 计时器，显示121号图标，倒计时结束1号变量自加1
#
#     $game_timer[:test].start(60 * 60, {:map => true, :text => "测试用文本"})
#   → 开始标识符为 :test 的 1min 计时器，显示 测试用文本 简介
#-----------------------------------------------------------------------------
# - 对计时器进行控制：
#     $game_timer[id].stop → 强制结束id标识符的计时器
#     $game_timer[id].halt → 暂停id标识符的计时器
#     $game_timer[id].continue → 继续id标识符的计时器
#     $game_timer.halt_all → 全部暂停（不含默认计时器）
#     $game_timer.continue_all → 全部继续（不含默认计时器）
#
#     $game_timer.halt → 暂停默认计时器
#     $game_timer.continue → 继续默认计时器
#=============================================================================

class Game_Timer_EX
  attr_reader :params, :display, :no_update
  attr_accessor :need_refresh
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize
    start(0)
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    if @params[:map] && !SceneManager.scene_is?(Scene_Map) # 不更新
      @no_update = true
      return @need_refresh = true
    end
    if !working?
      return if @count > 0 # 单纯的暂停
      return if (@count_temp -= 1) > 0 # 结束后的暂停
      return @display = false
    end
    @no_update = false
    @count -= 1
    @need_refresh = true if @count_temp == 0
    @count_temp = (@count_temp + 1) % 60
    self.stop if @count <= 0
  end
  #--------------------------------------------------------------------------
  # ● 正在工作？
  #--------------------------------------------------------------------------
  def working?
    @working == true
  end
  #--------------------------------------------------------------------------
  # ● 结束工作？
  #--------------------------------------------------------------------------
  def finish?
    @count == 0
  end
  #--------------------------------------------------------------------------
  # ● 开始
  #--------------------------------------------------------------------------
  def start(count, params = {})
    @params = params
    @working = true  # 正在倒计时？
    @no_update = false # 停止更新
    @display = true  # 开启显示？
    @need_refresh = true # 需要刷新显示？
    @count = count
    @count_temp = 0 # 临时用计数
    @params[:total] = count
    @params[:s] = $game_switches[ @params[:sid] ] if @params[:sid]
  end
  #--------------------------------------------------------------------------
  # ● 停止
  #--------------------------------------------------------------------------
  def stop
    @working = false
    @need_refresh = true
    @count = 0
    @count_temp = 90
    on_expire
  end
  #--------------------------------------------------------------------------
  # ● 暂停
  #--------------------------------------------------------------------------
  def halt
    @working = false
    @need_refresh = true
  end
  #--------------------------------------------------------------------------
  # ● 继续
  #--------------------------------------------------------------------------
  def continue
    @working = true
    @need_refresh = true
  end
  #--------------------------------------------------------------------------
  # ● 获取当前秒数
  #--------------------------------------------------------------------------
  def second
    @count / Graphics.frame_rate
  end
  #--------------------------------------------------------------------------
  # ● 获取当前毫秒数
  #--------------------------------------------------------------------------
  def msec
    f = @count - self.second * Graphics.frame_rate
    # 3 帧 = 50 ms
    #f * 50 / 3
    f * 17 - f / 3
  end
  #--------------------------------------------------------------------------
  # ● 计时器为 0 时的处理
  #--------------------------------------------------------------------------
  def on_expire
    $game_switches[ @params[:sid] ] = !@params[:s] if @params[:sid]
    s = $game_switches; v = $game_variables
    eval( @params[:eval] ) if @params[:eval]
  end
end
#==============================================================================
# ○ Game_Timer
#==============================================================================
class Game_Timer
  attr_reader :timers_ex
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  alias eagle_timer_ex_init initialize
  def initialize
    eagle_timer_ex_init
    @timers_ex = {}
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  alias eagle_timer_ex_update update
  def update
    eagle_timer_ex_update
    @timers_ex.each { |id, d| d.update }
  end
  #--------------------------------------------------------------------------
  # ● 暂停
  #--------------------------------------------------------------------------
  def halt
    @working = false
  end
  #--------------------------------------------------------------------------
  # ● 继续
  #--------------------------------------------------------------------------
  def continue
    @working = true
  end
  #--------------------------------------------------------------------------
  # ● 获取扩展计时器
  #--------------------------------------------------------------------------
  def [](id)
    @timers_ex[id] ||= Game_Timer_EX.new
    @timers_ex[id]
  end
  #--------------------------------------------------------------------------
  # ● 扩展计时器全部暂停
  #--------------------------------------------------------------------------
  def halt_all
    @timers_ex.each { |id, d| d.halt }
  end
  #--------------------------------------------------------------------------
  # ● 扩展计时器全部继续
  #--------------------------------------------------------------------------
  def continue_all
    @timers_ex.each { |id, d| d.continue }
  end
end
#==============================================================================
# ○ Sprite_Timer
#==============================================================================
class Sprite_Timer < Sprite
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  alias eagle_timer_ex_init initialize
  def initialize(viewport)
    @timers = {}
    eagle_timer_ex_init(viewport)
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  alias eagle_timer_ex_dispose dispose
  def dispose
    eagle_timer_ex_dispose
    @timers.each { |id, t| t.dispose }
    @timers.clear
  end
  #--------------------------------------------------------------------------
  # ● 显示
  #--------------------------------------------------------------------------
  def show
    @timers.each { |id, t| t.visible = true }
    self.visible = true
  end
  #--------------------------------------------------------------------------
  # ● 隐藏
  #--------------------------------------------------------------------------
  def hide
    @timers.each { |id, t| t.visible = false }
    self.visible = false
  end
  #--------------------------------------------------------------------------
  # ● 更新画面
  #--------------------------------------------------------------------------
  alias eagle_timer_ex_update update
  def update
    eagle_timer_ex_update
    update_ex_new
    update_ex_position
  end
  #--------------------------------------------------------------------------
  # ● 新加入计数器精灵
  #--------------------------------------------------------------------------
  def update_ex_new
    $game_timer.timers_ex.each do |id, t|
      next if @timers.has_key?(id) || !t.working?
      @timers[id] = Sprite_Timer_EX.new(@viewport, id, -1)
      @timers[id].z = 200
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新显示位置
  #--------------------------------------------------------------------------
  def update_ex_position
    # 从屏幕左上角开始，逐渐向下增加
    index = -1 # 用于暂存当前屏幕坐标index
    @timers.each do |id, t|
      t.visible = $game_timer[id].display
      next if !t.visible
      t.update
      index += 1
      next if t.window_index == index # 位置不需要变动
      t.window_index = index
      _y = 50 + (t.height + 4) * t.window_index
      if t.flag_new # 对于新创建的精灵，调整坐标
        t.flag_new = false
        t.set_xy(Graphics.width, _y)
      end
      t.set_des_xy(Graphics.width - t.width, _y)
    end
  end
end
#==============================================================================
# ○ Sprite_Timer_EX
#==============================================================================
class Sprite_Timer_EX < Sprite
  attr_accessor :window_index, :flag_new
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize(viewport, id, index)
    @flag_new = true
    super(viewport)
    @id = id
    @window_index = index
    create_bitmap
    set_des_xy(0, 0)
    update
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    self.bitmap.dispose
    super
  end
  #--------------------------------------------------------------------------
  # ● 生成位图
  #--------------------------------------------------------------------------
  def create_bitmap
    self.bitmap = Bitmap.new(130, 48)
    @bg_bitmap = Bitmap.new(self.width, self.height)
    # 生成背景
    @bg_bitmap.gradient_fill_rect(@bg_bitmap.rect,
      Color.new(0,0,0,0), Color.new(0,0,0))
  end
  #--------------------------------------------------------------------------
  # ● 绘制图标
  #     enabled : 有效的标志。false 的时候使用半透明效果绘制
  #--------------------------------------------------------------------------
  def draw_icon(bitmap, icon_index, x, y, enabled = true)
    _bitmap = Cache.system( "Iconset")
    rect = Rect.new(icon_index % 16 * 24, icon_index / 16 * 24, 24, 24)
    bitmap.blt(x, y, _bitmap, rect, enabled ? 255 : 120)
  end
  #--------------------------------------------------------------------------
  # ● 设置实际坐标，会重置目的xy
  #--------------------------------------------------------------------------
  def set_xy(x, y)
    self.x = @des_x = x
    self.y = @des_y = y
  end
  #--------------------------------------------------------------------------
  # ● 设置目的坐标
  #--------------------------------------------------------------------------
  def set_des_xy(x, y)
    @des_x = x
    @des_y = y
  end
  #--------------------------------------------------------------------------
  # ● 更新画面
  #--------------------------------------------------------------------------
  def update
    super
    update_bitmap
    update_xy
  end
  #--------------------------------------------------------------------------
  # ● 重绘
  #--------------------------------------------------------------------------
  def update_bitmap
    return if !$game_timer[@id].need_refresh
    $game_timer[@id].need_refresh = false
    self.bitmap.clear
    self.bitmap.blt(0, 0, @bg_bitmap, self.bitmap.rect)

    icon = $game_timer[@id].params[:icon]
    t = $game_timer[@id].params[:text]
    cy = t ? 0 : 10 # 偏移倒计时文本
    w = icon ? self.width - 30 : self.width - 15

    # 绘制倒计时文本
    self.bitmap.font.size = 24
    self.bitmap.font.color.set(255, 255, 255)
    if !$game_timer[@id].working? || $game_timer[@id].no_update
      self.bitmap.font.color.alpha = 100
    end
    sec = $game_timer[@id].second + 1 # 0~1秒之间，显示为1s
    sec = 0 if $game_timer[@id].finish?
    text = sprintf("%02d:%02d", sec / 60, sec % 60)
    self.bitmap.draw_text(0, cy, w, 24, text, 2)

    if icon # 绘制图标
     icon_v = $game_timer[@id].working? # 如果停止工作/不更新，则半透明绘制
     icon_v = false if $game_timer[@id].no_update
     draw_icon(bitmap, icon, self.width-24-3, cy, icon_v)
    end
    if $game_timer[@id].finish? # 绘制删除线
      bitmap.fill_rect(self.width-95-2, cy+13, 95, 1, Color.new(180,180,180))
    end
    if t # 绘制简介
      self.bitmap.font.size = 12
      self.bitmap.font.color.set(200, 200, 200)
      self.bitmap.draw_text(0, 24, self.width, 26, t, 2)
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新位置
  #--------------------------------------------------------------------------
  def update_xy
    6.times do
      break if @des_x == self.x
      self.x += (@des_x > self.x ? 1 : -1)
    end
    5.times do
      break if @des_y == self.y
      self.y += (@des_y > self.y ? 1 : -1)
    end
  end
end
