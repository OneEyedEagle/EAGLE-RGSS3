#==============================================================================
# ■ 通知队列 by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【组件-位图绘制转义符文本 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-MessageHint"] = true
#==============================================================================
# - 2021.12.29.21
#==============================================================================
# - 本插件新增了并行显示的竖直排列的通知队列
#------------------------------------------------------------------------------
# 【新增提示：事件指令-注释】
#
# - 在事件指令-注释中，编写该样式文本（需作为行首）
#
#       通知|tag字符串|文本
#
#    其中 通知 为固定的识别文本，不可缺少
#    其中 tag字符串 可以为以下类型文本的任意组合，用空格分隔（可不写）：
#
#       id=所使用的通知队列的id（若不填，则取 default ）
#       bg=该条通知的背景类型（0为窗口皮肤，1为纯色背景，2为透明，其它为图片名称）
#          （当填入 0 时，需要前置【组件-位图绘制窗口皮肤 by老鹰】）
#          （更具体的，可以见 "HINT_BG_TYPE" 的相关注释）
#       bgo=当使用图片作为背景时，图片的对齐模式
#          （具体见 "HINT_BGPIC_O" 的相关注释，比如 5 代表图片中心与通知的中心对齐，
#             比如 2 代表图片底部中心与通知文本的底部中心对齐）
#
#    其中 文本 为通知中显示的文本，可以用 \n 来进行换行
#
# 【注意】
#
# - 不同ID的通知队列各自独立，互不影响
# - 如果想特别设置指定ID的通知队列的显示方式，请查阅下方的【设置队列】一栏
#    简单来说，就是在 PARAMS[ID] 中设置相关的 字符串 => 值
#    对于没有设置的项，依然会取 PARAMS["default"] 中的值
#
# 【示例】
#    通知||这是一条通知
#       → 在 default 队列中显示一条通知，文本内容为“这是一条通知”
#
#    通知|id=居中 bg=0|您无权进行此操作。
#       → 在 居中 队列中显示一条通知，背景使用窗口皮肤
#
#------------------------------------------------------------------------------
# 【新增提示：全局脚本】
#
# - 在全局脚本中，使用Ruby脚本随时随地增加一条即时显示的通知
#
#       MESSAGE_HINT.add(ps, id="default")
#
#    其中 ps 为Hash，其中 :text 键值存储对应的文本，:bg 键值存储背景类型
#    其中 id 为所使用的通知队列的ID，可不传入
#
# 【示例】
#    MESSAGE_HINT.add({:text => "这是一条通知"})
#       → 在 default 队列中显示一条通知，文本内容为“这是一条通知”
#
#    MESSAGE_HINT.add({:text => "您无权进行此操作。", :bg => 0}, "居中")
#       → 在 居中 队列中显示一条通知，背景使用窗口皮肤
#
#------------------------------------------------------------------------------
# 【设置队列】
#
# - 由于通知类型多种多样，不同通知也应该放置于不同位置，
#   本插件能够按照 队列id 区分不同的通知队列，各个队列可以独立预设放置位置等
#
# - 具体可见 【常量】设置你的自定义通知队列，其中已经预设了一些队列，
#   你可以在新增通知时，编写比如 id=居中 来尝试这些队列
#
# - 推荐在本插件下方新建一个命名为 【通知队列设置】 的新脚本页，
#   并复制如下的内容，进行修改和扩写：
#
=begin
# --------复制以下的内容！--------

module MESSAGE_HINT
PARAMS ||= {}  # 确保常量存在，不要删除

# 如下，自定义了一个ID为 窗口左 的通知队列，
#  在新增通知时，设置其 id=窗口左 时，将会优先使用该设置
# （对于未设置的项，将依然使用 id=default 的设置）
PARAMS["窗口左"] = {
  "HINT_OX" => 0,
  "HINT_X" => 0,
  "HINT_DX_IN" => 50,
  "HINT_DX_OUT" => -50,
}

end  # 必须的模块结尾，不要漏掉

# --------复制以上的内容！--------
=end
#
#------------------------------------------------------------------------------
# 【高级】
#
# - 利用全局脚本直接清空指定队列：
#
#      MESSAGE_HINT.clear(id)
#
#   也可以省略 id ，直接使用 MESSAGE_HINT.clear ，则为清空 "default" 队列。
#
# - 利用全局脚本在游戏过程中覆盖修改指定队列的设置：
#
#     MESSAGE_HINT.set(k, v, id = "default")
#
#   其中 k 为参数名称（字符串），具体可见 PARAMS[id] 中的键值， v 为其对应的值
#       id 为队列的ID，默认取 "default"
#
#   该设置优先级 > PARAMS[id] > PARAMS["default"]
#
#==============================================================================

module MESSAGE_HINT
  #--------------------------------------------------------------------------
  # ○【常量】事件指令-注释 中新增通知的文本
  #--------------------------------------------------------------------------
  COMMENT_MESSAGE_HINT = /^通知 *?\| *?(.*?) *?\| *?(.*)/mi
  #--------------------------------------------------------------------------
  # ●【常量】存储全部设置
  #--------------------------------------------------------------------------
  PARAMS ||= {}
  #--------------------------------------------------------------------------
  # ●【常量】默认设置一览
  #--------------------------------------------------------------------------
  PARAMS["default"] = {
    #----------------------------------------------------------------------
    # 【背景相关】
    #----------------------------------------------------------------------
    # - 单个通知的背景
    #  填写 0 代表使用 窗口皮肤
    #    需要前置【组件-位图绘制窗口皮肤 by老鹰】
    #    窗口皮肤的文件名称写入 HINT_BG0_WINDOWSKIN，位于 Graphics/System 目录下
    #  填写 1 代表使用 纯色背景
    #    所使用的颜色请写入 HINT_BG1_COLOR
    #  填写 2 代表使用 透明背景
    #  填写 字符串 代表使用图片，位于 Graphics/System 目录下
    "HINT_BG_TYPE" => 0,
    #----------------------------------------------------------------------
    # - 通知的背景类型为 0 时生效
    #  窗口皮肤的名称
    "HINT_BG0_WINDOWSKIN" => "Window",
    #  窗口四周留白的宽度/高度
    "HINT_BG0_PADDING" => 8,
    #----------------------------------------------------------------------
    # - 通知的背景类型为 1 时生效
    #  背景颜色
    "HINT_BG1_COLOR" => Color.new(0,0,0, 150),
    #  窗口四周留白的宽度/高度
    "HINT_BG1_PADDING" => 4,
    #----------------------------------------------------------------------
    # - 通知的背景类型为 2 时生效
    #  窗口四周留白的宽度/高度
    "HINT_BG2_PADDING" => 2,
    #----------------------------------------------------------------------
    # - 通知的背景类型为 图片 时生效
    #  设置图片拷贝的位置（当文字的总宽高大于图片宽高时生效）
    #  此处为九宫格小键盘的对应位置，比如 7 代表图片左上角和位图左上角对齐，
    #    5 代表图片中心和位图中心对齐， 3 代表图片右下角和位图右下角对齐
    "HINT_BGPIC_O" => 7,

    #----------------------------------------------------------------------
    # 【文本相关】
    #----------------------------------------------------------------------
    # - 通知文本的文字初始位置
    #  (0, 0) 为位图的左上角，可以调整位置以适配背景图片
    "HINT_TEXT_X" => 0,
    "HINT_TEXT_Y" => 0,
    #----------------------------------------------------------------------
    # - 通知文本的文字大小
    "HINT_FONT_SIZE" => 16,
    #----------------------------------------------------------------------
    # - 通知文本的文字颜色
    #  填写颜色对象 Color.new(r, g, b, a)
    #  如果填入 nil，则取窗口皮肤的 0 号颜色
    "HINT_FONT_COLOR" => nil,
    #----------------------------------------------------------------------
    # - 通知文本的每一行的最大宽度
    #  填写 nil 代表无限制
    "HINT_LINE_WIDTH" => nil,
    #----------------------------------------------------------------------
    # - 通知文本的行内对齐方式
    #  填写 0 代表行内左对齐，1 代表行内居中对齐，2 代表行内右对齐
    "HINT_LINE_ALI" => 0,
    #----------------------------------------------------------------------
    # - 通知文本的左侧的额外留白宽度
    "HINT_TEXT_W_ADD_L" => 0,
    #----------------------------------------------------------------------
    # - 通知文本的右侧的额外留白宽度
    "HINT_TEXT_W_ADD_R" => 0,

    #----------------------------------------------------------------------
    # 【位置相关】
    #----------------------------------------------------------------------
    # - 通知的显示区域
    #  填写矩形对象 Rect.new(x,y,w,h)，其中均为屏幕上的坐标和宽高
    #  如果填写 nil，则为全屏
    #  （注意：在游戏中途修改该参数，将不会生效）
    "VIEWPORT_RECT" => nil,
    #----------------------------------------------------------------------
    # - 通知队列的初始显示位置
    "HINT_X" => Graphics.width,
    "HINT_Y" => Graphics.height - 100,
     # 当 "VIEWPORT_RECT" 为nil时，此为屏幕上的z值，注意别被其他窗口挡住了
    "HINT_Z" => 500,
    #----------------------------------------------------------------------
    # - 通知精灵的显示原点位置
    #   该值为比例值，将取宽度/高度的对应位置
    "HINT_OX" => 1,
    "HINT_OY" => 0.5,
    #----------------------------------------------------------------------
    # - 通知精灵的位置摆放类型
    # 0 → 最新的通知显示在 (HINT_X, HINT_Y) 处
    # 1 → 最旧的通知显示在 (HINT_X, HINT_Y) 处
    "HINT_POS_TYPE" => 1,
    #----------------------------------------------------------------------
    # - 通知精灵的插入方式
    # 0 → 最新的通知显示在旧通知的上方
    # 1 → 最新的通知显示在旧通知的下方
    "HINT_IN_TYPE" => 0,
    #----------------------------------------------------------------------
    # - 上下通知精灵之间的空隙
    "HINT_Y_OFFSET" => 2,

    #----------------------------------------------------------------------
    # 【移入移出相关】
    #----------------------------------------------------------------------
    # - 等待该帧数后，自动移出最早的一条通知
    "COUNT_MOVE_OUT" => 90,
    #----------------------------------------------------------------------
    # - 通知数量大于该值时，自动移出最早的一条通知
    "COUNT_MAX_OUT" => 10,
    #----------------------------------------------------------------------
    # - 在移入移出过程中，需要消耗的帧数
    "HINT_IN_OUT_T" => 20,
    #----------------------------------------------------------------------
    # - 在移入过程中，通知精灵的x/y偏移增量（逐渐从该值变为0）
    "HINT_DX_IN" => 50,
    "HINT_DY_IN" => 0,
    #----------------------------------------------------------------------
    # - 在移出过程中，通知精灵的x/y偏移增量（逐渐从0变为该值）
    "HINT_DX_OUT" => 50,
    "HINT_DY_OUT" => 0,
  }

  #--------------------------------------------------------------------------
  # ●【常量】设置你的自定义通知队列
  #--------------------------------------------------------------------------
  # 比如该处的通知队列的 id 为 "窗口左"
  #  具体效果为队列显示在窗口左侧
  PARAMS["窗口左"] = {
    "HINT_OX" => 0,
    "HINT_X" => 0,
    "HINT_DX_IN" => 50,
    "HINT_DX_OUT" => -50,
  }
  # 比如该处的通知队列的 id 为 "居中偏上"
  #  具体效果为队列显示在窗口中间，旧通知朝上移动
  PARAMS["居中偏上"] = {
    "HINT_BG_TYPE" => 1,
    "HINT_BG1_COLOR" => Color.new(0,0,0, 150),
    "HINT_FONT_COLOR" => Color.new(255,255,255,255),
    "HINT_POS_TYPE" => 0,
    "HINT_IN_TYPE" => 1,
    "HINT_X" => Graphics.width / 2,
    "HINT_Y" => Graphics.height / 2 - 70,
    "HINT_OX" => 0.5,
    "HINT_OY" => 0.5,
    "HINT_DX_IN" => 0,
    "HINT_DY_IN" => 50,
    "HINT_DX_OUT" => 0,
    "HINT_DY_OUT" => -50,
  }
  # 和上一个 “居中偏上” 相反，显示在屏幕中间下方一点
  PARAMS["居中偏下"] = {
    "HINT_BG_TYPE" => 1,
    "HINT_BG1_COLOR" => Color.new(0,0,0, 150),
    "HINT_FONT_COLOR" => Color.new(255,255,255,255),
    "HINT_POS_TYPE" => 0,
    "HINT_IN_TYPE" => 0,
    "HINT_X" => Graphics.width / 2,
    "HINT_Y" => Graphics.height / 2 + 70,
    "HINT_OX" => 0.5,
    "HINT_OY" => 0.5,
    "HINT_DX_IN" => 0,
    "HINT_DY_IN" => -50,
    "HINT_DX_OUT" => 0,
    "HINT_DY_OUT" => 50,
  }
end  # 不要删除

#===============================================================================
# ○ 以下不要修改！
#===============================================================================
module MESSAGE_HINT
  #--------------------------------------------------------------------------
  # ● 通用变量
  #--------------------------------------------------------------------------
  @data = {} # id => Spriteset_EagleHint
  #--------------------------------------------------------------------------
  # ● 新增
  #--------------------------------------------------------------------------
  # ps[:text] = ""
  def self.add(ps, id="default")
    $game_system.eagle_message_hint_params ||= {}
    @data[id] ||= Spriteset_EagleHint.new(id)
    @data[id].add(ps)
  end
  #--------------------------------------------------------------------------
  # ● 参数设置
  #--------------------------------------------------------------------------
  def self.set(k, v, id = "default")
    $game_system.eagle_message_hint_params[id] ||= {}
    $game_system.eagle_message_hint_params[id][k] = v
  end
  #--------------------------------------------------------------------------
  # ● 获取参数组
  #--------------------------------------------------------------------------
  def self.params(id = "default")
    ps0 = PARAMS["default"].dup
    ps1 = PARAMS[id] || {} if id != "default"
    ps2 = $game_system.eagle_message_hint_params[id] || {}
    ps0 = ps0.merge!(ps1) if ps1
    ps0 = ps0.merge!(ps2)
    ps0
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def self.update
    @data.each { |id, d| d.update }
  end
  #--------------------------------------------------------------------------
  # ● 清空
  #--------------------------------------------------------------------------
  def self.clear(id = "default")
    return if @data[id] == nil
    @data[id].clear
  end
end
#===============================================================================
# ○ Scene_Base
#===============================================================================
class Scene_Base
  #--------------------------------------------------------------------------
  # ● 基础更新
  #--------------------------------------------------------------------------
  alias eagle_message_hint_update_basic update_basic
  def update_basic
    eagle_message_hint_update_basic
    MESSAGE_HINT.update
  end
end
#===============================================================================
# ○ 通用
#===============================================================================
module MESSAGE_HINT
  #--------------------------------------------------------------------------
  # ● 解析tags文本
  #--------------------------------------------------------------------------
  def self.parse_tags(_t)
    # 脚本替换
    _evals = {}; _eval_i = -1
    _t.gsub!(/{(.*?)}/) { _eval_i += 1; _evals[_eval_i] = $1; "<#{_eval_i}>" }
    # 处理等号左右的空格
    _t.gsub!( / *= */ ) { '=' }
    # tag 拆分
    _ts = _t.split(/ | /)
    # tag 解析
    _hash = {}
    _ts.each do |_tag|  # _tag = "xxx=xxx"
      _tags = _tag.split('=')
      _k = _tags[0].downcase
      _v = _tags[1]
      _hash[_k.to_sym] = _v
    end
    # 脚本替换
    _hash.keys.each do |k|
      _hash[k] = _hash[k].gsub(/<(\d+)>/) { _evals[$1.to_i] }
    end
    return _hash
  end
  #--------------------------------------------------------------------------
  # ● 依据原点类型（九宫格），将b2位图拷贝到b1位图对应位置
  # 需确保 b1 的宽高均大于 b2
  #--------------------------------------------------------------------------
  def self.bitmap_copy_do(b1, b2, o)
    x = y = 0
    case o
    when 1,4,7; x = 0
    when 2,5,8; x = b1.width / 2 - b2.width / 2
    when 3,6,9; x = b1.width - b2.width
    end
    case o
    when 1,2,3; y = b1.height - b2.height
    when 4,5,6; y = b1.height / 2 - b2.height / 2
    when 7,8,9; y = 0
    end
    b1.blt(x, y, b2, b2.rect)
  end
end
#===============================================================================
# ○ Spriteset_EagleHint
#===============================================================================
class Spriteset_EagleHint
  include MESSAGE_HINT
  attr_reader  :id, :params
  #--------------------------------------------------------------------------
  # ● 类变量
  #--------------------------------------------------------------------------
  @@sprites_fin = []  # 已经显示完成的精灵（可以复用）
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(id)
    @id = id
    reset_params
    if @params["VIEWPORT_RECT"]
      @viewport = Viewport.new(@params["VIEWPORT_RECT"])
    else
      @viewport = Viewport.new
    end
    @data = []    # 待生成的数据
    @sprites = [] # 当前正在显示的精灵
    @num_out = 0  # 需要移出的精灵数量
    @count = 0    # 移出计数
  end
  #--------------------------------------------------------------------------
  # ● 重新读取参数
  #--------------------------------------------------------------------------
  def reset_params
    @params = MESSAGE_HINT.params(@id)
  end
  #--------------------------------------------------------------------------
  # ● 获得一个可用精灵
  #--------------------------------------------------------------------------
  def new_sprite
    if @@sprites_fin.empty?
      return Sprite_EagleHint.new(@viewport, self)
    end
    s = @@sprites_fin.shift
    s.reset(@viewport, self)
    s
  end
  #--------------------------------------------------------------------------
  # ● 新增
  #--------------------------------------------------------------------------
  def add(ps)
    @data.push(ps)
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    f = false
    @sprites.each { |s|
      s.update
      @@sprites_fin.push(s) if s.fin?
      f = true if s.in_or_out?
    }
    @sprites.delete_if { |s| s.fin? }
    update_out_count
    return if f
    return if !@sprites.empty? && update_pos
    update_new if !@data.empty?
    update_out if @num_out > 0
  end
  #--------------------------------------------------------------------------
  # ● 更新移出计数
  #--------------------------------------------------------------------------
  def update_out_count
    if @sprites.size == 0
      @num_out = 0
      return @count = 0
    end
    @count += 1
    f = false
    f = true if @count > @params["COUNT_MOVE_OUT"]
    f = true if @sprites.size > @params["COUNT_MAX_OUT"] && !@sprites[0].in_or_out?
    if f
      @num_out += 1
      @count = 0
      reset_params
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新生成
  #--------------------------------------------------------------------------
  def update_new
    d = @data.shift
    s = new_sprite
    s.redraw(d)
    s.move_in
    s.set_oxy(@params["HINT_OX"], @params["HINT_OY"])
    after_add_new(s)
    s.set_dxy(@params["HINT_DX_IN"], @params["HINT_DY_IN"])
    s.set_des_dxy(-@params["HINT_DX_IN"], -@params["HINT_DY_IN"])
    @sprites.push(s)
  end
  #--------------------------------------------------------------------------
  # ● 在新增加一个通知后的处理
  #--------------------------------------------------------------------------
  def after_add_new(s)
    s.set_xy(@params["HINT_X"], @params["HINT_Y"])
    s.z = @params["HINT_Z"]
    dh = @params["HINT_Y_OFFSET"]
    if @params["HINT_POS_TYPE"] == 0  # 最新的通知显示在预设处
      if @sprites[-1] != nil
        _s = @sprites[-1]
        if @params["HINT_IN_TYPE"] == 0  # 最新的通知显示在上方
          # 先使倒数第二个通知左上角与当前通知对齐，再加上需要移动的距离
          d = (s.y-s.oy) - (_s.y-_s.oy) + s.height + dh   # 旧通知下移
        elsif @params["HINT_IN_TYPE"] == 1  # 最新的通知显示在下方
          d = (s.y-s.oy) - (_s.y-_s.oy) - _s.height - dh   # 旧通知上移
        end
        @sprites.each { |_s| _s.set_des_dxy(0, d) }
      end
    elsif @params["HINT_POS_TYPE"] == 1  # 最旧的通知显示在预设处
      if @sprites[-1] != nil
        _y = @sprites[-1].y - @sprites[-1].oy
        if @params["HINT_IN_TYPE"] == 0  # 最新的通知显示在上方
          s.set_xy(nil, _y - dh - s.height + s.oy)
        elsif @params["HINT_IN_TYPE"] == 1  # 最新的通知显示在下方
          s.set_xy(nil, _y + dh + @sprites[-1].height + s.oy)
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新移出
  #--------------------------------------------------------------------------
  def update_out
    @sprites[0].move_out
    @sprites[0].set_des_dxy(@params["HINT_DX_OUT"], @params["HINT_DY_OUT"])
    @num_out -= 1
  end
  #--------------------------------------------------------------------------
  # ● 更新位置
  #--------------------------------------------------------------------------
  def update_pos
    if @params["HINT_POS_TYPE"] == 1  # 最旧的通知显示在预设处
      dx = @params["HINT_X"] - @sprites[0].x
      dy = @params["HINT_Y"] - @sprites[0].y
      if dx != 0 || dy != 0
        @sprites.each { |_s| _s.set_des_dxy(dx, dy) }
        return true
      end
    end
    return false
  end
  #--------------------------------------------------------------------------
  # ● 清空
  #--------------------------------------------------------------------------
  def clear
    @num_out = 999
  end
end
#===============================================================================
# ○ Sprite_EagleHint
#===============================================================================
class Sprite_EagleHint < Sprite
  include MESSAGE_HINT
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(viewport, spriteset)
    super(viewport)
    reset(viewport, spriteset)
  end
  #--------------------------------------------------------------------------
  # ● 重置
  #--------------------------------------------------------------------------
  def reset(viewport, spriteset)
    self.viewport = viewport
    @spriteset = spriteset
    @params_move = { :active => false }
    self.ox = self.oy = 0
    set_xy(0, 0)
  end
  #--------------------------------------------------------------------------
  # ● 重绘
  #--------------------------------------------------------------------------
  def redraw(params)
    # 处理文字宽高
    params[:text_ps] = { :font_size => @spriteset.params["HINT_FONT_SIZE"],
      :x0 => 0, :y0 => 0, :lhd => 2,
      :w => @spriteset.params["HINT_LINE_WIDTH"],
      :ali => @spriteset.params["HINT_LINE_ALI"],
    }
    if @spriteset.params["HINT_FONT_COLOR"]
      params[:text_ps][:font_color] = @spriteset.params["HINT_FONT_COLOR"]
    end
    d = Process_DrawTextEX.new(params[:text], params[:text_ps])
    d.run(false)
    params[:text_w] = d.width
    params[:text_h] = d.height
    self.bitmap.dispose if self.bitmap
    redraw_contents(params)
    # 绘制文字
    d.bind_bitmap(self.bitmap)
    d.run(true)
  end
  #--------------------------------------------------------------------------
  # ● 绘制内容
  #--------------------------------------------------------------------------
  def redraw_contents(params)
    w = params[:text_w] + @spriteset.params["HINT_TEXT_X"]
    w += @spriteset.params["HINT_TEXT_W_ADD_L"]
    w += @spriteset.params["HINT_TEXT_W_ADD_R"]
    h = params[:text_h] + @spriteset.params["HINT_TEXT_Y"]
    params[:text_ps][:x0] = @spriteset.params["HINT_TEXT_X"] + \
      @spriteset.params["HINT_TEXT_W_ADD_L"]
    params[:text_ps][:y0] = @spriteset.params["HINT_TEXT_Y"]
    # 获取背景类型
    bg_type = @spriteset.params["HINT_BG_TYPE"]
    if params[:bg]
      bg_type = params[:bg]
      bg_type = bg_type.to_i if bg_type.size == 1 && bg_type.to_i >= 0
    end
    # 处理四周的留白
    padding = 0
    if bg_type == 0  # 绘制windowskin
      padding = @spriteset.params["HINT_BG0_PADDING"]
    elsif bg_type == 1  # 绘制纯色背景
      padding = @spriteset.params["HINT_BG1_PADDING"]
    elsif bg_type == 2  # 透明背景
      padding = @spriteset.params["HINT_BG2_PADDING"]
    elsif bg_type.is_a?(String)  # 图片背景
    end
    params[:text_ps][:x0] += padding  # 文字绘制的左上角增加padding
    params[:text_ps][:y0] += padding
    w += padding * 2 # 宽高增加
    h += padding * 2
    # 绘制背景
    if bg_type == 0  # 绘制windowskin
      self.bitmap = Bitmap.new(w, h)
      skin = @spriteset.params["HINT_BG0_WINDOWSKIN"]
      begin
        r = Rect.new(0, 0, self.width, self.height)
        EAGLE.draw_windowskin(skin, self.bitmap, r)
      rescue
      end
    elsif bg_type == 1  # 绘制纯色背景
      self.bitmap = Bitmap.new(w, h)
      c = @spriteset.params["HINT_BG1_COLOR"]
      self.bitmap.fill_rect(self.bitmap.rect, c)
    elsif bg_type == 2  # 透明背景
      self.bitmap = Bitmap.new(w, h)
    elsif bg_type.is_a?(String)  # 图片背景
      _b = Cache.system(bg_type) rescue nil
      if _b
        self.bitmap = Bitmap.new([w, _b.width].max, [h, _b.height].max)
        o = params[:bgo] || @spriteset.params["HINT_BGPIC_O"]
        MESSAGE_HINT.bitmap_copy_do(self.bitmap, _b, o.to_i)
      else
        self.bitmap = Bitmap.new(w, h)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 移入移出开始
  #--------------------------------------------------------------------------
  def move_in
    self.opacity = 0
    @params_move[:in] = true
    @params_move[:out] = false
  end
  def move_out
    @params_move[:in] = false
    @params_move[:out] = true
  end
  #--------------------------------------------------------------------------
  # ● 完成？
  #--------------------------------------------------------------------------
  def fin?
    self.opacity == 0
  end
  #--------------------------------------------------------------------------
  # ● 在移入移出？
  #--------------------------------------------------------------------------
  def in_or_out?
    @params_move[:in] || @params_move[:out] || @params_move[:active]
  end
  #--------------------------------------------------------------------------
  # ● 直接指定oxy
  #--------------------------------------------------------------------------
  def set_oxy(_ox = nil, _oy = nil)
    self.ox = self.width * _ox if _ox
    self.oy = self.height * _oy if _oy
  end
  #--------------------------------------------------------------------------
  # ● 直接指定xy
  #--------------------------------------------------------------------------
  def set_xy(x = nil, y = nil)
    @x0 = x || self.x
    @y0 = y || self.y
    @dx = 0
    @dy = 0
    update_position
    @params_move[:active] = false
  end
  #--------------------------------------------------------------------------
  # ● 直接修改xy
  #--------------------------------------------------------------------------
  def set_dxy(dx = 0, dy = 0)
    set_xy(self.x + dx, self.y + dy)
  end
  #--------------------------------------------------------------------------
  # ● 指定目的xy（偏移量）
  #--------------------------------------------------------------------------
  def set_des_dxy(des_dx = 0, des_dy = 0)
    set_des_xy(self.x + des_dx, self.y + des_dy)
  end
  #--------------------------------------------------------------------------
  # ● 指定目的xy（开始移动）
  #--------------------------------------------------------------------------
  def set_des_xy(des_x = nil, des_y = nil)
    set_xy
    @params_move[:t] = @spriteset.params["HINT_IN_OUT_T"].to_i rescue 20
    @params_move[:i] = 0
    @params_move[:dx_init] = 0
    @params_move[:dy_init] = 0
    @params_move[:dx_d] = des_x - self.x
    @params_move[:dy_d] = des_y - self.y
    @params_move[:des_x] = des_x
    @params_move[:des_y] = des_y
    @params_move[:active] = true
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    update_position
    update_move if @params_move[:active]
    update_in_out
  end
  #--------------------------------------------------------------------------
  # ● 更新位置
  #--------------------------------------------------------------------------
  def update_position
    self.x = @x0 + @dx
    self.y = @y0 + @dy
  end
  #--------------------------------------------------------------------------
  # ● 更新移动
  #--------------------------------------------------------------------------
  def update_move
    @params_move[:i] += 1
    per = @params_move[:i] * 1.0 / @params_move[:t]
    f = @params_move[:i] == @params_move[:t]
    per = (f ? 1 : ease_value(per))
    @dx = @params_move[:dx_init] + @params_move[:dx_d] * per
    @dy = @params_move[:dy_init] + @params_move[:dy_d] * per
    if f
      set_xy(@params_move[:des_x], @params_move[:des_y])
      @params_move[:active] = false
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新移入移出的不透明度
  #--------------------------------------------------------------------------
  def update_in_out
    if @params_move[:in]
      if self.opacity < 255
        self.opacity += 15
      else
        @params_move[:in] = false
      end
    end
    if @params_move[:out]
      if self.opacity > 0
        self.opacity -= 15
      else
        @params_move[:out] = false
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 缓动函数
  #--------------------------------------------------------------------------
  def ease_value(v)
    if $imported["EAGLE-EasingFunction"]
      return EasingFuction.call("easeOutBack", v)
    end
    return 1 - 2**(-10 * v)
  end
end

#===============================================================================
# ○ Game_System
#===============================================================================
class Game_System
  attr_accessor  :eagle_message_hint_params
end
#===============================================================================
# ○ Game_Interpreter
#===============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 添加注释
  #--------------------------------------------------------------------------
  alias eagle_message_hint_command_108 command_108
  def command_108
    eagle_message_hint_command_108
    t = @comments.inject { |t, v| t = t + "\n" + v }
    t.scan(MESSAGE_HINT::COMMENT_MESSAGE_HINT).each do |v|
      ps = v[0].lstrip.rstrip  # tags string  # 去除前后空格
      ps = MESSAGE_HINT.parse_tags(ps)
      ps[:text] = v[1]  # text
      ps[:id] ||= "default"
      MESSAGE_HINT.add(ps, ps[:id])
    end
  end
end
