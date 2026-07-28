#==============================================================================
# ■ 弹出式文本 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【组件-通用方法汇总 by老鹰】与
#  【组件-位图绘制转义符文本 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-PopText"] = "1.0.0"
#==============================================================================
# - 2026.7.27.22 
#==============================================================================

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# ● 什么是 弹出式文本
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#
#  1. 在各类游戏中都有受击时显示伤害数字的设定，这就是本插件所说的弹出式文本。
#
#  2. 弹出式文本在创建后，将自动移入、自动移出，且不会跟随角色移动。
#

module POP_TEXT
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# ● 使用方式A：利用全局脚本
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#
#  - 该弹出式文本能够在任意时刻调用，此处对可使用的全局脚本进行说明。
#
#------------------------------------------------
# 【全局脚本a：生成一个弹出式文本】
#
#  - 调用该全局脚本生成一个弹出式文本，并自动移入移出：
#
#      POP_TEXT.new(params)
#
#    其中 params 为参数Hash，可以设置以下参数：
#
#     :text => "字符串",   → 绘制的转义符文本。
#                            与【组件-位图绘制转义符文本 by老鹰】一致。
#
#     :size => 数字,       → 字体大小。
#
#     :type => :符号,      → 移入移出方式（默认:float）。
#
#         可传入符号一览：
#              :float      → 上浮、淡出
#              :float2     → 上浮同时放大、淡出
#              :sink       → 下沉、淡出
#              :zoom1      → 放大、淡出同时缩小
#              :zoom2      → 上浮、淡出同时缩小
#              :zoom3      → 放大、淡出
#              :bounce     → 弹跳落地、淡出
#              :bounce2    → 弹跳落地（缓动函数版本）、淡出
#
#    （以下几组参数任选其一，如果都有，则仅排在前面的生效）
#
#     (1)（仅地图中生效）将弹出式文本显示到地图事件上
#
#       :eid => 数字,        → 所绑定的事件ID。
#                              正整数为地图上的对应ID号事件；
#                              负整数为玩家队伍中对应ID号的角色。
#       :map => 1 或者 0,    → 是否绑定到地图上（默认 1）。
#                              1 为绑定到地图上，0 为绑定到屏幕上。
#
#     (2)（仅战斗中生效）将弹出式文本显示到战斗角色上
#
#       :bid => 数字,        → 所绑定的战斗者的id。
#                              0 或 正整数为敌群中对应序号的敌人；
#                              负整数为玩家队伍中对应ID号的角色。
#
#       :battler => 战斗者Game_Battler（方便在脚本中设置，可不设置:bid）
#
#     (3) 直接设置弹出式文本显示在屏幕上的位置
#
#       :x => 数字,          → 显示位置的屏幕上x。
#       :y => 数字,          → 显示位置的屏幕上y。
#       :z => 数字,          → 显示位置的z。
#       :dy => 数字,         → 额外向上偏移的距离。
#
#  - 示例：
#
#     POP_TEXT.new({:text => "小心！", :eid => -1 })
#
#       → 在角色上显示弹出的 “小心！”。
#
#------------------------------------------------
# 【全局脚本b：生成一个弹出式文本】
#
#  - 调用该全局脚本生成一个弹出式文本，并自动移入移出：
#
#      POP_TEXT.new(text)
#
#    其中 text 为参数的标签对，可以设置的参数同上。
#
#    但注意，文本中参数名不写英语冒号:，且文本无法使用转义符。
#
#  - 示例：
#
#     POP_TEXT.new("text=小心！ eid=-1 type=float2")
#
#       → 在角色上显示弹出的 “小心！”。
#
#------------------------------------------------
# 【事件注释：生成一个弹出式文本】
#
# - 在事件指令-注释中，编写该样式文本（需作为行首）
#
#       POP|tag字符串|文本
#
#    其中 POP 为固定的识别文本，不可缺少。
#    其中 tag字符串 为【全局脚本a：生成一个弹出式文本】中的参数的标签对，
#             用空格分隔不同参数。
#             特别的，可以用 eid=0 显示到当前事件。
#
#    其中 文本 为需要显示的文本，可以用 \n 来进行换行
#
#  - 示例：
#
#    POP|eid=-1 type=zoom2|\i[192]恢复剂 + 1
#       → 在角色上显示弹出的 “\i[192]恢复剂 + 1”。
#
# - 正则匹配：事件指令-注释中的文本格式
COMMENT_POP_TEXT = /^POP *?\| *?(.*?) *?\| *?(.*)/mi

#==============================================================================

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#                      - 设置结束，以下内容请不要修改！ -
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

  #--------------------------------------------------------------------------
  # ● 生成一个POP
  #--------------------------------------------------------------------------
  def self.new(params = {})
    if params.is_a?(String)
      params = EAGLE_COMMON.parse_tags(params)
      a = [:bid, :size, :x, :y, :z, :dy, :type, :map]
      a.each { |sym| params[sym] = params[sym] if params[sym] }
      params[:type] = params[:type].to_sym if params[:type]
    end
    params[:bid] = get_battler_id(params[:battler]) if params[:battler]
    if @sprites_pop_finish.empty?
      s = Sprite_Pop.new
    else
      s = @sprites_pop_finish.pop
    end
    s.reset(params)
    @sprites_pop_new.push(s)
  end
  
  #--------------------------------------------------------------------------
  # ● 由战斗者获取其战斗中唯一ID
  #--------------------------------------------------------------------------  
  def self.get_battler_id(battler)
    return nil if battler == nil
    if battler.actor?  # 我方战斗者ID = 数据库ID的相反数
      return -battler.id
    elsif battler.enemy? # 敌方战斗者ID = 数据库敌群索引INDEX 
      return battler.index
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 每帧更新
  #--------------------------------------------------------------------------
  @sprites_pop = []; @sprites_pop_new = []; @sprites_pop_finish = []
  def self.update
    @sprites_pop = @sprites_pop.concat(@sprites_pop_new)
    @sprites_pop_new.clear
    @sprites_pop.each do |s|
      s.update
      next @sprites_pop_finish.push(s) if s.finish
    end
    @sprites_pop.delete_if { |s| s.finish }
  end
  
  #--------------------------------------------------------------------------
  # ● POP精灵
  #--------------------------------------------------------------------------
  class Sprite_Pop < Sprite
    attr_reader :finish
    #--------------------------------------------------------------------------
    # ● 重置
    #--------------------------------------------------------------------------
    def reset(params)
      @params = params
      @x0 = @y0 = @x1 = @y1 = @dx = @dy = 0
      @z = 100
      @on_map = false
      self.visible = false
      self.zoom_x = self.zoom_y = 1.0
      @params[:type] ||= :float
      redraw
      reset_position
      @fiber = Fiber.new { run }
      @finish = false
    end

    # 重绘
    def redraw
      self.bitmap.dispose if self.bitmap
      t = @params[:text]
      ps = { :font_size => @params[:size], :x0 => 2, :y0 => 0, :lhd => 2 }
      d = Process_DrawTextEX.new(t, ps)
      
      self.bitmap = Bitmap.new(d.width, d.height)
      self.bitmap.font.shadow = false
      self.bitmap.font.outline = true
      d.bind_bitmap(self.bitmap) 
      d.run(true)
    end

    # 重设初始位置
    def reset_position
      if @params[:eid]
        eid = @params[:eid].to_i
        self.ox = self.width / 2
        self.oy = self.height / 2
        # 初始位置为行走图底部中心
        e = @params[:cur_event_id] ? $game_map.events[@params[:cur_event_id]] : nil
        c = EAGLE_COMMON.get_chara(e, eid)
        @x0 = c.screen_x
        @y0 = c.screen_y
        s = EAGLE_COMMON.get_chara_sprite(eid)
        if s # 上移行走图的一半高度
          @y0 -= s.ch / 2
        else
          @y0 -= 16
        end
        # 如果绑定到地图上，就存储下当前地图的xy
        @params[:map] ||= '1'
        @on_map = @params[:map] == '1'
        if @on_map
          @x0_map = $game_map.display_x
          @y0_map = $game_map.display_y
        end
        @params[:dy] ||= 20
        return
      end

      if @params[:bid]
        bid = @params[:bid].to_i
        # 底部中点为显示原点
        self.ox = self.width / 2
        self.oy = self.height

        # 先定位到战斗者图像的中心处
        s = EAGLE_COMMON.get_battler_sprite(bid)
        @x0 = s.x
        @y0 = s.y - s.height / 2
        # 在小范围内随机
        @x1 = rand(s.width/2) - s.width/4
        @y1 = rand(s.height/2) - s.height/4
        @z = s.z
        # 设置向上移动的距离
        @params[:dy] ||= s.height / 2
        return
      end

      @x0 = @params[:x] || 0
      @y0 = @params[:y] || 0
      @x1 = @y1 = 0
      @z  = @params[:z] || 100
    end

    #--------------------------------------------------------------------------
    # ● 更新
    #--------------------------------------------------------------------------
    def update
      super
      return if @finish
      @fiber.resume if @fiber
      update_position
    end

    # 更新位置
    def update_position
      _x = _y = 0
      if @on_map 
        _x = (@x0_map - $game_map.display_x) * 32
        _y = (@y0_map - $game_map.display_y) * 32
      end
      self.x = @x0 + _x + @x1 + @dx
      self.y = @y0 + _y + @y1 + @dy
      self.z = @z
    end

    #--------------------------------------------------------------------------
    # ● 开始
    #--------------------------------------------------------------------------
    def run
      self.visible = true
      self.opacity = 255
      begin
        self.method("run_#{@params[:type]}").call
      rescue
        p "使用战斗POP时发生错误！"
        p "- 报错信息：#{$!}"
        p "- 请检查 :type 参数是否正确！已经用默认弹跳默认进行替换"
        run_float
      end
      self.opacity = 0
      @fiber = nil
      @finish = true
    end

    # 开始 - 向上浮现，再淡出
    def run_float
      dy0 = 0
      # -@y1 确保伤害数字最后到同一水平面消失
      dy1 = -@y1 - @params[:dy]
      t = 40
      t.times do |i|
        per = EasingFuction.call("easeOutCubic", i * 1.0 / t)
        @dy = dy0 + (dy1 - dy0) * per
        Fiber.yield
      end
      20.times { self.opacity -= 13; Fiber.yield }
    end

    # 开始 - 向上放大淡出
    def run_float2
      dy0 = 0
      dy1 = - @params[:dy]
      t = 60
      t.times do |i|
        per = EasingFuction.call("easeOutCubic", i * 1.0 / t)
        @dy = dy0 + (dy1 - dy0) * per
        self.zoom_x = self.zoom_y = 1.0 + (2.0 - 1.0) * per
        self.opacity = 255 - 255 * per
        Fiber.yield
      end
    end

    # 开始 - 下沉，再淡出
    def run_sink
      dx0 = 0
      dx1 = - @x1
      dy0 = - @params[:dy]
      dy1 = - @y1 + self.height / 2
      t = 40
      t.times do |i|
        per = EasingFuction.call("easeOutCubic", i * 1.0 / t)
        @dx = dx0 + (dx1 - dx0) * per
        @dy = dy0 + (dy1 - dy0) * per
        Fiber.yield
      end
      20.times { self.opacity -= 13; Fiber.yield }
    end

    # 开始 - 放大，再缩小淡出
    def run_zoom1
      t = 40
      t.times do |i|
        per = EasingFuction.call("easeOutBack", i * 1.0 / t)
        self.zoom_x = self.zoom_y = 2.0 + (1.0 - 2.0) * per
        Fiber.yield
      end
      10.times { Fiber.yield }
      t.times do |i| 
        per = EasingFuction.call("easeOutBack", i * 1.0 / t)
        self.zoom_x = self.zoom_y = 1.0 + (0.0 - 1.0) * per
        self.opacity -= 7
        Fiber.yield
      end
    end

    # 开始 - 上浮，再缩小淡出
    def run_zoom2
      dy0 = 0
      dy1 = - @params[:dy]
      t = 40
      t.times do |i|
        per = EasingFuction.call("easeOutBack", i * 1.0 / t)
        self.zoom_x = self.zoom_y = 0 + (1.0 - 0) * per
        #@dx += 2
        @dy = dy0 + (dy1 - dy0) * per
        Fiber.yield
      end
      10.times { Fiber.yield }
      t.times do |i| 
        per = EasingFuction.call("easeInBack", i * 1.0 / t)
        self.zoom_x = self.zoom_y = 1.0 - 1.0 * per
        @dy = dy1 + (dy0 - dy1) * per
        self.opacity -= 7
        Fiber.yield
      end
    end

    # 开始 - 原地放大淡出
    def run_zoom3
      t = 40
      t.times do |i|
        per = EasingFuction.call("easeOutBack", i * 1.0 / t)
        self.zoom_x = self.zoom_y = 1.0 + (2.0 - 1.0) * per
        self.opacity -= 7
        Fiber.yield
      end
    end

    # 开始 - 弹跳，再淡出
    def run_bounce
      vx = rand * 2 - 1
      vy = -2 - rand(2)
      @dy = 0
      f = false
      # 反弹线的y值
      zero_line = @params[:dy] * 2 -self.height
      90.times do |i|
        @dx += vx
        @dy += vy
        vy += 1 if i % 4 == 0
        Fiber.yield
        if (@dy >= zero_line) && f == false
          vy = (-vy * 0.5).to_i
          f = true
        end
        if (vy == 0)
          f = false
          vx = 0 if @dy >= zero_line
        end
      end
      13.times { self.opacity -= 20; Fiber.yield }
    end

    # 开始 - 弹跳（缓动函数），再淡出
    def run_bounce2
      vx = (rand * 2 - 1) * 3
      dy0 = 0
      # -@y1 确保伤害数字都掉落在同一水平面
      dy1 = - @y1 + @params[:dy]
      d_dy = dy1 - dy0
      t = 40
      t.times do |i|
        @dx += vx
        v = EasingFuction.call("easeOutBounce", i * 1.0 / t)
        @dy = dy0 + d_dy * v
        Fiber.yield
      end
      50.times { self.opacity -= 5; Fiber.yield }
    end

    #--------------------------------------------------------------------------
    # ● 释放
    #--------------------------------------------------------------------------
    def dispose
      self.bitmap.dispose
      super
    end
  end # end of class Sprite_Pop
end 

#===============================================================================
# ○ Sprite_Character
#===============================================================================
class Sprite_Character < Sprite_Base
  attr_reader :cw, :ch
end

#===============================================================================
# ○ Scene_Base
#===============================================================================
class Scene_Base
  # 更新画面（基础）
  alias eagle_popup_text_update_basic update_basic
  def update_basic
    eagle_popup_text_update_basic
    POP_TEXT.update
  end
end

#===============================================================================
# ○ Game_Interpreter
#===============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 添加注释
  #--------------------------------------------------------------------------
  alias eagle_pop_text_command_108 command_108
  def command_108
    eagle_pop_text_command_108
    t = @comments.inject { |t, v| t = t + "\n" + v }
    t.scan(POP_TEXT::COMMENT_POP_TEXT).each do |v|
      ps = v[0].lstrip.rstrip  # tags string  # 去除前后空格
      ps = EAGLE_COMMON.parse_tags(ps)
      ps[:text] = v[1]  # text
      ps[:cur_event_id] = @event_id
      POP_TEXT.new(ps)
    end
  end
end
