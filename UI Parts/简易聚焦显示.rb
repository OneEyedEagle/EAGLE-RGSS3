#==============================================================================
# ■ 简易聚焦显示 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
#==============================================================================
$imported ||= {}
$imported["EAGLE-FocusOn"] = "1.0.0"
#==============================================================================
# - 2024.11.23.14 
#==============================================================================
# - 本插件新增了在画面上显示遮挡、并挖空其中矩形的简易聚焦演出
#------------------------------------------------------------------------------
# 【使用方法：通用】
#
#    FOCUS.set_xywh(x, y, w, h, params={}) 
# 或 FOCUS.set_rect(rect, params={})
#
#    其中 x, y, w, h 或 rect 为画面上需要聚焦的矩形（屏幕上的实际坐标）
#    其中 params 为可选参数：
#       :t => 数字   # 移入移出过渡的帧数
#       :z => 数字   # 背景的z值
#       :color => Color.new(r, g, b, alpha)  # 背景的颜色
#
#  示例：
#
#    FOCUS.set_xywh(100,100,64,64) 或 FOCUS.set_rect(Rect.new(100,100,64,64))
#              # 突出显示屏幕上 100,100,64,64 矩形位置，其他区域为黑色半透明
#
#    FOCUS.set_xywh(0,0,100,100,{:color=>Color.new(255,255,255)})
#              # 突出显示屏幕上左上角的 100,100 矩形位置，其他区域为纯白色
#
#--------------------------------------------------------------------------
# 【使用方法：消除】
#
#    FOCUS.clear
#
#--------------------------------------------------------------------------
# 【使用方法：聚焦到地图坐标】
#
#    FOCUS.set_map(mx,my,mw,mh, params={})
#
#    其中 mx, my 为地图上的坐标（编辑器底部右下角显示的格子坐标）
#         mw, mh 为地图上的格子宽度、高度
#    其中 params 为可选参数（同上）
#
#  注意：
#
#    请自行确保该区域在屏幕显示区域中，否则可能出现看不到聚焦的情况。
#
#  示例：
#
#    FOCUS.set_map(5,5,2,2)
#              # 突出显示地图上 (5,5)左上角、2宽度、2高度 的矩形区域
#
#--------------------------------------------------------------------------
# 【使用方法：聚焦到地图事件】
#
#  ※ 本功能需要【组件-通用方法汇总 by老鹰】才有效。
#
#    FOCUS.set_event(id, params={})
#
#    其中 id 为地图上的事件的ID（编辑器底部右下角显示的ID:事件名称）
#    其中 params 为可选参数（同上）
#
#  注意：
#
#    1. 请自行确保该事件在屏幕显示区域中，否则可能出现看不到聚焦的情况。
#    2. 如果 目标事件的显示 与 该聚焦 在同一事件页（同一时刻）处理，
#        则可能出现事件还未显示、聚焦的宽高发生错误的情况，请在两者间等待10帧左右。
#
#  示例：
#
#    FOCUS.set_event(1)
#              # 突出显示地图上 1号事件的图像 的矩形区域
#
#--------------------------------------------------------------------------
# 【使用方法：聚焦到图片】
#
#  ※ 本功能需要【组件-通用方法汇总 by老鹰】才有效。
#
#    FOCUS.set_pic(id, params={})
#
#    其中 id 为事件指令-图片显示中的ID
#    其中 params 为可选参数（同上）
#
#  注意：
#
#    如果 图片显示 与 该聚焦 在同一事件页（同一时刻）处理，
#      则可能出现图片还未显示、无法聚焦的情况，请在两者间等待10帧左右。
#
#  示例：
#
#    FOCUS.set_pic(1)
#              # 突出显示 1号图片 的区域
#
#--------------------------------------------------------------------------
# 【使用方法：聚焦到战斗中角色】
#
#  ※ 本功能需要【组件-通用方法汇总 by老鹰】才有效。
#
#    FOCUS.set_battler(id, params={})
#
#    其中 id 为正数时，代表敌群中敌人的ID（1~8）
#            为负数时，代表我方队伍中，数据库ID为该绝对值的角色
#    其中 params 为可选参数（同上）
#
#  注意：
#
#    在默认RGSS中，并没有设置我方角色精灵的宽高，也因此聚焦我方角色时会缩为一个点。
#
#  示例：
#
#    FOCUS.set_battler(1)
#              # 突出显示 1号敌人 的区域
#
#==============================================================================
module FOCUS
  #--------------------------------------------------------------------------
  # ●【常量设置】默认的背景颜色
  #--------------------------------------------------------------------------
  FOCUS_BG_COLOR = Color.new(0,0,0,200)
  #--------------------------------------------------------------------------
  # ●【常量设置】默认的移入移出所用帧数
  #--------------------------------------------------------------------------
  FOCUS_MOVE_T = 30
  #--------------------------------------------------------------------------
  # ●【常量设置】默认的背景Z值
  #--------------------------------------------------------------------------
  FOCUS_Z = 150
  
  #--------------------------------------------------------------------------
  # ● 【计算】获取缓动函数的返回值
  #  x 为缓动函数的 当前时间/总时间 的比值（0~1之间小数）
  #  若使用了【组件-缓动函数 by老鹰】，则可以调用其中的缓动函数
  #--------------------------------------------------------------------------
  def self.ease_value(x)
    if $imported["EAGLE-EasingFunction"]
      return EasingFuction.call("easeInSine", x)
    end
    return 1 - 2**(-10 * x)
  end
  
  #--------------------------------------------------------------------------
  # ● 设置聚焦：指定屏幕矩形
  #--------------------------------------------------------------------------
  def self.set_xywh(x, y, w, h, params={})
    @need_refresh = true
    @params = params
    @params_move = {}
    @params_move[:tc] = 0
    @params_move[:t]  = params[:t] || FOCUS_MOVE_T
    @params_move[:x0] = @rect.x
    @params_move[:dx] = x - @params_move[:x0]
    @params_move[:y0] = @rect.y
    @params_move[:dy] = y - @params_move[:y0]
    @params_move[:w0] = @rect.width
    @params_move[:dw] = w - @params_move[:w0]
    @params_move[:h0] = @rect.height
    @params_move[:dh] = h - @params_move[:h0]
    @params_move[:opa] = 255
    @params_move[:dopa] = 0
  end
  def self.set_rect(rect, params={})
    set_xywh(rect.x, rect.y, rect.width, rect.height, params)
  end
  #--------------------------------------------------------------------------
  # ● 设置聚焦：消除
  #--------------------------------------------------------------------------
  def self.clear
    set_xywh(0, 0, Graphics.width, Graphics.height)
    @params_move[:opa] = 255
    @params_move[:dopa] = -255
  end
  #--------------------------------------------------------------------------
  # ● 设置聚焦：地图坐标
  #--------------------------------------------------------------------------
  def self.set_map(mx,my,mw,mh, params={})
    x1 = mx - $game_map.display_x
    y1 = my - $game_map.display_y
    x = x1 * 32
    y = y1 * 32
    w = mw * 32
    h = mh * 32
    set_xywh(x, y, w, h)
  end
  #--------------------------------------------------------------------------
  # ● 设置聚焦：事件
  #--------------------------------------------------------------------------
  def self.set_event(id, params={})
    return if !$imported["EAGLE-CommonMethods"]
    s = EAGLE_COMMON.get_chara_sprite(id)
    return if s.nil?
    x = s.x - s.ox
    y = s.y - s.oy
    set_xywh(x, y, s.width, s.height)
  end
  #--------------------------------------------------------------------------
  # ● 设置聚焦：图片
  #--------------------------------------------------------------------------
  def self.set_pic(id, params={})
    return if !$imported["EAGLE-CommonMethods"]
    s = EAGLE_COMMON.get_pic_sprite(id)
    return if s.nil?
    x = s.x - s.ox
    y = s.y - s.oy
    set_xywh(x, y, s.width, s.height)
  end
  #--------------------------------------------------------------------------
  # ● 设置聚焦：战斗中角色
  #--------------------------------------------------------------------------
  def self.set_battler(id, params={})
    return if !$imported["EAGLE-CommonMethods"]
    s = EAGLE_COMMON.get_battler_sprite(id)
    return if s.nil?
    x = s.x - s.ox
    y = s.y - s.oy
    w = s.width
    h = s.height
    set_xywh(x, y, w, h)
  end
  
  #--------------------------------------------------------------------------
  # ● 初始化（绑定于 SceneManager.run ）
  #--------------------------------------------------------------------------
  def self.init 
    @need_refresh = false
    @rect = Rect.new(0, 0, Graphics.width, Graphics.height)
    @sprite_bg = Sprite_Focus.new(nil, @rect)
  end
  #--------------------------------------------------------------------------
  # ● 更新（绑定于 Graphics.update ）
  #--------------------------------------------------------------------------
  def self.update
    return if !@need_refresh
    c = @params_move[:tc]
    t = @params_move[:t]
    return @need_refresh = false if c > t
    
    per = ease_value(c * 1.0 / t) 
    x = @params_move[:x0] + @params_move[:dx] * per
    y = @params_move[:y0] + @params_move[:dy] * per
    w = @params_move[:w0] + @params_move[:dw] * per
    h = @params_move[:h0] + @params_move[:dh] * per
    opa = @params_move[:opa] + @params_move[:dopa] * per
    @rect.set(x, y, w, h)

    params = {}
    params[:color] ||= FOCUS_BG_COLOR
    params[:z] ||= FOCUS_Z
    @sprite_bg.redraw(x, y, w, h, params)
    @sprite_bg.opacity = opa
    
    @params_move[:tc] += 1
  end
  #--------------------------------------------------------------------------
  # ● 背景精灵
  #--------------------------------------------------------------------------
  class Sprite_Focus < Sprite
    #--------------------------------------------------------------------------
    # ● 初始化
    #--------------------------------------------------------------------------
    def initialize(viewport, rect)
      super(viewport)
      self.bitmap = Bitmap.new(rect.width-rect.x, rect.height-rect.y)
    end
    #--------------------------------------------------------------------------
    # ● 重绘
    #--------------------------------------------------------------------------
    def redraw(x, y, w, h, params)
      self.bitmap.clear
      self.bitmap.fill_rect(self.bitmap.rect, params[:color])
      self.bitmap.clear_rect(x,y,w,h)
      self.z = params[:z]
    end
  end
end

class << SceneManager
  #--------------------------------------------------------------------------
  # ● 游戏开始
  #--------------------------------------------------------------------------
  alias eagle_focus_run run
  def run
    FOCUS.init
    eagle_focus_run
  end
end 

class << Graphics
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  alias eagle_focus_update update
  def update 
    eagle_focus_update
    FOCUS.update
  end
end
