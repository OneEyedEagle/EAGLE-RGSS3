#==============================================================================
# ■ Add-On Live2D扩展 by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【对话框扩展 by老鹰】之下
# ※ 本插件需要在【RGD】环境中使用
#==============================================================================
$imported ||= {}
$imported["EAGLE-MessageLive2D"] = true
#==============================================================================
# - 2020.8.22.15 随对话框独立
#==============================================================================
# - 本插件为对话框新增了 Live2D 的显示
#----------------------------------------------------------------------------
# 【Live2D】
#
#   在对话框中，利用转义符 \l2d[id|file|param] 来进行 Live2D 的初始化设置
#
#     其中 id 为唯一标识符，用于后续对该 Live2D 进行控制（字符串）
#     其中 file 为在 LIVE2D_PATH 目录下的 .model3.json 文件的名称
#     其中 param 为【对话框扩展】中的变量参数字符串，每次传入都将重置
#
# 【param参数一览】
#
#    do → 设置显示的位置类型
#     ·当传入 1~9 之间的数字时，live2d的中心点将绑定于对话框对应九宫格位置
#       （如1代表绑定于对话框左下角，5代表绑定于对话框中心，9代表绑定于右上角）
#     ·当传入 -1~-9 之间的数字时，live2d的中心点将绑定于屏幕对应九宫格的位置
#       （如-1代表绑定于屏幕左下角，-5代表绑定于屏幕中心，-9代表绑定于屏幕右上角）
#
#     x → 直接指定显示在自身坐标轴上的 (x,y) 坐标（覆盖 do 设置）
#     y → 直接指定显示在自身坐标轴上的 (x,y) 坐标
#
#    dx → 在x方向上额外的偏移增量（水平向右为正方向）
#    dy → 在y方向上额外的偏移增量（水平向下为正方向）
#     z → 设置live2d在屏幕上的 z 值
#
#    it → live2d淡入时所用帧数
#    ot → live2d淡出时所用帧数
#
#     k → 是否只能绑定于当前对话框（默认true）
#          当为 true 时，当前对话框关闭时，将一同淡出；
#            当前对话框衍生出新对话框时，如 hold 转义符和 seq 转义符，
#            将随旧对话框移动，而不会转移到新对话框内
#
# 【注意】
#
#     对于 Live2D 精灵，其显示原点为中心点，其大小随游戏分辨率而自适应，
#     其坐标轴为 以屏幕中心为原点，水平向右为x正方向，竖直向下为y正方向
#
# 【示例】
#
#    \l2d[haru] → 读取目录下的 haru.model3.json，其id为 "haru"，显示于屏幕正中央
#    \l2d[haru|do-4dx120] → 读取 haru.model3.json，其id为 "haru"，
#                            其中心点显示在屏幕左侧中点向右移动120像素处
#    \l2d[1|haru|do4] → 其id为 "1"，其中心点显示在对话框左侧中点处
#
#----------------------------------------------------------------------------
# 【Live2D控制：视点】
#
#   利用转义符 \l2dat[id|param] 来指定 Live2D 的视点位置
#
#     其中 id 为在 \l2d 中设置的唯一标识符
#     其中 param 为变量参数字符串
#
# 【param参数一览】
#
#     x/y → 指定看向 屏幕上 (x,y) 坐标 方向
#
# 【示例】
#
#    在上述示例后，继续写 \l2de[haru|f01]，以调用 Haru 中 "Name":"f01" 的表情
#
# 【高级】
#
#    利用脚本 MESSAGE_EX.live2d_lookat(id, param) 可达到同样目的
#
#----------------------------------------------------------------------------
# 【Live2D控制：表情】
#
#   利用转义符 \l2de[id|expression] 来调用 Live2D 中预设的表情 "Expressions"
#
#     其中 id 为在 \l2d 中设置的唯一标识符
#     其中 expression 为 Live2D 中预设表情 "Expressions" 中的 "Name" 对应的值
#
# 【示例】
#
#    在上述示例后，继续写 \l2de[haru|f01]，以调用 Haru 中 "Name":"f01" 的表情
#
# 【高级】
#
#    利用脚本 MESSAGE_EX.live2d_expression(id, expression) 可达到同样目的
#
#----------------------------------------------------------------------------
# 【Live2D控制：动作】
#
#   利用转义符 \l2dm[id|motion|index] 来调用 Live2D 中预设的动作 "Motions"
#
#     其中 id 为在 \l2d 中设置的唯一标识符
#     其中 motion 为 Live2D 中预设动作 "Motions" 中的字符串，即动作组的名称
#     其中 index 为对应动作组下的 index 号的动作（从0开始）
#        （若省略，则会随机取一个）
#
# 【示例】
#
#    在上述示例后，继续写 \l2dm[haru|Idle]，以调用 Haru 中的 "Idle" 下的随机动作
#    写 \l2dm[haru|TapBody|0]，以调用 Haru 中 "TapBody" 中的第 1 个动作
#
# 【高级】
#
#    利用脚本 MESSAGE_EX.live2d_motion(id, motion, index) 可达到同样目的
#
#----------------------------------------------------------------------------
# 【图片控制】
#
#   利用转义符 \l2dm2[id|motion|param] 来进行类似对话框中 \facem 的动态控制
#
#     其中 id 为在 \l2d 中设置的唯一标识符
#     其中 motion 为可用的图片动作的字符串
#     其中 param 可省略，为变量参数字符串
#
#   具体 motion 与 param 与【对话框扩展】中的 \facem 转义符保持一致
#
# 【示例】
#
#    在上述示例后，继续写 \l2dm2[haru|jump]，便是将 "haru" 的Live2d进行一次跳跃
#
# 【高级】
#
#    利用脚本 MESSAGE_EX.live2d_eagle_motion(id, motion, param) 可达到同样目的
#
#=============================================================================

#=============================================================================
# ○ 【设置部分】
#=============================================================================
module MESSAGE_EX
  #--------------------------------------------------------------------------
  # ● 【设置】指定 Live2D 的文件夹
  #  其中 <name> 将会被替换成对应调用的 Live2D 的名称
  #  如 Haru 文件夹下的 Haru.model3.json， <name> 将被替换成 Haru
  #--------------------------------------------------------------------------
  LIVE2D_PATH = "Graphics/Live2D/<name>/"
  #--------------------------------------------------------------------------
  # ● 【设置】定义\l2d各参数的预设值
  #--------------------------------------------------------------------------
  LIVE2D_INIT_HASH = {
    :z => 200,  # 在屏幕（无viewport）上的z值
    :sx => 100, # live2d 的横向/纵向百分比
    :sy => 100,
    :do => nil, # 显示位置类型
    :x => nil,
    :y => nil,
    :dx => 0, # 坐标偏移值
    :dy => 0,

    :it => 8, # 淡入所用帧数
    :ot => 6, # 淡出所用帧数
    :k => 1, # 是否只绑定于当前对话框
  }
#=============================================================================
# ○ 精灵池
#=============================================================================
  #--------------------------------------------------------------------------
  # ● 定义可用的池
  #--------------------------------------------------------------------------
  @pool_live2d = []
  class << self
    alias eagle_live2d_ex_all_pools all_pools
    def all_pools
      eagle_live2d_ex_all_pools + [:live2d]
    end
    alias eagle_live2d_ex_get_pool get_pool
    def get_pool(type)
      return @pool_live2d if type == :live2d
      eagle_live2d_ex_get_pool(type)
    end
  end
  #--------------------------------------------------------------------------
  # ● 对live2d精灵池的操作
  #--------------------------------------------------------------------------
  def self.live2d_push(s)
    pool_push(:live2d, s)
  end
  def self.live2d_new
    s = pool_new(:live2d)
    return Sprite_EagleLive2d.new if s.nil?
    s
  end
  #--------------------------------------------------------------------------
  # ● 获取指定live2d精灵
  #--------------------------------------------------------------------------
  def self.live2d_get(id)
    @pool_live2d.each { |s| return s if !s.finish? && s.id == id }
    return nil
  end
  #--------------------------------------------------------------------------
  # ● 对全部的live2d精灵进行操作
  #--------------------------------------------------------------------------
  def self.live2ds
    @pool_live2d.each { |s| yield s if !s.finish? }
  end
  #--------------------------------------------------------------------------
  # ● 新增live2d精灵
  #--------------------------------------------------------------------------
  def self.live2d_add(id, path, name, param = "", window = nil)
    s = live2d_get(id)
    if s.nil?
      s = live2d_new
      live2d_push(s)
    end
    h = LIVE2D_INIT_HASH.dup
    parse_param(h, param, :def) if param
    h[:id] = id || get_pic_sym(filename)
    s.reset(window, h, path, name)
    s.motion(:fade_in)
  end
  #--------------------------------------------------------------------------
  # ● 对指定的live2d精灵进行操作
  #--------------------------------------------------------------------------
  def self.live2d_eagle_motion(id, sym, param = "")
    s = live2d_get(id)
    return if s.nil?
    s.motion(sym, param || "")
  end
  #--------------------------------------------------------------------------
  # ● 对指定的live2d精灵进行表情处理
  #--------------------------------------------------------------------------
  def self.live2d_expression(id, key = nil)
    s = live2d_get(id)
    return if s.nil?
    return s.l2d.set_random_expression if key == nil
    s.l2d.set_expression(key)
  end
  #--------------------------------------------------------------------------
  # ● 对指定的live2d精灵进行动作处理
  #--------------------------------------------------------------------------
  def self.live2d_motion(id, key, index = nil)
    s = live2d_get(id)
    return if s.nil?
    return s.l2d.set_random_motion(key) if index == nil
    s.l2d.set_motion(key, index.to_i)
  end
  #--------------------------------------------------------------------------
  # ● 对指定的live2d精灵进行视点处理
  #--------------------------------------------------------------------------
  def self.live2d_lookat(id, param = "")
    s = live2d_get(id)
    return if s.nil?
    h = {}
    parse_param(h, param, :x)
    s.lookat(h[:x], h[:y])
  end
end
#=============================================================================
# ○ Window_EagleMessage
#=============================================================================
class Window_EagleMessage
  #--------------------------------------------------------------------------
  # ● 拷贝自身（扩展用处理）
  #--------------------------------------------------------------------------
  alias eagle_live2d_ex_clone_ex clone_ex
  def clone_ex(t)
    MESSAGE_EX.live2ds { |s| s.bind_window(t) if s.keep?(self) }
    eagle_live2d_ex_clone_ex(t)
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  alias eagle_message_ex_pic2_dispose dispose
  def dispose
    MESSAGE_EX.live2ds { |s| s.motion(:fade_out) if s.keep?(self) }
    eagle_message_ex_pic2_dispose
  end
  #--------------------------------------------------------------------------
  # ● 移出全部组件
  #--------------------------------------------------------------------------
  alias eagle_live2d_ex_move_out_assets eagle_move_out_assets
  def eagle_move_out_assets
    MESSAGE_EX.live2ds { |s| s.motion(:fade_out) if s.keep?(self) }
    eagle_live2d_ex_move_out_assets
  end
  #--------------------------------------------------------------------------
  # ● 设置 l2d 参数
  #--------------------------------------------------------------------------
  def eagle_text_control_l2d(param = '0')
    return if !game_message.draw
    name = ""; id = nil; pst = ""
    ps = param.split('|') # [id, file, param] or [file, param] or [file]
    name = ps[0] if ps.size == 1
    (name = ps[0]; pst = ps[1]) if ps.size == 2
    (id = ps[0]; name = ps[1]; pst = ps[2]) if ps.size >= 3
    path = MESSAGE_EX::LIVE2D_PATH.gsub( "<name>" ) { name }
    MESSAGE_EX.live2d_add(id || name, path, name, pst, self)
  end
  #--------------------------------------------------------------------------
  # ● 执行 l2dm
  #--------------------------------------------------------------------------
  def eagle_text_control_l2dm(param = '0')
    return if !game_message.draw
    params = param.split('|') # [id, motion, index]
    MESSAGE_EX.live2d_motion(params[0], params[1], params[2])
  end
  #--------------------------------------------------------------------------
  # ● 执行 l2de
  #--------------------------------------------------------------------------
  def eagle_text_control_l2de(param = '0')
    return if !game_message.draw
    params = param.split('|') # [id, expression]
    MESSAGE_EX.live2d_expression(params[0], params[1])
  end
  #--------------------------------------------------------------------------
  # ● 执行 l2dm2
  #--------------------------------------------------------------------------
  def eagle_text_control_l2dm2(param = '0')
    return if !game_message.draw
    params = param.split('|') # [id, motion, param]
    MESSAGE_EX.live2d_eagle_motion(params[0], params[1], params[2] || "")
  end
  #--------------------------------------------------------------------------
  # ● 执行 l2dat
  #--------------------------------------------------------------------------
  def eagle_text_control_l2dat(param = '0')
    return if !game_message.draw
    params = param.split('|') # [id, param]
    MESSAGE_EX.live2d_lookat(params[0], params[1] || "")
  end
end
#==============================================================================
# ○ Sprite_EagleLive2d
#==============================================================================
class Sprite_EagleLive2d < Sprite_EagleFace
  attr_reader  :params, :l2d
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    @l2d.dispose
    super
  end
  #--------------------------------------------------------------------------
  # ● 唯一标识符
  #--------------------------------------------------------------------------
  def id
    @params[:id]
  end
  #--------------------------------------------------------------------------
  # ● 只显示于当前对话框？
  #--------------------------------------------------------------------------
  def keep?(w)
    @params[:k] != 0 && @window == w
  end
  #--------------------------------------------------------------------------
  # ● 重置
  #--------------------------------------------------------------------------
  def reset(window, ps, path, name)
    bind_window(window)
    init_params
    @params = ps
    @params[:look_x] = @params[:look_y] = 0
    @l2d.dispose if @l2d
    @l2d = L2D.new(path, "#{name}.model3.json")
    @l2d.zoom_x = @params[:sx] * 1.0 / 100
    @l2d.zoom_y = @params[:sy] * 1.0 / 100
  end
  #--------------------------------------------------------------------------
  # ● 看向
  #--------------------------------------------------------------------------
  def lookat(x, y)
    @params[:look_x] = x if x
    @params[:look_y] = y if y
    @l2d.lookat(@params[:look_x], @params[:look_y])
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    @fiber.resume if @fiber
    update_position
  end
  #--------------------------------------------------------------------------
  # ● 更新位置
  #--------------------------------------------------------------------------
  def update_position
    reset_doxy(params[:do]) if params[:do]
    @x0 = params[:x] if params[:x]
    @y0 = params[:y] if params[:y]
    @l2d.x = @x0 + @x1 + params[:dx]
    @l2d.y = @y0 + @y1 + params[:dy]
    @l2d.z = params[:z]
    @l2d.opacity = @opa
  end
  #--------------------------------------------------------------------------
  # ● 设置相对显示（屏幕上）
  #--------------------------------------------------------------------------
  def reset_doxy(o)
    return if o == 0
    return if o > 0 && (@window.nil? || @window.disposed?)
    MESSAGE_EX.reset_xy_dorigin(self, @window, o)
    @x0 = self.x - Graphics.width / 2
    @y0 = self.y - Graphics.height / 2
  end
end
