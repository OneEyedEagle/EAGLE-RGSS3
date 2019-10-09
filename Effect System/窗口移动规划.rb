#==============================================================================
# ■ 窗口移动规划 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
$imported ||= {}
$imported["EAGLE-WindowMoveSystem"] = true
#=============================================================================
# - 2019.10.9.17
#=============================================================================
# - 本插件提供了对窗口/精灵的移动控制
#-----------------------------------------------------------------------------
# - 新增一个移动控制：
#
#      WINDOW_MOVE.new(window, string[, flag_reserve])
#
#   其中 window 为 Window类 或 Sprite类 的实例对象
#
#   其中 string 为移动指令的字符串
#    （用 英语分号 ; 隔开各个指令，可以在指令前后添加多余的空格）
#     指令一览：
#     （指令中，用 英语冒号 : 隔开指令名称与指令参数值）
#     wait:d  → 等待d帧后再处理剩下指令
#     t:d   → 开始按照设置的参数执行移动，持续d帧后再处理剩下指令
#     （以下参数若含小数，计算时保留，显示时取整）
#     x:d   → 直接指定x坐标为d（默认取窗口当前坐标）
#     y:d   → 直接指定y坐标为d
#     vx:d  → 设置x方向上每帧移动d像素
#     vy:d  → 设置y方向上每帧移动d像素
#     ax:d  → 在每帧的移动结束后，vx增加d
#     ay:d  → 在每帧的移动结束后，vy增加d
#     opa:d → 直接指定opacity不透明度值为d
#     vo:d  → 设置每帧内opacity变更值为d
#     （以下参数将在设置t的同时生效）
#     desx:d → 设置匀速直线运动的目的地x为d（覆盖vx与ax的设置）
#     desy:d → 设置匀速直线运动的目的地y为d（覆盖vx与ax的设置）
#     （以下参数将立即生效）
#     eval:string → 执行 eval(string)，其中不含英语分号和冒号
#
#   其中 flag_reserve 传入 true 时，代表旧移动序列将继续执行，在其结束后执行新移动序列；
#     传入 false 时，代表放弃之前剩余未执行的移动序列，直接开始执行新的移动序列
#     默认传入 true
#
#   示例：
#     在 Scene_Menu类 中的指令窗口 @command_window，为其附加从上方移入效果
=begin
class Scene_Menu
  alias eagle_window_move_example_command_window create_command_window
  def create_command_window
    eagle_window_move_example_command_window
    @command_window.y = 0 - @command_window.height
    pstr = "desy:0; t:40"
    WINDOW_MOVE.new(@command_window, pstr)
  end
end
=end
#=============================================================================

module WINDOW_MOVE
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def self.init
    @datas ||= {} # window => [data]
  end
  #--------------------------------------------------------------------------
  # ● 新增一个移动
  #--------------------------------------------------------------------------
  def self.new(window, path_string, reserve = true)
    @datas[window] ||= []
    data = Eagle_MoveSystem.new(window, path_string)
    @datas[window].clear if !reserve
    @datas[window].push(data)
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def self.update
    @datas.each do |window, datas|
      next if datas.empty?
      datas[0].update
      datas.shift if datas[0].finish?
    end
  end
  #--------------------------------------------------------------------------
  # ● 清除
  #--------------------------------------------------------------------------
  def self.clear
    @datas.clear
  end
end

class Eagle_MoveSystem
  attr_reader :win
  attr_accessor :wait, :t, :x, :y, :vx, :vy, :ax, :ay
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(window, path_string)
    @paths = path_string.split(';')
    @win = window
    @wait = 0 # 等待用倒计时
    @t = 0 # 移动用计时
    @x = window.x * 1.0; @y = window.y * 1.0 # 初始位置（浮点数）
    @vx = 0; @vy = 0 # 移动速度
    @ax = 0; @ay = 0 # 移动后 速度的变更量
    @opa = window.opacity # 不透明度
    @vo = 0 # 不透明度变更速度
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    return if (@wait -= 1) > 0
    if @t > 0
      @t -= 1
      @x += @vx; @y += @vy
      @vx += @ax; @vy += @ay
      @opa += @vo
      apply
    else
      parse_path
    end
  end
  #--------------------------------------------------------------------------
  # ● 应用
  #--------------------------------------------------------------------------
  def apply
    @win.x = @x
    @win.y = @y
    @window.opacity = @opa
  end
  #--------------------------------------------------------------------------
  # ● 解析移动指令
  #--------------------------------------------------------------------------
  def parse_path
    des_x = des_y = nil
    while(@wait == 0 || @t == 0)
      break if @paths.empty?
      str = @paths.shift # sym:value
      params = str.lstrip.split(':')
      case params[0]
      when "desx" # 覆盖 vx 与 ax，设置匀速直线运动的目的地
        des_x = params[1].to_i
      when "desy"
        des_y = params[1].to_i
      when "eval" # 一次性执行脚本
        eval(params[1])
      else
        m_c = (params[0] + "=").to_sym
        method(m_c).call(params[1].to_f) if respond_to?(m_c)
      end
    end
    if @t > 0
      if des_x
        @vx = (des_x - @x) * 1.0 / @t
        @ax = 0
      end
      if des_y
        @vy = (des_y - @y) * 1.0 / @t
        @ay = 0
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 移动结束？
  #--------------------------------------------------------------------------
  def finish?
    @paths.empty?
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
