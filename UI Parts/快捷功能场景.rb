#==============================================================================
# ■ 快捷功能场景 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【场景自由呼叫 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-EventToolbar"] = "2.1.1"
#==============================================================================
# - 2025.11.8.9 新增词条系统的嵌入 
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
#    若使用了【词条系统（文字版） by老鹰】，将加入 词条收集 的指令，且嵌入功能场景。
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
  # ○【常量】帮助文本的文字大小
  #--------------------------------------------------------------------------
  WIN_HELP_FONTSIZE = 14
  #--------------------------------------------------------------------------
  # ○【常量】底部按键提示文本的字体大小
  #--------------------------------------------------------------------------
  HINT_FONT_SIZE = 14
  #--------------------------------------------------------------------------
  # ○【常量】底部按键提示文本-主界面
  #--------------------------------------------------------------------------
  HINT_TEXT_DEFAULT = "上/下方向键 - 选择 | 确定键 - 执行 | 取消键 - 退出"
  #--------------------------------------------------------------------------
  # ○【常量】（若使用了【对话日志】by老鹰）底部按键提示文本-对话日志
  #--------------------------------------------------------------------------
  HINT_TEXT_MSGLOG = "上/下方向键 - 移动 | 取消键 - 退出"
  #--------------------------------------------------------------------------
  # ○【常量】（若使用了【词条系统（文字版）】by老鹰）底部按键提示文本-词条系统
  #--------------------------------------------------------------------------
  HINT_TEXT_DICT = "上/下方向键 - 切换词条 | 左/右方向键 - 切换类别 | 取消键 - 退出"

  #--------------------------------------------------------------------------
  # ● 初始化指令
  #--------------------------------------------------------------------------
  def self.init_window_command(w)
    #w.add_command("名称", :唯一符号, 是否允许选择, "说明文本")
    #w.set_handler(:唯一符号, method(:command))
    #w.set_params(:唯一符号, 指定属性, 指定值)
    
    w.add_command(">> 返回标题", :title, true, "回到标题")
    w.set_handler(:title, method(:call_title))
    # 给该选项增加属性：选择后不退出，而是继续留在当前界面
    #w.set_param(:title, :no_close, true)
    # 给该选项增加属性：选择后如果指令内容有场景切换，则会跳过当前界面的移出动画
    w.set_param(:title, :call_scene, true)
    # 给该选项增加属性：排序数字 越大越后面 不设置则为0
    w.set_param(:title, :sort_v, 99)

    if $imported["EAGLE-EventCommandSkip"]
      w.add_command(
        ">> 跳过剧情",
        :msg_skip,
        COMMAND_SKIP.skippable?,
        "跳过当前阶段的剧情，并显示关键要点"
      )
      w.set_handler(:msg_skip, COMMAND_SKIP.method(:call))
      w.set_param(:msg_skip, :sort_v, 10) 
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
      w.set_param(:msg_log, :sort_v, 15) 
    end

    if $imported["EAGLE-EventLog"]
      w.add_command(
        ">> 事件日志",
        :event_log,
        true,
        "开启事件日志界面，查看已发生的大事件"
      )
      w.set_handler(:event_log, EVENT_LOG.method(:call))
      w.set_param(:event_log, :sort_v, 20) 
    end

    if $imported["EAGLE-Dictionary"]
      t = $game_system.eagle_dict.empty? ? "暂无词条" : "查看已收集的词条"
      w.add_command(
        ">> 词条收集",
        :dict,
        true,
        t
      )
      w.set_handler(:dict, DICT.method(:start))
      w.set_param(:dict, :sort_v, 25) 
    end

    if $imported["EAGLE-QuestList"]
      w.add_command(
        ">> 任务列表",
        :quest,
        true,
        "开启任务列表界面，查看全部任务"
      )
      w.set_handler(:quest, QUEST.method(:start_list))
      w.set_param(:quest, :sort_v, 30) 
    end

    if $imported["EAGLE-FastSL"]
      w.add_command(
        ">> 快速存储",
        :fast_save,
        true,
        "快速存储于第\\v[#{$game_variables[FastSL::V_ID_FILE_INDEX]}]号档位"
      )
      w.set_handler(:fast_save, FastSL.method(:save))
      w.set_param(:fast_save, :no_close, true)
      w.set_param(:fast_save, :sort_v, 40) 
      w.add_command(
        ">> 快速读取",
        :fast_load,
        true,
        "从第\\v[#{$game_variables[FastSL::V_ID_FILE_INDEX]}]号档位读取"
      )
      w.set_handler(:fast_load, FastSL.method(:load))
      w.set_param(:fast_load, :sort_v, 41) 
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
      w.set_param(:msg_vi, :no_close, true)
      w.set_param(:msg_vi, :sort_v, 50) 
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
      w.set_param(:msg_auto, :sort_v, 51) 
      # 给该选项增加属性：选择后不退出当前界面
      w.set_param(:msg_auto, :no_close, true)
    end

    if $imported["EAGLE-CallScene"]
      w.add_command(
        ">> 存档",
        :save,
        true,
        "打开存档界面"
      )
      w.set_handler(:save, TOOLBAR.method(:call_scene_save))
      w.set_param(:save, :call_scene, true)
      w.set_param(:save, :sort_v, 98) 
    end
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
  # ● 设置指令窗口
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
    sprite.bitmap ||= Bitmap.new(Graphics.width, 24)
    sprite.bitmap.font.size = HINT_FONT_SIZE
    sprite.bitmap.clear
    sprite.bitmap.fill_rect(0, 20, sprite.width, 1,
      Color.new(255,255,255,120))
  end
  #--------------------------------------------------------------------------
  # ● 设置线条精灵（下侧）
  #--------------------------------------------------------------------------
  def self.set_sprite_down(sprite, t=nil)
    sprite.bitmap ||= Bitmap.new(Graphics.width, 24)
    sprite.bitmap.font.size = HINT_FONT_SIZE
    sprite.bitmap.clear
    sprite.bitmap.draw_text(0, 2, sprite.width, sprite.height, t, 1) if t
    sprite.bitmap.fill_rect(0, 0, sprite.width, 1,
      Color.new(255,255,255,120))
  end
end

#===============================================================================
# ○ Window_Toolbar
#===============================================================================
class Window_Toolbar < Window_Command
  #--------------------------------------------------------------------------
  # ● 设置指定选项的属性
  #
  # - 可增加属性一览：
  #
  #    :sort_v = 数字      → 选项的排序值，将从大到小排列，如果不写则取 0
  #    :no_close = true    → 选择后，指令窗口不关闭，也不退出界面 
  #    :call_scene = true  → 选择后，直接处理切换场景，不显示界面的移出动画
  #--------------------------------------------------------------------------
  def set_param(symbol, k, v)
    @list.each do |c|
      next if c[:symbol] != symbol
      c[k] = v
      return
    end
  end
  def get_param(symbol, k)
    @list.each do |c|
      next if c[:symbol] != symbol
      return c[k]
    end
  end
  def current_param(k)
    return current_data[k]
  end
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
  # ● 指令列表排序
  #--------------------------------------------------------------------------
  def sort_command_list
    @list.sort_by! { |obj| obj[:sort_v] || 0 }
  end
  #--------------------------------------------------------------------------
  # ● 删除指令
  #--------------------------------------------------------------------------
  def delete_command(symbol)
    @list.delete_if { |c| c[:symbol] == symbol }
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
  #--------------------------------------------------------------------------
  # ● 调用“确定”的处理方法
  #--------------------------------------------------------------------------
  attr_accessor  :flag_ok
  alias eagle_toolbar_call_ok_handler call_ok_handler
  def call_ok_handler
    @flag_ok = true  # 需要触发当前选项的标识
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
    ui_init
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

    @window_help = Window_ToolbarHelp.new(1)
    @window_help.z = @sprite_bg.z + 20
    @window_help.opacity=@window_help.back_opacity=@window_help.contents_opacity=0
    
    @window_toolbar = Window_Toolbar.new(0, 0)
    TOOLBAR.init_window_command(@window_toolbar)
    @window_toolbar.sort_command_list
    @window_toolbar.move(0, 0,
      @window_toolbar.window_width, @window_toolbar.window_height)
    @window_toolbar.refresh
    @window_toolbar.z = @sprite_bg.z + 20
    TOOLBAR.set_window_toolbar(@window_toolbar)
    @window_toolbar.help_window = @window_help
    @window_toolbar.opacity=@window_toolbar.back_opacity=@window_toolbar.contents_opacity=0
    @window_toolbar.deactivate

    @sprite_hint_up = Sprite.new
    TOOLBAR.set_sprite_up(@sprite_hint_up)
    @sprite_hint_up.y = 0 - @sprite_hint_up.height
    @sprite_hint_up.z = @sprite_bg.z + 30
    @sprite_hint_down = Sprite.new
    TOOLBAR.set_sprite_down(@sprite_hint_down)
    @sprite_hint_down.y = Graphics.height + @sprite_hint_down.height
    @sprite_hint_down.z = @sprite_bg.z + 30
  end
  #--------------------------------------------------------------------------
  # ● 指令窗口每帧移入/移出
  #--------------------------------------------------------------------------
  def window_toolbar_move_in
    @window_toolbar.contents_opacity += 15
    @window_help.contents_opacity += 15
  end
  def window_toolbar_move_out
    @window_toolbar.contents_opacity -= 15
    @window_help.contents_opacity -= 15
  end
  #--------------------------------------------------------------------------
  # ● 开始后处理
  #--------------------------------------------------------------------------
  def post_start
    super
    @window_toolbar.select(-1)
    ui_move_in(@window_toolbar) { window_toolbar_move_in }
    TOOLBAR.set_sprite_down(@sprite_hint_down, TOOLBAR::HINT_TEXT_DEFAULT)
    @window_toolbar.select(0)
    @window_toolbar.activate
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
    TOOLBAR.set_sprite_down(@sprite_hint_down)
    ui_move_out { window_toolbar_move_out }
    # 如果flag_ok还是 true，则需要处理下当前的指令
    @window_toolbar.eagle_toolbar_call_ok_handler if @window_toolbar.flag_ok
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
    process_ok if @window_toolbar.flag_ok 
    # 如果处理完了确定键的情况，flag_ok 还是 true，则处理取消
    process_cancel if @window_toolbar.flag_ok || input_key_cancel?
  end 
  #--------------------------------------------------------------------------
  # ● 处理按下确定键
  #--------------------------------------------------------------------------
  def process_ok
    # 一般指令在scene移出后才会执行
    # 呼叫场景的指令需要return_scene前执行，确保当前scene不为nil
    return process_call_scene if @window_toolbar.current_param(:call_scene)
    # 不关闭窗口的指令需要先执行，并重新激活窗口
    return process_no_close if @window_toolbar.current_param(:no_close)
  end
  #--------------------------------------------------------------------------
  # ● 处理按下确定键：切换场景类的指令
  #--------------------------------------------------------------------------
  def process_call_scene
    @flag_call_scene = true
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
    @window_toolbar.sort_command_list
    @window_toolbar.refresh
    @window_toolbar.activate
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

#===============================================================================
# ○ 内嵌：对话日志
#===============================================================================
if $imported["EAGLE-MessageLog"]
class Scene_ToolBar
  #--------------------------------------------------------------------------
  # ● UI-初始化
  #--------------------------------------------------------------------------
  alias eagle_toolbar_msg_log_ui_init ui_init
  def ui_init
    eagle_toolbar_msg_log_ui_init
    @flag_msg_log = false 
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  alias eagle_toolbar_msg_log_update update
  def update
    return update_msg_log if @flag_msg_log
    eagle_toolbar_msg_log_update
  end
  #--------------------------------------------------------------------------
  # ● 处理按下确定键
  #--------------------------------------------------------------------------
  alias eagle_toolbar_msg_log_process_ok process_ok
  def process_ok
    return process_msg_log if @window_toolbar.current_symbol == :msg_log
    eagle_toolbar_msg_log_process_ok
  end
  #--------------------------------------------------------------------------
  # ● 处理按下确定键：进入对话日志
  #--------------------------------------------------------------------------
  def process_msg_log
    @window_toolbar.flag_ok = false
    return @window_toolbar.activate if MSG_LOG.logs.size == 0
    
    @flag_msg_log = true
    @viewport_msg_log = Viewport.new(0,60,Graphics.width, Graphics.height-120)
    @viewport_msg_log.z = @sprite_bg.z + 30
    @spriteset_msg_log = MSG_LOG::Spriteset_MsgLog.new(@viewport_msg_log)
    @spriteset_msg_log.opacity = 0
    
    TOOLBAR.set_sprite_down(@sprite_hint_down)
    ui_move_in(@viewport_msg_log.rect) { 
      window_toolbar_move_out
      @spriteset_msg_log.opacity += 15
    }
    TOOLBAR.set_sprite_down(@sprite_hint_down, TOOLBAR::HINT_TEXT_MSGLOG)
  end
  #--------------------------------------------------------------------------
  # ● 更新对话日志
  #--------------------------------------------------------------------------
  def update_msg_log
    update_basic  # 因为覆盖了原本的更新，需要额外增加一次基础更新
    @spriteset_msg_log.update
    msg_log_to_scene if input_key_cancel?
  end
  #--------------------------------------------------------------------------
  # ● 退出对话日志
  #--------------------------------------------------------------------------
  def msg_log_to_scene
    @flag_msg_log = false
    TOOLBAR.set_sprite_down(@sprite_hint_down)
    ui_move_in(@window_toolbar) { 
      window_toolbar_move_in
      @spriteset_msg_log.opacity -= 15
    }
    @spriteset_msg_log.dispose
    
    TOOLBAR.set_sprite_down(@sprite_hint_down, TOOLBAR::HINT_TEXT_DEFAULT)
    @window_toolbar.activate
  end
end
end

#===============================================================================
# ○ 内嵌：词条系统（文字版）
#===============================================================================
if $imported["EAGLE-Dictionary"]
class Scene_ToolBar
  #--------------------------------------------------------------------------
  # ● UI-初始化
  #--------------------------------------------------------------------------
  alias eagle_toolbar_dict_ui_init ui_init
  def ui_init
    eagle_toolbar_dict_ui_init
    @flag_dict = false 
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  alias eagle_toolbar_dict_update update
  def update
    return update_dict if @flag_dict
    eagle_toolbar_dict_update
  end
  #--------------------------------------------------------------------------
  # ● 处理按下确定键
  #--------------------------------------------------------------------------
  alias eagle_toolbar_dict_process_ok process_ok
  def process_ok
    return process_dict if @window_toolbar.current_symbol == :dict
    eagle_toolbar_dict_process_ok
  end
  #--------------------------------------------------------------------------
  # ● 处理按下确定键：进入词条系统
  #--------------------------------------------------------------------------
  def process_dict
    @window_toolbar.flag_ok = false
    return @window_toolbar.activate if $game_system.eagle_dict.empty?
    
    @flag_dict = true
    @viewport_dict = Viewport.new(0,60,Graphics.width, Graphics.height-120)
    @viewport_dict.z = @sprite_bg.z + 30
    @data_category = $game_system.eagle_get_dict_with_category
    
    # 生成分割线绘制用精灵
    @sprite_dict_layer = Sprite.new
    @sprite_dict_layer.bitmap = Bitmap.new(@viewport_dict.rect.width, 
      @viewport_dict.rect.height)
    @sprite_dict_layer.z = @sprite_bg.z + 20
    @sprite_dict_layer.opacity = 0

    # 生成类别组
    @spriteset_category = Spriteset_EagleDict_Category.new(@data_category)
    @spriteset_category.set_pos(@viewport_dict.rect.y+@spriteset_category.height, 
      @sprite_bg.z + 10)
    @spriteset_category.opacity = 0
    # 绘制水平分割线
    _y = @spriteset_category.y + @spriteset_category.height/2
    @sprite_dict_layer.bitmap.fill_rect(12, _y, @sprite_dict_layer.width-24,1,
      Color.new(255,255,255,120))

    # 生成词条列表
    _w = DICT::LIST_WIDTH
    _h = @viewport_dict.rect.y + @viewport_dict.rect.height - _y
    @window_list = Window_EagleDict_List.new(0,0,150,_h+24)
    @window_list.x = 0
    @window_list.y = _y
    @window_list.z = @sprite_bg.z + 30
    @window_list.contents_opacity = 0
    # 绘制垂直分割线
    _x = @window_list.x + @window_list.width
    @sprite_dict_layer.bitmap.fill_rect(_x, @window_list.y + 12 + 4, 1, _h,
      Color.new(255,255,255,120))

    # 生成词条文本
    _w = @viewport_dict.rect.width - _x - 12
    viewport = Viewport.new(_x + 12, @window_list.y + 12, _w, _h)
    viewport.z = @sprite_bg.z + 12
    @spriteset_info = Spriteset_EagleDict_Info.new(viewport, @window_list)
    
    @spriteset_category.window_list = @window_list
    @spriteset_category.opacity = 0
    @spriteset_category.refresh
    
    TOOLBAR.set_sprite_down(@sprite_hint_down)
    ui_move_in(@viewport_dict.rect) { 
      window_toolbar_move_out
      @sprite_dict_layer.opacity += 15
      @spriteset_category.opacity += 15
      @window_list.contents_opacity += 15
      @spriteset_info.opacity += 15
    }
    TOOLBAR.set_sprite_down(@sprite_hint_down, TOOLBAR::HINT_TEXT_DICT)
  end
  #--------------------------------------------------------------------------
  # ● 更新词条系统
  #--------------------------------------------------------------------------
  def update_dict
    update_basic  # 因为覆盖了原本的更新，需要额外增加一次基础更新
    #@window_list.update  # update_basic 中已经对窗口进行了更新
    @spriteset_category.update
    @spriteset_info.update
    dict_to_scene if input_key_cancel?
  end
  #--------------------------------------------------------------------------
  # ● 退出词条系统
  #--------------------------------------------------------------------------
  def dict_to_scene
    @flag_dict = false
    TOOLBAR.set_sprite_down(@sprite_hint_down)
    ui_move_in(@window_toolbar) { 
      window_toolbar_move_in
      @spriteset_category.opacity -= 15
      @window_list.contents_opacity -= 15
      @spriteset_info.opacity -= 15
      @sprite_dict_layer.opacity -= 15
    }
    @sprite_dict_layer.bitmap.dispose
    @sprite_dict_layer.dispose
    @spriteset_info.dispose
    @window_list.dispose
    @window_list = nil
    @spriteset_category.dispose
    @viewport_dict.dispose
    
    TOOLBAR.set_sprite_down(@sprite_hint_down, TOOLBAR::HINT_TEXT_DEFAULT)
    @window_toolbar.activate
  end
end
end
