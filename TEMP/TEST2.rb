#
module BUTTON
  # BUTTON.new(:test, {:touch => {:evals=>{:start=>"v[1]+=1"}}})
  #

  # touchs[:axis] = Symbol  【可选】
  # touchs[:touch] = { type => params }
  #   params = { :methods => {:start => method} }
  def self.new(sym, touchs = {})
    s = new_sprite(Button, touchs[:axis])
    if touchs[:touch]
      touchs[:touch].each { |t, ps| s.bind_touch(t, ps[:methods], ps[:evals], ps[:cond]) }
    end
    add_sprite(sym, s)
  end
  def self.[](sym)
    @buttons_all[sym] || @buttons_map[sym] || nil
  end
  def self.new_sprite(button_class = Button, axis = :screen)
    button_class = Button
    s = button_class.new(nil)
    s.bind_axis(axis) if axis # 绑定显示轴
    s
  end
  def self.add_sprite(sym, sprite)
    if sprite.respond_to?(:axis) && sprite.axis == :map
      @buttons_map[sym] = sprite
    else
      @buttons_all[sym] = sprite
    end
  end
  def self.delete(sym)
    if @buttons_all[sym]
      @buttons_all[sym].dispose
      @buttons_all.delete_key(sym)
    end
    if if @buttons_map[sym]
      @buttons_map[sym].dispose
      @buttons_map.delete_key(sym)
    end
  end

  def self.init
    # 一直显示（跨Scene）
    @buttons_all = {} # key => Sprite
    # 当离开地图时隐藏，返回时再显示
    @buttons_map = {}
  end
  def self.update
  end
end # end of BUTTON

class Scene_Base
end

class Button < Sprite
  attr_reader :axis
  def initialize(viewport = nil)
    super(viewport)
    bind_axis
    @x0 = @y0 = 0 # 位置坐标的原点（屏幕坐标）（默认为屏幕坐标的左上角）
    @x_ = @y_ = 0 # 相对原点的i显示位置
    @touchs = {} # type => { }
  end
  def dispose
    super
  end

  def bind_axis(type = :screen)
    # 绑定坐标轴  屏幕坐标轴（左上角原点）:screen 或 地图坐标轴（地图左上角原点）:map
    @axis = type
  end
  def set_xy(x_, y_)
    # 相对于坐标轴的显示原点位置
    @x_ = x_ if x_
    @y_ = y_ if y_
  end

  # type  Symbol
  #   :mouse 绑定鼠标
  #   :event_id 绑定当前地图的id号事件
  #   :player 绑定队首（玩家控制的角色）
  #   :chara_id 绑定队伍中的id号角色
  # methods Symbol => method(:sym)
  # evals  Symbol => eval_string
  #   :start
  #   :on
  #   :end
  #   :click
  # cond  eval_string
  #   a 代表目标对象， b 代表自身
  #   eval后返回值为true时，代表接触成功
  #   传入nil时按类调用默认的接触判定方法
  def bind_touch(type, methods = {}, evals = {}, cond = nil)
    @touchs[type] = {}
    @touchs[type][:methods] = methods || {}
    @touchs[type][:evals] = evals || {}
    @touchs[type][:cond] = cond if cond
    @touchs[type][:last_flag_touch] = false
  end
  def delete_touch(type)
    @touchs.delete_key(type)
  end

  def update
    super
    return if !self.visible
    update_axis
    update_xy
    update_touch
  end

  def update_axis
    if @axis == :map && SceneManager.scene_is?(Scene_Map)
      @x0 = 0 - $game_map.display_x * 32
      @y0 = 0 - $game_map.display_y * 32
      return
    end
    @x0 = @y0 = 0
  end
  def update_xy
    self.x = @x0 + @x_
    self.y = @y0 + @y_
  end

  def update_touch
    @touchs.each do |k, v|
      flag_touch = check_touch?(k, v)
      if flag_touch == true
        if v[:last_flag_touch] == false # 上一帧false，本帧true，激活接触开始时方法
          v[:methods][:start].call if v[:methods][:start]
          eval_string(v[:evals][:start]) if v[:evals][:start]
        else # 激活持续方法
          v[:methods][:on].call if v[:methods][:on]
          eval_string(v[:evals][:on]) if v[:evals][:on]
          if Input.trigger?(:C)
            v[:methods][:click].call if v[:methods][:click]
            eval_string(v[:evals][:click]) if v[:evals][:click]
          end
        end
      else
        if v[:last_flag_touch] == true # 上一帧true，本帧false，激活接触结束时方法
          v[:methods][:end].call if v[:methods][:end]
          eval_string(v[:evals][:end]) if v[:evals][:end]
        end
      end
      @touchs[k][:last_flag_touch] = flag_touch
    end
  end
  def check_touch?(k, v)
    return (eval(v[:cond]) == true) if v[:cond]
    return touch_mouse?(v) if k == :mouse
    return touch_player?(v) if k == :player
    k_s = k.to_s
    return touch_event?(v, $1.to_i) if k_s =~ /event_(\d+)/
    return touch_chara?(v, $1.to_i) if k_s =~ /chara_(\d+)/
    return false
  end
  # 以下全部按照屏幕坐标进行计算
  def touch_mouse?(v)
    in_self_rect?(Mouse.x, Mouse.y)
  end
  def touch_player?(v)
    return false
  end
  def touch_event?(v，id)
    return false
  end
  def touch_chara?(v, id)
    return false
  end

  def in_self_rect?(x, y)
    return false if x < self.x || x > self.x + self.width
    return false if y < self.y || y > self.y + self.height
    return true
  end

  def eval_string(str)
    s = $game_swtiches
    v = $game_variables
    eval(str)
  end
end # end of class
