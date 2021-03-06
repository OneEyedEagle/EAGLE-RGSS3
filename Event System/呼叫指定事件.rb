#==============================================================================
# ■ 呼叫指定事件 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
$imported ||= {}
$imported["EAGLE-CallEvent"] = true
#==============================================================================
# - 2021.6.16.20
#==============================================================================
# - 本插件新增了在事件解释器中呼叫任意事件页并执行的事件脚本
#   （与 呼叫公共事件 效果一致，会等待执行结束）
#---------------------------------------------------------------------------
# 【使用：标准参数格式】
#
# - 在事件脚本中，使用如下指令调用指定事件页（整页调用）
#
#      call_event(mid, eid, pid)
#
#   其中 mid 为编辑器中的地图序号（若填入 0，则为当前地图）
#        eid 为编辑器中的事件序号（若填入 0，则为当前事件）
#        pid 为事件编辑器中的页号（若填入 0，则为符合出现条件的最大页号）
#
# 【示例】
#
# - 事件脚本 call_event(0, 5, 0) 为调用当前地图5号事件的当前事件页，并等待结束
#
# - 事件脚本 call_event(1, 2, 1) 为调用1号地图2号事件的1号页，并等待结束
#
# 【注意】
#
# - 具体调用效果同默认事件指令的 呼叫公共事件，当前事件将等待该调用结束
#
# - 被调用的事件页中，全部的【本事件】将替换为当前事件
#
#---------------------------------------------------------------------------
# 【使用：标签格式】
#
# - 在事件脚本中，使用如下指令调用指定事件页
#
#      t = "tags"
#      call_event(t)
#
#   其中 tags 为以下语句的任意组合，用空格分隔
#         等号左右可以添加冗余空格
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
#  【示例】
#
#  - 事件脚本 t = "mid=1 eid=3 pid=2"; call_event(t)
#      为调用1号地图3号事件的2号页的全部指令，并等待结束
#      此句与 call_event(1,3,2) 效果相同
#
#  - 事件脚本 t = "eid=5 sym=调查"; call_event(t)
#    若使用了【事件互动扩展 by老鹰】：
#      为调用当前地图5号事件的当前事件页中的【调查】互动，并等待结束
#    若未使用：
#      为调用当前地图5号事件的当前事件页的全部指令，并等待结束
#
#---------------------------------------------------------------------------
# 【使用：脚本中任意位置】
#
# - 在脚本中，使用如下指令调用指定事件页（参数与上述一致）
#
#      EAGLE.call_event(mid, eid, pid)
#
#      EAGLE.call_event(t)
#
#  【示例】
#
#  - 脚本中编写 EAGLE.call_event(1,3,2)
#      为在当前场景调用1号地图3号事件的2号页的全部指令，并等待结束
#
# 【注意】
#
# - 当不在地图上时，调用事件时，部分与地图相关的指令会被忽略
#
#   以下指令将被忽略：
#     场所移动、地图卷动、设置移动路径、显示动画、显示心情图标、集合队伍成员
#
# - 被调用的事件页中，全部的【本事件】依然为原始事件
#
#=============================================================================

#=============================================================================
# ○ EAGLE - Cache
#=============================================================================
module EAGLE
  #--------------------------------------------------------------------------
  # ● 读取地图
  #--------------------------------------------------------------------------
  def self.cache_load_map(map_id)
    @cache_map ||= {}
    return @cache_map[map_id] if @cache_map[map_id]
    @cache_map[map_id] = load_data(sprintf("Data/Map%03d.rvdata2", map_id))
    @cache_map[map_id]
  end
  #--------------------------------------------------------------------------
  # ● 清空缓存
  #--------------------------------------------------------------------------
  def self.cache_clear
    @cache_map ||= {}
    @cache_map.clear
    GC.start
  end
  #--------------------------------------------------------------------------
  # ● 获取地图数据
  #--------------------------------------------------------------------------
  def self.get_map_data(map_id)
    EAGLE.cache_load_map(map_id)
  end
end
#=============================================================================
# ○ EAGLE
#=============================================================================
module EAGLE
  #--------------------------------------------------------------------------
  # ● 解析tags文本
  #--------------------------------------------------------------------------
  def self.parse_tags(_t)
    # 脚本替换
    _evals = {}; _eval_i = -1
    _t.gsub!(/{(.*?)}/) { _eval_i += 1; _evals[_eval_i] = $1; "<#{_eval_i}>" }
    # 处理等号左右的空格
    _t.gsub!( / *= */ ) { '=' }
    # tag 拆分
    _ts = _t.split(/ | /)
    # tag 解析
    _hash = {}
    _ts.each do |_tag|  # _tag = "xxx=xxx"
      _tags = _tag.split('=')
      _k = _tags[0].downcase
      _v = _tags[1]
      _hash[_k.to_sym] = _v
    end
    # 脚本替换
    _hash.keys.each do |k|
      _hash[k] = _hash[k].gsub(/<(\d+)>/) { _evals[$1.to_i] }
    end
    return _hash
  end
  #--------------------------------------------------------------------------
  # ● 呼叫指定事件 - 解析参数
  #--------------------------------------------------------------------------
  def self.call_event_args(args)
    h = {}
    if args.size == 1
      # 当只传入1个参数时，认定为tag字符串
      _h = EAGLE.parse_tags(args[0])
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
      map = EAGLE.get_map_data(h[:mid])
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
      message_window = Window_Message.new
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
        SceneManager.scene.update
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
end
