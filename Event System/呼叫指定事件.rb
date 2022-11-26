#==============================================================================
# ■ 呼叫指定事件 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【组件-通用方法汇总 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-CallEvent"] = "1.2.2"
#==============================================================================
# - 2022.11.26.14 修复在战斗场景中卡死的bug
#==============================================================================
# - 本插件新增了在事件解释器中呼叫任意事件页并执行的事件脚本
#   （与 呼叫公共事件 效果一致，会等待执行结束）
# - 本插件新增了事件页的插入，通过注释，可以把指定事件页的全部内容黏贴到注释位置
#   （就仿佛一开始编写了这些指令，可以确保像是【事件消息机制】等能够找到标签）
#---------------------------------------------------------------------------
# 【使用：标准参数格式】
#
# - 在事件脚本中，使用如下指令调用指定事件页（整页调用）：
#
#      call_event(mid, eid, pid)
#
#   其中 mid 为编辑器中的地图序号（若填入 0，则为当前地图）
#        eid 为编辑器中的事件序号（若填入 0，则为当前事件）
#        pid 为事件编辑器中的页号（若填入 0，则为符合出现条件的最大页号）
#
# - 示例：
#
#  · 事件脚本 call_event(0, 5, 0) 为调用当前地图5号事件的当前事件页，并等待结束
#
#  · 事件脚本 call_event(1, 2, 1) 为调用1号地图2号事件的1号页，并等待结束
#
# - 注意：
#
#  · 具体调用效果同默认事件指令的 呼叫公共事件，当前事件将等待该调用结束
#
#  · 被调用的事件页中，全部的【本事件】将替换为当前事件
#
#---------------------------------------------------------------------------
# 【使用：标签字符串格式】
#
# - 在事件脚本中，使用如下指令调用指定事件页：
#
#      t = "tags"
#      call_event(t)
#
#   其中 tags 为以下语句的任意组合，用空格分隔
#       （等号左右可以添加冗余空格）
#
#      mid=数字  → 数字 替换为编辑器中的地图序号
#                 （若填入 0，或不写该语句，则取当前地图）
#                 （若填入 -1，则取公共事件）
#      eid=数字  → 数字 替换为编辑器中的事件序号
#                 （若填入 0，或不写该语句，则取当前事件）
#      pid=数字  → 数字 替换为事件编辑器中的页号
#                 （若填入 0，或不写该语句，则取符合出现条件的最大页号）
#
#   （若使用了【事件互动扩展 by老鹰】，可使用下述标签）
#      sym=字符串 → 字符串 替换为目标事件中的互动标签
#                 （若不写该语句，默认执行整个事件页）
#
# - 示例：
#
#  · 事件脚本 t = "mid=1 eid=3 pid=2"; call_event(t)
#      为调用1号地图3号事件的2号页的全部指令，并等待结束
#      此句与 call_event(1,3,2) 效果相同
#
#  · 事件脚本 t = "eid=5 sym=调查"; call_event(t)
#    若使用了【事件互动扩展 by老鹰】：
#      为调用当前地图5号事件的当前事件页中的【调查】互动，并等待结束
#    若未使用：
#      为调用当前地图5号事件的当前事件页的全部指令，并等待结束
#
#---------------------------------------------------------------------------
# 【使用：脚本中任意位置】
#
# - 在脚本中，使用如下指令调用指定事件页（参数与上述一致）：
#
#      EAGLE.call_event(mid, eid, pid)
#
#      EAGLE.call_event(t)
#
# - 示例：
#
#  · 脚本中编写 EAGLE.call_event(1,3,2)
#      为在当前场景调用1号地图3号事件的2号页的全部指令，并等待结束
#
# - 注意：
#
#  · 当不在地图上时，调用事件时，部分与地图相关的指令会被忽略
#
#    以下指令将被忽略：
#      场所移动、地图卷动、设置移动路径、显示动画、显示心情图标、集合队伍成员
#
#  · 被调用的事件页中，全部的【本事件】依然为原始事件
#
#---------------------------------------------------------------------------
# 【使用：事件页替换】
#
# - 考虑到有些插件会依据事件页中存在的指令来进行设置，比如【事件消息机制 by老鹰】，
#    就是检查事件页的指令列表中，是否含有指定名称的“标签”。
#
#   但呼叫指定事件只能保证事件的执行，而无法帮助这些插件进行它们的设置。
#
#   因此增加该功能，可以在事件生成时，依据指定注释指令进行指令的替换，
#    把目标事件页完整的复制到该注释的位置处，就仿佛一开始便写了这一些指令在事件页中。
#
# - 在事件指令-注释中，编写该样式文本：
#
#       事件页替换|tag字符串
#
#    其中 事件页替换 为固定的识别文本，不可缺少
#    其中 tag字符串 与上述介绍保持一致
#
# - 示例：
#
#   · 事件注释 “事件页替换|mid=1 eid=2 pid=1”
#      为在该注释位置处，插入1号地图2号事件的1号页的全部指令
#
# - 注意：
#
#   · 请确保每个注释指令中，只含有一个事件页替换
#
#=============================================================================
module EAGLE
  #--------------------------------------------------------------------------
  # ○【常量】事件指令-注释 中进行事件页替换的文本
  #--------------------------------------------------------------------------
  COMMENT_PAGE_REPLACE = /^事件页替换 *?\| *?(.*)/mi
  #--------------------------------------------------------------------------
  # ○ 处理事件指令的替换
  #--------------------------------------------------------------------------
  def self.process_page_replace(event, list)
    index = 0
    while(true)
      index_start = index
      command = list[index]
      index += 1
      break if command.code == 0
      next if command.code != 108
      # 获取完整的注释内容
      comments = [command.parameters[0]]
      while list[index + 1] && list[index + 1].code == 408
        index += 1
        comments.push(list[index].parameters[0])
      end
      index_end = index
      t = comments.inject { |t, v| t = t + "\n" + v }
      # 检查是否存在事件页替换
      t =~ EAGLE::COMMENT_PAGE_REPLACE
      if $1
        ps = $1.strip  # tags string  # 去除前后空格
        h = call_event_args([ps])
        next if h == nil
        page = call_event_page(h)
        list2 = page.list
        # 去除结尾的空指令
        list2.pop if list2[-1].code == 0
        # 加入到当前列表
        list.insert(index, list2)
        list.flatten!
        # 删去注释指令
        d = index_end - index_start
        d.times { list.delete_at(index_start) }
      end
    end
    return list
  end

  #--------------------------------------------------------------------------
  # ● 呼叫指定事件 - 解析参数
  #--------------------------------------------------------------------------
  def self.call_event_args(args)
    h = {}
    if args.size == 1
      # 当只传入1个参数时，认定为tag字符串
      _h = EAGLE_COMMON.parse_tags(args[0])
      h.merge!(_h)
      h[:mid] = h[:mid].to_i if h[:mid]
      h[:eid] = h[:eid].to_i if h[:eid]
      h[:pid] = h[:pid].to_i if h[:pid]
    elsif args.size == 3
      # 当传入3个参数时，认定为 地图ID，事件ID，页ID
      h[:mid] = args[0]
      h[:eid] = args[1]
      h[:pid] = args[2]
    else
      # 否则返回nil，在调用处进行报错提示
      return nil
    end
    return h
  end
  #--------------------------------------------------------------------------
  # ● 呼叫指定事件 - 获取事件页
  #--------------------------------------------------------------------------
  def self.call_event_page(h)
    event = nil
    if h[:mid] == -1
      return $data_common_events[h[:eid]]
    end
    if h[:mid] != $game_map.map_id
      map = EAGLE_COMMON.get_map_data(h[:mid])
      event_data = map.events[h[:eid]] rescue return
      event = Game_Event.new(h[:mid], event_data)
    else
      event = $game_map.events[h[:eid]] rescue return
    end
    page = nil
    if h[:pid] == nil || h[:pid] == 0
      page = event.find_proper_page
    else
      page = event.event.pages[h[:pid]-1] rescue return
    end
    return page
  end
  #--------------------------------------------------------------------------
  # ● 呼叫指定事件 - 任意时刻调用
  #--------------------------------------------------------------------------
  def self.call_event(*args)
    h = EAGLE.call_event_args(args)
    if h == nil
      p "【警告】执行 EAGLE.call_event 时发现参数数目有错误！"
      p "EAGLE.call_event 来自于脚本【呼叫指定事件 by老鹰】，" +
        "请仔细阅读脚本说明并进行修改！"
      return false
    end
    h[:mid] = $game_map.map_id if h[:mid] == nil || h[:mid] == 0
    page = EAGLE.call_event_page(h)
    return if page == nil
    # 实际执行
    if SceneManager.scene_is?(Scene_Map) # 如果在地图上
      interpreter = Game_Interpreter.new
    else # 如果在其他场景
      interpreter = Game_Interpreter_EagleCallEvent.new
      message_window = Window_EagleMessage.new if $imported["EAGLE-MessageEX"]
      message_window ||= Window_Message.new
    end
    interpreter.setup(page.list, h[:eid])
    if $imported["EAGLE-EventInteractEX"]
      interpreter.event_interact_search(h[:sym]) if h[:sym]
    end
    if SceneManager.scene_is?(Scene_Map) # 如果在地图上
      while true
        SceneManager.scene.update
        interpreter.update
        break if !interpreter.running?
      end
    else # 如果在其他场景
      while true
        SceneManager.scene.update_basic
        interpreter.update
        message_window.update
        break if !interpreter.running?
      end
      message_window.dispose if message_window
    end
    return true
  end
end
#===============================================================================
# ○ 定制的Game_Interpreter
#===============================================================================
class Game_Interpreter_EagleCallEvent < Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 场所移动
  #--------------------------------------------------------------------------
  def command_201
  end
  #--------------------------------------------------------------------------
  # ● 地图卷动
  #--------------------------------------------------------------------------
  def command_204
  end
  #--------------------------------------------------------------------------
  # ● 设置移动路径
  #--------------------------------------------------------------------------
  def command_205
  end
  #--------------------------------------------------------------------------
  # ● 显示动画
  #--------------------------------------------------------------------------
  def command_212
  end
  #--------------------------------------------------------------------------
  # ● 显示心情图标
  #--------------------------------------------------------------------------
  def command_213
  end
  #--------------------------------------------------------------------------
  # ● 集合队伍成员
  #--------------------------------------------------------------------------
  def command_217
  end
end
#===============================================================================
# ○ Game_Interpreter
#===============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 呼叫指定事件
  #--------------------------------------------------------------------------
  def call_event(*args)
    h = EAGLE.call_event_args(args)
    if h == nil
      p "【警告】执行 #{@map_id} 号地图 #{@event_id} 号事件中" +
        "事件脚本 call_event 时发现参数数目有错误！"
      p "事件脚本 call_event 来自于脚本【呼叫指定事件 by老鹰】，" +
        "请仔细阅读脚本说明并进行修改！"
      return false
    end
    h[:mid] = $game_map.map_id if h[:mid] == nil || h[:mid] == 0
    h[:eid] = @event_id if h[:eid] == nil || h[:eid] == 0
    page = EAGLE.call_event_page(h)
    return false if page == nil
    # 实际调用
    child = Game_Interpreter.new(@depth + 1)
    child.setup(page.list, @event_id)
    if $imported["EAGLE-EventInteractEX"]
      child.event_interact_search(h[:sym]) if h[:sym]
    end
    child.run
    return true
  end
end
#===============================================================================
# ○ Game_Event
#===============================================================================
class Game_Event < Game_Character
  attr_reader :event
  #--------------------------------------------------------------------------
  # ● 设置事件页的设置
  #--------------------------------------------------------------------------
  alias eagle_page_replace_setup_page_settings setup_page_settings
  def setup_page_settings
    @list = list = EAGLE.process_page_replace(self, @page.list)
    eagle_page_replace_setup_page_settings
    @list = list  # 覆盖掉其它插件可能的修改
  end
end
