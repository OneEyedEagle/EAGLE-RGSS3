#encoding:utf-8
$imported ||= {}
$imported["EAGLE-ScreenCharasVX"] = "2.0.0"
=begin
===============================================================================

    ┌--------------------------------------------------------------------┐
    ┆            ,""---.                                                 ┆
    ┆          ㄏ       `.                                               ┆
    ┆       _ノ ㄏō       \                                              ┆
    ┆      / ´             y                                             ┆
    ┆      \J==ノ   by.老鹰 (github.com/OneEyedEagle/EAGLE-RGSS3)        ┆
    └--------------------------------------------------------------------┘

     ■ 显示抖动文字 ■ VX
       
        本插件允许你在屏幕或地图的指定位置处显示一排不断抖动文字。
        实质为在 Spriteset_Map 中绑定了一个精灵组，用于实时更新文字精灵。

     ▼ 使用方法 ·=========================================================
      
       （简易版本）为了在屏幕上显示抖动文字，可在事件指令-脚本中填写：

       map_text(文本, x, y, wait, t, d)
      
       文本      → （字符串）需要显示的文本。
       x         → （数字）第一个文字的左上角在屏幕上的x位置。
       y         → （数字）第一个文字的左上角在屏幕上的y位置。
       wait      → （数字）显示一个文字后等待的帧数。
       t         → （数字）文字在抖动时，每隔 t 帧才会移动一个像素距离。
       d         → （数字）文字在抖动时，向上下左右移动的最大像素距离。

       ------------------------------------------------------------------
       □ 注意！

       RGSS2无法正确分割汉字编码，
       为了正常显示汉字，本插件不使用默认的分割方法，
       而是需要你手动在每个汉字之间添加一个特殊符号来分割。

       默认的分割符号为 % ，可搜索正则表达式 /[%]/ 自行修改。

       也因此，如果多个汉字间没有 % 符号，将一起绘制，一起抖动！
    
       ------------------------------------------------------------------
       □ 示例

       map_text("这%是%一%句%测%试%语%句")
        → 在屏幕上的随机位置显示“这是一句测试语句”。

       map_text("这%是%一%句%测%试%语%句", 200,100)
        → 在屏幕的 (200,100) 处显示“这是一句测试语句”。
       
       map_text("这%是%一%句%测%试%语%句", 200,100, 20)
        → 在屏幕的 (200,100) 处显示“这是一句测试语句”，且每显示一个字后都等待20帧。

     ======================================================================
        -                                                              -
        
     ▼ 使用方法 ·=========================================================

       （完整版本）为了在屏幕or地图上显示抖动文字，可在事件指令-脚本中填写：

       shake_text(文本, 哈希表)

       文本      → （字符串）需要显示的文本。
       哈希表    → （哈希）可以自定义的参数。

       □ 关于 哈希表：
       
       哈希表是Ruby中常用的 key-value 数据结构，此处可以定义以下 键值对：
       
       :x      → （数字）第一个文字显示在屏幕上的x位置。
       :y      → （数字）第一个文字显示在屏幕上的y位置。
       :on_map → （布尔值）传入true时，将更改为显示在地图上的(x,y)网格处。
                  默认false，即显示在屏幕上。
       :t      → （数字）显示一个文字后的等待帧数。
       :s      → （数字）文字在抖动时，每隔该帧数才会移动一像素。
       :d      → （数字）文字在抖动时，向上下左右移动的最大像素距离。
       :out    → （数字）文字的显示时间，时间结束将自动消失。
                        若不设置或传入 nil，则不会自动消失
       :id     → （任意）设置当前组名，可利用事件脚本移出这组文字。
       :type   → （数字）设置文字抖动的类型，默认0连续移动类，1高频瞬移类。
       :offset → （数字）文字之间的显示距离，默认0
     
       ------------------------------------------------------------------
       □ 示例

       shake_text("这%是%一%句%测%试%语%句", {:x => 200, :y => 100, :type => 1})
         → 在屏幕的 (200,100) 处显示该句，且使用高频抖动版本

       shake_text("这%是%一%句%测%试%语%句", {:x => 13, :y => 9, :on_map => true})
         → 在地图的 (13,9) 格子处显示该句

     ======================================================================
        -                                                              -
        
     ▼ 使用方法 ·=========================================================

       以下为对抖动文字的控制方法，依然是在事件指令-脚本中填写：

       move_out_shake_text(id)    → 移出指定组名的全部抖动文本
       move_out_all_text          → 移出全部抖动文本
       move_out_all_text(n)       → 移出全部抖动文本，且每移出一组后，等待n帧
       clear_map_text             → 直接清除全部抖动文本

     ======================================================================
        -                                                              -
        
     ▼ 使用方法 ·=========================================================

       以下为对抖动文字的绘制进行设置，可以直接在事件脚本中对其进行赋值来修改：

       EAGLE::MapChara.name    →（字符串）所用的字体
       EAGLE::MapChara.size    →（数字）字体大小
       EAGLE::MapChara.bold    →（布尔值）字体是否加粗
       EAGLE::MapChara.italic  →（布尔值）字体是否倾斜
       EAGLE::MapChara.shadow  →（布尔值）字体是否有阴影
       EAGLE::MapChara.color   →（Color对象）字体颜色
       EAGLE::MapChara.opacity_down   →（数字）不透明度的下限
       EAGLE::MapChara.opacity_up     →（数字）不透明度的上限

       在文本绘制前将存储当前设置，用来确保同一串文字的设置一致。

       ------------------------------------------------------------------
       □ 示例

       EAGLE::MapChara.size = 16 
        → 抖动文字的字号调整为 16

       EAGLE::MapChara.shadow = false
        → 关闭抖动文字的阴影

       EAGLE::MapChara.color = Color.new(255,0,0)
        → 抖动文字的默认绘制颜色调整为 红色

     ======================================================================
        -                                                              -
        
     更新历史
     ----------------------------------------------------------------------
     - 2025.2.26.19 重写注释 
     ----------------------------------------------------------------------
     
===============================================================================
=end

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

module EAGLE end
module EAGLE::MapChara
  #--------------------------------------------------------------------------
  # ● 属性方法
  #--------------------------------------------------------------------------
  class << self
    attr_accessor :text, :clear, :out_id, :move_out
    attr_accessor :name, :size, :bold, :italic, :shadow, :color
    attr_accessor :opacity_down, :opacity_up
  end
  #--------------------------------------------------------------------------
  # ● 新增
  #--------------------------------------------------------------------------
  @text = [] 
  def self.add(text, params = {})
    params[:on_map] ||= false
    params[:x] ||= rand(400)
    params[:y] ||= rand(400)
    params[:t] ||= 10 # duration
    params[:s] ||= 3 # shake
    params[:d] ||= 3 # offset
    params[:type] ||= 0
    params[:offset] ||= 0
    params[:font] = get_font
    t = text.split(/[%]/)
    @text.push([t, params])
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
    @opacity_down = 150
    @opacity_up   = 255
    @move_out = -1
  end
  #--------------------------------------------------------------------------
  # ● 获取当前的字体设置
  #--------------------------------------------------------------------------
  def self.get_font
    f = Font.new 
    f.name = EAGLE::MapChara.name
    f.size = EAGLE::MapChara.size
    f.bold = EAGLE::MapChara.bold
    f.italic = EAGLE::MapChara.italic
    f.shadow = EAGLE::MapChara.shadow
    f.color = EAGLE::MapChara.color
    f
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
    @characters = [] # 存储全部文字精灵的数字
    @ids = {} # id => first_chara
    @duration_count = 0 # 单个字符串中绘制等待计数
    @text_count = 0     # 单个字符串中绘制计数
    @text_width = 0     # 单个字符串中绘制宽度计数
    @move_out_count = 0 # 移出时的等待计数
    @first_chara = true # 当前移入的为该句的第一个文字？
    @temp_bitmap = Bitmap.new(32, 32)
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    clear_first if !@characters.empty?
    @characters.each { |c| c.update }
    clear if EAGLE::MapChara.clear
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
    
    tp = EAGLE::MapChara.text[0]
    t = tp[0][@text_count]
    params = tp[1].dup
    @temp_bitmap.font = params[:font]
    r = @temp_bitmap.text_size(t)
    params[:dx] = @text_width + params[:offset]
    params[:dy] = 0
    params[:cw] = r.width
    params[:ch] = r.height
    s = Sprite_MapCharacter.new(t, params) 
    @characters.push(s)
    @text_width += r.width + params[:offset]
    
    if @first_chara
      @first_chara = false
      @ids[params[:id]] = s if params[:id]
    else
      @characters[-1].next_chara = s
    end
    @duration_count = params[:t]
    
    @text_count += 1
    # 处理当前句结束
    if @text_count >= tp[0].size
      EAGLE::MapChara.text.shift
      @duration_count = 0
      @text_count = 0
      @text_width = 0
      @first_chara = true
    end
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
    #@temp_bitmap.dispose
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
  def initialize(c, ps)
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
    
    t1 = EAGLE::MapChara.opacity_down
    t2 = EAGLE::MapChara.opacity_up
    self.opacity = t1 + rand(t2 - t1)
    
    self.bitmap = Bitmap.new(@params[:cw], @params[:ch])
    self.bitmap.font = @params[:font]
    self.bitmap.draw_text(0,0,self.width,self.height, c)
    
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
    case @params[:type]
    when 1; update_shake2
    else;   update_shake
    end
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
    @params[:vo] *= -1 if self.opacity < EAGLE::MapChara.opacity_down ||
      self.opacity >=  EAGLE::MapChara.opacity_up
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
  # ● 更新抖动（高频）
  #--------------------------------------------------------------------------
  def update_shake2
    return if (@params[:sc] -= 1) > 0
    @params[:sc] = @params[:s]
    
    @params[:sdx] = (-1 + rand() * 2) * @params[:d]
    @params[:sdy] = (-1 + rand() * 2) * @params[:d]
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
