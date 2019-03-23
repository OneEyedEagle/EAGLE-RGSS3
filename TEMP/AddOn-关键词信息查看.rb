#==============================================================================
# ■ Add-on 关键词信息查看 by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【对话框扩展 by老鹰】之下
#==============================================================================
# - 2019.3.23.16
#==============================================================================
#==============================================================================

module MESSAGE_EX
  KEYWORD_INFO = {
  # keyword => info (draw_text_ex),
    "执行者" => "奇迹之城中每一任的水晶守护者，被称为执行者。\n掌管对水晶能量的日常监控与紧急补偿。",
    "奇迹之城" => "据传是以前的神明为嘉奖跟随出征的人，\n赐下水晶，保佑一方人免遭沼泽威胁。",
  }
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
    @eagle_window_keyword_info.close
    eagle_keyword_info_close
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
      "\\font[u1uc17]#{c1}\\key[#{@eagle_keywords.size-1}]#{c2}\\font[u0uc0]"
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
    self.openness = 0
    @keywords = [] # [text, sprite_chara]
    @bitmaps = {} # id => bitmap
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
    super
  end
  #--------------------------------------------------------------------------
  # ● 重置清除
  #--------------------------------------------------------------------------
  def reset
    @keywords.clear
  end
  #--------------------------------------------------------------------------
  # ● 重绘
  #--------------------------------------------------------------------------
  def refresh
    keyword = @keywords[@index][0]
    text = "\ec[17]#{keyword}\ec[0] 注：\n"
    text += MESSAGE_EX.get_keyword_info(keyword)
    w, h = @message_window.eagle_calculate_text_wh(text, 0,
      [line_height - contents.font.size, 0].max)
    self.move(0, 0, w+standard_padding*2, h+standard_padding*2)
    create_contents
    draw_text_ex(0, 0, text)
  end
  #--------------------------------------------------------------------------
  # ● 重定位
  #--------------------------------------------------------------------------
  def reposition
    s_c = @keywords[@index][1]
    self.x = @message_window.eagle_charas_x0 + s_c.origin_x - self.width/2
    if @message_window.y > Graphics.height / 2
      # 显示到文字上方
      self.y = @message_window.eagle_charas_y0 + s_c.origin_y - self.height
    else
      self.y = @message_window.eagle_charas_y0 + s_c.origin_y + s_c.height
    end
    self.z = @message_window.z + 100
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
  end
  #--------------------------------------------------------------------------
  # ● 更新按键
  #--------------------------------------------------------------------------
  def update_key
    return if !QTE.trigger?(:TAB)
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
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    super
  end
end
