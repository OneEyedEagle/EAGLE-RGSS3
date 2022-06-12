#==============================================================================
# ■ 地图上显示指示文本 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【组件-通用方法汇总 by老鹰】、
#     【组件-位图绘制转义符文本 by老鹰】、
#     【组件-形状绘制 by老鹰】、
#     【组件-位图绘制指示文本 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-MapHintText"] = "1.0.1"
#==============================================================================
# - 2022.6.12.17
#==============================================================================
# - 本插件新增了能够显示在地图上的指示型文本提示
#------------------------------------------------------------------------------
# 【地图：事件的指示文本】
#
# - 当事件页的第一条指令为注释，且其中包含下述类型的文本时，设置该事件页的指示文本：
#
#      <观察 tag字符串>...</观察>
#
#    其中 观察 为固定的识别文本，不可缺少
#    其中 tag字符串 与【核心：增加一个指示型文本】中的 ps1 一致
#
#      比如 dx=20 dy=30 就是设置指示文本相对于指示圆点的偏移位置为(+20,+30)
#
#    其中 ... 为显示的指示文本，可以使用转义符，比如\i[1]，\v[1]，也可用\n换行
#
# - 在玩家按下 SHIFT 键时，将搜索并生成玩家周围事件的指示文本
#     （如果使用了【按键输入扩展 by老鹰】，则改为 TAB 键）
#
#   具体搜索距离见 SEARCH_RANGE 常量，或者利用 V_ID_SEARCH_RANGE 号变量的值。
#
# - 示例：
#
#       <观察 auto=1>这是一个勤劳的人，\n可惜耳朵有点背。</观察>
#           → 在按键后，将在地图上显示该句话。
#
#------------------------------------------------------------------------------
# 【核心：增加一个指示型文本】
#
# - 利用全局脚本增加一个立即显示的指示文本精灵：
#
#    MAP_HINT.new_sprite(t, ps1, ps2)
#
#  其中 t 为需要显示的文本的字符串
#  其中 ps1 为【组件-位图绘制指示文本 by老鹰】中的参数的Hash
#
#    比如：
#        :x => 数字, :y => 数字,    # 精灵显示的位置
#        :dx => 数字, :dy => 数字,  # 位图上以指示圆点为原点，文本及划线的偏移坐标
#
#    特别的，本插件增加了下列参数：
#        :eid => 数字,  # 绑定的事件的ID，将跟随该事件移动
#        :mx => 数字,  :my => 数字,  # 绑定的地图格子的坐标，将跟随地图移动
#        :wx => 数字,  :wy => 数字,  # 绑定的屏幕坐标
#        :auto => 1,    # 当该项不为0时，将自动依据事件的屏幕位置调整dx与dy的正负，
#                       # 确保文本向屏幕中间显示
#        :sx => 数字,  :sy => 数字,  # 指示原点的坐标的额外偏移量
#                          # 默认显示位置为格子中点，请自行调整更精确的显示位置
#
#    坐标显示的优先级为： 绑定事件 > 绑定地图格子 > 屏幕坐标
#
#  其中 ps2 为【组件-位图绘制转义符文本 by老鹰】中的参数的Hash
#
#==============================================================================
module MAP_HINT
  #--------------------------------------------------------------------------
  # ○【常量】绑定于事件的指示型文本的背景颜色
  #--------------------------------------------------------------------------
  BG_EVENT_TEXT = nil  #Color.new(0,0,0, 150)
  #--------------------------------------------------------------------------
  # ○【常量】指示精灵在渐隐前的等待帧数
  #--------------------------------------------------------------------------
  SHOW_WAIT = 100

  #--------------------------------------------------------------------------
  # ○【常量】事件页首行注释中，用于检索是否存在观察的匹配
  #--------------------------------------------------------------------------
  COMMENT_EVENT = /<观察 *(.*?)>(.*?)<\/观察>/m
  #--------------------------------------------------------------------------
  # ○【常量】检测半径
  #--------------------------------------------------------------------------
  # 当玩家与事件距离小于等于该值时，检索事件页中设置的观察
  #--------------------------------------------------------------------------
  SEARCH_RANGE = 4
  #--------------------------------------------------------------------------
  # 如果不想把激活距离设置为固定值，可以修改该项为变量序号
  #   该序号的变量的值如果大于0，则会被读取作为距离值
  #   该序号设置为 0 时，依然取 SEARCH_RANGE 设置的固定值
  #--------------------------------------------------------------------------
  V_ID_SEARCH_RANGE = 0
  #--------------------------------------------------------------------------
  # ○【常量】当玩家在地图时，按键触发周围事件首行注释里的指示文本
  #--------------------------------------------------------------------------
  def self.call?
    return false if $game_map.interpreter.running?  # 当有事件被触发时，不激活
    if $imported["EAGLE-InputEX"]
      return Input_EX.trigger?(:TAB)
    end
    Input.trigger?(:A)
  end

  #--------------------------------------------------------------------------
  # ● 初始化事件的指示精灵的参数
  #--------------------------------------------------------------------------
  def self.check_event_params(event, ps1, ps2)
    ps1[:dx] ||= 40   # 此处设置默认的 dx 和 dy
    ps1[:dx] = ps1[:dx].to_i
    ps1[:dy] ||= 30
    ps1[:dy] = ps1[:dy].to_i
    if ps1[:auto] != 0
      if event.screen_x > Graphics.width / 2
        ps1[:dx] *= -1 if ps1[:dx] > 0
      else
        ps1[:dx] *= -1 if ps1[:dx] < 0
      end
      if event.screen_y > Graphics.height / 2
        ps1[:dy] *= -1 if ps1[:dy] > 0
      else
        ps1[:dy] *= -1 if ps1[:dy] < 0
      end
    end
    ps1[:sx] ||= 0
    ps1[:sy] ||= 0
    ps1[:dc] = BG_EVENT_TEXT
  end
  #--------------------------------------------------------------------------
  # ● 判定全部事件
  #--------------------------------------------------------------------------
  def self.check_events
    $game_map.events.each do |id, e|
      check_event_near(e)
    end
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
    d = (event.x - $game_player.x).abs + (event.y - $game_player.y).abs
    if $imported["EAGLE-PixelMove"]
      d = (event.rgss_x - $game_player.rgss_x).abs + \
        (event.rgss_y - $game_player.rgss_y).abs
    end
    return if d > get_search_range  # 查询的范围

    t = EAGLE_COMMON.event_comment_head(event.list)
    t.scan(COMMENT_EVENT).each do |ps|
      h = EAGLE_COMMON.parse_tags(ps[0].lstrip)
      h[:eid] ||= event.id
      h2 = {}
      check_event_params(event, h, h2)
      new_sprite(ps[1], h, h2)
    end
  end
end
#=============================================================================
# ■ Scene_Map
#=============================================================================
class Scene_Map
  #--------------------------------------------------------------------------
  # ● 更新画面
  #--------------------------------------------------------------------------
  alias eagle_map_hint_update update
  def update
    MAP_HINT.check_events if MAP_HINT.call?
    eagle_map_hint_update
  end
end

#=============================================================================
# ■ 核心：显示指示精灵
#=============================================================================
module MAP_HINT
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def self.init
    @sprites = []
    @sprites_valid = []
  end
  #--------------------------------------------------------------------------
  # ● 创建一个显示精灵
  #--------------------------------------------------------------------------
  def self.new_sprite(t, ps1, ps2 = {})
    if ps1[:eid]  # 特殊情况：如果绑定到事件，则检查下是否已经有在显示的
      @sprites.each { |s| return s.start if s.same?(t, ps1) }
    end

    s = nil
    if @sprites_valid.empty?
      s = Sprite_HintText.new(t, ps1, ps2)
    else
      s = @sprites_valid.pop
      s.reset(t, ps1, ps2)
    end
    @sprites.push(s) if s
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def self.update
    @sprites.each do |s|
      s.update
      @sprites_valid.push(s) if s.finish?
    end
    @sprites.delete_if { |s| s.finish? }
  end
  #--------------------------------------------------------------------------
  # ● 全部结束
  #--------------------------------------------------------------------------
  def self.finish
    @sprites.each { |s| s.dispose }
    @sprites.clear
  end
#=============================================================================
# ■ 指示精灵
#=============================================================================
class Sprite_HintText < Sprite
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(t, ps1, ps2 = {})
    super(nil)
    reset(t, ps1, ps2)
  end
  #--------------------------------------------------------------------------
  # ● 参数相同？
  #--------------------------------------------------------------------------
  def same?(t, ps1)
    @t == t && ps1[:eid] == @ps1[:eid] && \
    ps1[:dx] == @ps1[:dx] && ps1[:dy] == @ps1[:dy]
  end
  #--------------------------------------------------------------------------
  # ● 复用时重置
  #--------------------------------------------------------------------------
  def reset(t, ps1, ps2 = {})
    @t = t
    @ps1 = ps1
    @ps1[:eid] = @ps1[:eid].to_i
    @ps1[:mx] = @ps1[:mx].to_i
    @ps1[:my] = @ps1[:my].to_i
    @ps1[:wx] = @ps1[:wx].to_i
    @ps1[:wy] = @ps1[:wy].to_i
    @ps1[:sx] = @ps1[:sx].to_i
    @ps1[:sy] = @ps1[:sy].to_i
    @ps2 = ps2
    self.bitmap.dispose if self.bitmap
    EAGLE.draw_hint_text(self, @t, @ps1, @ps2)
    start
  end
  #--------------------------------------------------------------------------
  # ● 开始显示
  #--------------------------------------------------------------------------
  def start
    self.z = 200
    self.opacity = 255
    self.visible = true
    @count = 0
    @count_max = 180
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    self.bitmap.dispose
    super
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
    update_position
    update_out
  end
  #--------------------------------------------------------------------------
  # ● 更新绑定位置
  #--------------------------------------------------------------------------
  def update_position
    if @ps1[:eid]
      e = EAGLE_COMMON.get_chara(nil, @ps1[:eid])
      return if e.nil?
      self.x = e.screen_x
      self.y = e.screen_y - 16
    elsif @ps1[:mx] || @ps1[:my]
      self.x = $game_map.adjust_x(@ps1[:mx]) * 32 + 16
      self.y = $game_map.adjust_x(@ps1[:my]) * 32 + 16
    elsif @ps1[:wx] || @ps1[:wy]
      self.x = @ps1[:wx]
      self.y = @ps1[:wy]
    end
    self.x += @ps1[:sx]
    self.y += @ps1[:sy]
  end
  #--------------------------------------------------------------------------
  # ● 结束？
  #--------------------------------------------------------------------------
  def finish?
    self.visible == false
  end
  #--------------------------------------------------------------------------
  # ● 移出
  #--------------------------------------------------------------------------
  def update_out
    @count += 1
    return if @count < MAP_HINT::SHOW_WAIT
    v = (@count-MAP_HINT::SHOW_WAIT) * 1.0 / (@count_max-MAP_HINT::SHOW_WAIT)
    self.opacity = 255 - 255 * ease_value(v)
    self.visible = false if @count >= @count_max
  end
  #--------------------------------------------------------------------------
  # ● 缓动函数
  #--------------------------------------------------------------------------
  def ease_value(x)
    x * x
  end
end
end  # end of Module
#=============================================================================
# ■ DataManager
#=============================================================================
class << DataManager
  #--------------------------------------------------------------------------
  # ● 初始化模块
  #--------------------------------------------------------------------------
  alias eagle_map_hint_init init
  def init
    MAP_HINT.init
    eagle_map_hint_init
  end
end
#=============================================================================
# ■ Scene_Base
#=============================================================================
class Scene_Base
  #--------------------------------------------------------------------------
  # ● 更新画面（基础）
  #--------------------------------------------------------------------------
  alias eagle_map_hint_update_basic update_basic
  def update_basic
    MAP_HINT.update
    eagle_map_hint_update_basic
  end
end
