#==============================================================================
# ■ 快捷功能界面 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
# - 2020.8.5.22 兼容对话框扩展，新增对话自动播放的设置
#==============================================================================
$imported ||= {}
$imported["EAGLE-EventToolbar"] = true
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
#    若使用了【对话日志 by老鹰】，将加入 对话日志 的指令。
#    若使用了【快速存读档 by老鹰】，将加入 快速存档 与 快速读档 的指令。
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
    call if Input.trigger?(:X)
  end
  #--------------------------------------------------------------------------
  # ● 初始化指令
  #--------------------------------------------------------------------------
  # 设置不需要退出当前界面的指令
  COMMANDS_NO_CLOSE = [:msg_auto, :msg_vi]
  def self.init_window_command
    #@window_toolbar.add_command("名称", :唯一符号, 是否允许选择, "说明文本")
    #@window_toolbar.set_handler(:唯一符号, method(:command))

    if $imported["EAGLE-EventCommandSkip"]
      @window_toolbar.add_command(
        ">> 跳过剧情",
        :msg_skip,
        COMMAND_SKIP.skippable?,
        "跳过当前阶段的剧情，并显示关键要点"
      )
      @window_toolbar.set_handler(:msg_skip, COMMAND_SKIP.method(:call))
    end

    if $imported["EAGLE-MessageEX"]
      t = "已\\c[17]关闭\\c[0]自动对话"
      if v = $game_message.win_params[:auto_t]
        t = sprintf("在 \\c[17]%0.1f\\c[0]s 后自动继续对话", v * 1.0 / 60)
      end
      @window_toolbar.add_command(
        ">> 自动对话",
        :msg_auto,
        true,
        t
      )
      @window_toolbar.set_handler(:msg_auto, TOOLBAR.method(:toggle_msg_auto))
    end

    if $imported["EAGLE-MessageLog"]
      @window_toolbar.add_command(
        ">> 对话日志",
        :msg_log,
        true,
        "开启对话日志界面，查看对话记录"
      )
      @window_toolbar.set_handler(:msg_log, MSG_LOG.method(:call))
    end

    if $imported["EAGLE-FastSL"]
      @window_toolbar.add_command(
        ">> 快速存储",
        :fast_save,
        true,
        "快速存储于第\\v[#{$game_variables[FastSL::V_ID_FILE_INDEX]}]号档位"
      )
      @window_toolbar.set_handler(:fast_save, FastSL.method(:save))
      @window_toolbar.add_command(
        ">> 快速读取",
        :fast_load,
        true,
        "从第\\v[#{$game_variables[FastSL::V_ID_FILE_INDEX]}]号档位读取"
      )
      @window_toolbar.set_handler(:fast_load, FastSL.method(:load))
    end

    if $game_message.visible
      scene = SceneManager.scene
      f = scene.message_window.visible rescue false
      t = f ? "隐藏" : "显示"
      @window_toolbar.add_command(
        ">> "+t+"对话框",
        :msg_vi,
        $game_message.visible,
        "切换对话框的显示/隐藏"
      )
      @window_toolbar.set_handler(:msg_vi, TOOLBAR.method(:toggle_msg_visible))
    end

    if $imported["EAGLE-CallScene"]
      @window_toolbar.add_command(
        ">> 存档",
        :save,
        true,
        "打开存档界面"
      )
      @window_toolbar.set_handler(:save, TOOLBAR.method(:call_scene_save))
    end
  end
  #--------------------------------------------------------------------------
  # ● 方法绑定-呼叫存档界面
  #--------------------------------------------------------------------------
  if $imported["EAGLE-CallScene"]
    def self.call_scene_save
      EAGLE.call_scene(Scene_Save)
    end
  end
  #--------------------------------------------------------------------------
  # ● 方法绑定-切换对话框显隐
  #--------------------------------------------------------------------------
  def self.toggle_msg_visible
    scene = SceneManager.scene
    msg = scene.message_window rescue return
    msg.visible ? msg.hide : msg.show
  end
  #--------------------------------------------------------------------------
  # ● 方法绑定-切换对话框自动播放
  #--------------------------------------------------------------------------
  AUTO_MSG_T = [nil, 30, 60, 120]
  def self.toggle_msg_auto
    v = $game_message.win_params[:auto_t]
    i = AUTO_MSG_T.index(v)
    if i
      $game_message.win_params[:auto_t] = AUTO_MSG_T[(i + 1) % AUTO_MSG_T.size]
    else
      $game_message.win_params[:auto_t] = nil
    end
    $game_message.win_params[:auto_r] = false
  end

  #--------------------------------------------------------------------------
  # ● 设置主窗口
  #--------------------------------------------------------------------------
  def self.set_window_toolbar
    @window_toolbar.x = 90
    @window_toolbar.y = Graphics.height / 2 - @window_toolbar.height / 2 - 20
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
    sprite.bitmap.font.size = 14
    sprite.bitmap.fill_rect(0, 20, sprite.width, 1,
      Color.new(255,255,255,120))
  end
  #--------------------------------------------------------------------------
  # ● 设置线条精灵（下侧）
  #--------------------------------------------------------------------------
  def self.set_sprite_down(sprite)
    sprite.bitmap = Bitmap.new(Graphics.width, 24)
    sprite.bitmap.font.size = 14
    sprite.bitmap.draw_text(0, 2, sprite.width, sprite.height,
      "上/下方向键 - 选择 | 确定键 - 执行 | 取消键 - 退出", 1)
    sprite.bitmap.fill_rect(0, 0, sprite.width, 1,
      Color.new(255,255,255,120))
    sprite.y = Graphics.height
  end
  #--------------------------------------------------------------------------
  # ● 呼叫
  #--------------------------------------------------------------------------
  def self.call
    ui_init
    ui_update
    ui_dispose
  end
#===============================================================================
# ○ UI
#===============================================================================
class << self
  #--------------------------------------------------------------------------
  # ● UI-初始化
  #--------------------------------------------------------------------------
  def ui_init
    @sprite_bg = Sprite.new
    set_sprite_bg(@sprite_bg)
    @sprite_bg.opacity = 0
    @sprite_bg.z = 300 if $game_message.visible

    @sprite_bg_info = Sprite.new
    @sprite_bg_info.z = @sprite_bg.z + 1
    set_sprite_info(@sprite_bg_info)

    @window_toolbar = Window_Toolbar.new(0, 0)
    init_window_command
    @window_toolbar.move(0, 0,
      @window_toolbar.window_width, @window_toolbar.window_height)
    @window_toolbar.refresh
    @window_toolbar.select(0)
    @window_toolbar.opacity = 0
    @window_toolbar.back_opacity = 0
    @window_toolbar.contents_opacity = 255
    @window_toolbar.z = @sprite_bg.z + 1
    set_window_toolbar

    @window_help = Window_ToolbarHelp.new(1)
    @window_help.z = @sprite_bg.z + 1
    @window_help.opacity = 0
    @window_help.back_opacity = 0
    @window_help.contents_opacity = 255
    @window_help.openness = 0

    @window_toolbar.help_window = @window_help

    @sprite_hint_up = Sprite.new
    @sprite_hint_up.z = @sprite_bg.z + 1
    set_sprite_up(@sprite_hint_up)

    @sprite_hint_down = Sprite.new
    @sprite_hint_down.z = @sprite_bg.z + 1
    set_sprite_down(@sprite_hint_down)
  end
  #--------------------------------------------------------------------------
  # ● UI-释放
  #--------------------------------------------------------------------------
  def ui_dispose
    @window_help.dispose
    @window_toolbar.dispose
    instance_variables.each do |varname|
      ivar = instance_variable_get(varname)
      if ivar.is_a?(Sprite)
        ivar.bitmap.dispose
        ivar.dispose
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● UI-更新至完成
  #--------------------------------------------------------------------------
  def ui_update
    ui_move_in
    update_basic
    while true
      @window_toolbar.update
      @window_help.update
      update_basic
      break if Input.trigger?(:B)
      break if @window_toolbar.close?
    end
    ui_move_out
    @window_toolbar.eagle_toolbar_call_ok_handler if @window_toolbar.flag_ok
  end
  #--------------------------------------------------------------------------
  # ● UI-基础更新
  #--------------------------------------------------------------------------
  def update_basic
    Graphics.update
    Input.update
  end
  #--------------------------------------------------------------------------
  # ● UI-移入
  #--------------------------------------------------------------------------
  def ui_move_in
    @window_toolbar.open
    @window_help.open
    params = {}
    params[@sprite_hint_down] = { :type => :y,
      :des => @window_toolbar.y + @window_toolbar.height }
    params[@sprite_hint_up] = { :type => :y,
      :des => @window_toolbar.y - 4 - @sprite_hint_up.height }
    ui_move(params) {
      @window_toolbar.update
      @window_help.update
      @sprite_bg.opacity += 15
    }
  end
  #--------------------------------------------------------------------------
  # ● UI-移出
  #--------------------------------------------------------------------------
  def ui_move_out
    @window_toolbar.close
    @window_help.close
    params = {}
    params[@sprite_hint_down] = { :type => :y,
      :des => Graphics.height + @sprite_hint_down.height }
    params[@sprite_hint_up] = { :type => :y,
      :des => 0 - @sprite_hint_up.height }
    ui_move(params) {
      @window_toolbar.update
      @window_help.update
      @sprite_bg.opacity -= 15
    }
  end
  #--------------------------------------------------------------------------
  # ● UI-控制三次立方移动
  #--------------------------------------------------------------------------
  def ui_move(params, t = 20)
    # params = { sprite => {:type =>, :des => } }
    params.each do |s, v|
      case v[:type]
      when :x
        v[:init] = s.x
        v[:dis] = v[:des] - s.x
      when :y
        v[:init] = s.y
        v[:dis] = v[:des] - s.y
      end
    end

    _i = 0; _t = t
    while(true)
      break if _i > _t
      per = _i * 1.0 / _t
      per = (_i == _t ? 1 : (1 - 2**(-10 * per)))
      _i += 1
      params.each do |s, v|
        case v[:type]
        when :x
          s.x = v[:init] + v[:dis] * per
        when :y
          s.y = v[:init] + v[:dis] * per
        end
      end
      yield
      update_basic
    end
  end
end
end # end of module
#===============================================================================
# ○ Window_Toolbar
#===============================================================================
class Window_Toolbar < Window_Command
  attr_reader :flag_ok
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
    fitting_height(@list.size)
  end
  #--------------------------------------------------------------------------
  # ● 获取项目的宽度
  #--------------------------------------------------------------------------
  def item_width
    140
  end
  #--------------------------------------------------------------------------
  # ● “确定”和“取消”的处理
  #--------------------------------------------------------------------------
  def process_handling
    return unless open? && active
    return process_ok       if ok_enabled?        && Input.trigger?(:C)
    return process_cancel   if cancel_enabled?    && Input.trigger?(:B)
  end
  #--------------------------------------------------------------------------
  # ● 调用“确定”的处理方法
  #--------------------------------------------------------------------------
  alias eagle_toolbar_call_ok_handler call_ok_handler
  def call_ok_handler
    if TOOLBAR::COMMANDS_NO_CLOSE.include?(current_symbol)
      eagle_toolbar_call_ok_handler
      clear_command_list_eagle
      TOOLBAR::init_window_command
      refresh
      activate
      return
    end
    #eagle_toolbar_call_ok_handler
    @flag_ok = true
    close
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
  # ● 刷新
  #--------------------------------------------------------------------------
  def refresh
    contents.clear
    draw_text_ex(0, 0, "\\}" + @text) if @text
  end
  #--------------------------------------------------------------------------
  # ● 放大字体尺寸
  #--------------------------------------------------------------------------
  def make_font_bigger
    contents.font.size += 4 if contents.font.size <= 64
  end
  #--------------------------------------------------------------------------
  # ● 缩小字体尺寸
  #--------------------------------------------------------------------------
  def make_font_smaller
    contents.font.size -= 4 if contents.font.size >= 16
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
