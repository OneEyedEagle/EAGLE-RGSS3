#==============================================================================
# ■ 组件-通用方法汇总 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# 【此插件兼容VX和VX Ace】
#==============================================================================
$imported ||= {}
$imported["EAGLE-CommonMethods"] = "1.1.8"
#==============================================================================
# - 2024.1.19.23 event_comment_head 增加保留换行功能
#==============================================================================
# - 本插件提供了一系列通用方法，广泛应用于各种插件中
#---------------------------------------------------------------------------
# 【脚本版本判定】
#
#  EAGLE_COMMON.get_version(name)
#   → 获得 name 脚本的版本号数组，如[1, 0, 0]
#
#  EAGLE_COMMON.check_version(name, v1, v2=nil, v3=nil)
#   → 检查 name 脚本的版本号是否大于 v1.v2.v3 （v2和v3若未传入，则取0）
#
#---------------------------------------------------------------------------
# 【字符串解析】
#
#  EAGLE_COMMON.parse_tags(t)
#   → 解析 tags 字符串
#    （其中 {{a}} 在生成时被替换为eval后结果；{a} 将原样保留，需自己后续手动eval）
#     比如传入 "a=5 b=-1 c=测试"，返回 { :a => "5", :b => "-1", :c => "测试" }
#     请注意需要自己去执行 .to_i 来获得数字值
#
#  EAGLE_COMMON.eagle_eval(t, ps = {})
#   → 扩展的执行字符串t
#     （其中 s = $game_switches; v = $game_variables; ss = $game_self_switches
#       es = $game_map.events; gp = $game_player）
#     如果 ps 中存在 ps[:event] 的值，则可用 event 代表它
#
#  EAGLE_COMMON.check_bool(str, default=false)
#   → 检查字符串被eval后的真假
#     只有当字符串为 "1" 或 "true" 或 1 或 true 时，返回 true
#     只有当字符串为 "0" 或 "false" 或 0 或 false 时，返回 false
#     字符串为其它情况时，将返回传入的 default 的值
#
#---------------------------------------------------------------------------
# 【位图相关】
#
#  EAGLE_COMMON.bitmap_copy_do(b1, b2, o)
#   → 将b2位图拷贝到b1位图的对应位置
#      其中 o 为九宫格小键盘类型，
#       比如7代表 b1和b2的左上角对齐，5代表b1和b2中点对齐，6代表b1和b2的右边中点对齐
#
#  EAGLE_COMMON.draw_icon(bitmap, icon, x, y, w=24, h=24)
#   → 在bitmap位图的(x,y)位置绘制第icon号图标（该位置为绘制后图标的左上角）
#      其中w和h传入预留的可供绘制区域的宽高，用于保证能够居中绘制图标
#
#  EAGLE_COMMON.draw_face(bitmap, face_name, face_index, x, y, flag_draw=true)
#   → 在bitmap位图的(x,y)位置绘制文件名为face_name的第face_index号脸图
#     （该位置为绘制后脸图的左上角）
#      如果 face_name 中含有 _数字x数字，则为自定义的行数x列数（默认为2行4列）
#      如果 flag_draw 传入 false，则不会进行绘制，可以只用于获取脸图宽高
#     返回绘制脸图的宽和高两个数字
#
#  EAGLE_COMMON.draw_character(bitmap, character_name, character_index, x, y)
#   → 在bitmap位图的(x,y)位置绘制文件名为character_name的第character_index号行走图
#     （如果文件名带有 $，则 character_index 只有 0 有效）
#     （该位置为绘制行走图后的底部左端点的位置）
#     （绘制的为方向朝下的静止时的行走图）
#     返回行走图的单个图像的宽和高两个数字
#
#  EAGLE_COMMON.snapshot_custom(objs=[])
#   → 生成指定元素的截图
#      objs 数组中的全部元素都需要有 z 属性
#     返回生成的截图 bitmap
#
#  EAGLE_COMMON.img2rects(image, ps={})
#   → 将精灵/位图image均匀分隔为小矩形
#      ps 参数具体见方法的注释
#     返回 ss 为各个小矩形的精灵的数组，pos 为各个精灵的坐标[x,y]的数组
#
#---------------------------------------------------------------------------
# 【精灵相关】
#
#  EAGLE_COMMON.reset_sprite_oxy(obj, o, restore = true)
#   → 将 obj（精灵）的显示原点设置为 o 指定的类型
#      o 为九宫格小键盘类型，
#         比如 7 代表左上角设为原点，5 代表中点设为原点
#     若 restore 设置为 true，则不改变当前的显示位置，即自动修改x、y以适应新的原点
#
#  EAGLE_COMMON.reset_xy_dorigin(obj, obj2, o)
#   → 将 obj（精灵）的显示位置设置为 obj2 的指定位置
#     比如 o 为 7，则表示把 obj 的当前xy设置为 obj2 的左上角处
#     比如 o 为 3，则表示把 obj 的当前xy设置为 obj2 的右下角处
#     （如果 o 为负数，则表示 obj2 为当前屏幕，传入的obj2无效）
#
#  EAGLE_COMMON.reset_xy(obj, o, obj2, o2)
#   → 将 obj（精灵）的o位置 放置到 obj2 的o2位置
#     比如 o 为 7，o2 为 5，就是把 obj 的左上角放置到 obj2 的中点处
#
#  EAGLE_COMMON.rect_collide_rect?(rect1, rect2)
#   → 判定 rect1 （由RECT.new获得）是否与 rect2 碰撞（边界重叠也算碰撞）
#
#  EAGLE_COMMON.sprite_on_sprite?(s1, s2)
#   → 判定 精灵s1 是否与 精灵s2 存在重叠（依据实际占据屏幕的大小）
#
#  EAGLE_COMMON.point_in_sprite?(x, y, s, alpha=true)
#   → 判定屏幕坐标(x,y) 是否位于 精灵s 内（依据实际占据屏幕的大小）
#     （若 alpha 传入 true，则位于透明像素也算在精灵内，
#       否则位于透明像素时将返回 false，即点不在精灵内）
#
#---------------------------------------------------------------------------
# 【地图相关】
#
#  EAGLE_COMMON.get_map_data(map_id)
#   → 获取map_id号地图的数据，返回 RPG::Map 的实例map
#     之后可以用 event = map.events[event_id] 获取指定序号的 RPG::Event 实例
#
#---------------------------------------------------------------------------
# 【事件相关】
#
#  EAGLE_COMMON.get_chara(event, id)
#   → 获取id号的Game_Character对象（地图场景中），
#       传入的 event 为当前事件（当id号对象不存在时，将取当前事件）
#     若 id 为 0，则返回当前事件，若当前事件为nil，则返回玩家$game_player
#     若 id 为正整数，则返回地图上对应id号事件，若不存在，则返回当前事件
#     若 id 为负整数，则返回玩家队伍中对应数据库中 |id| 号的角色，若不存在，则为队首
#
#  EAGLE_COMMON.get_chara_sprite(id)
#   → 获取id号的Game_Character对象所对应的Sprite_Charactor精灵对象
#     若未找到，则返回 nil
#
#  EAGLE_COMMON.get_pic_sprite(id)
#   → 获取id号的显示图片所对应的Sprite_Picture精灵对象
#     若未找到，则返回 nil
#
#  EAGLE_COMMON.get_battler_sprite(id)
#   → 获取id号的Game_Battler对象（战斗场景中），
#     若 id 为正整数，则返回敌群中对应序号的敌人的Sprite_Battler
#     若 id 为负整数，则返回玩家队伍中对应数据库中 |id| 号的角色，若不存在，则返回nil
#
#  EAGLE_COMMON.forward_event_id(chara) 
#   → 获取 chara 面前一格的事件的ID
#       其中 chara 为 Game_CharacterBase 对象
#       如 $game_player 代表玩家，$game_map.events[id] 代表id号事件
#
#---------------------------------------------------------------------------
# 【事件页相关】
#
#  EAGLE_COMMON.event_comment_head(command_list, keep_newline=false)
#   → 获取事件页指令列表中开头的注释指令（可能包含多个连续的注释指令）
#     command_list 为事件页page的list属性，即RPG::Event::Page中的指令数组@list
#     keep_newline 传入 true 时，将保留编辑器中的换行，否则只导出单行文本
#
#---------------------------------------------------------------------------
# 【数据库相关】
#
#  EAGLE_COMMON.get_item_obj(type, id)
#   → 由标志字符与id，获得指定对象
#      type 为's'代表技能，'i'代表物品，'w'代表武器，'a'代表呼叫
#     比如 get_item_obj("i", 1) 将返回 $data_items[1]
#     比如 get_item_obj("w", 10) 将返回 $data_weapons[10]
#
#  EAGLE_COMMON.get_item_str(item, num = 1)
#   → 由指定对象，获取标志字符
#     比如 get_item_str($data_items[10]) 将返回 "i10"
#     比如 get_item_str($data_armors[1], 5) 将返回 "5a1"
#
#---------------------------------------------------------------------------
# 【菜单相关】
# 
#  $game_temp.last_menu_item
#   → （仅VA）获取最近一次在菜单中所使用物品/技能的实例
#
#==============================================================================

#===============================================================================
# □ 脚本版本判定
#===============================================================================
module EAGLE_COMMON
  #--------------------------------------------------------------------------
  # ●【常量】兼容
  #--------------------------------------------------------------------------
  MODE_VX = RUBY_VERSION[0..2] == "1.8"
  MODE_VA = RUBY_VERSION[0..2] == "1.9" 
  #--------------------------------------------------------------------------
  # ● 获取脚本的版本号
  #    name = "EAGLE-CommonMethods"
  #   如版本为 "1.0.2"，返回 [1, 0, 2]
  #--------------------------------------------------------------------------
  def self.get_version(name)
    if $imported[name]
      if $imported[name] == true
        return [1, 0, 0]
      elsif $imported[name].is_a?(String)
        s = $imported[name]
        ss = s.split(/\./)
        return ss.collect { |e| e.to_i }
      end
    end
    return [0, 0, 0]
  end
  #--------------------------------------------------------------------------
  # ● 判定指定脚本是否大于指定版本
  #  v1 为大版本，一般出现较大的变动，且使用方法也会发生变化
  #  v2 为功能更新，一般新增或删除了部分功能
  #  v3 为BUG修复，可以直接复制并覆盖
  #--------------------------------------------------------------------------
  def self.check_version(name, v1, v2=nil, v3=nil)
    v = get_version(name)
    f = true
    f = false if v[0] < v1.to_i
    f = false if v2 && v[1] < v2.to_i
    f = false if v3 && v[2] < v3.to_i
    p "【警告】在进行前置检测时，发现老鹰的 #{name} 版本过低！" if !f
    return f
  end
end

#==============================================================================
# □ 字符串解析
#===============================================================================
module EAGLE_COMMON
  #--------------------------------------------------------------------------
  # ● 解析tags文本
  #  其中 {{str}} 将作为脚本，被替换为运行的结果
  #  其中 {str} 将被完全保留，需要之后在实际调用时自己进行eval
  #   _t = "v=5, s={{v[1]}} t=测试"
  #   返回 { :v => "5", :s => "0", :t => "测试" }
  #--------------------------------------------------------------------------
  def self.parse_tags(_t)
    # 脚本替换
    _t.gsub!(/{{(.*?)}}/) { eagle_eval($1) }
    # 内容替换
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
  # ● 执行文本
  #--------------------------------------------------------------------------
  def self.eagle_eval(t, ps = {})
    s = $game_switches; v = $game_variables; ss = $game_self_switches
    es = $game_map.events
    gp = $game_player
    event = ps[:event] || nil
    begin
      eval(t.to_s)
    rescue
      p $!
    end
  end
  #--------------------------------------------------------------------------
  # ● 判断字符串的真假
  #  str = "1" 或 "true" 或 1 或 true
  #  返回 true
  #  str = "2", default=false
  #  返回 false
  #  str = "2", default=true
  #  返回 true
  #--------------------------------------------------------------------------
  def self.check_bool(str, default=false, ps={})
    return default if str.nil?
    v = eagle_eval(str, ps)
    return true if v == true || v == 1
    return false if v == false || v == 0
    return default
  end
end

#==============================================================================
# □ 位图相关
#===============================================================================
module EAGLE_COMMON
  #--------------------------------------------------------------------------
  # ● 依据原点类型（九宫格），将b2位图拷贝到b1位图对应位置
  # （需确保 b1 的宽高均大于 b2）
  # 如 o 为 2 时，将 b2 与 b1 底部中点对齐，再进行拷贝
  #--------------------------------------------------------------------------
  def self.bitmap_copy_do(b1, b2, o)
    x = y = 0
    case o
    when 1,4,7; x = 0
    when 2,5,8; x = b1.width / 2 - b2.width / 2
    when 3,6,9; x = b1.width - b2.width
    end
    case o
    when 1,2,3; y = b1.height - b2.height
    when 4,5,6; y = b1.height / 2 - b2.height / 2
    when 7,8,9; y = 0
    end
    b1.blt(x, y, b2, b2.rect)
  end
  #--------------------------------------------------------------------------
  # ● 绘制图标
  #--------------------------------------------------------------------------
  def self.draw_icon(bitmap, icon, x, y, w=24, h=24)
    _bitmap = Cache.system("Iconset")
    rect = Rect.new(icon % 16 * 24, icon / 16 * 24, 24, 24)
    bitmap.blt(x+w/2-12, y+h/2-12, _bitmap, rect, 255)
  end
  #--------------------------------------------------------------------------
  # ● 绘制角色肖像图
  #--------------------------------------------------------------------------
  def self.draw_face(bitmap, face_name, face_index, x, y, flag_draw=true)
    _bitmap = Cache.face(face_name)
    face_name =~ /_(\d+)x(\d+)_?/i  # 从文件名获取行数和列数（默认为2行4列）
    num_line = $1 ? $1.to_i : 2
    num_col = $2 ? $2.to_i : 4
    sole_w = _bitmap.width / num_col
    sole_h = _bitmap.height / num_line

    if flag_draw
      rect = Rect.new(face_index % 4 * sole_w, face_index / 4 * sole_h, sole_w, sole_h)
      des_rect = Rect.new(x, y, sole_w, sole_h)
      bitmap.stretch_blt(des_rect, _bitmap, rect)
    end
    return sole_w, sole_h
  end
  #--------------------------------------------------------------------------
  # ● 绘制人物行走图
  #  (x, y) 为行走图放置位置的底部左顶点的位置
  #--------------------------------------------------------------------------
  def self.draw_character(bitmap, character_name, character_index, x, y)
    return unless character_name
    _bitmap = Cache.character(character_name)
    sign = character_name[/^[\!\$]./]
    if sign && sign.include?('$')
      cw = _bitmap.width / 3
      ch = _bitmap.height / 4
    else
      cw = _bitmap.width / 12
      ch = _bitmap.height / 8
    end
    n = character_index
    src_rect = Rect.new((n%4*3+1)*cw, (n/4*4)*ch, cw, ch)
    bitmap.blt(x, y - ch, _bitmap, src_rect)
    return cw, ch
  end
  #--------------------------------------------------------------------------
  # ● 生成指定元素组的截图
  #  其中 objs 数组中的元素必须有 z 属性
  #--------------------------------------------------------------------------
  def self.snapshot_custom(objs=[])
    z_max = 65535
    sprite_back = Sprite.new
    sprite_back.bitmap = Bitmap.new(1,1)
    sprite_back.zoom_x = Graphics.width
    sprite_back.zoom_y = Graphics.height
    sprite_back.z = z_max
    objs.each { |s| s.z += z_max }
    b = Graphics.snap_to_bitmap
    objs.each { |s| s.z -= z_max }
    sprite_back.bitmap.dispose
    sprite_back.dispose
    return b
  end
  #--------------------------------------------------------------------------
  # ● 将图片均匀切割为横向ps[:nx]块、纵向ps[:ny]块
  # 传入 image 为位图或精灵
  #   若传入精灵，则精灵的xy将作为初始位置，否则为左上角
  # 传入 ps 为参数数组
  #   ps[:nx] （必须）横向的块数
  #   ps[:ny] （必须）纵向的块数
  #   ps[:vp] 生成的精灵的所处视图
  #   ps[:ox] ps[:oy] 精灵的显示原点（0~1之间的浮点数，默认不传入为0左上角）
  #
  # 返回 ss 为每一块的精灵的数组
  # 返回 pos 为每一个位置[x,y]的数组（同时为每个精灵的位置）
  #--------------------------------------------------------------------------
  def self.img2rects(image, ps={})
    if image.is_a?(Sprite)
      sprite = image
      bitmap = sprite.bitmap 
    end
    if image.is_a?(Bitmap)
      sprite = nil
      bitmap = image
    end
    ss = []; pos = []; w = bitmap.width; h = bitmap.height
    nx = ps[:nx] || 10  # 横方向的块数
    ny = ps[:ny] || 10  # 纵方向的块数
    dx = w / nx 
    dy = h / ny 
    nx.times do |i|
      ny.times do |j|
        b = Bitmap.new(dx, dy)
        _x = i * dx
        _y = j * dy 
        b.blt(0, 0, bitmap, Rect.new(_x, _y, dx, dy))
        s = Sprite.new(ps[:vp])
        s.bitmap = b 
        s.x = _x
        s.y = _y
        if sprite
          s.x += sprite.x - sprite.ox
          s.y += sprite.y - sprite.oy
        end
        if ps[:ox] # 0~1之间的小数
          s.ox = s.width * ps[:ox]
          s.x += s.ox
        end
        if ps[:oy]
          s.oy = s.height * ps[:oy]
          s.y += s.oy
        end
        pos.push([s.x, s.y])
        ss.push(s)
      end
    end
    return ss, pos
  end
end

#==============================================================================
# □ 精灵相关
#===============================================================================
module EAGLE_COMMON
  #--------------------------------------------------------------------------
  # ● 重置指定精灵的显示原点
  #  如果 restore 传入 true，则代表屏幕显示位置将保持不变，
  #    即自动调整xy的值，以适配新的oxy
  #--------------------------------------------------------------------------
  def self.reset_sprite_oxy(obj, o, restore = true)
    case o
    when 1,4,7; obj.ox = 0
    when 2,5,8; obj.ox = obj.width / 2
    when 3,6,9; obj.ox = obj.width
    end
    case o
    when 1,2,3; obj.oy = obj.height
    when 4,5,6; obj.oy = obj.height / 2
    when 7,8,9; obj.oy = 0
    end
    if restore
      obj.x += obj.ox
      obj.y += obj.oy
    end
  end
  #--------------------------------------------------------------------------
  # ● 重置指定对象依据另一对象小键盘位置的新位置
  #--------------------------------------------------------------------------
  def self.reset_xy_dorigin(obj, obj2, o) # 左上角和左上角对齐
    if o < 0 # o小于0时，将obj2重置为全屏
      obj2 = Rect.new(0,0,Graphics.width,Graphics.height)
      o = o.abs
    end
    case o
    when 1,4,7; obj.x = obj2.x
    when 2,5,8; obj.x = obj2.x + obj2.width / 2
    when 3,6,9; obj.x = obj2.x + obj2.width
    end
    case o
    when 1,2,3; obj.y = obj2.y + obj2.height
    when 4,5,6; obj.y = obj2.y + obj2.height / 2
    when 7,8,9; obj.y = obj2.y
    end
  end
  #--------------------------------------------------------------------------
  # ● 重置指定对象依位置
  #  obj 的 o位置 将与 obj2 的 o2位置 相重合
  #  假定 obj 与 obj2 目前均是左上角为显示原点，即若其有oxy属性，则值为0
  #--------------------------------------------------------------------------
  def self.reset_xy(obj, o, obj2, o2)
    # 先把 obj 的左上角放置于目的地
    case o2
    when 0,1,4,7; obj.x = obj2.x
    when 2,5,8; obj.x = obj2.x + obj2.width / 2
    when 3,6,9; obj.x = obj2.x + obj2.width
    end
    case o2
    when 0,1,2,3; obj.y = obj2.y + obj2.height
    when 4,5,6; obj.y = obj2.y + obj2.height / 2
    when 7,8,9; obj.y = obj2.y
    end
    # 再应用obj的o调整
    case o
    when 1,4,7;
    when 2,5,8; obj.x = obj.x - obj.width / 2
    when 3,6,9; obj.x = obj.x - obj.width
    end
    case o
    when 1,2,3; obj.y = obj.y - obj.height
    when 4,5,6; obj.y = obj.y - obj.height / 2
    when 7,8,9;
    end
  end

  #--------------------------------------------------------------------------
  # ● 精灵位于屏幕外？
  #--------------------------------------------------------------------------
  def self.out_of_screen?(s)
    s.x - s.ox + s.width < 0 || s.y - s.oy + s.height < 0 ||
    s.x - s.ox > Graphics.width || s.y - s.oy > Graphics.height
  end
  #--------------------------------------------------------------------------
  # ● 获取精灵实际占用矩形
  #--------------------------------------------------------------------------
  def self.get_rect(s)
    x = s.x - s.ox * s.zoom_x; y = s.y - s.oy * s.zoom_y
    w = s.width * s.zoom_x; h = s.height * s.zoom_y
    Rect.new(x, y, w, h)
  end
  #--------------------------------------------------------------------------
  # ● 矩形之间碰撞？
  #--------------------------------------------------------------------------
  def self.rect_collide_rect?(rect1, rect2)
    if((rect1.x > rect2.x && rect1.x > rect2.x + rect2.width-1) ||
       (rect1.x < rect2.x && rect1.x + rect1.width-1 < rect2.x) ||
       (rect1.y > rect2.y && rect1.y > rect2.y + rect2.height-1) ||
       (rect1.y < rect2.y && rect1.y + rect1.height-1 < rect2.y))
      return false
    end
    return true
  end
  #--------------------------------------------------------------------------
  # ● 精灵重叠？
  #--------------------------------------------------------------------------
  def self.sprite_on_sprite?(s1, s2)
    r1 = get_rect(s1)
    r2 = get_rect(s2)
    rect_collide_rect?(r1, r2)
  end
  #--------------------------------------------------------------------------
  # ● 点在精灵内？
  #--------------------------------------------------------------------------
  def self.point_in_sprite?(x, y, s, alpha=true)
    r = get_rect(s)
    if(x < r.x || x > r.x + r.width-1 ||
       y < r.y || y > r.y + r.height-1)
      return false
    end
    if alpha == false
      _x = x - (s.x - s.ox)
      _y = y - (s.y - s.oy)
      return false if s.bitmap.get_pixel(_x, _y).alpha == 0
    end
    return true
  end
end

#==============================================================================
# □ 地图相关
#===============================================================================
module EAGLE_COMMON
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
    EAGLE_COMMON.cache_load_map(map_id)
  end
end

#==============================================================================
# □ 事件相关
#===============================================================================
module EAGLE_COMMON
  #--------------------------------------------------------------------------
  # ● 获取事件对象
  #--------------------------------------------------------------------------
  def self.get_chara(event, id)
    if id == 0 # 当前事件
      return nil if event == nil
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
  # ● 获取地图事件的精灵
  #--------------------------------------------------------------------------
  def self.get_chara_sprite(id)
    return if !SceneManager.scene_is?(Scene_Map)
    charas_s = SceneManager.scene.spriteset.character_sprites
    chara = get_chara(nil, id)
    charas_s.each { |s| return s if s.character == chara }
    return nil
  end
  #--------------------------------------------------------------------------
  # ● 获取图片的精灵
  #--------------------------------------------------------------------------
  def self.get_pic_sprite(id)
    if SceneManager.scene_is?(Scene_Map) || SceneManager.scene_is?(Scene_Battle)
      ss = SceneManager.scene.spriteset.picture_sprites
      return ss[id]
    end 
    return nil
  end
  #--------------------------------------------------------------------------
  # ● 获取战斗角色的精灵
  #--------------------------------------------------------------------------
  def self.get_battler_sprite(id)
    return if !SceneManager.scene_is?(Scene_Battle)
    if id > 0
      ss = SceneManager.scene.spriteset.enemy_sprites
      return ss[id] || nil 
    else
      ss = SceneManager.scene.spriteset.actor_sprites
      ss.each { |s| return s if s.battler.id == id.abs }
      return nil 
    end
  end

  #--------------------------------------------------------------------------
  # ○ 获取角色面前一格的事件ID
  #--------------------------------------------------------------------------
  def self.forward_event_id(chara)
    x = $game_map.round_x_with_direction(chara.x, chara.direction)
    y = $game_map.round_y_with_direction(chara.y, chara.direction)
    events = $game_map.events_xy(x, y)
    return events.empty? ? 0 : events[0].id
  end
end
class Spriteset_Map
  attr_reader  :character_sprites, :picture_sprites
end
class Scene_Map
  attr_reader  :spriteset
end
class Spriteset_Battle
  attr_reader  :actor_sprites, :enemy_sprites, :picture_sprites
end
class Scene_Battle
  attr_reader  :spriteset
end

#==============================================================================
# □ 事件页相关
#===============================================================================
module EAGLE_COMMON
  #--------------------------------------------------------------------------
  # ● 读取事件页开头的注释组
  #--------------------------------------------------------------------------
  def self.event_comment_head(command_list, keep_newline = false)
    return "" if command_list.nil? || command_list.empty?
    t = ""; index = 0
    while command_list[index].code == 108 || command_list[index].code == 408
      t += command_list[index].parameters[0]
      t += '\n' if keep_newline
      index += 1
    end
    t
  end
end

#==============================================================================
# □ 数据库相关
#===============================================================================
module EAGLE_COMMON
  #--------------------------------------------------------------------------
  # ● 由物品标志字符获取指定对象
  #--------------------------------------------------------------------------
  def self.get_item_obj(type, id)
    case type
    when 's'; obj = $data_skills[id]
    when 'i'; obj = $data_items[id]
    when 'w'; obj = $data_weapons[id]
    when 'a'; obj = $data_armors[id]
    end
    return obj
  end
  #--------------------------------------------------------------------------
  # ● 由指定对象获取物品标志字符
  #--------------------------------------------------------------------------
  def self.get_item_str(item, num = 1)
    _type = ""
    c = item.class
    _type += "s" if c == RPG::Skill
    _type += "i" if c == RPG::Item
    _type += "w" if c == RPG::Weapon
    _type += 'a' if c == RPG::Armor
    t = _type + item.id.to_s
    t = num.to_s + t if num != 1
    return t
  end
end

if EAGLE_COMMON::MODE_VA
#==============================================================================
# □ 菜单相关
#===============================================================================
class Game_Temp
  attr_accessor :last_menu_item
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  alias eagle_common_functions_init initialize
  def initialize
    eagle_common_functions_init
    @last_menu_item = nil
  end
end
class Scene_ItemBase < Scene_MenuBase
  #--------------------------------------------------------------------------
  # ● 公共事件预定判定
  #    如果预约了事件的调用，则切换到地图画面。
  #--------------------------------------------------------------------------
  alias eagle_common_functions_check_common_event check_common_event
  def check_common_event
    $game_temp.last_menu_item = item
    eagle_common_functions_check_common_event
  end
end
end 
