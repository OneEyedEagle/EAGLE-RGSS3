#————————————————————————————————————————
# ●Unravel_Bitmap By.Lyaci
#   *位图消逝 v2.8
#   -图片的散开效果
#   -适用于 RPG MAKER XP/VX/ACE，RGD
#————————————————————————————————————————
=begin
————————————————————————————————————————
基本使用：
 必要参数
 a = Bitmap.new(sx,sy,aim_bitmap,x,y,w,h,n)
 全部参数
 a = Bitmap.new(sx,sy,aim_bitmap,x,y,w,h,n,d,co,type,rc,clear,viewport){|sprite|}
 参数说明：
 sx,sy：精灵顶点 aim_bitmap：源位图对象 x,y,w,h：定位源位图坐标宽高
 n：精灵数量 设为<大于0>为设定数量 设为<0>为铺满 设为<-1>为网格减半铺满
 d：直径、边长 co：透明度增加最小值
 type：移动类型符号（见注释处）
 rc：分离样式<:C-圆形><:S-正方形><:T-三角形>
 clear：清除源位图开关 viewport：显示视口
 {|sprite|}：初始代码块（优先级大于所有内部效果） 参数为精灵
————————————————————————————————————————
深入使用：
 控制相关方法：
 Unravel_Bitmap#get_all_sprite 取得所有存在精灵
 Unravel_Bitmap#get_viewport 取得视口
 Unravel_Bitmap#begin 开始 Unravel_Bitmap#stop 停止
 效果相关方法：
 Unravel_Bitmap#move_effe 增加移动操作代码块（自定义效果，优先级大于所有内部效果）
  Unravel_Bitmap#move_effe {|sprite,index|...} <sprite-精灵><index-编号，可省略>
 Unravel_Bitmap#fast_effe(a,b,t) 增加快慢效果
  a：初始速度倍率 b：结束速度倍率 t：经过时长（帧）
 Unravel_Bitmap#turning_effe = mx 增加或移除转向效果
  mx = 转向间隔值 为nil则移除
 Unravel_Bitmap#gradual_speed_effe(as,hit,mx) 增加或移除加速度效果
   as为nil则移除，参数解释转到Sprite_Unbit内部查看
 Unravel_Bitmap#gradual_zoom_effe(up,min,max,re) 增加或移除扩缩效果
   up为nil则移除，参数解释转到Sprite_Unbit内部查看
 Unravel_Bitmap#flee_effe(mx,fs,fr) 增加或移除逃逸效果
   up为nil则移除，参数解释转到Sprite_Unbit内部查看
 Unravel_Bitmap#stretch_effe(izx,izy,sig,rzx,rzy) 增加或移除拉缩效果
   izx为nil则移除，参数解释转到Sprite_Unbit内部查看
 Unravel_Bitmap#ax Unravel_Bitmap#ay 移动横/纵倍率（实时）
 Unravel_Bitmap#ao 透明倍率（实时）
 类方法：
 Unravel_Bitmap.make_speed(xp,yp,op) 移动增幅
  xp yp op 对应新的增幅数，越大运动越快，省略恢复默认 - 默认为 100,100,550
 Unravel_Bitmap.make_otake(sw) 透明过滤，开启增加效率
  sw：true 开启 false关闭 默认开启
 Unravel_Bitmap.make_otake_value(value) 透明过滤值
  value：0~255 默认为 1
 Unravel_Bitmap.make_turning_effe(bool)
 Unravel_Bitmap.make_gradual_speed_effe(bool)
 Unravel_Bitmap.make_gradual_zoom_effe(bool)
 Unravel_Bitmap.make_flee_effe(bool)
 Unravel_Bitmap.make_stretch_effe(bool)
  bool：各效果初始开启为设置的常数
 *该定义的类方法多用于生成实例的前后 是可逆的效果状态
 精灵方法：
 Sprite_Unbit#
  bs：相对尺寸
  xo yo：位置
  rx ry：移动量
  oo ro：透明量/增减量
  angle_face：旋转方向
  turning：转向开关
  turn_max：转向最大间隔
  turning_set(mx)：设置转向
  gradual_speed：加速度开关
  gradual_speed_set(as,hit,mx)：设置加速度
  gradual_zoom：缩放开关
  gradual_zoom_set(up,min,max,re)：设置缩放
  new_size(zoom) 取得新的相对尺寸
  flee：逃逸开关
  flee_set(mx,fs,fr)：设置逃逸
  参数解释转到Sprite_Unbit内部查看
 更多：
  请参考示例
————————————————————————————————————————
注释：
type：移动类型符号
 <:RU-右上><:RD-右下><:LU-左上><:LD-左下>
 <:LR-两侧><:LRUD-四周扩散>
 <:DD-往下><:UU-往上><:LL-往左><:RR-往右>
 <:XX-横向><:YY-纵向><:SO-固定>
 <:TEN-十字><:L_LEAN-左斜向><:R_LEAN-右斜向>
已做成应用：
 行走图效果
 战斗死亡效果
 地图名效果
扩展子类：
 不规则碎片 UB_Split
*Ver
 Ver:1.0 Date:2014.9.20 ~ Ver:2.8 Date:2019.9.24
————————————————————————————————————————
声明：
本体与拓展脚本可用于非商业、商业，使用和转载请保留此信息
=end
#————————————————————————————————————————
class Unravel_Bitmap
  #————————————————————————————————————————
  # 设置
  #————————————————————————————————————————
  AX = AY = 1.0     #移动速度倍率
  AO = 1.0          #消失倍率
  RX_BASE = 100.0   #横移动速率
  RY_BASE = 100.0   #纵移动速率
  RO_BASE = 100.0   #消失速率
  XP_BASE = 100     #横移动基础值
  YP_BASE = 100     #纵移动基础值
  OP_BASE = 550     #消失基础值
  TURN_EFFE = false #是否转向效果v2.5 逃逸开启的话建议关闭该效果
  TURN_MX = 300     #转向间隔
  GSPEED_EFFE = true#是否加速度效果v2.6
  GSPEED_EFFE_STRETCH = true#是否把拉缩效果嵌入加速度效果（不可逆）v2.8
  GZOOM_EFFE = true #是否缩放效果v2.6
  FLEE_EFFE = true  #是否逃逸效果v2.7
  STRETCH_EFFE = false#是否拉缩效果v2.8 建议用类方法独立开启
  OTAKE = true      #是否透明过滤
  OTAKE_VALUE = 1   #透明最小过滤
  SZ = 5000         #初始优先级
  WIN_W = defined?(Graphics.width) ? Graphics.width : 640    #窗口宽
  WIN_H = defined?(Graphics.height) ? Graphics.height : 480  #窗口高
  #————————————————————————————————————————
  attr_accessor :ax,:ay,:ao
  attr_accessor :fast_effe
  #————————————————————————————————————————
  #*新建一个要拆（？？）的位图对象
  #————————————————————————————————————————
  def initialize(sx,sy,aim_bitmap,x,y,w,h,n,d=4,co=0.5,type=:RU,rc=:C,
    clear=true,viewport=nil,&ini_block)
    @ax,@ay,@ao = AX,AY,AO
    @turning_effe
    @sprite_datas = []; @viewport = viewport;jn = number = n;oo = 255
    all_clear = (clear && jn < 1) ? true : false
    clear = all_clear ? false : clear
    @type_rand = false
    case rc #in rc type
    when :C
      vrc = switch_proc {|ex,ey,d,b|aim_bitmap.rc_circle(ex,ey,d,0,true,1.0,b,clear) }
    when :S
      vrc = switch_proc {|ex,ey,d,b|aim_bitmap.rc_square(ex,ey,d,d,b,clear) }
    when :T
      vrc = switch_proc {|ex,ey,d,b|aim_bitmap.rc_triangle(ex,ey,d,1.0,2.0,b,clear) }
    end
    case number #in rcs
    when -1
      n = (w*h/d**2.0/2).ceil;lw = (w/d.to_f/2).ceil;lh = (n/(h/d.to_f)).ceil
      rcs = switch_proc {|i|@xo=x+sx+i%lw*d*2+(i/lw%2*d);@yo=y+sy+i/lh*d }
    when 0
      n = (w*h/d**2.0).ceil;lw = (w/d.to_f).ceil;lh = (n/(h/d.to_f)).ceil
      rcs = switch_proc {|i|@xo=x+sx+i%lw*d;@yo=y+sy+i/lh*d }
    else
      rcs = switch_proc {|i|@xo=x+sx+rand(w);@yo=y+sy+rand(h) }
    end
    type_each(type) #in move type
    d2 = d/2;number = n ; number.times{|i|rcs.call(i)
    next if @@otake && aim_bitmap.get_pixel(@xo-sx+d2,@yo-sy+d2).alpha < @@otake_value
    rx = (rand(@@speed_x)+1) / RX_BASE;ry = (rand(@@speed_y)+1) / RY_BASE
    ro = co + rand(@@speed_o) / RO_BASE
    rx,ry = @mvp.call(rx,ry,i) if @type_rand
    sprite = Sprite_Unbit.new(viewport)
    @sprite_datas << sprite
    sprite.xo = @xo
    sprite.yo = @yo
    sprite.oo = oo
    sprite.rx = rx
    sprite.ry = ry
    sprite.ro = ro
    sprite.bs = d
    sprite.x = @xo;sprite.y = @yo;sprite.z = SZ
    sprite.turning_set(TURN_MX) if @@turning_effe
    sprite.gradual_speed_set() if @@gradual_speed_effe
    sprite.gradual_zoom_set() if @@gradual_zoom_effe
    sprite.flee_set() if @@flee_effe
    sprite.stretch_set() if @@stretch_effe
    sprite.bitmap = Bitmap.new(d,d)
    vrc.call(@xo-sx,@yo-sy,d,sprite.bitmap)
    ini_block.call(sprite) if ini_block }
    aim_bitmap.clear_rect(x,y,w,h) if all_clear
    self.begin
  end
  #————————————————————————————————————————
  #*类型转数值
  #————————————————————————————————————————
  def type_each(type=nil)
    case type
    when :RU
      @type_rand = true
      @mvp = switch_yield {|a,b,i| return +a,-b }
    when :LU
      @type_rand = true
      @mvp = switch_yield {|a,b,i| return -a,-b }
    when :RD
      @type_rand = true
      @mvp = switch_yield {|a,b,i| return +a,+b }
    when :LD
      @type_rand = true
      @mvp = switch_yield {|a,b,i| return -a,+b }
    when :RU
      @type_rand = true
      @mvp = switch_yield {|a,b,i| return +a,-b }
    when :DD
      @type_rand = true
      @mvp = switch_yield {|a,b,i| return 0,+b }
    when :UU
      @type_rand = true
      @mvp = switch_yield {|a,b,i| return 0,-b }
    when :LL
      @type_rand = true
      @mvp = switch_yield {|a,b,i| return -a,0 }
    when :RR
      @type_rand = true
      @mvp = switch_yield {|a,b,i| return +a,0 }
    when :SO
      @type_rand = true
      @mvp = switch_yield {|a,b,i| return 0,0 }
    when :LR
      @type_rand = true
      @mvp = switch_yield {|a,b,i| a = -a if 0.eql?(i%2);return a,-b }
    when :LRUD
      @type_rand = true
      @mvp = switch_yield {|a,b,i| a = -a if 0.eql?(i%2)
      b = -b if 0.eql?((i-1)%3);return a,b }
    when :XX
      @type_rand = true
      @mvp = switch_yield {|a,b,i| a = -a if 0.eql?(i%2)
      b = -b if 0.eql?((i-1)%3);return -a,0 }
    when :YY
      @type_rand = true
      @mvp = switch_yield {|a,b,i| a = -a if 0.eql?(i%2)
      b = -b if 0.eql?((i-1)%3);return 0,-b }
    when :TEN
      @type_rand = true
      @mvp = switch_yield {|a,b,i|
      ten = [-a,a,0,0,0,0,-b,b]
      idx = i%4
      return ten[idx],ten[idx+4] }
    when :L_LEAN
      @type_rand = true
      @mvp = switch_yield {|a,b,i| a,b = -a,-b if 0.eql?(i%2);return a,b }
    when :R_LEAN
      @type_rand = true
      @mvp = switch_yield {|a,b,i| a,b = -a,-b if 0.eql?(i%2);return -a,b }
    end
  end
  #————————————————————————————————————————
  #*转换
  #————————————————————————————————————————
  def switch_yield
    lambda
  end
  def switch_proc(&block)
    block
  end
  #————————————————————————————————————————
  #*添加移动效果块（每帧执行/每精灵）
  #————————————————————————————————————————
  def move_effe(&move_proc)
    @move_effe_proc = move_proc
  end
  #————————————————————————————————————————
  #*添加快慢效果块（每帧执行/每实例）
  #————————————————————————————————————————
  def fast_effe(a=0.2,b=2.5,t=80)
    @ax = @ay = a if a
    @fast_effe_timer = 0
    @fast_effe = Proc.new {
    @fast_effe_timer += 1
    @ax = @ax + Math.log(@fast_effe_timer)/(t*10)#2
    @ay = @ay + Math.log(@fast_effe_timer)/(t*10)#2
    if @fast_effe_timer >= t
      @ax = @ay = b if b
      @fast_effe = nil
    end
    }
  end
  #————————————————————————————————————————
  #*添加转向效果 重新赋值则初始化执行 nil则关闭（每帧执行/每精灵）
  #————————————————————————————————————————
  def turning_effe=(mx)
    if mx
      @sprite_datas.each {|sprite| sprite.turning_set(mx) }
    else
      @sprite_datas.each {|sprite| sprite.turning = false }
    end
  end
  #————————————————————————————————————————
  #*添加加速度效果 重新赋值则初始化执行 第一个参数nil则关闭（每帧执行/每精灵）
  #————————————————————————————————————————
  def gradual_speed_effe(as=0.05, hit=10, mx=60)
    if as
      @sprite_datas.each {|sprite| sprite.gradual_speed_set(as,hit,mx) }
    else
      @sprite_datas.each {|sprite| sprite.gradual_speed = false }
    end
  end
  #————————————————————————————————————————
  #*添加缩放效果 重新赋值则初始化执行 第一个参数nil则关闭（每帧执行/每精灵）
  #————————————————————————————————————————
  def gradual_zoom_effe(up=100, min=0.5, max=1.5, re=30)
    if as
      @sprite_datas.each {|sprite| sprite.gradual_zoom_set(up,min,max,re) }
    else
      @sprite_datas.each {|sprite| sprite.gradual_zoom = false }
    end
  end
  #————————————————————————————————————————
  #*添加逃逸效果 重新赋值则初始化执行 第一个参数nil则关闭（每帧执行/每精灵）
  #————————————————————————————————————————
  def flee_effe(mx=20, fs=1.0, fr=20)
    if mx
      @sprite_datas.each {|sprite| sprite.flee_set(mx,fs,fr) }
    else
      @sprite_datas.each {|sprite| sprite.flee = false }
    end
  end
  #————————————————————————————————————————
  #*添加拉缩效果 重新赋值不会初始化 第一个参数nil则关闭（每帧执行/每精灵）
  #————————————————————————————————————————
  def stretch_effe(izx=2.0, izy=0.5, sig=true, rzx=0.02,rzy=0.001)
    if izx
      @sprite_datas.each {|sprite| sprite.stretch_set(izx,izy,sig,rzx,rzy) }
    else
      @sprite_datas.each {|sprite| sprite.stretch = false }
    end
  end
  #————————————————————————————————————————
  #*取得实例所有精灵（Sprite_Unbit对象）
  #————————————————————————————————————————
  def get_all_sprite
    @sprite_datas
  end
  #————————————————————————————————————————
  #*取得视口
  #————————————————————————————————————————
  def get_viewport
    @viewport
  end
  #————————————————————————————————————————
  #*实例控制-停止、重新开始（实例全体数据）
  #————————————————————————————————————————
  def stop
    Graphics.unvb_ins_all.delete(self)
  end
  def begin
    return if Graphics.unvb_ins_all.include?(self)
    Graphics.unvb_ins_all << self
  end
  #————————————————————————————————————————
  #*更新
  #————————————————————————————————————————
  def update
    @sprite_datas.each_with_index {|sprite,index|
    sprite.update(@ax,@ay,@ao)
    move_update(sprite,index)
    unless sprite.disposed?
      unless sprite.oo > 0
        sprite.dispose;sprite.bitmap.dispose
        @sprite_datas.delete_at(index)
        next
      end
      auto_dispose(sprite,index)
    end }
    @fast_effe.call if @fast_effe
    stop if @sprite_datas.empty?
  end
  def move_update(sprite,index)
    @move_effe_proc.call(sprite,index) if @move_effe_proc
  end
  #————————————————————————————————————————
  #*释放
  #————————————————————————————————————————
  def dispose
    @sprite_datas.each {|sprite|
    sprite.dispose;sprite.bitmap.dispose }
    @viewport.dispose if @viewport
  end
  def auto_dispose(sprite,index)
    x = sprite.x.between?(-sprite.bs,WIN_W)
    y = sprite.y.between?(-sprite.bs,WIN_H)
    unless (x & y)
      sprite.dispose;sprite.bitmap.dispose
      @sprite_datas.delete_at(index)
    end
  end
  #————————————————————————————————————————
  #*类方法
  #————————————————————————————————————————
  class << self
    def make_speed(xp=XP_BASE,yp=YP_BASE,op=OP_BASE)
      @@speed_x,@@speed_y,@@speed_o = xp,yp,op
    end
    def make_otake(sw=OTAKE)
      @@otake = sw
    end
    def make_otake_value(value=OTAKE_VALUE)
      @@otake_value = value
    end
    def make_turning_effe(bool=TURN_EFFE)
      @@turning_effe = bool
    end
    def make_gradual_speed_effe(bool=GSPEED_EFFE)
      @@gradual_speed_effe = bool
    end
    def make_gradual_zoom_effe(bool=GZOOM_EFFE)
      @@gradual_zoom_effe = bool
    end
    def make_flee_effe(bool=FLEE_EFFE)
      @@flee_effe = bool
    end
    def make_stretch_effe(bool=STRETCH_EFFE)
      @@stretch_effe = bool
    end
  end
  #————————————————————————————————————————
  #*初始化类变量
  #————————————————————————————————————————
  Unravel_Bitmap.make_speed
  Unravel_Bitmap.make_otake
  Unravel_Bitmap.make_otake_value
  Unravel_Bitmap.make_turning_effe
  Unravel_Bitmap.make_gradual_speed_effe
  Unravel_Bitmap.make_gradual_zoom_effe
  Unravel_Bitmap.make_flee_effe
  Unravel_Bitmap.make_stretch_effe
end
#————————————————————————————————————————
#*主更新
#————————————————————————————————————————
module Graphics
  @unvb_ins_all = []
  class << self
  #————————————————————————————————————————
  #*执行
  #————————————————————————————————————————
    alias_method(:unvb_update,:update) unless method_defined?(:unvb_update)
    alias_method(:unvb_freeze,:freeze) unless method_defined?(:unvb_freeze)
    def update
      @unvb_ins_all.each {|unvb_ins|unvb_ins.update};unvb_update
    end
    def freeze
      all_ub_dispose;unvb_freeze
    end
    def all_ub_dispose
      @unvb_ins_all.each{|unvb_ins|unvb_ins.dispose}
      @unvb_ins_all.clear
    end
  #————————————————————————————————————————
  #*所有实例对象
  #————————————————————————————————————————
    attr_accessor :unvb_ins_all
  end
end
class Bitmap
  #————————————————————————————————————————
  #*RGSS1 clear_rect
  #————————————————————————————————————————
  unless method_defined?(:clear_rect)
    OC0 = Color.new(0,0,0,0)
    def clear_rect(x,y,width,height)
      fill_rect(x, y, width, height, OC0)
    end
  end
  #————————————————————————————————————————
  #*RC bitmap
  #————————————————————————————————————————
  #x：位图x y：位图y d：直径 e：椭圆长轴半径增长 f：长轴逆转 l：取率
  def rc_circle(x,y,d,e=0,f=true,l=1.0,bitmap=self,rc_clear=true)
    t = nil;d2 = d*2;d3 = d/2
    d2.times {|i| xo = (Math.sin(Math::PI/d2*i)*(d3+e)).round
    yo = (Math.cos(Math::PI/d2*i)*(d3)).round;t == yo ? next : t = yo;c = xo*2*l
    f ? (xb,yb,w,h = x+xo-c+d3,y+yo+d3,c,1) : (xb,yb,w,h = y+yo+d3,x+xo-c+d3,1,c)
    bitmap.blt(xb-x,yb-y,self,Rect.new(xb,yb,w,h))
    clear_rect(xb,yb,w,h) if rc_clear }
  end
  #x：位图x y：位图y w：取宽 h：取高
  def rc_square(x,y,w,h,bitmap=self,rc_clear=true)
    bitmap.blt(0,0,self,Rect.new(x,y,w,h))
    clear_rect(x,y,w,h) if rc_clear
  end
  #x：位图x y：位图y d：底 l：取率 slope：取斜率 1.0为直角
  def rc_triangle(x,y,d,l=1.0,slope=2.0,bitmap=self,rc_clear=true)
    w = 0;d.times {|i| xo = (d/slope-w/slope).truncate;xb = x+xo ; yb = y+i
    bitmap.blt(xo,i,self,Rect.new(xb,yb,w,1))
    clear_rect(xb,yb,w,1) if rc_clear;w += l }
  end
end
#————————————————————————————————————————
#*RMVA SceneManager in F12
#————————————————————————————————————————
module SceneManager
  class << self
    if method_defined?(:run)
      alias :unvb_run :run;def run;Graphics.unvb_ins_all = [];unvb_run;end
    end
  end
end
#————————————————————————————————————————
#*Sprite_Unbit
#————————————————————————————————————————
class Sprite_Unbit < Sprite
  attr_accessor :bs             #相对尺寸
  attr_accessor :xo             #位置x
  attr_accessor :yo             #位置y
  attr_accessor :oo             #不透明度
  attr_accessor :rx             #增减x
  attr_accessor :ry             #增减y
  attr_accessor :ro             #增减o
  attr_accessor :turn_max       #转向间隔
  attr_accessor :turning        #转向开关
  attr_accessor :angle_face     #朝向
  attr_accessor :gradual_zoom   #缩放开关
  attr_accessor :gradual_speed  #加速度开关
  attr_accessor :flee           #逃逸开关
  attr_accessor :stretch        #拉缩开关
  attr_accessor :update_pos_method #位置更新方法
  RADIAN_BASE = Math::PI / 180
  GSPEED_TO_STRETCH = Unravel_Bitmap::GSPEED_EFFE_STRETCH
  #————————————————————————————————————————
  #*主更新
  #————————————————————————————————————————
  def initialize(viewport = nil)
    super(viewport)
    @bs = @bs_base = 0
    @update_pos_method = method :update_pos_base
    #turning_set
    #gradual_zoom_set
  end
  def update(ax,ay,ao)
    super()
    update_gradual_zoom if @gradual_zoom
    update_gradual_speed if @gradual_speed
    update_turning if @turning
    update_stretch if @stretch
    @update_pos_method.call(ax,ay,ao)
  end
  #————————————————————————————————————————
  #*取得新的相对尺寸 zoom倍率
  #————————————————————————————————————————
  def bs=(new_bs)
    @bs = @bs_base = new_bs
  end
  def new_size(zoom)
    @bs = (@bs_base * zoom).truncate
  end
  #————————————————————————————————————————
  #*gradual speed effe
  #————————————————————————————————————————
  #参考值 加速倍率as=0.05 击中概率（hit%/100%/mx帧）参考值即为10%击中/秒
  #*该方法不能在self.initialize引用
  def gradual_speed_set(as=0.05, hit=10, mx=60)
    @gradual_speed = true
    @gradual_speed_hit = hit
    @gradual_speed_mx = mx
    @gradual_speed_as = as
    @gradual_speed_run = false
    @gradual_speed_arx = @rx * @gradual_speed_as
    @gradual_speed_ary = @ry * @gradual_speed_as
  end
  def update_gradual_speed
    return gradual_speed_run if @gradual_speed_run
    if Graphics.frame_count % @gradual_speed_mx == 0
      if @gradual_speed_hit > rand(100)
        @gradual_speed_run = true
        stretch_set(0,0,false,0.005,0.002) if GSPEED_TO_STRETCH
      end
    end
  end
  def gradual_speed_run
    @rx += @gradual_speed_arx
    @ry += @gradual_speed_ary
  end
  #————————————————————————————————————————
  #*gradual zoom effe
  #————————————————————————————————————————
  #参考值 幅度up=100 最小倍min=0.2 最大倍max=2.0 返回间隔/帧re=20  #up_use=0.002
  def gradual_zoom_set(up=100, min=0.5, max=1.5, re=30)
    @gradual_zoom_up = up
    @gradual_zoom_up_use = -(rand()/up)
    @gradual_zoom_max = [rand((max-1) * 100) / 100.0 + 1,max].min
    @gradual_zoom_min = [rand(),min].max
    @gradual_zoom_re = rand(re)
    @gradual_zoom = true
  end
  def update_gradual_zoom
    range = self.zoom_x
    new_size(range)
    unless range.between?(@gradual_zoom_min,@gradual_zoom_max)
      if rand(@gradual_zoom_re).eql?(0)
        @gradual_zoom_up = -@gradual_zoom_up
        @gradual_zoom_up_use = -(rand()/@gradual_zoom_up)
        self.zoom_x += @gradual_zoom_up_use
        self.zoom_y += @gradual_zoom_up_use
      end
    else
      self.zoom_x += @gradual_zoom_up_use
      self.zoom_y += @gradual_zoom_up_use
    end
  end
  #————————————————————————————————————————
  #*flee effe
  #————————————————————————————————————————
  #参考值 执行等待/帧 mx=20 逃逸倍速 fs=1.0（视觉好）0.5（衔接好） 转动频率 fr=20
  def flee_set(mx=20, fs=1.0, fr=20)
    @flee = true
    @flee_speed = fs
    @flee_timer = 0
    @flee_max = mx
    @flee_dir = fr
    @direction = 0
    @point = Math.atan2(@ry*Math::PI, @rx*Math::PI) / RADIAN_BASE
    @update_pos_method = method :update_pos_flee
  end
  def update_pos_flee(ax,ay,ao)
    if @flee_timer > @flee_max
      @direction += -rand(@flee_dir)+rand(@flee_dir)
      new_radian = (@direction + @point) * RADIAN_BASE
      fx = Math.cos(new_radian)
      fy = Math.sin(new_radian)
      self.x = @xo += (fx * @flee_speed + @rx / 2) * ax
      self.y = @yo += (fy * @flee_speed + @ry / 2) * ay
      self.opacity = @oo -= @ro * ao
    else
      @flee_timer += 1
      update_pos_base(ax,ay,ao)
    end
  end
  def flee=(bool)
    @flee = bool
    unless bool
      @update_pos_method = method :update_pos_base
    end
  end
  #————————————————————————————————————————
  #*base pos
  #————————————————————————————————————————
  #参考值 传递整体计算倍率ax,ay,ao=1.0
  def update_pos_base(ax,ay,ao)
    self.x = @xo += @rx * ax
    self.y = @yo += @ry * ay
    self.opacity = @oo -= @ro * ao
  end
  #————————————————————————————————————————
  #*stretch effe
  #————————————————————————————————————————
  #参考值 初始拉伸倍率izx=2.0 izy=0.5 拉到最小极限会强制关闭更新状态
  #sig=初始角开关 rzx=0.02缩值x rzy=0.001缩值y
  def stretch_set(izx=2.0, izy=0.5, sig=true, rzx=0.02,rzy=0.001)
    return if @stretch
    @stretch = true
    ig = Math.atan2(@ry, @rx) / RADIAN_BASE
    ag = (Math.tan(ig) * 100).ceil
    ag = ag.eql?(0) ? -1 : ag
    @add_angle = ag / ag.abs / 1.0
    self.zoom_x += izx
    self.zoom_y -= izy
    self.angle = ig if sig
    @sze = 1.0 / @bs_base
    @rzx,@rzy = rzx,rzy
  end
  def update_stretch
    self.zoom_x -= @rzx#0.03
    self.zoom_y -= @rzy#0.001
    self.angle += @add_angle
    range = self.zoom_x
    new_size(range)
    if range < @sze
      @stretch = false
      self.zoom_x = @sze
      self.zoom_y = @sze
    end
  end
  #————————————————————————————————————————
  #*trun effe
  #————————————————————————————————————————
  #参考值 转向间隔/帧 mx=300
  def turning_set(mx=300)
    @turning = true
    @turn_timer = 0
    @trun_max = mx
    @turn_maxtime = rand @trun_max
  end
  def update_turning
    @turn_timer += 1
    if @turn_timer >= @turn_maxtime
      @turn_timer = 0
      @turn_maxtime = rand @trun_max
      rand(2).eql?(0) ?  trun_x : trun_y
    end
  end
  def trun_x
    @rx=-@rx
  end
  def trun_y
    @ry=-@ry
  end
end
