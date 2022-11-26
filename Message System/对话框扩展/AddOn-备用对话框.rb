#==============================================================================
# ■ Add-On 备用对话框 by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【对话框扩展 by老鹰】（>= 1.9.3）之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-AnotherMsg"] = "1.0.3"
#=============================================================================
# - 2022.11.26.11 修改注释
#==============================================================================
# - 本插件新增了多对话框的处理，当对话框已经开启时，将生成新的对话框继续执行事件
#------------------------------------------------------------------------------
# 【多对话框】
#
# - 在对话框已经开启、即将显示文字时，如果其它事件开始执行【显示文字】指令：
#
#  · 在默认RGSS中，将等待当前对话框结束，其它事件才能继续执行；
#
#  · 在本插件中，将生成一个新的对话框来与当前对话框同时处理，一同响应按键
#
# - 注意：
#
#  · 生成的对话框不会处理选择框等子窗口，依然会使用默认的对话框来处理
#
#  · 删去了事件执行前的 wait_for_message，确保并行事件的执行不会被对话框阻止
#
# - 兼容：
#
#  · 当使用了【Add-On 触发事件消息 by老鹰】时，
#     将自动为消息中的【显示文字】生成新对话框来显示，避免了卡死的问题
#
#------------------------------------------------------------------------------
# 【最高优先级的对话框】
#
# - 利用全局脚本，在任意位置、任意时刻显示一个独立的对话框：
#
#     MESSAGE_EX.alert(text, params = {})
#
#    其中 text 为需要显示的字符串，其中转义符用 \\ 代替 \，
#      可以使用【对话框扩展 by老鹰】中的全部转义符
#
#    其中 params 为可选参数，传入与事件指令中相同的对话框参数
#
#      "face_name" => 脸图文件名称
#      "face_index" => 脸图文件索引号
#      "background" => 对话框背景类型（0普通，1暗色，2透明）
#      "position" => 对话框位置（0上，1中，2下）
#
# - 注意：该对话框关闭后，才会继续进行之前的处理
#
# - 示例：
#
#     MESSAGE_EX.alert("\\name[警告]你只有先进行存档，才能继续！")
#
#     t = "\\win[o5 do-5]你不应该这样做。"
#     ps = {"face_name" => "Actor_1", "face_index" => 0 }
#     MESSAGE_EX.alert(t, ps)
#
#==============================================================================

module MESSAGE_EX
  #--------------------------------------------------------------------------
  # ● 最高显示优先级的对话框
  #--------------------------------------------------------------------------
  def self.alert(text, params = {})
    msg = $game_message.clone2
    w = Window_AnotherEagleMsg.new(msg)
    
    msg.face_name = params["face_name"] || ""
    msg.face_index = params["face_index"] || 0
    msg.background = params["background"] || 0
    msg.position = params["position"] || 2
    msg.add(text)
    
    while true
      w.update
      Input.update
      Graphics.update
      break if msg.visible == false
    end
    w.dispose
  end

  #--------------------------------------------------------------------------
  # ● 生成一个新的备用对话框
  # 返回：Game_Message的实例，用于在事件解释器中替换$game_message
  #--------------------------------------------------------------------------
  @another_windows = []
  def self.create_another_msg
    msg = $game_message.clone2
    window = Window_AnotherEagleMsg.new(msg)
    @another_windows.push(window)
    return msg
  end
  #--------------------------------------------------------------------------
  # ● 更新全部备用对话框
  #--------------------------------------------------------------------------
  def self.update_another_msgs
    @another_windows.each { |w| w.update }
  end
  #--------------------------------------------------------------------------
  # ● 释放指定的备用对话框
  #--------------------------------------------------------------------------
  def self.dispose_another_msg(msg)
    i = @another_windows.index { |w| w.game_message == msg }
    return if i == nil
    @another_windows[i].dispose 
    @another_windows.delete_at(i)
  end
  #--------------------------------------------------------------------------
  # ● 释放全部备用对话框
  #--------------------------------------------------------------------------
  def self.dispose_another_msgs
    @another_windows.each { |w| w.dispose }
    @another_windows.clear
  end
end
#===============================================================================
# ○ 对话框子类
#===============================================================================
class Window_AnotherEagleMsg < Window_EagleMessage
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
#===============================================================================
# ○ Game_Interpreter
#===============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ●【覆盖】执行
  #--------------------------------------------------------------------------
  def run
    #wait_for_message
    while @list[@index] do
      execute_command
      @index += 1
    end
    Fiber.yield
    @fiber = nil
  end
  #--------------------------------------------------------------------------
  # ● 显示文字
  #--------------------------------------------------------------------------
  alias eagle_another_msg_old_command_101 command_101
  def command_101
    if @eagle_raw_msg != true && (@eagle_another_msg || $game_message.active)
      if @eagle_another_msg == nil 
        @eagle_another_msg = MESSAGE_EX.create_another_msg 
      end
      @eagle_raw_msg = false
      return eagle_another_command_101 
    end
    @eagle_raw_msg = true
    eagle_another_msg_old_command_101
  end
  #--------------------------------------------------------------------------
  # ● 显示文字（备用对话框）
  #--------------------------------------------------------------------------
  def eagle_another_command_101
    @eagle_another_msg.event_id = @event_id

    @eagle_another_msg.face_name = @params[0]
    @eagle_another_msg.face_index = @params[1]
    @eagle_another_msg.background = @params[2]
    @eagle_another_msg.position = @params[3]
    while next_event_code == 401       # 文字数据
      @index += 1
      @eagle_another_msg.add(@list[@index].parameters[0])
    end
    eagle_another_wait_for_message
  end
  #--------------------------------------------------------------------------
  # ● 等待文字显示（备用对话框）
  #--------------------------------------------------------------------------
  def eagle_another_wait_for_message
    Fiber.yield while @eagle_another_msg.busy?
  end
  #--------------------------------------------------------------------------
  # ● 事件结束的指令
  #--------------------------------------------------------------------------
  if !defined?(command_0)
    def command_0
    end
  end
  alias eagle_another_command_0 command_0
  def command_0
    eagle_another_command_0
    if @eagle_another_msg
      Fiber.yield while @eagle_another_msg.visible
      MESSAGE_EX.dispose_another_msg(@eagle_another_msg)
      @eagle_another_msg = nil
    end
  end
end
#=============================================================================
# ○ 绑定
#=============================================================================
class Scene_Base
  #--------------------------------------------------------------------------
  # ● 基础更新
  #--------------------------------------------------------------------------
  alias eagle_another_msg_update_basic update_basic
  def update_basic
    eagle_another_msg_update_basic
    MESSAGE_EX.update_another_msgs
  end
  #--------------------------------------------------------------------------
  # ● 结束处理
  #--------------------------------------------------------------------------
  alias eagle_another_msg_terminate terminate
  def terminate
    eagle_another_msg_terminate
    MESSAGE_EX.dispose_another_msgs
  end
end
