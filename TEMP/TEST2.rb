#
class Button < Sprite
  def initialize(viewport = nil)
    super(viewport)
    @x0 = @y0 = 0 # 位置坐标的原点（屏幕坐标）（默认为屏幕坐标的左上角）
    @x_ = @y_ = 0 # 相对原点的i显示位置
    @touchs = {} # type => { }
  end
  def bind_origin(type)
    # 绑定屏幕左上角或地图左上角
    @origin = type
  end
  def set_xy(x_, y_)
    @x_ = x_ if x_
    @y_ = y_ if y_
  end
  def bind_touch(type, methods = {})
    @touchs[type] = {}
    @touchs[type][:cond] = ""
    @touchs[type][:methods] = methods
  end
  def update
    super
    update_origin
    update_xy
    update_touch
  end
  def update_origin
    if @origin == :map && SceneManager.scene_is?(Scene_Map)
      @x0 = 0 - $game_map.display_x * 32
      @y0 = 0 - $game_map.display_y * 32
    end
    @x0 = @y0 = 0
  end
  def update_xy
    self.x = @x0 + @x_
    self.y = @y0 + @y_
  end
  def update_touch
  end
  def touch_mouse?

  end
  def touch_event?(a)
  end

  def dispose
    super
  end
end
