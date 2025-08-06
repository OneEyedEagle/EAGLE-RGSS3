#==============================================================================
# ■ 快捷功能场景 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【场景自由呼叫 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-EventToolbar"] = "2.0.0"
#==============================================================================
# - 2025.7.27.18 更改为使用【场景自由呼叫】，方便做场景跳转
#==============================================================================
# - 本插件新增了剧情演出时可供开启的快捷功能场景
#------------------------------------------------------------------------------
# 【使用】
#
#    在地图上时，按下 A 键即可开启快捷功能界面（注意此时地图将被暂停）
#
# 【兼容】
#
#    若使用了【事件指令跳过 by老鹰】，将加入 跳过剧情 的指令。
#    若使用了【对话框扩展 by老鹰】，将加入 自动剧情 的指令。
#    若使用了【对话日志 by老鹰】，将加入 对话日志 的指令，且嵌入功能场景。
#    若使用了【事件记录日志 by老鹰】，将加入 事件日志 的指令。
#    若使用了【快速存读档 by老鹰】，将加入 快速存档 与 快速读档 的指令。
#    若使用了【词条系统（文字版） by老鹰】，将加入 词条收集 的指令。
#    若使用了【任务列表 by老鹰】，将加入 任务列表 的指令。
#
#    注意：由于可用按键较少，可酌情关闭上述插件中的按键开启，只保留本插件中的调用。
#
# 【扩展】
#
#   ·若想在地图以外的场景中调用，可在对应场景的update中增加 TOOLBAR.update
#   ·若想加入新的指令，可参考 TOOLBAR::init_window_command 中的设置
#
#==============================================================================

module TOOLBAR
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def self.update
    if Input.trigger?(:X)
      @scene_cur = SceneManager.scene
      EAGLE.call_scene(Scene_ToolBar) 
    end
  end
  #--------------------------------------------------------------------------
  # ○【常量】指令框与屏幕左侧的距离（x坐标）
  #--------------------------------------------------------------------------
  WIN_COMMAND_X = 80
  #--------------------------------------------------------------------------
  # ○【常量】指令框宽度
  #--------------------------------------------------------------------------
  WIN_COMMAND_WIDTH = 140
  #--------------------------------------------------------------------------
  # ○【常量】指令框文字大小
  #--------------------------------------------------------------------------
  WIN_COMMAND_FONTSIZE = 18
  #--------------------------------------------------------------------------
  # ○【常量】指令框文字颜色
  #--------------------------------------------------------------------------
  WIN_COMMAND_FONT_COLOR = Color.new(255,255,255,255)
  #--------------------------------------------------------------------------
  # ○【常量】指令框的最大显示行数
  #--------------------------------------------------------------------------
  WIN_COMMAND_MAX = 8
  #--------------------------------------------------------------------------
  # ○【常量】帮助文本文字大小
  #--------------------------------------------------------------------------
  WIN_HELP_FONTSIZE = 14
  #--------------------------------------------------------------------------
  # ○【常量】提示文本的字体大小
  #--------------------------------------------------------------------------
  HINT_FONT_SIZE = 14

  #--------------------------------------------------------------------------
  # ● 初始化指令
  #--------------------------------------------------------------------------
  # 设置不需要退出当前界面的指令
  COMMANDS_NO_CLOSE = [:msg_auto, :msg_vi, :fast_save]
  # 设置需要呼叫其它场景的指令
  COMMANDS_CALL_SCENE = [:save, :title]

  def self.init_window_command(w)
    #w.add_command("名称", :唯一符号, 是否允许选择, "说明文本")
    #w.set_handler(:唯一符号, method(:command))

    if $imported["EAGLE-EventCommandSkip"]
      w.add_command(
        ">> 跳过剧情",
        :msg_skip,
        COMMAND_SKIP.skippable?,
        "跳过当前阶段的剧情，并显示关键要点"
      )
      w.set_handler(:msg_skip, COMMAND_SKIP.method(:call))
    end

    if $imported["EAGLE-MessageLog"]
      t = MSG_LOG.logs.size > 0 ? "查看对话记录" : "暂无对话记录"
      w.add_command(
        ">> 对话日志",
        :msg_log,
        true,
        t
      )
      w.set_handler(:msg_log, MSG_LOG.method(:call))
    end

    if $imported["EAGLE-EventLog"]
      w.add_command(
        ">> 事件日志",
        :event_log,
        true,
        "开启事件日志界面，查看已发生的大事件"
      )
      w.set_handler(:event_log, EVENT_LOG.method(:call))
    end

    if $imported["EAGLE-Dictionary"]
      w.add_command(
        ">> 词条收集",
        :dict,
        true,
        "开启词条收集界面，查看已解锁的词条"
      )
      w.set_handler(:dict, DICT.method(:start))
    end

    if $imported["EAGLE-QuestList"]
      w.add_command(
        ">> 任务列表",
        :quest,
        true,
        "开启任务列表界面，查看全部任务"
      )
      w.set_handler(:quest, QUEST.method(:start_list))
    end

    if $imported["EAGLE-FastSL"]
      w.add_command(
        ">> 快速存储",
        :fast_save,
        true,
        "快速存储于第\\v[#{$game_variables[FastSL::V_ID_FILE_INDEX]}]号档位"
      )
      w.set_handler(:fast_save, FastSL.method(:save))
      w.add_command(
        ">> 快速读取",
        :fast_load,
        true,
        "从第\\v[#{$game_variables[FastSL::V_ID_FILE_INDEX]}]号档位读取"
      )
      w.set_handler(:fast_load, FastSL.method(:load))
    end

    if $game_message.visible
      f_show = $game_message.visible && !$game_message.choice?
      scene = @scene_cur
      f = scene.message_window.visible rescue false
      t = f ? "隐藏" : "显示"
      w.add_command(
        ">> "+t+"对话框",
        :msg_vi,
        f_show,
        "切换对话框的显示/隐藏"
      )
      w.set_handler(:msg_vi, TOOLBAR.method(:toggle_msg_visible))
    end

    if $imported["EAGLE-MessageEX"]
      t = "已\\c[17]关闭\\c[0]自动对话"
      if v = $game_message.auto
        t = sprintf("在 \\c[17]%0.1f\\c[0]s 后自动继续对话", v * 1.0 / 60)
      end
      w.add_command(
        ">> 自动对话",
        :msg_auto,
        true,
        t
      )
      w.set_handler(:msg_auto, TOOLBAR.method(:toggle_msg_auto))
    end

    if $imported["EAGLE-CallScene"]
      w.add_command(
        ">> 存档",
        :save,
        true,
        "打开存档界面"
      )
      w.set_handler(:save, TOOLBAR.method(:call_scene_save))
    end
    
    w.add_command(">> 返回标题", :title, true, "回到标题")
    w.set_handler(:title, method(:call_title))
  end
  #--------------------------------------------------------------------------
  # ● 方法绑定-呼叫界面
  #--------------------------------------------------------------------------
  # 存档
  def self.call_scene_save
    EAGLE.call_scene(Scene_Save)
  end
  # 返回标题
  def self.call_title
    SceneManager.goto(Scene_Title)
  end
  #--------------------------------------------------------------------------
  # ● 方法绑定-切换对话框显隐
  #--------------------------------------------------------------------------
  def self.toggle_msg_visible
    return if $game_message.choice?
    scene = @scene_cur #SceneManager.scene
    msg = scene.message_window rescue return
    if $imported["EAGLE-MessageEX"]
      msg.visible ? msg.hide(true) : msg.show(true)
    else
      msg.visible ? msg.hide : msg.show
    end
  end
  #--------------------------------------------------------------------------
  # ● 方法绑定-切换对话框自动播放
  #--------------------------------------------------------------------------
  AUTO_MSG_T = [nil, 30, 60, 120]
  def self.toggle_msg_auto
    v = $game_message.auto
    i = AUTO_MSG_T.index(v)
    if i
      $game_message.auto = AUTO_MSG_T[(i + 1) % AUTO_MSG_T.size]
    else
      $game_message.auto = nil
    end
  end

  #--------------------------------------------------------------------------
  # ● 设置主窗口
  #--------------------------------------------------------------------------
  def self.set_window_toolbar(w)
    w.x = WIN_COMMAND_X
    w.y = Graphics.height / 2 - w.height / 2 - 20
  end
  #--------------------------------------------------------------------------
  # ● 设置背景精灵
  #--------------------------------------------------------------------------
  def self.set_sprite_bg(sprite)
    sprite.bitmap = Bitmap.new(Graphics.width, Graphics.height)
    sprite.bitmap.fill_rect(0, 0, sprite.width, sprite.height,
    Color.new(0,0,0,200))
  end
  #--------------------------------------------------------------------------
  # ● 设置标题精灵
  #--------------------------------------------------------------------------
  def self.set_sprite_info(sprite)
    sprite.zoom_x = sprite.zoom_y = 3.0
    sprite.bitmap = Bitmap.new(Graphics.height, Graphics.height)
    sprite.bitmap.font.size = 64
    sprite.bitmap.font.color = Color.new(255,255,255,10)
    sprite.bitmap.draw_text(0,0,sprite.width,64, "PAUSE", 0)
    sprite.angle = 0
    sprite.x = -16
    sprite.y = Graphics.height - 64 * 2.2
  end
  #--------------------------------------------------------------------------
  # ● 设置线条精灵（上侧）
  #--------------------------------------------------------------------------
  def self.set_sprite_up(sprite)
    sprite.bitmap = Bitmap.new(Graphics.width, 24)
    sprite.bitmap.font.size = HINT_FONT_SIZE
    sprite.bitmap.fill_rect(0, 20, sprite.width, 1,
      Color.new(255,255,255,120))
  end
  #--------------------------------------------------------------------------
  # ● 设置线条精灵（下侧）
  #--------------------------------------------------------------------------
  def self.set_sprite_down(sprite)
    sprite.bitmap = Bitmap.new(Graphics.width, 24)
    sprite.bitmap.font.size = HINT_FONT_SIZE
    sprite.bitmap.draw_text(0, 2, sprite.width, sprite.height,
      "上/下方向键 - 选择 | 确定键 - 执行 | 取消键 - 退出", 1)
    sprite.bitmap.fill_rect(0, 0, sprite.width, 1,
      Color.new(255,255,255,120))
    sprite.y = Graphics.height
  end
end

#===============================================================================
# ○ Scene_ToolBar
#===============================================================================
class Scene_ToolBar < Scene_Base
  include TOOLBAR
  #--------------------------------------------------------------------------
  # ● 开始
  #--------------------------------------------------------------------------
  def start 
    super
    @flag_call_scene = false
    @flag_no_close = false
    
    ui_init
    
    @window_toolbar.open
    @window_help.open
    ui_move_in(@window_toolbar) { @window_toolbar.update; @window_help.update }
    @window_toolbar.activate.select(0)
  end 
  #--------------------------------------------------------------------------
  # ● 结束
  #--------------------------------------------------------------------------
  def terminate 
    instance_variables.each do |varname|
      ivar = instance_variable_get(varname)
      if ivar.is_a?(Sprite)
        ivar.bitmap.dispose
        ivar.dispose
      end
    end
    super 
  end
  #--------------------------------------------------------------------------
  # ● UI-初始化
  #--------------------------------------------------------------------------
  def ui_init
    @sprite_bg = Sprite.new
    TOOLBAR.set_sprite_bg(@sprite_bg)
    @sprite_bg.opacity = 0
    @sprite_bg.z = 300
    @sprite_bg.z = 500 if $game_message.visible

    @sprite_bg_info = Sprite.new
    @sprite_bg_info.z = @sprite_bg.z + 10
    TOOLBAR.set_sprite_info(@sprite_bg_info)
    @sprite_bg_info.opacity = 0

    @window_toolbar = Window_Toolbar.new(0, 0)
    TOOLBAR.init_window_command(@window_toolbar)
    @window_toolbar.move(0, 0,
      @window_toolbar.window_width, @window_toolbar.window_height)
    @window_toolbar.refresh
    @window_toolbar.opacity = 0
    @window_toolbar.back_opacity = 0
    @window_toolbar.contents_opacity = 255
    @window_toolbar.z = @sprite_bg.z + 20
    TOOLBAR.set_window_toolbar(@window_toolbar)
    @window_toolbar.deactivate

    @window_help = Window_ToolbarHelp.new(1)
    @window_help.z = @sprite_bg.z + 20
    @window_help.opacity = 0
    @window_help.back_opacity = 0
    @window_help.contents_opacity = 255
    @window_help.openness = 0
    @window_toolbar.help_window = @window_help

    @sprite_hint_up = Sprite.new
    @sprite_hint_up.z = @sprite_bg.z + 30
    TOOLBAR.set_sprite_up(@sprite_hint_up)
    @sprite_hint_down = Sprite.new
    @sprite_hint_down.z = @sprite_bg.z + 30
    TOOLBAR.set_sprite_down(@sprite_hint_down)

    @flag_msg_log = false 
    if $imported["EAGLE-MessageLog"]
      @viewport_msg_log = Viewport.new(0,60,Graphics.width, Graphics.height-120)
      @viewport_msg_log.z = @sprite_bg.z + 30
    end
  end
  #--------------------------------------------------------------------------
  # ● UI-移入
  #--------------------------------------------------------------------------
  def ui_move_in(w)  # w 为居中显示的窗口
    params = {}
    params[@sprite_hint_down] = { :type => :y,
      :des => w.y + w.height }
    params[@sprite_hint_up] = { :type => :y,
      :des => w.y - 4 - @sprite_hint_up.height }
    ui_move(params) {
      yield if block_given?
      @sprite_bg.opacity += 15
      @sprite_bg_info.opacity += 15
    }
  end
  #--------------------------------------------------------------------------
  # ● UI-移出
  #--------------------------------------------------------------------------
  def ui_move_out
    params = {}
    params[@sprite_hint_down] = { :type => :y,
      :des => Graphics.height + @sprite_hint_down.height }
    params[@sprite_hint_up] = { :type => :y,
      :des => 0 - @sprite_hint_up.height }
    ui_move(params) {
      yield if block_given?
      @sprite_bg.opacity -= 15
      @sprite_bg_info.opacity -= 15
    }
  end
  #--------------------------------------------------------------------------
  # ● UI-控制三次立方移动
  #--------------------------------------------------------------------------
  def ui_move(params, t = 20)
    # params = { sprite => {:type =>, :des => } }
    params.each do |s, v|
      case v[:type]
      when :x; v[:init] = s.x; v[:dis] = v[:des] - s.x
      when :y; v[:init] = s.y; v[:dis] = v[:des] - s.y
      end
    end
    _i = 0; _t = t
    while(true)
      break if _i > _t
      per = _i * 1.0 / _t
      per = (_i == _t ? 1 : ease_value(per))
      _i += 1
      params.each do |s, v|
        case v[:type]
        when :x; s.x = v[:init] + v[:dis] * per
        when :y; s.y = v[:init] + v[:dis] * per
        end
      end
      yield
      update_basic
    end
  end
  #--------------------------------------------------------------------------
  # ● UI-缓动函数
  #--------------------------------------------------------------------------
  def ease_value(x)
    if $imported["EAGLE-EasingFunction"]
      return EasingFuction.call("easeOutExpo", x)
    end
    1 - 2**(-10 * x)
  end
  #--------------------------------------------------------------------------
  # ● 结束前处理
  #--------------------------------------------------------------------------
  def pre_terminate
    super
    return if @flag_call_scene
    @window_toolbar.close
    @window_help.close
    ui_move_out { @window_toolbar.update; @window_help.update }
    # 如果flag_ok还是 true，则需要处理下当前的指令
    @window_toolbar.eagle_toolbar_call_ok_handler if @window_toolbar.flag_ok
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
    return update_msg_log if @flag_msg_log
    process_ok if @window_toolbar.flag_ok 
    # 如果处理完了确定键的情况，flag_ok 还是 true，则触发取消
    process_cancel if @window_toolbar.flag_ok || input_key_cancel?
  end 
  #--------------------------------------------------------------------------
  # ● 处理按下取消键
  #--------------------------------------------------------------------------
  def process_cancel
    return_scene
  end 
  #--------------------------------------------------------------------------
  # ● 按下了取消键？
  #--------------------------------------------------------------------------
  def input_key_cancel?
    Input.trigger?(:B)
  end
  #--------------------------------------------------------------------------
  # ● 处理按下确定键
  #--------------------------------------------------------------------------
  def process_ok
    s = @window_toolbar.current_symbol
    # 一般指令需要ui移出后执行，
    # 呼叫场景的指令需要return_scene前执行，确保当前scene不为nil
    @flag_call_scene = TOOLBAR::COMMANDS_CALL_SCENE.include?(s)
    return process_call_scene if @flag_call_scene
    @flag_no_close = TOOLBAR::COMMANDS_NO_CLOSE.include?(s)
    return process_no_close if @flag_no_close
    return process_msg_log if $imported["EAGLE-MessageLog"] && s == :msg_log 
  end
  #--------------------------------------------------------------------------
  # ● 处理按下确定键：切换场景类的指令
  #--------------------------------------------------------------------------
  def process_call_scene
    @window_toolbar.flag_ok = false
    @window_toolbar.eagle_toolbar_call_ok_handler
    # 如果是直接跳转，则需要返回场景
    return_scene if SceneManager.eagle_scene == nil
  end
  #--------------------------------------------------------------------------
  # ● 处理按下确定键：不关闭窗口的指令
  #--------------------------------------------------------------------------
  def process_no_close 
    @window_toolbar.flag_ok = false
    @window_toolbar.eagle_toolbar_call_ok_handler
    @window_toolbar.clear_command_list_eagle
    TOOLBAR.init_window_command(@window_toolbar)
    @window_toolbar.refresh
    @window_toolbar.activate
  end
  #--------------------------------------------------------------------------
  # ● 处理按下确定键：对话日志的指令
  #--------------------------------------------------------------------------
  def process_msg_log
    @window_toolbar.flag_ok = false
    return @window_toolbar.activate if MSG_LOG.logs.size == 0
    @flag_msg_log = true
    @sprites_msg_log = []
    @log_index = -1
    @speed = 0; @d_speed_count = 0; @d_speed = 2
    update_msg_log_new
    
    @window_toolbar.close
    @window_help.close
    ui_move_in(@viewport_msg_log.rect) { 
      @window_toolbar.update
      @window_help.update
      @sprites_msg_log.each { |s| s.opacity += 15 }
    }
  end
  def update_msg_log
    # 更新按键后移动速度增加
    @speed -= 1 if Input.press?(:DOWN)
    @speed += 1 if Input.press?(:UP)
    # 更新上下移动边界
    s = @sprites_msg_log[0]
    if s.y - s.oy + @speed < MSG_LOG::UP_LIMIT_Y
      @speed = 0
      d = MSG_LOG::UP_LIMIT_Y - (s.y - s.oy)
      @sprites_msg_log.each { |s| s.move_xy(0, d) }
    end
    s = @sprites_msg_log[-1]
    if s.y - s.oy + @speed > MSG_LOG::DOWN_LIMIT_Y
      @speed = 0
      d = MSG_LOG::DOWN_LIMIT_Y - (s.y - s.oy)
      @sprites_msg_log.each { |s| s.move_xy(0, d) }
    end
    # 更新速度递减
    if @speed != 0 && (@d_speed_count += 1) > @d_speed
      @d_speed_count = 0
      @speed += (@speed > 0 ? -1 : 1)
    end
    # 更新移动
    @sprites_msg_log.each { |s| 
      s.move_xy(0, @speed)
      s.opacity += 15 if s.opacity < 255
    }
    # 如果最顶部的移动到中间，则绘制新的
    update_msg_log_new if @sprites_msg_log[-1].y > @viewport_msg_log.rect.height/2
    # 更新退出
    msg_log_to_scene if input_key_cancel?
  end
  def update_msg_log_new 
    i_start = @log_index + 1
    i_end = @log_index + MSG_LOG::LOG_READ_NUM
    i_end = MSG_LOG.logs.size - 1 if i_end >= MSG_LOG.logs.size
    while( i_start <= i_end )
      data = MSG_LOG.logs[i_start]
      s = new_sprite(data)
      @sprites_msg_log.push(s)
      MSG_LOG::WAIT_COUNT.times { update_basic }
      i_start += 1
    end
    @log_index = i_end
  end
  def new_sprite(data)
    s = MSG_LOG::Sprite_MsgLog.new(@viewport_msg_log)
    s.opacity = 0
    data.draw(s)
    if @sprites_msg_log[-1]
      s.set_xy(0, @sprites_msg_log[-1].y - @sprites_msg_log[-1].oy - s.height)
    else
      y0 = (@viewport_msg_log.rect.height - s.height) / 2 
      s.set_xy(0, y0)
    end
    s.set_xy(MSG_LOG::OFFSET_X, nil)
    s
  end
  def msg_log_to_scene
    @flag_msg_log = false
    @window_toolbar.open
    @window_help.open
    ui_move_in(@window_toolbar) { 
      @window_toolbar.update
      @window_help.update
      @sprites_msg_log.each { |s| s.opacity -= 25 }
    }
    @window_toolbar.activate
    @sprites_msg_log.each { |s| s.bitmap.dispose if s.bitmap; s.dispose }
    @sprites_msg_log.clear
  end
end

#===============================================================================
# ○ Window_Toolbar
#===============================================================================
class Window_Toolbar < Window_Command
  attr_accessor  :flag_ok
  #--------------------------------------------------------------------------
  # ● 清除指令列表
  #--------------------------------------------------------------------------
  def clear_command_list
    @list ||= []
  end
  def clear_command_list_eagle
    @list = []
  end
  #--------------------------------------------------------------------------
  # ● 生成指令列表
  #--------------------------------------------------------------------------
  def make_command_list
  end
  #--------------------------------------------------------------------------
  # ● 获取窗口的宽度
  #--------------------------------------------------------------------------
  def window_width
    col_max * (item_width + spacing) - spacing + standard_padding * 2
  end
  #--------------------------------------------------------------------------
  # ● 获取窗口的高度
  #--------------------------------------------------------------------------
  def window_height
    n = [@list.size, TOOLBAR::WIN_COMMAND_MAX].min
    fitting_height(n)
  end
  #--------------------------------------------------------------------------
  # ● 获取项目的宽度
  #--------------------------------------------------------------------------
  def item_width
    TOOLBAR::WIN_COMMAND_WIDTH
  end
  #--------------------------------------------------------------------------
  # ● 调用“确定”的处理方法
  #--------------------------------------------------------------------------
  alias eagle_toolbar_call_ok_handler call_ok_handler
  def call_ok_handler
    @flag_ok = true
  end
  #--------------------------------------------------------------------------
  # ● 绘制项目
  #--------------------------------------------------------------------------
  def draw_item(index)
    @draw_item_enable = command_enabled?(index)
    change_color(normal_color, @draw_item_enable)
    r = item_rect_for_text(index)
    draw_text_ex(r.x, r.y, command_name(index))
  end
  #--------------------------------------------------------------------------
  # ● 重置字体
  #--------------------------------------------------------------------------
  def reset_font_settings
    super
    contents.font.size = TOOLBAR::WIN_COMMAND_FONTSIZE
  end
  #--------------------------------------------------------------------------
  # ● 通常颜色
  #--------------------------------------------------------------------------
  def normal_color
    TOOLBAR::WIN_COMMAND_FONT_COLOR
  end
  #--------------------------------------------------------------------------
  # ● 更改内容绘制颜色
  #     enabled : 有效的标志。false 的时候使用半透明效果绘制
  #--------------------------------------------------------------------------
  def change_color(color, enabled = true)
    contents.font.color.set(color)
    contents.font.color.alpha = translucent_alpha unless enabled
    contents.font.color.alpha = translucent_alpha if !@draw_item_enable
  end
  #--------------------------------------------------------------------------
  # ● 更新帮助窗口
  #--------------------------------------------------------------------------
  def update_help
    @help_window.clear
    @help_window.set_text(current_ext)
    @help_window.x = self.x + self.width - 12
    @help_window.y = self.y + item_rect(index).y - self.oy
  end
end
#===============================================================================
# ○ Window_ToolbarHelp
#===============================================================================
class Window_ToolbarHelp < Window_Help
  #--------------------------------------------------------------------------
  # ● 重置字体
  #--------------------------------------------------------------------------
  def reset_font_settings
    super
    contents.font.size = TOOLBAR::WIN_HELP_FONTSIZE
  end
  #--------------------------------------------------------------------------
  # ● 通常颜色
  #--------------------------------------------------------------------------
  def normal_color
    TOOLBAR::WIN_COMMAND_FONT_COLOR
  end
  #--------------------------------------------------------------------------
  # ● 刷新
  #--------------------------------------------------------------------------
  def refresh
    contents.clear
    draw_text_ex(0, 0, @text) if @text
  end
end

#===============================================================================
# ○ Scene_Map
#===============================================================================
class Scene_Map < Scene_Base
  attr_reader :spriteset, :message_window
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  alias eagle_toolbar_update update
  def update
    eagle_toolbar_update
    TOOLBAR.update
  end
end
