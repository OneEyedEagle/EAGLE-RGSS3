#==============================================================================
# ■ 组件-通用方法汇总 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
$imported ||= {}
$imported["EAGLE-CommonMethods"] = "1.0.3"
#==============================================================================
# - 2022.2.10.22
#==============================================================================
# - 本插件提供了一系列通用方法，广泛应用于各种插件中
#===============================================================================

#==============================================================================
# □ 脚本版本判定
#===============================================================================
module EAGLE_COMMON
  #--------------------------------------------------------------------------
  # ● 获取脚本的版本号
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
# □ 文本相关
#===============================================================================
module EAGLE_COMMON
  #--------------------------------------------------------------------------
  # ● 解析tags文本
  #  其中 {{str}} 将作为脚本，被替换为运行的结果
  #  其中 {str} 将被完全保留，需要之后在实际调用时自己进行eval
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
  def self.eagle_eval(t)
    s = $game_switches; v = $game_variables
    es = $game_map.events
    eval(t)
  end
  #--------------------------------------------------------------------------
  # ● 判断字符串的真假
  #--------------------------------------------------------------------------
  def self.check_bool(str, default=false)
    return default if str.nil?
    v = eagle_eval(str)
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
  # 需确保 b1 的宽高均大于 b2
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
end

#==============================================================================
# □ 地图数据相关
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
  # ● 获取事件精灵
  #--------------------------------------------------------------------------
  def self.get_chara_sprite(id)
    return if !SceneManager.scene_is?(Scene_Map)
    charas_s = SceneManager.scene.spriteset.character_sprites
    chara = get_chara(nil, id)
    charas_s.each { |s| return s if s.character == chara }
    return nil
  end
end
class Spriteset_Map
  attr_reader  :character_sprites
end
class Scene_Map
  attr_reader  :spriteset
end

#==============================================================================
# □ 事件页相关
#===============================================================================
module EAGLE_COMMON
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
end

#==============================================================================
# □ 精灵相关
#===============================================================================
module EAGLE_COMMON
  #--------------------------------------------------------------------------
  # ● 重置指定精灵的显示原点
  #  如果 restore 传入 true，则代表屏幕显示位置将保持不变，即自动调整xy的值，以适配新的oxy
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
