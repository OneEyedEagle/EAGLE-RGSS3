#==============================================================================
# ■ Add-On 贴图片 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【鹰式对话框扩展 V2.0】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-MessagePics"] = "2.2.0"
#==============================================================================
# - 2026.2.22.11 随对话框更新
#==============================================================================
# - 本插件为对话框新增了显示图片
#-----------------------------------------------------------------------------
module MESSAGE_EX
#╔════════════════════════════════════════╗
# A■ 图片绘制设置                                                      \PIC2 ■
#  ────────────────────────────────────────

#  ● \pic2[图片序号|文件名|param]

#  · 图片序号   →  每张图片都要有一个序号，方便利用转义符进行控制。
#                  注意：这个是字符串！
#            
#                 【高级】如果你会脚本，可以用 MESSAGE_EX.pic2_get("图片序号")
#                    或者（有对话框窗口 msg 后）msg.pics("图片序号")，
#                    获取这张图片的精灵。
#
#  · 文件名     →  在 Graphics/Pictures 下的图片名称，可省略后缀名。
#                  如果在 PIC_SYM_TO_FILENAME 中有设置，则优先读取其中的名称。
#
#                  如：
#                    PIC_SYM_TO_FILENAME 中设置了 
#                        1 => "bird_happy",  "bh" => "bird_happy",
#                    那么 \pic2[0|1] 或 \pic2[0|bh] ，都会读取图片 bird_happy，
#                    当然，直接写 \pic2[0|bird_happy] 也能读取该图片。

#     ---------------------------------------------------------------------
#  ◇ 预设参数         ▼ [param]“参数串”一览（字母+数字组合）
  PIC2_INIT_HASH = {
    # （位置相关）
    :do => nil,   # 显示位置的类型
                  #  *  1~9  → 图片将绑定于对话框对应九宫格位置
                  #           （1对话框左下角，5对话框中心，9右上角）
                  #  * -1~-9 → 图片将绑定于屏幕对应九宫格位置
                  #           （-1屏幕左下角，-5屏幕中心，-9屏幕右上角）
                  #  * 0 → 图片将嵌入对话框内部，并根据 :z 的值浮于文字上方或下方
                  #        此时 :x 和 :y 生效，用于设置图片在对话框内的坐标
                  #  * nil($) → 图片将直接显示在屏幕的 (x,y) 位置
    :o  => 7,     # 显示原点类型（5中心为显示原点，7左上角为显示原点）
    :dx => 0,     # 图片位置的左右偏移值（正数往右、负数往左）
    :dy => 0,     # 图片位置的上下偏移值（正数往下、负数往上）
    :x  => 0,     # 当 :do 为 nil 或 0 时生效，图片位置的坐标
    :y  => 0,     
    :z  => 100,   # 图片的 z 值（当 do 不为0时，代表在屏幕上的z值）
    # （动画相关）
    :w => 1,      # 图片中水平方向的帧数
    :h => 1,      # 图片中竖直方向的帧数
    :n => 1,      # 图片中的总帧数
                  #  * 与默认脸图类似，动画帧的读取方式为从左上角开始，先向右，再换行
    :i => 0,      # 初始显示的帧
    :t => 10,     # 播放下一帧前的等待时间（若nil($)则不会自动切换）
    # （移入移出）
    :it => 8,     # 图片淡入时所用帧数
    :ot => 6,     # 图片淡出时所用帧数
    # （其它）
    :k => 1,      # 是否只能绑定于当前对话框（1是 0否）
                  #  * 1 → 当前对话框关闭时图片将一同淡出。
                  #        当前对话框衍生出新对话框时，如利用 \hold \seq，
                  #          图片将随旧对话框移动，而不转移到新对话框内。
  }
#     ---------------------------------------------------------------------
#  ？ 示例
#
#    \pic2[L|1|do3]这是我要说的第一句话
#
#       → 将 bird_happy 图片显示在对话框的右下角，其 图片序号 为 "L"
#
#╚════════════════════════════════════════╝

#╔════════════════════════════════════════╗
# B■ 图片控制                                                       \PIC2M ■
#  ────────────────────────────────────────

#  ● \pic2m[图片序号|动作|param]

#  · 动作     →  具体见【鹰式对话框扩展】中的 \facem 转义符
#
#     ---------------------------------------------------------------------
#  ？ 示例
#
#    在上述示例后，继续写 \pic2m[L|jump]，便是将 "L" 的图片进行一次短暂跳跃
#
#╚════════════════════════════════════════╝

#     ---------------------------------------------------------------------
#  ◇ [预设]图片的简称              > 素材文件存储于 Graphics/System 目录下
#
#  ├  \pic 与 \pic2 都生效
#
#  ├  对于图片名，先会转化成数字来这里匹配，然后字符串直接匹配，
#       如果都没匹配到，就直接去目录下找图片。
#
  PIC_SYM_TO_FILENAME = {
    1 => "bird_happy",
  }

#==============================================================================
#                                 × 设定完毕 × 
#==============================================================================

  # 读取绘制图片时的名称
  def self.get_pic_file(name)
    PIC_SYM_TO_FILENAME[name.to_i] || PIC_SYM_TO_FILENAME[name] || name
  end
  # 读取绘制图片的唯一标识符
  def self.get_pic_sym(name)
    return name.to_i if PIC_SYM_TO_FILENAME[name.to_i]
    return name
  end

  #--------------------------------------------------------------------------
  # ● 精灵池
  #--------------------------------------------------------------------------
  class << self
    alias eagle_pic2s_all_pools all_pools
    def all_pools
      eagle_pic2s_all_pools + [:pic2]
    end
  end
  def self.pic2_push(s)
    pool_push(:pic2, s)
  end
  def self.pic2_new
    s = pool_new(:pic2)
    return Sprite_EaglePic.new if s.nil?
    s
  end

  #--------------------------------------------------------------------------
  # ● 图片精灵的处理
  #--------------------------------------------------------------------------
  # 新增一个图片精灵
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

  # 对全部的指定图片精灵进行操作
  def self.pic2s
    get_pool(:pic2).each { |s| yield s if !s.finish? }
  end

  # 获取指定图片精灵
  def self.pic2_get(id)
    get_pool(:pic2).each { |s| return s if !s.finish? && s.id == id }
    return nil
  end

  # 对指定图片精灵执行动作
  def self.pic2_motion(id, sym, param = "")
    s = pic2_get(id)
    return if s.nil?
    s.motion(sym, param || "")
  end
end

#==============================================================================
# ○ Window_EagleMessage
#==============================================================================
class Window_EagleMessage
  #--------------------------------------------------------------------------
  # ●（外部用）读取指定的图片精灵
  #--------------------------------------------------------------------------
  def pics(id)
    MESSAGE_EX.pic2_get(id)
  end
  
  # 拷贝自身（扩展用处理）
  alias eagle_message_ex_pic2_clone_ex clone_ex
  def clone_ex(t)
    MESSAGE_EX.pic2s { |s| s.bind_window(t) if s.keep?(self) }
    eagle_message_ex_pic2_clone_ex(t)
  end

  # 释放
  alias eagle_message_ex_pic2_dispose dispose
  def dispose
    MESSAGE_EX.pic2s { |s| s.motion(:fade_out) if s.keep?(self) }
    eagle_message_ex_pic2_dispose
  end

  # 移出全部文字精灵
  alias eagle_message_ex_pic2_sprites_move_out eagle_message_sprites_move_out
  def eagle_message_sprites_move_out
    MESSAGE_EX.pic2s { |s| s.motion(:fade_out) if s.keep?(self) }
    eagle_message_ex_pic2_sprites_move_out
  end

  #--------------------------------------------------------------------------
  # ● \pic2
  #--------------------------------------------------------------------------
  def eagle_text_control_pic2(param = '0')
    return if !@flag_draw
    params = param.split('|') # [id, filename, param_str]
    MESSAGE_EX.pic2_add(params[0], params[1], params[2] || "", self)
  end

  #--------------------------------------------------------------------------
  # ● \pic2m
  #--------------------------------------------------------------------------
  def eagle_text_control_pic2m(param = '0')
    return if !@flag_draw
    params = param.split('|') # [id, motion, param]
    MESSAGE_EX.pic2_motion(params[0], params[1], params[2] || "")
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

  # 获取当前图片的唯一标识符
  def id; @params[:id]; end

  # 当前图片只显示于当前对话框？
  def keep?(w)
    @params[:k] != 0 && @window == w
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

  # 设置显示原点
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

  # 设置相对显示原点
  def reset_doxy(o)
    return if o == 0
    MESSAGE_EX.reset_xy_dorigin(self, @window, o)
    reset_xy(self.x, self.y)
  end

  # 设置显示位置（基础）
  def reset_xy(x, y)
    @x0 = x
    @y0 = y
  end

  #--------------------------------------------------------------------------
  # ● 帧动画
  #--------------------------------------------------------------------------
  # 重置帧数据
  def reset_pattern
    params[:w_solo] = self.width / params[:w] # 单个cell的宽高
    params[:h_solo] = self.height / params[:h]
    params[:i] ||= 0 # 当前显示的帧序号
    params[:tc] = 0 # 等待时间计数
    apply_index
  end

  # 应用帧
  def apply_index
    _x = params[:i] % params[:w] * params[:w_solo]
    _y = params[:i] / params[:w] * params[:w_solo]
    self.src_rect.set(_x, _y, params[:w_solo], params[:h_solo])
  end

  # 更新帧
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

  # 更新位置：无绑定
  def update_position_base
  end

  # 更新位置：嵌入窗口
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

  # 更新位置：绑定于窗口上
  def update_position_on_window
    reset_doxy(params[:do]) if @window && !@window.disposed?
  end

  # 更新位置：绑定在屏幕上
  def update_position_on_screen
    reset_doxy(params[:do])
  end
end
