#==============================================================================
# ■ 窗口移动绑定 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
$imported ||= {}
$imported["EAGLE-WindowMove"] = true
#=============================================================================
# - 2019.9.27.22
#=============================================================================
# - 本插件提供了可绑定窗口/精灵的移动控制
#-----------------------------------------------------------------------------
# - 新增一个移动控制：
#      WINDOW_MOVE.new(window, params)
#   其中 window 为 Window类 或 Sprite类 的实例对象
#   其中 params 为移动控制参数的 Hash
#     :w → 移动开始前的等待帧数
#     :t → 移动过程中所耗的帧数
#     :vx/:vy → 设置x/y方向的每帧移动量
#     :x/:y → 直接指定移动的目标地点（覆盖:vx/:vy）
#     :vo → 设置透明度的每帧变更量
#
#   示例：
#     在 Scene_Menu类 中的指令窗口 @command_window，为其附加从上方移入效果
=begin
class Scene_Menu
  alias eagle_window_move_example_command_window create_command_window
  def create_command_window
    eagle_window_move_example_command_window
    @command_window.y = 0 - @command_window.height
    params = { :t => 40, :y => 0 }
    WINDOW_MOVE.new(@command_window, params)
  end
end
=end
#=============================================================================

module WINDOW_MOVE
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def self.init
    @datas ||= []
  end
  #--------------------------------------------------------------------------
  # ● 新增一个移动
  #--------------------------------------------------------------------------
  def self.new(window, params)
    data = Eagle_Window_MoveData.new(window, params)
    @datas.push(data)
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def self.update
    temp = []
    @datas.each do |d|
      d.update
      next d.finish if d.finish?
      temp.push(d)
    end
    @datas = temp
  end
  #--------------------------------------------------------------------------
  # ● 清除
  #--------------------------------------------------------------------------
  def self.clear
    @datas.clear
  end
end

class Eagle_Window_MoveData
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(win, params)
    @window = win
    # 浮点坐标
    @x = @window.x; @y = @window.y
    # 移动前等待
    @wait = params[:w] || 0
    # 移动耗时
    @t = params[:t] || 1
    # x方向速度
    @vx = params[:vx] || 0
    @vx = (params[:x] - @x) * 1.0 / @t if params[:x]
    # y方向速度
    @vy = params[:vy] || 0
    @vy = (params[:y] - @y) * 1.0 / @t if params[:y]
    # 透明度变化速度
    @vo = params[:vo] || 0
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    return @wait -= 1 if @wait > 0
    return @t = 0 if @window.nil? || @window.disposed?
    @t -= 1
    @x += @vx; @y += @vy
    @window.x = @x; @window.y = @y
    @window.opacity += @vo
  end
  #--------------------------------------------------------------------------
  # ● 结束
  #--------------------------------------------------------------------------
  def finish
    @window = nil
  end
  #--------------------------------------------------------------------------
  # ● 已经结束？
  #--------------------------------------------------------------------------
  def finish?
    @t <= 0
  end
end

class << DataManager
  #--------------------------------------------------------------------------
  # ● 初始化模块
  #--------------------------------------------------------------------------
  alias eagle_window_move_init init
  def init
    eagle_window_move_init
    WINDOW_MOVE.init
  end
end

class Scene_Base
  #--------------------------------------------------------------------------
  # ● 基础更新
  #--------------------------------------------------------------------------
  alias eagle_window_move_update_basic update_basic
  def update_basic
    eagle_window_move_update_basic
    WINDOW_MOVE.update
  end
end
