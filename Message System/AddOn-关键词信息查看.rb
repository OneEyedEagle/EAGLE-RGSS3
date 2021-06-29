#==============================================================================
# ■ Add-On 关键词信息查看 by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【对话框扩展 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-MsgKeywordInfo"] = true
#==============================================================================
# - 2021.6.28.16 优化提示精灵
#==============================================================================
# - 本插件新增 \key[word] 转义符，对话框绘制完成后，可以逐个查看 word 的详细信息
#------------------------------------------------------------------------------
# 【功能说明】
#
# - 在对话框打开时，当已有关键词被绘制，按下指定按键可以打开详细信息窗口
#     默认设置的指定按键为 SHIFT 键
#
# - 在第一次按下 SHIFT键，将定位到最后绘制的关键词，并显示它的预设信息文本
#   再次按下 SHIFT键，将跳转到前一个关键词处，并同步更新显示它的信息文本
#   当已经显示第一个关键词时，再次按下 SHIFT键，将关闭信息窗口
#
#------------------------------------------------------------------------------
# 【高级：更改关键词的信息文本】
#
# - 利用脚本对指定关键词的信息文本进行增减（本质为将多个关键词的文本进行叠加）
#
#      $game_message.change_keyword_info(keyword, do_type, keyword2)
#
#    keyword 为需要执行操作的关键词（字符串）
#    do_type 为需要执行的操作（对数组的操作）
#       :push → 将 keyword2 的文本加到当前关键词信息文本的后面
#       :pop → 删去新增的位于末尾的关键词
#       :unshift → 将 keyword2 的文本加到当前关键词信息文本的前面
#       :shift → 删去新增的位于首位的关键词
#       :delete → 删去新增的全部 keyword2 关键词
#
#   示例：
#     关键词 "测试1" 预设的信息文本为 "测试用文本1号"
#     关键词 "测试2" 预设的信息文本为 "测试用文本2号"
#     则操作 $game_message.change_keyword_info("测试1", :push, "测试2")
#     将会把 keyword_1 对应的信息文本变更为 "测试用文本1号\n测试用文本2号"
#     而操作 $game_message.change_keyword_info("测试1", :pop, "测试2")
#     将会把 keyword_1 对应的信息文本变更为 "测试用文本1号"
#
#------------------------------------------------------------------------------
# 【注意】
#
#   为了不因为本插件而过度修改对话框，已被查看过的关键词，不开放重新绘制的设置。
#
#------------------------------------------------------------------------------
# 【原理】
#
#    在 Window_Message类 的 eagle_text_control_key 方法中，进行了关键词增加。
#    在 Window_Keyword_Info类 中，处理了按键与显示切换。
#
#==============================================================================
module MESSAGE_EX
  #--------------------------------------------------------------------------
  # ● 【设置】按键激活？
  #--------------------------------------------------------------------------
  def self.keyword_trigger?
    Input.trigger?(:A)  # SHIFT键
  end
  #--------------------------------------------------------------------------
  # ● 【设置】提示文本
  #--------------------------------------------------------------------------
  KEYWORD_HINT1 = "SHIFT"
  KEYWORD_HINT2 = "查看"

  #--------------------------------------------------------------------------
  # ● 【设置】定义关键词的信息文本
  # （可以使用VA默认对话框中的转义符，其中\n代表换行）
  #--------------------------------------------------------------------------
  KEYWORD_INFO = {
  # keyword => info (draw_text_ex),
    "浮空遗迹" => "坐落于DEMO村东方的奇妙的浮空遗迹，\n虽然理应没有了作用，但有翻新的痕迹。",
    "湛蓝水晶" => "据传是以前的神明为嘉奖跟随出征的人而赐下的水晶。",
  }
  #--------------------------------------------------------------------------
  # ● 【设置】定义对话框中，关键词的前后需要插入的文本
  # （可以使用 对话框扩展 中的转义符，需要用 \\ 代替 \ ）
  #--------------------------------------------------------------------------
  KEYWORD_PREFIX = "\\font[u1uc17]"
  KEYWORD_SURFIX = "\\font[u0uc0]"
  #--------------------------------------------------------------------------
  # ● 【设置】定义关键词信息前后需要插入的文本
  # （可以使用VA默认对话框中的转义符，其中\n代表换行）
  #  \keyword 将会被替换成对应的关键词
  #--------------------------------------------------------------------------
  KEYWORD_INFO_PREFIX = "\ec[17]\keyword\ec[0] 注：\n"
  KEYWORD_INFO_SURFIX = ""
  #--------------------------------------------------------------------------
  # ● 【设置】定义关键词信息窗口的皮肤INDEX
  # （见 对话框扩展 中的 INDEX_TO_WINDOWSKIN ）
  #--------------------------------------------------------------------------
  KEYWORD_WINDOWSKIN_INDEX = 1
  #--------------------------------------------------------------------------
  # ● 【设置】定义关键词信息窗口的远离文字的像素值
  # （同 对话框扩展 中的 \pop 的 d 变量）
  #--------------------------------------------------------------------------
  KEYWORD_WINDOW_D = 8
  #--------------------------------------------------------------------------
  # ● 【设置】定义关键词信息窗口的TAG皮肤的INDEX
  # （见 对话框扩展 中的 INDEX_TO_WINDOWTAG ）
  #--------------------------------------------------------------------------
  KEYWORD_WINDOWTAG_INDEX = 1
  #--------------------------------------------------------------------------
  # ● 【设置】定义关键词信息窗口的TAG的远离文字的像素值
  # （同 对话框扩展 中的 \pop 的 td 变量）
  #--------------------------------------------------------------------------
  KEYWORD_WINDOWTAG_D = 4

  #--------------------------------------------------------------------------
  # ● 获取关键词的信息文本
  #--------------------------------------------------------------------------
  def self.get_keyword_info(keyword)
    if $game_message.keywords_info[keyword]
      s = ""
      $game_message.keywords_info[keyword].each do |word|
        if KEYWORD_INFO[word]
          s += "\n" if s != ""
          s += KEYWORD_INFO[word]
        end
      end
      return s
    end
    return KEYWORD_INFO[keyword] || ""
  end
end

#=============================================================================
# ○ Game_Message
#=============================================================================
class Game_Message
  attr_reader  :keywords_info
  #--------------------------------------------------------------------------
  # ● 清除
  #--------------------------------------------------------------------------
  alias eagle_keyword_info_clear clear
  def clear
    eagle_keyword_info_clear
    @keywords_info = {} # keyword => info_array
  end
  #--------------------------------------------------------------------------
  # ● 变更关键词的文本
  #--------------------------------------------------------------------------
  def change_keyword_info(keyword, do_type, keyword2 = nil)
    @keywords_info[keyword] = [keyword] if @keywords_info[keyword] == nil
    case do_type
    when :push;  @keywords_info[keyword].push(keyword2) if keyword2
    when :unshift; @keywords_info[keyword].unshift(keyword2) if keyword2
    when :pop;   @keywords_info[keyword].pop
    when :shift; @keywords_info[keyword].shift
    when :delete; @keywords_info[keyword].delete(keyword2)
    end
    @keywords_info.delete(keyword) if @keywords_info[keyword].empty?
  end
end

#=============================================================================
# ○ Window_EagleMessage
#=============================================================================
class Window_EagleMessage
  #--------------------------------------------------------------------------
  # ● 初始化组件
  #--------------------------------------------------------------------------
  alias eagle_keyword_info_init_params eagle_message_init_params
  def eagle_message_init_params
    @eagle_keywords = [] # [text]
    @eagle_window_keyword_info = Window_Keyword_Info.new(self)
    eagle_keyword_info_init_params
  end
  #--------------------------------------------------------------------------
  # ● 关闭
  #--------------------------------------------------------------------------
  alias eagle_keyword_info_close close
  def close
    eagle_keyword_info_close
    @eagle_keywords.clear
    @eagle_window_keyword_info.reset
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  alias eagle_keyword_info_update update
  def update
    eagle_keyword_info_update
    @eagle_window_keyword_info.update
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  alias eagle_keyword_info_dispose dispose
  def dispose
    @eagle_window_keyword_info.dispose
    eagle_keyword_info_dispose
  end
  #--------------------------------------------------------------------------
  # ● 翻页处理（覆盖）
  #--------------------------------------------------------------------------
  alias eagle_keyword_info_new_page new_page
  def new_page(text, pos)
    @eagle_window_keyword_info.reset
    eagle_keyword_info_new_page(text, pos)
  end
  #--------------------------------------------------------------------------
  # ● 替换转义符（此时依旧是 \\ 开头的转义符）
  #--------------------------------------------------------------------------
  alias eagle_keyword_info_process_conv eagle_process_conv
  def eagle_process_conv(text)
    text = eagle_keyword_info_process_conv(text)
    text.gsub!(/\\key\[(.*?)\]/i) {
      c1 = $1[0]; c2 = $1[1..-1]; @eagle_keywords.push($1)
      t =  MESSAGE_EX::KEYWORD_PREFIX
      t += "#{c1}\\key[#{@eagle_keywords.size-1}]#{c2}"
      t += MESSAGE_EX::KEYWORD_SURFIX
      t
    }
    text
  end
  #--------------------------------------------------------------------------
  # ● 设置key参数
  #--------------------------------------------------------------------------
  def eagle_text_control_key(param = "")
    if @eagle_chara_sprites[-1]
      text = @eagle_keywords[param.to_i]
      @eagle_window_keyword_info.add_keyword(text, @eagle_chara_sprites[-1])
    end
  end
end

#=============================================================================
# ○ 关键字信息显示窗口
#=============================================================================
class Window_Keyword_Info < Window_Base
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(message_window)
    @message_window = message_window
    super(0, 0, 24, 24)
    self.windowskin = MESSAGE_EX.windowskin(MESSAGE_EX::KEYWORD_WINDOWSKIN_INDEX)
    self.openness = 0
    @keywords = [] # [text, sprite_chara]
    @bitmaps = {} # id => bitmap

    @sprite_tag = Sprite.new
    @sprite_tag.bitmap = MESSAGE_EX.windowtag(MESSAGE_EX::KEYWORD_WINDOWTAG_INDEX)
    w = @sprite_tag.bitmap.width
    h = @sprite_tag.bitmap.height
    @sprite_tag.src_rect.set(0,0, w/3, h/3)
    @sprite_tag.visible = false

    @sprite_hint = Sprite.new
    t1 = MESSAGE_EX::KEYWORD_HINT1
    t2 = MESSAGE_EX::KEYWORD_HINT2
    b = Bitmap.new(32, 32)
    b.font.size = 16
    r1 = b.text_size(t1)
    r2 = b.text_size(t2)
    b.dispose
    @sprite_hint.bitmap = Bitmap.new(4 + 2+r1.width+2 + 2+r2.width+2 + 4,
      4+r1.height+4 + 4)
    @sprite_hint.bitmap.font.size = 16
    @sprite_hint.bitmap.font.outline = false
    @sprite_hint.bitmap.font.shadow = false

    @sprite_hint.bitmap.fill_rect(0, 0, @sprite_hint.width,
      @sprite_hint.height - 4, Color.new(255,255,255,255))
    @sprite_hint.bitmap.clear_rect(1, 1, @sprite_hint.width-2,
      4+r2.height+4 - 2)

    @sprite_hint.bitmap.fill_rect(4, 4, 2+r1.width+2, r1.height,
      Color.new(255,255,255,255))
    @sprite_hint.bitmap.font.color = Color.new(0,0,0,255)
    @sprite_hint.bitmap.draw_text(4+2, 4, r1.width * 2, r1.height, t1, 0)

    @sprite_hint.bitmap.font.color = Color.new(255,255,255,255)
    @sprite_hint.bitmap.draw_text(4 + 2+r1.width+2 + 4, 4,
      r2.width * 2, r2.height, t2, 0)

    @sprite_hint.bitmap.clear_rect(@sprite_hint.width / 2-3,
      @sprite_hint.height-5, 7, 2)
    [ [-3,1],[3,1], [-2,2],[2,2], [-1,3],[1,3], [0,4] ].each do |xy|
      @sprite_hint.bitmap.set_pixel(@sprite_hint.width / 2 + xy[0],
       @sprite_hint.height - 5 + xy[1], Color.new(255,255,255,255))
    end

    @sprite_hint.ox = @sprite_hint.width / 2
    @sprite_hint.oy = @sprite_hint.height
    @state_hint = :init
    @count_hint = 0
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    @bitmaps.delete(@index)
    @bitmaps.each { |i, b| b.dispose }
    @sprite_hint.bitmap.dispose
    @sprite_hint.dispose
    @sprite_tag.dispose
    super
  end
  #--------------------------------------------------------------------------
  # ● 新增关键词
  #--------------------------------------------------------------------------
  def add_keyword(text, sprite_chara)
    @keywords.push([text, sprite_chara])
  end
  #--------------------------------------------------------------------------
  # ● 打开
  #--------------------------------------------------------------------------
  def open
    return if self.openness > 0
    @index = @keywords.size - 1
    refresh
    reposition
    super
  end
  #--------------------------------------------------------------------------
  # ● 关闭
  #--------------------------------------------------------------------------
  def close
    super()
    self.openness -= 1  # 保证tag精灵不会被再次显示
    @sprite_tag.visible = false
  end
  #--------------------------------------------------------------------------
  # ● 重置清除
  #--------------------------------------------------------------------------
  def reset
    @keywords.clear
    @bitmaps.each { |i, b| b.dispose }
    @bitmaps.clear
    create_contents_no_dispose
    close
  end
  #--------------------------------------------------------------------------
  # ● 生成窗口内容（不释放原本位图）
  #--------------------------------------------------------------------------
  def create_contents_no_dispose
    if contents_width > 0 && contents_height > 0
      self.contents = Bitmap.new(contents_width, contents_height)
    else
      self.contents = Bitmap.new(1, 1)
    end
  end
  #--------------------------------------------------------------------------
  # ● 重绘
  #--------------------------------------------------------------------------
  def refresh
    if !@bitmaps.has_key?(@index)
      keyword = @keywords[@index][0]
      text =  MESSAGE_EX::KEYWORD_INFO_PREFIX.dup
      text.sub!(/\keyword/) { keyword }
      text += MESSAGE_EX.get_keyword_info(keyword)
      text += MESSAGE_EX::KEYWORD_INFO_SURFIX
      dh = [line_height - contents.font.size, 0].max
      text = @message_window.convert_escape_characters(text)
      w, h = MESSAGE_EX.calculate_text_wh(contents, text, 0, dh)
      h += dh # 最后一行补足高度
      self.move(0, 0, w+standard_padding*2, h+standard_padding*2)
      create_contents_no_dispose
      draw_text_ex(0, 0, text)
      @bitmaps[@index] = self.contents
    else
      w, h = @bitmaps[@index].width, @bitmaps[@index].height
      self.move(0, 0, w+standard_padding*2, h+standard_padding*2)
      self.contents = @bitmaps[@index]
    end
  end
  #--------------------------------------------------------------------------
  # ● 获取第i个关键词的首字符精灵的左上角xy（屏幕坐标）
  #--------------------------------------------------------------------------
  def get_keyword_xy(i)
    s_c = @keywords[i][1]
    _x = @message_window.eagle_charas_x0 - @message_window.eagle_charas_ox
    _x += s_c.origin_x
    _y = @message_window.eagle_charas_y0 - @message_window.eagle_charas_oy
    _y += s_c.origin_y
    return _x, _y
  end
  #--------------------------------------------------------------------------
  # ● 重定位
  #--------------------------------------------------------------------------
  def reposition
    _x, _y = get_keyword_xy(@index)
    self.x = _x - self.width/2
    up =  @message_window.y > Graphics.height / 2
    if up # 窗口显示到文字上方
      self.y = _y - self.height - MESSAGE_EX::KEYWORD_WINDOW_D
    else # 窗口显示到文字下方
      s_c = @keywords[@index][1]
      self.y = _y + s_c.height + MESSAGE_EX::KEYWORD_WINDOW_D
    end
    fix_position
    self.z = @message_window.z + 100

    o = up ? 2 : 8
    MESSAGE_EX.set_windowtag(self, @sprite_tag, o, 10 - o, o)
    if up
      @sprite_tag.y -= MESSAGE_EX::KEYWORD_WINDOWTAG_D
    else
      @sprite_tag.y += MESSAGE_EX::KEYWORD_WINDOWTAG_D
    end
    @sprite_tag.z = self.z + 1
  end
  #--------------------------------------------------------------------------
  # ● 修正位置，确保完整显示
  #--------------------------------------------------------------------------
  def fix_position
    self.x = [[self.x, 0].max, Graphics.width - self.width].min
    self.y = [[self.y, 0].max, Graphics.height - self.height].min
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
    update_key if @message_window.open?
    @sprite_tag.visible = true if self.openness == 255
    update_hint
  end
  #--------------------------------------------------------------------------
  # ● 更新按键
  #--------------------------------------------------------------------------
  def update_key
    return if !MESSAGE_EX.keyword_trigger?
    return if @keywords.empty?
    return open if self.openness < 255
    move_left
  end
  #--------------------------------------------------------------------------
  # ● 显示上一个关键词
  #--------------------------------------------------------------------------
  def move_left
    @index -= 1
    return close if @index < 0
    refresh
    reposition
  end
  #--------------------------------------------------------------------------
  # ● 更新提示按键
  #--------------------------------------------------------------------------
  def update_hint
    case @state_hint
    when :init
      return if @keywords.size == 0
      i = @index || @keywords.size - 1
      if self.openness > 0
        i_old = i
        i = (i - 1 + @keywords.size) % @keywords.size
        return if i == i_old
      end
      _x, @_y = get_keyword_xy(i)
      @sprite_hint.x = _x
      @sprite_hint.y = @_y
      @sprite_hint.z = @message_window.z + 99
      @sprite_hint.opacity = 0
      @count_hint = 0
      @state_hint = :show
    when :show
      if @count_hint < 180
      else
        @sprite_hint.opacity += 5
        if @count_hint > 280
          @count_hint = 0
          @state_hint = :jump
        end
      end
    when :jump
      t = @count_hint % 60
      if t <= 10
        h = 15
        y1 = (t-5)**2 * h * 1.0/25 - h
        @sprite_hint.y = @_y + y1
      end
      if @count_hint > 150
        @count_hint = 0
        @state_hint = :hide
      end
    when :hide
      @sprite_hint.opacity -= 5
      if @count_hint > 100
        @count_hint = 0
        @state_hint = :fin
      end
    when :fin
      if @count_hint > 240
        @count_hint = 0
        @state_hint = :init
      end
    end
    @count_hint += 1
  end
end
