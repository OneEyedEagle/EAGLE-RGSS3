#==============================================================================
# ■ 事件页替换VX by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【组件-通用方法汇总 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-ReplaceEventCommand"] = "1.0.0"
#==============================================================================
# - 2025.9.8.23
#==============================================================================
# - 本插件新增了事件页的插入，通过注释，可以把指定事件页的全部内容黏贴到注释位置
#   （就仿佛一开始编写了这些指令，可以确保像是【事件消息机制】等能够找到标签）
#---------------------------------------------------------------------------
# 【使用】
#
# - 考虑到有些插件会依据事件页中存在的指令来进行设置，比如【事件消息机制 by老鹰】，
#    就是检查事件页的指令列表中，是否含有指定名称的“标签”。
#
#   因此增加该功能，可以在事件生成时，依据指定注释指令进行指令的替换，
#    把目标事件页完整的复制到该注释的位置处，就仿佛一开始便写了这一些指令在事件页中。
#
# - 在事件指令-注释中，编写该样式文本：
#
#       事件页替换|tag字符串
#
#    其中 事件页替换 为固定的识别文本，不可缺少
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
  #COMMENT_PAGE_REPLACE = /^事件页替换 *?\| *?(.*)/mi
  COMMENT_PAGE_REPLACE = /^sub event *?\| *?(\d+), *(\d+), *(\d+)/mi
  #--------------------------------------------------------------------------
  # ○ 处理事件指令的替换
  #--------------------------------------------------------------------------
  def self.process_page_replace(event, list)
    index = 0
    while(true)
      index_start = index
      command = list[index]
      index += 1
      break if command == nil
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
        #ps = [$1.strip]  # tags string  # 去除前后空格
        ps = [$1.to_i, $2.to_i, $3.to_i]
        h = call_event_args(ps)
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
    h[:mid] = $game_map.map_id if h[:mid] == 0
    map = EAGLE_COMMON.get_map_data(h[:mid])
    event_data = map.events[h[:eid]] rescue return
    event = Game_Event.new(h[:mid], event_data)
    page = nil
    if h[:pid] == nil || h[:pid] == 0
      page = event.find_proper_page
    else
      page = event.event.pages[h[:pid]-1] rescue return
    end
    return page
  end
end
#===============================================================================
# ○ Game_Event
#===============================================================================
class Game_Event < Game_Character
  attr_reader :event
  #--------------------------------------------------------------------------
  # ● 设置事件页
  #--------------------------------------------------------------------------
  alias eagle_page_replace_setup setup
  def setup(new_page)
    eagle_page_replace_setup(new_page) 
    @list = EAGLE.process_page_replace(self, @page.list) if @page
  end
end
