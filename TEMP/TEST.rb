# 留言式对话

# 对话一次性显示完，之后随时间渐隐
# Scene切换时仍然重新显示

module MESSAGE_BLOCK
  #--------------------------------------------------------------------------
  # ○【常量】当该序号开关开启时，事件的 显示文章 将替换成 聊天式对话
  #--------------------------------------------------------------------------
  S_ID = 21
  #--------------------------------------------------------------------------
  # ○【常量】定义初始的屏幕Z值
  #--------------------------------------------------------------------------
  INIT_Z = 100
  #--------------------------------------------------------------------------
  # ○【常量】定义固定显示的帧数
  #--------------------------------------------------------------------------
  WAIT_BEFORE_OUT = 90

  #--------------------------------------------------------------------------
  # ○【常量】定义对话文字的大小
  #--------------------------------------------------------------------------
  FONT_SIZE = 16
  #--------------------------------------------------------------------------
  # ○【常量】文本周围留出空白的宽度（用于绘制窗口的边框）
  #--------------------------------------------------------------------------
  TEXT_BORDER_WIDTH = 8
  #--------------------------------------------------------------------------
  # ○【常量】定义对话框皮肤
  #--------------------------------------------------------------------------
  ID_TO_SKIN = {}
  ID_TO_SKIN[0] = "Window"  # 默认窗口皮肤
  #--------------------------------------------------------------------------
  # ○【常量】定义默认使用的对话框皮肤
  #--------------------------------------------------------------------------
  DEF_SKIN_ID = 0

  #--------------------------------------------------------------------------
  # ● 从 显示文本 提取信息
  #--------------------------------------------------------------------------
  def self.extract_text_info(text, params)
    result = false # 是否成功导入了对话
    # 缩写
    s = $game_switches; v = $game_variables
    # 提取可能存在的flags
    text.gsub!( /<sym:? ?(.*?)>/im ) { params[:sym] = $1; "" }
    text.gsub!( /<skin:? ?(.*?)>/im ) { params[:skin] = $1; "" }
    text.gsub!( /<wait:? ?(.*?)>/im ) { params[:wait] = $1.to_i; "" }
    # 设置位置 当前对话框的o处，与 w/m/e 的o处相重合
    text.gsub!( /<o(\d+) ?pos:? ?(w\d+,\d+|m\d+,\d+|e-?\d+)o(\d+) ?(dx-?\d+dy-?\d+)?>/im ) {
      params[:pos] = [$1, $2, $3, $4]
      ""
    }
    # 提取位于开头的姓名
    n = ""
    text.sub!(/^【(.*?)】|\[(.*?)\]/m) { n = $1 || $2; "" }
    params[:name] = n
    # 提取可能存在的显示图片（将独立为新的对话框显示）
    text.gsub!(/<pic:? ?(.*?)>/im) {
      _params = params.dup
      _params[:pic] = $1
      $game_message.add_block(_params, params[:sym])
      result = true
      ""
    }
    # 提取文本 删去前后的换行
    text.chomp!
    text.sub!(/^\n/) { "" }
    params[:text] = text
    if text != ""
      $game_message.add_block(params, params[:sym])
      result = true
    end
    return result
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
  # ● 获取窗口皮肤名称
  #--------------------------------------------------------------------------
  def self.get_skin_name(sym)
    return ID_TO_SKIN[sym] if ID_TO_SKIN.has_key?(sym)
    return ID_TO_SKIN[sym.to_i] if ID_TO_SKIN.has_key?(sym.to_i)
    return sym
  end
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
    when 1,4,7; obj.x = obj2.x
    when 2,5,8; obj.x = obj2.x + obj2.width / 2
    when 3,6,9; obj.x = obj2.x + obj2.width
    end
    case o2
    when 1,2,3; obj.y = obj2.y + obj2.height
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
  # ● 更新精灵显示
  #--------------------------------------------------------------------------
  @blocks1 = {}
  @blocks2 = []
  def self.update
    $game_message.eagle_block_data1.each do |sym, d|
      next if d[:finish] == true
      @blocks1[sym] ||= Sprite_EagleMsgBlock.new(self, d)
      s = @blocks1[sym]
      s.reset(d) if d[:redraw] == true
      s.update
    end
    $game_message.eagle_block_data2.each do |d|
      s = Sprite_EagleMsgBlock.new(self, d)
      @blocks2.push(s)
    end
    $game_message.eagle_block_data2.clear
    @blocks2.delete_if { |s| s.finish? }
    @blocks2.each { |s| s.update }
  end
end
#===============================================================================
# ○ Scene_Base
#===============================================================================
class Scene_Base
  #--------------------------------------------------------------------------
  # ● 基础更新
  #--------------------------------------------------------------------------
  alias eagle_message_block_update_basic update_basic
  def update_basic
    eagle_message_block_update_basic
    MESSAGE_BLOCK.update
  end
end

#===============================================================================
# ○ Game_Message
#===============================================================================
class Game_Message
  attr_accessor  :eagle_block_data1, :eagle_block_data2
  #--------------------------------------------------------------------------
  # ● 清除
  #--------------------------------------------------------------------------
  alias eagle_message_block_clear clear
  def clear
    eagle_message_block_clear
    clear_block_params
  end
  #--------------------------------------------------------------------------
  # ● 重置
  #--------------------------------------------------------------------------
  def clear_block_params
    # 存储有 sym 的独立data，在重新回到地图上时，会再次显示
    #  同一时间只会显示一个
    @eagle_block_data1 = {} # sym => data_hash
    # 存储临时的data
    @eagle_block_data2 = []
  end
  #--------------------------------------------------------------------------
  # ● 新增一个文本块
  #--------------------------------------------------------------------------
  def add_block(data = {}, sym = nil)
    if sym
      @eagle_block_data1[sym] = data
      data[:redraw] = true
      data[:finish] = false
    else
      @eagle_block_data2.push(data)
    end
  end
end

#===============================================================================
# ○ Sprite_EagleMsgBlock
#===============================================================================
class Sprite_EagleMsgBlock < Sprite
  attr_reader :params
  #--------------------------------------------------------------------------
  # ● 初始时
  #--------------------------------------------------------------------------
  def initialize(_window, _params = {})
    super(nil)
    self.z = MESSAGE_BLOCK::INIT_Z
    @window = _window
    reset(_params)
  end
  #--------------------------------------------------------------------------
  # ● 重置
  #--------------------------------------------------------------------------
  def reset(_params)
    init_params(_params)
    redraw
    start
  end
  #--------------------------------------------------------------------------
  # ● 初始化参数（确保部分参数存在）
  #--------------------------------------------------------------------------
  def init_params(_params)
    @params = _params
    params[:face_name] ||= ""
    params[:face_index] ||= 0
    params[:background] ||= 0
    params[:position] ||= 1
    params[:text] ||= ""

    params[:skin] ||= MESSAGE_BLOCK::DEF_SKIN_ID
    params[:wait] ||= MESSAGE_BLOCK::WAIT_BEFORE_OUT
    params[:pos] ||= nil
    params[:redraw] = false
    params[:finish] = false
  end
  #--------------------------------------------------------------------------
  # ● 已经结束？
  #--------------------------------------------------------------------------
  def finish?
    params[:finish] == true
  end
  #--------------------------------------------------------------------------
  # ● 获取背景色 1
  #--------------------------------------------------------------------------
  def back_color1
    Color.new(0, 0, 0, 160)
  end
  #--------------------------------------------------------------------------
  # ● 获取背景色 2
  #--------------------------------------------------------------------------
  def back_color2
    Color.new(0, 0, 0, 0)
  end
  #--------------------------------------------------------------------------
  # ● 获取事件对象
  #--------------------------------------------------------------------------
  def get_event(id)
    if id == 0 # 当前事件
      return $game_map.events[params[:event_id]]
    elsif id > 0 # 第id号事件
      chara = $game_map.events[id]
      chara ||= $game_map.events[params[:event_id]]
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
  # ● 获取事件对象对应的精灵
  #--------------------------------------------------------------------------
  def get_event_sprite(obj)
    begin
      SceneManager.scene.spriteset.character_sprites.each do |s|
        return s if s.character == obj
      end
    rescue
    end
    return nil
  end
  #--------------------------------------------------------------------------
  # ● 重绘
  #--------------------------------------------------------------------------
  def redraw
    # 脸图宽高
    params[:face_w] = 0
    params[:face_h] = 0
    if params[:face_name] != ""
      params[:face_w], params[:face_h] = MESSAGE_BLOCK.draw_face(self.bitmap,
        params[:face_name],params[:face_index], 0, 0, false)
    end

    # 内容宽高
    params[:cont_w] = 0
    params[:cont_h] = 0
    #  若绘制文本
    if params[:text] != ""
      ps = { :font_size => MESSAGE_BLOCK::FONT_SIZE, :x0 => 0, :y0 => 0,
        :lhd => 2 }
      d = Process_DrawTextEX.new(params[:text], ps)
      d.run(false)
      params[:cont_w] = d.width
      params[:cont_h] = d.height
    end

    # 背景宽高
    params[:bg_w] = params[:face_w] + params[:cont_w] + MESSAGE_BLOCK::TEXT_BORDER_WIDTH * 2
    params[:bg_h] = [params[:cont_h], params[:face_h]].max + MESSAGE_BLOCK::TEXT_BORDER_WIDTH * 2

    # 实际位图宽高
    self.bitmap.dispose if self.bitmap
    w = params[:bg_w]
    h = params[:bg_h]
    self.bitmap = Bitmap.new(w, h)

    # 绘制背景
    params[:bg_x] = params[:bg_y] = 0
    case params[:background]
    when 0 # 普通背景
      skin = MESSAGE_BLOCK.get_skin_name(params[:skin])
      EAGLE.draw_windowskin(skin, self.bitmap,
        Rect.new(params[:bg_x], params[:bg_y], params[:bg_w], params[:bg_h]))
    when 1 # 暗色背景
      w = self.bitmap.width
      h = self.bitmap.height
      rect1 = Rect.new(0, 0, w, 12)
      rect2 = Rect.new(0, 12, w, h - 24)
      rect3 = Rect.new(0, h - 12, w, 12)
      self.bitmap.gradient_fill_rect(rect1, back_color2, back_color1, true)
      self.bitmap.fill_rect(rect2, back_color1)
      self.bitmap.gradient_fill_rect(rect3, back_color1, back_color2, true)
    when 2 # 透明背景
    end

    # 绘制脸图
    if params[:face_name] != ""
      face_x = MESSAGE_BLOCK::TEXT_BORDER_WIDTH
      face_y = MESSAGE_BLOCK::TEXT_BORDER_WIDTH
      MESSAGE_BLOCK.draw_face(self.bitmap, params[:face_name],
        params[:face_index], face_x, face_y, true)
    end

    # 绘制内容
    cont_x = params[:bg_x] + params[:face_w] + MESSAGE_BLOCK::TEXT_BORDER_WIDTH
    cont_y = params[:bg_y] + MESSAGE_BLOCK::TEXT_BORDER_WIDTH
    if params[:text] != ""
      ps = { :font_size => MESSAGE_BLOCK::FONT_SIZE, :x0 => cont_x, :y0 => cont_y,
        :lhd => 2 }
      d = Process_DrawTextEX.new(params[:text], ps, self.bitmap)
      d.run(true)
    elsif params[:pic] != ""
      bitmap_pic = Cache.picture(params[:pic]) rescue Cache.empty_bitmap
      rect = Rect.new(0, 0, bitmap_pic.width, bitmap_pic.height)
      des_rect = Rect.new(cont_x, cont_y, params[:cont_w], params[:cont_h])
      self.bitmap.stretch_blt(des_rect, bitmap_pic, rect)
    end
  end

  #--------------------------------------------------------------------------
  # ● 开始显示
  #--------------------------------------------------------------------------
  def start
    process_position
    @fiber = Fiber.new { fiber_main }
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
    update_position
    @fiber.resume if @fiber
  end
  #--------------------------------------------------------------------------
  # ● 处理位置参数
  #--------------------------------------------------------------------------
  def process_position
    if params[:pos]
      # ["o", "w12,25" | "m1,6" | "e5", "o2", "dx1dy1"]
      h = {}
      h[:o] = params[:pos][0].to_i
      h[:o2] = params[:pos][2].to_i
      h[:dx] = 0
      h[:dy] = 0
      if params[:pos][3]
        dxy = params[:pos][3].split( /dx|dy/ )
        h[:dx] = dxy[1].to_i
        h[:dy] = dxy[-1].to_i
      end
      case params[:pos][1].slice!( /[wme]/i )
      when 'w'
        h[:type] = :win
        xy = params[:pos][1].split( /,/ )
        h[:wx] = xy[0].to_i
        h[:wy] = xy[1].to_i
      when 'm'
        h[:type] = :map
        xy = params[:pos][1].split( /,/ )
        h[:mx] = xy[0].to_i
        h[:my] = xy[1].to_i
      when 'e'
        h[:type] = :event
        h[:id] = params[:pos][1].to_i
        h[:obj] = get_event(h[:id])
        s = get_event_sprite(h[:obj])
        h[:obj_w] = s.width
        h[:obj_h] = s.height
      end
      params[:pos_update] = h
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新位置参数
  #--------------------------------------------------------------------------
  def update_position
    return if params[:pos_update].nil?
    h = params[:pos_update]
    r = Rect.new
    case h[:type]
    when :win
      # 屏幕坐标
      r.set(h[:wx], h[:wy], 0, 0)
    when :map
      # 地图格子的左上角
      _x = $game_map.adjust_x(h[:mx]) * 32
      _y = $game_map.adjust_y(h[:my]) * 32
      r.set(_x, _y, 32, 32)
    when :event
      # 事件的底部中心点坐标
      _x = h[:obj].screen_x - h[:obj_w] / 2
      _y = h[:obj].screen_y - h[:obj_h]
      # 修改为图像的左上角坐标
      r.set(_x, _y, h[:obj_w], h[:obj_h])
    end
    MESSAGE_BLOCK.reset_xy(self, h[:o], r, h[:o2])
    MESSAGE_BLOCK.reset_sprite_oxy(self, h[:o])
  end

  #--------------------------------------------------------------------------
  # ● 主线程
  #--------------------------------------------------------------------------
  def fiber_main
    until_move_end_zoom(:in)
    params[:wait].times { Fiber.yield }
    until_move_end_zoom(:out)
    params[:finish] = true
    @fiber = nil
  end

  #--------------------------------------------------------------------------
  # ● 移入移出（淡入淡出）
  #--------------------------------------------------------------------------
  def until_move_end_fade(type = :in, t = 20)
    if type == :in
      self.opacity = 0
    elsif type == :out
      self.opacity = 255
    end
    loop do
      Fiber.yield
      if type == :in
        self.opacity += 3
        break if self.opacity >= 255
      elsif type == :out
        self.opacity -= 3
        break if self.opacity <= 0
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 移入移出（放缩）
  #--------------------------------------------------------------------------
  def until_move_end_zoom(type = :in, t = 20)
    _i = 0; _t = t
    _init = 0; _d = 0
    if type == :in
      _init = 0.0
      _d = 1.0
    elsif type == :out
      _init = 1.0
      _d = -1.0
    end
    self.zoom_x = self.zoom_y = _init
    while(true)
      break if _i > _t
      per = _i * 1.0 / _t
      per = (_i == _t ? 1 : ease_value(:zoom, per))
      v = _init + _d * per
      self.zoom_x = self.zoom_y = v
      Fiber.yield
      _i += 1
    end
  end
  #--------------------------------------------------------------------------
  # ● 缓动函数
  #--------------------------------------------------------------------------
  def ease_value(type, x)
    if $imported["EAGLE-EasingFunction"]
      return EasingFuction.call("easeOutBack", x)
    end
    return 1 - 2**(-10 * x)
  end
end

#===============================================================================
# ○ Game_Interpreter
#===============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 显示文字
  #--------------------------------------------------------------------------
  alias eagle_message_block_command_101 command_101
  def command_101
    if $game_switches[MESSAGE_BLOCK::S_ID]
      call_message_block
      return
    end
    eagle_message_block_command_101
  end
  #--------------------------------------------------------------------------
  # ● 呼叫聊天对话
  #--------------------------------------------------------------------------
  def call_message_block
    params = {}
    params[:event_id] = @event_id
    params[:face_name] = @params[0]
    params[:face_index] = @params[1]
    params[:background] = @params[2]
    params[:position] = @params[3]

    ts = []
    while next_event_code == 401       # 文字数据
      @index += 1
      ts.push(@list[@index].parameters[0])
    end
    t = ts.inject("") {|r, text| r += text + "\n" }
    result = MESSAGE_BLOCK.extract_text_info(t, params)

    if $imported["EAGLE-MessageLog"]
      ps = {}
      ps[:name] = params[:name] if !params[:name].empty?
      MSG_LOG.new_log(params[:text], ps) if params[:text] != ""
    end
  end
end
