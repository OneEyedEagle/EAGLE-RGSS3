module WINDOW_MOVE
  def self.new(window, params)
    data = Eagle_Window_MoveData.new(window, params)
    @datas.push(data)
  end
  def self.update
    return if @datas.empty?
    d = @datas.shift
    d.update
    return d.finish if d.finish?
    @datas.push(d)
  end
  def self.clear
    @datas ||= []
    @datas.clear
  end
end
class Eagle_Window_MoveData
  def initialize(win, params)
    @window = win
    # 浮点坐标
    @x = @window.x; @y = @window.y
    # 移动耗时
    @t = params[:t] || 1
    # x方向速度
    @vx = params[:vx] || 0
    @vx = (params[:x] - @x) / @t if params[:x]
    # y方向速度
    @vy = params[:vy] || 0
    @vy = (params[:y] - @y) / @t if params[:y]
    # 透明度变化速度
    @vo = params[:vo] || 0
  end
  def update
    @t -= 1
    @x += @vx; @y += @vy
    @window.x = @x; @window.y = @y
    @window.opacity += @vo
  end
  def finish?
    @t <= 0
  end
end
class Scene_Base
  alias eagle_window_move_post_start post_start
  def post_start
    eagle_window_move_post_start
    WINDOW_MOVE.clear
  end
  alias eagle_window_move_update_basic update_basic
  def update_basic
    eagle_window_move_update_basic
    WINDOW_MOVE.update
  end
end
