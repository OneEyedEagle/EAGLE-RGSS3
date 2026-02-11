#==============================================================================
# ■ Add-On 自定义鼠标指针 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【鼠标扩展 by老鹰】之下
#    或 将 MOUSE_EX 模块中的方法修改为使用你自己的鼠标系统
# ※ 本插件部分功能需要 RGD(> 1.5.0) 才能正常使用
#==============================================================================
$imported ||= {}
$imported["EAGLE-MouseEXPointer"] = "1.0.1"
#=============================================================================
# - 2026.2.9.23
#=============================================================================
# - 本插件新增了对鼠标指针的自定义
#=============================================================================
# ○ 使用方法
#=============================================================================
#  
#  1. 在 POINTER_INFO 中设置好鼠标指针图像信息，并记住所设置的各个名称。
#
#  2. 对于一般情形下的鼠标指针：
#
#   - 通常情况下将使用 "默认" 名称的图像设置。
#
#   - 使用全局脚本 MOUSE_EX.set_pointer("名称") 修改为对应图像。
#     使用全局脚本 MOUSE_EX.restore_pointer 重置为 "默认" 的图像。
#     使用全局脚本 MOUSE_EX.lock_pointer 锁定鼠标指针（不自动切换，可用脚本修改）。
#     使用全局脚本 MOUSE_EX.unlock_pointer 解除鼠标指针的锁定。
#
#   - 使用事件脚本 set_mouse_pointer("名称") 修改为对应图像。
#     使用事件脚本 restore_mouse_pointer 重置为 "默认" 的图像。
#     使用事件脚本 lock_mouse_pointer 锁定鼠标指针（不自动切换，可用脚本修改）。
#     使用事件脚本 unlock_mouse_pointer 解除鼠标指针的锁定。
#
#  3. 对于鼠标停留在 地图事件 上时的鼠标指针：
#
#   - 在事件页开头新增 “添加注释”，并填写
#    【鼠标指针 名称】
#     即可在鼠标停留于该事件上时，修改为对应图像。
#
#  4. 对于鼠标停留在 窗口Window 和 精灵Sprite 上时的鼠标指针：
#
#   - 为窗口或精灵增加了以下方法：
#
#       window.set_mouse_type(name, rect=nil, method=nil)
#       sprite.set_mouse_type(name, rect=nil, method=nil)
#
#           → 鼠标停留在窗口/精灵的rect区域时，更改为 name 名称的图像。
#             若 rect 为 nil ，则鼠标在窗口/精灵内时即会更改。
#             可以反复调用，以对不同区域增加不同鼠标图像，先放入将会先判定。
#           → method 为传入的 method(:方法名称) 对象，鼠标点击左键时将调用该方法。
#
#       window.delete_mouse_type(name=nil)
#       sprite.delete_mouse_type(name=nil)
#
#           → 删去更改鼠标指针为 name 名称的全部区域判定。
#             若 name 为 nil ，则删去全部区域判定。
#
#  5. 对于鼠标停留在 地图/战斗 - 显示图片 上时的鼠标指针：
#
#   - 使用全局脚本 MOUSE_EX.set_pic_mouse(pid, name, rect=nil, method=nil) 
#       对 pic 号显示图片进行设置，
#     使用全局脚本 MOUSE_EX.delete_mouse_type(pid, name=nil) 进行删除。
#
#=============================================================================
# ○ 隐藏系统鼠标
#=============================================================================
if $RGD
  Mouse.visible = false
end
#=============================================================================
module MOUSE_EX
  #--------------------------------------------------------------------------
  # ●【常量】预设鼠标指针图像信息
  # 1. 图像文件放在 Graphics/System 目录下，为单帧图片）
  # 2. ox和oy代表图像中的哪个点作为鼠标实际位置，其中左上角为0,0，右下角为宽,高）
  # 3. 每行帧数 和 每行列数 决定了指针的帧动画的总帧数，将从左上按行逐个播放
  # 4. 隔多长时间切换 为指针的帧动画的播放间隔帧数，如果为 0 则不切换
  #--------------------------------------------------------------------------
  POINTER_INFO = {
  # "名称" => ["图像文件名", ox,oy, 每行帧数,每列帧数, 隔多长时间切换]
    # 初始的默认状态
    "默认"  => ["Cursor",    0,0,         1,   1,          0],
    
    "查看"  => ["Cursor_look", 16,16,     1,   1,          0],
    "调查"  => ["Cursor_navigate", 0,0,     1,   1,          0],
    "移动"  => ["Cursor_move", 0,0,       1,   1,          0],
    "问号"  => ["Cursor_question", 0,0,     1,   1,          0],
    
    "交谈"  => ["Cursor_talk", 16,32,     6,   1,         15],
    "拿取"  => ["Cursor_hand", 0,0,       2,   1,         20],
  }
  #--------------------------------------------------------------------------
  # ●【常量】检测指针因窗口、精灵等切换图像的间隔帧数，避免每帧检测而卡顿
  #--------------------------------------------------------------------------
  DETECTION_INTERVAL = 5
  #--------------------------------------------------------------------------
  # ●【常量】调试模式-输出鼠标指针样式切换的LOG
  #--------------------------------------------------------------------------
  DEBUG_MODE = false
  #--------------------------------------------------------------------------
  # ● 读取指定事件的当前页的首条注释里设置的鼠标指针样式
  #--------------------------------------------------------------------------
  def self.get_event_pointer(event)  # Game_Event
    t = EAGLE_COMMON.event_comment_head(event.list, true)
    t =~ /【鼠标指针 *(.*?)】/i
    if $1
      return $1
    else
      return nil
    end
  end
  #--------------------------------------------------------------------------
  # ● 未找到指针图像时，绘制默认箭头
  #--------------------------------------------------------------------------
  def self.draw_default_pointer(sprite)
    w = 32
    h = 32
    sprite.bitmap ||= Bitmap.new(w, h)
    sprite.bitmap.clear
    sprite.bitmap.fill_rect(0, 0, 2, h, Color.new(255, 255, 255))
    sprite.bitmap.fill_rect(0, 0, w, 2, Color.new(255, 255, 255))
    sprite.bitmap.fill_rect(0, 0, 10, 10, Color.new(255, 0, 0))
  end
  
#=============================================================================
# ** 全局方法
#=============================================================================
  #--------------------------------------------------------------------------
  # ● 获取鼠标指针精灵
  #--------------------------------------------------------------------------
  def self.get_mouse_sprite
    return SceneManager.scene.mouse_pointer
  end
  #--------------------------------------------------------------------------
  # ● 设置指针的默认状态
  #--------------------------------------------------------------------------
  def self.set_pointer(type)
    s = get_mouse_sprite
    s.set_state(type) if s
  end
  #--------------------------------------------------------------------------
  # ● 重置指针的默认状态
  #--------------------------------------------------------------------------
  def self.restore_pointer
    s = get_mouse_sprite
    s.restore_state if s
  end
  #--------------------------------------------------------------------------
  # ● 获取当前指针状态
  #--------------------------------------------------------------------------
  def self.get_pointer_state
    s = get_mouse_sprite
    return s.current_state if s
    return nil
  end
  #--------------------------------------------------------------------------
  # ● 锁定当前指针的状态（不再自动切换）
  #--------------------------------------------------------------------------
  def self.lock_pointer
    s = get_mouse_sprite
    s.lock_state if s 
  end
  #--------------------------------------------------------------------------
  # ● 解除锁定
  #--------------------------------------------------------------------------
  def self.unlock_pointer
    s = get_mouse_sprite
    s.unlock_state if s 
  end
  #--------------------------------------------------------------------------
  # ● 获取指定图片的精灵
  #--------------------------------------------------------------------------
  def self.set_pic_mouse(pid, type, rect=nil, method=nil)
    s = SceneManager.scene.spriteset.get_pic_sprite(pid)
    return nil if s == nil
    if SceneManager.scene_is?(Scene_Map)
      pics = $game_map.screen.pictures
    elsif SceneManager.scene_is?(Scene_Battle)
      pics = $game_troop.screen.pictures
    else
      return 
    end
    pics[pid].set_mouse_type(type, rect, method)
    s.set_mouse_type(type, rect, method)
  end
  #--------------------------------------------------------------------------
  # ● 获取指定图片的精灵
  #--------------------------------------------------------------------------
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
    pics[pid].delete_mouse_type(type)
    s.delete_mouse_type(type)
  end
end

#=============================================================================
# ** MOUSE_OBJECT
#=============================================================================
module MOUSE_OBJECT
  #--------------------------------------------------------------------------
  # ● 设置鼠标指针样式
  #  rect 为 nil 时代表在窗口/精灵内时就生效
  #--------------------------------------------------------------------------
  def set_mouse_type(type, rect=nil, method=nil)
    @mouse_type ||= []
    @mouse_type.push([type, rect, method])
    $game_temp.mouse_objects << self if !$game_temp.mouse_objects.include?(self)
  end
  #--------------------------------------------------------------------------
  # ● 获取鼠标指针样式
  #--------------------------------------------------------------------------
  def get_mouse_type(mouse_x, mouse_y)
    @mouse_type ||= []
    return nil if @mouse_type.empty?
    rx = mouse_x - (self.x - self.ox)
    ry = mouse_y - (self.y - self.oy)
    if viewport
      rx = rx - self.viewport.rect.x + self.viewport.ox
      ry = ry - self.viewport.rect.y + self.viewport.oy
    end
    @mouse_type.each do |a|
      r = a[1]
      return a if r == nil
      next if mouse_x < r.x || mouse_x > r.x + r.width-1 
      next if mouse_y < r.y || mouse_y > r.y + r.height-1
      return a
    end
    return nil
  end
  #--------------------------------------------------------------------------
  # ● 清空设置的鼠标指针样式
  #--------------------------------------------------------------------------
  def delete_mouse_type(type=nil)
    @mouse_type ||= []
    if type == nil
      @mouse_type.clear
    else
      @mouse_type.delete_if { |a| a[0] == type }
    end
    $game_temp.mouse_objects.delete(self) if @mouse_type.size == 0
  end
end
#=============================================================================
# ** Window
#=============================================================================
class Window
  include MOUSE_OBJECT
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  alias mouse_pointer_dispose dispose
  def dispose
    delete_mouse_type
    mouse_pointer_dispose
  end
end
#=============================================================================
# ** Sprite
#=============================================================================
class Sprite
  include MOUSE_OBJECT
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  alias mouse_pointer_dispose dispose
  def dispose
    delete_mouse_type
    mouse_pointer_dispose
  end
end
#=============================================================================
# ** Game_Temp
#=============================================================================
class Game_Temp
  attr_accessor :mouse_objects
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  alias mouse_pointer_initialize initialize
  def initialize
    mouse_pointer_initialize
    @mouse_objects = []
  end
end

#=============================================================================
# ** 鼠标指针精灵
#=============================================================================
class Sprite_MousePointer < Sprite
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(viewport = nil)
    super(viewport)
    @default_state_raw = "默认"
    @default_state = @default_state_raw
    @current_state = @default_state
    @current_obj = nil
    @current_method = nil
    @flag_lock = false
    @detection_counter = 0
    update_bitmap
    update_position
    self.z = 9999  # 确保鼠标在最上层
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    self.bitmap.dispose if self.bitmap
    super
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
    update_index
    update_position
    update_detection
    update_object if @current_obj
  end
  #--------------------------------------------------------------------------
  # ● 更新位图
  #--------------------------------------------------------------------------
  def update_bitmap
    data = MOUSE_EX::POINTER_INFO[@current_state]
    if data
      filename = data[0]
      path = "Graphics/System/#{filename}"
      if FileTest.exist?("#{path}.png")
        _bitmap = Cache.system(filename)
        self.ox = data[1]
        self.oy = data[2]
        @n_col = data[3]  # 列数
        @w_solo = _bitmap.rect.width / @n_col
        @n_line = data[4] # 行数 
        @h_solo = _bitmap.rect.height / @n_line
        @index_max = @n_col * @n_line
        @index = 0
        self.bitmap = _bitmap
        set_index(@index)
        @count_max = data[5] # 每N帧切换一次图像
        @count = @count_max
        return
      end
    end
    # 如果找不到图像，绘制一个默认的指针
    MOUSE_EX.draw_default_pointer(self)
  end
  #--------------------------------------------------------------------------
  # ● 更新帧动画
  #--------------------------------------------------------------------------
  def update_index
    return if @count_max <= 0
    @count += 1
    if @count >= @count_max
      @count = 0
      @index = (@index + 1) % @index_max
      set_index(@index)
    end
  end
  #--------------------------------------------------------------------------
  # ● 设置当前帧
  #--------------------------------------------------------------------------
  def set_index(index)
    sx = index % @n_col * @w_solo
    sy = index / @n_col * @h_solo
    self.src_rect.set(sx, sy, @w_solo, @h_solo)
  end
  #--------------------------------------------------------------------------
  # ● 更新位置
  #--------------------------------------------------------------------------
  def update_position
    return if !MOUSE_EX.in?
    self.x = MOUSE_EX.x
    self.y = MOUSE_EX.y
  end
  #--------------------------------------------------------------------------
  # ● 更新状态检测
  #--------------------------------------------------------------------------
  def update_detection
    return if @flag_lock  # 如果锁定，则不再检测
    @detection_counter += 1
    return if @detection_counter < MOUSE_EX::DETECTION_INTERVAL
    @detection_counter = 0
    detect_current_state
  end
  #--------------------------------------------------------------------------
  # ● 检测当前状态
  #--------------------------------------------------------------------------
  def detect_current_state
    old_state = @current_state
    new_state = determine_state
    if new_state != old_state
      @current_state = new_state
      update_bitmap
      log_state_change(old_state, new_state) if MOUSE_EX::DEBUG_MODE
    end
  end
  #--------------------------------------------------------------------------
  # ● 获取当前状态
  #--------------------------------------------------------------------------
  def determine_state
    # 检查鼠标下的窗口、精灵
    type = check_obj_under_mouse
    return type if type
    # 检查鼠标下的事件
    type = check_event_under_mouse
    return type if type
    # 默认状态
    @current_obj = nil
    @current_method = nil
    return @default_state
  end
  #--------------------------------------------------------------------------
  # ● 检查窗口、精灵
  #--------------------------------------------------------------------------
  def check_obj_under_mouse
    mouse_objects = $game_temp.mouse_objects
    return nil unless mouse_objects
    mouse_objects.sort_by! { |obj| 
      [obj.viewport ? -obj.viewport.z : 0, -obj.z]
    }
    mouse_objects.each do |obj|
      next if obj.is_a?(Sprite) and !obj.mouse_in?
      next if obj.is_a?(Window) and !obj.mouse_in?
      data = obj.get_mouse_type(self.x, self.y)
      if data
        @current_obj = obj
        @current_method = data[2]
        return data[0] 
      end
    end
    return nil
  end
  #--------------------------------------------------------------------------
  # ● 检查事件
  #--------------------------------------------------------------------------
  def check_event_under_mouse
    return nil unless SceneManager.scene_is?(Scene_Map)
    SceneManager.scene.spriteset.character_sprites.each do |s|
      character = s.character
      case character.class.name
      when "Game_Event"
        if s.mouse_in?(true, false)
          type = MOUSE_EX.get_event_pointer(character)
          if type
            @current_obj = s
            return type 
          end
        end
      when "Game_Vehicle"
      when "Game_Follower"
      when "Game_Player"
      end
    end
    return nil 
  end
  #--------------------------------------------------------------------------
  # ● 更新鼠标当前所选中的obj
  #--------------------------------------------------------------------------
  def update_object
    if @current_method
      @current_method.call if MOUSE_EX.up?(:ML)
    end
  end
  #--------------------------------------------------------------------------
  # ● 记录状态变化（调试用）
  #--------------------------------------------------------------------------
  def log_state_change(old_state, new_state)
    puts "Mouse pointer changed: #{old_state} -> #{new_state}"
    puts "Position: (#{self.x}, #{self.y})"
  end
  #--------------------------------------------------------------------------
  # ● 设置指针的默认状态
  #--------------------------------------------------------------------------
  def set_state(type)
    @default_state = type
    @current_state = @default_state
    update_bitmap
  end
  #--------------------------------------------------------------------------
  # ● 重置默认状态
  #--------------------------------------------------------------------------
  def restore_state
    set_state(@default_state_raw)
  end
  #--------------------------------------------------------------------------
  # ● 获取当前状态
  #--------------------------------------------------------------------------
  def current_state
    @current_state
  end
  #--------------------------------------------------------------------------
  # ● 锁定指针状态
  #--------------------------------------------------------------------------
  def lock_state
    @flag_lock = true
  end
  def unlock_state
    @flag_lock = false
  end
end

#=============================================================================
# ** Scene_Base
#=============================================================================
class Scene_Base
  attr_reader   :mouse_pointer
  #--------------------------------------------------------------------------
  # ● 开始
  #--------------------------------------------------------------------------
  alias mouse_pointer_start start
  def start
    mouse_pointer_start
    create_mouse_pointer
  end
  #--------------------------------------------------------------------------
  # ● 创建鼠标指针
  #--------------------------------------------------------------------------
  def create_mouse_pointer
    @mouse_pointer = Sprite_MousePointer.new
    $game_temp.mouse_objects.clear
  end
  #--------------------------------------------------------------------------
  # ● 更新鼠标指针
  #--------------------------------------------------------------------------
  alias mouse_pointer_update_basic update_basic
  def update_basic
    mouse_pointer_update_basic
    @mouse_pointer.update if @mouse_pointer
  end
  #--------------------------------------------------------------------------
  # ● 结束
  #--------------------------------------------------------------------------
  alias mouse_pointer_terminate terminate
  def terminate
    mouse_pointer_terminate
    dispose_mouse_pointer
  end
  #--------------------------------------------------------------------------
  # ● 释放鼠标指针
  #--------------------------------------------------------------------------
  def dispose_mouse_pointer
    @mouse_pointer.dispose if @mouse_pointer
  end
end

#=============================================================================
# ** Game_Event
#=============================================================================
class Game_Event < Game_Character
  attr_reader  :event
end

#=============================================================================
# ** 绑定显示图片
#=============================================================================
class Game_Picture
  attr_reader   :mouse_type 
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  alias mouse_pointer_initialize initialize
  def initialize(number)
    mouse_pointer_initialize(number)
    @mouse_type = []
  end
  #--------------------------------------------------------------------------
  # ● 设置鼠标指针样式
  #  rect 为 nil 时代表在窗口/精灵内时就生效
  #--------------------------------------------------------------------------
  def set_mouse_type(type, rect=nil, method=nil)
    @mouse_type.push([type, rect, method])
  end
  #--------------------------------------------------------------------------
  # ● 清空设置的鼠标指针样式
  #--------------------------------------------------------------------------
  def delete_mouse_type(type=nil)
    if type == nil
      @mouse_type.clear
    else
      @mouse_type.delete_if { |a| a[0] == type }
    end
  end
end
#=============================================================================
# ** Sprite_Picture
#=============================================================================
class Sprite_Picture < Sprite
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #     picture : Game_Picture
  #--------------------------------------------------------------------------
  alias mouse_pointer_initialize initialize
  def initialize(viewport, picture)
    mouse_pointer_initialize(viewport, picture)
    rebind_mouse_type
  end
  #--------------------------------------------------------------------------
  # ● 重新绑定鼠标指针样式
  #--------------------------------------------------------------------------
  def rebind_mouse_type
    @picture.mouse_type.each do |a|
      set_mouse_type(*a)
    end
  end
end
#=============================================================================
# ** Spriteset_Map
#=============================================================================
class Spriteset_Map
  attr_reader   :character_sprites
  #--------------------------------------------------------------------------
  # ● 获取指定ID的图片精灵
  #--------------------------------------------------------------------------
  def get_pic_sprite(pid)
    @picture_sprites[pid]
  end
end
#=============================================================================
# ** Spriteset_Battle
#=============================================================================
class Spriteset_Battle
  #--------------------------------------------------------------------------
  # ● 获取指定ID的图片精灵
  #--------------------------------------------------------------------------
  def get_pic_sprite(pid)
    @picture_sprites[pid]
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
# ** 游戏解释器扩展
#=============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 脚本命令：设置鼠标指针
  #--------------------------------------------------------------------------
  def set_mouse_pointer(type)
    MOUSE_EX.set_pointer(type)
  end
  #--------------------------------------------------------------------------
  # ● 脚本命令：恢复鼠标指针
  #--------------------------------------------------------------------------
  def restore_mouse_pointer
    MOUSE_EX.restore_pointer
  end
  #--------------------------------------------------------------------------
  # ● 脚本命令：锁定鼠标指针
  #--------------------------------------------------------------------------
  def lock_mouse_pointer
    MOUSE_EX.lock_pointer
  end
  #--------------------------------------------------------------------------
  # ● 脚本命令：解锁鼠标指针
  #--------------------------------------------------------------------------
  def unlock_mouse_pointer
    MOUSE_EX.unlock_pointer
  end
end
