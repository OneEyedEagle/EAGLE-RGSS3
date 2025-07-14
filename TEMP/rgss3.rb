#encoding: utf-8
# RGSS（Ruby Game Scripting System），也就是「Ruby游戏脚本系统」
# 使用面向对象脚本语言 Ruby 来开发 Windows® 平台的2D游戏。
# RGSS3 即RGSS系列的第三代产品。（对应的 RPG Maker 作品为 RPG Maker VX Ace）
# === Author
# ©2011 ENTERBRAIN, INC./YOJI OJIMA <[url]www.rpgmakerweb.com[/url]>
# === Translate
# taroxd <[url]https://taroxd.github.io/[/url]>
# 余烬之中 <[url]https://github.com/ShadowMomo[/url]>
# 喵呜喵5 <[url]https://rpg.blue/home.php?mod=space&uid=291206[/url]>
# DivineCrow <[url]https://rpg.blue/home.php?mod=space&uid=2630062[/url]>
# kuerlulu <[url]http://hyrious.github.io/[/url]>
# VIPArcher <[url]https://rpg.blue/home.php?mod=space&uid=336539[/url]>
# === Doc Author
# shitake <[url]https://rpg.blue/home.php?mod=space&uid=2653399[/url]>
#
module RGSS3
 
  # 位图类。位图表示图像的数据。
  # 在画面上显示位图，必须使用精灵（Sprite）之类的对象。
  # 超类：Object。
  #
  class Bitmap
 
    # 使用 draw_text 方法描绘字符串时所使用的字体（Font）。
    attr_accessor :font
 
    # Bitmap.new(filename)    -> self
    #   载入由 filename 参数所指定的图像，生成一个 Bitmap 对象。
    #   RGSS-RTP 和加密档案中的文件会自动搜索。扩展名可以省略。
    #
    # Bitmap.new(width, height)    -> self
    #   生成指定大小的 Bitmap 对象。
    #
    def initialize(*args)
      #This is a stub, used for indexing.
    end
 
    # dispose    -> nil
    #   释放位图，若位图已释放，则什么都不做。
    def dispose
      #This is a stub, used for indexing.
    end
 
    # dispose?    -> nil
    #   释放位图，若位图已释放，则什么都不做。
    def dispose?
      #This is a stub, used for indexing.
    end
 
    # width   -> Integer
    #   获取位图的宽度。
    def width
      #This is a stub, used for indexing.
    end
 
    # height   -> Integer
    #   获取位图的高度。
    def height
      #This is a stub, used for indexing.
    end
 
    # rect   -> Rect
    #   获取位图的矩形（Rect）。
    def rect
      #This is a stub, used for indexing.
    end
 
    # blt(x, y, src_bitmap, src_rect[, opacity])   -> nil
    #   将位图 src_bitmap 的矩形 src_rect（Rect）中的数据整体传送到当前位图的坐标 (x, y) 处。
    #   opacity 是透明度，范围 0～255。
    def blt(x, y, src_bitmap, src_rect, opacity = 255)
      #This is a stub, used for indexing.
    end
 
    # stretch_blt(dest_rect, src_bitmap, src_rect[, opacity])   -> nil
    #   将位图 src_bitmap 的矩形 src_rect（Rect）中的数据整体传送到当前位图的矩形 dest_rect（Rect）处。
    #   opacity 是透明度，范围 0～255。
    def stretch_blt(dest_rect, src_bitmap, src_rect, opacity = 255)
      #This is a stub, used for indexing.
    end
 
    # fill_rect(x, y, width, height, color)   -> nil
    #   将位图的矩形 (x, y, width, height)填充指定的颜色 color（Color）。
    # fill_rect(rect, color)   -> nil
    #   将位图的矩形(rect)填充指定的颜色 color（Color）。
    def fill_rect(*args)
      #This is a stub, used for indexing.
    end
 
    # gradient_fill_rect(x, y, width, height, color1, color2[, vertical])   -> nil
    #   将位图的矩形 (x, y, width, height)渐变填充颜色 color1（Color）至 color2（Color）。
    #   将 vertical 设为 true 可以纵向渐变。默认为横向渐变。
    # gradient_fill_rect(rect, color1, color2[, vertical])   -> nil
    #   将位图的矩形（Rect）渐变填充颜色 color1（Color）至 color2（Color）。
    #   将 vertical 设为 true 可以纵向渐变。默认为横向渐变。
    def gradient_fill_rect(*args)
      #This is a stub, used for indexing.
    end
 
    # clear   -> nil
    #   清除整个位图。
    def clear
      #This is a stub, used for indexing.
    end
 
    # clear_rect(x, y, width, height)   -> nil
    #   清除位图的矩形 (x, y, width, height)。
    # clear_rect(rect)   -> nil
    #   清除位图的矩形 rect（Rect）。
    def clear_rect(*args)
      #This is a stub, used for indexing.
    end
 
    # get_pixel(x, y)   -> Color
    #   获取点 (x, y) 的颜色（Color）。
    def get_pixel(x, y)
      #This is a stub, used for indexing.
    end
 
    # set_pixel(x, y, color)   -> color
    #   设置点 (x, y) 的颜色（Color）。
    def set_pixel(x, y, color)
      #This is a stub, used for indexing.
    end
 
    # hue_change(hue)   -> nil
    #   在 360 度内变换位图的色相。
    #   此处理需要花费时间。另外，由于转换误差，反复转换可能会导致色彩失真。
    def hue_change(hue)
      #This is a stub, used for indexing.
    end
 
    # blur   -> nil
    #   对位图执行模糊效果。此处理需要花费时间。
    def blur
      #This is a stub, used for indexing.
    end
 
    # radial_blur(angle, division)    -> nil
    #   对位图执行放射型模糊。angle 指定 0~360 的角度，角度越大，效果越圆润。
    #   division 指定 2～100 的分界数，分界数越大，效果越平滑。此处理需要花费大量时间。
    def radial_blur(angle, division)
      #This is a stub, used for indexing.
    end
 
    # draw_text(x, y, width, height, str[, align])    -> nil
    # draw_text(rect, str[, align])   -> nil
    #   在位图的矩形 (x, y, width, height) 或 rect（Rect）中描绘字符串 str 。
    #   若 str 不是字符串对象，则会在执行之前，先调用 to_s 方法转换成字符串。
    #   若文字长度超过区域的宽度，文字宽度会自动缩小到 60%。
    #   文字的横向对齐方式默认为居左，可以设置 align 为 1 居中，或设置为 2 居右。垂直方向总是居中对齐。
    #   此处理需要花费时间，因此不建议每帧重绘一次文字。
    def draw_text(*args)
      #This is a stub, used for indexing.
    end
 
    # text_size(str)    -> Integer
    #   获取使用 draw_text 方法描绘字符串 str 时的矩形（Rect）。该区域不包含轮廓部分 (RGSS3) 和斜体的突出部分。
    #   若 str 不是字符串对象，则会在执行之前，先调用 to_s 方法转换成字符串。
    def text_size(str)
      #This is a stub, used for indexing.
    end
 
  end
 
  # RGBA 颜色的类。每个成分以浮点数（Float）管理。
  # 超类：Object。
  #
  class Color
 
    # 红色值（0～255）。超出范围的数值会自动修正。
    attr_accessor :red
 
    # 绿色值（0～255）。超出范围的数值会自动修正。
    attr_accessor :green
 
    # 蓝色值（0～255）。超出范围的数值会自动修正。
    attr_accessor :blue
 
    # alpha 值（0～255）。超出范围的数值会自动修正。
    attr_accessor :alpha
 
    # Color.new(red, green, blue[, alpha])    -> self
    #   生成 Color 对象。alpha 值省略时使用 255。
    # Color.new   -> self
    #   如果没有指定参数，默认为(0, 0, 0, 0)。
    def Color.new(red = 0, green = 0, blue = 0, alpha = 0)
      #This is a stub, used for indexing.
    end
 
    # set(red, green, blue[, alpha])  -> self
    #   一次设置所有属性。alpha默认值为255。
    # set(color)   -> self
    #   从另一个 Color 对象上复制所有的属性。(RGSS3)
    def set(*args)
      #This is a stub, used for indexing.
    end
 
  end
 
  # 字体的类。字体是 Bitmap 类的属性。
  # 如果游戏根目录下存在“Fonts”文件夹，那么就算系统中没有安装相应字体，游戏中依然可以使用该文件夹中存在的字体。
  # 超类：Object。
  #
  class Font
 
    class << self
 
      # 默认字体名。
      attr_accessor :default_name
 
      # 默认字体大小。
      attr_accessor :default_size
 
      # 默认粗体标记。
      attr_accessor :default_bold
 
      # 默认斜体标记。
      attr_accessor :default_italic
 
      # 默认文字轮廓标记。
      attr_accessor :default_shadow
 
      # 默认文字阴影标记。
      attr_accessor :default_outline
 
      # 默认文字颜色（Color）。
      attr_accessor :default_color
 
      # 默认文字轮廓颜色（Color）。
      attr_accessor :default_out_color
 
    end
 
    # 字体的名称。默认值是 "nsimsun" (RGSS3)。如果设置为字符串数组，可以依照喜欢的顺序指定多个字体。
    # example:
    #   font.name = ["微软雅黑", "黑体"]
    # 在这个例子中，若系统中不存在优先度高的 "微软雅黑"，则会使用第二选择 "黑体"。
    attr_accessor :name
 
    # 字体大小，默认为 24 (RGSS3)。
    attr_accessor :size
 
    # 粗体标记。默认为 false。
    attr_accessor :bold
 
    # 斜体标记。默认为 false。
    attr_accessor :italic
 
    # 文字轮廓标记，默认为 true。
    attr_accessor :shadow
 
    # 文字阴影标记。默认为 false (RGSS3)。启用时会在文字的右下方描绘黑色阴影。
    attr_accessor :outline
 
    # 文字颜色（Color）。也可以调整 alpha 值。默认为 (255,255,255,255)。
    # alpha 值也同时用来描绘文字轮廓 (RGSS3) 和文字阴影。
    attr_accessor :color
 
    # 文字轮廓颜色（Color），默认值为 (0,0,0,128)。
    attr_accessor :out_color
 
    # Font.new([name[, size]])
    #   生成字体对象。
    def Font.new(name = 'nsimsun', size = 24)
 
    end
 
    # Font.exist?(name)
    #   若系统中存在指定的字体则返回 true。
    def Font.exist?(name)
 
    end
 
  end
 
  # 平面的类。平面是将位图的图案在整个画面上平铺显示的特殊精灵，用于显示远景图等。
  # 超类：Object。
  #
  class Plane
 
    # 平面所使用的位图（Bitmap）的引用。
    attr_accessor :bitmap
 
    # 与平面关联的显示端口（Viewport）的引用。
    attr_accessor :viewport
 
    # 平面的可见状态，true 代表可见。默认为 true。
    attr_accessor :visible
 
    # 平面的 z 坐标。数值越大的显示在越前方。
    # Z 坐标相同的，越晚生成的对象显示在越前方。
    attr_accessor :z
 
    # 平面原点的 X 坐标。修改此数值可以滚动平面。
    attr_accessor :ox
 
    # 平面原点的 Y 坐标。修改此数值可以滚动平面。
    attr_accessor :oy
 
    # 平面的横向放大率，1.0 代表原始大小。
    attr_accessor :zoom_x
 
    # 平面的纵向放大率，1.0 代表原始大小。
    attr_accessor :zoom_y
 
    # 平面的不透明度，范围是 0~255。超出范围的数值会自动修正。
    attr_accessor :opacity
 
    # 平面的合成方式（0：正常、1：加法、2：减法）。
    attr_accessor :blend_type
 
    # 与平面合成的颜色（Color）色彩的 alpha 值作为合成的比例。
    attr_accessor :color
 
    # 平面的色调（Tone）。
    attr_accessor :tone
 
    # Plane.new([viewport])
    #   生成一个 Plane 对象。必要时指定一个显示端口（Viewport）。
    def initialize(viewport = nil)
      #This is a stub, used for indexing.
    end
 
    # dispose
    #   释放平面。若是已释放则什么都不做。
    def dispose
      #This is a stub, used for indexing.
    end
 
    # disposed?   -> TrueClass or FalseClass
    #   当平面已释放则返回 true。
    def disposed?
      #This is a stub, used for indexing.
    end
 
  end
 
  # 矩形的类。
  # 超类：Object。
  #
  class Rect
 
    # 矩形左上角的 X 坐标。
    attr_accessor :x
 
    # 矩形左上角的 Y 坐标。
    attr_accessor :y
 
    # 矩形的宽度。
    attr_accessor :width
 
    # 矩形的高度。
    attr_accessor :height
 
    # Rect.new(x, y, width, height)
    #   创建一个 Rect 对象。未指定参数时，默认值为 (0, 0, 0, 0)。(RGSS3)
    def initialize(x = 0, y = 0, width = 0, height = 0)
      #This is a stub, used for indexing.
    end
 
    # set(x, y, width, height)  -> self
    #   设置Rect的属性,一次设置所有属性。
    # set(rect)   -> self
    #   从另一个 Rect 对象上复制所有的属性。(RGSS3)
    def set(*args)
      #This is a stub, used for indexing.
    end
 
    # empty   -> self
    #   将所有属性设置为 0。
    def empty
      #This is a stub, used for indexing.
    end
 
  end
 
  # 精灵的类。精灵是为了在游戏画面上显示角色等图像的基本概念。
  # 超类：Object。
  #
  class Sprite
 
    # 精灵传输元位图（Bitmap）的引用。
    attr_accessor :bitmap
 
    # 从位图传输的矩形（Rect）。
    attr_accessor :src_rect
 
    # 与精灵关联的显示端口（Viewport）的引用。
    attr_accessor :viewport
 
    # 精灵的可见状态，true 代表可见。默认为 true。
    attr_accessor :visible
 
    # 精灵的 X 坐标。
    attr_accessor :x
 
    # 精灵的 y 坐标。
    attr_accessor :y
 
    # 精灵的 z 坐标。数值越大的显示在越前方。
    # Z 坐标相同时，Y 坐标越大的显示在越前方。Y 坐标也相同时，越晚生成的对象显示在越前方。
    attr_accessor :z
 
    # 精灵原点的 X 坐标。
    attr_accessor :ox
 
    # 精灵原点的 Y 坐标。
    attr_accessor :oy
 
    # 精灵的横向放大率，1.0 代表原始大小。
    attr_accessor :zoom_x
 
    # 精灵的纵向放大率，1.0 代表原始大小。
    attr_accessor :zoom_y
 
    # 精灵的旋转角度。以逆时针方向指定角度数。绘制旋转效果需要时间，所以请避免过量使用。
    attr_accessor :angle
 
    # 波的振幅，以像素数来指定。
    attr_accessor :wave_amp
 
    # 波浪的周期，以像素数来指定。
    attr_accessor :wave_length
 
    # 波浪效果动画的速度，默认为 360，数值愈大速度愈快。
    attr_accessor :wave_speed
 
    # 使用角度制指定精灵最上面一行的相位。每次调用 update 方法会更新一次。
    # 一般情况下不需要使用此属性，除非需要同步两个精灵的波动效果。
    attr_accessor :wave_phase
 
    # 精灵是否左右翻转。设为 true 时会左右反转绘制。默认为 false。
    attr_accessor :mirror
 
    # 指定草木繁茂处的像素数。默认为 0。可以用来表示角色的脚隐藏在草丛中等等的效果。
    attr_accessor :bush_depth
 
    # 指定草木繁茂处的不透明度，范围是 0～255。超出范围的数值会自动修正。默认为 128。
    # 可以用来表示角色的脚隐藏在草丛中等等的效果。
    # bush_opacity 的值会与 opacity 相乘。举例来说，opacity 和 bush_opacity 都
    # 设为 128，就会视为半透明再加上半透明，实际的不透明度为 64。
    attr_accessor :bush_opacity
 
    # 精灵的不透明度，范围是 0~255。超出范围的数值会自动修正。
    attr_accessor :opacity
 
    # 精灵的合成方式（0：正常、1：加法、2：减法）。
    attr_accessor :blend_type
 
    # 与精灵合成的颜色（Color）。色彩的 alpha 值作为合成的比例。
    # 此颜色与 flash 的颜色分开处理。然而，alpha 值较高的颜色会优先合成。
    attr_accessor :color
 
    # 精灵的色调（Tone）。
    attr_accessor :tone
 
    # Sprite.new([viewport])
    #   生成一个精灵对象。必要时指定一个显示端口（Viewport）。
    def initialize(viewport = nil)
      #This is a stub, used for indexing.
    end
 
    # dispose
    #   释放精灵。若是已释放则什么都不做。
    def dispose
      #This is a stub, used for indexing.
    end
 
    # disposed?   -> TrueClass or FalseClass
    #   当精灵已释放则返回 true。
    def disposed?
      #This is a stub, used for indexing.
    end
 
    # flash(color, duration)
    #   开始精灵闪烁。
    #   duration 是指定闪烁的帧数。
    #   color 若设为 nil，闪烁时精灵会消失。
    def flash(color, duration)
      #This is a stub, used for indexing.
    end
 
    # update
    #   更新精灵的闪烁或波的相位。原则上，此方法一帧调用一次。
    #   若是没有使用闪烁或波动效果，则无须调用此方法。
    def update
      #This is a stub, used for indexing.
    end
 
    # width
    #   获取精灵的宽度，相当于 src_rect.width。
    def width
      #This is a stub, used for indexing.
    end
 
    # height
    #   获取精灵的高度，相当于 src_rect.height。
    def height
      #This is a stub, used for indexing.
    end
 
  end
 
  # 多维数组的类。每个元素都是带符号的两字节整数，也就是 -32,768~32,767 之间的整数。
  # Ruby Array 类在处理大量信息时效率很差，因此使用了此类。
  # 超类：Object。
  #
  class Table
 
    # Table.new(xsize[, ysize[, zsize]])
    #   生成 Table 对象。指定多维数组各维的长度。生成的数组可以是 1~3 维。生成没有元素的数组也可以。
    def initialize(xsize, ysize = nil, zsize = nil)
      #This is a stub, used for indexing.
    end
 
    # self[x]
    # self[x, y]
    # self[x, y, z]
    #   读取数组的元素。生成的数组有几维，该方法就接受几个参数。若指定的元素不存在则返回 nil。
    def [](x, y = nil, z = nil)
      #This is a stub, used for indexing.
    end
 
    # self[x] = value
    # self[x, y] = value
    # self[x, y, z] = value
    # 存入数组的元素。生成的数组有几维，该方法就接受几个参数。若指定的元素不存在则返回 nil。
    def []=(x, y = nil, z = nil, value)
      #This is a stub, used for indexing.
    end
 
    # resize(xsize[, ysize[, zsize]])
    #   更改数组的长度。保留更改前的数据。
    def resize(xsize, ysize = nil, zsize = nil)
      #This is a stub, used for indexing.
    end
 
    # xsize
    #   获取数组 X 维的长度。
    def xsize
    end
 
    # ysize
    #   获取数组 Y 维的长度。
    def ysize
      #This is a stub, used for indexing.
    end
 
    # zsize
    #   获取数组 Z 维的长度。
    def zsize
      #This is a stub, used for indexing.
    end
 
  end
 
  # 管理元件地图的类。元件地图是显示二维游戏地图所使用的特殊概念，内部由多个精灵构成。
  # 组成元件地图的每个精灵的 Z 坐标都是固定的。
  #   1.显示在角色之下的元件，其 Z 坐标为 0。
  #   2.显示在角色之上的元件，其 Z 坐标为 200。
  # 在修改地图上人物的 Z 坐标时，必须以此为前提做出决定。
  # 超类：Object。
  #
  class Tilemap
 
    # bitmaps[index]
    # 作为元件组的第 index（0~8）号的位图（Bitmap）对象的引用。
    # 号码与对应的元件组关系如下面列表所示：
    # ----------------------------------
    # |0 |TileA1 |1 |TileA2 |2 |TileA3 |
    # ----------------------------------
    # |3 |TileA4 |4 |TileA5 |5 |TileB  |
    # ----------------------------------
    # |6 |TileC  |7 |TileD  |8 |TileE  |
    # ----------------------------------
    attr_accessor :bitmaps
 
    # 地图数据的引用（Table），设置一个 [ 横尺寸 * 纵尺寸 * 3 ] 的三维数组。
    attr_accessor :map_data
 
    # 闪烁数据的表格（Table）的引用，可以在模拟游戏中显示移动范围等。
    # 设置一个 [ 横尺寸 * 纵尺寸 ] 的二维数组。此数组大小必须与地图数据相同。
    # 每个元素代表元件闪烁的颜色，RGB 各 4 位。例如：0xf84 代表闪烁颜色为 RGB(15,8,4)。
    attr_accessor :flash_data
 
    # 地图数据的引用（Table），设置一个 [ 横尺寸 * 纵尺寸 * 3 ] 的三维数组。
    attr_accessor :flags
 
    # 标志列表（Table）的引用。设置一个以图块 ID 为下标的一维数组。
    attr_accessor :viewport
 
    # 元件地图可见的状态。true 表示可见。默认为 true。
    attr_accessor :visible
 
    # 元件地图原点的 X 坐标。修改此数值可滚动元件地图。
    attr_accessor :ox
 
    # 元件地图原点的 Y 坐标。修改此数值可滚动元件地图。
    attr_accessor :oy
 
    # Tilemap.new([viewport])
    #   生成一个 Tilemap 对象。必要时指定一个显示端口（Viewport）。
    def initialize(viewport = nil)
      #This is a stub, used for indexing.
    end
 
    # dispose
    #   释放元件地图。若是已经释放则什么都不做。
    def dispose
      #This is a stub, used for indexing.
    end
 
    # disposed?   -> TrueClass or FalseClass
    #   若元件地图已释放则返回 true。
    def disposed?
      #This is a stub, used for indexing.
    end
 
    # update
    #   更新自动元件的动画等等。原则上，此方法一帧调用一次。
    def update
      #This is a stub, used for indexing.
    end
 
  end
 
  # 色调的类。各个属性以浮点数（Float）管理。
  # 超类：Object。
  #
  class Tone
 
    # 红色值（-255~255）。超出范围的数值会自动修正。
    attr_accessor :red
 
    # 绿色值（-255~255）。超出范围的数值会自动修正。
    attr_accessor :green
 
    # 蓝色值（-255~255）。超出范围的数值会自动修正。
    attr_accessor :blue
 
    # 灰度滤镜强度值（0~255）。超出范围的数值会自动修正。
    # 当此值非 0 时，处理时间会比只用色调调整平衡要长。
    attr_accessor :gray
 
 
    # Tone.new(red, green, blue[, gray])
    #   生成 Tone 对象。gray 值省略时使用 0。
    # Tone.new (RGSS3)
    #   若没有指定参数，默认值为 (0, 0, 0, 0)。(RGSS3)
    def initialize(red = 0, green = 0, blue, gray = 0)
      #This is a stub, used for indexing.
    end
 
    # set(red, green, blue[, gray])
    #   一次设置所有属性。
    # set(tone)
    #   从另一个 Tone 对象上复制所有的属性。
    def set(*args)
      #This is a stub, used for indexing.
    end
 
  end
 
  # 显示端口的类。用于只在画面的一部分显示精灵，而不影响其余部分。
  # 超类：Object。
  #
  class Viewport
 
    # 设定为显示端口的矩形（Rect）。
    attr_accessor :rect
 
    # 显示端口的可见状态，true 代表可见。默认为 true。
    attr_accessor :visible
 
    # 显示端口的 Z 坐标。数值越大的显示在越前方。
    # Z 坐标相同的，越晚生成的对象显示在越前方。
    attr_accessor :z
 
    # 显示端口原点的 X 坐标。修改此数值可以震动画面。
    attr_accessor :ox
 
    # 显示端口原点的 Y 坐标。修改此数值可以震动画面。
    attr_accessor :oy
 
    # 与显示端口合成的颜色（Color）。色彩的 alpha 值作为合成的比例。
    # 此颜色与 flash 效果的颜色分开处理。
    attr_accessor :color
 
    # 显示端口的色调（Tone）。
    attr_accessor :tone
 
    # Viewport.new(x, y, width, height)
    #   生成 Viewport 对象。
    # Viewport.new(rect)
    #   生成 Viewport 对象。大小和传入的rect相同。
    # Viewport.new
    #   生成 Viewport 对象。大小和整个画面相同。
    def initialize(viewport = nil)
      #This is a stub, used for indexing.
    end
 
    # dispose
    #   释放显示端口。若是已释放则什么都不做。
    #   该操作并不会自动释放其他关联的对象。
    def dispose
      #This is a stub, used for indexing.
    end
 
    # flash(color, duration)
    #   开始闪烁显示端口。duration 指定闪烁的帧数。
    #   若 color 设为 nil，闪烁时显示端口会消失。
    def flash(color, duration)
      #This is a stub, used for indexing.
    end
 
    # disposed?   -> TrueClass or FalseClass
    #   当显示端口已释放则返回 true。
    def disposed?
      #This is a stub, used for indexing.
    end
 
    # update
    #   更新显示端口的闪烁。原则上，此方法一帧调用一次。
    #   若是没有使用闪烁效果，则无须调用此方法。
    def update
      #This is a stub, used for indexing.
    end
 
  end
 
  # 游戏内窗口的类，内部由多个精灵构成。
  # 超类：Object。
  #
  class Window
 
    # 窗口皮肤位图（Bitmap）的引用。
    attr_accessor :windowskin
 
    # 窗口内容位图（Bitmap）的引用。
    attr_accessor :contents
 
    # 光标矩形（Rect）。
    attr_accessor :cursor_rect
 
    # 窗口关联的显示端口（Viewport）的引用。
    attr_accessor :viewport
 
    # 光标闪烁的状态。true 表示闪烁。默认为 true。
    attr_accessor :active
 
    # 窗口可见的状态。true 表示可见。默认为 true。
    attr_accessor :visible
 
    # 滚动箭头可见的状态，true 表示可见。默认为 true。
    attr_accessor :arrows_visible
 
    # 暂停标记可见的状态。暂停标记是表示消息窗口等待输入的记号。true 表示可见。默认为 false。
    attr_accessor :pause
 
    # 窗口的 X 坐标。
    attr_accessor :x
 
    # 窗口的 Y 坐标。
    attr_accessor :y
 
    # 窗口的宽度。
    attr_accessor :width
 
    # 窗口的高度。
    attr_accessor :height
 
    # 窗口的 Z 坐标。数值越大的窗口显示在越前方。
    # Z 坐标相同的，越晚生成的对象显示在越前方。
    # 默认为 100。(RGSS3)
    attr_accessor :z
 
    # 窗口内容原点的 X 坐标。修改此数值可以滚动窗口。
    # 该属性同样影响光标。
    attr_accessor :ox
 
    # 窗口内容原点的 Y 坐标。修改此数值可以滚动窗口。
    # 该属性同样影响光标。
    attr_accessor :oy
 
    # 窗口边框与内容之间的边距，默认为 12。(RGSS3)
    attr_accessor :padding
 
    # 底端用的 padding。由于该属性会随着 padding 的改变而改变，因此必须在 padding 之后设置。
    attr_accessor :padding_bottom
 
    # 窗口的不透明度（0～255）。超出此范围的数值会自动修正。默认为 255。
    attr_accessor :opacity
 
    # 窗口背景的不透明度（0～255）。超出此范围的数值会自动修正。默认为 192。(RGSS3)
    attr_accessor :back_opacity
 
    # 窗口内容的不透明度（0～255）。超出此范围的数值会自动修正。默认为 255。
    attr_accessor :contents_opacity
 
    # 窗口的打开程度（0～255）。超出此范围的数值会自动修正。
    # 将此数值从 0（完全关闭）至 255（完全打开）之间变换，可以产生窗口打开和关闭的动画效果。
    # openness 不满 255 时，窗口的内容不会显示。默认为 255。
    attr_accessor :openness
 
    # 窗口背景的色调（Tone）。
    attr_accessor :tone
 
    # Window.new([x, y, width, height])
    # 生成一个 Window 对象，根据需要指定位置与大小。
    def initialize(x = 0, y = 0, width = 0, height = 0)
      #This is a stub, used for indexing.
    end
 
    # dispose
    #   释放窗口。若是已释放则什么都不做。
    def dispose
      #This is a stub, used for indexing.
    end
 
    # disposed?
    #   当窗口已释放则返回 true。
    def disposed?
      #This is a stub, used for indexing.
    end
 
    # update
    #   刷新光标的闪烁和暂停标记的动画。该方法原则上每帧调用一次。
    def update
      #This is a stub, used for indexing.
    end
 
    # move(x, y, width, height)
    #   同时设置窗口的 X 坐标、Y 坐标、宽度、高度。
    def move(x, y, width, height)
      #This is a stub, used for indexing.
    end
 
    # open?
    #   如果窗口完全打开（openness == 255）则返回 true。
    def open?
      #This is a stub, used for indexing.
    end
 
    # close?
    #   如果窗口完全关闭（openness == 0）则返回 true。
    def close?
      #This is a stub, used for indexing.
    end
 
  end
 
  # 通知 RGSS 内部异常的异常类。
  # 一般在尝试存取已经释放的 Bitmap 或 Sprite 类的对象时抛出。
  # 超类：StandardError。
  #
  class RGSSError
    #This is a stub, used for indexing
  end
 
  # 通知游戏执行时按下 F12 键的异常类。
  # 由 RGSS2 之前的隐藏类 Reset 更名而来。
  # 超类：Exception。
  #
  class RGSSReset
    #This is a stub, used for indexing
  end
 
  # 执行音乐和声音处理的模块。
  module Audio
 
    class << self
 
      # setup_midi
      #   执行 DirectMusic 播放 MIDI 的准备。
      #   方法化后，可以将 RGSS2 启动时执行的处理放在任意时机执行。
      #   不调用本方法也可以播放 MIDI，但是在 Windows Vista 之后的版本中，初次播放会有 1~2 秒的延迟。
      def setup_midi
        #This is a stub, used for indexing.
      end
 
      # bgm_play(filename[, volume[, pitch[, pos]]])
      #   开始播放 BGM。依次指定文件名、音量、音调和起始位置。
      #   起始位置 (RGSS3) 只对 ogg 和 wav 有效。
      #   RGSS-RTP 内的文件也会自动搜索。扩展名可以省略。
      def bgm_play(filename, volume = 100, pitch = 0, pos = 0)
        #This is a stub, used for indexing.
      end
 
      # bgm_stop
      #   停止播放 BGM。
      def bgm_stop
        #This is a stub, used for indexing.
      end
 
      # bgm_fade(time)
      #   开始淡出 BGM。time 以毫秒为单位指定淡出需要的时间。
      def bgm_fade(time)
        #This is a stub, used for indexing.
      end
 
      # bgm_pos(time)
      #   获取 BGM 的播放位置。只对 ogg 和 wav 有效。无效时返回 0。
      def bgm_pos(time)
        #This is a stub, used for indexing.
      end
 
      # bgs_play(filename[, volume[, pitch[, pos]]])
      #   开始播放 BGS。依次指定文件名、音量、音调和起始位置。
      #   起始位置 (RGSS3) 只对 ogg 和 wav 有效。
      #   RGSS-RTP 内的文件也会自动搜索。扩展名可以省略。
      def bgs_play(filename, volume = 100, pitch = 0, pos = 0)
        #This is a stub, used for indexing.
      end
 
      # bgs_stop
      #   停止播放 BGS。
      def bgs_stop
        #This is a stub, used for indexing.
      end
 
      # bgs_fade(time)
      #   开始淡出 BGS。time 以毫秒为单位指定淡出需要的时间。
      def bgs_fade(time)
        #This is a stub, used for indexing.
      end
 
      # bgs_pos(time)
      #   获取 BGS 的播放位置。只对 ogg 和 wav 有效。无效时返回 0。
      def bgs_pos(time)
        #This is a stub, used for indexing.
      end
 
      # me_play(filename[, volume[, pitch[, pos]]])
      #   开始播放 ME。依次指定文件名、音量、音调和起始位置。
      #   RGSS-RTP 内的文件也会自动搜索。扩展名可以省略。
      #   播放 ME 时会暂停 BGM。BGM 重新开始的时机与 RGSS1 稍有不同。
      def me_play(filename, volume = 100, pitch = 0)
        #This is a stub, used for indexing.
      end
 
      # me_stop
      #   停止播放 ME。
      def me_stop
        #This is a stub, used for indexing.
      end
 
      # me_fade(time)
      #   开始淡出 ME。time 以毫秒为单位指定淡出需要的时间。
      def me_fade(time)
        #This is a stub, used for indexing.
      end
 
      # se_play(filename[, volume[, pitch[, pos]]])
      #   开始播放 SE。依次指定文件名、音量、音调和起始位置。
      #   RGSS-RTP 内的文件也会自动搜索。扩展名可以省略。
      #   若是在极短时间内重复播放同一个 SE，会自动延长间隔以防出现爆音。
      def se_play(filename, volume = 100, pitch = 0)
        #This is a stub, used for indexing.
      end
 
      # se_stop
      #   停止播放 SE。
      def se_stop
        #This is a stub, used for indexing.
      end
 
    end
 
  end
 
  # 该模块负责画面整体的处理。
  module Graphics
 
    class << self
 
      # 每秒更新画面的次数。数值越大就需要越多的 CPU 资源。一般设置为 60。
      # 不建议更改此数值，更改时指定范围 10~120 中的数值。超出范围的数值会自动修正。
      attr_accessor :frame_rate
 
      # 画面更新次数的计数。游戏开始时将该属性设为 0，游戏时间（秒）就可以通过该属性除以 frame_rate 的值而算出。
      attr_accessor :frame_count
 
      # 画面的亮度。取范围 0~255 中的数值。fadeout、fadein、transition 方法内部会根据需要修改此数值。
      attr_accessor :brightness
 
      # update
      #   更新游戏画面，推进一帧。该方法需要定期调用。
      # example:
      #   loop do
      #     Graphics.update
      #     Input.update
      #     do_something
      #   end
      def update
        #This is a stub, used for indexing.
      end
 
      # wait(duration)
      #   等待指定的帧数，与下面的代码等效：
      #   duration.times do
      #     Graphics.update
      #   end
      def wait(duration)
        #This is a stub, used for indexing.
      end
 
      # fadeout(duration)
      #   执行画面的淡出。
      #   duration 是淡出花费的帧数。
      def fadeout(duration)
        #This is a stub, used for indexing.
      end
 
      # fadein(duration)
      #   执行画面的淡入。
      #   duration 是淡入花费的帧数。
      def fadein(duration)
        #This is a stub, used for indexing.
      end
 
      # freeze
      #   固定当前画面以准备渐变。
      #   在调用 transition 方法之前，禁止一切画面的重绘。
      def freeze
        #This is a stub, used for indexing.
      end
 
      # transition([duration[, filename[, vague]]])
      #   执行由 Graphics.freeze 方法固定的画面到当前画面的渐变。
      #   duration 是渐变花费的帧数，默认值为 10 。
      #   filename 指定渐变图像的文件名（未指定时则执行普通的淡出）。RGSS-RTP、加密档案中的文件都会被查找。 扩展名可以省略。
      #   vague 是设置图像的起始点和终结点之间边界的模糊度，数值愈大则愈模糊。默认值为 40。
      def transition(duration = 10, filename = nil, vague = 40)
        #This is a stub, used for indexing.
      end
 
      # snap_to_bitmap
      #   以位图对象的形式获取当前的游戏画面。
      #   即使以 freeze 方法固定图像，该方法也会获取当前本来应该显示的图像。
      #   生成的位图不再需要时，必须立刻释放位图。
      def snap_to_bitmap
        #This is a stub, used for indexing.
      end
 
      # frame_reset
      #   重置画面的更新时间。在执行耗时的处理之后，调用此方法可以避免严重的跳帧。
      def frame_reset
        #This is a stub, used for indexing.
      end
 
      # width
      #   获取画面的宽度。默认值为 544。
      def width
        #This is a stub, used for indexing.
      end
 
      # height
      #   获取画面的高度。默认值为 416。
      def height
        #This is a stub, used for indexing.
      end
 
      # resize_screen(width, height)
      #   修改画面的尺寸。
      # width、height 指定宽度和高度，范围为 640×480。
      def resize_screen(width, height)
        #This is a stub, used for indexing.
      end
 
      # play_movie(filename)
      #   从文件名为 filename 的文件中播放视频。
      #   在播放结束后，才会返回。
      def play_movie(filename)
        #This is a stub, used for indexing.
      end
 
    end
 
  end
 
  # 处理手柄、键盘输入的模块。
  # 在 RGSS3 中，使用符号而非按键序号来管理。
  module Input
 
    # 方向键下。
    DOWN
 
    # 方向键左。
    LEFT
 
    # 方向键右。
    RIGHT
 
    # 方向键上。
    UP
 
    # 对应键盘上面的按键 A。
    A
 
    # 对应键盘上面的按键 A。
    B
 
    # 对应键盘上面的按键 A。
    C
 
    # 对应键盘上面的按键 A。
    X
 
    # 对应键盘上面的按键 A。
    Y
 
    # 对应键盘上面的按键 A。
    Z
 
    # 对应键盘上面的按键 A。
    L
 
    # 对应键盘上面的按键 A。
    R
 
    # 对应键盘上面的 SHIFT 键。
    SHIFT
 
    # 对应键盘上面的 CTRL 键。
    CTRL
 
    # 对应键盘上面的 ALT 键。
    ALT
 
    # 对应键盘上的功能键 F5。
    F5
 
    # 对应键盘上的功能键 F6。
    F6
 
    # 对应键盘上的功能键 F7。
    F7
 
    # 对应键盘上的功能键 F9。
    F9
 
    # 对应键盘上的功能键 F9。
    F9
 
    class << self
 
      # update
      #   更新输入信息。原则上一帧调用一次。
      def update
        #This is a stub, used for indexing.
      end
 
      # press?(sym)
      #   检测符号 sym 对应的按键当前是否被按下。
      #   如果按键被按下，则返回 true ，否则返回 false 。
      # example
      #   if Input.press?(:C)
      #     do_something
      #   end
      def press?(sym)
        #This is a stub, used for indexing.
      end
 
      # trigger?(sym)
      #   检测符号 sym 对应的按键是否被重新按下。
      #   从没有按下的状态转变为按下的瞬间才被视为「重新按下」。
      #   如果按钮被重新按下，则返回 true，如果不是，返回 false。
      # example
      #   if Input.trigger?(:C)
      #     do_something
      #   end
      def trigger?(sym)
        #This is a stub, used for indexing.
      end
 
      # repeat?(sym)
      #   检测符号 sym 对应的按键是否被重新按下。
      #   不同于 trigger? ，按住按键时会考虑按键的重复。
      #   如果按钮被重新按下，则返回 true，如果不是，返回 false。
      # example
      #   if Input.repeat?(:C)
      #     do_something
      #   end
      def repeat?(sym)
        #This is a stub, used for indexing.
      end
 
      # dir4
      #   判断方向键的状态，以 4 方向输入的形式，返回与小键盘上的数字对应的整数（2, 4, 6, 8）。
      #   没有方向键按下时（或等价的情况下）返回 0。
      def dir4
        #This is a stub, used for indexing.
      end
 
      # dir8
      #   判断方向键的状态，以 8 方向输入的形式，返回与小键盘上的数字对应的整数（1, 2, 3, 4, 6, 7, 8, 9）。
      #   没有方向键按下时（或等价的情况下）返回 0。
      def dir8
        #This is a stub, used for indexing.
      end
 
    end
 
  end
 
  # rgss_main { ... }
  #   仅进行一次加载的函数。
  #   当检测到用户按下F12的时候，这个函数会被重置。
  # example:
  #   rgss_main { SceneManager.run }
  def rgss_main(&block)
    #This is a stub, used for indexing
  end
 
  # rgss_stop { ... }
  #   停止脚本的执行，只保留画面的刷新。
  def rgss_stop
    #This is a stub, used for indexing
  end
 
  # load_data(filename)   -> Object
  #   加载由 filename 指定的数据文件并还原成对象。
  # example:
  #   $data_actors = load_data("Data/Actors.rvdata2")
  #   这个函数基本上与下面的语句相同：
  #   File.open(filename, "rb") { |f|
  #     obj = Marshal.load(f)
  #   }
  #   不同之处在于，本函数可以从加密档案内加载数据文件。
  def load_data(filename)
    #This is a stub, used for indexing
  end
 
  # save_data(obj, filename)    -> nil
  #   将对象 obj 写入名为 filename 的数据文件。
  # example:
  #   save_data($data_actors, "Data/Actors.rvdata2")
  #   这个函数等价于：
  #   File.open(filename, "wb") { |f|
  #     Marshal.dump(obj, f)
  #   }
  def save_data(obj, filename)
    #This is a stub, used for indexing
  end
 
  # msgbox(arg[, ...])    -> nil
  #   将参数输出到对话框。如果参数并不是字符串，则会使用 to_s 方法转换为字符串后再进行输出。
  def msgbox(*args)
    #This is a stub, used for indexing
  end
 
  # msgbox_p(obj, [obj2, ...])    -> nil
  #   将 obj 以人类可读的格式输出到对话框，相当于下面的代码（参考 Object#inspect）。
  #   msgbox obj.inspect, "\n", obj2.inspect, "\n", ...
  def msgbox_p(*args)
    #This is a stub, used for indexing
  end
 
end