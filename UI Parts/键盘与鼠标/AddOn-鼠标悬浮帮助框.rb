#==============================================================================
# ■ Add-On 鼠标悬浮帮助框 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【鼠标扩展 by老鹰】之下
#    或 将 MOUSE_EX.x 和 MOUSE_EX.y 修改为使用你自己的鼠标坐标
# ※ 本插件需要放置在【组件-通用方法汇总 by老鹰】与
#  【组件-位图绘制转义符文本 by老鹰】与【组件-位图绘制窗口皮肤 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-MouseEXHelp"] = "1.0.2"
#=============================================================================
# - 2026.11.15.22 修复地图事件无法显示文本的bug
#=============================================================================
# - 本插件新增了全局显示在鼠标指针旁的帮助文本
#=============================================================================

module MOUSE_EX
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# ● 使用方式A：利用脚本直接显示文本
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#
#  - 在 脚本 中调用：
#
#       MOUSE_EX.show_help(text, params)
#
#    其中 text 为【必须设置】显示的文本，可以使用转义符。
#
#    其中 params 为以下参数组的 Hash ：
#
#      :bg => 0        # 对话框背景类型（0普通 1暗色 2透明 -1纯暗色）
#                        如果使用了【组件-形状绘制2】，则-1纯暗色将绘制圆角矩形。
#
#      :skin => 0      # 对话框窗口皮肤的索引（数字）或 图片名称（字符串）
#
#      :w => 数字      # 文字的最大宽度
#                        若未设置，则不会自动换行
#
#      :font => 数字   # 文字大小
#
#      :id => 数字或字符串  # 用来区分需要同时显示的不同文本
#
#      :pos => 如果固定摆放在屏幕上，而不跟随鼠标移动，请设置该Hash。
#
#          可以设置以下参数：
#
#          o=>数字  → 设置文本框的显示原点，依据九宫格位置进行划分。
#                     如1代表左下角，5代表中点为其显示原点。
#
#          wx=>数字 wy=>数字  → 设置文本框的屏幕坐标。
#                     如 wx=>320, wy=>240 代表显示到屏幕的 (320, 240) 处。
#
#          dx=>数字 dy=>数字  → 设置文本框坐标的最终偏移值。
#                     如 dy=-10 代表再往上移动10像素。
#
#          fix=>数字          → 设置是否强制显示在屏幕内。
#                     1 代表强制完整显示在屏幕内，默认 0 可以出屏幕。
#
#          z=>数字            → 设置该文本框的z值，默认9999。
#
#  - 示例：
#
#     MOUSE_EX.show_help("这是一句测试用的帮助。")
#         → 显示对应文本在鼠标指针旁
#
#  - 注意：
#
#    1. 需要每帧都调用该指令，否则会立刻自动隐藏。
#    2. 会实时跟随鼠标移动，并自动避免超出屏幕边界。
#

#  ※ 默认背景类型
# （未设置 :bg 时，使用该值）
DEF_BG = -1

#  ※ 默认文字大小
# （未设置 :font 时，使用该值）
FONT_SIZE = 20

#  ※ 默认所用的窗口皮肤
# （:bg => 0 时，若未设置 :skin ，使用该处的值）
DEF_SKIN_ID = 0
#  ※ 预设窗口皮肤
ID_TO_SKIN = {}
ID_TO_SKIN[0] = "Window"  # 0号为默认窗口皮肤

#  ※ 文本周围留出空白的宽度（用于绘制窗口边框）
TEXT_BORDER_WIDTH = 8

#  ※ 与鼠标指针的距离
DISTANCE_TO_POINTER_X = 12
DISTANCE_TO_POINTER_Y = 12

#  ※ 若未收到指令，将在该帧数后自动隐藏
TEXT_SHOW_TIME = 5

#  ※ 若未设置ID，默认使用该值
DEF_ID = "DEFAULT"

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# ● 使用方式B：脚本中给窗口/精灵预设显示的文本
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#
#   - 窗口或精灵调用以下方法：
#
#       window.set_mouse_help(text, rect=nil, params={})
#       sprite.set_mouse_help(text, rect=nil, params={})
#
#        → 鼠标停留在窗口/精灵的rect区域时，显示 text 的文本内容。
#           若 rect 为 nil ，则鼠标在窗口/精灵内对应位置时才会显示。
#
#        → params 同【使用方式A】中的 params 。
#
#        可以反复调用，对不同区域设置不同文本，先设置的会先判定。
#
#       window.delete_mouse_type
#       sprite.delete_mouse_type
#
#        → 删去预设的全部显示文本。
#

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# ● 使用方式C：给显示图片预设显示的文本
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#
#   - 利用全局脚本对 pic 号 地图/战斗 - 显示图片 预设：
#
#       MOUSE_EX.set_pic_help(pid, text, rect=nil) 
#
#        → 参数与【使用方式B】中一致。
#
#       MOUSE_EX.delete_pic_help(pid)  → 删除绑定的显示文本。
#

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# ● 使用方式D：给地图事件预设显示的文本
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#
#   - 在事件页开头新增 “添加注释”，并填写
#
#         <鼠标文本>文本内容</鼠标文本>
#
#     即可在鼠标停留于该事件上时，自动显示“文本内容”。
#
#  ※ 匹配用的正则表达式
REGEXP_MAP_CHARA_HELP = /<鼠标文本>(.*?)<\/鼠标文本>/i

#==============================================================================

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#                      - 设置结束，以下内容请不要修改！ -
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

  # 获取窗口皮肤的名称
  def self.get_skin_name(sym)
    return ID_TO_SKIN[sym] if ID_TO_SKIN.has_key?(sym)
    return ID_TO_SKIN[sym.to_i] if ID_TO_SKIN.has_key?(sym.to_i)
    return sym
  end

  # 设置显示文本
  def self.show_help(text, params={})
    params[:text] = text
    id = params[:id] || DEF_ID
    s = new_help(id)
    s.reset(params)
  end

  #--------------------------------------------------------------------------
  # ● 显示图片的绑定文本
  #--------------------------------------------------------------------------
  def self.set_pic_mouse(pid, text, rect=nil)
    s = SceneManager.scene.spriteset.get_pic_sprite(pid)
    return nil if s == nil
    if SceneManager.scene_is?(Scene_Map)
      pics = $game_map.screen.pictures
    elsif SceneManager.scene_is?(Scene_Battle)
      pics = $game_troop.screen.pictures
    else
      return 
    end
    pics[pid].set_mouse_help(text, rect)
    s.set_mouse_help(text, rect)
  end
  def self.delete_pic_mouse(pid, type=nil)
    s = SceneManager.scene.spriteset.get_pic_sprite(pid)
    return if s == nil
    if SceneManager.scene_is?(Scene_Map)
      pics = $game_map.screen.pictures
    elsif SceneManager.scene_is?(Scene_Battle)
      pics = $game_troop.screen.pictures
    else
      return 
    end
    pics[pid].set_mouse_help(type)
    s.delete_mouse_help(type)
  end

#===============================================================================
# ○ 显示文本的精灵
#===============================================================================
class Sprite_MouseText < Sprite
  attr_reader :id, :params, :pos
  # 初始化
  def initialize(id, viewport=nil)
    @id = id
    super(viewport)
    @params = {:show => 0, :pos => nil}
  end

  # 更新
  def update
    return if !visible?
    super
    update_position
    update_visible
  end

  #--------------------------------------------------------------------------
  # ● 设置显示文本
  #--------------------------------------------------------------------------
  def reset(_params)
    return hide if _params[:text] == nil or _params[:text] == ""
    if params[:text] != _params[:text]
      reset_params(_params)
      redraw
    end
    update_position
    show
  end

  # 重置参数（确保参数存在）
  def reset_params(_params)
    @params = _params

    params[:text] = _params[:text] || ""
    params[:background] = _params[:bg] || DEF_BG
    params[:skin] = _params[:skin] || DEF_SKIN_ID
    params[:font] = _params[:font] || FONT_SIZE
    params[:w]    = _params[:w] || nil
    params[:pos]  = _params[:pos] || nil
  end

  #--------------------------------------------------------------------------
  # ● 重绘
  #--------------------------------------------------------------------------
  def redraw
    # 内容宽高
    params[:cont_w] = 0
    params[:cont_h] = 0
    #  若绘制文本
    if params[:text] != ""
      ps = { :font_size => params[:font], :x0 => 0, :y0 => 0, :w => params[:w], :lhd => 2 }
      d = Process_DrawTextEX.new(params[:text], ps)
      d.run(false)
      params[:cont_w] = d.width
      params[:cont_h] = d.height
    end

    # 背景宽高
    params[:bg_w] = params[:cont_w] + TEXT_BORDER_WIDTH * 2
    params[:bg_h] = params[:cont_h] + TEXT_BORDER_WIDTH * 2

    # 实际位图宽高
    self.bitmap.dispose if self.bitmap
    w = params[:bg_w]
    h = params[:bg_h]
    self.bitmap = Bitmap.new(w, h)

    # 绘制背景
    params[:bg_x] = params[:bg_y] = 0
    case params[:background]
    when 0 # 普通背景
      skin = MOUSE_EX.get_skin_name(params[:skin])
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

    # 绘制内容
    cont_x = params[:bg_x] + TEXT_BORDER_WIDTH
    cont_y = params[:bg_y] + TEXT_BORDER_WIDTH
    if params[:text] != ""
      ps = { :font_size => params[:font], :x0 => cont_x, :y0 => cont_y, :w => params[:w], :lhd => 2 }
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
  # ● 更新位置
  #--------------------------------------------------------------------------
  def update_position
    return update_position_near_mouse if params[:pos] == nil
    return update_position_on_window  if params[:pos]
  end

  # 在鼠标指针旁边
  def update_position_near_mouse
    self.z = 9999
    self.ox = self.oy = 0
    self.x = MOUSE_EX.x + DISTANCE_TO_POINTER_X
    self.y = MOUSE_EX.y + DISTANCE_TO_POINTER_Y

    if self.x + self.width > Graphics.width
      self.ox = self.width
      self.x = MOUSE_EX.x - DISTANCE_TO_POINTER_X
    end
    if self.y + self.height > Graphics.height
      self.oy = self.height
      self.y = MOUSE_EX.y - DISTANCE_TO_POINTER_Y
    end
  end

  # 在屏幕上固定位置
  def update_position_on_window
    h = params[:pos]
    r = Rect.new
    r.set(h[:wx], h[:wy], 0, 0)
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
    self.z = 9999
    self.z = h[:z] if h[:z]
  end

  #--------------------------------------------------------------------------
  # ● 更新显示
  #--------------------------------------------------------------------------
  def update_visible
    return if params[:show] < 0
    params[:show] -= 1
    hide if params[:show] == 0
  end
  def show
    self.visible = true
    params[:show] = TEXT_SHOW_TIME
  end
  def hide
    self.visible = false
  end
  def visible?
    self.visible == true
  end
end

  #--------------------------------------------------------------------------
  # ● 初始化、更新精灵
  #--------------------------------------------------------------------------
  def self.init_help
    @mouse_help_sprites = {}
  end
  def self.new_help(id)
    return @mouse_help_sprites[id] if @mouse_help_sprites[id]
    s = Sprite_MouseText.new(id)
    @mouse_help_sprites[id] = s
    return s
  end
  def self.get_help(id)
    return @mouse_help_sprites[id]
  end
  def self.update_help
    @mouse_help_sprites.each { |id, s| s.update }
  end
  def self.delete_help(id)
    @mouse_help_sprites[id].dispose
    @mouse_help_sprites.delete(id)
  end
end # end of MOUSE_EX
#=============================================================================
# ** DataManager
#=============================================================================
class << DataManager
  # 初始化模块
  alias eagle_mouse_help_text_init init
  def init
    MOUSE_EX.init_help
    eagle_mouse_help_text_init
  end
end
#=============================================================================
# ** Scene_Base
#=============================================================================
class Scene_Base
  # 更新画面（基础）
  alias eagle_mouse_help_text_update_basic update_basic
  def update_basic
    eagle_mouse_help_text_update_basic
    MOUSE_EX.update_help
  end
end
#=============================================================================
# ** Scene_Map
#=============================================================================
class Scene_Map < Scene_Base
  attr_reader   :spriteset
end
#=============================================================================
# ** Scene_Battle
#=============================================================================
class Scene_Battle < Scene_Base
  attr_reader   :spriteset
end

#=============================================================================
# ** MOUSE_OBJECT
#=============================================================================
module MOUSE_OBJECT
  #--------------------------------------------------------------------------
  # ● 设置鼠标帮助文本
  #  rect 为 nil 时代表在窗口/精灵内时就生效
  #--------------------------------------------------------------------------
  def set_mouse_help(text, rect=nil, params={})
    @mouse_help ||= []
    @mouse_help.push([text, rect, params])
  end
  #--------------------------------------------------------------------------
  # ● 更新鼠标帮助文本
  #--------------------------------------------------------------------------
  def update_mouse_help_text
    return if self.is_a?(Sprite) and !self.mouse_in?(true, false)
    return if self.is_a?(Window) and !self.mouse_in?
    data = get_mouse_help(MOUSE_EX.x, MOUSE_EX.y)
    if data
      MOUSE_EX.show_help(data[0], data[2])
      return 
    end
  end
  #--------------------------------------------------------------------------
  # ● 获取鼠标帮助文本
  #--------------------------------------------------------------------------
  def get_mouse_help(mouse_x, mouse_y)
    @mouse_help ||= []
    return nil if @mouse_help.empty?
    rx = mouse_x - (self.x - self.ox)
    ry = mouse_y - (self.y - self.oy)
    if viewport
      rx = rx - self.viewport.rect.x + self.viewport.ox
      ry = ry - self.viewport.rect.y + self.viewport.oy
    end
    @mouse_help.each do |a|
      r = a[1]
      return a if r == nil
      next if rx < r.x || rx > r.x + r.width-1 
      next if ry < r.y || ry > r.y + r.height-1
      return a
    end
    return nil
  end
  #--------------------------------------------------------------------------
  # ● 清空设置的鼠标帮助文本
  #--------------------------------------------------------------------------
  def delete_mouse_help(type=nil)
    @mouse_help ||= []
    if type == nil
      @mouse_help.clear
    else
      @mouse_help.delete_if { |a| a[0] == type }
    end
  end
end
#=============================================================================
# ** Window
#=============================================================================
class Window
  include MOUSE_OBJECT
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  alias eagle_mouse_help_text_update update
  def update
    eagle_mouse_help_text_update
    update_mouse_help_text
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  alias eagle_mouse_help_text_dispose dispose
  def dispose
    delete_mouse_help
    eagle_mouse_help_text_dispose
  end
end
#=============================================================================
# ** Sprite
#=============================================================================
class Sprite
  include MOUSE_OBJECT
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  alias eagle_mouse_help_text_update update
  def update
    eagle_mouse_help_text_update
    update_mouse_help_text
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  alias eagle_mouse_help_text_dispose dispose
  def dispose
    delete_mouse_help
    eagle_mouse_help_text_dispose
  end
end

#===============================================================================
# ○ Game_Event
#===============================================================================
class Game_Event < Game_Character
  attr_accessor   :mouse_help, :mouse_help_last
  #--------------------------------------------------------------------------
  # ● 设置事件页的设置
  #--------------------------------------------------------------------------
  alias eagle_mouse_help_text_setup_page_settings setup_page_settings
  def setup_page_settings
    @mouse_help = nil
    eagle_mouse_help_text_setup_page_settings
    t = EAGLE_COMMON.event_comment_head(@list, true)
    t.scan(MOUSE_EX::REGEXP_MAP_CHARA_HELP).each do |ps|
      @mouse_help = ps[0]
      @mouse_help_last = nil
    end
  end
end
class Sprite_Character < Sprite_Base
  #--------------------------------------------------------------------------
  # ● 更新其它
  #--------------------------------------------------------------------------
  alias eagle_mouse_help_text_update_other update_other
  def update_other
    eagle_mouse_help_text_update_other
    if @character && @character.is_a?(Game_Event)
      if @character.mouse_help_last != @character.mouse_help
        @character.mouse_help_last = @character.mouse_help
        set_mouse_help(@character.mouse_help)
      end
    end
  end
end