#==============================================================================
# ■ 显示变量 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【组件-通用方法汇总 by老鹰】与
#   【组件-位图绘制转义符文本 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-ShowVariable"] = "1.1.0"
#==============================================================================
# - 2024.2.12.10 修改注释
#==============================================================================
# - 本插件提供了在屏幕上显示变量的便捷方法
#-----------------------------------------------------------------------------
# 【原理说明】
# - 在默认 RGSS3 中，事件指令-变量操作 是对 $game_variables[id] 对象进行处理，
#   而该对象可以存储任意内容（当然需要有 Marshal 的序列化处理，这样才能存档），
#   但除了转义符 \v[id] ，没有其它地方可以方便显示。
#
# - 本插件为每一个变量，新增了一个可以显示在屏幕上的UI：
#   在地图/战斗时，指定的文本将显示于屏幕指定位置，当变量值变更时将自动重绘。
#
# - 注意：在同一时间，一个变量只能绑定一个UI进行自动重绘
#         但你依然可以利用 \v[id] 来获取指定变量的值，
#         不过这些变量的变化不会让UI自动重绘。
#
# - 提示：事件指令-变量操作 中的脚本，填入以下内容，可以给变量赋值字符串：
#
#      "你想要的文本" 
#
#-----------------------------------------------------------------------------
# 【新建 - 事件指令：注释】
#
# - 创建一个新的变量显示：
#
#      VAR id|tag字符串|显示文本
#
#   其中 VAR 为固定的识别文本，不可缺少
#   其中 id 替换为绑定的变量的序号
#   其中 tag字符串 可以为以下类型文本的任意组合，用空格分隔（可不写）：
#
#   （位置相关）
#      ox=小数 oy=小数  → 显示原点（0~1之间的小数，如0代表左端点，0.5代表中点）
#      x=数字  y=数字   → 显示原点在屏幕上的位置（默认0）
#      z=数字           → Z值（在Spriteset中的viewport2内）
#   （文本相关）
#      w=数字          → 文字的最大宽度
#      size=数字       → 文字的初始大小
#      color={Color.new(0,0,0,0)}  → 文字的初始颜色
#      x0=数字 y0=数字 → 文字绘制起点的偏移值
#      padding=数字    → 文字绘制区域的周围留空距离
#   （背景相关）
#      bg=数字或字符   → 背景类型（0为窗口皮肤，1为纯色背景，2为透明，其它为图片名称）
#                      （图片放置于Graphics/System下）
#      bg0=文本        → bg为0时，所用窗口皮肤的文件名
#      bg1=Color.new(0,0,0,0)  → bg为1时，所用颜色
#      bgpic=数字      → bg为字符时，背景图片与文本的对齐位置（九宫格小键盘）
#                      （比如 5 代表图片中心与文本区域中点对齐；7 代表左上角对齐）
#   （显示相关）
#      t=数字     → 设置在该帧后自动渐隐，下一次变量更新时再次显示
#                  （默认 nil，一直显示）
#
#   其中 显示文本 为具体绘制的文本
#     其中 <vid> 将被替换为绑定变量的ID，<v> 将被替换为绑定变量的值
#
# - 示例：
#
#     VAR 1|| → 以默认参数在地图上显示 "1号变量：0 "
#     VAR 2 | y=450 | 当前任务目标：<v>
#      → 在屏幕的x=0，y=450处显示 "当前任务目标：测试文本" 字样
#
#-----------------------------------------------------------------------------
# 【新建 - 全局脚本】
#
# - 创建一个新的变量显示：
#
#      VAR.add(v_id[, params])
#
#   其中 v_id 为所绑定的默认变量的 id 号（从1开始，与数据库中一致）
#   其中 params 为存储额外参数的hash，可省略
#
# - 参数列表：
#   （位置相关）
#     :ox/:oy  → 精灵的显示原点（0~1之间的比例小数，0.5代表中点）
#     :x/:y/:z → 精灵在屏幕中的显示位置
#   （文本相关）
#     :text    → 所绘制文本，其中 <v> 将会被替换成所绑定变量的值
#     :w       → 文本的最大宽度
#     :size    → 所绘制文本的文字大小
#     :color   → 所绘制文本的文字颜色
#     :x0/:y0  → 所绘制文本在位图Bitmap中的位置（以位图左上角为原点）
#     :padding → 文字绘制区域的周围留空距离
#   （背景相关）
#     :bg    → 背景类型（0为窗口皮肤，1为纯色背景，2为透明，其它为图片名称）
#                      （图片放置于Graphics/System下）
#     :bg0   → bg为0时，所用窗口皮肤的文件名
#     :bg1   → bg为1时，所用颜色 Color.new(0,0,0,0)
#     :bgpic → bg为字符时，背景图片与文本的对齐位置
#   （显示相关）
#     :t       → 当一段时间（t帧）未有变化时，自动隐藏
#
# - 文本：
#     利用和 Window_Base#draw_text_ex 相似的方法进行绘制
#     （由于默认字符串存储方式，请用 \\ 代替 \ 来写转义符）
#     可以使用 文本替换类 的转义符，如 \\v[id]、\\n[id] 等
#     可以用 \\i[id] 绘制图标，用 \\c[i] 进行颜色变更
#     可以用 \n 换行
#
# - 示例：
#   （1号变量值为 0 ，2号变量值为 "测试文本"）
#     VAR.add(1) → 以默认参数在地图上显示 "1号变量：0 "
#     VAR.add(2, { :y => 480-30, :text => "当前任务目标：<v>" })
#      → 在屏幕的x=0，y=450处显示 "当前任务目标：测试文本" 字样
#
#-----------------------------------------------------------------------------
# 【删除 - 事件指令：注释】
#
# - 删除指定变量显示：
#
#      VAR id|FIN
#
#   其中 VAR 和 FIN 为固定的识别文本，不可缺少
#   其中 id 替换为绑定的变量的序号
#
# - 示例：
#
#     VAR 1|FIN → 删去1号变量的显示
#
#-----------------------------------------------------------------------------
# 【删除 - 全局脚本】
#
# - 利用全局脚本删除指定变量显示：
#
#      VAR.delete(v_id)
#
# - 示例：
#
#     VAR.delete(1) → 删去1号变量的显示
#
#-----------------------------------------------------------------------------
# 【高级 - 全局脚本】
#
# - 显示指定变量显示：
#
#      VAR.show(v_id)
#
# - 隐藏指定变量显示：
#
#      VAR.hide(v_id)
#
# - 若未传入 v_id 或传入 nil，则将显示/隐藏全部已有的变量显示
#
#==============================================================================

module VAR
  #--------------------------------------------------------------------------
  # ●【常量】默认设定
  #--------------------------------------------------------------------------
  PARAMS = {
    #--------------------------------------------------------------------
    # - 显示文本
    #  （其中  <vid> 将替换为绑定变量的ID， <v> 将替换为绑定变量的值）
    "TEXT" => "<vid>号变量：<v>",

    #--------------------------------------------------------------------
    # - 显示原点
    #  （设置为 0~1 之间的比例小数，比如0.5代表中点）
    "OX" => 0,
    "OY" => 0,
    #--------------------------------------------------------------------
    # - 摆放位置
    "X" => 0,
    "Y" => 0,
    "Z" => 100,

    #--------------------------------------------------------------------
    # - 初始文字大小
    "FONT_SIZE" => Font.default_size,
    #--------------------------------------------------------------------
    # - 初始文字颜色
    "FONT_COLOR" => Color.new(255, 255, 255, 255),
    #--------------------------------------------------------------------
    # - 文字绘制位置（在位图内）
    "X0" => 0,
    "Y0" => 0,

    #-----------------------------------------------------------------
    # - 所用背景
    # （0 窗口皮肤，1 纯色背景，2 透明背景，字符串图片名称）
    "TEXT_BG" => 1,
    #-----------------------------------------------------------------
    # - BG为0时，设置所用的窗口皮肤
    "TEXT_BG0" => "Window",
    #-----------------------------------------------------------------
    # - BG为1时，设置所用的颜色
    "TEXT_BG1" => Color.new(0,0,0, 150),
    #-----------------------------------------------------------------
    # - BG为字符串时，设置图片哪个位置与文字绑定
    # （比如 2 代表图片底部中点绑定到文字区域的底部中点，
    #    5 代表图片中心绑定到文字区域的中心）
    "TEXT_BG_PIC" => 2,
    #-----------------------------------------------------------------
    # - 文字四周的留空值
    # （当使用图片背景时无效）
    "TEXT_PADDING" => 8,
  }

  #--------------------------------------------------------------------------
  # ○【常量】事件指令-注释 中新增变量显示的文本
  #--------------------------------------------------------------------------
  COMMENT_VARSHOW = /^VAR *?(\d+) *?\|(.*?)\| *?(.*)/mi
  #--------------------------------------------------------------------------
  # ○【常量】事件指令-注释 中结束变量显示的文本
  #--------------------------------------------------------------------------
  COMMENT_VARSHOW_FIN = /^VAR *?(\d+) *?\|FIN/mi
end
#===============================================================================
# ○ 不推荐修改下列内容
#===============================================================================
module VAR
  #--------------------------------------------------------------------------
  # ● 新增
  # params = {
  #  :t => nil,  # 当设置为正整数时，将在 :t 帧后自动渐隐，下一次变量更新时再次显示
  #  :ox => 0, :oy => 0,   # 设置显示原点（0~1之间的比例小数，0.5代表中点）
  #  :x => 0, :y => 0, :z => 100, # 设置显示位置
  #  :w => nil, # 文字的最大宽度
  #  :size => nil, # 文字的大小
  #  :color => nil, # 文字的初始颜色
  #  :text => "",  # 显示的文本 其中<v>替换为绑定变量的值
  #  :x0 => 0,  :y0 => 0,  # 文字绘制的偏移值
  #  :padding => 4,  # 文字绘制区域的周围留空距离
  #  :bg => 0, # 背景类型（0为窗口皮肤，1为纯色背景，2为透明，其它为图片名称）
  #  :bg0 => "",  # 窗口皮肤的文件名
  #  :bg1 => Color.new(),  # 纯色
  #  :bgpic => 5, # 背景图片与文本的对齐位置
  # }
  #--------------------------------------------------------------------------
  def self.add(v_id, params = {})
    params[:refresh] = true # 需要刷新的标志
    params[:visible] = true # 是否显示
    vars = [ :t, :x, :y, :z, :w, :size, :x0, :y0, :padding ]
    vars.each { |v| params[v] = params[v].to_i if params[v] }
    vars = [ :ox, :oy ]
    vars.each { |v| params[v] = params[v].to_f if params[v] }
    vars = [ :color, :bg1 ]
    vars.each { |v| params[v].is_a?(Color) ? params[v] : eval(params[v]) if params[v] }
    $game_system.var_show[v_id] = params
  end
  #--------------------------------------------------------------------------
  # ● 设置
  #--------------------------------------------------------------------------
  def self.set(v_id, params = {})
    return if $game_system.var_show[v_id].nil?
    $game_system.var_show[v_id].merge!(params)
    $game_system.var_show[v_id][:refresh] = true # 需要刷新的标志
  end
  #--------------------------------------------------------------------------
  # ● 删除
  #--------------------------------------------------------------------------
  def self.delete(v_id)
    $game_system.var_show.delete(v_id)
  end
  #--------------------------------------------------------------------------
  # ● 显示
  #--------------------------------------------------------------------------
  def self.show(v_id = nil)
    if v_id
      return if $game_system.var_show[v_id].nil?
      $game_system.var_show[v_id][:visible] = true
    else
      $game_system.var_show.each { |vid, ps|
        $game_system.var_show[vid][:visible] = true
      }
    end
  end
  #--------------------------------------------------------------------------
  # ● 隐藏
  #--------------------------------------------------------------------------
  def self.hide(v_id = nil)
    if v_id
      return if $game_system.var_show[v_id].nil?
      $game_system.var_show[v_id][:visible] = false
    else
      $game_system.var_show.each { |vid, ps|
        $game_system.var_show[vid][:visible] = false
      }
    end
  end
end
#==============================================================================
# ○ Game_System
#==============================================================================
class Game_System
  #--------------------------------------------------------------------------
  # ● 读取
  #--------------------------------------------------------------------------
  def var_show
    @var_show ||= {}
    @var_show
  end
end
#==============================================================================
# ○ Game_Variables
#==============================================================================
class Game_Variables
  #--------------------------------------------------------------------------
  # ● 设置变量（覆盖）
  #--------------------------------------------------------------------------
  def []=(variable_id, value)
    v_old = @data[variable_id]
    @data[variable_id] = value
    on_change
    on_change_different(variable_id) if v_old != value
  end
  #--------------------------------------------------------------------------
  # ● 变量改变时的操作
  #--------------------------------------------------------------------------
  def on_change_different(variable_id)
    if $game_system.var_show[variable_id]
      $game_system.var_show[variable_id][:refresh] = true
    end
  end
end
#==============================================================================
# ○ 显示用的精灵
#==============================================================================
class Sprite_VarShow < Sprite
  include VAR
  attr_accessor :flag_update
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(viewport, v_id)
    super(viewport)
    @v_id = v_id
    @flag_update = false # 每帧重置为false，若更新结束依然为false，则需要删除
    refresh
  end
  #--------------------------------------------------------------------------
  # ● 参数
  #--------------------------------------------------------------------------
  def params
    $game_system.var_show[@v_id]
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    self.bitmap.dispose
    super
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
    update_visible
    update_fade if params[:t]
    refresh if params[:refresh]
  end
  #--------------------------------------------------------------------------
  # ● 更新显隐
  #--------------------------------------------------------------------------
  def update_visible
    if params[:visible] == true && self.visible == false
      fade_init
    elsif params[:visible] == false && self.visible == true
    end
    self.visible = params[:visible]
  end
  #--------------------------------------------------------------------------
  # ● 更新渐隐
  #--------------------------------------------------------------------------
  def update_fade
    params[:tc] ||= params[:t]
    if params[:tc] == 0
      self.opacity -= 15 if self.opacity > 0
    else
      params[:tc] -= 1
    end
  end
  #--------------------------------------------------------------------------
  # ● 初始化渐隐
  #--------------------------------------------------------------------------
  def fade_init
    self.opacity = 255
    params[:tc] = nil
  end
  #--------------------------------------------------------------------------
  # ● 重绘
  #--------------------------------------------------------------------------
  def refresh
    $game_system.var_show[@v_id][:refresh] = false
    self.x = params[:x] || PARAMS["X"]
    self.y = params[:y] || PARAMS["Y"]
    self.z = params[:z] || PARAMS["Z"]
    redraw
    _ox = params[:ox] || PARAMS["OX"]
    _oy = params[:oy] || PARAMS["OY"]
    self.ox = self.width * _ox
    self.oy = self.height * _oy
    fade_init
  end
  #--------------------------------------------------------------------------
  # ● 绘制内容
  #--------------------------------------------------------------------------
  def redraw
    ps = { :x0 => 0, :y0 => 0, :lhd => 2, :ali => 0 }
    ps[:font_size] =  params[:size] || PARAMS["FONT_SIZE"]
    ps[:font_color] = params[:color] || PARAMS["FONT_COLOR"]
    ps[:w] = params[:w] if params[:w]

    if params[:text]
      t = params[:text].dup
    else
      t = PARAMS["TEXT"].dup
    end
    t.gsub!(/<vid>/) { @v_id }
    t.gsub!(/<v>/) { $game_variables[@v_id] }

    self.bitmap.dispose if self.bitmap
    return if t == ""

    d = Process_DrawTextEX.new(t, ps)
    d.run(false)
    ps[:text_w] = d.width
    ps[:text_h] = d.height
    redraw_contents(ps)
    # 绘制文字
    d.bind_bitmap(self.bitmap)
    d.run(true)
  end
  #--------------------------------------------------------------------------
  # ● 绘制内容背景
  #--------------------------------------------------------------------------
  def redraw_contents(ps)
    ps[:x0] = params[:x0] || PARAMS["X0"]
    ps[:y0] = params[:y0] || PARAMS["Y0"]
    w = ps[:text_w] + ps[:x0]
    h = ps[:text_h] + ps[:y0]
    # 获取背景类型
    bg_type = PARAMS["TEXT_BG"]
    if params[:bg]
      bg_type = params[:bg]
      bg_type = bg_type.to_i if bg_type.size == 1 && bg_type.to_i >= 0
    end
    # 处理四周的留白
    padding = params[:padding] || PARAMS["TEXT_PADDING"]
    padding = 0 if bg_type.is_a?(String)  # 图片背景
    ps[:x0] += padding  # 文字绘制的左上角增加padding
    ps[:y0] += padding
    w += padding * 2 # 宽高增加
    h += padding * 2
    # 绘制背景
    if bg_type == 0  # 绘制windowskin
      self.bitmap = Bitmap.new(w, h)
      skin = params[:bg0] || PARAMS["TEXT_BG0"]
      begin
        r = Rect.new(0, 0, self.width, self.height)
        EAGLE.draw_windowskin(skin, self.bitmap, r)
      rescue
      end
    elsif bg_type == 1  # 绘制纯色背景
      self.bitmap = Bitmap.new(w, h)
      c = params[:bg1] || PARAMS["TEXT_BG1"]
      self.bitmap.fill_rect(self.bitmap.rect, c)
    elsif bg_type == 2  # 透明背景
      self.bitmap = Bitmap.new(w, h)
    elsif bg_type.is_a?(String)  # 图片背景
      _b = Cache.system(bg_type) rescue nil
      if _b
        self.bitmap = Bitmap.new([w, _b.width].max, [h, _b.height].max)
        o = params[:bgpic] || PARAMS["TEXT_BG_PIC"]
        EAGLE_COMMON.bitmap_copy_do(self.bitmap, _b, o.to_i)
      else
        self.bitmap = Bitmap.new(w, h)
      end
    end
  end
end
#==============================================================================
# ○ 精灵组
#==============================================================================
class Spriteset_VarShow
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(viewport)
    @viewport = viewport
    @var_show = {} # v_id => Sprite
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    @var_show.each { |v_id, s| s.flag_update = false }
    $game_system.var_show.each do |v_id, ps|
      @var_show[v_id] ||= Sprite_VarShow.new(@viewport, v_id)
      @var_show[v_id].update
      @var_show[v_id].flag_update = true
    end
    return if @var_show.empty?
    @var_show.each { |v_id, s| s.dispose if s.flag_update == false }
    @var_show.delete_if { |v_id, s| s.disposed? }
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    @var_show.each { |v_id, s| s.dispose }
  end
end

#==============================================================================
# ○ Spriteset_Map
#==============================================================================
class Spriteset_Map
  attr_reader  :var_show
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  alias eagle_varshow_init initialize
  def initialize
    eagle_varshow_init
    @var_show = Spriteset_VarShow.new(@viewport2)
  end
  #--------------------------------------------------------------------------
  # ● 释放精灵
  #--------------------------------------------------------------------------
  alias eagle_varshow_dispose_timer dispose_timer
  def dispose_timer
    eagle_varshow_dispose_timer
    @var_show.dispose
  end
  #--------------------------------------------------------------------------
  # ● 更新精灵
  #--------------------------------------------------------------------------
  alias eagle_varshow_update_timer update_timer
  def update_timer
    eagle_varshow_update_timer
    @var_show.update if @var_show
  end
end
#==============================================================================
# ○ Scene_Map
#==============================================================================
class Scene_Map
  #--------------------------------------------------------------------------
  # ● 生成信息窗口
  #--------------------------------------------------------------------------
  alias eagle_varshow_create_message_window create_message_window
  def create_message_window
    eagle_varshow_create_message_window
    @spriteset.var_show.update
  end
end


#==============================================================================
# ○ Spriteset_Battle
#==============================================================================
class Spriteset_Battle
  attr_reader  :var_show
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  alias eagle_varshow_init initialize
  def initialize
    eagle_varshow_init
    @var_show = Spriteset_VarShow.new(@viewport2)
  end
  #--------------------------------------------------------------------------
  # ● 释放精灵
  #--------------------------------------------------------------------------
  alias eagle_varshow_dispose_timer dispose_timer
  def dispose_timer
    eagle_varshow_dispose_timer
    @var_show.dispose
  end
  #--------------------------------------------------------------------------
  # ● 更新精灵
  #--------------------------------------------------------------------------
  alias eagle_varshow_update_timer update_timer
  def update_timer
    eagle_varshow_update_timer
    @var_show.update if @var_show
  end
end
#==============================================================================
# ○ Scene_Battle
#==============================================================================
class Scene_Battle
  #--------------------------------------------------------------------------
  # ● 生成信息窗口
  #--------------------------------------------------------------------------
  alias eagle_varshow_create_message_window create_message_window
  def create_message_window
    eagle_varshow_create_message_window
    @spriteset.var_show.update
  end
end

#===============================================================================
# ○ Game_Interpreter
#===============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 添加注释
  #--------------------------------------------------------------------------
  alias eagle_varshow_command_108 command_108
  def command_108
    eagle_varshow_command_108
    t = @comments.inject { |t, v| t = t + "\n" + v }
    t.scan(VAR::COMMENT_VARSHOW).each do |v|
      vid = v[0].to_i
      ps = v[1].lstrip.rstrip  # tags string  # 去除前后空格
      ps = EAGLE_COMMON.parse_tags(ps)
      ps[:text] = v[2]
      ps[:text] = nil if ps[:text] == ""
      VAR.add(vid, ps)
    end
    t.scan(VAR::COMMENT_VARSHOW_FIN).each do |v|
      vid = v[0].to_i
      VAR.finish(vid)
    end
  end
end
