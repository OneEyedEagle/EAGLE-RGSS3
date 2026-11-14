#==============================================================================
# ■ 搬动事件 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【组件-通用方法汇总 by老鹰】之下
# ※ 推荐与【按键扩展】【鼠标扩展】【自由显示光标】一起使用
#==============================================================================
$imported ||= {}
$imported["EAGLE-PickUpEvent"] = "1.1.1"
#==============================================================================
# - 2026.11.14.11 优化搬运表现，增加显示在玩家头顶的设置
#==============================================================================
# - 本插件新增了搬运事件的功能。
#=============================================================================

module PICKUP_EVENT
#-----------------------------------------------------------
# ○ 使用方式
#-----------------------------------------------------------
# 
# 1. 对于能够搬动的事件，需要在其事件页的开头增加一个 注释 指令，并在其中填入：
#
#       <可搬动>
#
#-----------------------------------------------
# 2.1 使用键盘开始搬动：
#
#     玩家面朝事件时，按下按键（如果使用了【按键扩展】，则为 TAB，否则为 SHIFT），
#       将搬起该事件，此时玩家能够继续移动。
#
# 2.2 使用鼠标开始搬动：（需使用【鼠标扩展 by老鹰】）
#
#     鼠标放到该事件的图像上，按鼠标右键，将搬起该事件。
#
#-----------------------------------------------
# 3.1 使用键盘放下事件：
#
#     按下同样按键，将尝试放下事件：
#
#       如果目标位置有其它事件、不可通行、位于地图外，
#       将放置失败，播放警告音，并继续搬动。
#
# 3.2 使用鼠标放下事件：
#
#     按鼠标右键将尝试放下事件：
#
#       如果放置失败，可以设置重置事件位置，也可以同键盘处理保持一致。
#
#-----------------------------------------------------------
# ○ 注意
#-----------------------------------------------------------
#
# 1. 在搬动事件的过程中，如果离开了地图界面（如打开菜单）、触发了其它事件内容，
#      将自动中断搬动，并重置事件位置。
#
# 2. 如果是用键盘开始搬动，则必须使用键盘放下事件，反之用鼠标同样。
#
# 3. 本插件已兼容【大体型事件 by老鹰】，方便设置占据多个格子的事件并搬动。
#
# 4. 建议与【自由显示光标 by老鹰】一同使用，将显示一个展示当前是否能放下的光标。

#【常量】在【自由显示光标】中使用的光标的ID
  CURSOR_ID = "搬动事件"

#【常量】在【自由显示光标】中使用的光标图像的文件名
  CURSOR_PIC = "Cursor_Pickup"
  
#-----------------------------------------------------------
# ○ 部分设置
#-----------------------------------------------------------
#
# 【常量】匹配注释的正则
#  （事件页开头的注释中，需要有这个文本，才能被搬动）
  COMMENT_PICKUP = /<可搬动>/mi
  
#-----------------------------------------------------------
# 【键盘相关】

# 键盘触发搬动的前置条件
#  （s 是 Sprite_Character ，e 是 Game_Event）
  def self.keyboard_cond?(s, e)
    event_in_front_of_player?(e) 
  end

# 键盘按键 - 搬起事件
#  （玩家正对事件时，按下该键开始搬动）
  def self.keyboard_pickup?
    if $imported["EAGLE-InputEX"]
      return INPUT_EX.up?(:TAB)
    end
    Input.trigger?(:A)
  end
  
# 键盘按键 - 放下事件
#  （搬动事件时，按下该键放下）
#  （如果没有空位，则会放置失败）
  def self.keyboard_drop?
    keyboard_pickup?  # 与搬起的按键一致
  end

# 键盘拿起事件时，被拿起的事件是在玩家头顶还是在玩家面前一格
#  true - 玩家头顶   false - 玩家面前一格
  FLAG_KEYBOARD_EVENT_POS = true

# 如果 FLAG_KEYBOARD_EVENT_POS 为 true ，键盘搬动事件时显示在玩家头顶，
#  则此处设置事件额外增加的 z 值，确保能显示在其它事件上方
  ON_HEAD_DZ = 100
  
#-----------------------------------------------------------
# 【鼠标相关】
#  （需要【鼠标扩展 by老鹰】，或者改成你自己的鼠标系统）

# 鼠标触发搬动的前置条件
#  （s 是 Sprite_Character ，e 是 Game_Event）
  def self.mouse_cond?(s, e)
    return false if !$imported["EAGLE-MouseEX"]
    s.mouse_in?(true, false)
  end
  
# 鼠标按键 - 搬起事件
  def self.mouse_pickup?
    MOUSE_EX.up?(:MR)
    #MOUSE_EX.press?(:ML, 5)
  end
  
# 鼠标按键 - 放下事件
  def self.mouse_drop?
    MOUSE_EX.up?(:MR)
    #!MOUSE_EX.press?(:ML, 5)
  end
  
# 如果鼠标放下事件失败，是否重置搬动，并把事件放回原位置
#  true - 自动放回原位置   false - 仅播放警告音效
  FLAG_RESET_MOUSE_FAIL = false
  
# 获取鼠标所在地图格子的RGSS坐标
  def self.mouse_map_xy
    return MOUSE_EX.map_x, MOUSE_EX.map_y
  end

#=============================================================================
  
  #--------------------------------------------------------------------------
  # ● 判定事件的拿起与放下
  #--------------------------------------------------------------------------
  def self.porcess_pickup_event(s, e)
    f = pickup_event?(e)
    if f == true 
      # 已经拿取了当前事件，移动位置
      _x, _y = destination_xy
      if @params[:last_x] != _x or @params[:last_y] != _y
        @params[:last_x] = _x
        @params[:last_y] = _y
        move_event_when_pickup(s, e)
        # 检查是否能放下
        f2 = drop_event?(_x, _y)
        @params[:last_drop_result] = f2
        update_help_text
      end
      drop_event(@params[:last_drop_result]) if drop_key?(s) 
    elsif f == false
      # 已经拿取了其它事件，返回
      return 
    elsif f == nil and @flag_process_drop == false
      # 还没有拿取任何事件，可以尝试拿取
      f3 = pickup_key?(s, e)
      if f3 > 0
        @params ||= {}
        @params[:key] = f3
        pickup_event(e)
      end
    end
  end
  
  #--------------------------------------------------------------------------
  # 判定当前事件是否已经拿起
  #   传入 nil 时代表是否有任意事件被拿起
  def self.pickup_event?(e=nil)
    return nil if @event == nil
    return true if e == nil and @event != nil
    @event == e
  end
  
  #--------------------------------------------------------------------------
  # 重置flag：放下事件
  #  在同一帧内，如果已经成功处理了放下事件，不能再同时处理拿起事件
  def self.reset_drop_flag
    @flag_process_drop = false
  end
  
  #--------------------------------------------------------------------------
  # 判定是否能放下事件
  def self.drop_event?(_x, _y)
    return false if !map_xy_empty?(_x, _y)
    if $imported["EAGLE-BigEvent"]
      @event.eagle_pos.each do |xy|
        _x2 = _x + xy[0]
        _y2 = _y + xy[1]
        return false if !map_xy_empty?(_x2, _y2)
      end
    end
    return true
  end
  
  # 地图上的指定位置可以放置？
  def self.map_xy_empty?(_x, _y)
    return false unless $game_map.valid?(_x, _y)
    return false if !$game_map.passable?(_x, _y, 2)
    return false if $game_map.events_xy_nt(_x, _y).any? { |e| 
      e != @event and e.normal_priority? }
    return true
  end
  
  #--------------------------------------------------------------------------
  # 获取事件的落位处
  def self.destination_xy
    case @params[:key]
    when 1 # 键盘按键
      return player_front_xy
    when 2 # 鼠标选择
      return mouse_map_xy
    end
  end
  
  # 获取玩家面前一格
  def self.player_front_xy
    x = $game_map.round_x_with_direction($game_player.real_x, $game_player.direction)
    y = $game_map.round_y_with_direction($game_player.real_y, $game_player.direction)
    return x, y
  end
  
  #--------------------------------------------------------------------------
  # 移动事件
  def self.move_event_when_pickup(s, e)
    case @params[:key]
    when 1 # 键盘按键
      if @params[:on_head] == true
        # 玩家头顶
        pl = $game_player
        e.moveto_pickup(pl.x, pl.y, pl.real_x, pl.real_y)
      else
        # 玩家面前
        e.moveto(@params[:last_x], @params[:last_y])
      end
    when 2 # 鼠标选择
      e.moveto(@params[:last_x], @params[:last_y])
    end
    s.update_position
  end
  
  # 每次移动位置后，显示是否能放置
  def self.update_help_text
    # @params[:last_drop_result] 存储了当前是否能放下
    f = @params[:last_drop_result]
    if @params[:key] == 1 and @params[:on_head] == true  # 事件显示在玩家头顶时
      if $imported["EAGLE-Cursor"]
        CURSOR.set_map_xy(PICKUP_EVENT::CURSOR_ID, @params[:last_x], @params[:last_y], 
          {:map=>true, :text=>f ? "可放置" : "空间不足",:d=>12,:ins=>true})
      end
      return
    end
    if $imported["EAGLE-Cursor"]
      CURSOR.set_map_chara(PICKUP_EVENT::CURSOR_ID, @event.id, {:map=>true,
        :text=>f ? "可放置" : "空间不足",:d=>12,:ins=>true})
    end
  end

  #--------------------------------------------------------------------------
  # 满足拿取的按键要求？
  def self.pickup_key?(s, e)
    return 1 if keyboard_cond?(s, e) and keyboard_pickup?
    return 2 if mouse_cond?(s, e)    and mouse_pickup?
    return 0
  end
  
  # 检查指定事件是否在玩家面前
  def self.event_in_front_of_player?(e)
    front_x, front_y = player_front_xy
    e.pos?(front_x, front_y)
  end

  #--------------------------------------------------------------------------
  # 满足放下的按键要求？
  def self.drop_key?(s)
    return true if @params[:key] == 1 and keyboard_drop?
    return true if @params[:key] == 2 and mouse_drop?
    return false
  end
  
  #--------------------------------------------------------------------------
  # ● 处理拿起事件
  #--------------------------------------------------------------------------
  def self.pickup_event(e)
    @event = e
    @params[:init_x] = e.x
    @params[:init_y] = e.y
    @params[:init_through] = @event.through
    @params[:last_x] = nil
    @params[:last_y] = nil
    @params[:last_drop_result] = false
    @event.through = true
    pickup_success
  end
  
  def self.pickup_success
    case @params[:key]
    when 1 # 键盘按键
      @params[:on_head] = PICKUP_EVENT::FLAG_KEYBOARD_EVENT_POS
      if @params[:on_head]
        @event.pickup_dy = -$game_player.sprite_height
        @event.pickup_dz = PICKUP_EVENT::ON_HEAD_DZ
      end
    when 2 # 鼠标选择
    end
    if $imported["EAGLE-Cursor"]
      CURSOR.new(PICKUP_EVENT::CURSOR_ID, {:pic=>PICKUP_EVENT::CURSOR_PIC})
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 处理放下事件
  #--------------------------------------------------------------------------
  def self.drop_event(success = true)
    success ? drop_success : drop_fail
  end
  
  def self.drop_success
    case @params[:key]
    when 1 # 键盘按键
      @event.moveto(@params[:last_x], @params[:last_y])
      @event.pickup_dy = 0
      @event.pickup_dz = 0
    when 2 # 鼠标选择
    end
    reset_params
    @flag_process_drop = true
  end
  
  def self.drop_fail
    case @params[:key]
    when 1 # 键盘按键
      Sound.play_buzzer
    when 2 # 鼠标选择
      if PICKUP_EVENT::FLAG_RESET_MOUSE_FAIL
        event_reset_position
        reset_params
      else
        Sound.play_buzzer
      end
    end
  end
  
  # 重置参数组
  def self.reset_params
    @params[:key] = 0
    @event.through = @params[:init_through]
    @event = nil
    CURSOR.delete(PICKUP_EVENT::CURSOR_ID) if $imported["EAGLE-Cursor"]
  end
  
  # 重置事件位置
  def self.event_reset_position
    _x = @params[:init_x]
    _y = @params[:init_y]
    @event.moveto(_x, _y)
  end
  
  # 强制放下
  def self.force_drop
    return if @event == nil
    event_reset_position
    reset_params
  end
end

class Game_Map
  #--------------------------------------------------------------------------
  # ● 更新画面
  #     main : 事件解释器更新的标志
  #--------------------------------------------------------------------------
  alias eagle_pickup_update update
  def update(main = false)
    PICKUP_EVENT.reset_drop_flag
    eagle_pickup_update(main)
  end
  #--------------------------------------------------------------------------
  # ● 检测／设置启动中的地图事件
  #--------------------------------------------------------------------------
  alias eagle_pickup_setup_starting_map_event setup_starting_map_event
  def setup_starting_map_event
    event = eagle_pickup_setup_starting_map_event
    PICKUP_EVENT.force_drop if event
    event
  end
end

class Game_CharacterBase
  attr_accessor :sprite_width, :sprite_height, :pickup_dx, :pickup_dy, :pickup_dz
  #--------------------------------------------------------------------------
  # ● 初始化公有成员变量
  #--------------------------------------------------------------------------
  alias eagle_pickup_cb_init_public_members init_public_members
  def init_public_members
    eagle_pickup_cb_init_public_members
    @sprite_width = 0
    @sprite_height = 0
    @pickup_dx = 0
    @pickup_dy = 0
    @pickup_dz = 0
  end
  #--------------------------------------------------------------------------
  # ● 移动到指定位置
  #--------------------------------------------------------------------------
  def moveto_pickup(x, y, real_x, real_y)
    @x = x % $game_map.width
    @y = y % $game_map.height
    @real_x = real_x
    @real_y = real_y
    @prelock_direction = 0
    straighten
    update_bush_depth
  end
end

class Game_Event < Game_Character
  attr_accessor :through, :flag_pickup
  #--------------------------------------------------------------------------
  # ● 初始化公有成员变量
  #--------------------------------------------------------------------------
  alias eagle_pickup_init_public_members init_public_members
  def init_public_members
    eagle_pickup_init_public_members
    @flag_pickup = false
  end
  #--------------------------------------------------------------------------
  # ● 设置事件页的设置
  #--------------------------------------------------------------------------
  alias eagle_pickup_setup_page_settings setup_page_settings
  def setup_page_settings
    eagle_pickup_setup_page_settings
    t = EAGLE_COMMON.event_comment_head(@list)
    @flag_pickup = true if t =~ PICKUP_EVENT::COMMENT_PICKUP
  end
  #--------------------------------------------------------------------------
  # ● 能够更新搬动？
  #--------------------------------------------------------------------------
  def update_pickup?
    !@erased and @flag_pickup
  end
end

class Sprite_Character < Sprite_Base
  attr_reader  :character
  #--------------------------------------------------------------------------
  # ● 设置角色的位图
  #--------------------------------------------------------------------------
  alias eagle_pickup_set_character_bitmap set_character_bitmap
  def set_character_bitmap
    eagle_pickup_set_character_bitmap
    @character.sprite_width  = @cw
    @character.sprite_height = @ch
  end
  #--------------------------------------------------------------------------
  # ● 更新位置
  #--------------------------------------------------------------------------
  alias eagle_pickup_update_position update_position
  def update_position
    eagle_pickup_update_position
    self.x += @character.pickup_dx
    self.y += @character.pickup_dy
    self.z += @character.pickup_dz
  end
  #--------------------------------------------------------------------------
  # ● 更新其它
  #--------------------------------------------------------------------------
  alias eagle_pickup_update_other update_other
  def update_other
    eagle_pickup_update_other
    return if $game_map.interpreter.running?
    if @character && @character.is_a?(Game_Event) && @character.update_pickup?
      update_pickup
    end
  end
  def update_pickup
    PICKUP_EVENT.porcess_pickup_event(self, @character)
  end
end

class Scene_Map < Scene_Base
  #--------------------------------------------------------------------------
  # ● 结束前处理
  #--------------------------------------------------------------------------
  alias eagle_pickup_pre_terminate pre_terminate
  def pre_terminate
    PICKUP_EVENT.force_drop
    eagle_pickup_pre_terminate
  end
end
