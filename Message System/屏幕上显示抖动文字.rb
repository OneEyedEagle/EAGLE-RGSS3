#==============================================================================
# ■ 屏幕上显示抖动文字 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
# - 2019.3.21.17 公开
#==============================================================================
# - 在屏幕上指定的位置显示抖动文字组
# - 通过调用事件 脚本 指令，新增一个抖动文本精灵组：
#
#        map_text(文本字符串[, x, y, 字符间等待帧数, 是否等待按键,
#                   抖动一像素所用时间, 抖动偏移值])
#
#  【可选属性】
#      x, y            ：字符串左上角显示的位置
#      字符间等待帧数   ：每个字符间显示间隔帧数
#      是否等待按键     ：等待按下确定键后再继续之后的事件
#      抖动一像素所用时间 ：字符移动一像素时所用时间帧数
#      抖动偏移值       ：单个字符抖动的左右上下最大偏移像素值（有随机修正）
#
#   示例：
#     map_text("这里是要显示的字符串", 100, 100) # 在屏幕上(100,100)处显示文本
#
# - 通过事件 脚本 指令，清除掉全部抖动文字精灵：
#
#        clear_map_text
#
# - 给 EAGLE::MapChara类 设置以下属性的预设值，之后显示的文字精灵将应用这些设置
#
#     name属性（字符串）  ：设置所用的字体名称
#     size属性（数字）    ：设置字体大小
#     bold属性（布尔值）  ：设置字体是否加粗
#     italic属性（布尔值）：设置字体是否倾斜
#     shadow属性（布尔值）：设置字体是否有阴影
#     color属性（Color对象）：设置字体颜色
#     outline属性（布尔值） ：设置字体是否显示边框
#     out_color属性（Color对象）：设置字体边框的颜色
#     opacity_down /opacity_up（数字）：设置字符透明度变更的下限/上限
#
#   示例：
#     EAGLE::MapChara.size = 28 # 设置之后的文字字号为 28
#     EAGLE::MapChara.outline = false # 设置之后的文字关闭边框绘制

# - 实现：在Spriteset_Map中绑定了一个精灵组，用于更新全部抖动文字精灵
#==============================================================================

class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 调用显示地图抖动文本
  #--------------------------------------------------------------------------
  def map_text(text, x = rand(400), y = rand(400), duration = 15, wait = false,
       shake = 3, offset = 3)
    EAGLE::MapChara.add(text, x, y, duration, shake, offset)
    return unless wait
    Fiber.yield while !Input.trigger?(:C)
  end
  #--------------------------------------------------------------------------
  # ● 清除地图抖动文本
  #--------------------------------------------------------------------------
  def clear_map_text
    EAGLE::MapChara.clear_all
  end
end

module EAGLE end
module EAGLE::MapChara
  #--------------------------------------------------------------------------
  # ● 属性方法
  #--------------------------------------------------------------------------
  class << self
    attr_accessor :text, :clear
    attr_accessor :name, :size, :bold, :italic, :shadow, :color
    attr_accessor :opacity_down, :opacity_up
    attr_accessor :outline, :out_color
  end
  #--------------------------------------------------------------------------
  # ● 新增
  #--------------------------------------------------------------------------
  @text = []
  def self.add(text, x, y, duration, shake, offset)
    t = []
    text.each_char { |c| t.push(c) }
    font_params = [@name, @size, @bold, @italic, @shadow, @color,
      @opacity_down, @opacity_up, @outline, @out_color]
    @text.push([t, x, y, duration, shake, offset, font_params])
  end
  #--------------------------------------------------------------------------
  # ● 清除标志
  #--------------------------------------------------------------------------
  def self.clear_all
    @clear = true
  end
  #--------------------------------------------------------------------------
  # ● 重置字体属性
  #--------------------------------------------------------------------------
  def self.reset
    @name = Font.default_name
    @size = Font.default_size
    @bold = Font.default_bold
    @italic = Font.default_italic
    @shadow = Font.default_shadow
    @color = Font.default_color
    @outline = Font.default_outline
    @out_color = Font.default_out_color
    @opacity_down = 50
    @opacity_up   = 255
  end
end

class Spriteset_Map
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  alias eagle_map_characters_initialize initialize
  def initialize
    @map_characters = Spriteset_MapCharacters.new
    eagle_map_characters_initialize
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  alias eagle_map_characters_update update
  def update
    eagle_map_characters_update
    @map_characters.update
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  alias eagle_map_characters_dispose dispose
  def dispose
    @map_characters.dispose
    eagle_map_characters_dispose
  end
end

class Spriteset_MapCharacters
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize
    EAGLE::MapChara.reset
    @characters = []    # 存储全部文字精灵的数字
    @duration_count = 0 # 单个字符串中绘制等待计数
    @text_count = 0     # 单个字符串中绘制计数
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    @characters.each { |c| c.update }
    clear if EAGLE::MapChara.clear
    draw  if !EAGLE::MapChara.text.empty?
  end
  #--------------------------------------------------------------------------
  # ● 绘制当前缓存的字符串
  #--------------------------------------------------------------------------
  def draw
    return if (@duration_count -= 1) > 0
    p = EAGLE::MapChara.text[0]
    t = p[0]
    x = p[1] + (p[6][1] + 2) * @text_count
    @duration_count = p[3]
    @characters.push(Sprite_MapCharacter.new(x, p[2], t[@text_count], p[4], p[5], p[6]))
    @text_count += 1
    if @text_count >= t.size
      EAGLE::MapChara.text.shift
      @text_count = 0
    end
  end
  #--------------------------------------------------------------------------
  # ● 清除地图抖动文本
  #--------------------------------------------------------------------------
  def clear
    if defined?(Unravel_Bitmap) && Unravel_Bitmap.is_a?(Class)
    @characters.each { |c|
    Unravel_Bitmap.new(c.x,c.y,c.bitmap.clone,0,0,c.bitmap.width,c.bitmap.height,100,2,4,:LRUD,:S)
    }
    end
    @characters.each { |c| c.dispose if c }
    @characters.clear
    EAGLE::MapChara.clear = false
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    @characters.each { |c| c.dispose if c }
    @characters.clear
    EAGLE::MapChara.clear = false
  end
end

class Sprite_MapCharacter < Sprite
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(x, y, character, shake, offset, font_params)
    super(nil)
    self.x = @_x = x
    self.y = @_y = y
    self.z = 200
    @opa1 = font_params[6]
    @opa2 = font_params[7]
    self.opacity = @opa1 + rand(@opa2 - @opa1)
    @dopa = rand(2) == 0 ? -1 : 1
    @dx = rand(2) == 0 ? -1 : 1
    @dy = rand(2) == 0 ? -1 : 1
    @character = character
    @shake = shake
    @frame = 0
    @offset = offset # 抖动偏差值
    set_box
    @size = font_params[1]
    self.bitmap = Bitmap.new(@size + 5, @size + 5)
    set_font(font_params)
    self.bitmap.draw_text(0,0,self.bitmap.width,self.bitmap.height, @character)
  end
  #--------------------------------------------------------------------------
  # ● 设置抖动范围盒
  #--------------------------------------------------------------------------
  def set_box
    @l = self.x - @offset + rand(2) * @dx - 1
    @r = self.x + @offset + rand(2) * @dx + 1
    @u = self.y - @offset + rand(2) * @dy - 1
    @d = self.y + @offset + rand(2) * @dy - 1
  end
  #--------------------------------------------------------------------------
  # ● 读取字体设置
  #--------------------------------------------------------------------------
  def set_font(font_params)
    self.bitmap.font.name    = font_params[0]
    self.bitmap.font.size    = font_params[1]
    self.bitmap.font.bold    = font_params[2]
    self.bitmap.font.italic  = font_params[3]
    self.bitmap.font.shadow  = font_params[4]
    self.bitmap.font.color   = font_params[5]
    self.bitmap.font.outline = font_params[-2]
    self.bitmap.font.out_color = font_params[-1]
  end
  #--------------------------------------------------------------------------
  # ● 更新抖动
  #--------------------------------------------------------------------------
  def update
    super
    self.opacity += @dopa
    @dopa *= -1 if self.opacity < @opa1 || self.opacity >= @opa2
    return if (@frame -= 1) > 0
    @frame = @shake
    self.x += @dx
    @dx *= -1 if self.x <= @l || self.x >= @r
    self.y += @dy
    @dy *= -1 if self.y <= @u || self.y >= @d
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    super
    self.bitmap.dispose
  end
end
