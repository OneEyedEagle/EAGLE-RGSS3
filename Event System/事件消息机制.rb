#==============================================================================
# ■ 事件消息机制 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
#==============================================================================
$imported ||= {}
$imported["EAGLE-EventMsg"] = "1.5.2"
#==============================================================================
# - 2022.5.5.23 现在可以正常把事件消息存档了
#==============================================================================
# - 本插件新增消息机制，以直接触发事件中的指令
#-----------------------------------------------------------------------------
# ○ 地图的事件
#-----------------------------------------------------------------------------
# - 对于 Game_Event 对象，利用 msg(LABEL[, cur_page]) 方法，并行调用指定指令序列
#
#    其中 LABEL 为事件中的标签内容的字符串
#               需要与 事件指令-标签 中所写的内容完全一致，包括前后空格
#
#    其中 cur_page 传入 false，则在事件的全部事件页中搜索 LABEL 标签
#                  传入 true，则只在当前激活的事件页中搜索 LABEL 标签
#                  可省略，默认传入 false
#
# 【运行逻辑】
#
#    1. 在目标事件页（无视事件触发条件）中搜索内容为 LABEL 的标签
#
#    2. 若找到，则继续查找在该标签后的第一个内容为 END 的标签
#
#    3. 立即执行这两个标签中间的事件指令（若未找到 END，则一直执行到事件结尾）
#
#    4. 当成功找到标签时，msg 方法返回 true，否则返回 false
#
#
# 【示例】
#
#   当前地图的 1 号事件的第 2 页的指令列表如下
#    |- 显示文字：测试语句1
#    |- 标签：A
#    |- 显示文字：测试语句2
#    |- 标签：END
#    |- 显示文字：测试语句3
#    |- 标签：B
#    |- 显示文字：测试语句4
#    |- 标签：END
#
#  → 正常执行该事件，将按序显示 测试语句1、测试语句2、测试语句3、测试语句4
#
#  → 若在另一事件中调用事件脚本 $game_map.events[1].msg("A")，则只显示 测试语句2
#
#  → 若在另一事件中调用事件脚本 $game_map.events[1].msg("B")，则只显示 测试语句4
#
#
# 【注意】
#
#   1. 为了保证事件的等待指令有意义，并且不出现明显的操作延时感，
#      若消息未执行完，此时再传入同一消息，将不会重复执行，但依然返回 true。
#
#   2. 事件触发了 暂时消除 后，其当前的全部消息都将终止执行。
#
#   3. 事件切换页面后，仅在当前页查找的全部消息将终止执行。
#
#
# 【特殊指令：特定功能的标签】
#
#   1. 编写内容为 RESTART 的标签指令，在读取到该标签时，将立即从头开始执行当前消息。
#        可放置于 END 标签指令前，用来制作循环执行的消息。
#      注意：中止事件处理依然能够强行结束消息。
#
#
# 【特殊指令：扩展的标签跳转】
#
#   - 对于事件消息中的【标签跳转】指令，将在本消息的初始查找范围内尝试跳转，
#     （如果新增消息时，明确了是当前页查找，那标签跳转也只在当前页内查找。）
#
#     如果找到跳转的标签：
#       当前消息压栈，执行跳转后的内容，且丢弃之前消息的剩余指令。
#     如果未找到标签：
#       控制台输出报错，无视该跳转指令，继续执行之后的内容。
#
#   - 如果想在跳转后回到当前消息，请见【事件脚本：仿公共事件调用消息】。
#
#
# 【特殊指令：自动触发的消息】
#
#   - 在一些特定场合，可能需要地图事件中的消息能够自动执行，
#     本插件新增了如下的特定时机，及自动执行的消息（并行执行，不影响其它消息）。
#     如果没有设置对应标签的话，那就无事发生。
#
#   1. 当事件生成时（一般为进入地图时，当然如果使用了【事件拷贝】，那就是生成时），
#      将自动触发一次【全部页】中按页号从小到大的第一个“全局初始化”消息
#      等价于 event.msg("全局初始化", false)
#
#   2. 当事件页符合条件并显示时，将自动触发一次【当前页】中的“初始化”消息
#      等价于 event.msg("初始化", true)
#
#      需要在当前事件页里编写以下指令：
#
#        |-标签：初始化
#        |    ...
#        |-标签：END
#
#   3. 当事件位置发生变化时，将自动触发一次【当前页】中的“位置变化”消息
#      等价于 event.msg("位置变化", true)
#
#   - 注意：在调用前会先强制终止本事件已在执行的同名消息！
#
#
# 【事件脚本：仿公共事件调用消息】
#
#   - 编写内容为 msg(LABEL, wait=false) 的事件脚本来调用当前页中的 LABEL 消息
#        若wait传入true，则会等待消息结束，否则继续执行当前事件。
#
#      注意：该调用是直接另开一个并行处理以执行新的消息，
#           当 wait 传入 false 时，当前消息依然继续执行。
#
#
# 【事件脚本：实时判定的消息跳转】
#
#   - 为了制作有限状态机，需要能够实时监测状态之间的切换，
#     本插件添加了实时判定的绑定，能够在每帧更新前，先判定是否发生跳转，
#     若判定成功，则会终止当前消息，并跳转到新消息，开始执行新消息的指令。
#
#   - 利用事件脚本编写一个实时绑定：
#
#        msg_goto(LABEL, COND, V=1)
#
#     其中 LABEL 为需要跳转到的消息的标签名称（字符串）
#        与当前消息的搜索范围保持一致
#     其中 COND 是在 eval 后，若返回 true，则进行跳转的脚本判定内容（字符串）
#        可用 e 代表当前事件Game_Event，gp 代表 $game_player
#             s 代表开关组，v 代表变量组，es 代表 $game_map.events
#     其中 V 是优先级数字，当有多个绑定符合条件时，最大数字的才发生跳转
#
#     之后，每帧都将判定每个绑定是否符合跳转条件。
#
#   - 注意：每次发生跳转后，将清空全部的绑定，且丢弃之前消息的剩余指令。
#      （对于状态机来说，每个状态的跳转情况都应该独立设计。）
#
#
# 【高级：消息的判定与控制】
#
#    event.msg?(LABEL=nil) → 当指定事件正在执行LABEL消息时，返回true
#                         若 LABEL 传入 nil，任一消息正在执行，则返回 true
#
#    event.msg_fin(LABEL=nil) → 强制终止某事件的指定消息
#                         若 LABEL 传入 nil，则终止全部消息
#
#    event.msg_halt(LABEL=nil, t=nil) → 暂时停止LABEL消息的执行，t为暂停的时长
#                         若 LABEL 传入 nil，则为事件的全部消息
#                         若 t 传入 nil，则为一直暂停，直至调用 msg_continue
#       注意：暂停的消息，依然被视作正在执行，即 msg? 判定返回 true。
#
#    event.msg_continue(LABEL=nil) → 继续执行LABEL消息
#                                    若 LABEL 传入 nil，则为事件的全部消息
#
# 【高级：定时触发的消息】
#
#   - 有一些消息可能需要它能够延时执行，但专门为了它去创建全局计时器总有些麻烦，
#     本插件新增了事件的定时消息，在计时归零时，将呼叫指定的消息。
#
#       event.msg_time(LABEL, time[, cur_page])
#
#     其中 time 为帧数，如果传入的是秒数，请自己手动乘以60 （默认帧率）
#
#   - 示例：
#
#       event.msg_time("跳跃", 120)  → 在 120帧（2秒）后触发“跳跃”消息
#
#-----------------------------------------------------------------------------
# ○ 地图的公共事件
#-----------------------------------------------------------------------------
# - 利用脚本调用公共事件中的消息
#
#      $game_map.msg_common(LABLE[, common_event])
#
#    其中 LABEL 同上，与事件中的标签文本完全一致的字符串
#
#    其中 common_event 传入 0 ，将按序查询全部公共事件，并调用第一组匹配
#                      传入数组，将在数组范围内按序查询公共事件，并调用第一组匹配
#                      传入正整数，将在该ID的公共事件内查询
#                      可省略，默认传入 0
#
#    当成功查找到LABEL时，将返回 true 并立即执行；否则返回 false
#
# 【高级】
#
#    $game_map.msg?  → 当公共事件存在任意正在执行的消息时，返回true
#
#-----------------------------------------------------------------------------
# ○ 战斗的敌群事件
#-----------------------------------------------------------------------------
# - 利用脚本调用敌群事件中的消息
#
#      $game_troop.msg(LABEL[, cond_met])
#
#    其中 LABEL 同上，与事件中的标签文本完全一致的字符串
#
#    其中 cond_met 传入 true 时，将只在满足条件的全部事件页中搜索
#                  传入 false 时，将在全部事件页中搜索
#                  可省略，默认传入 true
#
# 【注意】
#
#   1.消息的执行不受战斗系统的等待影响，因此消息中的显示对话可能会覆盖战斗对话
#   （如：技能释放后调用消息并显示文本，而此时敌人全灭，则可能会覆盖胜利结算的对话）
#
# 【高级】
#
#    $game_troop.msg?  → 当敌群存在任意正在执行的消息时，返回true
#
#-----------------------------------------------------------------------------
# ○ 高级
#-----------------------------------------------------------------------------
# - 新增了部分便利的全局方法，用于获取指定对象
#
#    $game_temp.last_menu_item → 获取最近一次在菜单中所使用物品/技能的实例
#
#    $game_map.forward_event_id(chara) → 获取 chara 面前一格事件的ID
#       其中 chara 为 Game_CharacterBase 对象
#       如 $game_player 代表玩家，$game_map.events[id] 代表id号事件
#
#==============================================================================

module EVENT_MSG
  #--------------------------------------------------------------------------
  # ●【常量】设置事件页自动执行的消息的标签名称
  #--------------------------------------------------------------------------
  PAGE_AUTO_INIT_GLOBAL = "全局初始化"
  PAGE_AUTO_INIT = "初始化"
  PAGE_AUTO_POS = "位置变化"

  #--------------------------------------------------------------------------
  # ● 获取指定LABEL的指令序列
  #--------------------------------------------------------------------------
  def self.find_label_list(msg_label, lists)
    list_start = false
    eagle_list = []
    lists.each do |list|
      list.each do |command|
        if command.code == 118
          label = command.parameters[0]
          if list_start
            break if label == "END"
          else
            next list_start = true if label == msg_label
          end
        end
        eagle_list.push(command) if list_start
      end
      break if list_start
    end
    return nil if eagle_list.empty?
    eagle_list.push( RPG::EventCommand.new )
    return eagle_list
  end
#==============================================================================
# ■ 注入用的实例方法
#==============================================================================
module INTO_CLASS
  #--------------------------------------------------------------------------
  # ● 初始化消息
  #--------------------------------------------------------------------------
  def msg_trigger_init
    @eagle_msg_cur_event_id ||= 0
    @eagle_interpreters ||= []
    @eagle_msg_lists = []  # 数据暂存，直接执行的话“初始化”标签就失效了
  end
  #--------------------------------------------------------------------------
  # ● 新增消息
  #--------------------------------------------------------------------------
  def msg_trigger_call(label, lists)
    label = label.to_s
    list = EVENT_MSG.find_label_list(label, lists)
    return false if list == nil
    @eagle_msg_lists.push( [label, list, lists] )
    return true
  end
  #--------------------------------------------------------------------------
  # ● 当前正在执行指定消息？
  #--------------------------------------------------------------------------
  def msg_trigger_running?(label)
    @eagle_interpreters.any? { |i| i.running? && i.eagle_label == label }
  end
  #--------------------------------------------------------------------------
  # ● 更新消息
  #--------------------------------------------------------------------------
  def msg_trigger_update
    @eagle_interpreters.each { |i| i.update }
    if ! @eagle_msg_lists.empty?
      list = @eagle_msg_lists.shift
      i = msg_get_valid_interpreter
      i.eagle_label = list[0]
      i.setup(list[1], @eagle_msg_cur_event_id, list[2])
    end
  end
  #--------------------------------------------------------------------------
  # ● 获取一个可用的解释器
  #--------------------------------------------------------------------------
  def msg_get_valid_interpreter
    @eagle_interpreters.each do |i|
      return i if ! i.running?
    end
    i = Game_Interpreter_EagleMsg.new
    @eagle_interpreters.push(i)
    return i
  end
  #--------------------------------------------------------------------------
  # ● 当前正在执行消息？
  #--------------------------------------------------------------------------
  def msg?(label = nil)
    return true if label.nil? && @eagle_interpreters.any? { |i| i.running? }
    return true if !label.nil? && msg_trigger_running?(label.to_s)
    return false
  end
  #--------------------------------------------------------------------------
  # ● 暂停执行消息
  #--------------------------------------------------------------------------
  def msg_halt(label = nil, t = nil)
    if label == nil
      @eagle_interpreters.each { |i| i.halt = true; i.halt_t = t }
    else
      inters = @eagle_interpreters.select { |i| label == i.eagle_label }
      inters.each { |i| i.halt = true; i.halt_t = t }
    end
  end
  #--------------------------------------------------------------------------
  # ● 继续执行消息
  #--------------------------------------------------------------------------
  def msg_continue(label = nil)
    if label == nil
      @eagle_interpreters.each { |i| i.halt = false }
    else
      inters = @eagle_interpreters.select { |i| label == i.eagle_label }
      inters.each { |i| i.halt = false }
    end
  end
  #--------------------------------------------------------------------------
  # ● 强制中止指定消息
  #--------------------------------------------------------------------------
  def msg_fin(label = nil)
    if label == nil
      @eagle_interpreters.each { |i| i.finish }
    else
      inters = @eagle_interpreters.select { |i| label == i.eagle_label }
      inters.each { |i| i.finish }
    end
  end
  def msg_abort(label = nil); msg_fin(label); end
end # end of INTO_CLASS
#==============================================================================
# ■ Game_Interpreter_EagleMsg
#==============================================================================
class Game_Interpreter_EagleMsg < Game_Interpreter
  attr_accessor  :eagle_label  #（外部修改）当前执行的消息
  attr_accessor  :halt, :halt_t
  #--------------------------------------------------------------------------
  # ● 设置事件
  #--------------------------------------------------------------------------
  def setup(list, event_id = 0, lists = nil)
    # list 是 消息标签 到 第一个END 之间的内容（还额外增加了一个空指令用于结束）
    @lists = lists  # 保存原本的全部指令列表，用于做跳转
    @halt = false
    @halt_t = nil
    @gotos = []  # 绑定的消息跳转
    super(list, event_id)
  end
  #--------------------------------------------------------------------------
  # ● 储存实例
  #    对纤程进行 Marshal 的自定义方法。
  #    此方法将事件的执行位置也一并保存起来。
  #--------------------------------------------------------------------------
  def marshal_dump
    [@depth, @map_id, @event_id, @list, @index + 1, @branch,
     @eagle_label, @lists, @halt, @halt_t, @gotos]
  end
  #--------------------------------------------------------------------------
  # ● 读取实例
  #     obj : marshal_dump 中储存的实例（数组）
  #    恢复多个数据（@depth、@map_id 等）的状态，必要时重新创建纤程。
  #--------------------------------------------------------------------------
  def marshal_load(obj)
    @depth, @map_id, @event_id, @list, @index, @branch, \
    @eagle_label, @lists, @halt, @halt_t, @gotos = obj
    create_fiber
  end
  #--------------------------------------------------------------------------
  # ● 仅在一页事件页中查找？
  #--------------------------------------------------------------------------
  def lists_only_one?
    @lists.size == 1
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    if @halt
      if @halt_t && @halt_t > 0
        @halt_t -= 1
        @halt = false if @halt_t == 0
      end
      return
    end
    check_goto
    super
  end
  #--------------------------------------------------------------------------
  # ● 执行
  #--------------------------------------------------------------------------
  def run
    loop do
      break if @list[@index] == nil
      execute_command
      @index += 1
    end
    Fiber.yield
    @fiber = nil
  end
  #--------------------------------------------------------------------------
  # ● 强制停止
  #--------------------------------------------------------------------------
  def finish
    @fiber = nil
  end
  #--------------------------------------------------------------------------
  # ● 添加标签
  #--------------------------------------------------------------------------
  def command_118
    super
    # 因为执行完成后还会自增1，所以此处需要在开头0的基础上再减1
    @index = -1 if @params[0] == 'RESTART'
  end
  #--------------------------------------------------------------------------
  # ● 转至标签
  #--------------------------------------------------------------------------
  def command_119
    label_name = @params[0]
    @eagle_index_before = @index
    super
    if @eagle_index_before != @index
      return
    end
    if @lists  # 跳转到别的事件消息，同时覆盖当前的执行
      list = EVENT_MSG.find_label_list(label_name, @lists)
      if list
        self.eagle_label = label_name
        setup(list, @event_id, @lists)
      else  # 未找到，报错，并继续当前的执行
        p "【错误】在执行#{@map_id}号地图#{@event_id}号事件的标签跳转：#{label_name}时："
        p " - 未找到目标标签，无法进行事件消息的切换。"
        #@index = @list.size  # 中止事件处理
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 事件脚本-绑定跳转
  #--------------------------------------------------------------------------
  def msg_goto(*args)
    d = Data_EagleMsg_GOTO.new(*args)
    @gotos.push(d)
    # sort_by 默认由小到大排列
    @gotos = @gotos.sort_by { |e| -e.v }
  end
  #--------------------------------------------------------------------------
  # ● 检查跳转
  #--------------------------------------------------------------------------
  def check_goto
    @gotos.each do |d|
      next if eagle_eval(d.cond) != true
      list = EVENT_MSG.find_label_list(d.label, @lists)
      if list
        self.eagle_label = d.label
        setup(list, @event_id, @lists)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 条件判定
  #--------------------------------------------------------------------------
  def eagle_eval(t)
    e = $game_map.events[@event_id]
    s = $game_switches; v = $game_variables
    es = $game_map.events
    gp = $game_player
    begin
      f = eval(t)
      return f == true
    rescue
      p $!
    end
    return false
  end
end # end of Game_Interpreter_EagleMsg
#==============================================================================
# ■ Data_EagleMsg_GOTO
#==============================================================================
class Data_EagleMsg_GOTO
  attr_accessor  :label, :cond, :v
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(*args)
    @label = args[0]
    @cond = args[1] || "false"
    @v = args[2] || 1
  end
end
end # end of EVENT_MSG
#==============================================================================
# ■ Scene_ItemBase
#==============================================================================
class Scene_ItemBase < Scene_MenuBase
  #--------------------------------------------------------------------------
  # ● 公共事件预定判定
  #    如果预约了事件的调用，则切换到地图画面。
  #--------------------------------------------------------------------------
  alias eagle_event_msg_trigger_check_common_event check_common_event
  def check_common_event
    $game_temp.last_menu_item = item
    eagle_event_msg_trigger_check_common_event
  end
end
#==============================================================================
# ■ Game_Temp
#==============================================================================
class Game_Temp
  attr_accessor :last_menu_item
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  alias eagle_event_msg_trigger_init initialize
  def initialize
    eagle_event_msg_trigger_init
    @last_menu_item = nil
  end
end
#==============================================================================
# ■ Game_Troop
#==============================================================================
class Game_Troop < Game_Unit
  include EVENT_MSG::INTO_CLASS
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  alias eagle_event_msg_trigger_init initialize
  def initialize
    msg_trigger_init
    eagle_event_msg_trigger_init
  end
  #--------------------------------------------------------------------------
  # ● 新增消息
  #--------------------------------------------------------------------------
  def msg(label, cond_met = true)
    return true if msg_trigger_running?(label)
    lists = []
    troop.pages.each do |page|
      if cond_met == true
        next unless conditions_met?(page)
      end
      lists.push(page.list)
    end
    return msg_trigger_call(label, lists)
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  alias eagle_event_msg_trigger_update update
  def update
    eagle_event_msg_trigger_update
    msg_trigger_update
  end
end
#==============================================================================
# ■ Game_Map
#==============================================================================
class Game_Map
  include EVENT_MSG::INTO_CLASS
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  alias eagle_event_msg_trigger_init initialize
  def initialize
    msg_trigger_init
    eagle_event_msg_trigger_init
  end
  #--------------------------------------------------------------------------
  # ○ 获取角色面前一格的事件ID
  #--------------------------------------------------------------------------
  def forward_event_id(chara)
    x = $game_map.round_x_with_direction(chara.x, chara.direction)
    y = $game_map.round_y_with_direction(chara.y, chara.direction)
    events = events_xy(x, y)
    return events.empty? ? 0 : events[0].id
  end
  #--------------------------------------------------------------------------
  # ● 新增消息
  #--------------------------------------------------------------------------
  def msg_common(label, common_event_id = 0)
    return true if msg_trigger_running?(label)
    lists = []
    if common_event_id.is_a?(Array)
      common_event_id.each do |i|
        lists.push( $data_common_events[common_event_id].list )
      end
    elsif common_event_id == 0
      $data_common_events.each { |event| lists.push( event.list ) }
    else
      lists.push( $data_common_events[common_event_id].list )
    end
    return msg_trigger_call(label, lists)
  end
  #--------------------------------------------------------------------------
  # ● 更新事件
  #--------------------------------------------------------------------------
  alias eagle_event_msg_trigger_update_events update_events
  def update_events
    eagle_event_msg_trigger_update_events
    msg_trigger_update
  end
end
#==============================================================================
# ■ Game_Event
#==============================================================================
class Game_Event
  include EVENT_MSG::INTO_CLASS
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #     event : RPG::Event
  #--------------------------------------------------------------------------
  def initialize(map_id, event)
    @map_id = map_id  # 为了能调用全局初始化，先存储实例变量
    @event = event
    @id = @event.id
    super()
    @id = @event.id  # 因为父类里初始化了@id，此处需要再赋值一次
    moveto(@event.x, @event.y)
    refresh
  end
  #--------------------------------------------------------------------------
  # ● 初始化私有成员变量
  #--------------------------------------------------------------------------
  alias eagle_event_msg_trigger_init_private_members init_private_members
  def init_private_members
    msg_trigger_init
    @eagle_msg_counts = {}  # msg => [count, cur_page]  # 倒计时归零时调用消息
    eagle_event_msg_trigger_init_private_members
    msg_fin(EVENT_MSG::PAGE_AUTO_INIT_GLOBAL)
    msg(EVENT_MSG::PAGE_AUTO_INIT_GLOBAL, false)
  end
  #--------------------------------------------------------------------------
  # ● 新增消息
  #--------------------------------------------------------------------------
  def msg(label, cur_page = false)
    return true if msg_trigger_running?(label)
    return false if cur_page && @page.nil?
    lists = (cur_page ? [@page.list] : @event.pages.collect { |e| e.list })
    return msg_trigger_call(label, lists)
  end
  #--------------------------------------------------------------------------
  # ● 新增定时消息
  #--------------------------------------------------------------------------
  def msg_time(label, time, cur_page = false)
    @eagle_msg_counts[label] = [time, cur_page]
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  alias eagle_event_msg_trigger_update update
  def update
    msg_trigger_update_position
    eagle_event_msg_trigger_update
    msg_trigger_update
    msg_trigger_update_time
    msg_trigger_update_finish
  end
  #--------------------------------------------------------------------------
  # ● 设置事件页
  #--------------------------------------------------------------------------
  alias eagle_event_msg_trigger_setup_page setup_page
  def setup_page(new_page)
    # 终止全部当前页的消息
    @eagle_interpreters.each { |i| i.finish if i.lists_only_one? }
    eagle_event_msg_trigger_setup_page(new_page)
    @eagle_msg_cur_event_id = @event.id
    msg_fin(EVENT_MSG::PAGE_AUTO_INIT)
    msg(EVENT_MSG::PAGE_AUTO_INIT, true)
  end
  #--------------------------------------------------------------------------
  # ● 位置变动时
  #--------------------------------------------------------------------------
  def msg_trigger_update_position
    if (@eagle_last_x && @eagle_last_x != @real_x) ||
       (@eagle_last_y && @eagle_last_y != @real_y)
      #msg_fin(EVENT_MSG::PAGE_AUTO_POS)  # 1帧内可能判定不完，别强行停止了
      msg(EVENT_MSG::PAGE_AUTO_POS, true)
    end
    @eagle_last_x = @real_x
    @eagle_last_y = @real_y
  end
  #--------------------------------------------------------------------------
  # ● 更新强制停止
  #--------------------------------------------------------------------------
  def msg_trigger_update_finish
    msg_fin(nil) if @erased
  end
  #--------------------------------------------------------------------------
  # ● 更新定时消息
  #--------------------------------------------------------------------------
  def msg_trigger_update_time
    @eagle_msg_counts.each { |sym, v|
      next if msg_trigger_running?(sym)
      if v[0] == 0
        msg(sym, v[1])
        @eagle_msg_counts.delete(sym)
      else
        @eagle_msg_counts[sym][0] -= 1
      end
    }
  end
end
#==============================================================================
# ■ Game_Interpreter
#==============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 事件脚本-调用当前页的消息
  #--------------------------------------------------------------------------
  def msg(label, wait = false)
    e = $game_map.events[@event_id]
    return if e == nil
    e.msg(label, true)
    while e.msg?(label)
      break if wait == false
      Fiber.yield
    end
  end
  #--------------------------------------------------------------------------
  # ● 事件脚本-绑定跳转
  #--------------------------------------------------------------------------
  def msg_goto(*args)
  end
end
