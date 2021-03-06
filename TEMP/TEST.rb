# 留言式对话

# 对话一次性显示完，之后随时间渐隐
# Scene切换时仍然重新显示


module MESSAGE_BLOCK
  #--------------------------------------------------------------------------
  # ○【常量】当该序号开关开启时，事件的 显示文章 将替换成 聊天式对话
  #--------------------------------------------------------------------------
  S_ID = 15
  #--------------------------------------------------------------------------
  # ○【常量】当S_ID序号开关开启时，该开关开启时，将重新使用默认对话框
  #  即不关闭 聊天式对话 的同时使用默认对话框
  #  【注意】需要手动关闭该开关，以确保聊天式对话能够正常继续使用！
  #--------------------------------------------------------------------------
  S_ID_MSG = 14
  #--------------------------------------------------------------------------
  # ○【常量】定义初始的视图矩形
  #--------------------------------------------------------------------------
  INIT_VIEW = Rect.new(20, 30, Graphics.width-20*2, Graphics.height-30*2)
  #--------------------------------------------------------------------------
  # ○【常量】定义初始的屏幕Z值
  #--------------------------------------------------------------------------
  INIT_Z = 10
  #--------------------------------------------------------------------------
  # ○【常量】定义文本块的初始Y位置（在视图中的位置）
  # 其中 <vph> 将被替换为视图的高度，<th> 将被替换成文本块的高度
  # 如 "<vph> - <th>" 代表最新的对话将位于视图的最底部
  #--------------------------------------------------------------------------
  INIT_TEXT_Y = "<vph> - <th>"
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
    # 定义类型
    params[:type] = :text
    # 提取可能存在的flags
    text.gsub!( /<no ?wait>/im ) { params[:flag_no_wait] = true; "" }
    text.gsub!( /<skin:? ?(.*?)>/im ) { params[:skin] = $1; "" }
    text.gsub!( /<unsend:? ?(.*?)>/im ) { params[:unsend] = eval($1).to_i; "" }
    # 提取位于开头的姓名
    n = ""
    text.sub!(/^【(.*?)】|\[(.*?)\]/m) { n = $1 || $2; "" }
    params[:name] = n
    # 提取可能存在的显示图片（将独立为新的对话框显示）
    text.gsub!(/<pic:? ?(.*?)>/im) {
      _params = params.dup
      _params[:pic] = $1
      $game_message.add_chat(_params)
      result = true
      ""
    }
    # 提取文本 删去前后的换行
    text.chomp!
    text.sub!(/^\n/) { "" }
    params[:text] = text
    if text != ""
      $game_message.add_chat(params)
      result = true
    end
    return result
  end

  #--------------------------------------------------------------------------
  # ● 绘制角色肖像图
  #--------------------------------------------------------------------------
  def self.draw_face(bitmap, face_name, face_index, x, y, w=96, h=96)
    _bitmap = Cache.face(face_name)
    face_name =~ /_(\d+)x(\d+)_?/i  # 从文件名获取行数和列数（默认为2行4列）
    num_line = $1 ? $1.to_i : 2
    num_col = $2 ? $2.to_i : 4
    sole_w = _bitmap.width / num_col
    sole_h = _bitmap.height / num_line

    rect = Rect.new(face_index % 4 * sole_w, face_index / 4 * sole_h, sole_w, sole_h)
    des_rect = Rect.new(x, y, w, h)
    bitmap.stretch_blt(des_rect, _bitmap, rect)
  end
  #--------------------------------------------------------------------------
  # ● 获取窗口皮肤名称
  #--------------------------------------------------------------------------
  def self.get_skin_name(sym)
    return ID_TO_SKIN[sym] if ID_TO_SKIN.has_key?(sym)
    return ID_TO_SKIN[sym.to_i] if ID_TO_SKIN.has_key?(sym.to_i)
    return sym
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
    else
      @eagle_block_data2.push(data)
    end
  end
end

#===============================================================================
# ○ Window_EagleMessage_Block
#===============================================================================
class Window_EagleMessage_Block < Window
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize
    super
    self.openness = 0
    @blocks1 = {}
    @blocks2 = []
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    super
    @blocks1.each { |k, b| b.dispose }
    @blocks1.clear
  end

  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
    update_blocks
  end
  #--------------------------------------------------------------------------
  # ● 更新文本块
  #--------------------------------------------------------------------------
  def update_blocks
    $game_message.eagle_block_data1.each do |sym, d|
      @blocks1[sym] ||=
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
    @window = _window
    init_params(_params)
    redraw
  end
  #--------------------------------------------------------------------------
  # ● 初始化参数（确保部分参数存在）
  #--------------------------------------------------------------------------
  def init_params(_params)
    @params = _params
    params[:text] ||= ""
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
  end
  #--------------------------------------------------------------------------
  # ● 重绘
  #--------------------------------------------------------------------------
  def redraw
    # 内容宽高
    params[:cont_w] = 0
    params[:cont_h] = 0
    #  若绘制文本
    if params[:text] != ""
      ps = { :font_size => MESSAGE_CHAT::FONT_SIZE, :x0 => 0, :y0 => 0,
        :w => params[:cont_w_max], :lhd => 2 }
      d = Process_DrawTextEX.new(params[:text], ps)
      d.run(false)
      params[:cont_w] = d.width
      params[:cont_h] = d.height
    end

    params[:bg_w] = [params[:cont_w] + MESSAGE_CHAT::TEXT_BORDER_WIDTH * 2, 32].max
    params[:bg_h] = [params[:cont_h] + MESSAGE_CHAT::TEXT_BORDER_WIDTH * 2, 32].max

    # 实际位图宽高
    w = params[:spacing_lr] * 2 + params[:face_w] + params[:tag_w] +
      [params[:cont_w] + MESSAGE_CHAT::TEXT_BORDER_WIDTH * 2, params[:name_w],
       32].max
    h = params[:spacing_ud] * 2 + params[:spacing_name] +
      [params[:name_h] + params[:cont_h] + MESSAGE_CHAT::TEXT_BORDER_WIDTH * 2,
       params[:face_h], 32].max
    self.bitmap = Bitmap.new(w, h)
    
    # 绘制背景
    params[:bg_x] = params[:bg_y] = 0
    case params[:background]
    when 0 # 普通背景
      skin = MESSAGE_CHAT.get_skin_name(params[:skin])
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

    # 绘制内容
    cont_x = params[:bg_x] + MESSAGE_CHAT::TEXT_BORDER_WIDTH
    cont_y = params[:bg_y] + MESSAGE_CHAT::TEXT_BORDER_WIDTH
    if params[:text] != ""
      ps = { :font_size => MESSAGE_CHAT::FONT_SIZE, :x0 => cont_x, :y0 => cont_y,
        :w => cont_x+params[:cont_w_max], :lhd => 2 }
      d = Process_DrawTextEX.new(params[:text], ps, self.bitmap)
      d.run(true)
    elsif params[:pic] != ""
      bitmap_pic = Cache.picture(params[:pic]) rescue Cache.empty_bitmap
      rect = Rect.new(0, 0, bitmap_pic.width, bitmap_pic.height)
      des_rect = Rect.new(cont_x, cont_y, params[:cont_w], params[:cont_h])
      self.bitmap.stretch_blt(des_rect, bitmap_pic, rect)
    end
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
    if $game_switches[MESSAGE_CHAT::S_ID]
      if $game_switches[MESSAGE_CHAT::S_ID_MSG] == false
        call_message_block
        return
      end
    end
    eagle_message_block_command_101
  end
  #--------------------------------------------------------------------------
  # ● 呼叫聊天对话
  #--------------------------------------------------------------------------
  def call_message_block
    params = {}
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
    result = MESSAGE_CHAT.extract_text_info(t, params)

    if $imported["EAGLE-MessageLog"]
      ps = {}
      ps[:name] = params[:name] if !params[:name].empty?
      MSG_LOG.new_log(params[:text], ps) if params[:text] != ""
    end
  end
end

#===============================================================================
# ○ Scene_Map
#===============================================================================
class Scene_Map < Scene_Base
  #--------------------------------------------------------------------------
  # ● 生成滚动文字窗口
  #--------------------------------------------------------------------------
  alias eagle_message_block_scroll_window create_scroll_text_window
  def create_scroll_text_window
    eagle_message_block_scroll_window
    @eagle_message_block_window = Window_EagleMessage_Block.new
  end
end
#===============================================================================
# ○ Scene_Battle
#===============================================================================
class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # ● 生成滚动文字窗口
  #--------------------------------------------------------------------------
  alias eagle_message_block_scroll_window create_scroll_text_window
  def create_scroll_text_window
    eagle_message_block_scroll_window
    @eagle_message_block_window = Window_EagleMessage_Block.new
  end
end
