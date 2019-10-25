#==============================================================================
# ■ UI移动控制 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
$imported ||= {}
$imported["EAGLE-UIMove"] = true
#=============================================================================
# - 2019.10.25.18 新增 until 指令
#=============================================================================
# - 本插件提供了对窗口/精灵的移动控制
#-----------------------------------------------------------------------------
# - 新增一个移动控制：
#
#      EAGLE_UI_MOVE.new(obj, string[, params])
#
#   其中 obj 为 Window类 或 Sprite类 的实例对象
#
#   其中 string 为移动指令的字符串
#    （用 英语分号 ; 隔开各个指令，可以在指令前后添加多余的空格）
#    （指令中，用 英语冒号 : 隔开指令名称与指令参数值）
#     指令一览：
#     wait:d  → 等待d帧后再处理剩下指令
#     t:d   → 开始按照设置的参数执行移动，运动d帧后再继续处理剩下指令
#             注意：在移动结束后，全部参数将被重置为 0
#     （以下参数若含小数，计算时保留，显示时取整）
#     x:d   → 直接指定x坐标为d（默认取窗口当前坐标）
#     y:d   → 直接指定y坐标为d
#     vx:d  → 设置x方向上每帧移动d像素
#     vy:d  → 设置y方向上每帧移动d像素
#     ax:d  → 在每帧的移动结束后，vx增加d
#     ay:d  → 在每帧的移动结束后，vy增加d
#     opa:d → 直接指定opacity不透明度值为d
#     vo:d  → 设置每帧内opacity变更值为d
#     angle:d → （仅Sprite类有效）直接指定angle旋转角度值为d
#     va:d → （仅Sprite类有效）设置每帧中angle的变更量为d
#     aa:d → （仅Sprite类有效）设置每帧中va的变更量为d
#     vzx:d → （仅Sprite类有效）设置每帧中zoom_x的变更量为d
#     vzy:d → （仅Sprite类有效）设置每帧中zoom_y的变更量为d
#     （预定匀速直线运动，将覆盖原有的vx、vy与ax、ay）
#     desx:d → 设置匀速直线运动的目的地x坐标为d
#     desy:d → 设置匀速直线运动的目的地y坐标为d
#     （高级设置）
#      （在下列的 string 中，不可含有英语分号）
#      （可用 obj 代表当前正在运动的窗口/精灵对象）
#      （可用 s 代表开关组，v 代表变量组）
#     until:string → 直到 eval(string) 返回值为 true，才继续执行之后的指令
#     eval:string → 执行 eval(string)
#     teval:string → 设置下一个t生效期间，每帧移动后额外执行的脚本（按指令顺序）
#
#   其中 params 传入额外设置的Hash（可选）
#    额外参数一览：
#     :reserve → 传入 true，则旧移动序列将继续执行，在其结束后执行新移动序列；
#                传入 false，放弃之前剩余未执行的移动序列，直接开始执行新的移动序列
#                默认传入 true
#     :loop → 传入 true，则循环执行所设置的移动序列；默认传入 false
#
#   示例：
#     在 Scene_Menu类 中的指令窗口 @command_window，为其附加从上方移入效果
=begin
class Scene_Menu
  alias eagle_ui_move_example_command_window create_command_window
  def create_command_window
    eagle_ui_move_example_command_window
    @command_window.y = 0 - @command_window.height
    pstr = "desy:0; t:40"
    EAGLE_UI_MOVE.new(@command_window, pstr)
  end
end
=end
#=============================================================================

module EAGLE_UI_MOVE
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def self.init
    @datas ||= {} # obj => [data]
  end
  #--------------------------------------------------------------------------
  # ● 新增一个移动
  #--------------------------------------------------------------------------
  def self.new(obj, path_string, params = {})
    @datas[obj] ||= []
    data = Eagle_MoveControl.new(obj, path_string, params)
    @datas[obj].clear if params[:reserve] && params[:reserve] == true
    @datas[obj].push(data)
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def self.update
    @datas.each do |obj, datas|
      next if obj.disposed?
      next if datas.empty?
      datas[0].update
      datas.shift if datas[0].finish?
    end
  end
  #--------------------------------------------------------------------------
  # ● 清除
  #--------------------------------------------------------------------------
  def self.clear
    @datas.delete_if { |obj, datas| obj.disposed? }
  end
end
#=============================================================================
# ○ 移动控制类
#=============================================================================
class Eagle_MoveControl
  attr_reader :obj
  attr_accessor :t, :x, :y, :vx, :vy, :ax, :ay
  attr_accessor :angle, :va, :aa, :vzx, :vzy
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(obj, path_string, params)
    @obj = obj
    @paths = path_string.split(';').collect { |s| s.lstrip }
    @params = params
    reset
    @fiber = Fiber.new { fiber_main }
  end
  #--------------------------------------------------------------------------
  # ● 重置
  #--------------------------------------------------------------------------
  def reset
    # 属性绑定
    @x = @obj.x * 1.0; @y = @obj.y * 1.0 # 初始位置（浮点数）
    @opa = @obj.opacity # 不透明度
    # 变量初值
    @t = 0 # 移动用计时
    @vx = 0; @vy = 0 # 移动速度
    @ax = 0; @ay = 0 # 移动后 速度的变更量
    @vo = 0 # 不透明度变更速度
    @angle = 0 # 旋转角度
    @va = 0; @aa = 0
    @zx = 1.0; @zy = 1.0 # 缩放
    @vzx = 0; @vzy = 0 # 缩放度变更量
    if @obj.is_a?(Sprite)
      @angle = @obj.angle
      @zx = @obj.zoom_x; @zy = @obj.zoom_y # 缩放
    end
    @tevals = [] # 每帧执行的脚本
    @des_x = nil
    @des_y = nil
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    @fiber.resume if @fiber
  end
  #--------------------------------------------------------------------------
  # ● 主线程
  #--------------------------------------------------------------------------
  def fiber_main
    @index = 0
    while @index != @paths.size
      str = @paths[@index] # sym:value
      process_command(str)
      @index += 1
      process_move if @t > 0
      @index = 0 if @params[:loop] == true && @index == @paths.size
    end
    @fiber = nil
  end
  #--------------------------------------------------------------------------
  # ● 处理指令
  #--------------------------------------------------------------------------
  def process_command(str)
    i = str.index(':')
    code = str[0..i-1]
    param = str[i+1..-1]
    case code
    when "wait"
      param.to_i.times { Fiber.yield }
    when "desx" # 覆盖 vx 与 ax，设置匀速直线运动的目的地
      @des_x = param.to_i
    when "desy"
      @des_y = param.to_i
    when "until" # 直到条件成立，才继续执行
      Fiber.yield until eval_str(param) == true
    when "eval" # 一次性执行的脚本
      eval_str(param)
    when "teval" # 随着下一次t每帧执行的脚本
      @tevals.push(param)
    else
      m_c = (code + "=").to_sym
      method(m_c).call(param.to_f) if respond_to?(m_c)
    end
    apply
  end
  #--------------------------------------------------------------------------
  # ● 处理移动
  #--------------------------------------------------------------------------
  def process_move
    if @des_x
      @vx = (@des_x - @x) * 1.0 / @t
      @ax = 0
    end
    if @des_y
      @vy = (@des_y - @y) * 1.0 / @t
      @ay = 0
    end
    while @t > 0
      @x += @vx; @y += @vy
      @vx += @ax; @vy += @ay
      @opa += @vo
      @angle += @va;
      @va += @aa
      @zx += @vzx; @zy += @vzy
      @tevals.each { |s| eval_str(s) }
      apply
      Fiber.yield
      @t -= 1
    end
    reset
  end
  #--------------------------------------------------------------------------
  # ● 应用
  #--------------------------------------------------------------------------
  def apply
    @obj.x = @x
    @obj.y = @y
    @obj.opacity = @opa
    if @obj.is_a?(Sprite)
      @obj.angle = @angle
      @obj.zoom_x = @zx
      @obj.zoom_y = @zy
    end
  end
  #--------------------------------------------------------------------------
  # ● 执行脚本
  #--------------------------------------------------------------------------
  def eval_str(string)
    s = $game_switches; v = $game_variables
    eval(string)
  end
  #--------------------------------------------------------------------------
  # ● 移动结束？
  #--------------------------------------------------------------------------
  def finish?
    @fiber == nil
  end
  #--------------------------------------------------------------------------
  # ● 强制终止
  #--------------------------------------------------------------------------
  def stop
    @fiber = nil
  end
end
#=============================================================================
# ○ 绑定
#=============================================================================
class << DataManager
  #--------------------------------------------------------------------------
  # ● 初始化模块
  #--------------------------------------------------------------------------
  alias eagle_ui_move_init init
  def init
    eagle_ui_move_init
    EAGLE_UI_MOVE.init
  end
end
class Scene_Base
  #--------------------------------------------------------------------------
  # ● 基础更新
  #--------------------------------------------------------------------------
  alias eagle_ui_move_update_basic update_basic
  def update_basic
    eagle_ui_move_update_basic
    EAGLE_UI_MOVE.update
  end
  #--------------------------------------------------------------------------
  # ● 结束处理
  #--------------------------------------------------------------------------
  alias eagle_ui_move_terminate terminate
  def terminate
    eagle_ui_move_terminate
    EAGLE_UI_MOVE.clear
  end
end
