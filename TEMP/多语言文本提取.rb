# TODO

module MultiLang
  #--------------------------------------------------------------------------
  # ● 常量定义
  #--------------------------------------------------------------------------
  # 全部语言符号的数组
  ALL_LANG = [:CN, :EN, :JP]
  # 新游戏时默认语言的符号（注：每个存档的语言独立存储）
  DEFAULT_LANG = :CN
  # 无标签文本被归类语言的符号
  #（默认为 :ALL 代表全部语言下均显示 ）
  NO_LABEL_TEXT_TYPE = :ALL
  #--------------------------------------------------------------------------
  # ● 设置当前语言
  #--------------------------------------------------------------------------
  def self.set(symbol = DEFAULT_LANG)
    return if !ALL_LANG.include?(symbol)
    $game_system.symbol_lang = symbol
  end
  #--------------------------------------------------------------------------
  # ● 获取当前语言对应文本
  #--------------------------------------------------------------------------
  def self.get_text(text)
    sym_def = NO_LABEL_TEXT_TYPE
    sym_cur = $game_system.symbol_lang
    ALL_LANG.each do |l|
      # 无标签文本在全部语言下显示 or 无标签文本归类到 当前语言 下
      if sym_def == :ALL || sym_def == sym_cur
        # 将其余语言的文本清除
        next text.gsub!(/\[(#{l})\](.*?)\[\/\1\]/im) { l == sym_cur ? $2 : "" }
      end
      # 不需要无标签文本，提取出全部当前语言的文本并返回
      next if l != sym_cur
      return text.scan(/\[(#{l})\](.*?)\[\/\1\]/im).inject(""){|t, x| t + x[1] }
    end
    return text
  end
end # end of module MultiLang
class Game_System
  attr_accessor :symbol_lang
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  alias eagle_multilang_init initialize
  def initialize
    eagle_multilang_init
    @symbol_lang = MultiLang::DEFAULT_LANG # 当前语言的标记
  end
end

class Game_Message
  #--------------------------------------------------------------------------
  # ● 获取包括换行符的所有内容
  #--------------------------------------------------------------------------
  def all_text
    t = @texts.inject("") {|r, text| r += text + "\n" }
    t = MultiLang.get_text(t)
    t.gsub!(/\n/) { "" }
    t
  end
end
