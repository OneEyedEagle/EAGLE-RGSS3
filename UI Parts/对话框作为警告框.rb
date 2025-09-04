#==============================================================================
# ■ 对话框作为警告框 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
#==============================================================================
$imported ||= {}
$imported["EAGLE-MsgAlert"] = "1.0.0"
#==============================================================================
# - 2025.8.31.12
#==============================================================================
# - 本插件利用对话框来作为任意时刻都能使用的警告框。
#------------------------------------------------------------------------------
# 【使用：利用默认对话框】
#
#    result = ALERT.show(text, choices, params)
#
#  其中：
#
#     text    → 对话框显示文本的字符串，如果需要使用转义符，请将 \ 替换为 \\ 。
#                如： text="你确定要\\c[1]覆盖\\c[0]存档吗？"
#
#     choices → 选择框显示的选择支及选择该选择支后的返回结果。
#                数组，其中每一项是 [选择支文本, 返回值] 的数组。
#                若填写 []，则不显示选项，且返回值 result=true。
#                若未填写，则取 choices=[["是", true], ["否", false]]。
#
#     result  → 返回值，根据选择支的设置不同，返回不同的值。
#
#     params  → 对话框的相关设置，Hash，可设置以下参数
#
#                "face_name"  => "",  # 所使用的脸图文件名
#                "face_index" => 0,   # 所使用的脸图索引号
#                "background" => 0,   # 对话框背景 0=正常 1=暗色 2=透明
#                "position"   => 2,   # 对话框位置 0=居上 1=居中 2=居下
#                "z"          => 200, # （仅RGSS默认对话框）对话框的z值
#                                     # （对于鹰式对话框扩展，请使用\\win[z=200]）
#
#------------------------------------------------------------------------------
# 【使用：利用鹰式对话框扩展】
#
#    result = ALERT.show2(text, choices, params)
#
#  其中各个参数同上。
#
#------------------------------------------------------------------------------
# 【示例：存档时判定是否覆盖已有存档】
#
# - 在默认存档界面中，并不会判定当前是否有存档，而是直接覆盖。
#   利用本插件新增的方法，可以很容易增加一个是否覆盖当前存档的提示框。
#
class Scene_Save < Scene_File
  #--------------------------------------------------------------------------
  # ● 确定存档文件
  #--------------------------------------------------------------------------
  alias eagle_alert_on_savefile_ok on_savefile_ok
  def on_savefile_ok
    if File.exist?(DataManager.make_filename(@index))
      # 使用鹰式对话框扩展作为二次确认窗口
      if $imported["EAGLE-MessageEX"]
        w = @savefile_windows[@index]
        x = @savefile_viewport.rect.x + w.x + w.width / 2
        y = @savefile_viewport.rect.y + w.y + w.height / 2
        t = "\\win[o=5 x=#{x} y=#{y} fw=1 fh=1]确定要\\c[1]覆盖\\c[0]当前存档吗？"
        t += "\\choice[ali=1]" if $imported["EAGLE-ChoiceEX"]
        return false if !ALERT.show2(t)
        return eagle_alert_on_savefile_ok
      end
      # 使用默认对话框作为二次确认窗口
      return false if !ALERT.show("确定要\\c[1]覆盖\\c[0]当前存档吗？")
    end
    eagle_alert_on_savefile_ok
  end
end
#
#------------------------------------------------------------------------------
# 【示例：返回标题时二次确定】
#
# - 在默认菜单界面的 结束游戏 指令中，可以选择返回标题或退出游戏，
#   但默认并没有二次提示玩家要确定已经保存，而是直接处理了。
#   利用本插件新增的方法，可以很容易增加这个二次确定。
#
class Scene_End < Scene_MenuBase
  #--------------------------------------------------------------------------
  # ● 指令“返回标题”
  #--------------------------------------------------------------------------
  alias eagle_alert_command_to_title command_to_title
  def command_to_title
    # 使用默认对话框作为二次确认窗口
    t = "确定要\\c[10]返回标题\\c[0]吗？
未保存的内容都会丢失！"
    if ALERT.show(t)
      eagle_alert_command_to_title
    else
      @command_window.activate  # 重新激活指令框
    end
  end
  #--------------------------------------------------------------------------
  # ● 指令“退出”
  #--------------------------------------------------------------------------
  alias eagle_alert_command_shutdown command_shutdown
  def command_shutdown
    # 使用默认对话框作为二次确认窗口
    t = "确定要\\c[10]退出游戏\\c[0]吗？
未保存的内容都会丢失！"
    if ALERT.show(t)
      eagle_alert_command_shutdown
    else
      @command_window.activate  # 重新激活指令框
    end
  end
end
#
#==============================================================================

module ALERT
  #--------------------------------------------------------------------------
  # ● 利用默认对话框进行处理
  #--------------------------------------------------------------------------
  def self.show(text, choices=[["是", true], ["否", false]], params={})
    msg = Game_Message.new
    msg.add(text)
    @result = 0
    msg.choice_proc = Proc.new {|n| @result = n }
    w = Window_Message_Alone.new(msg)
    raw(msg, w, choices, params)
    return choices[@result][1] if !choices.empty?
    return true
  end
  
  #--------------------------------------------------------------------------
  # ● 利用【鹰式对话框扩展】进行处理
  #--------------------------------------------------------------------------
  def self.show2(text, choices=[["是", true], ["否", false]], params={})
    msg = $game_message.clone2
    msg.add(text)
    w = Window_EagleMessage_Alone.new(msg)
    raw(msg, w, choices, params)
    return choices[msg.choice_result][1] if !choices.empty?
    return true
  end
  
  #--------------------------------------------------------------------------
  # ● 通用-处理对话框及选择框
  #--------------------------------------------------------------------------
  def self.raw(msg, window, choices, params)
    # 设置对话框属性
    msg.face_name  = params["face_name"]  || ""
    msg.face_index = params["face_index"] || 0
    msg.background = params["background"] || 0
    msg.position   = params["position"]   || 2
    window.z       = params["z"] if params["z"]
    # 添加选择支
    if !choices.empty?
      choices.each {|s| msg.choices.push(s[0]) }
      msg.choice_cancel_type = 0
    end
    # 更新，直至关闭对话框
    while true
      window.update
      Input.update
      Graphics.update
      break if msg.visible == false
    end
    # 留出对话框关闭的时间
    15.times { 
      window.update
      Input.update
      Graphics.update
    }
    # 释放对话框
    window.dispose
  end
end

#=============================================================================
# ○ 兼容默认对话框和选择框
#=============================================================================
class Window_Message_Alone < Window_Message
  #--------------------------------------------------------------------------
  # ● 获取主参数组
  #--------------------------------------------------------------------------
  def game_message;     @game_message;      end
  def game_message=(g); @game_message = g;  end
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize(msg)
    @game_message = msg
    super()
  end
  #--------------------------------------------------------------------------
  # ● 更新纤程
  #--------------------------------------------------------------------------
  def update_fiber
    if @fiber
      @fiber.resume
    elsif @game_message.busy? && !@game_message.scroll_mode
      @fiber = Fiber.new { fiber_main }
      @fiber.resume
    else
      @game_message.visible = false
    end
  end
  #--------------------------------------------------------------------------
  # ● 生成所有窗口
  #--------------------------------------------------------------------------
  def create_all_windows
    @gold_window = Window_Gold.new
    @gold_window.x = Graphics.width - @gold_window.width
    @gold_window.y = 0
    @gold_window.openness = 0
    @choice_window = Window_ChoiceList_Alone.new(self, @game_message)
    @number_window = Window_NumberInput.new(self)
    @item_window = Window_KeyItem.new(self)
  end
  #--------------------------------------------------------------------------
  # ● 处理纤程的主逻辑
  #--------------------------------------------------------------------------
  def fiber_main
    @game_message.visible = true
    update_background
    update_placement
    loop do
      process_all_text if @game_message.has_text?
      process_input
      @game_message.clear
      @gold_window.close
      Fiber.yield
      break unless text_continue?
    end
    close_and_wait
    @game_message.visible = false
    @fiber = nil
  end
  #--------------------------------------------------------------------------
  # ● 更新窗口背景
  #--------------------------------------------------------------------------
  def update_background
    @background = @game_message.background
    self.opacity = @background == 0 ? 255 : 0
  end
  #--------------------------------------------------------------------------
  # ● 更新窗口的位置
  #--------------------------------------------------------------------------
  def update_placement
    @position = @game_message.position
    self.y = @position * (Graphics.height - height) / 2
    @gold_window.y = y > 0 ? 0 : Graphics.height - @gold_window.height
  end
  #--------------------------------------------------------------------------
  # ● 处理所有内容
  #--------------------------------------------------------------------------
  def process_all_text
    open_and_wait
    text = convert_escape_characters(@game_message.all_text)
    pos = {}
    new_page(text, pos)
    process_character(text.slice!(0, 1), text, pos) until text.empty?
  end
  #--------------------------------------------------------------------------
  # ● 输入处理
  #--------------------------------------------------------------------------
  def process_input
    if @game_message.choice?
      input_choice
    elsif @game_message.num_input?
      input_number
    elsif @game_message.item_choice?
      input_item
    else
      input_pause unless @pause_skip
    end
  end
  #--------------------------------------------------------------------------
  # ● 判定文字是否继续显示
  #--------------------------------------------------------------------------
  def text_continue?
    @game_message.has_text? && !settings_changed?
  end
  #--------------------------------------------------------------------------
  # ● 判定背景和位置是否被更改
  #--------------------------------------------------------------------------
  def settings_changed?
    @background != @game_message.background ||
    @position != @game_message.position
  end
  #--------------------------------------------------------------------------
  # ● 翻页处理
  #--------------------------------------------------------------------------
  def new_page(text, pos)
    contents.clear
    draw_face(@game_message.face_name, @game_message.face_index, 0, 0)
    reset_font_settings
    pos[:x] = new_line_x
    pos[:y] = 0
    pos[:new_x] = new_line_x
    pos[:height] = calc_line_height(text)
    clear_flags
  end
  #--------------------------------------------------------------------------
  # ● 获取换行位置
  #--------------------------------------------------------------------------
  def new_line_x
    @game_message.face_name.empty? ? 0 : 112
  end
end
class Window_ChoiceList_Alone < Window_ChoiceList
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize(message_window, game_message)
    @game_message = game_message
    super(message_window)
  end
  #--------------------------------------------------------------------------
  # ● 更新窗口的位置
  #--------------------------------------------------------------------------
  def update_placement
    self.width = [max_choice_width + 12, 96].max + padding * 2
    self.width = [width, Graphics.width].min
    self.height = fitting_height(@game_message.choices.size)
    self.x = Graphics.width - width
    if @message_window.y >= Graphics.height / 2
      self.y = @message_window.y - height
    else
      self.y = @message_window.y + @message_window.height
    end
  end
  #--------------------------------------------------------------------------
  # ● 获取选项的最大宽度
  #--------------------------------------------------------------------------
  def max_choice_width
    @game_message.choices.collect {|s| text_size(s).width }.max
  end
  #--------------------------------------------------------------------------
  # ● 生成指令列表
  #--------------------------------------------------------------------------
  def make_command_list
    @game_message.choices.each do |choice|
      add_command(choice, :choice)
    end
  end
  #--------------------------------------------------------------------------
  # ● 获取“取消处理”的有效状态
  #--------------------------------------------------------------------------
  def cancel_enabled?
    @game_message.choice_cancel_type > 0
  end
  #--------------------------------------------------------------------------
  # ● 调用“确定”的处理方法
  #--------------------------------------------------------------------------
  def call_ok_handler
    @game_message.choice_proc.call(index)
    close
  end
  #--------------------------------------------------------------------------
  # ● 调用“取消”的处理方法
  #--------------------------------------------------------------------------
  def call_cancel_handler
    @game_message.choice_proc.call(@game_message.choice_cancel_type - 1)
    close
  end
end 

#===============================================================================
# ○ 兼容【鹰式对话框扩展】
#===============================================================================
if $imported["EAGLE-MessageEX"]
class Window_EagleMessage_Alone < Window_EagleMessage
  #--------------------------------------------------------------------------
  # ● 获取主参数组（方便子窗口修改为自己的game_message）
  #--------------------------------------------------------------------------
  def game_message;     @game_message;      end
  def game_message=(g); @game_message = g;  end
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize(msg)
    self.game_message = msg
    super()
  end
end
end
