#==============================================================================
# ■ Add-On 并行对话 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【鹰式对话框扩展 V2.0】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-MessagePara"] = "2.2.0"
#==============================================================================
# - 2026.2.22.11 随对话框更新
#==============================================================================
# - 本插件利用【鹰式对话框扩展】中的对话框，设计了能够并行显示的对话框。

#--------------------------------------------------------------------------
# ○ 概念：标签序列
#--------------------------------------------------------------------------
# - 标签序列是由 标签/标签对 任意排列组成的字符串。
#
# - 与事件页中的指令类似，将按顺序逐个解析并执行。
#
# - 但因为是字符串，能够方便编辑、导出、复用。
#
# - 注意：
#
#    · 在实际解析前，将拷贝【鹰式对话框扩展】中的 0 号环境 作为初始状态。
#    · 以下所有 标签/标签对 需要使用小写字母。

#==============================================================================
#                              ■ 标签/标签对一览 ■ 
#==============================================================================
module MESSAGE_PARA

# -────────────────────────────────────────-
# 1▍ 打开对话框
# -────────────────────────────────────────-

#  ● <msg>string</msg>
   
#  · string  → 对话文本。
#              可以使用【鹰式对话框扩展】中的转义符。
#              因为没有金钱窗口，故【不可】使用 \$ 转义符！

#  □ 注意 ：当解析该标签对时，将暂停，直至对话框关闭。

#  ？ 示例
#        <msg>这是一句测试用的文本，感觉没啥特别的哈！</msg>

# -────────────────────────────────────────-
# 2▍ 设置下一个对话框的脸图
# -────────────────────────────────────────-

#  ● <face>
   
#       → 重置脸图参数，下一个对话框变为无脸图。

#  ● <face face_name[ face_index]>

#       → 下一个对话框显示的脸图为 face_name 文件中的第 face_index 个。
#         其中 face_index 可省略，默认 0。

#  □ 注意 ：脸图文件放在 Graphics/Faces 目录下，且文件名中不可含有空格。
#  □ 注意 ：支持【鹰式对话框扩展】中对脸图格式的扩展！

#  ？ 示例
#        <face actor1 0>  → 下一个对话框将显示 actor1 脸图中的第 1 个脸图。

# -────────────────────────────────────────-
# 3▍ 设置下一个对话框的参数
# -────────────────────────────────────────-

#  ● <msgp param_str>

#       → 设置对话框的参数

#  ◇ 预设参数          ▼ [param_str]“参数串”一览（字母+数字组合）
  PARA_MESSAGE_PARAMS = {
    :bg   => 0,      # 对话框的背景类型（0普通，1暗色，2透明）
    :pos  => 2,      # 对话框的位置类型（0居上，1居中，2居下）
    :w    => -1,     # 对话框绘制完成后、关闭前的等待帧数
                     #  * -1 → 不自动关闭，按确定键才关闭
    :t    => 1,      # 对话框关闭后的等待帧数
    :z    => 100,    # 对话框的z值
  }

#  ？ 示例
#      <msgp w=20>  → 之后的对话框在绘制完成后，将额外等待20帧才会自动关闭

# -────────────────────────────────────────-
# 4▍ 显示动画（仅地图上有效）
# -────────────────────────────────────────-

#  ● <anim chara_index animation_id[ wait]>

#       → 在指定角色上显示动画。

#   其中 chara_index 为指定的事件/角色的序号：
#     正数 → 地图事件中 指定ID 的事件；
#      0   → 当前并行对话绑定的事件（仅地图上事件页注释所激活的并行对话有效）；
#     负数 → 玩家队伍中 数据库ID 为该负数绝对值的角色，若不存在则取队首。

#   其中 animation_id 为数据库中指定动画的ID号（从1开始）。

#   其中[ wait] 为可选项：
#     不写 → 则不等待，直接执行之后的指令；
#     正数 → 等待该帧数，再继续之后的指令；
#      0   → 需要等待动画播放结束，才继续之后的指令。

#  ？ 示例
#      <anim -1 1 0> → 玩家队伍中的1号角色显示1号动画，且等待动画结束。

# -────────────────────────────────────────-
# 5▍ 显示心情气泡（仅地图上有效）
# -────────────────────────────────────────-

#  ● <balloon chara_index balloon_id[ wait]>

#       → 在指定角色上显示心情气泡。

#   其中 balloon_id 为心情气泡的ID号（从1开始）。

#   其中[ wait] 同上。

#  ？ 示例
#       <balloon 0 1>  → 当前事件显示1号气泡，不等待，继续之后的标签。

# -────────────────────────────────────────-
# 6▍ 等待
# -────────────────────────────────────────-

#  ● <wait count>

#       → 等待 count 帧数，再继续执行之后的标签

#  ？ 示例
#       <wait 60> → 等待 1 秒，然后再继续之后的标签。

# -────────────────────────────────────────-
# 7▍ 等待直至条件满足
# -────────────────────────────────────────-

#  ● <until>str</until>

#       → 等待，直至 eval(str) 返回 true 。

#   其中 str 中可用 s 代替 $game_switches， v 代替 $game_variables
#              pl 代替 $game_player， e 代替 当前事件 或 当前敌人

#  ？ 示例
#       <until>s[1]</until> → 等待，直至1号开关开启，再继续之后的标签。

# -────────────────────────────────────────-
# 8▍ 跳过下一个标签
# -────────────────────────────────────────-

#  ● <if>str</if>

#       → 如果 eval(str) 返回 false，则跳过下一个标签。

#  ？ 示例
#       <if>v[1] > 5</if> → 如果1号变量的值小于等于5，则跳过下一个标签。

# -────────────────────────────────────────-
# 9▍ 直接结束
# -────────────────────────────────────────-

#  ● <break>

#       → 直接结束当前序列

# -────────────────────────────────────────-
# 10▍ 执行脚本
# -────────────────────────────────────────-

#  ● <rb>str</rb>

#       → 执行Ruby脚本，与 eval(str) 效果一致

# -────────────────────────────────────────-
# 11▍ 呼叫预设的“标签序列”
# -────────────────────────────────────────-

#  ● <call list_name>

#       → 呼叫预设的“标签序列”
#         在文本文件预设的序列中查找名称为 list_name 的序列，并开始解析它。

# -────────────────────────────────────────-
# 12▍ 切换按键继续的允许状态
# -────────────────────────────────────────-

#  ● <toggleinput>

#       → 如果 NEXT_BY_KEY 为true，则该标签之后的对话将自动继续。
#         如果 NEXT_BY_KEY 为false，则该标签之后的对话将按键才能继续。

#     ---------------------------------------------------------------------
#  ◇ 是否需要按确定键继续对话？
#  ├   true  → 需要按键才能继续对话
#      false → 自动继续对话
  NEXT_BY_KEY = true

#==============================================================================
#                            ■ “标签序列”的执行 ■ 
#==============================================================================

#  ◇ 强制结束全部标签序列的开关
#  ├  该序号开关打开时，将结束全部标签序列，并且不再生成新对话
  S_ID_NO_MSG = 0

# -────────────────────────────────────────-
# 1▍ 利用全局脚本执行一次
# -────────────────────────────────────────-

#   MESSAGE_PARA.add(name, list_str[, ensure_fin])
#
#    其中 name 为任意的唯一标识符（若已有重名序列，则之前的会被强制结束）。
#       推荐使用 Symbol 或 String 类型。

#    其中 list_str 为 “标签序列” 字符串（注意！转义符需要用 \\ 代替 \）。

#   【可选】ensure_fin 传入 true 时，将保证该标签序列必定执行完成。
#       （默认 false，场所移动 / Scene切换时将强制结束。）

#  ？ 示例
#     MESSAGE_PARA.add(:test, "<call test1><msg>...</msg>")
#       → 生成一个占位 :test 的标签序列，内容如字符串，
#         并立即开始更新，但场景切换时将直接结束。

# -────────────────────────────────────────-
# 2▍ 征用 事件指令-滚动文本 执行一次
# -────────────────────────────────────────-

#  ◇ 征用 事件指令-滚动文本 的启用开关
#  ├  该序号开关打开时，事件指令-滚动文本将被作为“标签序列”读入并执行一次。
#     推荐给该开关命名为：滚动文本→并行对话
  S_ID_SCROLL_TEXT = 19

#  ├ 格式说明：
#
#  1. 第一行文本 固定为 唯一标识符name 。

#  2. 禁止快进选项，将作为 ensure_fin 参数传入，
#     即如果勾选，则该标签序列必定执行完成（场景切换后也会继续执行）。
#
#  □ 注意 ：其中的转义符按正常方式进行编写。

# -────────────────────────────────────────-
# 3▍ 在地图事件页编写可执行多次的
# -────────────────────────────────────────-

#   事件页第一个指令为 注释 时，按下述格式编写“标签序列”：
#
#        <list[ 'name'][ {cond}][ params]>...</list>
#
#   其中 ... 替换成“标签序列”（转义符按照正常写法）。
#
#  【可选】'name' 替换成该“标签序列”的唯一标识符（强制为字符串形式）。
#      若不写，则为当前事件的ID（数字形式）。
#
#  【可选】{cond} 替换成触发条件，被 eval 后返回 true 才会触发。
#      若不写，则默认为 true，即自动触发。
#      可用 s 代替 $game_switches， v 代替 $game_variables
#          pl 代替 $game_player， a 代表当前事件 $game_map.events[@event_id]
#          e 代替 $game_map.events 或 $game_troop.members
#          d 代替 a.distance_to(0)，即当前事件与玩家的距离|dx|+|dy|的值

#  【可选】params 替换成 变量名+参数值 的字符串。

#  ◇ 预设参数         ▼ [param]“参数串”一览（字母+数字组合）
  EVENT_PARAMS = {
    :f => 1,     # 当cond条件不满足时，是否立即结束显示？
    :w => 60,    # 显示结束后需再等待w帧，才能再次触发。
                 #  * nil($) → 与事件暂时消除类似，直至下次回到该地图前不再触发。
  }

#  ？ 示例（无参数）
#      <list><msg>第一句台词</msg><msg>第二句台词</msg></list>
#         → 该事件页增加 name 为事件ID数字，自动循环执行的对话组，
#           使用当前对话框的参数，依次显示这两句台词。

#  ？ 示例（含参数）
#      <list {s[1]} w$>...</list> 
#           → 当1号开关开启时，显示一次，直到重新回到该地图。
#      <list 'DEMO' {d<=3}>...</list> 
#           → 设置玩家与事件间的距离不大于3时触发。
#      <list {v[1]>0} f0w60>...</list> 
#           → 当1号变量大于0，自动循环显示，间隔60帧，
#             且不会因为条件不满足而强制结束。

#  □ 注意 ：
#    1. 若文本量超出单个注释窗口，可以拆分成多个连续的 注释 指令，将一并读取。
#    2. 对于每个事件，同时只会执行一个并行对话。
#    3. 当事件被触发时，它正在执行的并行对话将被强制结束，且不会再次生成。
#    4. 事件的并行对话占用了 事件ID（数字）的唯一标识符，
#       因此请尽量不要使用 数字ID 作为 name 来命名自己的“标签序列”。


#==============================================================================
#                            ■ “标签序列”的预设 ■ 
#==============================================================================

# -────────────────────────────────────────-
# 1▍ 利用全局脚本预设（不存入存档）
# -────────────────────────────────────────-

#    MESSAGE_PARA.reserve(name, list_str)

#  其中 name 为任意的唯一标识符（将覆盖原有的同名预设）。
#  其中 list_str 为“标签序列”字符串（注意：转义符需要用 \\ 代替 \）。

#  可用脚本呼叫预设的“标签序列”（只执行一次）
#
#    MESSAGE_PARA.call(name, [, ensure_fin])

# -────────────────────────────────────────-
# 2▍ 利用文本文件预设
# -────────────────────────────────────────-

#  ◇ 文本文件 的数组
#  ├  路径和文件名之间用 / 分隔，文件名要带有后缀名。
#  ├  文件不局限于.txt，只要其中只包含 UTF-8 编码的文本，可以为任意后缀名。
#  ├  在游戏开启时将按序读入。
#  ├  若使用了【组件-读取加密档案中的TXT by老鹰】，则可将其放置于加密路径下。
  FILES_MSG_LIST = ["Eagle/PARA.eagle"]

#  ├ 格式说明：
#
#  1. 按 <list name>...</list> 格式，可反复编写多个“标签序列”。
#
#     其中 name 替换成该“标签序列”的唯一名称，便于进行调用。
#     其中 ... 替换成“标签序列”（转义符正常写法）。
#

#==============================================================================
#                            ■ “标签序列”的控制 ■ 
#==============================================================================

# -────────────────────────────────────────-
# 1▍ 锁定
# -────────────────────────────────────────-

#   MESSAGE_PARA.lock(type) → 添加以 type 为名称的锁

#   MESSAGE_PARA.unlock(type) → 解除以 type 为名称的锁

#  □ 注意 ：当存在任一锁时，将不会生成任何新的并行对话。

# -────────────────────────────────────────-
# 2▍ 强制结束
# -────────────────────────────────────────-

#   MESSAGE_PARA.list_finish(name[, force])

#     → 结束名称为 name 的“标签序列”。
#       若 force 传入 true，则不进行移出，而是直接隐藏，
#        默认 force 为 false，即保留对话框的关闭。

#   MESSAGE_PARA.all_finish(force = false)

#     → 移出全部并行对话。

#==============================================================================
#                                 × 设定完毕 × 
#==============================================================================
end

#==============================================================================
# ○ 【读取部分】
#==============================================================================
module EAGLE
  # 读取事件页开头的注释组
  def self.event_comment_head(command_list)
    return "" if command_list.nil? || command_list.empty?
    t = ""; index = 0
    while command_list[index].code == 108 || command_list[index].code == 408
      t += command_list[index].parameters[0]
      index += 1
    end
    t
  end

  # 读取TXT文本
  if !$imported["EAGLE-LoadTXT"]
  def self.load_text(filename)
    text = ""
    File.open(filename, 'r') { |f| f.each_line { |l| text += l } }
    text.encode("UTF-8")
  end
  end
end

#==============================================================================
# ○ 并行对话模块
#==============================================================================
module MESSAGE_PARA
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def self.init
    @lists = {} # 存储当前正在更新的并行对话列表
    @lock_count = [] # 当前锁定类型汇总
    @lists_strs = {} # 存储预读取的全部对话序列 name_sym => list_msg
    FILES_MSG_LIST.each do |filename|
      @lists_strs.merge!( parse_list_file(filename) )
    end
  end

  # 解析含“标签序列”的文本文件
  # hash - 存储解析出的全部 name => [cond_string, 并行对话文本list_msg]
  def self.parse_list_file(filename)
    hash = {}
    text = EAGLE.load_text(filename) rescue ""
    text.scan(/<list ?(.*?)>(.*?)<\/list>/m).each do |params|
      hash[ params[0].to_sym ] = params[1]
    end
    hash
  end

  #--------------------------------------------------------------------------
  # ● 呼叫预设的“标签序列”
  #--------------------------------------------------------------------------
  def self.call(name_sym, ensure_fin = false)
    name_sym = name_sym.to_sym if !name_sym.is_a?(Symbol)
    v = get_list_str(name_sym)
    return if v == ""
    add(name_sym, v, ensure_fin)
  end

  # 读取预设的“标签序列”字符串
  def self.get_list_str(sym)
    @lists_strs[sym] || ""
  end

  # 保存“标签序列”到预设
  def self.reserve(id, list_str)
    @lists_strs[id] = list_str
  end

  #--------------------------------------------------------------------------
  # ● 呼叫“标签序列”
  #--------------------------------------------------------------------------
  # list_str - "<msg>foo</msg><msg>foo</msg>"
  def self.add(id, list_str, ensure_fin = false)
    return false if lock?
    @lists[id].finish(true).dispose if @lists[id]
    @lists[id] = MessagePara_List.new(id, list_str)
    @lists[id].f_ensure_fin = ensure_fin
    return true
  end

  #--------------------------------------------------------------------------
  # ● 控制
  #--------------------------------------------------------------------------
  # 指定对话组存在？
  def self.list_exist?(id)
    @lists.has_key?(id)
  end

  # 直接结束
  #  force - 是否强制立即关闭（取消移出特效）
  def self.list_finish(id, force = false)
    return if !list_exist?(id)
    @lists[id].finish(force)
  end

  # 全部强制结束
  def self.all_finish(force = false)
    @lists.each { |id, l| l.finish(force) }
  end

  # 全部结束（除了保证显示完的list）
  def self.all_finish_sys(force = false)
    @lists.each do |id, l|
      next l.halt if l.f_ensure_fin
      l.finish(force)
    end
  end

  # 全部继续
  def self.all_go_on
    @lists.each { |id, l| l.go_on }
  end

  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def self.update
    update_lock
    @lists.each { |id, l| l.update }
    @lists.delete_if { |id, l| f = l.finish?; l.dispose if f; f }
  end

  # 更新锁定
  def self.update_lock
    if $game_switches[S_ID_NO_MSG]
      return if lock?
      all_finish_sys
      lock
    else
      return if !lock?
      unlock
    end
  end

  # 锁定
  def self.lock(type = :switch)
    @lock_count.push(type)
  end
  # 解锁
  def self.unlock(type = :switch)
    @lock_count.delete(type)
  end
  # 锁定？
  def self.lock?
    !@lock_count.empty?
  end
end

#==============================================================================
# ○ 并行对话列表
#==============================================================================
class MessagePara_List # 该list中每一时刻只显示一个对话框
  attr_reader    :game_message, :params
  attr_accessor  :f_ensure_fin
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize(id, list_str)
    @id = id
    @list_str = list_str   # 待处理的标签队列
    @game_message = $game_system.message_envs['0'].clone2
    @game_message.clear
    @face = ["", 0]
    @params = MESSAGE_PARA::PARA_MESSAGE_PARAMS.dup
    @params[:id] = id
    @params[:input] = MESSAGE_PARA::NEXT_BY_KEY
    @window = Window_EagleMessage_Para.new(self)
    @f_ensure_fin = false # 保证必定显示完？（场景切换时只暂时暂停并关闭）
    
    @fiber = Fiber.new { fiber_main }
    @finish = false # 结束的标志
  end

  # 释放
  def dispose
    @window.dispose if @window
    @window = nil
  end

  # 更新
  def update
    @window.update if @window
    @fiber.resume if @fiber
  end

  # 结束？
  def finish?
    @fiber == nil
  end

  #--------------------------------------------------------------------------
  # ● 外部控制
  #--------------------------------------------------------------------------
  # 暂停
  def halt
    @params[:halt] = true
  end

  # 继续
  def go_on
    @params[:halt] = false
  end

  # 结束
  def finish(force = false)
    @finish = true
    if @window
      if force
        @window.finish_force
      else
        @window.finish
      end
    end
    self
  end

  #--------------------------------------------------------------------------
  # ● 主逻辑
  #--------------------------------------------------------------------------
  def fiber_main
    Fiber.yield
    parse_list while !@list_str.empty?
    dispose
    @fiber = nil
  end

  # 解析序列字符串
  def parse_list
    tag_name, tag_str = parse_next_tag
    method_name = "tag_" + tag_name
    send(method_name, tag_str) if respond_to?(method_name)
    process_finish if @finish
  end
  # 如果中途结束的处理
  def process_finish
    @list_str.clear
  end

  # 解析下一个标签（移除首位的非标签内容）
  def parse_next_tag
    i = 0; s = @list_str.size
    while @list_str[i] != '<'
      i += 1
      return @list_str.clear if i == s
    end
    @list_str = @list_str[i..-1]
    @list_str.slice!(/<(.*?)>/)
    str = $1
    # tag_name 为标签中的标识符
    tag_name = str.slice!(/\w+/)
    # tag_str 为标签中标识符以外的字符
    tag_str = str.lstrip # 去除前后的多余空格
    return tag_name, tag_str
  end

  # 标签：开启对话框
  def tag_msg(tag_str)
    @list_str.slice!(/^(.*?)<\/msg>/m)
    set_new_window($1)
    Fiber.yield while @game_message.visible
  end
  # 预定对话
  def set_new_window(text)
    @game_message.clear
    @game_message.add(text)
    @game_message.face_name = @face[0]
    @game_message.face_index = @face[1]
    @game_message.background = @params[:bg]
    @game_message.position = @params[:pos]
    @game_message.win_params[:z] = @params[:z]
    @game_message.visible = true
  end

  # 标签：预设脸图参数
  def tag_face(tag_str)
    ps = tag_str.split(' ')
    @face[0] = (ps[0] ? ps[0] : "")
    @face[1] = (ps[1] ? ps[1].to_i : 0)
  end

  # 标签：预设对话框参数
  def tag_msgp(tag_str)
    MESSAGE_EX.parse_param(@params, tag_str) # 解析对话框参数
  end

  # 标签：反转按键继续对话框
  def tag_toggleinput(tag_str)
    @params[:input] = !@params[:input]
  end

  # 标签：呼叫预定序列
  def tag_call(tag_str)
    s = MESSAGE_PARA.get_list_str(tag_str.to_sym)
    @list_str = s + @list_str if s != ""
  end

  # 标签：显示动画
  def tag_anim(tag_str)
    ps = tag_str.split(' ')
    character = get_character(ps[0].to_i)
    return if character.nil?
    character.animation_id = ps[1].to_i
    if ps[2] != nil
      c = ps[2].to_i
      while character.animation_id > 0
        Fiber.yield
        c -= 1
        break if c == 0
      end
    end
  end

  # 标签：显示心情
  def tag_balloon(tag_str)
    ps = tag_str.split(' ')
    character = get_character(ps[0].to_i)
    return if character.nil?
    character.balloon_id = ps[1].to_i
    if ps[2] != nil
      c = ps[2].to_i
      while character.balloon_id > 0
        Fiber.yield
        c -= 1
        break if c == 0
      end
    end
  end

  # 获取指定角色
  def get_character(index)
    return nil if !SceneManager.scene_is?(Scene_Map)
    if index > 0
      return $game_map.events[index]
    elsif index == 0
      return get_bind_event
    elsif index < 0
      id = index.abs
      $game_player.followers.each { |f| return f.actor if f.actor && f.actor.actor.id == id }
      return $game_player
    end
  end
  # 绑定的对象
  def get_bind_event
    if @id.is_a?(Integer)
      return $game_map.events[@id] if SceneManager.scene_is?(Scene_Map)
      return $game_troop.members[@id] if SceneManager.scene_is?(Scene_Battle)
    end
    return nil
  end

  # 标签：等待
  def tag_wait(tag_str)
    wait_c = tag_str.to_i.abs
    wait_c.times do
      Fiber.yield
      break if @list_str.empty?
    end
  end

  # 标签：等待直至
  def tag_until(tag_str)
    @list_str.slice!(/^(.*?)<\/until>/m)
    t = $1.dup
    Fiber.yield until(eval_str(t) == true || @list_str.empty?)
  end

  # 标签：结束
  def tag_break(tag_str)
    finish
  end

  # 标签：判定，若返回false，则跳过下一指令
  def tag_if(tag_str)
    @list_str.slice!(/^(.*?)<\/if>/m)
    parse_next_tag if(eval_str($1) == false)
  end

  # 标签：脚本
  def tag_rb(tag_str)
    @list_str.slice!(/^(.*?)<\/rb>/m)
    eval_str($1)
  end
  # 执行字符串
  def eval_str(str)
    s = $game_switches; v = $game_variables; pl = $game_player
    e = get_bind_event
    eval(str)
  end
end

#==============================================================================
# ○ 并行对话框
#==============================================================================
class Window_EagleMessage_Para < Window_EagleMessage
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize(list)
    @list = list
    @input_wait_c = nil
    super()
  end 

  # 获取主参数
  def game_message; @list.game_message; end
  def para_params ; @list.params      ; end

  # 去除全部子窗口
  def create_all_windows  ; end
  def dispose_all_windows ; end
  def update_all_windows  ; end

  #--------------------------------------------------------------------------
  # ● 更新纤程
  #--------------------------------------------------------------------------
  def update_fiber
    if @fiber
      return if para_params[:halt]
      @fiber.resume
    elsif game_message.busy?
      @fiber = Fiber.new { fiber_main }
    end
  end

  # 主逻辑
  def fiber_main
    game_message.visible = true
    eagle_process_before_start
    eagle_process_before_draw
    process_all_text
    process_input
    eagle_process_before_close
    close_and_wait
    game_message.visible = false
    @fiber = nil
  end

  #--------------------------------------------------------------------------
  # ● 输入处理
  #--------------------------------------------------------------------------
  def process_input
    return if @eagle_force_close
    if para_params[:input]
      input_pause  # 处理按键继续的精灵
    else 
      process_input_pause
    end
    return if @eagle_force_close
    eagle_process_hold
  end

  # 按键继续的处理
  def input_pause 
    return if !@flag_draw
    before_input_pause
    eagle_process_draw_update # 统一更新一次
    @eagle_sprite_pause.bind_last_chara(@eagle_chara_sprites[-1])
    @eagle_sprite_pause.show
    @flag_input_pause = true
    self.pause = true unless MESSAGE_EX::NO_DEFAULT_PAUSE
    process_input_pause
    self.pause = false
    @flag_input_pause = false
    @eagle_sprite_pause.hide
  end

  # 输入等待前的操作
  def before_input_pause
    # 去掉 pause 精灵的宽度占位计算
    return if !para_params[:input]
    super
  end

  # 处理等待继续
  def process_input_pause
    @input_wait_c = para_params[:w] || (para_params[:input] ? -1 : 0)
    @input_wait_c = 40 if para_params[:input] == false && @input_wait_c < 0
    while true
      Fiber.yield
      break if para_params[:input] && process_input_pause_key
      break if @input_wait_c == 0
      @input_wait_c -= 1
    end
  end

  # 处理等待时按键继续
  def process_input_pause_key
    Input.trigger?(:C)
  end

  # 监听“确定”键的按下，更新快进的标志
  def update_show_fast
    super if para_params[:input]
  end

  #--------------------------------------------------------------------------
  # ● 强制结束当前对话框
  #--------------------------------------------------------------------------
  def finish_force
    self.openness = 0
    self.opacity = 0
    hide
    finish
    eagle_message_sprites_move_out
    eagle_move_out_assets
    @back_sprite.opacity = 0
    game_message.visible = false
    @fiber = nil
  end

  # 结束当前对话框（保留移出）
  def finish
    force_close
    @input_wait_c = 0
    # 移出hold和seq的拷贝对话框
    eagle_release_hold
    eagle_clear_seq_window if $imported["EAGLE-MessageSeq"]
  end

  #--------------------------------------------------------------------------
  # ● 获取pop的弹出对象（需要有x、y方法）
  #--------------------------------------------------------------------------
  def eagle_get_pop_obj
    if MESSAGE_EX.in_scene?(:map) && pop_params[:id] == 0
      pop_params[:type] = :map_chara
      return $game_map.events[para_params[:id]]
    end
    super
  end
end

#==============================================================================
# ○ 初始化
#==============================================================================
class << DataManager
  #--------------------------------------------------------------------------
  # ● 初始化模块
  #--------------------------------------------------------------------------
  alias eagle_message_para_init init
  def init
    MESSAGE_PARA.init
    eagle_message_para_init
  end
end

#==============================================================================
# ○ Game_Player
#==============================================================================
class Game_Player
  #--------------------------------------------------------------------------
  # ● 预定场所移动的位置
  #     d : 移动后的方向（2,4,6,8）
  #--------------------------------------------------------------------------
  alias eagle_message_para_reserve_transfer reserve_transfer
  def reserve_transfer(map_id, x, y, d = 2)
    MESSAGE_PARA.lock(:player)
    eagle_message_para_reserve_transfer(map_id, x, y, d)
    flag = map_id == $game_map.map_id ? false : true
    MESSAGE_PARA.all_finish_sys(flag)
  end
  #--------------------------------------------------------------------------
  # ● 执行场所移动
  #--------------------------------------------------------------------------
  alias eagle_message_para_perform_transfer perform_transfer
  def perform_transfer
    eagle_message_para_perform_transfer
    MESSAGE_PARA.all_go_on
    MESSAGE_PARA.unlock(:player)
  end
end

#==============================================================================
# ○ Scene_Base
#==============================================================================
class Scene_Base
  #--------------------------------------------------------------------------
  # ● 开始处理
  #--------------------------------------------------------------------------
  alias eagle_message_para_start start
  def start
    MESSAGE_PARA.unlock(:scene_end)
    eagle_message_para_start
  end
  #--------------------------------------------------------------------------
  # ● 开始后处理
  #--------------------------------------------------------------------------
  alias eagle_message_para_post_start post_start
  def post_start
    eagle_message_para_post_start
    MESSAGE_PARA.all_go_on
  end
  #--------------------------------------------------------------------------
  # ● 基础更新
  #--------------------------------------------------------------------------
  alias eagle_message_para_update_basic update_basic
  def update_basic
    eagle_message_para_update_basic
    MESSAGE_PARA.update
  end
  #--------------------------------------------------------------------------
  # ● 结束前处理
  #--------------------------------------------------------------------------
  alias eagle_message_para_pre_terminate pre_terminate
  def pre_terminate
    MESSAGE_PARA.lock(:scene_end)
    MESSAGE_PARA.all_finish_sys(true)
    eagle_message_para_pre_terminate
  end
end

#==============================================================================
# ○ 地图事件的并行对话
#==============================================================================
class Game_Map
  #--------------------------------------------------------------------------
  # ● 指定事件正在执行？
  #--------------------------------------------------------------------------
  def is_event_running?(event_id)
    @interpreter.running? && @interpreter.event_id == event_id
  end
end
class Game_Event < Game_Character
  #--------------------------------------------------------------------------
  # ● 设置事件页
  #--------------------------------------------------------------------------
  alias eagle_message_para_setup_page setup_page
  def setup_page(new_page)
    eagle_message_para_setup_page(new_page)
    set_para_message
  end
  #--------------------------------------------------------------------------
  # ● 设置注释中的“标签序列”
  #--------------------------------------------------------------------------
  def set_para_message
    t = EAGLE.event_comment_head(@list)
    @eagle_para_params = {} # name => params_hash
    @eagle_para_msgs = parse_event_para_list(t) # name => [cond, list_str]
  end
  #--------------------------------------------------------------------------
  # ● 解析含“标签序列”的字符串
  #--------------------------------------------------------------------------
  def parse_event_para_list(text)
    hash = {}
    text.scan(/<list ?('.*?')? ?(\{.*?\})? ?(.*?)?>(.*?)<\/list>/m).each do |params|
      name = self.id
      name = params[0][1..-2] if params[0]
      cond = "true"
      cond = params[1][1..-2] if params[1]
      hash[name] = [cond, params[3]]
      @eagle_para_params[name] = MESSAGE_PARA::EVENT_PARAMS.dup
      MESSAGE_EX.parse_param(@eagle_para_params[name], params[2])
      @eagle_para_params[name][:f] = MESSAGE_EX.check_bool(@eagle_para_params[name][:f])
    end
    hash
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  alias eagle_message_para_update update
  def update
    eagle_message_para_update
    f_update = update_para?
    @eagle_para_msgs.each do |name, ps|
      update_para(f_update, name, ps[0], ps[1], @eagle_para_params[name])
    end
  end
  #--------------------------------------------------------------------------
  # ● 能够更新并行对话？
  #--------------------------------------------------------------------------
  def update_para?
    return false if MESSAGE_PARA.lock?
    return false if $game_map.is_event_running?(self.id)
    return false if !near_the_screen?
    return true
  end
  #--------------------------------------------------------------------------
  # ● 更新指定名称的并行对话
  #--------------------------------------------------------------------------
  def update_para(f_update, name, cond_str, list_str, params)
    if !f_update # 若此时不能更新，则直接移出
      return MESSAGE_PARA.list_finish(name, true)
    end
    if params[:wc] # 处理显示后的等待
      return if params[:wc] < 0
      params[:wc] -= 1
      return if params[:wc] > 0
      params[:wc] = nil
    end
    f_exist = MESSAGE_PARA.list_exist?(name)
    f_cond = para_cond_meet?(cond_str)
    if f_exist # 若当前存在
      if !f_cond && params[:f] == true # 若已经不满足条件，则移出
        params[:wc] = nil
        MESSAGE_PARA.list_finish(name)
      end
    else
      if params[:last_exist] == true # 若上一帧有，当前帧没了，则进入等待
        params[:wc] = params[:w] || -1
      else # 若上一帧也没有，则新加入
        MESSAGE_PARA.add(name, list_str) if f_cond
      end
    end
    params[:last_exist] = f_exist
  end
  #--------------------------------------------------------------------------
  # ● 符合并行对话条件？
  #--------------------------------------------------------------------------
  def para_cond_meet?(cond_str)
    s = $game_switches; v = $game_variables
    pl = $game_player; a = self
    e = $game_map.events if SceneManager.scene_is?(Scene_Map)
    e = $game_troop.members if SceneManager.scene_is?(Scene_Battle)
    d = distance_to(0)
    eval(cond_str) == true
  end
  #--------------------------------------------------------------------------
  # ● 获取与指定ID号事件的距离|dx|+|dy|
  #   distance_to(0) 获取与玩家的距离|dx|+|dy|
  #--------------------------------------------------------------------------
  def distance_to(id)
    chara = nil
    chara = $game_player if id == 0
    chara = $game_map.events[id] if id > 0
    return 9999 if chara.nil?
    return distance_x_from(chara.x).abs + distance_y_from(chara.y).abs
  end
end

#===============================================================================
# ○ 征用滚动文本
#===============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 显示滚动文字
  #--------------------------------------------------------------------------
  alias eagle_message_para_command_105 command_105
  def command_105
    return call_message_para if $game_switches[MESSAGE_PARA::S_ID_SCROLL_TEXT]
    eagle_message_para_command_105
  end
  #--------------------------------------------------------------------------
  # ● 写入并行对话
  #--------------------------------------------------------------------------
  def call_message_para
    ensure_fin = @list[@index].parameters[1]
    n = ""
    if next_event_code == 405
      @index += 1
      n += @list[@index].parameters[0]
    end
    t = ""
    while next_event_code == 405
      @index += 1
      t += @list[@index].parameters[0]
      t += "\n"
    end
    MESSAGE_PARA.add(n, t, ensure_fin)
    Fiber.yield
  end
end
