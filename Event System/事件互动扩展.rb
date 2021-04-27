#==============================================================================
# ■ 事件互动扩展 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
$imported ||= {}
$imported["EAGLE-EventInteractEX"] = true
#==============================================================================
# - 2021.4.27.15 兼容khas的SAS即时战斗系统
#==============================================================================
# - 本插件新增了事件页的按空格键触发的互动类型，事件自动触发自身
#------------------------------------------------------------------------------
# 【思路】
#
# - 由于默认的“按确定键”触发事件页，是单纯的执行事件页的全部指令，
#   而且对于玩家面前是否存在可触发的事件，无法给出一个提示，
#   因此我设计了这个外置的并行的互动列表UI，效仿大部分游戏都有的互动提示功能
#
# - 由于事件触发事件在默认设计中是不存在的，
#   如果使用并行触发或自动触发，又会影响事件的正常按键触发，
#   但如果使用另一个并行事件，在需要判定多个事件时，又非常复杂和冗余，
#   因此我设计了事件触发事件的并行判定，在触发时，将和玩家按键触发一样挂起其他内容
#
#---------------------------------------------------------------------------
# 【使用 - 玩家互动列表】
#
# - 当事件页的第一条指令为注释，且其中包含【xx】类型的文本时，
#     在玩家相邻且面朝事件，且事件页出现条件均满足，将自动开启它的互动列表
#
#   注意：注释中的【xx】可重复填写多次。
#
#   对于未填写【xx】类型注释内容的事件页，依然按照默认的方式执行全部指令。
#
# - 在事件页的执行内容中，按照与【事件消息机制 by老鹰】中的同样策略进行编写
#   对于注释中写的【xx】类型的互动，应在当前事件页中编写：
#
#     标签： xx
#       其余事件指令
#     标签：END
#
#   来定义这个互动能触发的事件指令
#   若未编写，则不触发任何指令
#
# - 此时按下 SHIFT键 能够在不同的互动类型中切换
#       按下 确定键 执行对应的互动类型中的指令
#       按下 方向键 将正常移动，即在显示互动列表时，不会干扰玩家的移动
#
# - 特别的，本插件的互动不会锁定事件的方向，因此请自己手动添加【朝向玩家】
#
# - 特别的，【转至标签】指令仍然有效，在使用时请注意不要出现循环嵌套
#
# 【高级】
#
# - 在【xx】文本中，编写 if{cond} 来设置该互动的出现条件
#    当 eval(cond) 返回 true 时，才会显示这个互动
#
#    可以用 s 代表开关组，v 代表变量组，e 代表当前事件（Game_Event）
#          es 代表 $game_map.events，gp 代表 $game_player
#
#    特别的，为地图人物新增了 path?(chara_id, dirs) 方法，来判定目标对象位置
#      其中 chara_id 为 -1 时代表玩家，正数代表事件序号，0代表当前事件
#           为 字符串 时代表名称中含有该字符串的任一事件
#          （注意，若事件的当前页为空时，会判定为查找失败并被跳过）
#      其中 dirs 为 wasd 的排列组合字符串（与人物方向相关），可用 | 分隔不同判定
#        比如 "www" 代表面前的第三格位置
#        比如 "w|s" 代表面前一格或背后一格
#        特别的，c 代表当前格
#
#      比如 e.path?(-1, "w") 为判定玩家是否在当前事件的面前一格处
#      比如 e.path?("路人A", "w|s|c")
#         为判定名称带有 路人A 的任一事件是否在当前事件的面前/身后/当前一格处
#
#  如：【偷窃if{s[1]}】 代表只有当1号开关开启时，才显示偷窃指令
#
# 【示例】
#
# - 当前地图的 1 号事件的第 1 页中指令列表（事件页的出现条件已经满足）
#    |- 注释：【交谈】【商店】【贿赂】
#    |- 标签：交谈
#    |- 显示文字：测试语句1
#    |- 显示文字：测试语句2
#    |- 标签：END
#    |- 显示文字：测试语句3
#    |- 标签：商店
#    |- 显示商店
#    |- 标签：END
#    |- 标签：贿赂
#    |- 显示文字：测试语句4
#    |- 标签：END
#
#    当玩家面对这个事件时，将显示一个列表，
#    其中显示 交谈、商店、贿赂 三个类型，按shift可以切换
#    若当前显示的为 交谈，则按下确定键后，将显示 测试语句1 和 测试语句2 ，随后结束
#    若当前显示的为 商店，则按下确定键后，将显示商店，随后结束
#    若按下方向键，则玩家正常移动，且自动关闭列表
#
#   注意1：其中的 测试语句3 将不会被执行到。
#   注意2：若删去事件页开头的注释指令，将回归默认的事件页执行方式，
#          即按确定键后，依次执行全部指令
#
#---------------------------------------------------------------------------
# 【使用 - 事件触发事件】
#
# - 当事件页的第一条指令为注释时，在其中编写 <auto tags> 来定义自动触发
#   触发时，同样会挂起玩家的操作，即与玩家主动触发保持一致效果
#
# - 事件会每帧判定目标事件是否在指定位置上，如果成功，则触发一次互动类型
#   可以重复编写多次，以设置多个相互独立的自动触发
#
#   其中 auto 大小写任意
#   其中 tags 为以下语句的任意组合，用空格分隔
#         等号左右可以添加冗余空格
#
#      d=dirs → 设置以本事件为中心，朝哪个方向去查找另一个事件
#                  其中 dirs 替换为上一个内容中的 path? 方法的dirs
#                  如 c 代表位置相同，w 代表在本事件的前面一格
#                     c|w|a|s|d 代表在本事件的四方向周围一格或位置相同
#                  特别的，如果为数字，代表XY距离的差值绝对值的和恰好为该数字
#                若不写，则默认为相同位置
#
#      e=eid  → 设置要查找的事件的id
#                  其中 eid 替换为 -1 时代表玩家，正数代表指定事件的序号
#                  为 字符串 时代表名称中含有该字符串的任一事件
#                  （注意，若事件的当前页为空时，会判定为查找失败并被跳过）
#                   可以用 | 分隔不同事件，此时其中任一事件达成条件，即会触发
#                若不写，则默认查看玩家的位置
#
#      esym=字符串 → 当查找成功时，被找到的事件需要执行的互动内容
#                       其中 字符串 替换成那个事件的当前页中的互动标签
#                       当e为玩家时该设置无效
#                     默认无设置
#
#      sym=字符串 → 当查找成功时，本事件需要执行的互动内容
#                      其中 字符串 替换成本事件的当前页中的互动标签
#
#      cond={脚本} → 设置额外的执行条件的脚本，当 eval(脚本)返回true时，才能触发
#                       其中脚本替换为 Ruby 脚本
#                     默认无设置
#
#      t=时间 → 设置触发一次后，再次触发前的等待帧数
#                  其中时间替换为 数字，单位为帧
#                  若存在任一事件在执行（挂起玩家移动的执行模式），等待将暂停计时
#                  若设置为0，则在事件重置或事件页更新时，才能再次触发
#                默认设置 0
#
# 【示例】
#
# - 以上一个示例为基础
#   第一个指令注释新增为如下文本：
#    |- 注释：【交谈】【商店】【贿赂】
#             <auto d=w|s e=-1 sym=贿赂>
#
#   则当事件的面前/背后一格为玩家时，将自动触发一次【贿赂】的互动，之后不再重复触发
#
# - 以上一个示例为基础
#   第一个指令注释新增为如下文本：
#    |- 注释：<auto d=s e=小明 esym=贿赂 sym=受贿>
#
#   则当事件的背后一格为 名称含有小明 的事件时（且事件页不为空），
#     将触发一次 小明 事件的【贿赂】的互动（与玩家按键触发一致），
#     和本事件的【受贿】的互动（编号小的事件先触发）
#
# - 以上一个示例为基础
#   第一个指令注释新增为如下文本：
#    |- 注释：<auto d=w|ww|www e=逃犯 sym=抓住 t=60>
#
#   则当事件的面前三格内有 名称含有逃犯 的事件时（且事件页不为空），
#     将触发一次本事件的【抓住】的互动，
#     在互动结束后，进行60帧的冷却，冷却结束时若事件还在，将再次触发
#
# 【注意】
#
# - 由于这个并行判定的触发同样是地图上玩家按键触发的模式，
#     即触发时将挂起玩家操作，同样会隐藏互动列表
#     因此请不要编写太多高频率重复刷新的并行触发，那样将导致互动列表闪烁
#
# - 如果实在需要，推荐使用【事件消息机制】，然后将 auto 改为 para
#     调用事件消息进行并行处理，将不再挂起一般的操作
#
#---------------------------------------------------------------------------
# 【联动】
#
# - 由于本插件使用了与【事件消息机制 by老鹰】中的同样格式
#   因此可以用【事件消息机制 by老鹰】中的脚本，来触发对应的事件指令
#
#   但注意，其触发方式为 并行执行
#
#   如 $game_map.events[1].msg("贿赂", true)
#     → 触发 1号事件 的 当前事件页 的 贿赂 标签中的指令
#
# - 对于事件触发事件，由于完全按照玩家按键触发进行时，总会有一些奇怪的地方出现卡顿感
#   因此同样新增了调用事件消息来进行处理
#   内容不变，仅仅将 auto 替换成 para 即可
#
#   以上一个示例为基础
#   第一个指令注释新增为如下文本：
#    |- 注释：<para d=s e=小明 esym=贿赂 sym=受贿>
#
#   就会改成用 并行执行 的方式调用本事件的【受贿】互动和小明事件的【贿赂互动】
#
#---------------------------------------------------------------------------
# 【兼容性】
#
# - 本插件覆盖了 Game_Map 中的 setup_starting_map_event 方法
#     该方法用于执行当前被标记为启动的事件
#   本插件新增了对事件中指令列表的筛选，选出了与其互动类型相对应的指令
#
# - 本插件覆盖了 Game_Player 中的 update_nonmoving 方法
#     该方法用于在玩家停止移动时，判定事件的接触触发、按键触发等
#   本插件扩展了按键触发部分，先提取位于玩家面前的可触发的事件，
#     随后显示列表，再判定按键并执行事件的触发
#==============================================================================
module EVENT_INTERACT
  #--------------------------------------------------------------------------
  # ● 【常量】定义互动文本的图标索引号
  #--------------------------------------------------------------------------
  SYM_TO_ICON = {
    "交谈" => 4,
    "偷窃" => 482,
    "送礼" => 259,
    "贿赂" => 361,
    "推" => 11,
    "拉" => 11,
  }
  #--------------------------------------------------------------------------
  # ● 【常量】当未定义互动文本的图标时，使用这里的图标
  #--------------------------------------------------------------------------
  DEFAULT_ICON = 4
  #--------------------------------------------------------------------------
  # ● 当返回true时，切换到下一个互动类型
  #--------------------------------------------------------------------------
  def self.next_sym?
    Input.trigger?(:A)
  end
  #--------------------------------------------------------------------------
  # ● 显示的切换提示文本
  #--------------------------------------------------------------------------
  def self.next_text
    " SHIFT →"
  end
  #--------------------------------------------------------------------------
  # ●【常量】互动列表的显示位置
  # 0 时为事件下方，1 时为事件上方，2 时为事件右侧
  #--------------------------------------------------------------------------
  def self.hint_pos
    # 取消注释下面这一句，可以改成使用1号变量的值进行位置控制
    # return $game_variables[1]
    # 默认显示在事件右侧
    return 2
  end
end
#=============================================================================
# ■ 读取部分
#=============================================================================
module EAGLE
  #--------------------------------------------------------------------------
  # ● 读取事件页开头的注释组
  #--------------------------------------------------------------------------
  def self.event_comment_head(command_list)
    return "" if command_list.nil? || command_list.empty?
    t = ""; index = 0
    while command_list[index].code == 108 || command_list[index].code == 408
      t += command_list[index].parameters[0]
      index += 1
    end
    t
  end
  #--------------------------------------------------------------------------
  # ● 判定e2是否在e1的dirs位置上 或 在e1的dirs位置上的事件的名字是否含e2.to_s
  #  dirs 为 wasd 的排列组合字符串，若为空，则判定是否坐标一致
  #       其中 w 代表面前一格，s 代表后退一格，a 代表左手边一格，d 代表右手边一格
  #        c 代表当前格，数字代表XY坐标差的和
  #       可以用 | 分割不同位置
  #  e2_str 为事件的字符串
  #       其中 正数 为对应事件，-1 为玩家，字符串为事件名称
  #       可以用 | 分割不同事件
  #--------------------------------------------------------------------------
  def self.check_chara_pos?(e1, dirs, e2_str)
    e2_str.split('|').each do |e2_|
      # 提取目标事件
      e2_id = e2_.to_i
      if e2_id == 0
        e2 = e2_  # 字符串：名称含有e2的事件
      else
        e2 = EAGLE.get_chara(self, e2_id)  # 数字：指定序号的事件
      end
      # 提取目标位置
      dirs.split('|').each do |cs|
        # 判定距离的差值
        if (d = cs.to_i) != 0  # 数字：距离差
          e = check_chara_pos_dxy?(e1, d, e2)
          return e if e
          next
        end
        # 字符串：wasd组合
        # 判定直接坐标
        e = check_chara_pos_wasd?(e1, cs, e2)
        return e if e
      end
    end
    return false
  end
  #--------------------------------------------------------------------------
  # ● 查找指定距离差值的事件
  #--------------------------------------------------------------------------
  def self.check_chara_pos_dxy?(e1, d, e2)
    if e2.is_a?(String) # 名字含有e2的任一事件满足距离差值
      $game_map.events.each do |eid, _e|
        next if _e.list == nil || _e.list.size == 1
        next if !_e.name.include?(e2)
        dx = (e1.x - _e.x).abs
        dy = (e1.y - _e.y).abs
        return _e if dx + dy == d
      end
      return nil
    end
    # 指定事件与当前事件的距离差值满足d
    dx = (e2.x - e1.x).abs
    dy = (e2.y - e1.y).abs
    return e2 if dx + dy == d
    return nil
  end
  #--------------------------------------------------------------------------
  # ● 计算指定路径的目的地
  #--------------------------------------------------------------------------
  WASD_DX = {
    2 => {'w' => 0, 'a' => 1, 's' => 0, 'd' => -1, 'c' => 0},
    4 => {'w' => -1, 'a' => 0, 's' => 1, 'd' => 0, 'c' => 0},
    6 => {'w' => 1, 'a' => 0, 's' => -1, 'd' => 0, 'c' => 0},
    8 => {'w' => 0, 'a' => -1, 's' => 0, 'd' => 1, 'c' => 0}
  }
  WASD_DY = {
    2 => {'w' => 1, 'a' => 0, 's' => -1, 'd' => 0, 'c' => 0},
    4 => {'w' => 0, 'a' => 1, 's' => 0, 'd' => -1, 'c' => 0},
    6 => {'w' => 0, 'a' => -1, 's' => 0, 'd' => 1, 'c' => 0},
    8 => {'w' => -1, 'a' => 0, 's' => 1, 'd' => 0, 'c' => 0}
  }
  def self.get_wasd_pos(e1, dirs)
    _x = e1.x
    _y = e1.y
    _d = e1.direction
    dirs.each_char { |c|
      _x += WASD_DX[_d][c]
      _y += WASD_DY[_d][c]
    }
    return _x, _y
  end
  #--------------------------------------------------------------------------
  # ● 查找指定路径目的地的事件
  #--------------------------------------------------------------------------
  def self.check_chara_pos_wasd?(e1, dirs, e2)
    _x, _y = get_wasd_pos(e1, dirs)
    if e2.is_a?(String) # 名字含有e2的任一事件满足坐标
      list = $game_map.events_xy(_x, _y)
      return nil if list.empty?
      list.each { |_e|
        next if _e.list == nil || _e.list.size == 1
        return _e if _e.name.include?(e2)
      }
      return nil
    end
    return e2 if e2.x == _x && e2.y == _y
    return nil
  end
  #--------------------------------------------------------------------------
  # ● 获取事件对象
  #--------------------------------------------------------------------------
  def self.get_chara(event, id)
    if id == 0 # 当前事件
      return $game_map.events[event.id]
    elsif id > 0 # 第id号事件
      chara = $game_map.events[id]
      chara ||= $game_map.events[event.id]
      return chara
    elsif id < 0 # 队伍中数据库id号角色（不存在则取队长）
      id = id.abs
      $game_player.followers.each do |f|
        return f if f.actor && f.actor.actor.id == id
      end
      return $game_player
    end
  end
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
end
#=============================================================================
# ■ 读取部分
#=============================================================================
module EVENT_INTERACT
  #--------------------------------------------------------------------------
  # ● 提取事件页开头注释指令中预设的互动类型的数组
  #  event 为 Game_Event 的对象
  #--------------------------------------------------------------------------
  def self.extract_syms(event)
    syms = []
    t = EAGLE.event_comment_head(event.list)
    t.scan(/【(.*?)】/mi).each do |ps|
      _t = ps[0]
      _t.gsub!(/ *(?i:if){(.*?)} */) { "" }
      next if $1 && eagle_eval($1, event) == false # 跳过该选项的增加
      syms.push(_t)
    end
    return syms
  end
  #--------------------------------------------------------------------------
  # ● 提取事件页开头注释指令中预设的自身触发的互动类型的Hash
  #  event 为 Game_Event 的对象
  #--------------------------------------------------------------------------
  def self.extract_tags(event, sym = "auto")
    syms = []
    t = EAGLE.event_comment_head(event.list)
    t.scan(/<#{sym}:? *(.*?)>/mi).each do |ps|
      _hash = EAGLE.parse_tags(ps[0])
      _hash[:t] ||= 0
      _hash[:t] = _hash[:t].to_i
      _hash[:tc] = 0
      syms.push(_hash)
    end
    return syms
  end
  #--------------------------------------------------------------------------
  # ● 提取物品备注中预设的互动类型的Hash
  #--------------------------------------------------------------------------
  def self.extract_item_tags(item, sym = "item")
    syms = []
    t = item.note
    t.scan(/<#{sym}:? *(.*?)>/mi).each do |ps|
      _hash = EAGLE.parse_tags(ps[0])
      syms.push(_hash)
    end
    return syms
  end
  #--------------------------------------------------------------------------
  # ● 执行字符串
  #--------------------------------------------------------------------------
  def self.eagle_eval(t, e)
    # 缩写
    s = $game_switches; v = $game_variables
    es = $game_map.events
    gp = $game_player
    eval(t)
  end
#=============================================================================
# ■ 事件互动列表
#=============================================================================
  #--------------------------------------------------------------------------
  # ● 清除数据
  #--------------------------------------------------------------------------
  @info = nil
  def self.clear
    @info = nil
  end
  #--------------------------------------------------------------------------
  # ● 重置存储的数据
  #--------------------------------------------------------------------------
  def self.reset(event, syms)
    if @info && @info[:event].id == event.id && @info[:syms] == syms
      return
    end
    @info = {}
    @info[:event] = event
    @info[:syms] = syms
    @info[:i] = 0
    @info[:i_draw] = -1 # 当前绘制的索引
  end
  #--------------------------------------------------------------------------
  # ● 切换至下一个互动类型
  #--------------------------------------------------------------------------
  def self.next_sym
    return if !self.next_sym?
    @info[:i] += 1
    @info[:i] = 0 if @info[:i] >= @info[:syms].size
  end
  #--------------------------------------------------------------------------
  # ● 获取当前的互动类型
  #--------------------------------------------------------------------------
  def self.sym
    @info[:syms][@info[:i]]
  end
  #--------------------------------------------------------------------------
  # ● 每帧更新（于Spriteset_Map中调用）
  #--------------------------------------------------------------------------
  def self.update(sprite, event_sprites)
    if @info == nil || self.sym == nil || $game_map.interpreter.running?
      return sprite.visible = false
    end
    sprite.visible = true
    redraw(sprite)
    update_position(sprite, event_sprites)
  end
  #--------------------------------------------------------------------------
  # ● 每帧重绘
  #--------------------------------------------------------------------------
  def self.redraw(sprite)
    return if @info[:i_draw] == @info[:i]
    @info[:i_draw] = @info[:i]
    syms = @info[:syms]
    flag_draw_hint = syms.size > 1

    # 互动类型文本的文字大小
    sym_font_size = 16
    # 图标的宽高
    icon_wh = 28
    # 两个互动文本之间的间隔值
    sym_offset = 0

    # 预计算每个互动文本的宽度
    ws = []
    _b = Cache.empty_bitmap
    _b.font.size = sym_font_size
    syms.each { |t| r = _b.text_size(t); ws.push(r.width) }

    w = syms.size * (icon_wh + sym_offset) + ws.max + 6
    h = 2 + icon_wh + 2
    h += 12 if flag_draw_hint
    if sprite.bitmap && (sprite.width != w || sprite.height != h)
      sprite.bitmap.dispose
      sprite.bitmap = nil
    end
    sprite.bitmap ||= Bitmap.new(w, h)
    sprite.bitmap.clear
    sprite.bitmap.font.outline = true
    sprite.bitmap.font.shadow = false
    sprite.bitmap.font.color.alpha = 255
    _y = 0

    # 绘制背景
    sprite.bitmap.fill_rect(0, 0, sprite.width, sprite.height,
      Color.new(0, 0, 0, 160))
    _y += 2

    if flag_draw_hint && hint_pos == 1
      # 绘制按键说明文本
      sprite.bitmap.font.size = 12
      sprite.bitmap.font.color.alpha = 255
      sprite.bitmap.draw_text(0, _y, sprite.width, 14,
        next_text, 0)
      _y += 12

      # 绘制分割线
      sprite.bitmap.fill_rect(0, _y, sprite.width, 1,
        Color.new(255,255,255,120))
      _y += 2
    end

    # 绘制具体的选项
    sprite.bitmap.font.size = sym_font_size
    _x = 2
    _ox = 0
    syms.each_with_index do |t, i|
      # 绘制图标
      icon_index = SYM_TO_ICON[t] || DEFAULT_ICON
      dx = (icon_wh-24) / 2
      dy = (icon_wh-24) / 2
      draw_icon(sprite.bitmap, icon_index, _x+dx, _y+dy, i == @info[:i])
      _x += icon_wh+sym_offset
      # 若当前项被选中，绘制文本
      if i == @info[:i]
        _ox = _x - icon_wh + (icon_wh + ws[i])/2
        _x -= sym_offset
        sprite.bitmap.draw_text(_x, _y, ws[i]+2, icon_wh, t, 1)
        _x += ws[i]+sym_offset
      end
    end
    _y += icon_wh

    if flag_draw_hint && hint_pos != 1
      # 绘制分割线
      sprite.bitmap.fill_rect(0, _y, sprite.width, 1,
        Color.new(255,255,255,120))
      _y += 2

      # 绘制按键说明文本
      sprite.bitmap.font.size = 12
      sprite.bitmap.font.color.alpha = 255
      sprite.bitmap.draw_text(0, _y, sprite.width, 14,
        next_text, 0)
      _y += 12
    end

    # 将当前选中的互动类型，移动到行走图下方
    sprite.ox = _ox
    sprite.oy = 0
  end
  #--------------------------------------------------------------------------
  # ● 每帧更新位置
  #--------------------------------------------------------------------------
  def self.update_position(sprite, event_sprites)
    sprite.x = @info[:event].screen_x
    sprite.y = @info[:event].screen_y
    sprite_e = nil
    event_sprites.each { |s| break sprite_e = s if s.character == @info[:event] }
    if sprite_e
      case hint_pos
      when 0
      when 1
        sprite.y = sprite.y - sprite.height - sprite_e.oy
      when 2
        sprite.ox = 0
        sprite.x = sprite.x + sprite_e.ox
        sprite.y = sprite.y - sprite.height / 2 - sprite_e.height / 2
      end
    end
    if sprite.x + sprite.width > Graphics.width
      sprite.x = Graphics.width - sprite.width
    end
    if sprite.y + sprite.height > Graphics.height
      sprite.y = Graphics.height - sprite.height
    end
  end
  #--------------------------------------------------------------------------
  # ● 绘制图标
  #     enabled : 有效的标志。false 的时候使用半透明效果绘制
  #--------------------------------------------------------------------------
  def self.draw_icon(bitmap, icon_index, x, y, enabled = true)
    _bitmap = Cache.system("Iconset")
    rect = Rect.new(icon_index % 16 * 24, icon_index / 16 * 24, 24, 24)
    bitmap.blt(x, y, _bitmap, rect, enabled ? 255 : 120)
  end
end
#===============================================================================
# ○ Game_Interpreter
#===============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 添加标签
  #--------------------------------------------------------------------------
  alias eagle_event_interact_command_118 command_118
  def command_118
    eagle_event_interact_command_118
    event_interact_finish if @params[0] == 'END'
  end
  #--------------------------------------------------------------------------
  # ● 转至互动
  #--------------------------------------------------------------------------
  def event_interact_search(sym)
    label_name = sym
    @list.size.times do |i|
      if @list[i].code == 118 && @list[i].parameters[0] == label_name
        @index = i
        return
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 结束互动
  #--------------------------------------------------------------------------
  def event_interact_finish
    @index = @list.size
  end
end
#===============================================================================
# ○ Game_Map
#===============================================================================
class Game_Map
  #--------------------------------------------------------------------------
  # ● （覆盖）检测／设置启动中的地图事件
  #--------------------------------------------------------------------------
  def setup_starting_map_event
    event = @events.values.find {|event| event.starting }
    if event
      @interpreter.setup(event.list, event.id)
      # 新增处理，跳转到当前互动类型的指令组
      @interpreter.event_interact_search(event.starting_type)
      # 将flag重置放到最后处理
      event.clear_starting_flag
    end
    event
  end
end
#===============================================================================
# ○ Game_Character
#===============================================================================
class Game_Character < Game_CharacterBase
  #--------------------------------------------------------------------------
  # ● 通过dirs路径（与当前朝向有关）能否与event_id事件重合？
  # 或通过dirs路径能否找到一个名称含 event_id.to_s 的事件？
  #--------------------------------------------------------------------------
  def path?(event_str, dirs = "")
    return EAGLE.check_chara_pos?(self, dirs, event_str)
  end
end
#===============================================================================
# ○ Game_Event
#===============================================================================
class Game_Event < Game_Character
  attr_reader :starting_type
  #--------------------------------------------------------------------------
  # ● 获取事件名称
  #--------------------------------------------------------------------------
  def name
    @event.name
  end
  #--------------------------------------------------------------------------
  # ● 初始化公有成员变量
  #--------------------------------------------------------------------------
  alias eagle_event_interact_init_public_members init_public_members
  def init_public_members
    eagle_event_interact_init_public_members
    @starting_type = nil
    @starting_ex = []
    @starting_ex_para = []
  end
  #--------------------------------------------------------------------------
  # ● 清除启动中的标志
  #--------------------------------------------------------------------------
  alias eagle_event_interact_clear_starting_flag clear_starting_flag
  def clear_starting_flag
    eagle_event_interact_clear_starting_flag
    @starting_type = nil
  end
  #--------------------------------------------------------------------------
  # ● 清除事件页的设置
  #--------------------------------------------------------------------------
  alias eagle_event_interact_clear_page_settings clear_page_settings
  def clear_page_settings
    eagle_event_interact_clear_page_settings
    @starting_ex.clear
    @starting_ex_para.clear
  end
  #--------------------------------------------------------------------------
  # ● 设置事件页的设置
  #--------------------------------------------------------------------------
  alias eagle_event_interact_setup_page_settings setup_page_settings
  def setup_page_settings
    eagle_event_interact_setup_page_settings
    if @list
      @starting_ex = EVENT_INTERACT.extract_tags(self)
      @starting_ex_para = EVENT_INTERACT.extract_tags(self, "para")
    end
  end
  #--------------------------------------------------------------------------
  # ● 自动事件的启动判定
  #--------------------------------------------------------------------------
  alias eagle_event_interact_check_event_trigger_auto check_event_trigger_auto
  def check_event_trigger_auto
    eagle_event_interact_check_event_trigger_auto
    @starting_ex.each { |_hash| return if check_hash_trigger(_hash) }
    if $imported["EAGLE-EventMsg"]
      @starting_ex_para.each { |_hash| check_hash_trigger(_hash, :msg) }
    end
  end
  #--------------------------------------------------------------------------
  # ● 判定互动
  #--------------------------------------------------------------------------
  def check_hash_trigger(_hash, type = :player)
    # 若之前触发过了，留出一部分延迟时间，防止无缝触发
    if _hash[:active] == true
      return false if $game_map.interpreter.event_id > 0
      return false if type == :msg && msg?
      return false if _hash[:t] == 0
      _hash[:tc] -= 1
      _hash[:active] = false if _hash[:tc] <= 0
      return false
    end
    return false if _hash[:cond] && !EVENT_INTERACT.eagle_eval(_hash[:cond], self)
    e = path?(_hash[:e] || "-1", _hash[:d] || "c")
    if e
      apply_hash_trigger(_hash, e, type)
      _hash[:active] = true
      _hash[:tc] = _hash[:t]
      return true
    end
    return false
  end
  #--------------------------------------------------------------------------
  # ● 执行互动
  #--------------------------------------------------------------------------
  def apply_hash_trigger(_hash, e, type)
    if type == :player
      if _hash[:esym] && e != $game_player
        e.start_ex(_hash[:esym])
      end
      if _hash[:sym]
        start_ex(_hash[:sym])
      end
    end
    if type == :msg
      if _hash[:esym] && e != $game_player
        e.msg(_hash[:esym])
      end
      if _hash[:sym]
        msg(_hash[:sym])
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 事件启动（扩展）
  #--------------------------------------------------------------------------
  def start_ex(type = nil)
    return if empty?
    @starting_type = type
    @starting = true
    @locked = true
  end
end
#===============================================================================
# ○ Game_Player
#===============================================================================
class Game_Player < Game_Character
  #--------------------------------------------------------------------------
  # ● 获取指定触发条件的事件
  #--------------------------------------------------------------------------
  def eagle_get_map_event(x, y, triggers, normal)
    $game_map.events_xy(x, y).each do |event|
      if event.trigger_in?(triggers) &&
         (normal == nil || event.normal_priority? == normal) &&
         event.list.size > 1  # 事件页不为空
        return event
      end
    end
    return nil
  end
  #--------------------------------------------------------------------------
  # ● 获取角色当前格子的可触发事件
  #--------------------------------------------------------------------------
  def eagle_get_event_here(triggers)
    return eagle_get_map_event(@x, @y, triggers, nil)
  end
  #--------------------------------------------------------------------------
  # ● 获取角色面前的可触发事件
  #--------------------------------------------------------------------------
  def eagle_get_event_there(triggers)
    x2 = $game_map.round_x_with_direction(@x, @direction)
    y2 = $game_map.round_y_with_direction(@y, @direction)
    e = eagle_get_map_event(x2, y2, triggers, true)
    return e if e
    return nil unless $game_map.counter?(x2, y2)
    x3 = $game_map.round_x_with_direction(x2, @direction)
    y3 = $game_map.round_y_with_direction(y2, @direction)
    e = eagle_get_map_event(x3, y3, triggers, true)
    return e
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）非移动中的处理
  #     last_moving : 此前是否正在移动
  #--------------------------------------------------------------------------
  def update_nonmoving(last_moving)
    return if $game_map.interpreter.running?
    if last_moving
      $game_party.on_player_walk
      return if check_touch_event
    end
    if movable? # 不再统一判定按键，改为各自处理
      return if Input.trigger?(:C) && get_on_off_vehicle
      return if eagle_check_action_event # 将默认的替换成新的方法
    end
    update_encounter if last_moving
  end
  #--------------------------------------------------------------------------
  # ● 检查主动触发事件
  #--------------------------------------------------------------------------
  def eagle_check_action_event
    e = nil
    # 检查位于玩家底层的可以被按键触发的事件
    e = eagle_get_event_here([0]) if e == nil
    # 检查位于前面的可以被按键触发的事件
    e = eagle_get_event_there([0,1,2]) if e == nil
    # 如果存在事件
    if e
      # 提取事件页预设的互动列表
      syms = EVENT_INTERACT.extract_syms(e)
      # 重置数据
      EVENT_INTERACT.reset(e, syms)
      # 更新切换
      EVENT_INTERACT.next_sym
      # 判定空格键触发事件
      if Input.trigger?(:C)
        syms.empty? ? e.start : e.start_ex(EVENT_INTERACT.sym)
        $game_map.setup_starting_event
        return true
      end
    else # 如果不存在事件，则清除数据
      EVENT_INTERACT.clear
    end
    # 最后返回 false，代表没有按键触发事件
    return false
  end
end
#===============================================================================
# ○ 兼容 Sapphire Action System IV By Khas Arcthunder - arcthunder.site40.net
#===============================================================================
$khas_awesome ||= []
FLAG_khas_SAS = $khas_awesome.any? { |s| s[0] == "Sapphire Action System" }
if FLAG_khas_SAS
class Game_Player < Game_Character
  #--------------------------------------------------------------------------
  # ● 获取指定触发条件的事件
  #--------------------------------------------------------------------------
  def eagle_get_map_event(px, py, triggers, normal)
    for event in $game_map.events.values
      if (event.px - px).abs <= event.cx && (event.py - py).abs <= event.cy
        if event.trigger_in?(triggers) &&
           (normal == nil || event.normal_priority? == normal) &&
           event.list.size > 1  # 事件页不为空
          return event
        end
      end
    end
    return nil
  end
  #--------------------------------------------------------------------------
  # ● 获取角色当前格子的可触发事件
  #--------------------------------------------------------------------------
  def eagle_get_event_here(triggers)
    return eagle_get_map_event(@px, @py, triggers, nil)
  end
  #--------------------------------------------------------------------------
  # ● 获取角色面前的可触发事件
  #--------------------------------------------------------------------------
  def eagle_get_event_there(triggers)
    fx = @px+Trigger_Range[@direction][0]
    fy = @py+Trigger_Range[@direction][1]
    e = eagle_get_map_event(fx, fy, triggers, true)
    return e if e
    if $game_map.pixel_table[fx,fy,5] == 1
      fx += Counter_Range[@direction][0]
      fy += Counter_Range[@direction][1]
      e = eagle_get_map_event(fx, fy, triggers, true)
      return e if e
    end
    return nil
  end
end
end
#===============================================================================
# ○ 兼容 像素级移动 by 老鹰
#===============================================================================
if $imported["EAGLE-PixelMove"]
class Game_Player < Game_Character
  #--------------------------------------------------------------------------
  # ● 获取角色当前格子的可触发事件
  #--------------------------------------------------------------------------
  def eagle_get_event_here(triggers)
    $game_map.events_rect(get_collision_rect(false)).each do |event|
      if event.trigger_in?(triggers) && # 去除了与人物同层的限制
         event.list.size > 1  # 事件页不为空
        return event
      end
    end
    return nil
  end
  #--------------------------------------------------------------------------
  # ● 获取角色面前的可触发事件
  #--------------------------------------------------------------------------
  def eagle_get_event_there(triggers)
    x_p, y_p = get_collision_xy(@direction)
    x2 = $game_map.round_x_with_direction(x_p, @direction)
    y2 = $game_map.round_y_with_direction(y_p, @direction)
    e = eagle_get_map_event(x2, y2, triggers, true)
    return e if e
    x2_rgss, e = PIXEL_MOVE.unit2rgss(x2)
    y2_rgss, e = PIXEL_MOVE.unit2rgss(y2)
    return unless $game_map.counter?(x2_rgss, y2_rgss)
    # 柜台属性：向前方推进 RGSS 中的一格来查找事件
    x3 = $game_map.round_x_with_direction_n(x2, @direction,
      PIXEL_MOVE.pixel2unit(32))
    y3 = $game_map.round_y_with_direction_n(y2, @direction,
      PIXEL_MOVE.pixel2unit(32))
    e = eagle_get_map_event(x3, y3, triggers, true)
    return e
  end
end
end
#===============================================================================
# ○ Spriteset_Map
#===============================================================================
class Spriteset_Map
  #--------------------------------------------------------------------------
  # ● 生成人物精灵
  #--------------------------------------------------------------------------
  alias eagle_event_interact_create_characters create_characters
  def create_characters
    eagle_event_interact_create_characters
    @sprite_trigger_hint = Sprite.new(@viewport1)
    @sprite_trigger_hint.z = 500
  end
  #--------------------------------------------------------------------------
  # ● 释放人物精灵
  #--------------------------------------------------------------------------
  alias eagle_event_interact_dispose_characters dispose_characters
  def dispose_characters
    eagle_event_interact_dispose_characters
    EVENT_INTERACT.clear
    @sprite_trigger_hint.bitmap.dispose if @sprite_trigger_hint.bitmap
    @sprite_trigger_hint.dispose
  end
  #--------------------------------------------------------------------------
  # ● 更新人物精灵
  #--------------------------------------------------------------------------
  alias eagle_event_interact_update_characters update_characters
  def update_characters
    eagle_event_interact_update_characters
    EVENT_INTERACT.update(@sprite_trigger_hint, @character_sprites)
  end
end
