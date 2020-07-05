#==============================================================================
# ■ Add-On 对话框附加图片 by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【对话框扩展 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-MessagePics"] = true
#==============================================================================
# - 2020.7.5.15
#==============================================================================
# - 本插件为对话框新增了绑定图片
#----------------------------------------------------------------------------
# 【绑定图片】
#
#   当绘制到本插件新增的转义符时，将显示一张绑定于指定位置的图片。
#
# 【使用】
#
#   在对话框中，利用转义符 \epic[file|param] 来进行图片的设置。
#
#   其中 file 为在 Graphics/Pictures 下的图片名称，可省略后缀名。
#   若在 PIC_SYM_TO_FILENAME 中设置了 file 到图片名的映射，则优先读取映射后的名称。
#
#   例如：
#     PIC_SYM_TO_FILENAME 中存在 1 => "bird_happy", 与 "bh" => "bird_happy",
#     则写 \epic[1] 或 \epic[bh] 时，将读取 bird_happy 名称的图片。
#     当然，写 \epic[bird_happy] 同样会读取该图片。
#
#   其中 |param 可省略，param 为【对话框扩展】中的变量参数字符串。
#
# 【参数一览】
#
#    do → 设置图片绑定的位置类型
#     ·当传入 1~9 之间的数字时，图片的显示原点将绑定于对话框对应九宫格位置
#       （如1代表绑定于对话框左下角，5代表绑定于对话框中心，9代表绑定于右上角）
#     ·当传入 -1~-9 之间的数字时，图片的显示原点将绑定于屏幕对应九宫格的位置
#       （如-1代表绑定于屏幕左下角，-5代表绑定于屏幕中心，-9代表绑定于屏幕右上角）
#     ·当传入 0 时，图片将显示在对话框内部（此时参数 z 代表窗口内视图中的z值）
#       （此时新增 x 与 y 参数，用于修改在对话框内部的坐标偏移值）
#
#     o → 图片的显示原点的类型（按九宫格）
#       （如传入5代表中心点为显示原点，传入7代表左上角为显示原点）
#
#    dx → x方向额外的偏移增量（水平向右为正方向）
#    dy → y方向额外的偏移增量（水平向下为正方向）
#     z → 图片的 z 值（当 do 不为0时，代表在屏幕上的z值）
#
#     x → 当 do 传入0时，代表在对话框内部的x坐标
#     y → 当 do 传入0时，代表在对话框内部的y坐标
#
#     w → 图片中，水平方向所含有的帧数
#     h → 图片中，竖直方向所含有的帧数
#       （与默认脸图类似，动态帧的读取方式为从左上角开始，先向右，再换行）
#     n → 图片中总共有的帧数
#     t → 每次间隔 t 帧切换到下一帧（若为 nil，则不自动切换）
#
#    id → 指定该图片的唯一标识符
#          在 Window_Message 中的脚本执行时，可用 pics(id) 获取该图片精灵
#          默认传入 图片名称字符串 或 PIC_SYM_TO_FILENAME 中的key
#
# 【示例】
#
#    \epic[1|do3o7]这是我要说的第一句话
#       → 将 bird_happy 图片的左上角显示在对话框的右下角
#
#==============================================================================
module MESSAGE_EX
  #--------------------------------------------------------------------------
  # ● 【设置】定义 图片代号 → 图片名称 的映射
  #  当绘制图片时（含对话框的\pic与当前插件的\epic），
  #  传入的文件名将首先在该常量中（转化为数字、字符串各进行一次）匹配，
  #  若失败，则将其作为文件名去目录下查找
  #--------------------------------------------------------------------------
  PIC_SYM_TO_FILENAME = {
    1 => "bird_happy",
  }
  #--------------------------------------------------------------------------
  # ● 【设置】定义\epic各参数的预设值
  #--------------------------------------------------------------------------
  EPIC_INIT_HASH = {
    :do => 0, # 显示位置类型
    :o => 7,  # 自身显示原点类型
    :dx => 0, # 坐标偏移值
    :dy => 0,
    :z => 100,
    # 嵌入时，指定在窗口内的坐标
    :x => 0,
    :y => 0,
    # 帧播放
    :w => 1,  # 横向cell数目
    :h => 1,  # 纵向cell数目
    :n => 1,  # 总帧数
    :t => 10, # 播放下一帧前的等待时间（若为nil则不切换）
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
end
#==============================================================================
# ○ Window_Message
#==============================================================================
class Window_Message
  #--------------------------------------------------------------------------
  # ● 初始化组件
  #--------------------------------------------------------------------------
  alias eagle_message_ex_epic_init_assets eagle_message_init_assets
  def eagle_message_init_assets
    eagle_message_ex_epic_init_assets
    @eagle_pics = {}
  end
  #--------------------------------------------------------------------------
  # ● 拷贝自身（扩展用处理）
  #--------------------------------------------------------------------------
  alias eagle_message_ex_epic_clone_ex clone_ex
  def clone_ex(t)
    t.eagle_pics = @eagle_pics
    t.eagle_pics.each { |k, s| s.bind_window(t) }
    eagle_message_ex_epic_clone_ex(t)
  end
  #--------------------------------------------------------------------------
  # ● 移出全部文字精灵
  #--------------------------------------------------------------------------
  alias eagle_message_ex_epics_sprites_move_out eagle_message_sprites_move_out
  def eagle_message_sprites_move_out
    @eagle_pics.each { |k, s| s.dispose }
    @eagle_pics.clear
    eagle_message_ex_epics_sprites_move_out
  end
  #--------------------------------------------------------------------------
  # ● 更新（在 @fiber 更新之后）
  #--------------------------------------------------------------------------
  alias eagle_message_ex_epic_update_after_fiber eagle_update_after_fiber
  def eagle_update_after_fiber
    eagle_message_ex_epic_update_after_fiber
    @eagle_pics.each { |k, s| s.update }
  end
  #--------------------------------------------------------------------------
  # ● 设置epic参数
  #--------------------------------------------------------------------------
  def eagle_text_control_epic(param = '0')
    return if !game_message.draw
    params = param.split('|') # [filename, param_str]
    _bitmap = Cache.picture( MESSAGE_EX.get_pic_file(params[0]) ) rescue return
    h = MESSAGE_EX::EPIC_INIT_HASH.dup
    parse_param(h, params[1], :id) if params[1]
    h[:id] ||= MESSAGE_EX.get_pic_sym(params[0])
    s = Sprite_EaglePic.new(self, h, _bitmap)
    @eagle_pics[h[:id]] = s
  end
  #--------------------------------------------------------------------------
  # ● 读取图片精灵
  #--------------------------------------------------------------------------
  def pics(id)
    @eagle_pics[id]
  end
end
#=============================================================================
# ○ 对话框拷贝
#=============================================================================
class Window_Message_Clone < Window_Message
  attr_accessor :eagle_pics
end
#==============================================================================
# ○ Sprite_EaglePic
#==============================================================================
class Sprite_EaglePic < Sprite
  attr_reader  :params
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(window_bind, ps, bitmap, viewport = nil)
    super(viewport)
    self.bitmap = bitmap
    bind_window(window_bind)
    reset(ps)
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    bind_window(nil)
    self.viewport = nil
    super
  end
  #--------------------------------------------------------------------------
  # ● 设置绑定的窗口
  #--------------------------------------------------------------------------
  def bind_window(window_bind)
    @window_bind = window_bind
  end
  #--------------------------------------------------------------------------
  # ● 重置
  #--------------------------------------------------------------------------
  def reset(ps)
    @params = ps
    reset_pattern
    reset_oxy
    # 设置初始显示位置
    reset_xy(params[:x], params[:y])
    # 设置后期移动而增加的位置
    @x_move = 0; @y_move = 0
    # 当嵌入对话框时
    #   (x0,y0) 当前文字显示区域的左上角的屏幕坐标
    @in_win_x0 = 0; @in_win_y0 = 0
    #   (_ox,_oy) 当前文字显示区域的显示原点位置（对话框内部坐标系）
    @in_win_ox = 0; @in_win_oy = 0
    # 控制参数
    @flag_move = nil
  end
  #--------------------------------------------------------------------------
  # ● 重置帧数据
  #--------------------------------------------------------------------------
  def reset_pattern
    params[:w_solo] = self.width / params[:w] # 单个cell的宽高
    params[:h_solo] = self.height / params[:h]
    params[:i] = 0 # 当前显示的帧序号
    params[:tc] = 0 # 等待时间计数
    apply_pattern
  end
  #--------------------------------------------------------------------------
  # ● 应用帧
  #--------------------------------------------------------------------------
  def apply_pattern
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
    apply_pattern
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
    @x_init = x
    @y_init = y
  end
  #--------------------------------------------------------------------------
  # ● 设置偏移位置（增量）
  #--------------------------------------------------------------------------
  def move(dx, dy)
    @x_move += dx if dx
    @y_move += dy if dy
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    update_pattern
    update_position
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
    self.x += (@x_move + params[:dx])
    self.y += (@y_move + params[:dy])
    self.z = params[:z]
  end
  #--------------------------------------------------------------------------
  # ● 更新位置：无绑定
  #--------------------------------------------------------------------------
  def update_position_base
    self.viewport = nil
    self.x = @x_init
    self.y = @y_init
  end
  #--------------------------------------------------------------------------
  # ● 更新位置：嵌入窗口
  #--------------------------------------------------------------------------
  def update_position_in_window
    self.x = @x_init
    self.y = @y_init
    if @window_bind
      self.viewport = @window_bind.eagle_chara_viewport
      @in_win_x0 = @window_bind.eagle_charas_x0
      @in_win_y0 = @window_bind.eagle_charas_y0
      if self.viewport
        @in_win_ox = @window_bind.eagle_charas_ox
        @in_win_oy = @window_bind.eagle_charas_oy
        self.x -= self.viewport.rect.x
        self.y -= self.viewport.rect.y
      end
    end
    self.x += (@in_win_x0 - @in_win_ox)
    self.y += (@in_win_y0 - @in_win_oy)
  end
  #--------------------------------------------------------------------------
  # ● 更新位置：绑定于窗口上
  #--------------------------------------------------------------------------
  def update_position_on_window
    self.viewport = nil
    if @window_bind
      reset_doxy(params[:do])
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新位置：绑定在屏幕上
  #--------------------------------------------------------------------------
  def update_position_on_screen
    self.viewport = nil
    reset_doxy(params[:do])
  end
  #--------------------------------------------------------------------------
  # ● 设置相对显示原点
  #--------------------------------------------------------------------------
  def reset_doxy(o)
    return if o == 0
    MESSAGE_EX.reset_xy_dorigin(self, @window_bind, o)
    reset_xy(self.x, self.y)
  end
  #--------------------------------------------------------------------------
  # ● 移出（外部调用）
  #--------------------------------------------------------------------------
  def move_out
    self.viewport = nil
    bind_window(nil)
  end
  #--------------------------------------------------------------------------
  # ● 自定义移动结束时调用，锁定当前位置
  #--------------------------------------------------------------------------
  def move_end
    reset_xy(self.x, self.y)
  end
end
