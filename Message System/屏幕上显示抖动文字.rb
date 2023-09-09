#encoding:utf-8
#==============================================================================
# ■ 显示抖动文字 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# 【此插件兼容VX和VX Ace】
#==============================================================================
$imported ||= {}
$imported["EAGLE-ScreenCharasShake"] = "1.0.0"
#==============================================================================
# - 2021.4.23.11
#------------------------------------------------------------------------------
# - 在固定的位置显示一组抖动文字
#------------------------------------------------------------------------------
# 【使用】
#
#   利用事件脚本新增一组抖动文本
#
#      map_text(文本字符串[, x, y, 字符间等待帧数, 抖动一像素所用时间, 抖动偏移值])
#
#   【可选参数】
#
#      x, y          ：字符串左上角显示的位置
#      字符间等待帧数 ：每个字符间显示间隔帧数
#      抖动一像素所用时间 ：字符移动一像素时所用时间帧数
#      抖动偏移值    ：单个字符抖动的左右上下最大偏移像素值（有随机修正）
#
#   【注意！】
#
#     RGSS2中无法按中文字符处理字符串，故需要在每个字符之间利用符号来分割，
#     默认的分割符号为 % ，可在146行处的 /[%]/ 修改，本质为正则表达式
#
#   【示例】
#   VA 版本
#     事件脚本 map_text("这是一句测试语句", 200,100, 10)
#        → 在屏幕的 (200,100) 处 显示该句，且每个字符之间等待间隔 10 帧
#
#   VX 版本
#     事件脚本 map_text("这%是%一%句%测%试%语%句", 200,100, 10)
#        → 在屏幕的 (200,100) 处 显示该句，且每个字符之间等待间隔 10 帧
#
#------------------------------------------------------------------------------
# 【使用】
#
#   利用事件脚本新增一组抖动文本
#
#      shake_text(文本字符串[, 参数Hash])
#
#    【参数可选属性】
#
#       :x → 数字，定义初始显示位置的屏幕坐标x
#       :y → 数字，定义初始显示位置的屏幕坐标y
#       :on_map → true 或 false，当为true时，将显示在地图上的(x,y)格子处
#                  默认取 false，即显示在屏幕上
#       :t → 数字，字符间等待帧数
#       :s → 数字，抖动一像素所用时间
#       :d → 数字，抖动的最大偏移值
#       :out → 数字，最大的持续显示时间，当时间到，将自动消失
#               若不设置或传入 nil，则不会自动消失
#       :id → 任意，定义唯一标识符，用于移出控制
#
#   【示例】
#
#      shake_text("这%是%一%句%测%试%语%句", {:x => 13, :y => 9, :on_map => true})
#        → 在地图的 (20,10) 格子处显示该句
#
#------------------------------------------------------------------------------
# 【使用】
#
#   利用事件脚本移出一组抖动文本
#
#       move_out_shake_text(id)
#
#   其中 id 与上文中的 :id 需要保持完全一致
#
#------------------------------------------------------------------------------
# 【使用】
#
#   利用事件脚本移出全部抖动文本
#
#       move_out_all_text(t)
#
#   其中 t 为移出一句后的等待帧数，不填则取 0
#
#------------------------------------------------------------------------------
# 【使用】
#
#   利用事件脚本清除掉全部抖动文字精灵
#
#      clear_map_text
#
#------------------------------------------------------------------------------
# 【高级】
#
#   通过调用 EAGLE::MapChara 类的类方法，可以对之后显示的文字进行设置
#
#     name属性（字符串）  ：设置所用的字体名称
#     size属性（数字）    ：设置字体大小
#     bold属性（布尔值）  ：设置字体是否加粗
#     italic属性（布尔值）：设置字体是否倾斜
#     shadow属性（布尔值）：设置字体是否有阴影
#     color属性（Color对象）：设置字体颜色
#     opacity_down /opacity_up（数字）：设置字符透明度变更的下限/上限
#
#   【示例】
#
#     事件脚本 EAGLE::MapChara.size = 16
#        → 之后的抖动文字的字号调整为 16
#
#     事件脚本 EAGLE::MapChara.color = Color.new(255,0,0)
#        → 之后的抖动文字的默认绘制颜色调整为 红色
#
#------------------------------------------------------------------------------
# 【实质】
#
#   在Spriteset_Map中绑定了一个精灵组，用于更新这些抖动文字精灵
#==============================================================================
FLAG_VX = RUBY_VERSION[0..2] == "1.8"
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 调用显示地图抖动文本
  #--------------------------------------------------------------------------
  def map_text(text, x = rand(400), y = rand(400), duration = 10, shake = 3, offset = 3)
    EAGLE::MapChara.add(text, {:x => x, :y => y, :t => duration, :s => shake, :d => offset})
    return true
  end
  def shake_text(text, params = {})
    EAGLE::MapChara.add(text, params)
    return true
  end
  #--------------------------------------------------------------------------
  # ● 移出指定id的抖动文本
  #--------------------------------------------------------------------------
  def move_out_shake_text(id)
    EAGLE::MapChara.out_id = id
  end
  #--------------------------------------------------------------------------
  # ● 移出全部抖动文本
  #--------------------------------------------------------------------------
  def move_out_all_text(t = 0)
    EAGLE::MapChara.move_out = t
  end
  #--------------------------------------------------------------------------
  # ● 清除地图抖动文本
  #--------------------------------------------------------------------------
  def clear_map_text
    EAGLE::MapChara.clear_all
    return true
  end
end

class Font_EagleMapChara < Font
  attr_accessor :opacity_down, :opacity_up
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize
    super
    @opacity_down = 150
    @opacity_up   = 255
  end
  #--------------------------------------------------------------------------
  # ● 重置
  #--------------------------------------------------------------------------
  def reset
    @name = Font.default_name
    @size = Font.default_size
    @bold = Font.default_bold
    @italic = Font.default_italic
    @shadow = Font.default_shadow
    @color = Font.default_color
    @opacity_down = 150
    @opacity_up   = 255
  end
end

module EAGLE end
module EAGLE::MapChara
  #--------------------------------------------------------------------------
  # ● 新增
  #--------------------------------------------------------------------------
  @text = []
  @font = Font_EagleMapChara.new
  def self.add(text, params = {})
    params[:x] ||= rand(400)
    params[:y] ||= rand(400)
    params[:on_map] ||= false
    params[:t] ||= 10 # duration
    params[:s] ||= 3 # shake
    params[:d] ||= 3 # offset
    if FLAG_VX
      t = text.split(/[%]/)
    else
      t = text.split('')
    end
    @text.push([t, params, @font.dup])
  end
  #--------------------------------------------------------------------------
  # ● 清除标志
  #--------------------------------------------------------------------------
  def self.clear_all
    @text.clear
    @clear = true
  end
  #--------------------------------------------------------------------------
  # ● 重置字体属性
  #--------------------------------------------------------------------------
  def self.reset
    @move_out = -1
    @font.reset
  end
  #--------------------------------------------------------------------------
  # ● 属性方法
  #--------------------------------------------------------------------------
  class << self
    attr_accessor :text, :clear, :out_id, :move_out
    def name;     @font.name; end
    def name=(v); @font.name = v; end
    def size;     @font.size; end
    def size=(v); @font.size = v; end
    def bold;     @font.bold; end
    def bold=(v); @font.bold = v; end
    def italic;     @font.italic; end
    def italic=(v); @font.italic = v; end
    def shadow;     @font.shadow; end
    def shadow=(v); @font.shadow = v; end
    def color;     @font.color; end
    def color=(v); @font.color = v; end
    def opacity_down;     @font.opacity_down; end
    def opacity_down=(v); @font.opacity_down = v; end
    def opacity_up;     @font.opacity_up; end
    def opacity_up=(v); @font.opacity_up = v; end
  end
end # end of module

class Spriteset_MapCharacters
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize
    EAGLE::MapChara.reset
    @characters = [] # 存储全部文字精灵的数字
    @ids = {} # id => first_chara
    @duration_count = 0 # 单个字符串中绘制等待计数
    @text_count = 0     # 单个字符串中绘制计数
    @move_out_count = 0 # 移出时的等待计数
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    clear_first if !@characters.empty?
    @characters.each { |c| c.update }
    return clear if EAGLE::MapChara.clear
    draw  if !EAGLE::MapChara.text.empty?
    move_out if EAGLE::MapChara.move_out >= 0
    move_out_id if EAGLE::MapChara.out_id
  end
  #--------------------------------------------------------------------------
  # ● 清除头部已经移出的文字
  #--------------------------------------------------------------------------
  def clear_first
    if @characters[0].out?
      s = @characters.shift
      s.dispose
    end
  end
  #--------------------------------------------------------------------------
  # ● 绘制当前缓存的字符串
  #--------------------------------------------------------------------------
  def draw
    return if (@duration_count -= 1) > 0
    # 如果并非首个字，但又没有精灵（显示中途打开菜单等）
    if @text_count > 0 && @characters.size == 0
      # 现在是继续显示之前未显示完的
      #  但如果将 @text_count 修改为全局变量，则会终止之前未显示完的
      return draw_end
    end

    tp = EAGLE::MapChara.text[0]
    params = tp[1].dup
    params[:dx] = (EAGLE::MapChara.size + 2) * @text_count
    params[:dy] = 0
    s = Sprite_MapCharacter.new(tp[0][@text_count], params, tp[2])
    if @text_count == 0
      @ids[params[:id]] = s if params[:id]
    else
      @characters[-1].next_chara = s
    end
    @characters.push(s)

    @text_count += 1
    @duration_count = params[:t] # 绘制一个字后的等待帧数
    draw_end if @text_count >= tp[0].size
  end
  #--------------------------------------------------------------------------
  # ● 绘制完成
  #--------------------------------------------------------------------------
  def draw_end
    EAGLE::MapChara.text.shift
    @text_count = 0
  end
  #--------------------------------------------------------------------------
  # ● 清除地图抖动文本
  #--------------------------------------------------------------------------
  def clear
    if defined?(Unravel_Bitmap) && Unravel_Bitmap.is_a?(Class)
    @characters.each do |c|
      next if c.out?
      Unravel_Bitmap.new(c.x,c.y,c.bitmap.clone,0,0,c.bitmap.width,c.bitmap.height,100,2,4,:LRUD,:S)
    end
    end
    dispose
  end
  #--------------------------------------------------------------------------
  # ● 移出全部地图抖动文本
  #--------------------------------------------------------------------------
  def move_out
    @move_out_count -= 1
    return if @move_out_count > 0
    @move_out_count = EAGLE::MapChara.move_out
    @characters.each do |c|
      if c.params[:out_active] == false
        if defined?(Unravel_Bitmap) && Unravel_Bitmap.is_a?(Class)
          Unravel_Bitmap.new(c.x,c.y,c.bitmap.clone,0,0,c.bitmap.width,c.bitmap.height,100,2,4,:LRUD,:S)
        end
        return c.move_out
      end
    end
    EAGLE::MapChara.move_out = -1
  end
  #--------------------------------------------------------------------------
  # ● 移出指定文字组
  #--------------------------------------------------------------------------
  def move_out_id
    id = EAGLE::MapChara.out_id
    if @ids[id] && !@ids[id].disposed?
      @ids[id].move_out
    end
    EAGLE::MapChara.out_id = nil
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    @ids.clear
    @characters.each { |c| c.dispose if c }
    @characters.clear
    EAGLE::MapChara.clear = false
  end
end

class Sprite_MapCharacter < Sprite
  attr_reader   :params
  attr_accessor :next_chara
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(c, ps, _font)
    super(nil)
    @params = ps
    @params[:sc] = 0 # 抖动一次后的等待时间计数
    @params[:sdx] = 0 # 实际抖动的距离
    @params[:sdy] = 0
    @params[:vx] = rand(2) == 0 ? -1 : 1
    @params[:vy] = rand(2) == 0 ? -1 : 1
    @params[:vo] = rand(2) == 0 ? -1 : 1
    @params[:oc] = 0 # 移出的等待计数
    @params[:out_active] = false
    update_pos

    set_box
    self.bitmap = Bitmap.new(_font.size + 5, _font.size + 5)
    self.bitmap.font = _font
    self.bitmap.draw_text(0,0,self.width,self.height, c)

    @opa_down = _font.opacity_down
    @opa_up = _font.opacity_up
    self.opacity = @opa_down + rand(@opa_up - @opa_down)

    @next_chara = nil
  end
  #--------------------------------------------------------------------------
  # ● 设置抖动范围盒
  #--------------------------------------------------------------------------
  def set_box
    @l = - @params[:d] + rand(2) * @params[:vx] - 1
    @r = + @params[:d] + rand(2) * @params[:vx] + 1
    @u = - @params[:d] + rand(2) * @params[:vy] - 1
    @d = + @params[:d] + rand(2) * @params[:vy] - 1
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
    update_shake
    update_pos
    return update_move_out if @params[:out_active]
    update_opacity
    update_out
  end
  #--------------------------------------------------------------------------
  # ● 更新移出
  #--------------------------------------------------------------------------
  def update_move_out
    self.opacity -= 15
  end
  #--------------------------------------------------------------------------
  # ● 更新透明度
  #--------------------------------------------------------------------------
  def update_opacity
    self.opacity += @params[:vo]
    @params[:vo] *= -1 if self.opacity < @opa_down || self.opacity >= @opa_up
  end
  #--------------------------------------------------------------------------
  # ● 更新抖动
  #--------------------------------------------------------------------------
  def update_shake
    return if (@params[:sc] -= 1) > 0
    @params[:sc] = @params[:s]

    @params[:sdx] += @params[:vx]
    @params[:vx] *= -1 if @params[:sdx] <= @l || @params[:sdx] >= @r
    @params[:sdy] += @params[:vy]
    @params[:vy] *= -1 if @params[:sdy] <= @u || @params[:sdy] >= @d
  end
  #--------------------------------------------------------------------------
  # ● 更新位置
  #--------------------------------------------------------------------------
  def update_pos
    if @params[:on_map]
      self.x = ($game_map.adjust_x(@params[:x]*256) + 8007) / 8 - 1000
      self.y = ($game_map.adjust_y(@params[:y]*256) + 8007) / 8 - 1000
    else
      self.x = @params[:x]
      self.y = @params[:y]
    end
    self.x += @params[:dx] + @params[:sdx]
    self.y += @params[:dy] + @params[:sdy]
    self.z = 200
  end
  #--------------------------------------------------------------------------
  # ● 更新自动移出
  #--------------------------------------------------------------------------
  def update_out
    return if @params[:out].nil?
    @params[:oc] += 1
    return if @params[:oc] < @params[:out]
    @params[:out_active] = true
  end
  #--------------------------------------------------------------------------
  # ● 执行移出
  #--------------------------------------------------------------------------
  def move_out
    @next_chara.move_out if @next_chara
    @params[:out_active] = true
  end
  #--------------------------------------------------------------------------
  # ● 已经移出？
  #--------------------------------------------------------------------------
  def out?
    self.opacity == 0
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    self.bitmap.dispose
    super
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
