#==============================================================================
# ■ 并行式对话 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【组件-通用方法汇总 by老鹰】与
#  【组件-位图绘制转义符文本 by老鹰】与【组件-位图绘制窗口皮肤 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-MessagePara2"] = "1.4.1"
#==============================================================================
# - 2026.3.22.10 新增<input>设置按键关闭
#==============================================================================

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# ● 什么是 并行式对话
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#
#  1. 在默认的系统中，所有事件共用一个全局的对话框（Window_Message）。
#     并行事件中如果有显示文本，则会因为其它事件在处理对话框而暂停执行。
#     此外，对话框开启时，也会阻止玩家移动，导致无法做一些不重要的对话。
#
#  2. 本插件引入了全新的绘制在单个精灵（Sprite）上的对话框：
#     对于单个事件页，该并行对话框关闭后，才会继续执行之后的事件指令；
#     对于不同事件，该并行对话框能同时显示多个，各个之间不会影响。
#
#  3. 为方便设置，对话框宽高将始终与文字宽高保持一致。
#

module MESSAGE_PARA2
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# ● 使用方式A：利用事件的显示文字
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#
#  - 在 事件指令-注释 中填写：
#
#         <并行对话> 
#
#    则之后的【显示文字】指令将使用本插件的并行对话框，不使用默认对话框。
#
#  ※ 启用并行对话的注释内容
COMMENT_PARA_ON  = "<并行对话>"

#
#  - 在 事件指令-注释 中填写：
#
#         <正常对话> 
#
#    则之后的【显示文字】将仍然使用默认对话框。
#
#  ※ 关闭并行对话的注释内容
COMMENT_PARA_OFF = "<正常对话>"

#------------------------------------------------
# 【说明】
#
#  1. 并行对话框为自动显示、自动隐藏，因此不响应玩家按键，也不阻碍玩家移动。
#
#  2. 如果玩家主动触发的事件中存在并行对话框，
#     仍需要等待并行对话结束、事件执行完毕，玩家才能继续移动。
#
#  3. 当位于地图时，并行对话框将绑定地图的视口Viewport，
#     即与行走图位于同一视口内，同样受到画面闪烁、屏幕抖动等特效影响。
#
#  4. 当重复激活并行对话框时，如果文本不变，则只会重置显示时间。
#

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# ● 在事件的显示文字中设置并行对话框
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#
#  - 在启用 <并行对话> 时，可以在【显示文字】中编写以下内容，
#    对当前并行对话框进行设置。
#
#------------------------------------------------
# 【预设】预先替换的文本
#
#  - 方便统一设置，对于同样的并行对话框，就不需要每个里面都写一长串设置了。
PRE_CONVERT = {}

# 示例：文本中的【角色头顶】会先被替换成后面的文本。
PRE_CONVERT["【角色头顶】"] = "<pos o=2 o2=8 e=0 fix=1><wait 120><no hangup>"

#------------------------------------------------
# 【设置a】脸图规格扩展
#
#  - 该扩展同【对话框扩展 by老鹰】中的处理。
#
#  - 当脸图文件名包含 _数字1x数字2 时（其中为字母x），
#    将定义该脸图文件的规格为 行数（数字1）x列数（数字2）。
#    若不写，则默认2行x4列。
#
#      如：ace_actor_1x1.png → 该脸图规格为 1×1，含有一张脸图，只有index为0时生效
#
#  - 该功能自动生效，只需要注意脸图文件的规格和对话框设置的脸图索引号。
#

#------------------------------------------------
# 【设置b】并行对话框的显示位置
#
#  - 在对话文本中编写：
#
#        <pos 标签对> 
#
#    设置该并行对话框的显示位置。
#
#  - 若未设置，则默认显示在屏幕左上角。
#
#  - “标签对” 中可编写以下内容：
#
#      o=数字 → 设置对话框的显示原点，依据九宫格位置进行划分。
#               如1代表对话框左下角，5代表中点为其显示原点。
#
#      wx=数字 wy=数字  → 设置对话框的屏幕坐标（第一优先级）。
#               如 wx=320 wy=240 代表显示到屏幕的 (320, 240) 处。
#
#      mx=数字 my=数字  → 设置对话框的地图坐标（第二优先级）。
#               如 mx=10 my=20 代表显示到地图的 (10, 20) 处（跟随地图移动）。
#
#      e=数字 → 设置要绑定的事件的id 。
#                 0  代表当前事件（若不存在，则取玩家）；
#               正数 代表当前地图上的指定事件；
#               负数 代表玩家队列中对应数据库ID的角色，
#                 如 e=-1 代表队伍中数据库ID为1号的角色，e=-2代表数据库2号的角色，
#                 若对应人物不在队伍中，则取队首角色。
#
#      o2=数字 → 将对话框显示在绑定对象的对应方位上，依据九宫格位置进行划分。
#                如 1 代表目标的左下角，5 代表目标的中心。
#                若设置了 wx 和 wy ，该参数无效。
#                若设置了 mx 和 my ，目标为 32x32 的地图格，o2=5 代表在格子中心。
#                若设置了 e ，目标为行走图，o2=8 代表在行走图顶部中点。
#
#      dx=数字 dy=数字 → 设置对话框坐标的最终偏移值。
#                        如 dy=-10 代表再往上移动10像素。
#
#      fix=数字 → 设置是否强制显示在屏幕内
#                 1 代表强制完整显示在屏幕内，默认 0 可以出屏幕。
#
#      z=数字 → 该对话框的z值。
#
#  - 示例：
#
#      <pos o=5 e=-1 o2=8> → 代表对话框中心会显示到玩家的头顶中心位置。
#
#  ※ 默认的Z值
INIT_Z = 200

#------------------------------------------------
# 【设置c】并行对话框的显示时间
#
#  - 在对话文本中编写：
#
#        <wait 数字> 
#
#    设置该并行对话框的显示时间。
#
#  - 该时间为对话框移入后、移出前的显示时间，不包括移入移出所需的时间。
#
#  - 如果设为 0，则不会自动移出，
#    此时请调用全局脚本 MESSAGE_PARA2.finish(id) 来手动移出该并行对话框，
#      其中的 id 为【设置h】中的唯一标识符（字符串）。
#
#  ※ 默认的显示时间（帧）
WAIT_BEFORE_OUT = 90

#------------------------------------------------
# 【设置d】并行对话框的按键继续
#
#  - 在对话文本中编写：
#
#        <input>
#
#    用于切换是否能按确定键关闭该并行对话框。
#
#  ※ 默认是否启用按键继续（若为 true ，则 <input> 为关闭该功能）
FLAG_INPUT = false

#------------------------------------------------
# 【设置e】并行对话框的关闭条件
#
#  - 在对话文本中编写：
#
#        <until>条件</until>
#
#    设置该并行对话框的关闭条件。
#
#  - 当 eval(条件) 返回 true 时，该并行对话框才会关闭。
#
#  ○ 注意：该设置将覆盖【设置c】【设置d】的效果。
#

#------------------------------------------------
# 【设置f】并行对话框的移入移出模式
#
#  - 在对话文本中编写：
#
#        <io 模式 可选参数>
#
#    设置该并行对话框的移入移出模式及所用时间。
#
#  - 其中 模式 可以替换为以下类型：
#
#       fade   →  淡入、淡出
#
#       zoom   →  放大移入、缩小移出
#
#  - 其中 可选参数 可以替换为以下键值对：
#
#       t=数字     # （所有模式）移入/移出的所用帧数
#
#       opa=数字   # （所有模式）每帧不透明度的变化量（移入时增加，移出时减少）
#                      （fade模式）默认值为 255 / t
#                      （zoom模式）默认值为 0
#
#       zin=数字   # （zoom模式）移入完成时的最终缩放比例（默认 1.0）
#
#       zout=数字  # （zoom模式）移出完成时的最终缩放比例（默认 0）
#
#  - 示例：
#
#       <io fade t=10>   →  淡入淡出分别需要10帧。
#
#       <io zoom>  →  使用放大移入和缩小移出。
#
#       <io zoom zin=2.0>  →  移入后将始终保持放大2倍状态。
#
#       <io zoom zin=2.0>  →  移入后将始终保持放大2倍状态。
#
#  ※ 默认启用的移入移出模式
#     "fade" 淡入淡出  "zoom" 缩放
DEF_IO_TYPE = "fade"
#  ※ 默认移入移出所需时间
DEF_IO_T = 20

#------------------------------------------------
# 【设置g】并行对话框的窗口皮肤
#
#  - 在对话文本中编写：
#
#        <skin id>
#
#    为当前并行对话框切换窗口皮肤。
#
#  - 其中 id 首先将在 ID_TO_SKIN 中查找预设的名称映射，
#    若不存在，则认定其为窗口皮肤的名称（位于Graphics/System目录下）。
#
#  - <skin0> 将切回默认皮肤。
#
#  ※ 预设窗口皮肤序号
ID_TO_SKIN = {}
ID_TO_SKIN[0] = "Window"  # 0号为默认窗口皮肤

#  ※ 默认所用的窗口皮肤
DEF_SKIN_ID = 0

#------------------------------------------------
# 【设置h】并行对话框不暂停事件执行
#
#  - 在对话文本中编写：
#
#        <no hangup>
#
#    设置当前并行对话框不会暂停当前事件的执行。
#

#------------------------------------------------
# 【设置i】并行对话框的唯一标识符
#
#  - 在对话文本中编写：
#
#        <id string>
#
#    来定义当前并行对话框的唯一标识符（字符串）。
#
#  - 对于有相同标识符的并行对话框，新对话将直接覆盖显示旧对话。
#
#  - 若不填写，则默认取当前事件的 ID（数字），
#    即默认状态下，同一事件在同一时刻只显示一个并行对话框。
#

#------------------------------------------------
# 【设置j】并行对话框的文字大小
#
#  - 在对话文本中编写：
#
#        <font 数字>
#
#    设置当前并行对话框的基础文字大小。
#
#  - 示例：
#
#      <font 16> → 设置字体大小为16，仅当前并行对话框生效。
#
#  ※ 默认文字大小
FONT_SIZE = 20
#  ※ 文本周围留出空白的宽度（用于绘制窗口边框）
TEXT_BORDER_WIDTH = 8

#------------------------------------------------
# 【设置k】并行对话框的重绘
#
#  - 在对话文本中编写：
#
#        <reset>
#
#    用于强制重绘制当前对话框。
#
#  - 当对话中仅包含转义符时，由于脚本中判定的是转义前的原始文本，
#    故哪怕 \v[id] 的对应变量的值发生变化，对话框也不会自动更新文本，
#    请手动增加 <reset> 来强制重绘整个并行对话框。
#

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# ● 使用方式B：利用全局脚本新增
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#
#  - 该并行对话框能够在任意时刻调用，此处对可使用的全局脚本进行说明。
#
#------------------------------------------------
# 【全局脚本a：生成并行对话框】
#
#  - 调用该全局脚本生成一个新的并行对话框：
#
#      MESSAGE_PARA2.add(sym, data)
#
#  - 其中 sym 为该并行对话框的唯一标识符，同【设置i】。
#
#    ○ 注意：为了保证地图事件的并行对话框正常执行，sym 请不要为数字。
#            推荐使用字符串类型，如 "测试名称" 。
#
#  - 其中 data 为并行对话框的设置（Hash类型）。
#
#    必须包括以下键值及数据：
#
#     :text => "文本内容"  # 绘制的文本内容，可含有转义符，不可含标签对
#
#    可以包括以下键值及数据：
#
#     :face_name  => "脸图名称"  # 需要绘制的脸图文件名称
#     :face_index => 0           # 需要绘制的脸图的索引号
#
#     :background => 0      # 对话框背景类型（0普通 1暗色 2透明 -1纯暗色）
#                             如果使用了【组件-形状绘制2】，则-1纯暗色将绘制圆角矩形。
#
#     :position => 0        # 对话框位置（0居上 1居中 2居下）
#
#     :skin => 0            # 对话框窗口皮肤的索引（数字）或 图片名称（字符串）
#
#     :wait => 1            # 对话框的时间
#
#     :io   => "fade"       # 对话框的移入移出模式（fade淡入淡出 zoom缩放）
#     :io_t => 20           # 移入移出的耗时
#
#     :map => true          # 在地图时，是否绑定在地图上（默认绑定）
#
#     :pos => { :o => 2, :e => -1, :o2 => 8  }
#                           # 对话框的位置设置，同【设置b】
#                           # 注意：此处设置 :e => 0 是无效的！
#
#     :font => 21           # 当前对话框的文字大小
#
#     :reset => true        # 是否强制重绘对话框内容
#
#  - 示例：
#
#     MESSAGE_PARA2.add("提示文字", {:text => "这是一句提示文本",
#         :pos => {:o => 5, :mx => 5, :my => 6 } })
#
#       → 在地图(5,6)处显示一个并行对话框，显示 这是一句提示文本。
#
#------------------------------------------------
# 【全局脚本b：检查指定并行对话框是否关闭】
#
#  - 调用该全局脚本对指定并行对话框进行检查，是否已经关闭：
#
#      MESSAGE_PARA2.finish?(sym)
#
#    返回 true，则表示已经完全关闭。
#
#------------------------------------------------
# 【全局脚本c：强制关闭指定并行对话框】
#
#  - 调用该全局脚本强制关闭指定并行对话框：
#
#      MESSAGE_PARA2.finish(sym)
#
#------------------------------------------------
# 【全局脚本d：获取指定并行对话框的精灵】
#
#  - 调用该全局脚本获取指定并行对话框的精灵Sprite：
#
#      MESSAGE_PARA2.msg(sym)
#

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# ● 高级：与【鹰式对话框扩展 AddOn并行对话】的比较
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#
#  - 两个插件均增加了能够全局使用的、自动显示隐藏的对话框，但有以下差异：
#
#  1. 本插件使用了精灵Sprite绘制对话框，而【AddOn并行对话】使用窗口Window。
#
#    → 本插件的并行对话框没有文字特效，文字和背景是在一张位图上的。
#
#    → 如果想使用【鹰式对话框扩展】中的转义符，必须使用【AddOn-并行对话】。
#
#  2. 本插件使用事件指令-显示文字，而【AddOn-并行对话】使用标签序列。
#
#    → 本插件用全局脚本创建并行对话框时，只能显示一个并行对话框，没有其他功能。
#
#    → 【AddOn并行对话】在序列中可设置多个对话文本逐个显示，以及其他扩展功能。
#
#  3. 为确保事件顺利执行完毕，本插件的并行对话框必须移出。
#
#    → 【AddOn并行对话】是独立于事件执行的，可以不移出对话框而始终显示。
#
#==============================================================================

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#                      - 设置结束，以下内容请不要修改！ -
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

  @sprites = {} # 事件ID => sprite
  def self.init; @sprites = {}; end

  # 生成精灵
  def self.new_sprite(d)
    Sprite_EagleMsg.new(nil, d)
  end

  # 新增一个并行对话精灵
  def self.add(eid, data)
    if @sprites[eid] == nil
      @sprites[eid] = new_sprite(data)
    else
      @sprites[eid].reset(data)
    end
    s = @sprites[eid]
    s.update
  end

  # 更新并行对话精灵
  def self.update
    @sprites.delete_if { |id, s| f = s.finish?; s.dispose if f; f }
    @sprites.each { |id, s| s.update }
  end

  # 获取指定对话框精灵
  def self.msg(eid)
    @sprites[eid] rescue nil
  end

  # 指定对话已结束？
  def self.finish?(eid)
    !@sprites.has_key?(eid)
  end

  # 强制结束指定对话
  def self.finish(eid)
    s = msg(eid)
    s.finish if s
  end

  # 获取窗口皮肤的名称
  def self.get_skin_name(sym)
    return ID_TO_SKIN[sym] if ID_TO_SKIN.has_key?(sym)
    return ID_TO_SKIN[sym.to_i] if ID_TO_SKIN.has_key?(sym.to_i)
    return sym
  end

  # 获取事件对象
  def self.get_event(id, id0=nil)
    if id == 0 # 当前事件
      if id0 and $game_map.events.include?(id0)
        return $game_map.events[id0]
      end
      return $game_player
    elsif id > 0 # 第id号事件
      chara = $game_map.events[id]
      chara ||= $game_map.events[id0] if id0
      return chara
    elsif id < 0 # 队伍中数据库id号角色（不存在则取队长）
      id = id.abs
      $game_player.followers.each do |f|
        return f if f.actor && f.actor.actor.id == id
      end
      return $game_player
    end
  end

  # 获取事件对象的精灵
  def self.get_event_sprite(obj)
    begin
      SceneManager.scene.spriteset.character_sprites.each do |s|
        return s if s.character == obj
      end
    rescue
    end
    return nil
  end

  # 执行脚本
  def self.eagle_eval(obj, str)
    msg = obj  # Sprite_EagleMsg
    s = $game_switches
    v = $game_variables
    e = $game_map.events
    pl = $game_player
    eval(str)
  end
end
class << DataManager
  alias eagle_message_para2_init init
  def init
    eagle_message_para2_init
    MESSAGE_PARA2.init  # 绑定初始化
  end
end
class Scene_Base
  alias eagle_message_para2_update_basic update_basic
  def update_basic
    eagle_message_para2_update_basic
    MESSAGE_PARA2.update  # 绑定更新
  end
end
# 方便绑定到事件精灵、战斗者精灵上
class Spriteset_Map; attr_reader :character_sprites, :viewport1; end
class Scene_Map; attr_reader :spriteset; end
class Spriteset_Battle; attr_reader :viewport1; end
class Scene_Battle; attr_reader :spriteset; end

#===============================================================================
# ○ 并行对话框的精灵
#===============================================================================
class Sprite_EagleMsg < Sprite
  include MESSAGE_PARA2
  attr_reader :params

  # 初始化
  def initialize(viewport, _params = {})
    super(viewport)
    reset(_params)
    @flag_no_wait = false
  end

  # 释放
  def dispose 
    self.bitmap.dispose if self.bitmap
    super 
  end

  # 重置
  def reset(_params)
    @flag_no_wait = false
    if @fiber # 已经存在
      if _params[:reset] == true or params[:show] == false
        # 如果强制更新，或已经结束显示，则正常重绘
      elsif _params[:text] == @params[:text]
        # 如果文本相同，则只重置倒计时
        @count_wait = @params[:wait]
        return
      end
    end
    @fiber = nil
    reset_params(_params)
    start
  end

  # 重置参数（确保参数存在）
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
    params[:input] = false if params[:input] == nil
    params[:until] = _params[:until] || ""
    params[:io] = _params[:io] || DEF_IO_TYPE
    params[:io_params] = _params[:io_params] || {}
    params[:io_t] = params[:io_params][:t] ? params[:io_params][:t].to_i : DEF_IO_T
    params[:font] = _params[:font] || FONT_SIZE
    
    params[:map] = _params[:map] != nil ? _params[:map] : true
    params[:pos] = _params[:pos] || nil
    params[:finish] = false
  end

  # 已结束？
  def finish?
    params[:finish] == true
  end

  # 重绘
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
      ps = { :font_size => params[:font], :x0 => 0, :y0 => 0, :lhd => 2 }
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
    when -1 # 纯暗色背景
      w = self.bitmap.width
      h = self.bitmap.height
      rect = Rect.new(0, 2, w, h - 4)
      if $imported["EAGLE-UtilsDrawing2"]
        # 如果使用了【组件-形状绘制2】，则改为圆角矩形
        self.bitmap.fill_rounded_rect(rect.x, rect.y, rect.width, rect.height, 4, back_color1)
      else
        self.bitmap.fill_rect(rect, back_color1)
      end
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
      ps = { :font_size => params[:font], :x0 => cont_x, :y0 => cont_y, :lhd => 2 }
      d = Process_DrawTextEX.new(params[:text], ps, self.bitmap)
      d.run(true)
    elsif params[:pic] != ""
      bitmap_pic = Cache.picture(params[:pic]) rescue Cache.empty_bitmap
      rect = Rect.new(0, 0, bitmap_pic.width, bitmap_pic.height)
      des_rect = Rect.new(cont_x, cont_y, params[:cont_w], params[:cont_h])
      self.bitmap.stretch_blt(des_rect, bitmap_pic, rect)
    end
  end

  # 获取暗色背景时的背景色
  def back_color1; Color.new(0, 0, 0, 160); end
  def back_color2; Color.new(0, 0, 0, 0); end

  #--------------------------------------------------------------------------
  # ● 开始
  #--------------------------------------------------------------------------
  def start
    redraw
    process_position
    @fiber = Fiber.new { fiber_main } if @fiber == nil
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

  # 处理位置
  def process_position
    self.z = INIT_Z
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
        h[:obj] = MESSAGE_PARA2.get_event(h[:e], params[:event_id]) rescue $game_player
        h[:o2] = 8 if h[:o2] <= 0 || h[:o2] > 9
        s = MESSAGE_PARA2.get_event_sprite(h[:obj])
        h[:obj_w] = s.width rescue 0
        h[:obj_h] = s.height rescue 0
      end
      h[:dx] = h[:dx].to_i
      h[:dy] = h[:dy].to_i
      h[:fix] = h[:fix].to_i || 0
      h[:z] = h[:z].to_i if h[:z]
      params[:pos_update] = h
    end
  end

  # 更新位置
  def update_position
    return if params[:pos_update].nil?
    h = params[:pos_update]
    r = Rect.new
    case h[:type]
    when :win   # 屏幕坐标
      r.set(h[:wx], h[:wy], 0, 0)
    when :map   # 地图格子的左上角
      _x = $game_map.adjust_x(h[:mx]) * 32
      _y = $game_map.adjust_y(h[:my]) * 32
      r.set(_x, _y, 32, 32)
    when :event # 事件的底部中心点
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
    self.z = h[:z] if h[:z]
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
    params[:show] = true
    process_wait
    params[:show] = false
    begin
      method("until_move_end_#{params[:io]}").call(:out, params[:io_t])
    rescue
      until_move_end_fade(:out)
    end
    params[:finish] = true
    @fiber = nil
  end

  # 重置视图
  def reset_viewport
    vp = nil
    if params[:map] == true and SceneManager.scene_is?(Scene_Map)
      vp = SceneManager.scene.spriteset.viewport1
    end
    self.viewport = vp
    self.opacity = 0 if self.opacity == 255
  end

  # 移入移出（淡入淡出）
  def until_move_end_fade(type = :in, t = 20)
    _opa = params[:io_params][:opa] ? params[:io_params][:opa].to_f : nil
    _opa = 255 / t if _opa == nil
    loop do
      Fiber.yield
      if type == :in
        self.opacity += _opa
        break if self.opacity >= 255
      elsif type == :out
        self.opacity -= _opa
        break if self.opacity <= 0
      end
    end
  end

  # 移入移出（缩放）
  def until_move_end_zoom(type = :in, t = 20)
    _opa = params[:io_params][:opa] ? params[:io_params][:opa].to_f : 0
    _i = 0; _t = t
    _init = 0; _d = 0
    _zin  = params[:io_params][:zin] ? params[:io_params][:zin].to_f : 1.0
    _zout = params[:io_params][:zout] ? params[:io_params][:zout].to_f : 0
    if type == :in
      _init = 0
      _d = _zin - _init
      self.opacity = 255 - _opa * t
    elsif type == :out
      _init = self.zoom_x
      _d = _zout - _init
    end
    while(true)
      break if _i > _t
      per = _i * 1.0 / _t
      per = (_i == _t ? 1 : ease_value(:zoom, per, type==:in))
      v = _init + _d * per
      self.zoom_x = self.zoom_y = v
      if type == :in
        self.opacity += _opa
      elsif type == :out
        self.opacity -= _opa
      end
      Fiber.yield
      _i += 1
    end
    if type == :in
      self.zoom_x = self.zoom_y = _zin
    elsif type == :out
      self.zoom_x = self.zoom_y = _zout
    end
  end
  def ease_value(type, x, flag=true)
    if $imported["EAGLE-EasingFunction"]
      return EasingFuction.call("easeOutBack", x) if flag
      return EasingFuction.call("easeInBack", x)
    end
    return 1 - 2**(-10 * x)
  end

  # 处理中途等待
  def process_wait
    return process_wait_until if params[:until] != ""
    process_wait_count
  end

  # 处理跳出等待
  def finish
    @flag_no_wait = true
  end

  # 处理等待帧数
  def process_wait_count
    if params[:wait] == 0
      loop do
        break if wait_input?
        break if @flag_no_wait
        Fiber.yield
      end
      return
    end
    @count_wait = params[:wait]
    loop do
      break if wait_input?
      break if @flag_no_wait
      Fiber.yield
      @count_wait -= 1
      break if @count_wait <= 0
    end
  end

  # 在等待时，是否按下按键
  def wait_input?
    if FLAG_INPUT == true
      return false if params[:input] == true
    else
      return false if params[:input] != true
    end
    return true if Input.trigger?(:C)
    if $imported["EAGLE-MouseEX"] 
      # 兼容【鼠标扩展 by老鹰】 鼠标点击并行对话框可关闭
      return true if mouse_in? && MOUSE_EX.up?(:ML)
    end
    return false
  end

  # 处理等待直至结束
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
  # 清除
  alias eagle_message_para2_clear clear
  def clear
    eagle_message_para2_clear
    @eagle_msg_block = false
  end

  # 添加注释
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

  # 显示文字
  alias eagle_message_para2_command_101 command_101
  def command_101
    if @eagle_msg_block
      call_message_para2_1
      return
    end
    eagle_message_para2_command_101
  end

  # 呼叫聊天对话
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
    #  ps = {}
    #  ps[:name] = params[:name] if !params[:name].empty?
      MSG_LOG.new_log(params[:text], ps) if params[:text] != ""
    end
  end

  # 从 显示文本 提取数据
  def call_message_para2_2(text, params)
    # 缩写
    s = $game_switches; v = $game_variables
    # 预替换
    MESSAGE_PARA2::PRE_CONVERT.each do |t1, t2|
      text.gsub!( /#{t1}/im) { t2 }
    end
    # 提取可能存在的flags
    text.gsub!( /<reset>/im ) { params[:reset] = true; "" }
    text.gsub!( /<font:? ?(.*?)>/im ) { params[:font] = $1.to_i; "" }
    text.gsub!( /<no hangup>/im) { params[:nohangup] = true; "" }
    text.gsub!( /<id:? ?(.*?)>/im ) { params[:id] = $1; "" }
    text.gsub!( /<skin:? ?(.*?)>/im ) { params[:skin] = $1; "" }
    text.gsub!( /<wait:? ?(.*?)>/im ) { params[:wait] = $1.to_i; "" }
    text.gsub!( /<until>(.*?)<\/until>/im ) { params[:until] = $1; "" }
    text.gsub!( /<input>/im ) { params[:input] = true; "" }
    text.gsub!( /<io:? *(\w+) ?(.*?)>/im ) {
      params[:io] = $1; params[:io_params] = EAGLE_COMMON.parse_tags($2); "" }
    # 设置位置 当前对话框的o处，与 w/m/e 的o处相重合
    text.gsub!( /<pos:? ?(.*?)>/im ) {
      # "o=? wx=? wy=? mx=? my=? e=? o2=? dx=? dy=? fix=? z=?"
      params[:pos] = EAGLE_COMMON.parse_tags($1)
      ""
    }
    # 提取位于开头的姓名
    #n = ""
    #text.sub!(/^【(.*?)】|^\[(.*?)\]/m) { n = $1 || $2; "" }
    #params[:name] = n
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

  # 等待并行对话结束
  def call_message_para2_3(params)
    eid = params[:id] || @event_id
    MESSAGE_PARA2.add(eid, params)
    return if params[:nohangup] == true
    Fiber.yield until MESSAGE_PARA2.finish?(eid)
  end
end
