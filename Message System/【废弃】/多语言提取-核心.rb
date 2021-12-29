#==============================================================================
# ■ 多语言提取-核心 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
$imported ||= {}
$imported["EAGLE-MultiLangCore"] = true
#=============================================================================
# - 2019.10.13.11
#=============================================================================
# - 本插件提供了从字符串中提取指定语言的标签对内容的方法
# - 利用 <sym></sym> 标签对编写不同语言的内容
#   其中 sym 替换成所设置的语言符号的字符串
# - 示例：
#     t = "<cn>...</cn><en>...</en>"
#     t2 = MultiLang.extract(t)
#     若当前语言为 :CN，则 t2 = "<cn>...</cn>"
#-----------------------------------------------------------------------------

module MultiLang
  #--------------------------------------------------------------------------
  # ● 常量
  #--------------------------------------------------------------------------
  # 全部语言符号的数组
  # （推荐符号全大写，但在文本中标签大小写均可）
  ALL_LANGUAGES = [:CN, :EN, :JP]
  # 新游戏时默认语言的符号（注：每个存档的语言独立存储）
  DEFAULT_LANGUAGE = :CN
  # 无标签文本被归类语言的符号
  #（默认为 :ALL 代表全部语言下均显示 ）
  NO_LABEL_TEXT_TYPE = :ALL
  #--------------------------------------------------------------------------
  # ● 设置当前语言
  #--------------------------------------------------------------------------
  def self.set(sym = DEFAULT_LANGUAGE)
    return if !ALL_LANGUAGES.include?(sym)
    $game_system.eagle_lang = sym
  end
  #--------------------------------------------------------------------------
  # ● 提取当前语言的文本
  #--------------------------------------------------------------------------
  def self.extract(text)
    sym_def = NO_LABEL_TEXT_TYPE
    sym_cur = $game_system.eagle_lang
    ALL_LANGUAGES.each do |l|
      # 无标签文本在全部语言下显示 or 无标签文本归类到 当前语言 下
      if sym_def == :ALL || sym_def == sym_cur
        # 将其余语言的文本清除
        next text.gsub!(/<(#{l})>(.*?)<\/\1>/im) { l == sym_cur ? $2 : "" }
      end
      # 不需要无标签文本，提取出全部当前语言的文本并返回
      next if l != sym_cur
      return text.scan(/\[(#{l})\](.*?)\[\/\1\]/im).inject(""){|t, x| t + x[1] }
    end
    return text
  end
end # end of module MultiLang

class Game_System
  attr_accessor :eagle_lang
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  alias eagle_multilang_init initialize
  def initialize
    eagle_multilang_init
    @eagle_lang = MultiLang::DEFAULT_LANGUAGE # 存储当前语言的标记
  end
end

#class Game_Message
#  def all_text
#    t = @texts.inject("") {|r, text| r += text + "\n" }
#    t = MultiLang.extract(t)
#    t.gsub!(/\n/) { "" }
#    t
#  end
#end
