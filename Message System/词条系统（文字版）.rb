#==============================================================================
# ■ 词条系统（文字版） by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【组件-位图绘制转义符文本 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-Dictionary"] = true
#==============================================================================
# - 2021.8.25.20 新增词条文本滚动/翻页切换
#==============================================================================
# - 本插件新增了简易的文字版词条收集系统，并增加了一个简易的显示UI
#------------------------------------------------------------------------------
# 【介绍】
#
# - 在许多游戏中都有针对部分词汇的详细说明文本，
#   比如游戏自创的概念，不仅在对话中需要提及，还需要在菜单中详细介绍，帮助理解。
#   但默认中并没有此类系统，因此本插件尝试新增了一个简单的纯文本的词条系统（含UI）。
#
#---------------------------------------------------------------------------
# 【词条新增：事件指令-注释】
#
# - 在 事件指令-注释 中，编写 《新增词条 ...》 来解锁指定词条。
#  （具体形式可以通过修改 COMMENT_UNLOCK 这个正则表达式来改变。）
#
#     其中 ... 替换为词条名称，不同词条名称之间使用空格分隔。
#
#     其中 词条名称 后面使用 | 来分隔不同的信息词。
#
# - 特别的，为了方便词条文本的更新，本插件引入了词条的信息词，
#     在解锁词条时，能选择同时解锁其信息词。
#     在编写词条文本时，可以方便对信息词进行判定来变更文本。
#
# - 示例：
#
#    《新增词条 主角1》  → 解锁名称为 "主角1" 的词条
#
#    《新增词条 主角1 主角2》  → 解锁名称为 "主角1" 与 "主角2" 的词条
#
#    《新增词条 主角1|基本信息|介绍1》
#       → 解锁名称为 "主角1" 的词条，同时解锁它的 "基本信息" 和 "介绍1" 的信息词
#          如果文本中含有 {ifs 基本信息}...{/ifs}，则会显示其中文本
#
#---------------------------------------------------------------------------
# 【词条新增：全局脚本】
#
# - 使用全局脚本 DICT.add(name, syms) 来解锁某个词条
#
#     其中 name 为词条的名称，如 "主角1"，"主角2"
#
#     其中 syms 为信息词数组，可以省略，如 []，如["基本信息"]
#
# - 示例：
#
#     DICT.add("主角1") → 解锁名称为 "主角1" 的词条
#
#     DICT.add("主角1", ["基本信息", "介绍1"])
#       → 解锁名称为 "主角1" 的词条，同时解锁它的 "基本信息" 和 "介绍1" 的信息词
#
#---------------------------------------------------------------------------
# 【词条编写】
#
# - 由于默认事件并不方便进行大批文本的编写与修改，而外置文件又面临加密后的读取问题，
#   本插件使用了原始的脚本内编写预设文本的方式。
#
# - 推荐在本插件的下一页脚本中，新增一个空白页，命名为“词条预设”，
#   并复制如下的内容，进行修改和扩写：
#
=begin
# --------复制以下的内容！--------

module DICT  # 必须的模块名称，不要修改
DATA ||= {}  # 如果放置在本插件上面，就需要这一句

DATA["词条"] = [ "类别", "文本"]

DATA["主角1"] = ["人物",
"这是这个DEMO的主要角色。

{ifs基本信息}\ec[1]基本信息\ec[0]
身高大概175cm？体重估计是70kg。
对自己身材非常不自信，但因为太懒了并没有任何动作。
{/ifs}

{ifs介绍1}“我说，这样就足够了？也太简单了吧。”
在帮助了被小混混骚扰的书店后，甚至有点意犹未尽。{/ifs}

总之就是这样一个难搞的人。
"]

end  # 必须的结尾，不要漏掉

# --------复制以上的内容！--------
=end
#
# - 以下针对第一个词条进行说明：
#
#   其中 DATA["词条"] 中的 词条 替换为该词条的名称（不可重名）
#     如 "主角1" "第一章" "主角2"
#
#   其中 "类别" 中的 类别 替换为该词条的所属类别（用 | 分隔不同类别）
#     如 "主线任务" "支线任务|人物" "地理" "人物|历史"
#
#     在UI中显示时，全部已收集词条的类别会自动提取并去重。
#     类别相同的将显示在同一列表中。
#
#   其中，"文本" 中的 文本 替换为该词条的具体描述内容
#
#   特别的，有如下编写规则：
#
#   ·用 \e 替换 \ 来使用默认对话框中的转义符
#       如 \ec[0] 变更文字颜色、\e{ 放大字号
#
#   ·用 \n 来表示换行，或直接在字符串中进行换行
#       如 "这是第一行\n这是第二行" 或
#"这是第一行
#这是第二行"
#
#     特别的，空行会被自动删除，因此若想添加空行，请增加一个空格来占位。
#
#   ·用 {{string}} 来编写会被率先替换的脚本执行文本。
#       如 {{v[1]}} 会被替换为 1号变量 的内容。
#       如 {{s[1] ? "开启" : "关闭"}} 当1号开关开启时，显示 开启，否则显示 关闭。
#
#   ·用 {if string}...{/if} 来编写需要满足指定条件才会显示的文本。
#       如 {if s[1]&&s[2]}...{/if} 只有当1号开关和2号开关都开启，才显示其中文本。
#
#   ·用 {if1 string}...{/if1} {if2 string}...{/if2} 等后缀数字来编写嵌套的if。
#       当新增了数字后，该if的范围更加明确，否则默认取最靠近的结尾{/if}。
#       其中的后缀数字可以为任意正整数。
#
#   ·用 {ifs sym}...{/ifs} 来编写只有 sym 信息词被解锁时，才会显示的文本。
#       如 {ifs 基本信息}...{/ifs} 只有当该词条的 基本信息 解锁时，才会显示。
#
#   ·用 {ifs1 sym}...{/ifs1} {ifs2 sym}...{/ifs2} 等后缀数字来嵌套ifs。
#
#---------------------------------------------------------------------------
# 【呼叫UI】
#
# - 利用全局脚本 DICT.start 来呼叫本插件编写的简易UI
#   同样可以在事件脚本中调用，将立即暂停其他内容，优先处理词条UI
#
#---------------------------------------------------------------------------
# 【联动】
#
# - 当使用了【AddOn-并行对话 by老鹰】或【并行式对话 by老鹰】，
#   在新增词条时，将显示提示文本窗口，若不想使用该功能，请注释掉 show_hint 方法。
#
#===============================================================================

#===============================================================================
# ○ 常量设置
#===============================================================================
module DICT
  #--------------------------------------------------------------------------
  # ○【常量】事件指令-注释 中新增词条的文本
  #  其中 (.*?) 中利用空格分隔不同词条，词条与解锁信息间使用 | 分隔
  #--------------------------------------------------------------------------
  COMMENT_UNLOCK = /《新增词条 ?(.*?)》/i
  #--------------------------------------------------------------------------
  # ○【常量】UI - 左侧词条列表的宽度
  #--------------------------------------------------------------------------
  LIST_WIDTH = 150
  #--------------------------------------------------------------------------
  # ○【常量】UI - 类别文本的字体大小
  #--------------------------------------------------------------------------
  CATE_FONT_SIZE = 20
  #--------------------------------------------------------------------------
  # ○【常量】UI - 详细信息文本的字体大小
  #--------------------------------------------------------------------------
  INFO_FONT_SIZE = 16
  #--------------------------------------------------------------------------
  # ○【常量】UI - 提示文本的字体大小
  #--------------------------------------------------------------------------
  HINT_FONT_SIZE = 14
  #--------------------------------------------------------------------------
  # ○【常量】UI - 详细信息文本等待绘制时的文本
  #--------------------------------------------------------------------------
  TEXT_WAIT = "读取中..."
  #--------------------------------------------------------------------------
  # ○【常量】UI - 详细信息文本绘制前的等待时间
  #--------------------------------------------------------------------------
  TIME_WAIT = 40
end

#===============================================================================
# ○ DICT
#===============================================================================
module DICT
  #--------------------------------------------------------------------------
  # ● 词条预设
  #--------------------------------------------------------------------------
  DATA ||= {}
  #--------------------------------------------------------------------------
  # ● 新增指定词条及信息
  #--------------------------------------------------------------------------
  def self.add(sym, syms = nil)
    if $game_system.eagle_dict.has_key?(sym)
      $game_system.eagle_dict[sym] += syms if syms
      add_hint(:add, sym, syms)
    else
      $game_system.eagle_dict[sym] = syms || []
      add_hint(:new, sym, syms)
    end
    $game_system.eagle_dict_new.push(sym)
  end
  #--------------------------------------------------------------------------
  # ● 待显示的提示文本
  #--------------------------------------------------------------------------
  @data_hints = []
  def self.add_hint(type, sym, syms)
    @data_hints.push([type, sym, syms])
  end
  #--------------------------------------------------------------------------
  # ● 获取指定词条的已解锁信息组
  #--------------------------------------------------------------------------
  def self.info(sym)
    if $game_system.eagle_dict.has_key?(sym)
      return $game_system.eagle_dict[sym]
    else
      return []
    end
  end
  #--------------------------------------------------------------------------
  # ● 获取指定词条的类别组
  #--------------------------------------------------------------------------
  def self.category(sym)
    if DATA.has_key?(sym)
      t = DATA[sym][0]
      return t.split('|')
    else
      return []
    end
  end
  #--------------------------------------------------------------------------
  # ● 获取指定词条的文本
  #--------------------------------------------------------------------------
  def self.text(sym)
    if DATA.has_key?(sym)
      t = DATA[sym][1]
      t = process_text(sym, t.dup)
      return t
    else
      return "（暂无对应信息。）"
    end
  end
  #--------------------------------------------------------------------------
  # ● 处理文本
  #--------------------------------------------------------------------------
  def self.process_text(sym, t)
    s = $game_switches; v = $game_variables
    t.gsub!(/\{\{(.*?)\}\}/mi) { eval($1) }
    t.gsub!(/\{if ?(.*?)\}(.*?)\{\/if\}/mi) { eval($1) == true ? $2 : "" }
    t.gsub!(/\{if(\d+) ?(.*?)\}(.*?)\{\/if\1\}/mi) { eval($2) == true ? $3 : "" }
    ss = self.info(sym)
    t.gsub!(/\{ifs ?(.*?)\}(.*?)\{\/ifs\}/mi) { ss.include?($1) ? $2 : "" }
    t.gsub!(/\{ifs(\d+) ?(.*?)\}(.*?)\{\/ifs\1\}/mi) { ss.include?($2) ? $3 : "" }
    # 清除多余的重复换行符
    t.gsub!(/(\n){1,}/) { "\n" }
    t.chop!
    t
  end
  #--------------------------------------------------------------------------
  # ● 显示提示
  #--------------------------------------------------------------------------
  def self.show_hint
    return if @data_hints.empty?
    if $imported["EAGLE-MessagePara"]
      return if MESSAGE_PARA.list_exist?(:dict)
      t = ""
      @data_hints.each do |data|
        pre = data[0] == :new ? "新增词条" : "词条更新"
        t += "#{pre}：#{data[1]}\n"
      end
      t = "<msg>\\win[do-2 o5 dx0dy-100 w0h0 fw1fh1 z250]\\ins#{t}</msg>"
      MESSAGE_PARA.add(:dict, t)
      @data_hints.clear
      return
    end
    if $imported["EAGLE-MessagePara2"]
      return if !MESSAGE_PARA2.finish?(:dict)
      t = ""
      @data_hints.each do |data|
        pre = data[0] == :new ? "新增词条" : "词条更新"
        t += "#{pre}：#{data[1]}\n"
      end
      d = { :text => t,
      :pos => { :o => 5, :wx => Graphics.width/2, :wy => Graphics.height-100 } }
      MESSAGE_PARA2.add(:dict, d)
      @data_hints.clear
      return
    end
  end
end
#===============================================================================
# ○ Game_System
#===============================================================================
class Game_System
  #--------------------------------------------------------------------------
  # ● 存储已有词条
  #--------------------------------------------------------------------------
  def eagle_dict
    @eagle_dict ||= {} # 词条 => [解锁词]
    @eagle_dict
  end
  #--------------------------------------------------------------------------
  # ● 存储需要绘制“新”的词条
  #--------------------------------------------------------------------------
  def eagle_dict_new
    @eagle_dict_new ||= []
    @eagle_dict_new
  end
end
#===============================================================================
# ○ Game_Interpreter
#===============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 添加注释
  #--------------------------------------------------------------------------
  alias eagle_dict_command_108 command_108
  def command_108
    eagle_dict_command_108
    @comments.each do |t|
      if t =~ DICT::COMMENT_UNLOCK
        ks = $1.split(' ')
        ks.each do |ss|
          v = ss.split('|')
          k = v.shift
          DICT.add(k, v)
        end
      end
    end
  end
end
#===============================================================================
# ○ Scene_Base
#===============================================================================
class Scene_Base
  #--------------------------------------------------------------------------
  # ● 更新画面
  #--------------------------------------------------------------------------
  alias eagle_dict_update update
  def update
    eagle_dict_update
    DICT.show_hint
  end
end

#===============================================================================
# ○ UI
#===============================================================================
class << DICT
  #--------------------------------------------------------------------------
  # ● 开始
  #--------------------------------------------------------------------------
  def start
    init_data
    return if @data_category.empty?
    begin
      init_sprites
      update
    rescue
      p $!
    ensure
      dispose
    end
  end
  #--------------------------------------------------------------------------
  # ● 初始化全部数据
  #--------------------------------------------------------------------------
  def init_data
    data = $game_system.eagle_dict.keys
    @data_category = {} # 类别 => [词条]
    data.each do |k|
      cs = self.category(k)
      cs.each do |c|
        @data_category[c] ||= []
        @data_category[c].push(k)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 生成精灵
  #--------------------------------------------------------------------------
  def init_sprites
    # 生成背景精灵
    @sprite_bg = Sprite.new
    @sprite_bg.z = 250
    set_sprite_bg(@sprite_bg)

    # 生成背景文字
    @sprite_bg_info = Sprite.new
    @sprite_bg_info.z = @sprite_bg.z + 1
    set_sprite_title(@sprite_bg_info)

    # 生成底部按键提示
    @sprite_hint = Sprite.new
    @sprite_hint.z = @sprite_bg.z + 20
    set_sprite_hint(@sprite_hint)

    # 生成分割线绘制用精灵
    @sprite_layer = Sprite.new
    @sprite_layer.bitmap = Bitmap.new(Graphics.width, Graphics.height)
    @sprite_layer.z = @sprite_bg.z + 20

    # 生成类别组
    @sprites_category = []; i = 0
    i_w = Graphics.width / @data_category.keys.size
    @data_category.each do |k, v|
      s = Sprite_EagleDict_Category.new(k)
      s.x = i_w /2 + i_w * i
      s.y = 12 + s.height / 2
      s.z = @sprite_bg.z + 10
      @sprites_category.push(s)
      i += 1
    end
    @index_category = 0

    # 绘制水平分割线
    _y = @sprites_category[0].y + @sprites_category[0].height / 2
    @sprite_layer.bitmap.fill_rect(12, _y, @sprite_layer.width-24,1,
      Color.new(255,255,255,120))

    # 生成词条列表
    _w = DICT::LIST_WIDTH
    _h = Graphics.height - _y - 30 - 24
    @window_list = Window_EagleDict_List.new(0,0,150,_h+24)
    @window_list.x = 0
    @window_list.y = _y
    @window_list.z = @sprite_bg.z + 11

    # 绘制垂直分割线
    _x = @window_list.x + @window_list.width
    @sprite_layer.bitmap.fill_rect(_x, @window_list.y + 12 + 4, 1, _h,
      Color.new(255,255,255,120))

    # 生成词条文本
    _w = Graphics.width - _x - 12
    @viewport_info = Viewport.new(_x + 12, @window_list.y + 12, _w, _h)
    @viewport_info.z = @sprite_bg.z + 12
    @sprite_info = Sprite.new(@viewport_info)
    @sprite_info.bitmap = Bitmap.new(_w, _h)

    # 词条翻页提示
    @sprite_info_hint = Sprite.new
    @sprite_info_hint.z = @sprite_bg.z + 20
    set_sprite_info_hint(@sprite_info_hint)

    @data_last_draw = nil  # 上一次绘制的词条
    @count_last_draw = 0   # 绘制倒计时计数，防止切换过快时立即绘制导致的卡顿
    @sprite_info_view_h = @viewport_info.rect.height  # 可显示文本的高度
    @type_info_page = :scroll # 文本翻页方式
                          # :scroll为自动滚动，:page 为翻页
    @count_last_view = 0 # 自动滚动用计数

    @refresh = true
    update_key_result
  end
  #--------------------------------------------------------------------------
  # ● 设置背景精灵
  #--------------------------------------------------------------------------
  def set_sprite_bg(sprite)
    sprite.bitmap = Bitmap.new(Graphics.width, Graphics.height)
    sprite.bitmap.fill_rect(0, 0, sprite.width, sprite.height,
      Color.new(0,0,0,200))
  end
  #--------------------------------------------------------------------------
  # ● 设置标题精灵
  #--------------------------------------------------------------------------
  def set_sprite_title(sprite)
    sprite.zoom_x = sprite.zoom_y = 1.5
    sprite.bitmap = Bitmap.new(Graphics.height, Graphics.height)
    sprite.bitmap.font.size = 64
    sprite.bitmap.font.color = Color.new(255,255,255,10)
    sprite.bitmap.draw_text(0,0,sprite.width,64, "词条收集", 0)
    sprite.x = 4
    sprite.y = 4
  end
  #--------------------------------------------------------------------------
  # ● 设置按键提示精灵
  #--------------------------------------------------------------------------
  def set_sprite_hint(sprite)
    sprite.bitmap = Bitmap.new(Graphics.width, 24)
    sprite.bitmap.font.size = DICT::HINT_FONT_SIZE

    sprite.bitmap.draw_text(0, 2, sprite.width, sprite.height,
      "上/下方向键 - 切换词条 | 左/右方向键 - 切换类别 | 取消键 - 退出", 1)
    sprite.bitmap.fill_rect(0, 0, sprite.width, 1,
      Color.new(255,255,255,120))

    sprite.oy = sprite.height
    sprite.y = Graphics.height
  end
  #--------------------------------------------------------------------------
  # ● 设置翻页提示精灵
  #--------------------------------------------------------------------------
  def set_sprite_info_hint(sprite)
    sprite.bitmap = Bitmap.new(@viewport_info.rect.width, 18)
    sprite.bitmap.font.size = DICT::HINT_FONT_SIZE
    sprite.oy = 0
    sprite.x = @viewport_info.rect.x
    sprite.y = @viewport_info.rect.y + @viewport_info.rect.height
  end
  #--------------------------------------------------------------------------
  # ● 重绘翻页提示精灵
  #--------------------------------------------------------------------------
  def redraw_sprite_info_hint
    s = @sprite_info_hint
    s.bitmap.clear
    t = nil
    if @type_info_page == :scroll
      t = "SHIFT键 - 手动翻页"
    elsif @type_info_page == :page
      t = "Q键 - 上一页 | SHIFT键 - 自动滚动 | W键 - 下一页"
    end
    s.bitmap.draw_text(0, 0, s.width, s.height, t, 1) if t
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    @sprites_category.each { |s| s.bitmap.dispose; s.dispose }
    instance_variables.each do |varname|
      ivar = instance_variable_get(varname)
      if ivar.is_a?(Sprite)
        ivar.bitmap.dispose if ivar.bitmap
        ivar.dispose
      end
    end
    @viewport_info.dispose
    @window_list.dispose
  end
  #--------------------------------------------------------------------------
  # ● 更新直至退出
  #--------------------------------------------------------------------------
  def update
    loop do
      update_basic
      update_key
      update_key_result
      update_info
      break if update_exit?
    end
  end
  #--------------------------------------------------------------------------
  # ● 基础更新
  #--------------------------------------------------------------------------
  def update_basic
    Graphics.update
    Input.update
  end
  #--------------------------------------------------------------------------
  # ● 更新按键
  #--------------------------------------------------------------------------
  def update_key
    if Input.trigger?(:LEFT)
      @refresh = true
      @index_category -= 1
      @index_category = @sprites_category.size - 1 if @index_category < 0
    elsif Input.trigger?(:RIGHT)
      @refresh = true
      @index_category += 1
      @index_category = 0 if @index_category >= @sprites_category.size
    end
    @window_list.update
  end
  #--------------------------------------------------------------------------
  # ● 更新按键结果
  #--------------------------------------------------------------------------
  def update_key_result
    if @refresh
      @sprites_category.each_with_index do |s, i|
        s.opacity = i == @index_category ? 255 : 130
      end
      k = @sprites_category[@index_category].key
      @window_list.data = @data_category[k]
      @window_list.category = k
      @window_list.activate.select_last
      @refresh = false
    end
    cur = @window_list.item
    if @data_last_draw != cur
      @data_last_draw = cur
      draw_info(DICT::TEXT_WAIT)
      @count_last_draw = DICT::TIME_WAIT
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新信息文本
  #--------------------------------------------------------------------------
  def update_info
    @count_last_draw -= 1
    if @count_last_draw == 0
      cur = @window_list.item
      $game_system.eagle_dict_new.delete(cur)
      t = DICT.text(cur)
      draw_info(t)
      redraw_sprite_info_hint if @sprite_info_view_h < @sprite_info.height
    end
    if @count_last_draw < 0 && @sprite_info_view_h < @sprite_info.height
      update_info_page
    end
  end
  #--------------------------------------------------------------------------
  # ● 绘制信息文本
  #--------------------------------------------------------------------------
  def draw_info(t)
    @sprite_info.bitmap.clear
    ps = { :font_size => DICT::INFO_FONT_SIZE,
      :x0 => 0, :y0 => 0, :lhd => 2, :w => @sprite_info.width }
    d = Process_DrawTextEX.new(t, ps, @sprite_info.bitmap)
    d.run(false)
    if d.height > @sprite_info.height
      b = Bitmap.new(@sprite_info.width, d.height + 10)
      d.bind_bitmap(b, true)
      @sprite_info.bitmap = b
    end
    d.run(true)
    @viewport_info.oy = 0
    @count_last_view = 0
  end
  #--------------------------------------------------------------------------
  # ● 更新信息文本的翻页
  #--------------------------------------------------------------------------
  def update_info_page
    if Input.trigger?(:A)
      if @type_info_page == :scroll
        @type_info_page = :page
        @viewport_info.oy = 0
        @count_last_view = 0
      else
        @type_info_page = :scroll
        @count_last_view = 120
      end
      redraw_sprite_info_hint
    end
    if @type_info_page == :page
      if Input.trigger?(:L)
        return if @viewport_info.oy - @sprite_info_view_h < 0
        @viewport_info.oy -= @sprite_info_view_h
      elsif Input.trigger?(:R)
        return if @viewport_info.oy + @sprite_info_view_h > @sprite_info.height
        @viewport_info.oy += @sprite_info_view_h
      end
      return
    end
    if @type_info_page == :scroll # 更新自动滚动
      @count_last_view += 1
      # 当文字底移动到顶部位置时，重置回开头
      if @viewport_info.oy + @sprite_info_view_h >
         @sprite_info.height + @sprite_info_view_h - 24
        @viewport_info.oy = 0
        @count_last_view = 0
      else
        # 等待该帧数后，开始滚动
        return if @count_last_view < 180
        if @count_last_view % 4 == 0  # 每隔几帧滚动1像素
          @viewport_info.oy += 1
        end
      end
      return
    end
  end
  #--------------------------------------------------------------------------
  # ● 退出
  #--------------------------------------------------------------------------
  def update_exit?
    Input.trigger?(:B)
  end
end
#===============================================================================
# ○ Sprite_EagleDict_Category
#===============================================================================
class Sprite_EagleDict_Category < Sprite
  attr_reader :key
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize(key)
    super(nil)
    @key = key
    self.bitmap = Bitmap.new(90, 30)
    self.bitmap.font.size = DICT::CATE_FONT_SIZE
    self.bitmap.draw_text(0,0,self.width,self.height,key,1)
    self.ox = self.width / 2
    self.oy = self.height / 2
  end
end
#===============================================================================
# ○ Window_EagleDict_List
#===============================================================================
class Window_EagleDict_List < Window_Selectable
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize(x, y, width, height)
    super
    @category = ""
    @data = []
    self.back_opacity = 0
    self.opacity = 0
    self.contents_opacity = 255
  end
  #--------------------------------------------------------------------------
  # ● 设置分类
  #--------------------------------------------------------------------------
  def category=(category)
    return if @category == category
    @category = category
    refresh
    self.oy = 0
  end
  #--------------------------------------------------------------------------
  # ● 设置数据
  #--------------------------------------------------------------------------
  def data=(d)
    @data = d
  end
  #--------------------------------------------------------------------------
  # ● 设置光标位置
  #--------------------------------------------------------------------------
  def index=(index)
    @index = index
    update_cursor
    call_update_help
    refresh
  end
  #--------------------------------------------------------------------------
  # ● 返回上一个选择的位置
  #--------------------------------------------------------------------------
  def select_last
    select(0)
  end
  #--------------------------------------------------------------------------
  # ● 获取列数
  #--------------------------------------------------------------------------
  def col_max
    return 1
  end
  #--------------------------------------------------------------------------
  # ● 获取项目数
  #--------------------------------------------------------------------------
  def item_max
    @data ? @data.size : 1
  end
  #--------------------------------------------------------------------------
  # ● 获取物品
  #--------------------------------------------------------------------------
  def item
    @data && index >= 0 ? @data[index] : nil
  end
  #--------------------------------------------------------------------------
  # ● 获取选择项目的有效状态
  #--------------------------------------------------------------------------
  def current_item_enabled?
    true
  end
  #--------------------------------------------------------------------------
  # ● 刷新
  #--------------------------------------------------------------------------
  def refresh
    make_item_list
    create_contents
    draw_all_items
  end
  #--------------------------------------------------------------------------
  # ● 生成物品列表
  #--------------------------------------------------------------------------
  def make_item_list
  end
  #--------------------------------------------------------------------------
  # ● 绘制项目
  #--------------------------------------------------------------------------
  def draw_item(index)
    item = @data[index]
    if item
      rect = item_rect(index)
      rect.width -= 4
      f = index == @index ? true : false
      draw_item_name(item, rect.x, rect.y, f, rect.width)
      draw_symbol_new(rect.x, rect.y) if new_dict?(item)
    end
  end
  #--------------------------------------------------------------------------
  # ● 绘制物品名称
  #     enabled : 有效的标志。false 的时候使用半透明效果绘制
  #--------------------------------------------------------------------------
  def draw_item_name(item, x, y, enabled = true, width = 172)
    return unless item
    change_color(normal_color, enabled)
    draw_text(x, y, width, line_height, item, 1)
  end
  #--------------------------------------------------------------------------
  # ● 新词条？
  #--------------------------------------------------------------------------
  def new_dict?(item)
    $game_system.eagle_dict_new.include?(item)
  end
  #--------------------------------------------------------------------------
  # ● 绘制“新”标志
  #--------------------------------------------------------------------------
  def draw_symbol_new(x, y)
    change_color(system_color)
    s = contents.font.size
    contents.font.size = 12
    draw_text(x + 4, y, 60, line_height, "新", 0)
    contents.font.size = s
  end
end
