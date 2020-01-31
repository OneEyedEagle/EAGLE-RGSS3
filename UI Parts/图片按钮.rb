#==============================================================================
# ■ 图片按钮 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
$imported ||= {}
$imported["EAGLE-Button"] = true
#=============================================================================
# - 2019.8.9.17
#=============================================================================
# - 新增能创建图片精灵，并绑定相应接触触发方法的模块
#-----------------------------------------------------------------------------
# ○ 模块方法
#-----------------------------------------------------------------------------
# - 绑定图片精灵
#
#     BUTTON.new(sym, settings, touch_params)
#
#   sym → 唯一标识符，推荐使用Symbol类型，相同标识符的图片将会直接覆盖
#
#   settings → 精灵参数预设，Hash类型
#     :scene => Scene_Class 绑定显示的场景（nil时为在任何场景中均显示）
#     :axis => Symbol 绑定显示的坐标轴
#        :screen → （默认）屏幕左上角为显示原点，向右为x轴正向，向下为y轴正向
#        :map → 地图左上角为显示原点，向右为x轴正向，向下为y轴正向
#        若绑定在地图上，则在地图变换后，原地图上的图片精灵将自动删除
#     :x/:y => Int 相对于坐标组原点的所在位置（像素）
#        若绑定在地图上，则为地图格子的坐标
#     :z => Int 精灵所处z值
#        若绑定在地图上，则地图图块z值为0，玩家同层z值100，玩家上层的事件z值200
#     :bitmap => Filename 位于 Graphics/System 目录下所用位图文件的名称
#
#   touch_params → 接触判定的绑定，Hash类型 { type => { time_type => eval_str } }
#     type 为 Symbol 类型，表示该接触判定的类型
#       :mouse    检测与鼠标的接触
#       :event_id 检测与当前地图的id号事件的接触
#       :player   检测与玩家队伍队首的接触
#       :chara_id 检测与玩家队列中的第id位角色的接触
#     time_type 为 Symbol类型，表示接触的时机
#       :start  未接触到接触时
#       :on     一直接触时（每一帧调用）
#       :click  接触并按下确定键时
#       :end    接触结束时
#     eval_str  String 满足当前时机时，所执行的字符串
#
# - 删去图片精灵
#
#     BUTTON.delete(sym[, f_dispose])
#
#   f_dispose →（可选）是否释放，默认释放
#
# - 获取图片精灵的实例对象
#
#     BUTTON[sym]
#
# -【进阶】为指定图片精灵的实例对象sprite 绑定自定义的接触判定方法
#   （默认接触判定方法：目标对象的显示原点是否在图片精灵的矩形内部）
#
#     sprite.bind_cond(touch_type, eval_cond)
#
#    touch_type → 接触判定的类型
#
#    eval_cond  → eval(eval_cond)的返回值为 true 时，代表接触判定成功
#        其中可用 a 代表自身， b 代表接触判定的目标事件对象
#       （默认）传入 nil 代表删去自定义的接触判定方法
#
#-----------------------------------------------------------------------------
# ○ 示例
#-----------------------------------------------------------------------------
# ss = { :bitmap => "filename", :x => 6, :y => 5, :axis => :map }
# ps = { :mouse => { :on => "v[1]+=1" },
#        :player => { :click => "v[2]+=1" },
#        :event_1 => { :start => "v[3]+=1;b.start" }, }
# BUTTON.new(:test, ss, ps)
#
#  → 在当前地图上的(6,5)处显示一个以 :test 为标识符的图片精灵，
#     当鼠标停留在上面时，每一帧中，1号变量自增1，
#     当玩家的行走图在上面时，且按下确定键，2号变量自增1，
#     当1号事件的行走图到达上面时，3号变量自增1，且执行1号事件
#=============================================================================

module BUTTON
  #--------------------------------------------------------------------------
  # ● 创建一个新的按钮并绑定
  #--------------------------------------------------------------------------
  # sym    Symbol 唯一标识符
  # settings  Hash 精灵相关参数
  # params   Hash 接触判定相关参数
  #   type => {    # 接触判定类型 => 接触判定时机与所执行方法
  #     time_sym => eval_str
  #   }
  #--------------------------------------------------------------------------
  def self.new(sym, settings = {}, touch_params = {})
    s = new_sprite(settings)
    touch_params.each { |t, ps| ps.each { |tt, pss| s.bind_touch(t, tt, pss) } }
    add_sprite(sym, s)
    s.update
  end
  #--------------------------------------------------------------------------
  # ● 生成新的按钮精灵，并设置属性
  #--------------------------------------------------------------------------
  # settings  Hash 精灵相关参数
  # button_class Class 所使用的按钮精灵类的名称
  #--------------------------------------------------------------------------
  def self.new_sprite(settings = {}, button_class = Eagle_Button)
    s = button_class.new(nil)
    s.bind_scene(settings[:scene]) if settings[:scene]
    s.bind_axis(settings[:axis]) if settings[:axis] # 绑定显示轴
    s.set_xy(settings[:x], settings[:y])
    s.z = settings[:z] || 1
    s.bitmap = Cache.system(settings[:bitmap]) if settings[:bitmap]
    s
  end
  #--------------------------------------------------------------------------
  # ● 绑定按钮精灵
  #--------------------------------------------------------------------------
  def self.add_sprite(sym, sprite)
    if sprite.axis == :map
      if SceneManager.scene_is?( Scene_Map )
        sprite.viewport = SceneManager.scene.spriteset.viewport1
      end
      sprite.bind_scene(Scene_Map)
    else
      sprite.bind_axis(:screen)
    end
    if !(sprite.scene && sprite.scene != SceneManager.scene.class)
      SceneManager.scene.eagle_buttons[sym] = sprite
    end
    @sprites[sym] = sprite
  end
  #--------------------------------------------------------------------------
  # ● 删去绑定
  #--------------------------------------------------------------------------
  def self.delete(sym, f_dispose = true)
    if @sprites[sym]
      @sprites[sym].dispose if f_dispose
      @sprites.delete(sym)
      SceneManager.scene.eagle_buttons.delete(sym)
    end
  end
  #--------------------------------------------------------------------------
  # ● 读取指定按钮对象
  #--------------------------------------------------------------------------
  def self.[](sym)
    @sprites[sym]
  end
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def self.init
    @sprites = {} # sym => button_sprite
  end
  #--------------------------------------------------------------------------
  # ● 初始化场景中的精灵（获取引用）
  #--------------------------------------------------------------------------
  def self.init_scene
    @sprites.select { |k, s| s.scene.nil? || s.scene == SceneManager.scene.class }
  end
  #--------------------------------------------------------------------------
  # ● 删去全部在地图上的精灵
  #--------------------------------------------------------------------------
  def self.delete_map
    @sprites.keys.each { |k| delete(k) if @sprites[k].axis == :map }
  end
  #--------------------------------------------------------------------------
  # ● 删去全部精灵
  #--------------------------------------------------------------------------
  def self.delete_all
    @sprites.each { |k, s| s.dispose }
    @sprites.clear
    SceneManager.scene.eagle_buttons.clear
  end
end # end of BUTTON
#==============================================================================
# ○ Button
#==============================================================================
class Eagle_Button < Sprite
  attr_reader   :axis, :scene
  attr_accessor :active
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize(viewport = nil)
    super(viewport)
    bind_scene
    bind_axis
    @x0 = @y0 = 0 # 位置坐标的原点（屏幕坐标）（默认为屏幕坐标的左上角）
    @x_ = @y_ = 0 # 相对原点的显示位置
    @touchs = {} # type => {}
    @active = true # 是否允许判定
  end
  #--------------------------------------------------------------------------
  # ● 绑定显示的场景
  #--------------------------------------------------------------------------
  def bind_scene(scene_class = nil)
    @scene = scene_class
  end
  #--------------------------------------------------------------------------
  # ● 绑定显示的坐标轴
  #--------------------------------------------------------------------------
  def bind_axis(type = :screen)
    # :map 地图坐标轴（地图左上角原点）
    # :screen 屏幕坐标轴（左上角原点）
    @axis = type
  end
  #--------------------------------------------------------------------------
  # ● 绑定显示的坐标（实际坐标基于此更新）
  #--------------------------------------------------------------------------
  def set_xy(x_, y_)
    @x_ = x_ if x_
    @y_ = y_ if y_
  end
  #--------------------------------------------------------------------------
  # ● 绑定接触方法
  #--------------------------------------------------------------------------
  # type  Symbol 类型
  #   :mouse 绑定鼠标
  #   :event_id 绑定当前地图的id号事件
  #   :player 绑定队首（玩家控制的角色）
  #   :chara_id 绑定队列中的第id位角色
  # time_type  Symbol 执行时机
  #   :start  从未接触到接触时
  #   :on     一直接触时
  #   :click  接触并按下确定键时
  #   :end    接触结束时
  # eval_str  String
  #--------------------------------------------------------------------------
  def bind_touch(type, time_type, eval_str)
    @touchs[type] ||= {}
    @touchs[type][time_type] = eval_str
    @touchs[type][:f_last_touch] = false
  end
  #--------------------------------------------------------------------------
  # ● 删去接触方法
  #--------------------------------------------------------------------------
  def delete_touch(type, time_type = nil)
    if(time_type)
      @touchs[type].delete(time_type)
    else
      @touchs.delete(type)
    end
  end
  #--------------------------------------------------------------------------
  # ● 绑定接触判定方法
  #--------------------------------------------------------------------------
  #  cond   => eval_string  判定是否接触成功的字符串
  #    传入 nil 则按类调用默认的接触判定方法
  #    其中 a 代表自身， b 代表接触判定的目标事件对象
  #    eval(cond)的返回值为 true ，代表判定接触成功
  #--------------------------------------------------------------------------
  def bind_cond(type, cond = nil)
    @touchs[type].delete(:cond)
    @touchs[type][:cond] = cond if cond
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
    update_xy
  end
  #--------------------------------------------------------------------------
  # ● 更新坐标
  #--------------------------------------------------------------------------
  def update_xy
    if @axis == :map && SceneManager.scene_is?(Scene_Map)
      self.x = 0 - $game_map.display_x * 32 + @x_ * 32
      self.y = 0 - $game_map.display_y * 32 + @y_ * 32
    else
      self.x = @x_
      self.y = @y_
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新接触判定
  #--------------------------------------------------------------------------
  def update_button
    return if !self.visible
    return if !@active
    update_touch
  end
  #--------------------------------------------------------------------------
  # ● 更新接触
  #--------------------------------------------------------------------------
  def update_touch
    @touchs.each do |k, v|
      # k => type
      # v => { time_type => params, :cond => eval, :f_last_touch => bool }
      f_touch = check_touch?(k, v)
      if f_touch == true
        # 上一帧false，本帧true，激活接触开始方法
        if v[:f_last_touch] == false
          eval_string(k, v[:start]) if v[:start]
        else
          eval_string(k, v[:on]) if v[:on]
          eval_string(k, v[:click]) if v[:click] && Input.trigger?(:C)
        end
      else # 上一帧true，本帧false，激活接触结束时方法
        eval_string(k, v[:end]) if v[:f_last_touch] == true && v[:end]
      end
      @touchs[k][:f_last_touch] = f_touch
    end
  end
  #--------------------------------------------------------------------------
  # ● 执行字符串
  #--------------------------------------------------------------------------
  def eval_string(type, str)
    s = $game_swtiches; v = $game_variables
    a = self; b = get_character(type)
    eval(str)
  end
  #--------------------------------------------------------------------------
  # ● 获取对应事件对象
  #--------------------------------------------------------------------------
  def get_character(type)
    return $game_player if type == :player
    str = type.to_s
    if str =~ /event_(\d+)/
      return $game_map.events[$1.to_i]
    end
    if str =~ /chara_(\d+)/
      return $game_party.members[$1.to_i]
    end
    return nil
  end
  #--------------------------------------------------------------------------
  # ● 检查是否接触
  #  （只进行屏幕坐标之间的判定）
  #--------------------------------------------------------------------------
  def check_touch?(k, v)
    return (eval_string(k, v[:cond]) == true) if v[:cond]
    return touch_mouse? if k == :mouse
    chara = get_character(k)
    return touch_chara?(chara) if chara
    return false
  end
  #--------------------------------------------------------------------------
  # ● 鼠标接触？
  #--------------------------------------------------------------------------
  def touch_mouse?
    in_self_rect?(Mouse.x, Mouse.y)
  end
  #--------------------------------------------------------------------------
  # ● 事件接触？
  #--------------------------------------------------------------------------
  def touch_chara?(chara)
    in_self_rect?(chara.screen_x, chara.screen_y - 16)
  end
  #--------------------------------------------------------------------------
  # ● 在矩形区域内？
  #--------------------------------------------------------------------------
  def in_self_rect?(x, y)
    # 计算相对于实际位图的坐标（左上原点）
    rx = x - (self.x - self.ox)
    ry = y - (self.y - self.oy)
    if viewport
      rx -= self.viewport.rect.x
      ry -= self.viewport.rect.y
    end
    # 边界判定  src_rect - 该矩形内的位图为精灵 (0,0) 处显示位图
    return false if rx < 0 || ry < 0 || rx > width || ry > height
    return self.bitmap.get_pixel(rx, ry).alpha != 0
  end
end # end of class
#=============================================================================
# ○ DataManager
#=============================================================================
class << DataManager
  #--------------------------------------------------------------------------
  # ● 设置新游戏
  #--------------------------------------------------------------------------
  alias eagle_button_setup_new_game setup_new_game
  def setup_new_game
    eagle_button_setup_new_game
    BUTTON.init
  end
end
#==============================================================================
# ○ Game_Player
#==============================================================================
class Game_Player
  #--------------------------------------------------------------------------
  # ● 执行场所移动
  #--------------------------------------------------------------------------
  alias eagle_button_perform_transfer perform_transfer
  def perform_transfer
    BUTTON.delete_map if transfer? && @new_map_id != $game_map.map_id
    eagle_button_perform_transfer
  end
end
#=============================================================================
# ○ Scene_Base
#=============================================================================
class Scene_Base
  attr_reader  :eagle_buttons
  #--------------------------------------------------------------------------
  # ● 开始
  #--------------------------------------------------------------------------
  alias eagle_button_start start
  def start
    eagle_button_start
    @eagle_buttons = BUTTON.init_scene
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  alias eagle_button_update_basic update_basic
  def update_basic
    eagle_button_update_basic
    @eagle_buttons.each { |k, s| s.update; s.update_button }
  end
  #--------------------------------------------------------------------------
  # ● 结束处理
  #--------------------------------------------------------------------------
  alias eagle_button_terminate terminate
  def terminate
    eagle_button_terminate
    @eagle_buttons.clear # 由于是引用，无需释放
  end
end
#=============================================================================
# ○ Scene_Map
#=============================================================================
class Spriteset_Map; attr_reader :viewport1; end
class Scene_Map
  attr_reader :spriteset
  #--------------------------------------------------------------------------
  # ● 开始
  #--------------------------------------------------------------------------
  alias eagle_button_map_post_start post_start
  def post_start
    @eagle_buttons.each do |k, s|
      s.viewport = @spriteset.viewport1 if s.axis == :map
      s.update
    end
    eagle_button_map_post_start
  end
end
