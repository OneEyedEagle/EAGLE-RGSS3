#==============================================================================
# ■ Add-On 贴图片 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【对话框扩展 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-MessagePics"] = "1.0.1"
#==============================================================================
# - 2022.9.12.20 重命名
#==============================================================================
# - 本插件为对话框新增了绑定图片
#----------------------------------------------------------------------------
# 【绑定图片】
#
#   当绘制到本插件新增的转义符时，将显示一张绑定于指定位置的图片。
#
# 【使用】
#
#   在对话框中，利用转义符 \pic2[id|file|param] 来进行图片的设置。
#
#   其中 id 为唯一标识符，用于后续对该图片进行控制（字符串）
#          在 Window_Message 中的脚本执行时，可用 pics(id) 获取该图片精灵
#
#   其中 file 为在 Graphics/Pictures 下的图片名称，可省略后缀名
#   若在 PIC_SYM_TO_FILENAME 中设置了 file 到图片名的映射，则优先读取映射后的名称
#
#   例如：
#     PIC_SYM_TO_FILENAME 中存在 1 => "bird_happy", 与 "bh" => "bird_happy",
#     则写 \pic2[0|1] 或 \pic2[0|bh] 时，将读取图片 bird_happy，其 id 为 "0"，
#     当然，写 \pic2[0|bird_happy] 同样能读取到该图片。
#
#   其中 |param 可省略，param 为【对话框扩展】中的变量参数字符串，每次传入都将重置
#
# 【param参数一览】
#
#    do → 设置图片绑定的位置类型
#     ·当传入 1~9 之间的数字时，图片的显示原点将绑定于对话框对应九宫格位置
#       （如1代表绑定于对话框左下角，5代表绑定于对话框中心，9代表绑定于右上角）
#     ·当传入 -1~-9 之间的数字时，图片的显示原点将绑定于屏幕对应九宫格的位置
#       （如-1代表绑定于屏幕左下角，-5代表绑定于屏幕中心，-9代表绑定于屏幕右上角）
#     ·当传入 0 时，图片将显示在对话框内部（此时参数 z 代表窗口内视图中的z值）
#       （此时新增 x 与 y 参数，用于修改在对话框内部的坐标偏移值）
#     ·当传入 nil 时，即 do$，将显示到屏幕的 (x,y) 位置（默认nil）
#
#     o → 图片的显示原点的类型（按九宫格）
#       （如传入5代表中心点为显示原点，传入7代表左上角为显示原点）
#
#    dx → x方向额外的偏移增量（水平向右为正方向）
#    dy → y方向额外的偏移增量（水平向下为正方向）
#     z → 图片的 z 值（当 do 不为0时，代表在屏幕上的z值）
#
#     x → 当 do 传入0时，代表在对话框内部的x坐标；否则代表在屏幕上的x坐标
#     y → 当 do 传入0时，代表在对话框内部的y坐标；否则代表在屏幕上的y坐标
#
#     w → 图片中，水平方向所含有的帧数
#     h → 图片中，竖直方向所含有的帧数
#       （与默认脸图类似，动态帧的读取方式为从左上角开始，先向右，再换行）
#     n → 图片中总共有的帧数
#     i → 初始显示的帧（默认0）
#     t → 每次间隔 t 帧切换到下一帧（若为 nil，则不自动切换）
#
#    it → 图片淡入时所用帧数
#    ot → 图片淡出时所用帧数
#
#     k → 是否只能绑定于当前对话框（默认true）
#          当为 true 时，当前对话框关闭时，将一同淡出；
#            当前对话框衍生出新对话框时，如 hold 转义符和 seq 转义符，
#            将随旧对话框移动，而不会转移到新对话框内
#
# 【示例】
#
#    \pic2[L|1|do3o7]这是我要说的第一句话
#       → 将 bird_happy 图片的左上角显示在对话框的右下角，其 id 为 "L"
#
#----------------------------------------------------------------------------
# 【图片控制】
#
#   在对话框中，利用转义符 \pic2m[id|motion|param] 来进行图片的动态控制。
#
#   其中 id 为在 \pic2 中设置的图片的唯一标识符
#   其中 motion 为可用的图片动作的字符串（严格大小写）
#   其中 param 可省略，为变量参数字符串
#
#   具体 motion 与 param 与【对话框扩展】中的 \facem 转义符保持一致
#
# 【示例】
#
#    在上述示例后，继续写 \pic2m[L|jump]，便是将 "L" 的图片进行一次短暂跳跃
#
#==============================================================================
module MESSAGE_EX
  #--------------------------------------------------------------------------
  # ● 【设置】定义 图片代号 → 图片名称 的映射
  #  当绘制图片时（含对话框的\pic与当前插件的\pic2），
  #  传入的文件名将首先在该常量中（转化为数字、字符串各进行一次）匹配，
  #  若失败，则将其作为文件名去目录下查找
  #--------------------------------------------------------------------------
  PIC_SYM_TO_FILENAME = {
    1 => "bird_happy",
  }
  #--------------------------------------------------------------------------
  # ● 【设置】定义\pic2各参数的预设值
  #--------------------------------------------------------------------------
  PIC2_INIT_HASH = {
    :do => nil, # 显示位置类型
    :o => 7,  # 自身显示原点类型
    :dx => 0, # 坐标偏移值
    :dy => 0,
    :x => 0,
    :y => 0,
    :z => 100,
    # 帧播放
    :w => 1,  # 横向cell数目
    :h => 1,  # 纵向cell数目
    :n => 1,  # 总帧数
    :t => 10, # 播放下一帧前的等待时间（若为nil则不切换）
    # 扩展
    :k => 1, # 是否只绑定于当前对话框
    :it => 8, # 淡入所用帧数
    :ot => 6, # 淡出所用帧数
  }
  #--------------------------------------------------------------------------
  # ● 读取绘制图片时的名称
  #--------------------------------------------------------------------------
  def self.get_pic_file(name)
    PIC_SYM_TO_FILENAME[name.to_i] || PIC_SYM_TO_FILENAME[name] || name
  end
  #--------------------------------------------------------------------------
  # ● 读取绘制图片的唯一标识符
  #--------------------------------------------------------------------------
  def self.get_pic_sym(name)
    return name.to_i if PIC_SYM_TO_FILENAME[name.to_i]
    return name
  end

  #--------------------------------------------------------------------------
  # ● 定义可用的池
  #--------------------------------------------------------------------------
  @pool_pic2s = []
  class << self
    alias eagle_pic2s_all_pools all_pools
    def all_pools
      eagle_pic2s_all_pools + [:pic2]
    end
    alias eagle_pic2s_get_pool get_pool
    def get_pool(type)
      return @pool_pic2s if type == :pic2
      eagle_pic2s_get_pool(type)
    end
  end
  #--------------------------------------------------------------------------
  # ● 对pic2精灵池的操作
  #--------------------------------------------------------------------------
  def self.pic2_push(s)
    pool_push(:pic2, s)
  end
  def self.pic2_new
    s = pool_new(:pic2)
    return Sprite_EaglePic.new if s.nil?
    s
  end

  #--------------------------------------------------------------------------
  # ● 新增一个图片精灵
  #--------------------------------------------------------------------------
  def self.pic2_add(id, filename, param = '', window = nil)
    s = pic2_get(id)
    if s.nil?
      _bitmap = Cache.picture( MESSAGE_EX.get_pic_file(filename) ) rescue return
      s = pic2_new
      s.bitmap = _bitmap
      pic2_push(s)
    end
    h = PIC2_INIT_HASH.dup
    parse_param(h, param, :def) if param
    h[:id] = id || get_pic_sym(filename)
    s.reset(window, h)
    s.motion(:fade_in)
  end
  #--------------------------------------------------------------------------
  # ● 对指定图片精灵执行动作
  #--------------------------------------------------------------------------
  def self.pic2_motion(id, sym, param = "")
    s = pic2_get(id)
    return if s.nil?
    s.motion(sym, param || "")
  end
  #--------------------------------------------------------------------------
  # ● 对全部的指定图片精灵进行操作
  #--------------------------------------------------------------------------
  def self.pic2s
    @pool_pic2s.each { |s| yield s if !s.finish? }
  end
  #--------------------------------------------------------------------------
  # ● 获取指定图片精灵
  #--------------------------------------------------------------------------
  def self.pic2_get(id)
    @pool_pic2s.each { |s| return s if !s.finish? && s.id == id }
    return nil
  end
end
#==============================================================================
# ○ Window_EagleMessage
#==============================================================================
class Window_EagleMessage
  #--------------------------------------------------------------------------
  # ● 拷贝自身（扩展用处理）
  #--------------------------------------------------------------------------
  alias eagle_message_ex_pic2_clone_ex clone_ex
  def clone_ex(t)
    MESSAGE_EX.pic2s { |s| s.bind_window(t) if s.keep?(self) }
    eagle_message_ex_pic2_clone_ex(t)
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  alias eagle_message_ex_pic2_dispose dispose
  def dispose
    MESSAGE_EX.pic2s { |s| s.motion(:fade_out) if s.keep?(self) }
    eagle_message_ex_pic2_dispose
  end
  #--------------------------------------------------------------------------
  # ● 移出全部文字精灵
  #--------------------------------------------------------------------------
  alias eagle_message_ex_pic2_sprites_move_out eagle_message_sprites_move_out
  def eagle_message_sprites_move_out
    MESSAGE_EX.pic2s { |s| s.motion(:fade_out) if s.keep?(self) }
    eagle_message_ex_pic2_sprites_move_out
  end
  #--------------------------------------------------------------------------
  # ● 设置pic2参数
  #--------------------------------------------------------------------------
  def eagle_text_control_pic2(param = '0')
    return if !@flag_draw
    params = param.split('|') # [id, filename, param_str]
    MESSAGE_EX.pic2_add(params[0], params[1], params[2] || "", self)
  end
  #--------------------------------------------------------------------------
  # ● 执行pic2m
  #--------------------------------------------------------------------------
  def eagle_text_control_pic2m(param = '0')
    return if !@flag_draw
    params = param.split('|') # [id, motion, param]
    MESSAGE_EX.pic2_motion(params[0], params[1], params[2] || "")
  end
  #--------------------------------------------------------------------------
  # ● 读取图片精灵
  #--------------------------------------------------------------------------
  def pics(id)
    MESSAGE_EX.pic2_get(id)
  end
end
#==============================================================================
# ○ Sprite_EaglePic
#==============================================================================
class Sprite_EaglePic < Sprite_EagleFace
  attr_reader  :params
  #--------------------------------------------------------------------------
  # ● 绑定
  #--------------------------------------------------------------------------
  def bind_window(window_bind)
    @window = window_bind
    self.viewport = nil
  end
  #--------------------------------------------------------------------------
  # ● 重置
  #--------------------------------------------------------------------------
  def reset(window, ps)
    bind_window(window)
    init_params
    @params = ps
    reset_pattern
    reset_oxy
    reset_xy(params[:x], params[:y])
    # 当嵌入对话框时
    #   (winx, winy) 当前对话框的位置
    @win_x0 = 0; @win_y0 = 0
    #   (x0,y0) 当前文字显示区域的左上角的屏幕坐标
    @in_win_x0 = 0; @in_win_y0 = 0
    #   (_ox,_oy) 当前文字显示区域的显示原点位置（对话框内部坐标系）
    @in_win_ox = 0; @in_win_oy = 0
  end
  #--------------------------------------------------------------------------
  # ● 唯一标识符
  #--------------------------------------------------------------------------
  def id
    @params[:id]
  end
  #--------------------------------------------------------------------------
  # ● 只显示于当前对话框？
  #--------------------------------------------------------------------------
  def keep?(w)
    @params[:k] != 0 && @window == w
  end
  #--------------------------------------------------------------------------
  # ● 重置帧数据
  #--------------------------------------------------------------------------
  def reset_pattern
    params[:w_solo] = self.width / params[:w] # 单个cell的宽高
    params[:h_solo] = self.height / params[:h]
    params[:i] ||= 0 # 当前显示的帧序号
    params[:tc] = 0 # 等待时间计数
    apply_index
  end
  #--------------------------------------------------------------------------
  # ● 应用帧
  #--------------------------------------------------------------------------
  def apply_index
    _x = params[:i] % params[:w] * params[:w_solo]
    _y = params[:i] / params[:w] * params[:w_solo]
    self.src_rect.set(_x, _y, params[:w_solo], params[:h_solo])
  end
  #--------------------------------------------------------------------------
  # ● 更新帧
  #--------------------------------------------------------------------------
  def update_pattern
    return if params[:n] <= 1
    return if params[:t].nil?
    params[:tc] += 1
    return if params[:tc] < params[:t]
    params[:i] += 1
    params[:i] = 0 if params[:i] == params[:n]
    apply_index
  end
  #--------------------------------------------------------------------------
  # ● 设置显示原点
  #--------------------------------------------------------------------------
  def reset_oxy
    case params[:o]
    when 1,4,7; self.ox = 0
    when 2,5,8; self.ox = params[:w_solo] / 2
    when 3,6,9; self.ox = params[:w_solo]
    end
    case params[:o]
    when 7,8,9; self.oy = 0
    when 4,5,6; self.oy = params[:h_solo] / 2
    when 1,2,3; self.oy = params[:h_solo]
    end
  end
  #--------------------------------------------------------------------------
  # ● 设置显示位置（基础）
  #--------------------------------------------------------------------------
  def reset_xy(x, y)
    @x0 = x
    @y0 = y
  end
  #--------------------------------------------------------------------------
  # ● 更新位置
  #--------------------------------------------------------------------------
  def update_position
    if params[:do] == nil
      update_position_base
    elsif params[:do] == 0
      update_position_in_window
    elsif params[:do] > 0
      update_position_on_window
    else
      update_position_on_screen
    end
    self.x = @x0 + @x1 + params[:dx]
    self.y = @y0 + @y1 + params[:dy]
    self.z = params[:z]
    self.opacity = @opa
  end
  #--------------------------------------------------------------------------
  # ● 更新位置：无绑定
  #--------------------------------------------------------------------------
  def update_position_base
  end
  #--------------------------------------------------------------------------
  # ● 更新位置：嵌入窗口
  #--------------------------------------------------------------------------
  def update_position_in_window
    @x0 = 0
    @y0 = 0
    if @window
      self.viewport = @window.eagle_chara_viewport
      @win_x0 = self.viewport.x
      @win_y0 = self.viewport.y
      @in_win_x0 = @window.eagle_charas_x0
      @in_win_y0 = @window.eagle_charas_y0
      if self.viewport
        @in_win_ox = @window.eagle_charas_ox
        @in_win_oy = @window.eagle_charas_oy
        @x0 -= self.viewport.rect.x
        @y0 -= self.viewport.rect.y
      end
    else
      @x0 = @win_x0
      @y0 = @win_y0
    end
    @x0 += (@in_win_x0 - @in_win_ox)
    @y0 += (@in_win_y0 - @in_win_oy)
  end
  #--------------------------------------------------------------------------
  # ● 更新位置：绑定于窗口上
  #--------------------------------------------------------------------------
  def update_position_on_window
    reset_doxy(params[:do]) if @window && !@window.disposed?
  end
  #--------------------------------------------------------------------------
  # ● 更新位置：绑定在屏幕上
  #--------------------------------------------------------------------------
  def update_position_on_screen
    reset_doxy(params[:do])
  end
  #--------------------------------------------------------------------------
  # ● 设置相对显示原点
  #--------------------------------------------------------------------------
  def reset_doxy(o)
    return if o == 0
    MESSAGE_EX.reset_xy_dorigin(self, @window, o)
    reset_xy(self.x, self.y)
  end
end
