#==============================================================================
# ■ 并行式对话 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【组件-通用方法汇总 by老鹰】与
#  【组件-位图绘制转义符文本 by老鹰】与【组件-位图绘制窗口皮肤 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-MessagePara2"] = "1.2.0"
#==============================================================================
# - 2022.8.14.9 放开 wait 参数传入 0 的限制
#==============================================================================
# - 本插件新增了自动显示并消除的对话模式，以替换默认的 事件指令-显示文字
#------------------------------------------------------------------------------
# 【介绍】
#
# - 在默认的系统中，由于所有事件共用了一个全局的对话框窗口（Window_Message），
#    当对话框开启时，并行事件（如果其中有显示文本）会因为对话框打开而暂停执行，
#    此外，对话框在开启时，势必会阻止玩家的移动，导致无法实现更灵活的对话。
#
# - 本插件引入了全新的绘制在精灵（Sprite）上的对话框：
#    对于单个事件页，该并行对话框关闭后，才会继续执行之后的事件指令；
#    对于不同事件，该并行对话框能同时显示多个，各个之间不会影响。
#
# - 为了方便设置，本插件的对话框自动调整为文字适配的宽高。
#
#------------------------------------------------------------------------------
# 【使用 - 事件的显示文字】
#
#  - 在 事件指令-注释 中填写 <并行对话> ，之后的【显示文字】指令将使用并行对话框；
#    而填写 <正常对话> ，之后的【显示文字】将仍然使用默认的对话框。
#
# - 关于【显示文字】：
#
#  1. 脸图规格扩展（同【对话框扩展 by老鹰】中的处理）
#
#      当脸图文件名包含 _数字1x数字2 时（其中为字母x），
#      将定义该脸图文件的规格为 行数（数字1）x列数（数字2）（默认2行x4列）
#
#      如：ace_actor_1x1.png → 该脸图规格为 1×1，含有一张脸图，只有index为0时生效
#
#      该功能自动生效，只需要注意脸图文件的规格和对话框设置的脸图索引号。
#
#  2. 在“文本框”中，编写 <pos 标签对> 用于设置对话框的显示位置
#     若没有设置，则默认显示在屏幕左上角
#
#     可用标签一览：
#
#      o=数字 → 设置对话框的显示原点
#               依据九宫格位置进行划分，如1代表对话框左下角，5代表中点为其显示原点
#
#      wx=数字 wy=数字 → 设置对话框原点的屏幕坐标（第一优先级）
#              如 wx=320 wy=240 代表显示到屏幕的 (320, 240) 处
#
#      mx=数字 my=数字 → 设置对话框原点的地图坐标（第二优先级）
#              如 mx=10 my=20 代表显示到地图的 (10, 20) 处（且跟随地图移动）
#
#      e=数字 → 设置要绑定的事件的id
#                0 代表当前事件（若不存在，则取玩家）
#               正数 代表当前地图上的指定事件
#               负数 代表玩家队列中对应数据库ID的角色
#                 如 e=-1 代表队伍中数据库ID为1号的角色，e=-2代表数据库2号的角色
#                 若对应人物不在队伍中，则取队首角色
#
#      o2=数字 → 设置所绑定对象的位置
#                依据九宫格位置进行划分，如1代表目标的左下角，5代表目标的中点
#                设置 wx 和 wy 时，该参数无效
#                设置 mx 和 my 时，地图坐标为 32x32 的小格，o2=5 代表在格子中心
#                设置 e 时，依据对应事件的行走图大小，o2=8 代表在行走图顶部中点
#
#      dx=数字 dy=数字 → 设置对话框坐标的最终偏移值
#              如 dy=-10 代表再往上移动10像素
#
#      fix=数字 → 设置是否强制显示在屏幕内
#                  传入 1 时代表强制该对话框完整显示在屏幕内，默认 0 可以出屏幕
#
#     如 <pos o=5 e=-1 o2=8> 代表对话框中心会显示到玩家的顶部中心
#
#  3. 在“文本框”中，编写 <wait 数字> 用于设置对话框的显示等待时间
#      该时间为对话框移入移出中间的显示等待时间，不包括移入移出的时间。
#      如果设为 0，则不会自动移出，需手动执行 MESSAGE_PARA2.finish(id) 移出，
#        其中 id 为第 8 点中设置的唯一标识符（字符串）
#
#  4. 在“文本框”中，编写 <until>条件</until> 用于设置对话框的等待条件
#      当 eval(条件) 返回 true 时，对话框才会关闭。
#      该设置将覆盖 <wait 数字> 的效果。
#
#  5. 在“文本框”中，编写 <io 模式 时间> 用于修改当前对话框的移入移出方式
#      模式 可以填入以下类型：
#         fade 代表淡入、淡出
#         zoom 代表放大移入、缩小移出
#      时间 为移入/移出的所用帧数
#     如 <io fade10> 代表淡入淡出分别需要10帧
#
#  6. 在“文本框”中，编写 <skin id> 用于为当前对话框切换窗口皮肤
#     其中 id 首先将在ID_TO_SKIN中查找预设的名称映射
#       若不存在，则认定其为窗口皮肤的名称（位于Graphics/System目录下）
#     如：<skin0> 将切换回默认皮肤
#
#  7. 在“文本框”中，填写 <no hangup> 用于不挂起当前事件的执行
#     即如果含有该字样，则事件会继续执行，而不会等待该对话框消失
#
#  8. 在“文本框”中，填写 <id string> 用于定义当前对话框的唯一标识符（字符串）
#     对于有相同标识符的对话，新显示的对话将直接覆盖旧的对话。
#     若不填写，则默认取当前事件的ID数字。
#
#---------------------------------------------------------------------------
# 【注意】
#
# - 并行对话为自动显示、自动隐藏，因此不会响应玩家的按键，也不会阻碍玩家移动
#
# - 如果玩家主动触发的事件中存在并行对话，仍然需要等待对话结束，玩家才能继续移动
#
# - 当位于地图/战斗时，并行式对话将自动绑定地图的视口
#    即与行走图位于同一 viewport 内，同样受到画面闪烁、抖动等特效影响
#
#------------------------------------------------------------------------------
# 【使用 - 全局脚本】
#
# - 为了能够在全局脚本中同样调用该对话框，此处对可使用的全局脚本进行说明。
#   调用该全局脚本生成一个新的并行对话框：
#
#     MESSAGE_PARA2.add(sym, data)
#
#   其中 sym 为唯一标识符，为了保证地图事件的正常执行，请不要使用数字类型
#       可以使用字符串类型，如 "测试名称"
#
#   其中 data 为对话框数据的Hash
#
#     必须包括以下键值及数据：
#
#      :text => "文本内容"    # 需要绘制的文本内容，可以含有转义符，不可含有标签对
#
#     可以包括以下键值及数据：
#
#      :face_name => "脸图名称"  # 需要绘制的脸图文件名称
#      :face_index => 0         # 需要绘制的脸图的索引号
#      :background => 0         # 对话框背景的类型（0普通 1暗色 2透明）
#      :position => 0           # 对话框位置的类型（0居上 1居中 2居下）
#
#      :skin => 0               # 对话框所用皮肤的索引
#      :wait => 1               # 对话框的停留帧数
#      :io   => "fade"          # 对话框的移入移出类型
#      :io_t => 20              # 移入移出的耗时
#
#      :pos => { :o => 2, :e => -1, :o2 => 8  } # 对话框的位置设置
#
#   如： MESSAGE_PARA2.add("提示文字", {:text => "这是一句提示文本",
#          :pos => {:o => 5, :mx => 5, :my => 6 }})
#   则会在地图的 (5,6) 处显示一个并行对话框，内容是 这是一句提示文本。
#
# - 同时，可以利用全局脚本对该对话框进行检查，看它是否已经关闭，
#   若返回 true，则已经完全关闭
#
#     MESSAGE_PARA2.finish?(sym)
#
#   当然，也有 MESSAGE_PARA2.finish(sym) 用于强制结束。
#
#------------------------------------------------------------------------------
# 【与对话框扩展的比较】
#
# - 在【对话框扩展 by老鹰】的【AddOn-并行对话】中，同样增加了并行对话功能，
#   此处针对本插件与它的相似于不同之处，进行阐述。
#
# - 相似：
#
#    两个插件均增加了能够全局使用的自动显示、隐藏的对话框。
#
# - 差异：
#
#   1. 本插件使用了精灵类进行对话框的绘制，而【AddOn-并行对话】继承了窗口类。
#      因此，本插件更加轻量化，不具有文字动态特效，绘制为一次性完成，
#      如果想使用【对话框扩展】中的转义符功能，必须使用【AddOn-并行对话】。
#
#   2. 本插件使用了事件指令来进行并行对话的编写，而【AddOn-并行对话】使用了标签序列。
#      因此，本插件调用全局脚本进行设置时，只能显示一个对话框，且没有其他功能，
#      但【AddOn-并行对话】可以执行序列，保证多个对话文本逐个显示，以及其他扩展功能。
#
#   3. 由于2中的设计，为了确保事件顺利继续执行，本插件不支持对话框永不移出，
#      而【AddOn-并行对话】是独立的解析与执行类，可以不移出对话框，并一直显示。
#      因此，本插件需要设置有效的对话框停留时间。
#
#==============================================================================

module MESSAGE_PARA2
  #--------------------------------------------------------------------------
  # ○【常量】事件指令-注释 中，启用并行对话的文字内容
  #--------------------------------------------------------------------------
  COMMENT_PARA_ON  = "<并行对话>"
  #--------------------------------------------------------------------------
  # ○【常量】事件指令-注释 中，关闭并行对话的文字内容
  #--------------------------------------------------------------------------
  COMMENT_PARA_OFF = "<正常对话>"

  #--------------------------------------------------------------------------
  # ○【常量】定义对话框的初始屏幕Z值
  #--------------------------------------------------------------------------
  INIT_Z = 200
  #--------------------------------------------------------------------------
  # ○【常量】定义对话框停留显示的帧数
  #--------------------------------------------------------------------------
  WAIT_BEFORE_OUT = 90
  #--------------------------------------------------------------------------
  # ○【常量】定义对话框移入移出的模式与所用时间
  # 可选模式： "fade" 代表淡入淡出，"zoom" 代表缩放
  #--------------------------------------------------------------------------
  DEF_IO_TYPE = "fade"
  DEF_IO_T = 20

  #--------------------------------------------------------------------------
  # ○【常量】定义对话文字的大小
  #--------------------------------------------------------------------------
  FONT_SIZE = 20
  #--------------------------------------------------------------------------
  # ○【常量】文本周围留出空白的宽度（用于绘制窗口的边框）
  #--------------------------------------------------------------------------
  TEXT_BORDER_WIDTH = 8

  #--------------------------------------------------------------------------
  # ○【常量】定义对话框皮肤
  #--------------------------------------------------------------------------
  ID_TO_SKIN = {}
  ID_TO_SKIN[0] = "Window"  # 0号为默认窗口皮肤
  #--------------------------------------------------------------------------
  # ○【常量】定义默认使用的对话框皮肤
  #--------------------------------------------------------------------------
  DEF_SKIN_ID = 0
  #--------------------------------------------------------------------------
  # ○【常量】定义预先进行一次替换的文本
  # 可以方便进行一些统一的设置，不需要每个对话框都写一串设置
  #--------------------------------------------------------------------------
  PRE_CONVERT = {}
  PRE_CONVERT["【角色头顶】"] = "<pos o=2 o2=8 e=0 fix=1><wait 120><no hangup>"

  #--------------------------------------------------------------------------
  # ● 新增一个并行对话精灵
  #--------------------------------------------------------------------------
  @sprites = {} # 事件ID => sprite
  def self.init
    @sprites = {}
  end
  #--------------------------------------------------------------------------
  # ● 新增一个并行对话精灵
  #--------------------------------------------------------------------------
  def self.add(eid, data)
    if @sprites[eid] == nil
      @sprites[eid] = new_sprite(data)
    else
      @sprites[eid].reset(data)
    end
    s = @sprites[eid]
    s.update
  end
  #--------------------------------------------------------------------------
  # ● 生成新的精灵
  #--------------------------------------------------------------------------
  def self.new_sprite(d)
    Sprite_EagleMsg.new(nil, d)
  end
  #--------------------------------------------------------------------------
  # ● 更新并行对话精灵
  #--------------------------------------------------------------------------
  def self.update
    @sprites.delete_if { |id, s| f = s.finish?; s.dispose if f; f }
    @sprites.each { |id, s| s.update }
  end
  #--------------------------------------------------------------------------
  # ● 指定对话已经结束？
  #--------------------------------------------------------------------------
  def self.finish?(eid)
    !@sprites.has_key?(eid)
  end
  #--------------------------------------------------------------------------
  # ● 强制结束指定对话
  #--------------------------------------------------------------------------
  def self.finish(eid)
    s = msg(eid)
    s.finish if s
  end
  #--------------------------------------------------------------------------
  # ● 获取指定对话框精灵
  #--------------------------------------------------------------------------
  def self.msg(eid)
    @sprites[eid] rescue nil
  end
end
#===============================================================================
# ○ DataManager
#===============================================================================
class << DataManager
  alias eagle_message_para2_init init
  def init
    eagle_message_para2_init
    MESSAGE_PARA2.init
  end
end
#===============================================================================
# ○ Scene_Base
#===============================================================================
class Scene_Base
  #--------------------------------------------------------------------------
  # ● 基础更新
  #--------------------------------------------------------------------------
  alias eagle_message_para2_update_basic update_basic
  def update_basic
    eagle_message_para2_update_basic
    MESSAGE_PARA2.update
  end
end
#=============================================================================
# ○ Scene_Map
#=============================================================================
class Spriteset_Map; attr_reader :character_sprites, :viewport1; end
class Scene_Map; attr_reader :spriteset; end
#=============================================================================
# ○ Scene_Battle
#=============================================================================
class Spriteset_Battle; attr_reader :viewport1; end
class Scene_Battle; attr_reader :spriteset; end

#===============================================================================
# ○ 通用
#===============================================================================
module MESSAGE_PARA2
  #--------------------------------------------------------------------------
  # ● 获取窗口皮肤名称
  #--------------------------------------------------------------------------
  def self.get_skin_name(sym)
    return ID_TO_SKIN[sym] if ID_TO_SKIN.has_key?(sym)
    return ID_TO_SKIN[sym.to_i] if ID_TO_SKIN.has_key?(sym.to_i)
    return sym
  end
  #--------------------------------------------------------------------------
  # ● 脚本执行
  #--------------------------------------------------------------------------
  def self.eagle_eval(obj, str)
    msg = obj  # Sprite_EagleMsg
    s = $game_switches
    v = $game_variables
    e = $game_map.events
    pl = $game_player
    eval(str)
  end
end

#===============================================================================
# ○ Sprite_EagleMsg
#===============================================================================
class Sprite_EagleMsg < Sprite
  include MESSAGE_PARA2
  attr_reader :params
  #--------------------------------------------------------------------------
  # ● 初始时
  #--------------------------------------------------------------------------
  def initialize(viewport, _params = {})
    super(viewport)
    self.z = INIT_Z
    reset(_params)
    @flag_no_wait = false
  end
  #--------------------------------------------------------------------------
  # ● 重置
  #--------------------------------------------------------------------------
  def reset(_params)
    reset_params(_params)
    redraw
    start
  end
  #--------------------------------------------------------------------------
  # ● 重置参数（确保部分参数存在）
  #--------------------------------------------------------------------------
  def reset_params(_params)
    @params = _params
    #params[:event_id]

    params[:text] = _params[:text] || ""
    params[:face_name] = _params[:face_name] || ""
    params[:face_index] = _params[:face_index] || 0
    params[:background] = _params[:background] || 0
    params[:position] = _params[:position] || 2

    params[:skin] = _params[:skin] || DEF_SKIN_ID
    params[:wait] = _params[:wait] || WAIT_BEFORE_OUT
    params[:wait] = 1 if params[:wait] < 0
    params[:until] = _params[:until] || ""
    params[:io] = _params[:io] || DEF_IO_TYPE
    params[:io_t] = _params[:io_t] || DEF_IO_T

    params[:pos] = _params[:pos] || nil
    params[:finish] = false
  end
  #--------------------------------------------------------------------------
  # ● 已经结束？
  #--------------------------------------------------------------------------
  def finish?
    params[:finish] == true
  end
  #--------------------------------------------------------------------------
  # ● 重绘
  #--------------------------------------------------------------------------
  def redraw
    # 脸图宽高
    params[:face_w] = 0
    params[:face_h] = 0
    if params[:face_name] != ""
      params[:face_w], params[:face_h] = EAGLE_COMMON.draw_face(self.bitmap,
        params[:face_name],params[:face_index], 0, 0, false)
    end

    # 内容宽高
    params[:cont_w] = 0
    params[:cont_h] = 0
    #  若绘制文本
    if params[:text] != ""
      ps = { :font_size => FONT_SIZE, :x0 => 0, :y0 => 0, :lhd => 2 }
      d = Process_DrawTextEX.new(params[:text], ps)
      d.run(false)
      params[:cont_w] = d.width
      params[:cont_h] = d.height
    end

    # 背景宽高
    params[:bg_w] = params[:face_w] + params[:cont_w] + TEXT_BORDER_WIDTH * 2
    params[:bg_h] = [params[:cont_h], params[:face_h]].max + TEXT_BORDER_WIDTH * 2

    # 实际位图宽高
    self.bitmap.dispose if self.bitmap
    w = params[:bg_w]
    h = params[:bg_h]
    self.bitmap = Bitmap.new(w, h)

    # 绘制背景
    params[:bg_x] = params[:bg_y] = 0
    case params[:background]
    when 0 # 普通背景
      skin = MESSAGE_PARA2.get_skin_name(params[:skin])
      EAGLE.draw_windowskin(skin, self.bitmap,
        Rect.new(params[:bg_x], params[:bg_y], params[:bg_w], params[:bg_h]))
    when 1 # 暗色背景
      w = self.bitmap.width
      h = self.bitmap.height
      rect1 = Rect.new(0, 0, w, 12)
      rect2 = Rect.new(0, 12, w, h - 24)
      rect3 = Rect.new(0, h - 12, w, 12)
      self.bitmap.gradient_fill_rect(rect1, back_color2, back_color1, true)
      self.bitmap.fill_rect(rect2, back_color1)
      self.bitmap.gradient_fill_rect(rect3, back_color1, back_color2, true)
    when 2 # 透明背景
    end

    # 绘制脸图
    if params[:face_name] != ""
      face_x = TEXT_BORDER_WIDTH
      face_y = TEXT_BORDER_WIDTH
      EAGLE_COMMON.draw_face(self.bitmap, params[:face_name],
        params[:face_index], face_x, face_y, true)
    end

    # 绘制内容
    cont_x = params[:bg_x] + params[:face_w] + TEXT_BORDER_WIDTH
    cont_y = params[:bg_y] + TEXT_BORDER_WIDTH
    if params[:text] != ""
      ps = { :font_size => FONT_SIZE, :x0 => cont_x, :y0 => cont_y, :lhd => 2 }
      d = Process_DrawTextEX.new(params[:text], ps, self.bitmap)
      d.run(true)
    elsif params[:pic] != ""
      bitmap_pic = Cache.picture(params[:pic]) rescue Cache.empty_bitmap
      rect = Rect.new(0, 0, bitmap_pic.width, bitmap_pic.height)
      des_rect = Rect.new(cont_x, cont_y, params[:cont_w], params[:cont_h])
      self.bitmap.stretch_blt(des_rect, bitmap_pic, rect)
    end
  end
  #--------------------------------------------------------------------------
  # ● 获取暗色背景时的背景色
  #--------------------------------------------------------------------------
  def back_color1; Color.new(0, 0, 0, 160); end
  def back_color2; Color.new(0, 0, 0, 0); end

  #--------------------------------------------------------------------------
  # ● 开始显示
  #--------------------------------------------------------------------------
  def start
    process_position
    @fiber = Fiber.new { fiber_main }
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    return params[:finish] = true if disposed?
    super
    update_position
    @fiber.resume if @fiber
  end
  #--------------------------------------------------------------------------
  # ● 处理位置参数
  #--------------------------------------------------------------------------
  def process_position
    if params[:pos]
      # "o=? wx=? wy=? mx=? my=? e=? o2=? dx=? dy=?"
      h = params[:pos].dup
      h[:o] = h[:o].to_i
      h[:o2] = h[:o2].to_i
      if h[:wx] || h[:wy]
        h[:type] = :win
        h[:o] = 7 if h[:o] <= 0 || h[:o] > 9
        h[:wx] = h[:wx].to_i
        h[:wy] = h[:wy].to_i
      elsif h[:mx] || h[:my]
        h[:type] = :map
        h[:o] = 7 if h[:o] <= 0 || h[:o] > 9
        h[:mx] = h[:mx].to_i
        h[:my] = h[:my].to_i
        h[:o2] = 5 if h[:o2] <= 0 || h[:o2] > 9
      elsif h[:e]
        h[:type] = :event
        h[:o] = 2 if h[:o] <= 0 || h[:o] > 9
        h[:e] = h[:e].to_i
        h[:obj] = get_event(h[:e]) rescue $game_player
        h[:o2] = 8 if h[:o2] <= 0 || h[:o2] > 9
        s = get_event_sprite(h[:obj])
        h[:obj_w] = s.width rescue 0
        h[:obj_h] = s.height rescue 0
      end
      h[:dx] = h[:dx].to_i
      h[:dy] = h[:dy].to_i
      h[:fix] = h[:fix].to_i || 0
      params[:pos_update] = h
    end
  end
  #--------------------------------------------------------------------------
  # ● 获取事件对象
  #--------------------------------------------------------------------------
  def get_event(id)
    if id == 0 # 当前事件
      return $game_map.events[params[:event_id]]
    elsif id > 0 # 第id号事件
      chara = $game_map.events[id]
      chara ||= $game_map.events[params[:event_id]]
      return chara
    elsif id < 0 # 队伍中数据库id号角色（不存在则取队长）
      id = id.abs
      $game_player.followers.each do |f|
        return f if f.actor && f.actor.actor.id == id
      end
      return $game_player
    end
  end
  #--------------------------------------------------------------------------
  # ● 获取事件对象对应的精灵
  #--------------------------------------------------------------------------
  def get_event_sprite(obj)
    begin
      SceneManager.scene.spriteset.character_sprites.each do |s|
        return s if s.character == obj
      end
    rescue
    end
    return nil
  end
  #--------------------------------------------------------------------------
  # ● 更新位置参数
  #--------------------------------------------------------------------------
  def update_position
    return if params[:pos_update].nil?
    h = params[:pos_update]
    r = Rect.new
    case h[:type]
    when :win
      # 屏幕坐标
      r.set(h[:wx], h[:wy], 0, 0)
    when :map
      # 地图格子的左上角
      _x = $game_map.adjust_x(h[:mx]) * 32
      _y = $game_map.adjust_y(h[:my]) * 32
      r.set(_x, _y, 32, 32)
    when :event
      # 事件的底部中心点坐标
      _x = h[:obj].screen_x - h[:obj_w] / 2
      _y = h[:obj].screen_y - h[:obj_h]
      # 修改为图像的左上角坐标
      r.set(_x, _y, h[:obj_w], h[:obj_h])
    end
    EAGLE_COMMON.reset_xy(self, h[:o], r, h[:o2])
    EAGLE_COMMON.reset_sprite_oxy(self, h[:o])
    if h[:fix] == 1 # 保证显示在屏幕内
      _x = self.x - self.ox
      _y = self.y - self.oy
      _x = [[_x, 0].max, Graphics.width - self.width].min
      _y = [[_y, 0].max, Graphics.height - self.height].min
      self.x = _x + self.ox
      self.y = _y + self.oy
    end
    self.x += h[:dx]
    self.y += h[:dy]
  end

  #--------------------------------------------------------------------------
  # ● 主线程
  #--------------------------------------------------------------------------
  def fiber_main
    reset_viewport
    begin
      method("until_move_end_#{params[:io]}").call(:in, params[:io_t])
    rescue
      until_move_end_fade(:in)
    end
    process_wait
    begin
      method("until_move_end_#{params[:io]}").call(:out, params[:io_t])
    rescue
      until_move_end_fade(:out)
    end
    params[:finish] = true
    @fiber = nil
  end
  #--------------------------------------------------------------------------
  # ● 重置视图
  #--------------------------------------------------------------------------
  def reset_viewport
    vp = nil
    if SceneManager.scene_is?(Scene_Map) || SceneManager.scene_is?(Scene_Battle)
      vp = SceneManager.scene.spriteset.viewport1
    end
    self.viewport = vp
    self.opacity = 0 if self.opacity == 255
  end

  #--------------------------------------------------------------------------
  # ● 移入移出（淡入淡出）
  #--------------------------------------------------------------------------
  def until_move_end_fade(type = :in, t = 20)
    v = 255 / t
    loop do
      Fiber.yield
      if type == :in
        self.opacity += v
        break if self.opacity >= 255
      elsif type == :out
        self.opacity -= v
        break if self.opacity <= 0
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 移入移出（放缩）
  #--------------------------------------------------------------------------
  def until_move_end_zoom(type = :in, t = 20)
    _i = 0; _t = t
    _init = 0; _d = 0
    if type == :in
      _init = 0
      _d = 1.0
    elsif type == :out
      _init = 1.0
      _d = -1.0
    end
    while(true)
      break if _i > _t
      per = _i * 1.0 / _t
      per = (_i == _t ? 1 : ease_value(:zoom, per))
      v = _init + _d * per
      self.zoom_x = self.zoom_y = v
      Fiber.yield
      _i += 1
    end
    if type == :in
      self.zoom_x = self.zoom_y = 1.0
    elsif type == :out
      self.zoom_x = self.zoom_y = 0
    end
  end
  #--------------------------------------------------------------------------
  # ● 缓动函数
  #--------------------------------------------------------------------------
  def ease_value(type, x)
    if $imported["EAGLE-EasingFunction"]
      return EasingFuction.call("easeOutBack", x)
    end
    return 1 - 2**(-10 * x)
  end

  #--------------------------------------------------------------------------
  # ● 处理中途等待
  #--------------------------------------------------------------------------
  def process_wait
    return process_wait_until if params[:until] != ""
    process_wait_count
  end
  #--------------------------------------------------------------------------
  # ● 处理跳出等待
  #--------------------------------------------------------------------------
  def finish
    @flag_no_wait = true
  end
  #--------------------------------------------------------------------------
  # ● 处理等待帧数
  #--------------------------------------------------------------------------
  def process_wait_count
    if params[:wait] == 0
      loop do
        break if @flag_no_wait
        Fiber.yield
      end
      return
    end
    params[:wait].times do
      break if @flag_no_wait
      Fiber.yield
    end
  end
  #--------------------------------------------------------------------------
  # ● 处理等待直至结束
  #--------------------------------------------------------------------------
  def process_wait_until
    loop do
      break if @flag_no_wait
      break if MESSAGE_PARA2.eagle_eval(self, params[:until]) == true
      Fiber.yield
    end
  end
end

#===============================================================================
# ○ Game_Interpreter
#===============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 清除
  #--------------------------------------------------------------------------
  alias eagle_message_para2_clear clear
  def clear
    eagle_message_para2_clear
    @eagle_msg_block = false
  end
  #--------------------------------------------------------------------------
  # ● 添加注释
  #--------------------------------------------------------------------------
  alias eagle_message_para2_command_108 command_108
  def command_108
    eagle_message_para2_command_108
    @comments.each do |t|
      if t.include?(MESSAGE_PARA2::COMMENT_PARA_OFF)
        break @eagle_msg_block = false
      end
      if t.include?(MESSAGE_PARA2::COMMENT_PARA_ON)
        break @eagle_msg_block = true
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 显示文字
  #--------------------------------------------------------------------------
  alias eagle_message_para2_command_101 command_101
  def command_101
    if @eagle_msg_block
      call_message_para2_1
      return
    end
    eagle_message_para2_command_101
  end
  #--------------------------------------------------------------------------
  # ● 呼叫聊天对话
  #--------------------------------------------------------------------------
  def call_message_para2_1
    params = {}
    params[:event_id] = @event_id
    params[:face_name] = @params[0]
    params[:face_index] = @params[1]
    params[:background] = @params[2]
    params[:position] = @params[3]

    ts = []
    while next_event_code == 401       # 文字数据
      @index += 1
      ts.push(@list[@index].parameters[0])
    end
    t = ts.inject("") {|r, text| r += text + "\n" }

    call_message_para2_2(t, params)

    if $imported["EAGLE-MessageLog"]
      ps = {}
      ps[:name] = params[:name] if !params[:name].empty?
      MSG_LOG.new_log(params[:text], ps) if params[:text] != ""
    end
  end
  #--------------------------------------------------------------------------
  # ● 从 显示文本 提取数据
  #--------------------------------------------------------------------------
  def call_message_para2_2(text, params)
    # 缩写
    s = $game_switches; v = $game_variables
    # 预替换
    MESSAGE_PARA2::PRE_CONVERT.each do |t1, t2|
      text.gsub!( /#{t1}/im) { t2 }
    end
    # 提取可能存在的flags
    text.gsub!( /<no hangup>/im) { params[:nohangup] = true; "" }
    text.gsub!( /<id:? ?(.*?)>/im ) { params[:id] = $1; "" }
    text.gsub!( /<skin:? ?(.*?)>/im ) { params[:skin] = $1; "" }
    text.gsub!( /<wait:? ?(.*?)>/im ) { params[:wait] = $1.to_i; "" }
    text.gsub!( /<until>(.*?)<\/until>/im ) { params[:until] = $1; "" }
    text.gsub!( /<io:? ?(.*?) ?(\d+)>/im ) {
      params[:io] = $1; params[:io_t] = $2.to_i; "" }
    # 设置位置 当前对话框的o处，与 w/m/e 的o处相重合
    text.gsub!( /<pos:? ?(.*?)>/im ) {
      # "o=? wx=? wy=? mx=? my=? e=? o2=? dx=? dy=? fix=?"
      params[:pos] = EAGLE_COMMON.parse_tags($1)
      ""
    }
    # 提取位于开头的姓名
    n = ""
    text.sub!(/^【(.*?)】|^\[(.*?)\]/m) { n = $1 || $2; "" }
    params[:name] = n
    # 提取可能存在的显示图片（将独立为新的对话框显示）
    text.gsub!(/<pic:? ?(.*?)>/im) {
      _params = params.dup
      _params[:pic] = $1
      call_message_para2_3(_params)
      ""
    }
    # 提取文本 删去前后的换行
    text.chomp!
    text.sub!(/^\n/) { "" }
    params[:text] = text
    call_message_para2_3(params) if text != ""
  end
  #--------------------------------------------------------------------------
  # ● 等待并行对话结束
  #--------------------------------------------------------------------------
  def call_message_para2_3(params)
    eid = params[:id] || @event_id
    MESSAGE_PARA2.add(eid, params)
    return if params[:nohangup] == true
    Fiber.yield until MESSAGE_PARA2.finish?(eid)
  end
end
