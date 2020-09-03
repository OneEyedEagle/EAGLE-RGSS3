#==============================================================================
# ■ 组件-位图绘制窗口皮肤 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
# - 2020.8.30.21 新增设置更多参数
#==============================================================================
# - 本插件提供了在位图上绘制窗口皮肤的方法
#-----------------------------------------------------------------------------
# - 在位图上指定区域绘制指定的窗口皮肤
#
#      EAGLE.draw_windowskin(windowskin, bitmap[, rect_b, params])
#
#   其中 windowskin 为 Graphics/System 目录下的窗口皮肤文件名称（字符串）
#       bitmap 为需要将窗口皮肤绘制在其上的位图对象
#       rect_b 【可省略】为位图对象被绘制的区域（默认取整个位图区域）
#       params 【可省略】设置更多细节参数，具体见方法注释
#==============================================================================

module EAGLE
  #--------------------------------------------------------------------------
  # ● 在位图上绘制窗口皮肤
  #  windowskin → 在 Graphics/System 目录下的窗口皮肤文件名称，字符串
  #  bitmap → 需要将窗口皮肤绘制在其上的位图对象
  #  rect_b → 位图对象被绘制的区域（当w、h为0时，取整个位图）
  #  params → :cx 设置内容在x方向上的偏移量， :cy 设置在y方向上的偏移量
  #--------------------------------------------------------------------------
  def self.draw_windowskin(windowskin, bitmap, rect_b = nil, params = {})
    rect_b ||= Rect.new(0,0,0,0)
    rect_b.width = bitmap.width if rect_b.width <= 0 # 绘制宽度
    rect_b.height = bitmap.height if rect_b.height <= 0 # 绘制高度
    return if rect_b.width < 32 || rect_b.height < 32
    params[:cx] ||= 2
    params[:cy] ||= 2
    skin = Cache.system(windowskin) rescue return
    draw_windowskin_bg(bitmap, skin, rect_b, params)
    draw_windowskin_bg2(bitmap, skin, rect_b, params)
    draw_windowskin_border(bitmap, skin, rect_b)
  end
  #--------------------------------------------------------------------------
  # ● 拉伸绘制背景层
  #--------------------------------------------------------------------------
  def self.draw_windowskin_bg(bitmap, skin, rect_b, params)
    rect = Rect.new(rect_b.x + params[:cx], rect_b.y + params[:cy],
      rect_b.width - params[:cx] * 2, rect_b.height - params[:cy] * 2)
    src_rect = Rect.new(0, 0, 64, 64)
    bitmap.stretch_blt(rect, skin, src_rect)
  end
  #--------------------------------------------------------------------------
  # ● 平铺绘制背景花纹
  #--------------------------------------------------------------------------
  def self.draw_windowskin_bg2(bitmap, skin, rect_b, params)
    rect = Rect.new(rect_b.x + params[:cx], rect_b.y + params[:cy],
      rect_b.width - params[:cx] * 2, rect_b.height - params[:cy] * 2)
    _x = rect.x
    _y = rect.y
    while(_y < rect.y + rect.height)
      src_rect = Rect.new(0, 64, 64, 64)
      d = rect.y + rect.height - _y
      src_rect.height = d if d < 64
      while(_x < rect.x + rect.width)
        d = rect.x + rect.width - _x
        src_rect.width = d if d < 64
        bitmap.blt(_x, _y, skin, src_rect)
        _x += src_rect.width
      end
      _x = rect.x
      _y += src_rect.height
    end
  end
  #--------------------------------------------------------------------------
  # ● 剪切绘制边框
  #--------------------------------------------------------------------------
  # 16像素为一个单位
  def self.draw_windowskin_border(bitmap, skin, rect_b)
    # 左上
    draw_windowskin_corner(rect_b.x, rect_b.y, skin, Rect.new(64, 0, 16, 16), bitmap)
    # 右上
    draw_windowskin_corner(rect_b.width - 16, rect_b.y, skin, Rect.new(112, 0, 16, 16), bitmap)
    # 左下
    draw_windowskin_corner(rect_b.x, rect_b.y + rect_b.height - 16, skin, Rect.new(64, 48, 16, 16), bitmap)
    # 右下
    draw_windowskin_corner(rect_b.width - 16, rect_b.y + rect_b.height - 16,
      skin, Rect.new(112, 48, 16, 16), bitmap)
    # 上边界
    draw_windowskin_h_border(rect_b.y, skin, Rect.new(80, 0, 32, 16), bitmap, rect_b)
    # 下边界
    draw_windowskin_h_border(rect_b.y + rect_b.height - 16, skin, Rect.new(80, 48, 32, 16), bitmap, rect_b)
    # 左边界
    draw_windowskin_v_border(rect_b.x, skin, Rect.new(64, 16, 16, 32), bitmap, rect_b)
    # 右边界
    draw_windowskin_v_border(rect_b.width - 16, skin, Rect.new(112, 16, 16, 32), bitmap, rect_b)
  end
  # 绘制四角
  def self.draw_windowskin_corner(x, y, skin, src_rect, bitmap)
    bitmap.blt(x, y, skin, src_rect)
  end
  # 绘制水平边框
  def self.draw_windowskin_h_border(y, skin, src_rect, bitmap, rect_b)
    _x = rect_b.x + 16
    _y = y
    _src_rect = src_rect
    while(_x < rect_b.width - 16)
      d = rect_b.width - 16 - _x
      src_rect.width = d if d < 32
      bitmap.blt(_x, _y, skin, _src_rect)
      _x += src_rect.width
    end
  end
  # 绘制垂直边框
  def self.draw_windowskin_v_border(x, skin, src_rect, bitmap, rect_b)
    _x = x
    _y = rect_b.y + 16
    _src_rect = src_rect
    while(_y < rect_b.y + rect_b.height - 16)
      d = rect_b.y + rect_b.height - 16 - _y
      src_rect.height = d if d < 32
      bitmap.blt(_x, _y, skin, _src_rect)
      _y += src_rect.height
    end
  end
end
