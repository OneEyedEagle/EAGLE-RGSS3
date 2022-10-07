#==============================================================================
# ■ 自由显示光标 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
#==============================================================================
$imported ||= {}
$imported["EAGLE-Cursor"] = "1.0.2"
#==============================================================================
# - 2022.9.30.21 
#==============================================================================
# - 本插件新增了一个允许利用全局脚本自由控制位置的光标
#-----------------------------------------------------------------------------
# 【使用】
#
# 1. 利用全局脚本创建光标（仅一次）
#
#       CURSOR.new(id, ps)
#
#    其中 id 为该光标的名称（需要与其他光标不同）
#    其中 ps 为可选的参数（均可不填），具体如下：
#
#      :vp => Viewport,  # 光标的所在视图
#      :z => 数字,       # 光标的Z值
#      :pic => 字符串,   # 位于 Graphics/System 下的光标图片
#                          图片规格：正方形，2x2，四块区域分别对应四角的光标
# 
# - 注意：如果已经存在，不会重复创建
#
#-------------------------------------------------------------------
# 2. 利用全局脚本定位光标（立即生效）
#
#       CURSOR.reset(id, ps)   → 将光标移出屏幕外
#
#       CURSOR.set_rect(id, rect, ps)  → 将光标定位到屏幕Rect区域上
#                                         rect = Rect.new(100,100,50,50)
#
#       CURSOR.set_xywh(id, x, y, w, h, ps)  → 将光标定位到屏幕（x,y,w,h）区域
#                       与 CURSOR.set_rect(id, Rect.new(x,y,w,h), ps) 相同效果 
#
#       CURSOR.set_sprite(id, s, ps)  → 将光标定位到精灵s的区域上
#
#       CURSOR.set_map_xy(id, x, y, ps) → 将光标定位到地图(x,y)上
#
#    （以下需要使用【组件-通用方法汇总 by老鹰】）
#
#       CURSOR.set_map_chara(id, eid, ps)  → 将光标定位到地图eid号事件上
#              0代表当前事件，正数为对应id号事件，负数为队伍中对应数据库id号的角色 
#
#       CURSOR.set_battler(id, bid, ps)  → 将光标定位到战斗bid号战斗者上
#                         正数为敌人的敌群中的序号，负数为队伍中对应数据库id号角色
#
#       CURSOR.set_pic(id, pid, ps)  → 将光标定位到pid号图片上
#
#
#   其中 ps 为可选的参数（均可不填），具体如下：
#
#     :text => 字符串,  #（需要【组件-位图绘制转义符文本 by老鹰】）
#                         显示在光标上的帮助文本
#     :t => 数字,       # 光标移动所需的帧数
#     :d => 数字,       # 光标位置向内侧移动的像素值，数字越大越接近被包围目标
#     :ins => boolean,  # true 代表无移动动画，直接定位（默认false）
#     :map => boolean,  # true 代表绑定于地图上，随地图移动（默认false）
#
#
# - 注意：该系列方法不会把光标绑定到目标上，
#         也因此目标移动时，光标将不会自动跟随，请自己手动重复调用
#
#-------------------------------------------------------------------
# 3. 利用全局脚本删除光标
#
#       CURSOR.delete(id)
#
#-----------------------------------------------------------------------------
# 【示例】
#
# 1. 在 事件指令-脚本 中：创建一个光标，并显示到当前地图的1号事件上
#
=begin

CURSOR.new("指引")
CURSOR.set_map_chara("指引", 1)

=end
#
# 2. 在 事件指令-脚本 中：在1号事件的指令中，将光标移动到2号事件上
#
=begin

CURSOR.set_map_chara("指引", 2)

=end
#
#==============================================================================

module CURSOR 
  #--------------------------------------------------------------------------
  # ●【常量】光标的Z值
  #--------------------------------------------------------------------------
  Z = 300
  
  #--------------------------------------------------------------------------
  # ●【常量】光标的图片
  #  需要正方形的图片，等比例分隔为 2x2 的四块，对应四角的光标
  #--------------------------------------------------------------------------
  PIC = "Cursor"
  #--------------------------------------------------------------------------
  # ● 获取光标的位图
  #--------------------------------------------------------------------------
  def self.get_bitmap(i, file)
    file = PIC if file == nil || file == ""
    begin
      b = Cache.system(file)
    rescue
      w = 22
      b = Bitmap.new(w, w)
      b.fill_rect(0,0,w,w, Color.new(255,255,255))
      d = 2
      b.clear_rect(0, 0, w/2-d, w/2-d)
      b.clear_rect(w/2+d, 0, w/2-d, w/2-d)
      b.clear_rect(0, w/2+d, w/2-d, w/2-d)
      b.clear_rect(w/2+d, w/2+d, w/2-d, w/2-d)
    end
    w = b.width / 2
    h = b.height / 2
    case i 
    when 0
      r = Rect.new(0, 0, w, h)
    when 1
      r = Rect.new(w, 0, w, h)
    when 2
      r = Rect.new(0, h, w, h)
    when 3
      r = Rect.new(w, h, w, h)
    end
    b2 = Bitmap.new(w, h)
    b2.blt(0, 0, b, r)
    b2
  end
  #--------------------------------------------------------------------------
  # ● 光标移动时的缓动函数
  #--------------------------------------------------------------------------
  def self.ease_value(x)
    return x * x
  end
  
  #--------------------------------------------------------------------------
  # ● 生成一个新的光标
  #--------------------------------------------------------------------------
  def self.new(id, ps={})
    return if exist?(id)
    @spritesets[id] = Spriteset_EagleCursor.new(ps)
  end
  #--------------------------------------------------------------------------
  # ● 删除一个光标
  #--------------------------------------------------------------------------
  def self.delete(id)
    return true if !exist?(id)
    @spritesets[id].dispose
    @spritesets.delete(id)
    return true
  end
  #--------------------------------------------------------------------------
  # ● 光标存在？
  #--------------------------------------------------------------------------
  def self.exist?(id)
    @spritesets[id] != nil
  end

  #--------------------------------------------------------------------------
  # ● 重置光标的位置（移出）
  #--------------------------------------------------------------------------
  def self.reset(id, ps={})
    return if !exist?(id)
    @spritesets[id].set_move(ps)
  end
  #--------------------------------------------------------------------------
  # ● 将光标移动到指定矩形上（窗口坐标）
  #--------------------------------------------------------------------------
  def self.set_rect(id, rect, ps={})
    return if !exist?(id)
    ps[:rect] = rect
    @spritesets[id].set_move(ps)
  end
  #--------------------------------------------------------------------------
  # ● 将光标移动到指定位置上（窗口坐标）
  #--------------------------------------------------------------------------
  def self.set_xywh(id, x, y, w, h, ps={})
    return if !exist?(id)
    ps[:rect] = Rect.new(x, y, w, h)
    @spritesets[id].set_move(ps)
  end 
  #--------------------------------------------------------------------------
  # ● 将光标移动到指定精灵上（窗口坐标）
  #--------------------------------------------------------------------------
  def self.set_sprite(id, s, ps={})
    return if !exist?(id)
    return if s == nil
    ps[:sprite] = s
    @spritesets[id].set_move(ps)
  end
  #--------------------------------------------------------------------------
  # ● 将光标移动到指定地图角色上（地图坐标）
  #--------------------------------------------------------------------------
  def self.set_map_chara(id, eid, ps={})
    return if !exist?(id)
    s = EAGLE_COMMON.get_chara_sprite(eid)
    ps[:map] = true
    set_sprite(id, s, ps)
  end
  #--------------------------------------------------------------------------
  # ● 将光标移动到指定地图位置上（地图坐标）
  #--------------------------------------------------------------------------
	def self.set_map_xy(id, x, y, ps={})
    return if !exist?(id)
    ps[:map] = true
		wx = 32 * (x - $game_map.display_x)
		wy = 32 * (y - $game_map.display_y)
		set_xywh(id, wx, wy, 32, 32, ps)
	end
  #--------------------------------------------------------------------------
  # ● 将光标移动到指定战斗者上（窗口坐标）
  #--------------------------------------------------------------------------
  def self.set_battler(id, bid, ps={})
    return if !exist?(id)
    s = EAGLE_COMMON.get_battler_sprite(bid)
    set_sprite(id, s, ps)
  end
  #--------------------------------------------------------------------------
  # ● 将光标移动到指定显示图片上（窗口坐标）
  #--------------------------------------------------------------------------
  def self.set_pic(id, pid, ps={})
    return if !exist?(id)
    s = EAGLE_COMMON.get_pic_sprite(pid)
    set_sprite(id, s, ps)
  end
  
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def self.init 
    @spritesets = {}
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def self.update 
    @spritesets.each do |id, s|
      s.update
    end
  end
end

class << DataManager
  #--------------------------------------------------------------------------
  # ● 初始化模块
  #--------------------------------------------------------------------------
  alias eagle_cursor_init init 
  def init
    eagle_cursor_init
    CURSOR.init
  end
end

class Scene_Base 
  #--------------------------------------------------------------------------
  # ● 基础更新
  #--------------------------------------------------------------------------
  alias eagle_cursor_update_basic update_basic 
  def update_basic
    eagle_cursor_update_basic
    CURSOR.update
  end
end

class Spriteset_EagleCursor
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(ps = {})
    @sprites = []
    init_sprites(ps)
    init_help(ps)
    @move = { :flag => false }
    set_move({:ins => true})
  end
  #--------------------------------------------------------------------------
  # ● 初始化精灵
  #--------------------------------------------------------------------------
  def init_sprites(ps)
    # 位置依次为 0左上 1右上 2左下 3右下
    4.times do |i|
      s = Sprite_EagleCursor.new(self, ps[:vp], i)
      s.bitmap = CURSOR.get_bitmap(i, ps[:pic])
      s.z = ps[:z] || CURSOR::Z
      s.visible = false
      @sprites.push(s)
    end
    @sprites[0].ox = @sprites[0].width; @sprites[0].oy = @sprites[0].height 
    @sprites[1].ox = 0; @sprites[1].oy = @sprites[1].height 
    @sprites[2].ox = @sprites[2].width; @sprites[2].oy = 0
    @sprites[3].ox = 0; @sprites[3].oy = 0
  end
  #--------------------------------------------------------------------------
  # ● 初始化帮助文本的精灵
  #--------------------------------------------------------------------------
  def init_help(ps)
    @sprite_help = Sprite.new(ps[:vp])
    @sprite_help.z = ps[:z] || CURSOR::Z 
    @sprite_help.z -= 1
    @sprite_help.visible = false
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    @sprite_help.bitmap.dispose
    @sprite_help.dispose
    @sprites.each { |s| s.dispose }
  end 
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update 
    if @move[:flag]
      update_move
    else
      @sprites.each { |s| s.update }
    end
    update_help if @sprite_help.bitmap
  end
  #--------------------------------------------------------------------------
  # ● 设置移动
  #--------------------------------------------------------------------------
  def set_move(ps = {})
    # 记录参数
    @move[:ps] = ps
    # 记录初始位置，将由 :xs_1 运动到 :xs_2
    @move[:xs_1] = @sprites.collect { |s| s.x_cur } 
    @move[:ys_1] = @sprites.collect { |s| s.y_cur }
    # 设置是否绑定在地图上
    @move[:map_x] = $game_map.display_x
    @move[:map_y] = $game_map.display_y
    @move[:on_map] = ps[:map] || false
    # 获得需要被选择的矩形
    if ps[:rect]
      r = ps[:rect]
    elsif ps[:sprite]
      s = ps[:sprite]
      r = Rect.new(s.x-s.ox, s.y-s.oy, s.width, s.height)
    else 
      r = Rect.new(0, 0, Graphics.width, Graphics.height)
    end
    if ps[:d]
      d = ps[:d].to_i
      r.x += d
      r.y += d
      r.width -= 2 * d
      r.height -= 2 * d
    end
    @move[:r] = r
    set_move_des_xy(r, ps)
    # 处理是否立即移动
    if ps[:ins]
      @sprites.each_with_index do |s, i|
        s.x_f = @move[:xs_2][i]
        s.y_f = @move[:ys_2][i]
        s.update
        s.visible = true
      end
      finish_move
      return
    end
    # 处理移动
    @move[:t] = ps[:t] || 20
    @move[:c] = 0
    start_move
  end
  #--------------------------------------------------------------------------
  # ● 设置移动的目的地
  #--------------------------------------------------------------------------
  def set_move_des_xy(r, ps)
    @move[:xs_2] = [r.x, r.x+r.width, r.x,          r.x+r.width]
    @move[:ys_2] = [r.y, r.y,         r.y+r.height, r.y+r.height]
  end
  #--------------------------------------------------------------------------
  # ● 开始移动
  #--------------------------------------------------------------------------
  def start_move
    @move[:flag] = true
    @sprites.each { |s| s.start_move }
    hide_help
  end
  #--------------------------------------------------------------------------
  # ● 更新移动
  #--------------------------------------------------------------------------
  def update_move
    return finish_move if @move[:c] >= @move[:t]
    @move[:c] += 1 
    @sprites.each_with_index do |s, i|
      x1 = @move[:xs_1][i]; y1 = @move[:ys_1][i]
      x2 = @move[:xs_2][i]; y2 = @move[:ys_2][i]
      v = CURSOR.ease_value(@move[:c] * 1.0 / @move[:t])
      s.x_f = x1 + (x2 - x1) * v
      s.y_f = y1 + (y2 - y1) * v
      s.update
    end
  end
  #--------------------------------------------------------------------------
  # ● 结束移动
  #--------------------------------------------------------------------------
  def finish_move
    @move[:flag] = false 
    @sprites.each { |s| s.finish_move }
    set_help(@move[:ps])
    show_help
  end
  #--------------------------------------------------------------------------
  # ● 是否绑定到地图上？
  #--------------------------------------------------------------------------
  def on_map?
    @move[:on_map] == true
  end
  #--------------------------------------------------------------------------
  # ● 获取因地图滚动而产生的偏移值
  #--------------------------------------------------------------------------
  def map_offset_x
    32 * (@move[:map_x] - $game_map.display_x)
  end
  def map_offset_y
    32 * (@move[:map_y] - $game_map.display_y)
  end
  #--------------------------------------------------------------------------
  # ● 绘制帮助文本
  #--------------------------------------------------------------------------
  def set_help(ps)
    if @sprite_help.bitmap
      @sprite_help.bitmap.dispose
      @sprite_help.bitmap = nil
    end
    return if ps[:text] == nil || ps[:text] == ""
    
    return if $imported["EAGLE-DrawTextEX"] == nil
    # 预绘制文字
    ps2 = { :ali => 1, :lhd => 4 }
    d = Process_DrawTextEX.new(ps[:text], ps2)
    # 新建一个位图
    tag_h = 5
    c = Color.new(0,0,0,150)
    b = Bitmap.new(d.width + 4 *2, d.height + 2 * 2 + tag_h)
    b.fill_rect(0,0,b.width,b.height-tag_h, c)
    # 绘制文字
    d.bind_bitmap(b)
    ps2[:x0] = 4
    ps2[:y0] = 2
    d.run
    # 绘制箭头
    [ [-4,0],[-3,0],[-2,0],[-1,0],[0,0],[1,0],[2,0],[3,0],[4,0],
      [-3,1],[-2,1],[-1,1],[0,1],[1,1],[2,1],[3,1],
      [-2,2],[-1,2],[0,2],[1,2],[2,2],
      [-1,3],[0,3],[1,3],
      [0,4] ].each do |xy|
      b.set_pixel(b.width / 2 + xy[0], b.height - 5 + xy[1], c)
    end

    @sprite_help.bitmap = b
    @sprite_help.ox = @sprite_help.width / 2
    @sprite_help.oy = @sprite_help.height
  end
  #--------------------------------------------------------------------------
  # ● 更新帮助文本
  #--------------------------------------------------------------------------
  def update_help
    @sprite_help.x = @sprites[0].x_cur + @move[:r].width / 2
    @sprite_help.y = @sprites[0].y_cur
  end
  #--------------------------------------------------------------------------
  # ● 显示/隐藏帮助（在移动完成后）
  #--------------------------------------------------------------------------
  def show_help
    @sprite_help.visible = true
  end
  def hide_help
    @sprite_help.visible = false
  end
end

class Sprite_EagleCursor < Sprite
  attr_reader    :index
  attr_accessor  :x_f, :y_f
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(set, vp = nil, index = 0)
    super(vp)
    @set = set
    @index = index
    @x_f = @y_f = 0.0  # 理论位置
    @x_d = @y_d = 0  # 因为自己的动态效果而产生的位置偏移
    @flag_anim = true
  end 
  #--------------------------------------------------------------------------
  # ● 开始移动
  #--------------------------------------------------------------------------
  def start_move
    @flag_anim = false
    @fiber_anim = nil
    reset_anim
  end
  #--------------------------------------------------------------------------
  # ● 结束移动
  #--------------------------------------------------------------------------
  def finish_move
    @flag_anim = true
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose 
    self.bitmap.dispose if self.bitmap
    super 
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update 
    super 
    update_position
    if @flag_anim
      @fiber_anim = Fiber.new { process_anim } if @fiber_anim == nil 
      @fiber_anim.resume 
    end
  end 
  #--------------------------------------------------------------------------
  # ● 更新位置
  #--------------------------------------------------------------------------
  def update_position
    self.x = x_cur + @x_d
    self.y = y_cur + @y_d
  end
  #--------------------------------------------------------------------------
  # ● 获取当前位置
  #--------------------------------------------------------------------------
  def x_cur
    v = @x_f
    v += @set.map_offset_x if @set.on_map?
    v
  end
  def y_cur
    v = @y_f
    v += @set.map_offset_y if @set.on_map?
    v
  end
  #--------------------------------------------------------------------------
  # ● 重置小幅移动
  #--------------------------------------------------------------------------
  def reset_anim
    @x_d = 0
    @y_d = 0
  end
  #--------------------------------------------------------------------------
  # ● 处理小幅移动
  #--------------------------------------------------------------------------
  def process_anim
    reset_anim
    case @index
    when 0; vx = -1; vy = -1
    when 1; vx = 1 ; vy = -1
    when 2; vx = -1; vy = 1
    when 3; vx = 1 ; vy = 1
    end
    wait = 5
    d = 3
    d.times do
      @x_d += (1 * vx)
      @y_d += (1 * vy)
      Fiber.yield
    end
    wait.times { Fiber.yield }
    (2*d).times do
      @x_d -= (1 * vx)
      @y_d -= (1 * vy)
      Fiber.yield
    end
    wait.times { Fiber.yield }
    d.times do
      @x_d += (1 * vx)
      @y_d += (1 * vy)
      Fiber.yield
    end
    @fiber_anim = nil
  end
end
