#==============================================================================
# ■ Add-On 关键词信息查看 by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【对话框扩展 by老鹰】之下
#==============================================================================
# - 2019.7.6.20 整合对话框扩展
#==============================================================================
# - 本插件新增 \key[word] 转义符，在对话框打开时，可以逐个查看 word 的详细信息文本
# - 在对话框打开时，当已经有关键词 word 被绘制时，能够按下指定按键打开信息窗口
#     指定按键：第一次按下时，定位到最后绘制的 关键词 前，
#              再次按下，向前一个关键词跳转显示，直至没有关键词并关闭信息窗口
#     信息窗口：显示对应关键词的预设的信息文本
# - 出于不修改主插件数据的原则，已经绘制完的被查看过的关键词，不新增显示变更
# -【高级】在 Window_Message类 的 eagle_text_control_key 方法中，进行了关键词增加
#    在 Window_Keyword_Info类 中，处理了按键与显示切换
#==============================================================================

module MESSAGE_EX
  #--------------------------------------------------------------------------
  # ● 【设置】按键激活？
  #--------------------------------------------------------------------------
  def self.keyword_trigger?
    Input.trigger?(:A)
  end
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
  # ● 【设置】定义关键词前后需要插入的文本
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
  KEYWORD_WINDOWTAG_INDEX = 2
  #--------------------------------------------------------------------------
  # ● 【设置】定义关键词信息窗口的TAG的远离文字的像素值
  # （同 对话框扩展 中的 \pop 的 td 变量）
  #--------------------------------------------------------------------------
  KEYWORD_WINDOWTAG_D = 3
  #--------------------------------------------------------------------------
  # ● 【设置】定义提示文本的内容
  # （具体设置见 Window_Keyword_Info类 中的 @sprite_hint 精灵实例）
  #--------------------------------------------------------------------------
  KEYWORD_KEY_HINT = "  ○ Shift键 - 查看关键词信息"
  #--------------------------------------------------------------------------
  # ● 获取关键词的信息文本
  #--------------------------------------------------------------------------
  def self.get_keyword_info(keyword)
    KEYWORD_INFO[keyword] || ""
  end
end
#=============================================================================
# ○ Window_Message
#=============================================================================
class Window_Message
  #--------------------------------------------------------------------------
  # ● 初始化组件
  #--------------------------------------------------------------------------
  alias eagle_keyword_info_init_assets eagle_message_init_assets
  def eagle_message_init_assets
    @eagle_keywords = [] # [text]
    @eagle_window_keyword_info = Window_Keyword_Info.new(self)
    eagle_keyword_info_init_assets
  end
  #--------------------------------------------------------------------------
  # ● 关闭
  #--------------------------------------------------------------------------
  alias eagle_keyword_info_close close
  def close
    eagle_keyword_info_close
    @eagle_window_keyword_info.close
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  alias eagle_keyword_info_update update
  def update
    eagle_keyword_info_update
    @eagle_window_keyword_info.update
    @eagle_window_keyword_info.update_key if self.open?
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

    @sprite_tag_bitmap = MESSAGE_EX.windowtag(MESSAGE_EX::KEYWORD_WINDOWTAG_INDEX)
    w = @sprite_tag_bitmap.width
    h = @sprite_tag_bitmap.height
    @sprite_tag = Sprite.new
    @sprite_tag.bitmap = Bitmap.new(w/3, h/3)

    @sprite_hint = Sprite.new
    @sprite_hint.y = Graphics.height - 50 # 调整hint文本所在的y位置
    @sprite_hint.bitmap = Bitmap.new(Graphics.width/2, line_height)
    @sprite_hint.bitmap.gradient_fill_rect(@sprite_hint.bitmap.rect,
      Color.new(0,0,0,150), Color.new(0,0,0,0))
    @sprite_hint.bitmap.draw_text(0,1,@sprite_hint.width,@sprite_hint.height,
      MESSAGE_EX::KEYWORD_KEY_HINT, 0)
    @sprite_hint.visible = false
  end
  #--------------------------------------------------------------------------
  # ● 新增关键词
  #--------------------------------------------------------------------------
  def add_keyword(text, sprite_chara)
    @keywords.push([text, sprite_chara])
    @sprite_hint.visible = true
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
  def close(hint_close = true)
    @sprite_hint.visible = false if hint_close
    @sprite_tag.visible = false
    super()
  end
  #--------------------------------------------------------------------------
  # ● 重置清除
  #--------------------------------------------------------------------------
  def reset
    @keywords.clear
    @bitmaps.each { |i, b| b.dispose }
    @bitmaps.clear
    create_contents_no_dispose
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
  # ● 重定位
  #--------------------------------------------------------------------------
  def reposition
    s_c = @keywords[@index][1]
    self.x = @message_window.eagle_charas_x0 - @message_window.eagle_charas_ox
    self.x = self.x + s_c.origin_x - self.width/2
    @sprite_tag.x = self.x + (self.width - @sprite_tag.width) / 2

    up =  @message_window.y > Graphics.height / 2
    if up # 窗口显示到文字上方
      self.y = @message_window.eagle_charas_y0 - @message_window.eagle_charas_oy
      self.y = self.y + s_c.origin_y - self.height
      @sprite_tag.y = self.y + self.height
      self.y -= MESSAGE_EX::KEYWORD_WINDOW_D
    else # 窗口显示到文字下方
      self.y = @message_window.eagle_charas_y0 - @message_window.eagle_charas_oy
      self.y = self.y + s_c.origin_y + s_c.height
      @sprite_tag.y = self.y
      self.y += MESSAGE_EX::KEYWORD_WINDOW_D
    end
    self.z = @message_window.z + 100

    MESSAGE_EX.windowtag_o(self, @sprite_tag, @sprite_tag_bitmap, up ? 2 : 8)
    if up
      @sprite_tag.y -= MESSAGE_EX::KEYWORD_WINDOWTAG_D
    else
      @sprite_tag.y += MESSAGE_EX::KEYWORD_WINDOWTAG_D
    end
    @sprite_tag.z = self.z + 1

    fix_position
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
    @sprite_tag.visible = true if self.open?
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
    return close(false) if @index < 0
    refresh
    reposition
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    @bitmaps.delete(@index)
    @bitmaps.each { |i, b| b.dispose }
    @sprite_hint.bitmap.dispose
    @sprite_hint.dispose
    @sprite_tag_bitmap.dispose
    @sprite_tag.bitmap.dispose
    @sprite_tag.dispose
    super
  end
end
