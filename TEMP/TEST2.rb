
module BUTTON
  #--------------------------------------------------------------------------
  # ● 创建一个新的按钮并绑定
  #--------------------------------------------------------------------------
  # sym    Symbol 唯一标识符
  # settings  Hash 精灵相关参数
  #   :axis => Symbol 【可选】绑定位置（默认屏幕）
  # params   Hash 接触判定相关参数
  #   type => {    # 接触判定类型 => 接触判定时机与所执行方法
  #     time_sym => { :method => method, :eval => "" }
  #   }
  def self.new(sym, settings = {}, params = {})
    s = new_sprite(Button, settings)
    params.each { |t, ps| ps.each { |tt, pss| s.bind_touch(t, tt, pss) } }
    add_sprite(sym, s)
  end
  #--------------------------------------------------------------------------
  # ● 读取指定按钮对象
  #--------------------------------------------------------------------------
  def self.[](sym)
    @buttons_all[sym] || @buttons_map[sym] || nil
  end
  #--------------------------------------------------------------------------
  # ● 生成新的按钮精灵，并设置属性
  #--------------------------------------------------------------------------
  def self.new_sprite(button_class = Button, settings = {})
    button_class = Button
    s = button_class.new(nil)
    s.bind_axis(settings[:axis]) if settings[:axis] # 绑定显示轴
    s.bitmap = Cache.system(settings[:bitmap]) if settings[:bitmap]
    s.set_xy(settings[:x], settings[:y])
    s.z = settings[:z] || 100
    s
  end
  #--------------------------------------------------------------------------
  # ● 绑定按钮精灵
  #--------------------------------------------------------------------------
  def self.add_sprite(sym, sprite)
    if sprite.respond_to?(:axis) && sprite.axis == :map
      @buttons_map[sym] = sprite
    else
      @buttons_all[sym] = sprite
    end
  end
  #--------------------------------------------------------------------------
  # ● 删去绑定
  #--------------------------------------------------------------------------
  def self.delete(sym, f_dispose = true)
    if @buttons_all[sym]
      @buttons_all[sym].dispose if f_dispose
      @buttons_all.delete_key(sym)
    end
    if @buttons_map[sym]
      @buttons_map[sym].dispose if f_dispose
      @buttons_map.delete_key(sym)
    end
  end
  #--------------------------------------------------------------------------
  # ● 模块初始化
  #--------------------------------------------------------------------------
  def self.init
    # 一直显示（跨Scene）
    @buttons_all = {} # key => Sprite
    # 当离开地图时隐藏，返回时再显示
    @buttons_map = {}
  end
  #--------------------------------------------------------------------------
  # ● 模块更新
  #--------------------------------------------------------------------------
  def self.update
    @buttons_all.each { |k, s| s.update; s.update_button }
  end
end # end of BUTTON

BUTTON.init # TODO

class Scene_Base
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  alias eagle_button_update_basic update_basic
  def update_basic
    eagle_button_update_basic
    BUTTON.update
  end
end

class Button < Sprite
  attr_reader :axis
  attr_accessor :active
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize(viewport = nil)
    super(viewport)
    bind_axis
    @x0 = @y0 = 0 # 位置坐标的原点（屏幕坐标）（默认为屏幕坐标的左上角）
    @x_ = @y_ = 0 # 相对原点的i显示位置
    @touchs = {} # type => { }
    @active = true # 是否允许判定
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    self.bitmap.dispose if self.bitmap
    super
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
  # ● 绑定显示的坐标（默认的x与y基于此更新）
  #--------------------------------------------------------------------------
  def set_xy(x_, y_)
    # 相对于坐标轴的显示原点位置
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
  #   :start  刚从未接触到接触时
  #   :on     一直接触时
  #   :click  接触并按下确定键时
  #   :end    接触结束时
  # params  Hash 参数组
  #   :method => method(:sym) 时机达成时，执行的方法
  #   :eval   => eval_string  时机达成时，执行的字符串
  # f_merge  Bool 是否以上一次的参数组为初值
  def bind_touch(type, time_type, params = {}, f_merge = false)
    @touchs[type] ||= {}
    if( f_merge )
      @touchs[type][time_type] ||= {}
      @touchs[type][time_type].merge!( params )
    else
      @touchs[type][time_type] = params
    end
    @touchs[type][:f_last_touch] = false
  end
  #--------------------------------------------------------------------------
  # ● 删去接触方法
  #--------------------------------------------------------------------------
  def delete_touch(type, time_type = nil)
    if( time_type )
      @touchs[type].delete_key(time_type)
    else
      @touchs.delete_key(type)
    end
  end
  #--------------------------------------------------------------------------
  # ● 绑定接触判定方法
  #--------------------------------------------------------------------------
  #  cond   => eval_string  判定是否接触成功的字符串
  #     a 代表自身， b 代表接触判定的目标对象
  #     eval后返回值为 true ，代表接触成功
  #    传入 nil 则按类调用默认的接触判定方法
  def bind_cond(type, cond = nil)
    @touchs[type].delete_key(:cond)
    @touchs[type][:cond] = cond if cond
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
    update_axis
    update_xy
  end
  #--------------------------------------------------------------------------
  # ● 更新坐标轴（转换为屏幕坐标）
  #--------------------------------------------------------------------------
  def update_axis
    if @axis == :map && SceneManager.scene_is?(Scene_Map)
      @x0 = 0 - $game_map.display_x * 32
      @y0 = 0 - $game_map.display_y * 32
    else
      @x0 = @y0 = 0
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新坐标
  #--------------------------------------------------------------------------
  def update_xy
    self.x = @x0 + @x_
    self.y = @y0 + @y_
  end
  #--------------------------------------------------------------------------
  # ● 更新按钮判定
  #--------------------------------------------------------------------------
  # 当作为按钮精灵时，额外进行的更新
  #  只在BUTTON模块内部调用
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
          call_method(k, v[:start]) if v[:start]
        else
          call_method(k, v[:on]) if v[:on]
          call_method(k, v[:click]) if v[:click] && Input.trigger?(:C)
        end
      else # 上一帧true，本帧false，激活接触结束时方法
        call_method(k, v[:end]) if v[:f_last_touch] == true && v[:end]
      end
      @touchs[k][:f_last_touch] = f_touch
    end
  end
  #--------------------------------------------------------------------------
  # ● 呼叫绑定方法
  #--------------------------------------------------------------------------
  def call_method(type, v)
    v[:method].call if v[:method]
    eval_string(type, v[:eval]) if v[:eval]
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
  #  （自身坐标已经转换为屏幕坐标系）
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
    return false
  end
  #--------------------------------------------------------------------------
  # ● 在矩形区域内？
  #--------------------------------------------------------------------------
  def in_self_rect?(x, y)
    x_ = self.x - self.ox
    y_ = self.y - self.oy
    return false if x < x_ || x > x_ + self.width
    return false if y < y_ || y > y_ + self.height
    return true
  end
end # end of class
