#encoding:utf-8
$imported ||= {}
$imported["EAGLE-MessageEX"] = "2.0.5"
=begin
===============================================================================

    ┌--------------------------------------------------------------------┐
    ┆            ,""---.                                                 ┆
    ┆          ㄏ       `.                                               ┆
    ┆       _ノ ㄏō       \                                              ┆
    ┆      / ´             y                                             ┆
    ┆      \J==ノ   by.老鹰 (https://github.com/OneEyedEagle/EAGLE-RGSS3)┆
    └--------------------------------------------------------------------┘

     ■ 鹰式对话框扩展 Ver 2.0 【核心】

     ======================================================================
        -                                                              -
                                                                    
     ▼ 特别感谢 ·=========================================================
     
       葱兔（http://onira.lofter.com/）

     ======================================================================
        -                                                              -
     
     更新历史
     ----------------------------------------------------------------------
     - 2026.1.3.0   V2.0.5 修复因Addon预设脸图和姓名动画而导致脸图宽度未重置的bug
     ----------------------------------------------------------------------
     - 2025.11.13.0 V2.0.4 优化缺少前置的报错
     ----------------------------------------------------------------------
     - 2025.11.9.18 V2.0.3 修复脸图移出时姓名框瞬移的bug
     ----------------------------------------------------------------------
     - 2025.11.6.0  V2.0.2 修复姓名框背景图片在停用缓动移动时无法正常消除的bug
     ----------------------------------------------------------------------
     - 2025.9.28.21 V2.0.1 \cin和\cout现在可以设置启用ctog了
     ----------------------------------------------------------------------
     - 2025.9.8.20  V2.0.0 \env中修复默认环境无法重置的bug
     ----------------------------------------------------------------------
     - 2025.9.1.21  V2.0.0 修复文字居中时，错误把等待按键精灵宽度计入的bug
     ----------------------------------------------------------------------
     - 2025.8.31.11 V2.0.0 修复\{\}转义符导致对话框文字绘制宽度不正常的bug
     ----------------------------------------------------------------------
     - 2025.8.27.22 V2.0.0 新增 auto窗口颜色自定义
     ----------------------------------------------------------------------
     - 2025.8.20.22 V2.0.0 新增 角色专属设置 字符串
     ----------------------------------------------------------------------
     - 2025.8.19.22 V2.0.0 修复对话框背景图片缩放异常的bug；兼容旧版本win的cdx/cdy
     ----------------------------------------------------------------------
     - 2025.8.18.23 V2.0.0 修复cin执行后，cswing无法修改显示原点的bug
     ----------------------------------------------------------------------
     
===============================================================================
=end

#==============================================================================
#                                 ■ 核心脚本 ■ 
#                          - 请不要轻易修改以下内容 -
#==============================================================================

if !defined?(MESSAGE_EX)
  msgbox("缺少鹰式对话框扩展【设定列表】！"); exit(0)
end

module MESSAGE_EX
#==============================================================================
# ○ 定义能响应的文字特效
#==============================================================================
module CHARA_EFFECTS
  def eagle_chara_effect_cin(param = ''); end
  def eagle_chara_effect_cout(param = ''); end
  if defined?(Unravel_Bitmap)
    def eagle_chara_effect_uout(param = ''); end
    def eagle_chara_effect_cu(param = ''); end
  end
  def eagle_chara_effect_csin(param = ''); end
  def eagle_chara_effect_cwave(param = ''); end
  def eagle_chara_effect_cswing(param = ''); end
  def eagle_chara_effect_czoom(param = ''); end
  def eagle_chara_effect_cshake(param = ''); end
  def eagle_chara_effect_cshake2(param = ''); end
  def eagle_chara_effect_cflash(param = ''); end
  def eagle_chara_effect_cmirror(param = ''); end
  def eagle_chara_effect_ctog(param = ''); end
  def eagle_chara_effect_cneon(param = ''); end
  def eagle_chara_effect_cmc(param = ''); end
  def eagle_chara_effect_cjump(param = ''); end
  def eagle_chara_effect_cfk(param = ''); end
  def eagle_chara_effect_cfade(param = ''); end
end
#==============================================================================
# ○ 常量读取用
#==============================================================================
  EX_PARAMS_INIT = {}  # 扩展转义符的默认常量
  #--------------------------------------------------------------------------
  # ● 获取指定转义符的默认值
  #--------------------------------------------------------------------------
  def self.get_default_params(param_sym)
    MESSAGE_EX.const_get("#{param_sym.to_s.upcase}_PARAMS_INIT".to_sym) rescue {}
  end
  #--------------------------------------------------------------------------
  # ● 读取指定文字组
  #--------------------------------------------------------------------------
  def self.get_charas_array(sym, index, num)
    h = MESSAGE_EX.const_get("#{sym.to_s.upcase}_CHARAS".to_sym) rescue {}
    array = h[index]
    return [] if array.nil?
    return array if num == 0
    return array.sample(num)
  end
  #--------------------------------------------------------------------------
  # ● 获取\conv[string]的替换字符串
  #--------------------------------------------------------------------------
  def self.get_conv(s)
    CONVERT_ESCAPE[s] || ""
  end
  #--------------------------------------------------------------------------
  # ● 读取对应的 windowskin 位图
  #--------------------------------------------------------------------------
  def self.windowskin(index)
    begin
      return Cache.system(INDEX_TO_WINDOWSKIN[index])
    rescue
      return Cache.system(INDEX_TO_WINDOWSKIN[0])
    end
  end
  #--------------------------------------------------------------------------
  # ● 读取对应的 bg 位图
  #--------------------------------------------------------------------------
  def self.windowbg(index, w = nil, h = nil)
    Cache.system(INDEX_TO_WINDOW_BG[index]) rescue nil
  end
  def self.namebg(index, w = nil, h = nil)
    Cache.system(INDEX_TO_NAME_BG[index]) rescue nil
  end
  #--------------------------------------------------------------------------
  # ● 播放对应的打字音
  #--------------------------------------------------------------------------
  def self.play_chara_se(index, c=nil)
    params = INDEX_TO_SE[index] || INDEX_TO_SE[0]
    return if params[0] == ""
    # 若启用了打字音，则再次应用下不同字符不同打字音
    index_new = index
    CAHRA_SE_ADJUST.each do |array, i|
      break index_new = i if array.include?(c)
    end
    params = INDEX_TO_SE[index_new]
    return if params[0] == ""
    volume = params[1] || INDEX_TO_SE[0][1]
    pitch = params[2] || INDEX_TO_SE[0][2]
    Audio.se_play("Audio/SE/" + params[0], volume, pitch)
  end
  #--------------------------------------------------------------------------
  # ● 读取对应的 tag 位图
  #--------------------------------------------------------------------------
  def self.windowtag(index)
    begin
      return Cache.system(INDEX_TO_WINDOWTAG[index])
    rescue
      return Cache.empty_bitmap
    end
  end
  #--------------------------------------------------------------------------
  # ● 重设tag
  #  i => 具体在tag位图上的帧序号，九宫格顺序排列
  #  o => tag位图的显示原点，理论上为pop对话框的do
  #  _do => tag位图的显示位置原点，理论上为pop对话框的o
  #--------------------------------------------------------------------------
  def self.set_windowtag(window, sprite, i, o, _do)
    w = sprite.src_rect.width; h = sprite.src_rect.height # 单个tag的宽度和高度
    sprite.src_rect.x = w * (2 - (9 - i) % 3)
    sprite.src_rect.y = h * ((9 - i) / 3)
    self.reset_xy_dorigin(sprite, window, _do)
    self.reset_xy_origin(sprite, o)
  end
  #--------------------------------------------------------------------------
  # ● 读取 pause 按键等待精灵的信息组
  #--------------------------------------------------------------------------
  def self.pause_params(index)
    INDEX_TO_PAUSE[index] || INDEX_TO_PAUSE[0]
  end
#==============================================================================
# ○ 共享方法
#==============================================================================
  #--------------------------------------------------------------------------
  # ● 判定当前所在场景的类型
  #--------------------------------------------------------------------------
  def self.in_scene?(s)
    return SceneManager.scene_is?(Scene_Map) if s == :map  # 地图场景中？
    return SceneManager.scene_is?(Scene_Battle) if s == :battle # 战斗场景中？
    return false
  end
  #--------------------------------------------------------------------------
  # ● 获取指定对象的信息文本
  #--------------------------------------------------------------------------
  def self.get_data_info(type, id, n ='0')
    case type
    when 's'; obj = $data_skills[id]
    when 'i'; obj = $data_items[id]
    when 'w'; obj = $data_weapons[id]
    when 'a'; obj = $data_armors[id]
    end
    if obj
      case n
      when 0, '0'; return "\ei[#{obj.icon_index}]#{obj.name}"
      when 1, '1'; return "\ei[#{obj.icon_index}]"
      when 2, '2'; return "#{obj.name}"
      end
    end
    return ""
  end
  #--------------------------------------------------------------------------
  # ● 解析字符串参数
  #--------------------------------------------------------------------------
  def self.parse_param(param_hash, param_text, default_type = "default")
    param_text = param_text.downcase rescue ""
    # 只有首位是省略名字的参数设置
    param_text.slice!(/ */)
    t = param_text.slice!(/^\-?\d+/)
    param_hash[default_type.to_sym] = t.to_i if t && t != ""
    while(param_text != "")
      param_text.slice!(/ */)
      t = param_text.slice!(/^[a-z]+/)
      param_text.slice!(/ */)
      if param_text[0] == '='
        param_text[0] = ''
        param_text.slice!(/ */)
      end
      if param_text[0] == "$"
        param_text[0] = ''
        next param_hash[t.to_sym] = nil
      end
      param_hash[t.to_sym] = (param_text.slice!(/^\-?\d+/)).to_i
    end
  end
  #--------------------------------------------------------------------------
  # ● 获取文本颜色
  #--------------------------------------------------------------------------
  def self.text_color(n, windowskin = Cache.system("Window"))
    return TEXT_COLORS[n] if TEXT_COLORS[n]
    n_ = n.to_i
    n_ = DEFAULT_COLOR_INDEX if n_ < 0
    windowskin.get_pixel(64 + (n_ % 8) * 8, 96 + (n_ / 8) * 8)
  end
  #--------------------------------------------------------------------------
  # ● 将指定值变更为布尔量
  #--------------------------------------------------------------------------
  def self.check_bool(v)
    return true if v == true
    return false if v.nil? || v == false || v == 0
    return true
  end
  #--------------------------------------------------------------------------
  # ● 应用font参数到font对象上
  #--------------------------------------------------------------------------
  def self.apply_font_params(font, ps)
    font.name = INDEX_TO_FONT[ps[:name]] if ps[:name]
    font.size = ps[:size] || Font.default_size
    font.color.alpha = ps[:ca]
    font.italic = ps[:i] ? MESSAGE_EX.check_bool(ps[:i]) : Font.default_italic
    font.bold = ps[:b] ? MESSAGE_EX.check_bool(ps[:b]) : Font.default_bold
    font.shadow = ps[:s] ? MESSAGE_EX.check_bool(ps[:s]) : Font.default_shadow
    font.outline = ps[:o] ? MESSAGE_EX.check_bool(ps[:o]) : Font.default_outline
    if ps[:or]
      font.out_color.set(ps[:or],ps[:og],ps[:ob],ps[:oa])
    else
      font.out_color = Font.default_out_color
    end
    ps[:l] = MESSAGE_EX.check_bool(ps[:l])
    ps[:lc] ||= 0
    ps[:lp] ||= 2
    ps[:d] = MESSAGE_EX.check_bool(ps[:d])
    ps[:dc] ||= 0
    ps[:u] = MESSAGE_EX.check_bool(ps[:u])
    ps[:uc] ||= 0
    ps[:k] = MESSAGE_EX.check_bool(ps[:k])
    ps[:kv] ||= 50
  end
  #--------------------------------------------------------------------------
  # ● 重置指定精灵的显示原点
  #--------------------------------------------------------------------------
  def self.reset_sprite_oxy(obj, o)
    case o # 固定不动点的位置类型 以九宫格小键盘察看 默认7左上角
    when 1; obj.ox = 0;             obj.oy = obj.height
    when 2; obj.ox = obj.width / 2; obj.oy = obj.height
    when 3; obj.ox = obj.width;     obj.oy = obj.height
    when 4; obj.ox = 0;             obj.oy = obj.height / 2
    when 5; obj.ox = obj.width / 2; obj.oy = obj.height / 2
    when 6; obj.ox = obj.width;     obj.oy = obj.height / 2
    when 7; obj.ox = 0;             obj.oy = 0
    when 8; obj.ox = obj.width / 2; obj.oy = 0
    when 9; obj.ox = obj.width;     obj.oy = 0
    end
  end
  #--------------------------------------------------------------------------
  # ● 重置指定对象的显示原点位置
  #--------------------------------------------------------------------------
  def self.reset_xy_origin(obj, o)
    case o # 固定不动点的位置类型 以九宫格小键盘察看
    when 1;                                obj.y = obj.y - obj.height
    when 2; obj.x = obj.x - obj.width / 2; obj.y = obj.y - obj.height
    when 3; obj.x = obj.x - obj.width;     obj.y = obj.y - obj.height
    when 4;                                obj.y = obj.y - obj.height / 2
    when 5; obj.x = obj.x - obj.width / 2; obj.y = obj.y - obj.height / 2
    when 6; obj.x = obj.x - obj.width;     obj.y = obj.y - obj.height / 2
    when 7; return  # 默认7左上角
    when 8; obj.x = obj.x - obj.width / 2
    when 9; obj.x = obj.x - obj.width
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
  # ● 基于指定位图，计算文本块所占宽高
  # （只进行 \\ 到 \e 的文本替换、忽略除\i以外的全部转义符、未考虑字号变化）
  #  k → 字符间距  ld → 行间距
  #--------------------------------------------------------------------------
  def self.calculate_text_wh(bitmap, text, k = 0, ld = 0)
    text_clone = text.dup; array_width = []; array_height = []
    # 转义符替换
    text_clone.gsub!(/\\/)      { "\e" }
    text_clone.gsub!(/\e\e/)    { "\\" }
    text_clone.gsub!(/\e[\.\|\^\!\$<>\{|\}]/i) { "" }
    # 每一行计算宽度高度
    text_clone.each_line do |line|
      icon_count = 0
      # 获取 \i[] 数目
      line.gsub!(/\ei\[\d+\]/i){ icon_count += 1; "" }
      # 清除掉全部的\w[wd]格式转义符
      line.gsub!(/\e\w+\[(\d|\w)+\]/i) { "" }
      r = bitmap.text_size(line)
      w = r.width + icon_count * 24 + (line.length - 1 + icon_count) * k
      array_width.push(w)
      h = icon_count > 0 ? [r.height, 24].max : r.height
      array_height.push(h)
    end
    return [array_width.max, array_height.inject{|sum, v| sum = sum + v + ld}]
  end
  #--------------------------------------------------------------------------
  # ● 基于指定文本设置game_message的参数
  #--------------------------------------------------------------------------
  def self.set_game_message(game_message, text)
    @window_clone_env ||= Window_EagleMessage_CloneEnv.new(game_message)
    @window_clone_env.set_game_message(game_message, text)
  end
  #--------------------------------------------------------------------------
  # ● 计算最小包围盒
  #--------------------------------------------------------------------------
  def self.get_smallest_box(rects)
    return Rect.new if rects.empty?
    r = rects.pop
    rects.each do |r2|
      r.width = [r.x + r.width, r2.x + r2.width].max - [r.x, r2.x].min
      r.height = [r.y + r.height, r2.y + r2.height].max - [r.y, r2.y].min
      r.x = r2.x if r2.x < r.x  # 新矩形在现有矩形的左外侧，更新x位置
      r.y = r2.y if r2.y < r.y  # 新矩形在现有矩形的上外侧，更新y位置
    end
    return r
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
end # end of MESSAGE_EX

#=============================================================================
# ○ DataManager
#=============================================================================
class << DataManager
  #--------------------------------------------------------------------------
  # ● 设置新游戏
  #--------------------------------------------------------------------------
  alias eagle_message_ex_setup_new_game setup_new_game
  def setup_new_game
    eagle_message_ex_setup_new_game
    $game_message.add_escape(MESSAGE_EX::ESCAPE_STRING_INIT)
    $game_system.reset_game_message_envs
  end
  #--------------------------------------------------------------------------
  # ● 设置战斗测试
  #--------------------------------------------------------------------------
  alias eagle_message_ex_setup_battle_test setup_battle_test
  def setup_battle_test
    eagle_message_ex_setup_battle_test
    $game_message.add_escape(MESSAGE_EX::ESCAPE_STRING_INIT)
    $game_system.reset_game_message_envs
  end
end

#=============================================================================
# ○ Game_Message
#=============================================================================
class Game_Message
  attr_reader   :params_need_apply # 存储预定要调用的转义符符号
  attr_accessor :escape_strings    # 存储预定要添加的字符串
  attr_accessor :chara_params      # 存储激活的文字特效 code_symbol => param_string
  attr_accessor :font_params, :win_params,  :pop_params
  attr_accessor :face_params, :name_params, :pause_params
  attr_accessor :func_params, :ex_params, :env, :auto
  attr_accessor :event_id, :child_window_w_des, :child_window_h_des
  attr_accessor :no_name_overlap_face, :no_input_pause, :active 
  attr_accessor :eagle_text    # 存储实际绘制的文本（去除预处理的转义符）
  attr_accessor :eagle_message # 兼容模式
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  alias eagle_message_ex_init initialize
  def initialize
    eagle_message_ex_init
    check_flags
    set_default_params
    reset_child_window_wh_add
  end
  #--------------------------------------------------------------------------
  # ● 检查flags
  #--------------------------------------------------------------------------
  def check_flags
    # 当前环境（默认 '0'）
    @env = '0' if @env.nil?
    # 姓名框不遮挡脸图？
    if @no_name_overlap_face == nil
      @no_name_overlap_face = MESSAGE_EX::DEFAULT_NO_OVERLAP_FACE
    end
    # 不进入按键等待？（扩展用）
    @no_input_pause = false if @no_input_pause.nil?
    # 如果处于兼容模式，且变量值为nil，确保变量值为false
    if EAGLE_MSG_EX_COMPAT_MODE == true
      @eagle_message = false if @eagle_message.nil?
    end
    # 设置是否自动播放对话
    @auto = nil
  end
  #--------------------------------------------------------------------------
  # ● 获取全部可保存params的符号的数组
  #--------------------------------------------------------------------------
  def eagle_params
    [:chara, :font, :win, :pop, :face, :name, :pause, :func, :ex]
  end
  #--------------------------------------------------------------------------
  # ● 获取params的初始值
  #--------------------------------------------------------------------------
  def set_default_params
    eagle_params.each do |sym|
      send("#{sym}_params=".to_sym, MESSAGE_EX.get_default_params(sym).dup)
    end
    @params_need_apply = eagle_params.dup # 添加修改预定，用于应用初始值
    @escape_strings = [] # 存储等待执行的转义符字符串
  end
  #--------------------------------------------------------------------------
  # ● 检查params是否都存在（读档后调用，确保新增变量写入旧存档中）
  #--------------------------------------------------------------------------
  def check_params
    check_flags
    eagle_params.each do |sym|
      params = self.send("#{sym}_params".to_sym)
      def_params = MESSAGE_EX.get_default_params(sym).dup
      if params == nil
        self.send("#{sym}_params=".to_sym, def_params)
        add_apply(sym)
      else
        params = def_params.merge(params)
        self.send("#{sym}_params=".to_sym, params)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 清除（每次对话框关闭前被调用）
  #--------------------------------------------------------------------------
  alias eagle_message_ex_clear clear
  def clear
    eagle_message_ex_clear
    @eagle_text = ""
    @event_id = 0 # 存储当前执行的Game_Interpreter的事件ID
    if EAGLE_MSG_EX_COMPAT_MODE == false # 如果不处于兼容模式，确保变量恒为true
      @eagle_message = true
    end
  end
  #--------------------------------------------------------------------------
  # ● 重置额外增加的宽高（new_page时调用）
  #--------------------------------------------------------------------------
  def reset_child_window_wh_add
    @child_window_w_des = 0 # 因子窗口嵌入而额外增加的宽高
    @child_window_h_des = 0
  end
  #--------------------------------------------------------------------------
  # ● 下一次对话时要解析的转义符
  # 【由于解析问题，字符串中请将 "\" 替换成 "\e" 】
  #--------------------------------------------------------------------------
  def add_escape(string)
    @escape_strings.push(string)
  end
  #--------------------------------------------------------------------------
  # ● 判定是否需要进入等待按键状态
  #--------------------------------------------------------------------------
  def input_pause?
    return false if @no_input_pause
    !(choice? || num_input? || item_choice?)
  end
  #--------------------------------------------------------------------------
  # ● 使用了各个对话框组件？
  #--------------------------------------------------------------------------
  def pop?;     @pop_params[:type] != nil; end
  def pop_tag?; @pop_params[:tag] > 0;     end
  def face?;    @face_params[:name] != ""; end
  def name?;    @name_params[:name] != ""; end
  #--------------------------------------------------------------------------
  # ● 添加修改预定
  #--------------------------------------------------------------------------
  def add_apply(param_sym)
    return if @params_need_apply.include?(param_sym)
    @params_need_apply.push(param_sym)
  end
  #--------------------------------------------------------------------------
  # ● 清空预定修改
  #--------------------------------------------------------------------------
  def clear_applys
    @params_need_apply.clear
  end
  #--------------------------------------------------------------------------
  # ● 重置指定参数
  #--------------------------------------------------------------------------
  def reset_params(param_sym, code_string = nil)
    return eagle_params.each{|sym| reset_params(sym)} if param_sym.nil?
    return reset_params_c(code_string) if param_sym == :chara
    return reset_params_ex(code_string) if param_sym == :ex
    default_params = MESSAGE_EX.get_default_params(param_sym)
    if code_string.nil? # 直接清除全部参数
      new_params = default_params.dup
    else
      new_params = method( param_sym.to_s + "_params" ).call.dup # 获取旧的hash
      code_string.split("|").each { |c|
        new_params[c.to_sym] = default_params[c.to_sym]
      }
    end
    self.send((param_sym.to_s+"_params=").to_sym, new_params)
    add_apply(param_sym) # 添加修改预定，用于应用结果
  end
  #--------------------------------------------------------------------------
  # ● 重置指定文字特效
  #--------------------------------------------------------------------------
  def reset_params_c(code_string = nil)
    default_params = MESSAGE_EX.get_default_params(:chara)
    return @chara_params = default_params if code_string.nil?
    code_string.split("|").each { |c|
      if default_params[c.to_sym]
        @chara_params[c.to_sym] = default_params[c.to_sym]
      else
        @chara_params.delete(c.to_sym)
      end
    }
  end
  #--------------------------------------------------------------------------
  # ● 重置扩展转义符
  #--------------------------------------------------------------------------
  def reset_params_ex(code_string = nil)
    default_params = MESSAGE_EX.get_default_params(:ex)
    return @ex_params = default_params if code_string.nil?
    code_string.split("|").each { |c|
      if default_params[c.to_sym]
        @ex_params[c.to_sym] = default_params[c.to_sym]
      else
        @ex_params.delete(c.to_sym)
      end
    }
  end
  #--------------------------------------------------------------------------
  # ● 参数拷贝
  #--------------------------------------------------------------------------
  def clone2
    t = Game_Message.new
    clone_rgss(t)
    t.visible = true
    eagle_params.each do |sym|
      m = "#{sym}_params"
      t.send("#{m}=".to_sym, method(m.to_sym).call.clone)
    end
    clone_ex(t)
    t
  end
  #--------------------------------------------------------------------------
  # ● 参数拷贝（RGSS中的变量）
  #--------------------------------------------------------------------------
  def clone_rgss(t)
    t.background = @background
    t.position = @position
  end
  #--------------------------------------------------------------------------
  # ● 参数拷贝（扩展）(将当前的参数赋值给 t)
  #--------------------------------------------------------------------------
  def clone_ex(t)
    t.no_name_overlap_face = @no_name_overlap_face
  end
  #--------------------------------------------------------------------------
  # ● 参数保留（扩展）(保留当前的参数给 t)
  #--------------------------------------------------------------------------
  def reserve_ex(t)
    t.auto = @auto
  end
  #--------------------------------------------------------------------------
  # ● 保存当前环境
  #--------------------------------------------------------------------------
  def save_env(sym = '0')
    return if sym == '0' # 如果是默认环境，则不保存
    $game_system.message_envs[sym] = self.clone2
  end
  #--------------------------------------------------------------------------
  # ● 读取指定环境
  #--------------------------------------------------------------------------
  def load_env(sym = '0')
    $game_system.reset_game_message_env(sym)
    t = $game_system.message_envs[sym]
    return false if t.nil?
    # 应用params
    eagle_params.each do |s|
      m = "#{s}_params"
      self.send("#{m}=".to_sym, t.method(m.to_sym).call.clone)
    end
    @params_need_apply = eagle_params  # 新增转义符的应用预定
    t.clone_ex(self)  # 拷贝额外扩展的数据
    reserve_ex(t)     # 需要特别保留的参数，在环境间传递
    return true
  end
end
#=============================================================================
# ○ Game_System
#=============================================================================
class Game_System
  attr_reader   :message_envs  # 对话框环境
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  alias eagle_message_ex_initialize initialize
  def initialize
    eagle_message_ex_initialize
    @message_envs = {} # sym => game_message
  end
  #--------------------------------------------------------------------------
  # ● 读档后的处理
  #--------------------------------------------------------------------------
  alias eagle_message_ex_on_after_load on_after_load
  def on_after_load
    eagle_message_ex_on_after_load
    #reset_game_message_envs
    $game_message.check_params # 确保新增AddOn时，参数hash存在
    @message_envs.each { |sym, g| g.check_params }
  end
  #--------------------------------------------------------------------------
  # ● 重置全部预设环境
  #--------------------------------------------------------------------------
  def reset_game_message_envs
    MESSAGE_EX::DEFAULT_ENVS.each do |sym, text|
      g = Game_Message.new
      MESSAGE_EX.set_game_message(g, text)
      @message_envs[sym] = g
    end
  end
  #--------------------------------------------------------------------------
  # ● 重置指定预设环境
  #--------------------------------------------------------------------------
  def reset_game_message_env(sym)
    t = MESSAGE_EX::DEFAULT_ENVS[sym]
    return false if t == nil  # 如果不是脚本预设的环境，则不处理
    g = Game_Message.new
    MESSAGE_EX.set_game_message(g, t)
    @message_envs[sym] = g
    return true
  end
end
#=============================================================================
# ○ Game_Interpreter
#=============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 显示文字
  #--------------------------------------------------------------------------
  alias eagle_message_ex_command_101 command_101
  def command_101
    $game_message.event_id = @event_id
    eagle_message_ex_command_101
  end
end

#=============================================================================
# ○ Window_EagleMessage
#=============================================================================
class Window_EagleMessage < Window_Base
  include MESSAGE_EX::CHARA_EFFECTS
  attr_reader   :eagle_charas_w, :eagle_charas_h, :eagle_chara_viewport
  attr_accessor :eagle_face_w, :eagle_face_h
  #--------------------------------------------------------------------------
  # ● 获取主参数组（方便子窗口修改成自己的game_message）
  #--------------------------------------------------------------------------
  def game_message;     $game_message;      end
  def game_message=(g); $game_message = g;  end
  #--------------------------------------------------------------------------
  # ● 【通用方法】
  #--------------------------------------------------------------------------
  def parse_param(param_hash, param_text, default_type = "default")
    MESSAGE_EX.parse_param(param_hash, param_text, default_type)
  end
  def text_color(n); MESSAGE_EX.text_color(n, self.windowskin); end
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize
    super(0, 0, window_width, window_height)
    create_all_windows
    eagle_message_init_assets
    eagle_message_init_params
    eagle_message_reset
    self.openness = 0
  end
  #--------------------------------------------------------------------------
  # ● 生成所有子窗口
  #--------------------------------------------------------------------------
  def create_all_windows
    @gold_window = Window_EagleMsgGold.new(self)
    @choice_window = Window_EagleChoiceList.new(self) rescue Window_ChoiceList.new(self)
    @number_window = Window_EagleNumberInput.new(self) rescue Window_NumberInput.new(self)
    @item_window = Window_EagleKeyItem.new(self) rescue Window_KeyItem.new(self)
  end
  #--------------------------------------------------------------------------
  # ● 初始化组件
  # （在进行 clone 时，需要将该方法中的组件直接赋值给拷贝窗口）
  #--------------------------------------------------------------------------
  def eagle_message_init_assets
    @back_sprite = Sprite.new  # 显示背景图片的精灵
    @eagle_chara_viewport = Viewport.new # 文字精灵的显示区域
    @eagle_chara_sprites = []  # 存储全部的文字精灵
    @eagle_sprite_pop_tag = Sprite.new # pop状态下的tag精灵
    @eagle_sprite_face = nil   # 脸图精灵
    @eagle_window_name = Window_EagleMsgName.new(self) # 姓名框
    @eagle_sprite_pause = Sprite_EaglePauseTag.new(self) # 等待按键的精灵
  end
  #--------------------------------------------------------------------------
  # ● 初始化参数（只会在 initialize 时执行一次）
  # （推荐将一些不需要传递给拷贝窗口的数据置于此处）
  #--------------------------------------------------------------------------
  def eagle_message_init_params
    self.back_opacity = MESSAGE_EX::WINDOW_BACK_OPACITY  # 背景不透明度
    self.arrows_visible = false # 内容位图未完全显示时出现的箭头
    @fiber = nil                # 纤程
    @background = 0             # 背景类型
    @position = 2               # 显示位置
    @flag_draw = true           # true 代表进行实际的绘制
    @flag_open_close = false    # 当正在进行打开/关闭时，置为 true
    @flag_input_pause = false   # 当正在进行按键等待时，置为 true
    @flag_need_open = true      # true 代表需要执行open_and_wait
    @flag_need_change_wh = false # true 代表需要进行宽高的动态变化
    @flag_need_close = false    # true 代表当前对话框必需处理关闭
    @flag_hold = false          # true 代表当前对话框会被拷贝保留，并同步更新
    @flag_instant = false       # true 代表当前对话框不再处理文字显示时的等待
    @flag_next = false          # true 代表当前对话框不关闭，下一显示文字将继续使用
    @flag_temp = false          # true 代表当前对话框的任何修改将不被保存
    @flag_temp_env = nil        # 存储当前对话框开启前的环境
    @flag_save_env = nil        # 当不为 nil 时，当前对话框状态保存到对应环境中
    @flag_no_fix = false        # 关闭位置修正功能
    @count_chara_se = 0         # 播放打字音的间隔帧数
    @eagle_dup_windows ||= []   # 存储生成的全部拷贝对话框
    @eagle_evals = []           # 当前对话中的待执行脚本 [eval_str, eval_str...]
    @eagle_chara_sets = {}      # 存储文字的全部分组 {分组名 => [文字精灵]}
    @eagle_current_set = nil    # 当前分组的名称
    # 对话框动态移动偏移量（此处新增定义，防止子类覆盖了 eagle_message_reset）
    @eagle_move_x = @eagle_move_y = 0
    # 存储对话框在上一帧的位置（此处新增定义，防止子类覆盖了 eagle_message_reset）
    @eagle_last_x = @eagle_last_y = nil
    # 存储当前脸图的宽度高度
    @eagle_face_w = @eagle_face_h = 0
    # 对话框位置的强制增量（move转义符、对话框关闭时使用）
    @eagle_offset_x = @eagle_offset_y = 0
    eagle_check_func("")        # 预先执行一遍func，确保它们都是布尔量
  end
  #--------------------------------------------------------------------------
  # ● 拷贝自身
  #--------------------------------------------------------------------------
  def clone(window = Window_EagleMessage_Clone)
    t = window.new(game_message.clone2)
    t.game_message.win_params[:z] = 0
    t.move(self.x, self.y, self.width, self.height)
    t.z = self.z - 5
    t.windowskin = self.windowskin
    # 拷贝背景精灵
    t.back_bitmap = @back_bitmap
    t.back_sprite = @back_sprite
    @back_bitmap = nil
    # 拷贝视图
    t.eagle_chara_viewport = @eagle_chara_viewport
    # 拷贝文字组
    t.eagle_chara_sprites = @eagle_chara_sprites
    t.eagle_chara_sprites.each { |s| s.bind_window(t) }
    # 复制文本宽高
    t.eagle_set_chara_wh(@eagle_charas_w, @eagle_charas_h,
      @eagle_charas_w_final, @eagle_charas_h_final)
    # 拷贝pop对象
    t.eagle_pop_obj = @eagle_pop_obj
    # 拷贝pop的tag
    t.eagle_sprite_pop_tag = @eagle_sprite_pop_tag
    # 拷贝脸图
    if @eagle_sprite_face
      t.eagle_face_w = @eagle_face_w
      t.eagle_face_h = @eagle_face_h
      t.eagle_sprite_face = @eagle_sprite_face
      t.eagle_sprite_face.bind_window(t)
    end
    # 拷贝姓名框
    t.eagle_window_name = @eagle_window_name
    t.eagle_window_name.bind_window(t)
    # 拷贝pause精灵
    t.eagle_sprite_pause = @eagle_sprite_pause
    t.eagle_sprite_pause.bind_window(t)
    # 扩展
    t = clone_ex(t)
    # 集体更新z值
    t.eagle_reset_z
    # 自身初始化组件与重置
    eagle_message_init_assets
    # 更新自身的z值
    eagle_reset_z
    t
  end
  #--------------------------------------------------------------------------
  # ● 拷贝自身（扩展用处理）
  #--------------------------------------------------------------------------
  def clone_ex(t)
    t
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    dispose_all_windows
    dispose_back_bitmap
    @back_sprite.dispose
    @eagle_chara_sprites.each { |s| s.dispose }
    @eagle_window_name.dispose
    @eagle_sprite_face.dispose if @eagle_sprite_face
    @eagle_sprite_pop_tag.dispose
    @eagle_sprite_pause.dispose
    @eagle_dup_windows.each { |w| w.dispose if !w.disposed? }
    @eagle_chara_viewport.dispose
    super
  end
  #--------------------------------------------------------------------------
  # ● 释放所有窗口
  #--------------------------------------------------------------------------
  def dispose_all_windows
    @gold_window.dispose
    @choice_window.dispose
    @number_window.dispose
    @item_window.dispose
  end
  #--------------------------------------------------------------------------
  # ● 释放背景位图
  #--------------------------------------------------------------------------
  def dispose_back_bitmap
    @back_bitmap.dispose if @back_bitmap
    @back_bitmap = nil
  end

  #--------------------------------------------------------------------------
  # ● 重置对话框
  #--------------------------------------------------------------------------
  def eagle_message_reset
    eagle_message_reset_continue
    eagle_move_out_assets    # 移出全部组件
    @eagle_last_x = @eagle_last_y = nil   # 重置存储的对话框的上一个位置
    @eagle_move_x = @eagle_move_y = 0     # 重置对话框动态移动位置
    @eagle_offset_x = @eagle_offset_y = 0 # 重置对话框因转义符而移动的位置
    @eagle_win_des_w = @eagle_win_des_h = 0  # 重置对话框最终显示宽高
    @eagle_charas_w = @eagle_charas_h = 0    # 重置文字区域的宽高
    @eagle_charas_w_final = @eagle_charas_h_final = 0
    @eagle_face_w = @eagle_face_h = 0  # 重置脸图的宽高（用于文字偏移）
    @eagle_pop_obj = nil     # 重置pop对象，防止报错
    eagle_reset_z            # 重置z值
    clear_flags              # 清除显示标志
  end
  #--------------------------------------------------------------------------
  # ● 重置对话框（对话框不关闭，清空全部设置，并继续显示）
  #--------------------------------------------------------------------------
  def eagle_message_reset_continue
    show if !self.visible    # 确保对话框显示
    if @flag_next  # 如果继续显示在当前对话框里，则不移出文字
    else
      eagle_message_sprites_move_out  # 移出全部文字精灵
      eagle_reset_charas_oxy  # 重置文字显示区域
      @eagle_chara_sets.clear  # 清空文字分组
    end
    eagle_process_env        # 处理环境的存储或读取
    eagle_process_temp       # 处理临时环境
    pop_params[:with_tag] = false
    @eagle_sprite_pop_tag.visible = false # 隐藏pop的tag
    @eagle_sprite_pause.visible = false   # 隐藏等待按键pause精灵
    @eagle_sprite_pause.bind_last_chara(nil)  # 重置pause精灵的文末位置
    @eagle_sprite_pause_width_add = 0     # 因pause精灵而扩展的窗口宽度
    @eagle_next_chara_x = 0     # 重置下一个文字的绘制坐标x（左对齐、不考虑换行）
    @eagle_force_close = false  # 重置强制关闭
  end
  #--------------------------------------------------------------------------
  # ● 移出全部组件
  #--------------------------------------------------------------------------
  def eagle_move_out_assets
    pop_params[:with_tag] = false
    @eagle_sprite_pop_tag.visible = false  # 隐藏pop的tag
    @eagle_sprite_pause.visible   = false  # 隐藏pause精灵
    face_params[:name] = ""
    eagle_move_out_face                    # 移出显示的脸图
    # 关闭姓名框（因为对话框关闭后，姓名框不再更新，减小openness确保关闭）
    @eagle_window_name.close
    @eagle_window_name.openness -= 15
    if @eagle_force_close # 如果是快进对话状态，则直接关闭
      @eagle_window_name.openness = 0 
      @eagle_window_name.update
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新全部组件的不透明度
  #--------------------------------------------------------------------------
  def update_assets_opacity(opa)
    @eagle_chara_sprites.each { |c| c.opacity = opa }
    @eagle_sprite_pop_tag.opacity = opa if pop_params[:with_tag]
    @eagle_sprite_face.opa        = opa if @eagle_sprite_face
    if game_message.name?
      @eagle_window_name.opacity  = opa if @eagle_window_name.back_opacity > 0
      @eagle_window_name.contents_opacity = opa
    end
    update_back_sprite_opa(opa)
  end
  #--------------------------------------------------------------------------
  # ● 重设z值
  #--------------------------------------------------------------------------
  def eagle_reset_z
    self.z = win_params[:z] if win_params[:z] > 0
    self.z = pop_params[:z] if game_message.pop? && pop_params[:z]
    @back_sprite.z          = self.z
    @eagle_chara_viewport.z = self.z + 1
    @eagle_sprite_pop_tag.z = self.z + 1
    @eagle_sprite_pause.z   = self.z + 2
    @eagle_window_name.z    = self.z + 3
  end
  #--------------------------------------------------------------------------
  # ● 显示窗口
  #--------------------------------------------------------------------------
  def show(no_anim=false)
    @eagle_chara_sprites.each { |s| no_anim ? s.visible=true : s.move_in }
    self.visible                  = true
    @back_sprite.visible          = true if self.opacity == 0
    @eagle_sprite_pop_tag.visible = true if pop_params[:with_tag]
    @eagle_sprite_face.visible    = true if @eagle_sprite_face
    @eagle_sprite_pause.visible   = true if @flag_input_pause
    @eagle_window_name.show.update       if game_message.name?
    show_ex
    self
  end
  #--------------------------------------------------------------------------
  # ● 显示（扩展用）
  #--------------------------------------------------------------------------
  def show_ex
    @eagle_dup_windows.each { |w| w.show }
  end
  #--------------------------------------------------------------------------
  # ● 隐藏窗口
  #--------------------------------------------------------------------------
  def hide(no_anim=false)
    @eagle_chara_sprites.each { |s| no_anim ? s.visible=false : s.move_out_temp }
    self.visible                  = false
    @back_sprite.visible          = false
    @eagle_sprite_pop_tag.visible = false if pop_params[:with_tag]
    @eagle_sprite_face.visible    = false if @eagle_sprite_face
    @eagle_sprite_pause.visible   = false if @flag_input_pause
    @eagle_window_name.hide               if game_message.name?
    hide_ex
    self
  end
  #--------------------------------------------------------------------------
  # ● 隐藏（扩展用）
  #--------------------------------------------------------------------------
  def hide_ex
    @eagle_dup_windows.each { |w| w.hide }
  end

  #--------------------------------------------------------------------------
  # ● 更新画面
  #--------------------------------------------------------------------------
  def update
    super
    eagle_update_before_fiber
    update_fiber
    eagle_update_after_fiber
  end
  #--------------------------------------------------------------------------
  # ● 更新fiber
  #--------------------------------------------------------------------------
  def update_fiber
    if @fiber
      @fiber.resume
    elsif game_message.busy? && !game_message.scroll_mode
      @fiber = Fiber.new { fiber_main }
      @fiber.resume
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新（在 @fiber 更新之前）
  #--------------------------------------------------------------------------
  def eagle_update_before_fiber
    update_all_windows
    if self.openness > 0
      eagle_update_assets_after_open
      eagle_update_func_after_open
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新所有窗口
  #--------------------------------------------------------------------------
  def update_all_windows
    @gold_window.update
    @choice_window.update
    @number_window.update
    @item_window.update
  end
  #--------------------------------------------------------------------------
  # ● 对话框打开后进行组件更新
  #--------------------------------------------------------------------------
  def eagle_update_assets_after_open
    @count_chara_se -= 1 if @count_chara_se > 0 # 打字音计数
    eagle_pop_update if game_message.pop?
    @eagle_window_name.update
    @eagle_sprite_face.update  if @eagle_sprite_face
    @eagle_sprite_pause.update if @eagle_sprite_pause.visible
  end
  #--------------------------------------------------------------------------
  # ● 对话框打开后进行部分功能的实时更新
  #--------------------------------------------------------------------------
  def eagle_update_func_after_open
    (self.visible ? hide : show) if MESSAGE_EX.toggle_visible?
    force_close if MESSAGE_EX.force_close?
  end
  #--------------------------------------------------------------------------
  # ● 更新（在 @fiber 更新之后）
  #--------------------------------------------------------------------------
  def eagle_update_after_fiber
    update_back_sprite  # 此处更新才能获得对话框的真实显示坐标
    @eagle_chara_sprites.each { |s| s.update }
    eagle_update_dup_windows
  end
  #--------------------------------------------------------------------------
  # ● 更新拷贝窗口
  #--------------------------------------------------------------------------
  def eagle_update_dup_windows
    if @eagle_dup_windows.size > 0
      @eagle_dup_windows.each { |w| w.update }
      if @eagle_dup_windows[-1].openness <= 0
        t = @eagle_dup_windows.pop
        t.dispose
      end
    end
  end

  #--------------------------------------------------------------------------
  # ● 打开直至完成（当有文字绘制完成时执行）
  #--------------------------------------------------------------------------
  def open_and_wait
    @flag_open_close = true
    eagle_process_open_and_wait
    @flag_open_close = false
    @flag_need_open  = false
  end
  #--------------------------------------------------------------------------
  # ● 处理打开方式（打开直至完成）
  #--------------------------------------------------------------------------
  def eagle_process_open_and_wait
    case func_params[:open]
    when 3;  eagle_open_type_slide
    when 2;  eagle_open_type_ease
    when 21; eagle_open_type_ease(nil, 1)
    when 22; eagle_open_type_ease(1, nil)
    when 1;  eagle_open_type_fade
    else;    eagle_open_type_default
    end
  end
  #--------------------------------------------------------------------------
  # ● 打开-滑动移入
  #--------------------------------------------------------------------------
  def eagle_open_type_slide
    self.openness = 0
    @eagle_chara_sprites.each { |c| c.visible = false }
    # 临时屏蔽位置修改功能，让对话框能显示到屏幕外
    @flag_no_fix = true
    h = {:ins => true, :open => true}
    eagle_set_wh(h)
    self.openness = 255
    # 直接指定初始位置在屏幕外
    @eagle_last_x = self.x
    @eagle_last_y = self.y > Graphics.height/2 ? (Graphics.height+20) : (0-self.height-20)
    # 移动回真实显示位置
    eagle_set_wh({:ease_type => :msg_open_slide})
    # 解除屏蔽
    @flag_no_fix = false
    @eagle_chara_sprites.each { |c| c.move_in; c.visible = true }
  end
  #--------------------------------------------------------------------------
  # ● 打开-动态展开
  #--------------------------------------------------------------------------
  def eagle_open_type_ease(init_w = 1, init_h = 1)
    @eagle_chara_sprites.each { |c| c.visible = false }
    if self.openness == 0 # 如果还没打开，则预设下初始窗口大小
      eagle_set_wh({:w => init_w, :h => init_h, :ins => true, :open => true}) 
    end
    self.openness = 255 #直接完成打开，该效果不需要openness打开
    eagle_set_wh({:open => true})
    @eagle_chara_sprites.each { |c| c.move_in; c.visible = true }
  end
  #--------------------------------------------------------------------------
  # ● 打开-淡入
  #--------------------------------------------------------------------------
  def eagle_open_type_fade
    eagle_set_wh({:ins => true, :open => true})
    update_back_sprite_zoom(nil, nil) # 将背景精灵的缩放重置为 1.0
    @eagle_chara_sprites.each { |c| c.move_in }
    self.openness = 255
    @eagle_window_name.openness = 255 if game_message.name? 
    _opa = 0
    while ( _opa < 255 )
      _opa += 26
      self.opacity = _opa if @background == 0 && !@back_sprite.visible
      update_assets_opacity(_opa)
      Fiber.yield
      eagle_win_update # 因为update中不更新基础对话框的位置，故加入一次更新
    end
  end
  #--------------------------------------------------------------------------
  # ● 打开-默认openness
  #--------------------------------------------------------------------------
  def eagle_open_type_default
    eagle_set_wh({:ins => true, :open => true})
    update_back_sprite_zoom(nil, nil) # 将背景精灵的缩放重置为 1
    @eagle_chara_sprites.each { |c| c.visible = false }
    open
    until open?
      update_back_sprite_opa(self.openness)
      Fiber.yield
    end
    @eagle_chara_sprites.each { |c| c.move_in; c.visible = true }
  end
  #--------------------------------------------------------------------------
  # ● 关闭直至完成
  #--------------------------------------------------------------------------
  def close_and_wait
    @flag_open_close = true
    show if !self.visible
    Fiber.yield # 关闭前等待1帧，用于截图等
    eagle_message_sprites_move_out
    Fiber.yield # 文字移出后等待1帧，确保成功移出
    eagle_process_close_and_wait
    @flag_open_close = false
    @flag_need_open = true
    @back_sprite.visible = false
    @back_sprite.bitmap = nil
  end
  #--------------------------------------------------------------------------
  # ● 处理关闭方式（关闭直至完成）
  #--------------------------------------------------------------------------
  def eagle_process_close_and_wait
    case func_params[:close]
    when 3;  eagle_close_type_slide
    when 2;  eagle_close_type_ease
    when 21; eagle_close_type_ease(nil, 1)
    when 22; eagle_close_type_ease(1, nil)
    when 1;  eagle_close_type_fade
    else;    eagle_close_type_default
    end
  end
  #--------------------------------------------------------------------------
  # ● 关闭-滑出
  #--------------------------------------------------------------------------
  def eagle_close_type_slide
    eagle_move_out_assets
    @flag_no_fix = true
    # 直接指定目的位置在屏幕外
    h = {:ease_type => :msg_close_slide, :close => true, 
      :w => self.width, :h => self.height}
    h[:x_init] = self.x
    h[:y_init] = self.y
    h[:x] = self.x
    h[:y] = self.y > Graphics.height/2 ? (Graphics.height+20) : (0-self.height-20)
    # 由于 eagle_set_wh 原理是把基于目前xywh的增量逐渐减小至0，然后完成更新，
    #  需要先强制把当前y改成目的地处，才能正常依靠增量减小而逼近目的地
    @eagle_offset_y += h[:y] - h[:y_init]
    eagle_set_wh(h)
    @flag_no_fix = false
    self.openness = 0
    close
    @eagle_offset_y = 0
  end
  #--------------------------------------------------------------------------
  # ● 关闭-动态缩小
  #--------------------------------------------------------------------------
  def eagle_close_type_ease(final_w = 1, final_h = 1)
    eagle_move_out_assets
    eagle_set_wh({:w => final_w, :h => final_h, :close => true}) if self.openness > 0
    self.openness = 0
    close
    if @eagle_window_name
      # 如果是透明对话框，没有缩小过程，此处强制姓名框关闭
      @eagle_window_name.contents_opacity = 0
      @eagle_window_name.update
    end
  end
  #--------------------------------------------------------------------------
  # ● 关闭-淡出
  #--------------------------------------------------------------------------
  def eagle_close_type_fade
    _opa = [self.opacity, @back_sprite.opacity].max
    while ( _opa > 0 )
      @eagle_offset_y -= 2
      _opa -= 30
      self.opacity = _opa if @background == 0 && !@back_sprite.visible
      update_assets_opacity(_opa)
      Fiber.yield
      eagle_win_update # 因为update中不更新对话框位置，故更新一次
    end
    self.openness = 0
    close
    @eagle_offset_y = 0
  end
  #--------------------------------------------------------------------------
  # ● 关闭-默认openness
  #--------------------------------------------------------------------------
  def eagle_close_type_default
    close
    until all_close?
      update_back_sprite_opa(self.openness)
      Fiber.yield
    end
  end
  #--------------------------------------------------------------------------
  # ● 关闭
  #--------------------------------------------------------------------------
  def close
    super
    eagle_message_reset
  end
  #--------------------------------------------------------------------------
  # ● 判定是否所有窗口已全部关闭
  #--------------------------------------------------------------------------
  def all_close?
    close? && @choice_window.close? &&
    @number_window.close? && @item_window.close?
  end
  #--------------------------------------------------------------------------
  # ● 移出全部文字精灵
  #--------------------------------------------------------------------------
  def eagle_message_sprites_move_out
    while(!@eagle_chara_sprites.empty?)
      c = eagle_take_out_a_chara
      ensure_character_visible(c, true) # 不要聚焦当前文字的缓动动画了，太慢
      c.move_out # 已经交由文字池进行后续更新释放
      if @eagle_force_close  # 如果强制关闭，则不等待移出了
      else
        win_params[:cwo].times { Fiber.yield }
        if @flag_need_change_wh || # 如果预定了宽高变化，则这里不需要再逐个变化了
           win_params[:cwo] == 0  # 如果根本没有逐个移出，也不需要动态变化宽高
        else
          eagle_recalc_charas_wh_when_out
        end
      end
    end
    @eagle_chara_sets.clear
  end
  #--------------------------------------------------------------------------
  # ● 取出一个文字精灵
  #--------------------------------------------------------------------------
  def eagle_take_out_a_chara
    case win_params[:cor]
    when 0, false; return @eagle_chara_sprites.shift
    when 1, true; return @eagle_chara_sprites.pop
    when 2;
      i = rand(@eagle_chara_sprites.size)
      return @eagle_chara_sprites.delete_at(i)
    end
  end
  #--------------------------------------------------------------------------
  # ● 取出一个文字精灵后，重新计算宽高
  #--------------------------------------------------------------------------
  def eagle_recalc_charas_wh_when_out
    rects = @eagle_chara_sprites.collect { |s| s.screen_rect }
    r = MESSAGE_EX.get_smallest_box(rects)
    @eagle_charas_w = r.width
    @eagle_charas_h = r.height
    eagle_set_wh({:ins => true})
  end

  #--------------------------------------------------------------------------
  # ● 设置对话框大小位置，并等待更新结束
  #--------------------------------------------------------------------------
  def eagle_set_wh(_p = {})
    eagle_before_set_xywh(_p)
    eagle_set_params_xywh(_p)
    eagle_apply_params_xywh(_p)
    wait_until_des_wh(_p)
    eagle_after_set_xywh(_p)
  end
  #--------------------------------------------------------------------------
  # ● 对话框位置大小更新前的处理
  #--------------------------------------------------------------------------
  def eagle_before_set_xywh(_p)
  end
  #--------------------------------------------------------------------------
  # ● 设置对话框xywh的参数Hash
  #--------------------------------------------------------------------------
  def eagle_set_params_xywh(_p = {})
    _p[:update] = [] # 将会进行更新的属性
    _p[:ins] = false if _p[:ins].nil? # 如果需要立刻更新完成，置为 true
    if @background == 2  or        # 透明背景时直接更新完成
       @eagle_force_close or       # 快进时直接更新完成
       func_params[:anim] == false # 关闭缓动动画时直接更新完成
      _p[:ins] = true
    end
    _p[:open] = false if _p[:open].nil? # 如果目标是打开窗口，置为 true
    _p[:t] ||= 20 # 更新所需时间（帧）
    # _p[:ease_type] # 指定预设所用的缓动函数类别，见 MESSAGE_EX.ease_value()
    
    # 先计算目标宽高（该变量与其它参数均无关，只需要预绘制后的文字区域宽高）
    #_p[:w] 与 _p[:h] 为更新结束时的宽高，如果为 nil，将自动计算
    _p[:w_init] = self.width
    if _p[:w].nil?
      _p[:w]  = eagle_window_width
      _p[:w] += eagle_window_width_add(_p[:w])
    end
    _p[:w_d] = _p[:w] - _p[:w_init]
    _p[:update].push(:w) if _p[:w_d] != 0

    _p[:h_init] = self.height
    if _p[:h].nil?
      _p[:h]  = eagle_window_height
      _p[:h] += eagle_window_height_add(_p[:h])
    end
    _p[:h_d] = _p[:h] - _p[:h_init]
    _p[:update].push(:h) if _p[:h_d] != 0
    
    # 如果为打开/预定变更宽高，记录最终的宽高
    if _p[:open] || @flag_need_change_wh 
      @eagle_win_des_w = _p[:w]
      @eagle_win_des_h = _p[:h]
      # 有可能对话框还没重置不透明度
      @back_sprite.visible ? @back_sprite.opacity = 255 : self.opacity = 255
      # 因为在更新宽高前打开了姓名框，这里先隐藏
      @eagle_window_name.hide if game_message.name?
    end
    # 需要先计算出目标宽高，再更新该设置，才能保证更新后的xy为真正的移动目标位置
    eagle_win_update 

    #_p[:x] 与 _p[:y] 为更新结束时的位置，如果为 nil，且对话框未关闭，将自动计算
    if _p[:open] || @eagle_last_x.nil? || @eagle_last_y.nil?
      # 如果为打开，则已经直接移到了目的地，此处不再变更xy
      _p[:x] = nil
      _p[:y] = nil
    elsif self.openness == 255
      _p[:x_init] = @eagle_last_x if _p[:x_init].nil?
      _p[:y_init] = @eagle_last_y if _p[:y_init].nil?
      _p[:x] = self.x if _p[:x].nil?
      _p[:y] = self.y if _p[:y].nil?
    end
    if _p[:x]
      _p[:x_d] = _p[:x] - _p[:x_init]
      _p[:update].push(:x) if _p[:x_d] != 0
    end
    if _p[:y]
      _p[:y_d] = _p[:y] - _p[:y_init]
      _p[:update].push(:y) if _p[:y_d] != 0
    end
  end
  #--------------------------------------------------------------------------
  # ● 应用对话框xywh的参数Hash的预修改
  #--------------------------------------------------------------------------
  def eagle_apply_params_xywh(_p = {})
    if _p[:x_d] # 如果设置了移动，则覆盖移动增量来进行对话框的移动
      @eagle_move_x = - _p[:x_d]
    end
    if _p[:y_d]
      @eagle_move_y = - _p[:y_d]
    end
    if _p[:ins] # 处理立即完成宽高的更新
      @eagle_move_x = 0
      @eagle_move_y = 0
      self.width = _p[:w]
      self.height = _p[:h]
      _p[:update].clear
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新对话框宽高直至完成
  #--------------------------------------------------------------------------
  def wait_until_des_wh(_p = {})
    return eagle_after_wh_change if _p[:update].empty?
    max_w = [_p[:w], _p[:w_init]].max
    max_h = [_p[:h], _p[:h_init]].max
    _i = 0; _t = _p[:t]
    _t = 0 if _t < 0
    while(true)
      break if self.openness == 0
      break if _i > _t
      _p[:i] = _i
      per = _i * 1.0 / _t
      if _i == _t
        per = 1
      else
        f = :msg_xywh
        f = :msg_open if _p[:open]
        f = :msg_close if _p[:close]
        f = _p[:ease_type] if _p[:ease_type]
        per = MESSAGE_EX.ease_value(f, per)
      end
      _p[:per] = per
      _p[:update].each do |sym|
        case sym
        when :x
          _x = _p[:x_init] + _p[:x_d] * per
          @eagle_move_x = (_x - _p[:x]).round
        when :y
          _y = _p[:y_init] + _p[:y_d] * per
          @eagle_move_y = (_y - _p[:y]).round
        when :w
          self.width = (_p[:w_init] + _p[:w_d] * per).round
        when :h
          self.height = (_p[:h_init] + _p[:h_d] * per).round
        end
      end
      eagle_after_wh_change
      update_back_sprite_zoom(max_w, max_h, _p)
      Fiber.yield
      _i += 1
    end
  end
  #--------------------------------------------------------------------------
  # ● 在宽度高度变化后的处理
  # 此时 self.width 与 self.height 为实时的宽高，非最终完成时的宽高
  #--------------------------------------------------------------------------
  def eagle_after_wh_change
    eagle_win_update  # 先更新对话框位置
    eagle_recreate_back_bitmap(self.width, self.height)  # 再生成新背景位图
  end
  #--------------------------------------------------------------------------
  # ● 对话框进行位置大小更新后的处理
  #--------------------------------------------------------------------------
  def eagle_after_set_xywh(_p)
    @eagle_last_x = self.x  # 存储对话框的新位置，之后将作为移动前的初始值
    @eagle_last_y = self.y
    # 因为在更新宽高前隐藏了姓名框，这里重新显示
    if _p[:open] || @flag_need_change_wh 
      @eagle_window_name.show if game_message.name?
    end
  end
  #--------------------------------------------------------------------------
  # ● 获取窗口的初始宽度高度
  #--------------------------------------------------------------------------
  def window_width;   Graphics.width;     end
  def window_height;  [96+standard_padding*2, fitting_height(4)].max;  end
  #--------------------------------------------------------------------------
  # ● 获取窗口的实际宽度高度
  #--------------------------------------------------------------------------
  def eagle_window_width
    w = eagle_window_charas_width
    if w
      w = [w, eagle_name_width].max  # 确保姓名框的嵌入
      w += eagle_face_width          # 确保脸图有地方显示
      w += standard_padding * 2      # 增加边框
      return w
    end
    return window_width
  end
  def eagle_window_height
    h = eagle_window_charas_height
    if h
      h += eagle_name_height         # 确保姓名框的嵌入
      h = [h, eagle_face_height].max if eagle_face_in_window? # 确保脸图完整显示
      h += standard_padding * 2      # 增加边框
      return h
    end
    return window_height
  end
  #--------------------------------------------------------------------------
  # ● 获取窗口的文字的宽度高度
  #--------------------------------------------------------------------------
  def eagle_window_charas_width
    if game_message.pop?
      return pop_params[:w] if pop_params[:w] > 0
    else
      return win_params[:w] if win_params[:w] > 0
    end
    w = nil
    w = @eagle_charas_w       if eagle_dynamic_w?
    w = @eagle_charas_w_final if eagle_dyn_fit_w?
    if w
      w = win_params[:wmin] if win_params[:wmin] > 0 && w < win_params[:wmin]
      w = win_params[:wmax] if win_params[:wmax] > 0 && w > win_params[:wmax]
    end
    return w
  end
  def eagle_window_charas_height
    if game_message.pop? 
      return eagle_check_param_h(pop_params[:h]) if pop_params[:h] > 0
    else
      return eagle_check_param_h(win_params[:h]) if win_params[:h] > 0
    end
    h = nil
    h = [@eagle_charas_h, line_height].max if eagle_dynamic_h?
    h = @eagle_charas_h_final if eagle_dyn_fit_h?
    if h
      h = win_params[:hmin] if win_params[:hmin] > 0 && h < win_params[:hmin]
      h = win_params[:hmax] if win_params[:hmax] > 0 && h > win_params[:hmax]
    end
    return h
  end
  #--------------------------------------------------------------------------
  # ● 检查内容高度参数
  #  如果h小于行高，则判定其为行数
  #--------------------------------------------------------------------------
  def eagle_check_param_h(h)
    return 0 if h <= 0
    h = line_height * h + win_params[:ld] * (h - 1) if h < line_height
    return h
  end
  #--------------------------------------------------------------------------
  # ● 直接指定宽度高度？
  #--------------------------------------------------------------------------
  def eagle_fix_w?
    game_message.pop? ? pop_params[:w] > 0 : win_params[:w] > 0
  end
  def eagle_fix_h?
    game_message.pop? ? pop_params[:h] > 0 : win_params[:h] > 0
  end
  #--------------------------------------------------------------------------
  # ● 动态调整宽度高度？
  #--------------------------------------------------------------------------
  def eagle_dynamic_w?
    game_message.pop? ? pop_params[:dw] : win_params[:dw]
  end
  def eagle_dynamic_h?
    game_message.pop? ? pop_params[:dh] : win_params[:dh]
  end
  #--------------------------------------------------------------------------
  # ● 预计算完整文字区域的宽度高度？
  #--------------------------------------------------------------------------
  def eagle_dyn_fit_w?
    game_message.pop? ? pop_params[:fw] : win_params[:fw]
  end
  def eagle_dyn_fit_h?
    game_message.pop? ? pop_params[:fh] : win_params[:fh]
  end
  #--------------------------------------------------------------------------
  # ● 可由子窗口增加对话框的宽度高度？
  #--------------------------------------------------------------------------
  def eagle_add_w_by_child_window?
    return false if eagle_fix_w?
    return true  if eagle_dynamic_w? || eagle_dyn_fit_w?
    return false
  end
  def eagle_add_h_by_child_window?
    return false if eagle_fix_h?
    return true  if eagle_dynamic_h? || eagle_dyn_fit_h?
    return false
  end
  #--------------------------------------------------------------------------
  # ● 额外增加的窗口宽度高度
  #--------------------------------------------------------------------------
  def eagle_window_width_add(cur_width)
    eagle_window_w_empty + game_message.child_window_w_des
  end
  def eagle_window_height_add(cur_height)
    eagle_window_h_empty + game_message.child_window_h_des
  end
  #--------------------------------------------------------------------------
  # ● 窗口内容中，无法被用于文本绘制的宽高
  #--------------------------------------------------------------------------
  def eagle_window_w_empty
    win_params[:cdl] + @eagle_sprite_pause_width_add + win_params[:cdr]
  end
  def eagle_window_h_empty
    win_params[:cdu] + win_params[:cdd]
  end

  #--------------------------------------------------------------------------
  # ● 更新win参数组（初始化/一页绘制完成时调用）
  #--------------------------------------------------------------------------
  def eagle_win_update
    return eagle_pop_update if game_message.pop? && @eagle_pop_obj
    eagle_change_windowskin
    self.x = win_params[:x] || default_init_x
    self.y = win_params[:y] || default_init_y
    MESSAGE_EX.reset_xy_dorigin(self, nil, win_params[:do]) if win_params[:do] < 0
    MESSAGE_EX.reset_xy_origin(self, win_params[:o])
    eagle_set_xy_ex
    self.x = self.x + win_params[:dx] + @eagle_move_x + @eagle_offset_x
    self.y = self.y + win_params[:dy] + @eagle_move_y + @eagle_offset_y
    eagle_fix_position if win_params[:fix]
    eagle_after_update_xy
  end
  #--------------------------------------------------------------------------
  # ● 获取对话框的初始位置
  #--------------------------------------------------------------------------
  def default_init_x;  0;  end
  def default_init_y; (@position*(Graphics.height-@eagle_win_des_h)/2); end
  #--------------------------------------------------------------------------
  # ● 重定义对话框的位置（此时已经处理完了xy或do的初始指定位置）（扩展用）
  #--------------------------------------------------------------------------
  def eagle_set_xy_ex
  end
  #--------------------------------------------------------------------------
  # ● 修正位置（确保对话框完整显示）
  #--------------------------------------------------------------------------
  def eagle_fix_position
    return if @flag_no_fix
    self.x = [[self.x, 0].max, Graphics.width - self.width].min
    self.y = [[self.y, 0].max, Graphics.height - self.height].min
  end
  #--------------------------------------------------------------------------
  # ● 更新xy后的操作
  #--------------------------------------------------------------------------
  def eagle_after_update_xy
    eagle_set_charas_viewport
    eagle_name_update if game_message.name?
    # 可能修改了对话框位置，检查下tag要不要显示
    eagle_pop_tag_fix_position if pop_params[:with_tag] 
  end
  #--------------------------------------------------------------------------
  # ● 设置文字显示区域的矩形（屏幕坐标）
  #--------------------------------------------------------------------------
  def eagle_set_charas_viewport
    @eagle_chara_viewport.rect.set(eagle_charas_x0, eagle_charas_y0,
      eagle_charas_max_w, eagle_charas_max_h)
  end
  #--------------------------------------------------------------------------
  # ● 更新pop参数组
  #--------------------------------------------------------------------------
  def eagle_pop_update
    eagle_change_windowskin(pop_params[:skin])
    eagle_pop_init_xy
    o = pop_params[:o] # 设置对话框的显示原点
    o ||= 10 - pop_params[:do]  # 显示原点恰好与绑定对象的位置相反
    MESSAGE_EX.reset_xy_origin(self, o)
    # 将对话框移动到绑定对象的对应方向上，并加上偏移量
    case pop_params[:do]
    when 1,4,7; self.x -= (pop_params[:chara_w] / 2 + pop_params[:d])
    when 3,6,9; self.x += (pop_params[:chara_w] / 2 + pop_params[:d])
    end
    case pop_params[:do]
    when 1,2,3; self.y += (pop_params[:d])
    when 4,5,6; self.y -= (pop_params[:chara_h] / 2)
    when 7,8,9; self.y -= (pop_params[:chara_h] + pop_params[:d])
    end
    self.x += @eagle_move_x + @eagle_offset_x
    self.y += @eagle_move_y + @eagle_offset_y
    eagle_pop_tag_update  # 更新pop的tag的位置
    self.x += pop_params[:dx]  # 坐标的补足偏移量
    self.y += pop_params[:dy]
    eagle_fix_position if pop_params[:fix]
    eagle_after_update_xy
  end
  #--------------------------------------------------------------------------
  # ● 更新pop的初始位置
  #--------------------------------------------------------------------------
  def eagle_pop_init_xy
    # 对话框左上角定位到绑定对象位图的对应o位置
    case pop_params[:type]
    when :map_chara
      # 如果对象使用的是行走图，则为Game_Chacter（行走图底部中心为显示原点）
      self.x = @eagle_pop_obj.screen_x
      self.y = @eagle_pop_obj.screen_y
    when :battle_sprite
      # 如果对象为战斗者精灵，则为Sprite_Battler（底部中心为显示原点）
      self.x = @eagle_pop_obj.x
      self.y = @eagle_pop_obj.y
    when :map_grid
      # 如果为地图格子，则格子底部中心为显示原点
      self.x = $game_map.adjust_x(@eagle_pop_obj[0]) * 32 + 16
      self.y = $game_map.adjust_y(@eagle_pop_obj[1]) * 32 + 32
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新pop的tag
  #--------------------------------------------------------------------------
  def eagle_pop_tag_update
    return if !pop_params[:with_tag]
    i = 10 - pop_params[:do] # tag的显示帧恰好与pop对话框的do值相对
    # tag的显示原点，是pop对话框的do，即目标物体的九宫格位置
    o = pop_params[:do]
    #  但注意，需要调整到 2468 的位置
    o = 2 if o == 1 || o == 3
    o = 8 if o == 7 || o == 9
    _do = pop_params[:o] # 对话框的显示原点是tag的显示位置
    _do ||= 10 - pop_params[:do]
    MESSAGE_EX.set_windowtag(self, @eagle_sprite_pop_tag, i, o, _do)
    case i # 坐标距离事件格子中心的偏移量
    when 1,4,7; @eagle_sprite_pop_tag.x += pop_params[:td]
    when 3,6,9; @eagle_sprite_pop_tag.x -= pop_params[:td]
    end
    case i
    when 1,2,3; @eagle_sprite_pop_tag.y -= pop_params[:td]
    when 7,8,9; @eagle_sprite_pop_tag.y += pop_params[:td]
    end
  end
  #--------------------------------------------------------------------------
  # ● 若tag因对话框的fix_position而位于对话框内，则隐藏
  #--------------------------------------------------------------------------
  def eagle_pop_tag_fix_position
    return if !pop_params[:with_tag]
    s = @eagle_sprite_pop_tag
    d = pop_params[:td]
    rect1 = Rect.new(s.x+d, s.y+d, s.width-2*d, s.height-2*d)
    rect2 = Rect.new(self.x, self.y, self.width, self.height)
    s.visible = false if MESSAGE_EX.rect_collide_rect?(rect1, rect2)
  end
  #--------------------------------------------------------------------------
  # ● 更新name参数组（随win/pop参数组更新）
  #--------------------------------------------------------------------------
  def eagle_name_update
    if name_params[:do] == 0  # 嵌入
      # 考虑到姓名框自己也有边框，此处 standard_padding 一加一减抵消了
      @eagle_window_name.x = self.x +  \
        @eagle_window_name.rect_real.x + eagle_face_left_width
      @eagle_window_name.y = self.y +  \
        @eagle_window_name.rect_real.y
    else
      MESSAGE_EX.reset_xy_dorigin(@eagle_window_name, self, name_params[:do])
      MESSAGE_EX.reset_xy_origin(@eagle_window_name, name_params[:o])
      # 若姓名框遮挡了脸图，则移动到不遮挡的地方
      if game_message.no_name_overlap_face && eagle_face_width > 0
        lx = self.x + eagle_face_left_width
        rx = self.x + self.width - eagle_face_right_width
        w = @eagle_window_name.width
        @eagle_window_name.x = lx if @eagle_window_name.x < lx
        @eagle_window_name.x = rx-w if @eagle_window_name.x+w > rx
      end
    end
    @eagle_window_name.x += name_params[:dx]  # 坐标的补足偏移量
    @eagle_window_name.y += name_params[:dy]
    @eagle_window_name.update_with_msg
  end

  #--------------------------------------------------------------------------
  # ● 变更窗口皮肤
  #--------------------------------------------------------------------------
  def eagle_change_windowskin(index = nil)
    index = win_params[:skin] if index.nil?
    eagle_set_pop_tag_by_windowskin(index)
    return if @win_skin_draw == index
    @win_skin_draw = index
    self.windowskin = MESSAGE_EX.windowskin(index)
    change_color(text_color(font_params[:c]))
  end
  #--------------------------------------------------------------------------
  # ● 获取当前窗口皮肤的序号
  #--------------------------------------------------------------------------
  def get_cur_windowskin_index(index = nil)
    return index if index
    return pop_params[:skin] if game_message.pop? && !pop_params[:skin].nil?
    return win_params[:skin]
  end
  #--------------------------------------------------------------------------
  # ● 依据窗口皮肤设置tag序号
  #--------------------------------------------------------------------------
  def eagle_set_pop_tag_by_windowskin(index = nil)
    tag_id = MESSAGE_EX::WINDOWSKIN_TO_WINDOWTAG[index]
    return if tag_id.nil?
    eagle_reset_pop_tag_bitmap(tag_id)
  end

  #--------------------------------------------------------------------------
  # ● 重新生成背景位图
  #--------------------------------------------------------------------------
  def eagle_recreate_back_bitmap(w = self.width, h = self.height)
    case @background
    when 1 # 暗色背景
      if @back_bitmap && @back_bitmap.width == w && @back_bitmap.height == h
      else # 重绘
        @back_bitmap.dispose if @back_bitmap
        @back_bitmap = Bitmap.new(w, h)
        rect1 = Rect.new(0, 0, w, 12)
        rect2 = Rect.new(0, 12, w, h - 24)
        rect3 = Rect.new(0, h - 12, w, 12)
        @back_bitmap.gradient_fill_rect(rect1, back_color2, back_color1, true)
        @back_bitmap.fill_rect(rect2, back_color1)
        @back_bitmap.gradient_fill_rect(rect3, back_color1, back_color2, true)
      end
      @back_sprite.bitmap = @back_bitmap
      update_back_sprite
      @back_sprite.visible = true
      @back_sprite.opacity = 255
      self.opacity = 0
    when 2 # 透明背景
      @back_sprite.visible = false
      @back_sprite.bitmap = nil
      @back_sprite.opacity = 255  # 依靠该值来进行关闭-淡出
      self.opacity = 0
    else # 普通
      if game_message.pop?
        return if pop_params[:bg] && eagle_draw_bg_pic(pop_params[:bg], w, h)
      else
        return if win_params[:bg] && eagle_draw_bg_pic(win_params[:bg], w, h)
      end
      @back_sprite.visible = false
      @back_sprite.bitmap = nil
      self.opacity = 255
    end
  end
  #--------------------------------------------------------------------------
  # ● 获取暗色背景的背景色
  #--------------------------------------------------------------------------
  def back_color1; Color.new(0, 0, 0, 160); end
  def back_color2; Color.new(0, 0, 0,   0); end
  #--------------------------------------------------------------------------
  # ● 绘制背景图片
  #--------------------------------------------------------------------------
  def eagle_draw_bg_pic(windowbg, w, h)
    _bitmap = MESSAGE_EX.windowbg(windowbg, w, h)
    if _bitmap != nil
      # 如果已经赋值，说明初始化过了
      return true if @back_sprite.bitmap == _bitmap
      self.opacity = 0
      @back_sprite.opacity = 0
      update_back_sprite  # 更新位置
      @back_sprite.bitmap = _bitmap
      @back_sprite.visible = true
      return true
    end
    return false
  end
  #--------------------------------------------------------------------------
  # ● 更新背景精灵
  #--------------------------------------------------------------------------
  def update_back_sprite 
    ps = game_message.pop? ? pop_params : win_params
    _o = ps[:bgo]
    _o = ps[:o] || 7 if @background == 1  # 暗色背景下，与对话框的原点一致
    MESSAGE_EX.reset_xy_dorigin(@back_sprite, self, _o)
    MESSAGE_EX.reset_sprite_oxy(@back_sprite, _o)
    @back_sprite.x += ps[:bgx]
    @back_sprite.y += ps[:bgy]
  end
  #--------------------------------------------------------------------------
  # ● 更新背景精灵的缩放
  #--------------------------------------------------------------------------
  def update_back_sprite_zoom(max_w = nil, max_h = nil, _p = {})
    if @back_sprite.visible == false # 使用了图片背景，才进行缩放
      @back_sprite.zoom_x = @back_sprite.zoom_y = 1
      return 
    end
    opa = 255
    des_zoom = _p[:close] ? 0 : 1 # 最终缩放值 如果对话框关闭则为0，否则永远为 1
    if max_w == nil # 如果最大宽度为 nil，则说明不需要动态变化背景图片
      @back_sprite.zoom_x = 1
    else
      if _p[:i] and _p[:i] == 0 # 跟随宽高动态缩放
        # 初始宽度为对话框 当前宽度 和 最终宽度 之间的最小值，确保打开时从0开始
        # 再除以图片的宽度，作为初始缩放值
        _p[:bg_zx0] = [self.width, max_w].min * 1.0 / @back_sprite.width
        _p[:bg_zxd] = des_zoom - _p[:bg_zx0]
        @back_sprite.zoom_x = _p[:bg_zx0]
      else
        @back_sprite.zoom_x = _p[:bg_zx0] + _p[:bg_zxd] * _p[:per]
        opa = self.width * 1.0 / max_w * 255
      end
    end
    if max_h == nil
      @back_sprite.zoom_y = 1
    else
      if _p[:i] and _p[:i] == 0
        _p[:bg_zy0] = [self.height, max_h].min * 1.0 / @back_sprite.height
        _p[:bg_zyd] = 1 - _p[:bg_zy0]
        @back_sprite.zoom_y = _p[:bg_zy0]
      else
        @back_sprite.zoom_y = _p[:bg_zy0] + _p[:bg_zyd] * _p[:per]
        opa = [opa, self.height * 1.0 / max_h * 255].min
      end
    end
    if _p[:open] || _p[:close]  # 如果打开或关闭，则更新背景图片的不透明度
      @back_sprite.opacity = opa 
    else   # 否则持续显示
      @back_sprite.opacity = 255
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新背景精灵的不透明度
  #--------------------------------------------------------------------------
  def update_back_sprite_opa(opa); @back_sprite.opacity = opa; end

  #--------------------------------------------------------------------------
  # ● 处理纤程的主逻辑
  #--------------------------------------------------------------------------
  def fiber_main
    game_message.visible = true
    loop do
      eagle_process_before_start
      eagle_process_before_draw
      process_all_text
      process_input
      eagle_process_before_close
      Fiber.yield
      break unless text_continue?
      eagle_process_after_check_continue
    end
    close_and_wait if !@flag_next
    game_message.visible = false
    @fiber = nil
  end
  #--------------------------------------------------------------------------
  # ● 对话框开启前的处理（导入事件中的参数）
  #--------------------------------------------------------------------------
  def eagle_process_before_start
    @background = game_message.background
    @position   = game_message.position
  end
  #--------------------------------------------------------------------------
  # ● 绘制全部文本前
  #--------------------------------------------------------------------------
  def eagle_process_before_draw
    @flag_temp_env = game_message.env  # 保存处理文本前的环境名（用于temp）
    game_message.save_env(:eagle_temp) # 保存处理文本前的环境（用于temp）
    game_message.active = true   # 对话框开始处理文字，该flag置为true用于判定
  end
  #--------------------------------------------------------------------------
  # ● 关闭前
  #--------------------------------------------------------------------------
  def eagle_process_before_close
    game_message.clear
    @gold_window.close if @gold_window
    game_message.active = false   # 对话框不再显示了，将该flag置为false
  end
  #--------------------------------------------------------------------------
  # ● 判定文字是否继续显示（覆盖）
  #--------------------------------------------------------------------------
  def text_continue?
    return false if @flag_need_close
    return game_message.has_text? && !settings_changed?
  end
  #--------------------------------------------------------------------------
  # ● 判定对话框设置是否被更改（覆盖）
  #  此时 $game_message 中存储了下一条指令的对话信息
  #  若返回 false，则会保留当前对话框不关闭，继续显示下一个指令的文本
  #--------------------------------------------------------------------------
  def settings_changed?
    # 因为有动态移动，不再关注位置的改变
    @background != game_message.background #|| @position != game_message.position
  end
  #--------------------------------------------------------------------------
  # ● 当前对话框继续显示，一些变量重置的处理
  #--------------------------------------------------------------------------
  def eagle_process_after_check_continue
    if @flag_hold  # 保留当前对话框时
      # 如果想要新对话框从当前位置再移动到目标位置，则需要该处理
      # 如果注释了，则新对话框是直接在目标位置打开
      #self.openness = 255 
      #@flag_need_open = false
    end
    eagle_message_reset_continue
    @flag_need_change_wh = true  # 由于没有打开关闭，需要更新宽高
  end

  #--------------------------------------------------------------------------
  # ● 获取即将绘制的所有文本内容
  #--------------------------------------------------------------------------
  def eagle_all_text
    text = game_message.all_text
    if !game_message.escape_strings.empty? # 如果存在待处理的转义符串，加到开头
      text = game_message.escape_strings.inject("") { |sum, s| sum = sum + s } + text
      game_message.escape_strings.clear
    end
    text = convert_escape_characters(text)
    text
  end
  #--------------------------------------------------------------------------
  # ● 进行控制符的事前变换
  #    在实际绘制前、将控制符替换为实际的内容。
  #    为了减少歧异，文字「\」会被首先替换为转义符（\e）。
  #--------------------------------------------------------------------------
  def convert_escape_characters(text)
    result = text.to_s.clone
    result = eagle_process_conv(result)
    result = eagle_process_alias(result)
    result = eagle_process_rb(result)
    result = super(result) # 此处将 \\ 替换成了 \e
    result = eagle_process_extra(result)
    result
  end
  #--------------------------------------------------------------------------
  # ● 替换转义符（此时依旧是 \\ 开头的转义符）
  #--------------------------------------------------------------------------
  def eagle_process_conv(text)
    text.gsub!(/\\(conv|M)\[(.*?)\]/i) { MESSAGE_EX.get_conv($2) }
    text
  end
  #--------------------------------------------------------------------------
  # ● 转义符别名（此时依旧是 \\ 开头的转义符）
  #--------------------------------------------------------------------------
  def eagle_process_alias(text)
    MESSAGE_EX::ALIAS_ESCAPE_CHARAS.each { |k, v|
      t1 = k.upcase; t2 = v.upcase
      text.gsub!(/\\#{t1}\[/i) { "\\" + t2 + "[" }
    }
    MESSAGE_EX::ALIAS_ESCAPE_CHARA_PARAM.each { |k, v|
      t1 = k.upcase; t2 = v[0].upcase; t3 = v[1].upcase
      text.gsub!(/\\#{t1}\[(.*?)\]/i) { "\\"+t2+"["+t3+$1+"]" }
    }
    text
  end
  #--------------------------------------------------------------------------
  # ● 处理脚本转义符（此时依旧是 \\ 开头的转义符）
  #--------------------------------------------------------------------------
  def eagle_process_rb(text)
    s = $game_switches; v = $game_variables
    event = $game_map.events[game_message.event_id] rescue nil
    text.gsub!(/\\RB\{(.*?)\}/i) { eval($1).to_s }
    text
  end
  #--------------------------------------------------------------------------
  # ● 处理其它转义符（此时是 \e 开头的转义符）
  #--------------------------------------------------------------------------
  def eagle_process_extra(text)
    text.gsub!(/\eINFO\[(\w)[ ,]*(\d+)[ ,]*(\d+)?\]/i) {
      MESSAGE_EX.get_data_info($1, $2.to_i, $3 || '0')
    }
    text.gsub!(/\eNL/i) { "\n" } # 换行转义符
    text
  end

  #--------------------------------------------------------------------------
  # ● （覆盖）处理所有文本内容
  #--------------------------------------------------------------------------
  def process_all_text
    return if !game_message.has_text?
    text = eagle_all_text; pos = {}
    new_page(text, pos)
    text = eagle_before_process_all_text(text, pos)
    if func_params[:para] && !input_pause?
      @fiber_para = Fiber.new { process_all_text_para(text, pos); 
        @fiber_para = nil }
      return
    end
    process_all_text_para(text, pos)
  end
  #--------------------------------------------------------------------------
  # ● 处理所有文本内容（支持并行用）
  #--------------------------------------------------------------------------
  def process_all_text_para(text, pos)
    loop do # 循环绘制每个文字
      break if text.empty?
      process_character(text.slice!(0, 1), text, pos)
    end
    eagle_process_draw_update if !@eagle_chara_sprites.empty?
    eagle_process_force_close if @eagle_force_close 
  end
  #--------------------------------------------------------------------------
  # ● 强制快速结束
  #--------------------------------------------------------------------------
  def force_close
    @eagle_force_close = true  # 迅速绘制完（跳过全部等待）并跳过最后的等待按键
    @eagle_force_close_c = 0   # 每隔一定绘制次数才等待
    @eagle_auto_continue_c = 0 # 若进入了按键等待，则将计数置0，并依靠auto跳过按键
  end
  #--------------------------------------------------------------------------
  # ● 在处理所有文本内容后，处理强制中断的额外等待
  # （因为文字绘制过程中的等待都无了）
  #--------------------------------------------------------------------------
  def eagle_process_force_close
    @pause_skip = true  # 如果启用了强制关闭，则跳过后续的按键等待
    10.times { Fiber.yield }
  end
  #--------------------------------------------------------------------------
  # ● 翻页处理（删去了翻页功能）
  #--------------------------------------------------------------------------
  def new_page(text, pos)
    eagle_reset_env # 特殊：重置环境
    game_message.reset_child_window_wh_add  # 重置子窗口嵌入时占据的宽高
    pos[:x] = 0; pos[:y] = 0    # 重置pos参数
    pos[:new_x] = 0; pos[:height] = 0
    if @flag_next  # 旧页面不清空，继续绘制
      pos[:y] = @eagle_charas_h_final + win_params[:ld]  # 不要忘记加个行间距
      @flag_need_change_wh = true  # 如果是旧页面继续绘制，则需要更新宽高
      eagle_after_set_xywh({})  # 重置记录的当前xy，作为窗口移动的初始位置
    end

    reset_font_settings
    eagle_check_pre_settings(text)  # 处理预先内容（脸图、姓名等）
    # 去除开头和结尾的换行符
    loop { break if text[0] != "\n"; text[0] = '' }
    loop { break if text[-1] != "\n"; text[-1] = '' }
    # 存储实际绘制的文本，预先转义符已删去（扩展用，获取显示的对话文本）
    game_message.eagle_text = text.clone
    eagle_apply_params_changes  # 执行预定的转义符修改

    clear_flags
    pre_calc_charas_wh(text, pos)  # 预绘制，计算最终宽高
    clear_flags  # 重置绘制会用到的变量
    eagle_apply_params_changes  # 执行预定的转义符修改
  end
  #--------------------------------------------------------------------------
  # ● 清除标志（此处放置每次绘制前需要清空的数据）
  #--------------------------------------------------------------------------
  def clear_flags
    @show_fast        = false   # 快进的标志
    @line_show_fast   = false   # 行单位快进的标志
    @pause_skip       = false   # “不等待输入”的标志
    pop_params[:type] = nil     # pop绑定对象的类型
  end
  #--------------------------------------------------------------------------
  # ● 应用预定的转义符更新
  #--------------------------------------------------------------------------
  def eagle_apply_params_changes
    game_message.params_need_apply.each do |sym|
      m_c = ("eagle_text_control_#{sym}").to_sym
      method(m_c).call("") if respond_to?(m_c)
    end
    game_message.clear_applys
  end
  #--------------------------------------------------------------------------
  # ● 预先绘制一次，获取文字区域绘制完成时的宽高
  #--------------------------------------------------------------------------
  def pre_calc_charas_wh(text, pos)
    text_ = text.clone; pos_ = pos.clone
    @flag_draw = false  # 不进行实际绘制
    game_message.save_env(:pre_draw)  # 保存预绘制前的环境
    last_c_w = @eagle_charas_w  # 保存预绘制前的文字区域宽高
    last_c_h = @eagle_charas_h
    @eagle_charas_w = @eagle_charas_h = 0
    process_character(text_.slice!(0, 1), text_, pos_) until text_.empty?
    @eagle_charas_w_final = [@eagle_charas_w, last_c_w].max # 文字绘制后的宽高
    @eagle_charas_h_final = @eagle_charas_h
    before_input_pause unless @pause_skip  # 此处追加对pause精灵占用宽度的处理
    @eagle_charas_w = last_c_w
    @eagle_charas_h = last_c_h  # 复原当前文字区域宽高
    self.ox = self.oy = 0
    game_message.load_env(:pre_draw)  # 复原转义符环境
    @flag_draw = true
  end
  #--------------------------------------------------------------------------
  # ● 翻页后、绘制前的处理（返回最后需要绘制的文本）
  #--------------------------------------------------------------------------
  def eagle_before_process_all_text(text, pos)
    # 打开窗口前执行文本开头的部分转义符
    text_pre = ""
    loop do 
      break if text[0] == nil or text[0] != "\e"
      text[0] = ''
      sym = obtain_escape_code(text).upcase
      # 先执行win和pop，确保对话框开启前位置和大小确定
      if sym == "WIN" or sym == "POP"
        process_escape_character(sym, text, pos)
        next
      end
      # 其它转义符保留
      text_pre += "\e#{sym}"
      param = obtain_escape_param_string(text)
      text_pre += "[#{param}]" if param != ""
    end
    text = text_pre + text
    # 对话框更新大小位置后、打开前，先打开姓名框
    @eagle_window_name.start if game_message.name?
    # 处理打开对话框 or 更新宽高
    if @flag_need_open # 打开窗口
      eagle_set_wh({:ins => true})  # 打开前需要立即定位一次，避免突然闪现
      open_and_wait 
    elsif @flag_need_change_wh # 如果需要更新宽高
      eagle_set_wh
      @flag_need_change_wh = false
    end
    # 返回最后实际绘制的文本
    return text
  end

  #--------------------------------------------------------------------------
  # ● 文字显示区域的左上角位置（屏幕坐标系）
  #--------------------------------------------------------------------------
  def eagle_charas_x0
    self.x + standard_padding + eagle_face_left_width + win_params[:cdl]
  end
  def eagle_charas_y0
    self.y + standard_padding + eagle_name_height + win_params[:cdu]
  end
  #--------------------------------------------------------------------------
  # ● 计算文字显示区域的宽度和高度
  #--------------------------------------------------------------------------
  def eagle_charas_max_w
    v = self.width - standard_padding*2 - eagle_face_width 
    v = v - win_params[:cdl] - win_params[:cdr]
    v
  end
  def eagle_charas_max_h
    v = self.height - standard_padding*2 - eagle_name_height
    v = v - win_params[:cdu] - win_params[:cdd]
    v
  end
  #--------------------------------------------------------------------------
  # ● 文字显示区域的显示原点
  #--------------------------------------------------------------------------
  def eagle_charas_ox; self.ox; end
  def eagle_charas_oy; self.oy; end
  #--------------------------------------------------------------------------
  # ● 更新正在移入移出文字的显示区域的显示原点
  #--------------------------------------------------------------------------
  def update_moving_charas_oxy
    @eagle_chara_sprites.each { |c|
      c.reset_window_oxy(self.ox, self.oy) if c.move_updating?
    }
  end
  #--------------------------------------------------------------------------
  # ● 重置文字显示区域
  #--------------------------------------------------------------------------
  def eagle_reset_charas_oxy
    # 重置初始区域
    self.ox = self.oy = 0
    # 重置显示区域
    @eagle_chara_viewport.rect.set(0,0,Graphics.width,Graphics.height)
    # 重置文字宽高
    @eagle_charas_w = @eagle_charas_h = 0
    @eagle_charas_w_final = @eagle_charas_h_final = 0
  end
  #--------------------------------------------------------------------------
  # ● 重新生成适合全部文字的位图
  #--------------------------------------------------------------------------
  def recreate_contents_for_charas
    w = @eagle_charas_w + eagle_window_w_empty
    h = @eagle_charas_h + eagle_window_h_empty
    w = 1 if w == 0
    h = 1 if h == 0
    f = self.contents.font.dup
    self.contents.dispose if self.contents
    self.contents = Bitmap.new(w, h)
    self.contents.font = f
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）普通文字的处理
  #--------------------------------------------------------------------------
  def process_normal_character(c, pos)
    pos[:c] = c
    c_rect = text_size(c); c_w = c_rect.width; c_h = c_rect.height
    eagle_auto_new_line(c_w, pos)
    if @flag_draw
      s = eagle_new_chara_sprite(pos[:x], pos[:y], c_w, c_h)
      s.eagle_font.draw(s.bitmap, 0, 0, c_w, c_h, c, 0)
    end
    eagle_process_draw_end(c_w, c_h, pos)
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）处理控制符指定的图标绘制
  #--------------------------------------------------------------------------
  def process_draw_icon(icon_index, pos)
    pos[:c] = icon_index
    eagle_auto_new_line(24, pos)
    if @flag_draw
      s = eagle_new_chara_sprite(pos[:x], pos[:y], 24, 24)
      s.eagle_font.draw_icon(s.bitmap, 0, 0, icon_index)
    end
    eagle_process_draw_end(24, 24, pos)
  end
  #--------------------------------------------------------------------------
  # ● 处理控制符指定的图片绘制
  #--------------------------------------------------------------------------
  def process_draw_pic(text, pos)
    pos[:c] = nil
    param = text.slice!(/^\[.*?\]/)[1..-2]
    params = param.split('|') # [filename, param_str]
    begin
      _bitmap = Cache.picture(params[0])
    rescue
      p "【对话框扩展】未找到\\pic所需的Graphics/Pictures/#{params[0]}图片！"
      return
    end
    h = {}
    parse_param(h, params[1], :opa) if params[1]
    h[:w] ||= _bitmap.width
    h[:h] ||= _bitmap.height
    h[:opa] ||= 255
    eagle_auto_new_line(h[:w], pos)
    if @flag_draw
      s = eagle_new_chara_sprite(pos[:x], pos[:y], h[:w], h[:h])
      s.eagle_font.draw_pic(s.bitmap, _bitmap, h)
    end
    eagle_process_draw_end(h[:w], h[:h], pos)
  end
  #--------------------------------------------------------------------------
  # ● （封装）生成一个新的文字精灵
  #--------------------------------------------------------------------------
  def eagle_new_chara_sprite(c_x, c_y, c_w, c_h)
    f = Font_EagleCharacter.new(font_params)
    f.set_param(:skin, win_params[:skin])
    f.set_param(:ex_cg, ex_params[:cg])
    s = MESSAGE_EX.charapool_new(self, f, c_x, c_y, c_w, c_h, @eagle_chara_viewport)
    s.start_effects(game_message.chara_params)
    @eagle_chara_sprites.push(s) # 存入实时更新的文字数组
    @eagle_chara_sets[@eagle_current_set].push(s) if @eagle_current_set # 分组
    s
  end
  #--------------------------------------------------------------------------
  # ● 检查自动换行
  #--------------------------------------------------------------------------
  def eagle_auto_new_line(c_w, pos)
    return if !@flag_draw  # 如果在预绘制，则不判定，避免初始宽度变成最后一行的宽度
    return if func_params[:aw] == false
    return if !eagle_fix_w? && eagle_dynamic_w?
    max_w = eagle_charas_max_w
    return if max_w <= 0
    return if pos[:x] + c_w <= max_w # 若当前文字绘制完成后会超出边界，则换行
    process_new_line('', pos)
  end
  #--------------------------------------------------------------------------
  # ● 绘制完成时的处理
  #--------------------------------------------------------------------------
  def eagle_process_draw_end(c_w, c_h, pos)
    # 处理下一次绘制的参数
    pos[:x] += (c_w + win_params[:ck])
    pos[:height] = [pos[:height], c_h].max
    # 记录下一个文字绘制位置x
    @eagle_next_chara_x = pos[:x]
    # 处理文字区域大小更改
    @eagle_charas_w = pos[:x] if @eagle_charas_w < pos[:x]
    @eagle_charas_h = pos[:y] + pos[:height] if @eagle_charas_h < pos[:y] + pos[:height]
    return if !@flag_draw
    return if show_fast?  # 如果是立即显示，则不更新
    if @eagle_force_close # 如果是强制关闭，则每隔一定次数才更新
      return if (@eagle_force_close_c += 1) < MESSAGE_EX::FORCE_CLOSE_N
      @eagle_force_close_c = 0
    end
    play_chara_se(pos)  # 播放打字音
    eagle_process_draw_update
    wait_for_one_character
  end
  #--------------------------------------------------------------------------
  # ● 绘制完成时的更新
  #--------------------------------------------------------------------------
  def eagle_process_draw_update
    # 重设对话框宽高，并更新对话框位置
    eagle_set_wh({:ins => true}) 
    # 对齐需要用到对话框的宽高，因此在更新xywh后执行
    eagle_charas_reset_alignment(win_params[:ali])
    # 确保最后绘制的文字在视图区域内
    ensure_character_visible(@eagle_chara_sprites[-1])
  end
  #--------------------------------------------------------------------------
  # ● 重排列全部文字精灵
  #--------------------------------------------------------------------------
  def eagle_charas_reset_alignment(align)
    return if @eagle_chara_sprites.empty?
    charas = [] # 存储当前迭代行的全部文字精灵
    # 存储当前迭代行的y值（同y的为同一行）（未考虑列排文字）
    charas_y = @eagle_chara_sprites[0].origin_y  # 初始为第一行
    # 最大宽度 = [可供文字绘制区域的最大宽度 - 等待按键精灵宽度, 文字宽度].max
    max_w = [eagle_charas_max_w - @eagle_sprite_pause_width_add, 
      @eagle_charas_w].max
    @eagle_chara_sprites.each do |s|
      next charas.push(s) if s.origin_y == charas_y # 第一行的首字符会存入
      # 对同一行的字符重排
      eagle_charas_realign_line(charas, align, max_w)
      charas.clear
      # 将当前迭代的 下一行的首字符 存入
      charas.push(s)
      charas_y = s.origin_y
    end
    # 对最后一行进行重排列
    eagle_charas_realign_line(charas, align, max_w) if !charas.empty?
  end
  #--------------------------------------------------------------------------
  # ● 重排列同一行上的文字精灵
  #--------------------------------------------------------------------------
  def eagle_charas_realign_line(charas, align, max_w)
    w_line = charas[-1].origin_x - charas[0].origin_x + charas[-1].width
    h_line = charas.collect{ |c| c.height }.max
    charas.each do |c|
      case align
      when 0 # 左对齐（默认对齐方式）
        _x = c.origin_x
      when 1 # 居中排列
        _x = c.origin_x + (max_w - w_line) / 2
      when 2 # 右排列
        _x = c.origin_x + max_w - w_line
      end
      _y = c.origin_y + h_line - c.height # 底部对齐
      c.reset_xy(_x, _y)
    end
  end
  #--------------------------------------------------------------------------
  # ● 确保指定文字在视图内
  #--------------------------------------------------------------------------
  def ensure_character_visible(c, no_anim = false)
    return if c.nil?
    ox_1 = self.ox
    ox_d = 0
    ox_d = c._x - self.ox if c._x < self.ox
    d = c._x + c.width - @eagle_chara_viewport.rect.width - self.ox
    ox_d = d if d > 0

    oy_1 = self.oy
    oy_d = 0
    oy_d = c._y - self.oy if c._y < self.oy
    d = c._y + c.height - @eagle_chara_viewport.rect.height - self.oy
    oy_d = d if d > 0

    if !no_anim && @flag_draw && !@flag_open_close && (ox_d != 0 || oy_d != 0)
      # 因为是在新行的首字符绘制完成后调用该方法，因此先把这个字符隐藏了
      c.visible = false
      t = MESSAGE_EX::CHARAS_SCROLL_OUT_FRAME
      (t+1).times do |i|
        per = i * 1.0 / t
        per = MESSAGE_EX.ease_value(:msg_vp, per)
        self.ox = (ox_1 + ox_d * per).round if ox_d != 0
        self.oy = (oy_1 + oy_d * per).round if oy_d != 0
        update_moving_charas_oxy
        Fiber.yield
      end
      c.visible = true
    end
    self.ox = ox_1 + ox_d
    self.oy = oy_1 + oy_d
    update_moving_charas_oxy # 保证文字跟着contents一起移动
  end
  #--------------------------------------------------------------------------
  # ● 处于快进显示？
  #--------------------------------------------------------------------------
  def show_fast?  # 忽略文字绘制后的等待，不跳过转义符产生的等待
    @flag_instant || @show_fast || @line_show_fast
  end
  #--------------------------------------------------------------------------
  # ● 播放打字音
  #--------------------------------------------------------------------------
  def play_chara_se(pos)
    return if @count_chara_se > 0
    MESSAGE_EX.play_chara_se(game_message.win_params[:se], pos[:c])
    @count_chara_se = MESSAGE_EX::CAHRA_SE_N
  end
  #--------------------------------------------------------------------------
  # ● 输出一个字符后的等待
  #--------------------------------------------------------------------------
  def wait_for_one_character
    win_params[:cwi].times do
      return if show_fast?
      update_show_fast if win_params[:cfast]
      Fiber.yield
      return if @eagle_force_close
    end
    Fiber.yield until self.visible  # 如果对话框隐藏了，则等待
  end
  #--------------------------------------------------------------------------
  # ● 监听“确定”键的按下，更新快进的标志
  #--------------------------------------------------------------------------
  def update_show_fast
    @show_fast = true if Input.trigger?(:C)
  end
  #--------------------------------------------------------------------------
  # ● 换行文字的处理（删去翻页）
  #  由于自动对齐的存在，无需预先计算当前行高，text参数无效
  #--------------------------------------------------------------------------
  def process_new_line(text, pos)
    pos[:height] += win_params[:ld] # 当前行增加一个行间距
    @line_show_fast = false
    pos[:x] = pos[:new_x]
    pos[:y] += pos[:height]
    pos[:height] = 0
  end

  #--------------------------------------------------------------------------
  # ● 设置【预先】指令的参数
  #--------------------------------------------------------------------------
  def eagle_check_pre_settings(text)
    eagle_check_temp(text)
    eagle_check_env(text)
    eagle_check_hold(text)
    eagle_check_instant(text)
    eagle_check_close(text)
    eagle_check_next(text)
    eagle_check_eval(text)
    eagle_draw_face(text)
    eagle_draw_name(text)
    eagle_check_func(text)
  end
  #--------------------------------------------------------------------------
  # ● 设置/执行temp指令
  #--------------------------------------------------------------------------
  def eagle_check_temp(text)
    text.gsub!(/\e(temp)/i) { "" }
    @flag_temp = true if $1
  end
  def eagle_process_temp
    return if @flag_temp == false
    @flag_temp = false
    game_message.load_env(:eagle_temp)
    game_message.env = @flag_temp_env
  end
  #--------------------------------------------------------------------------
  # ● 设置env指令
  #--------------------------------------------------------------------------
  def eagle_check_env(text)
    text.gsub!(/\eenv\[(.*?)\]/im) {
      t = $1; sym = t
      t.include?('|') ? sym = t.slice!(/.*?\|/).chop : t = "load"
      eagle_check_env_method(sym, t)
      ""
    }
  end
  def eagle_check_env_method(sym, m = "load")
    case m
    when "save"
      @flag_save_env = sym
    when "load"
      game_message.env = sym
      game_message.save_env(sym) if !game_message.load_env(sym)
    else
      p "对话框的 env 转义符参数错误！环境 #{sym} 与未定义的 #{m} 动作。"
    end
  end
  def eagle_process_env
    return if @flag_save_env == nil
    game_message.save_env(@flag_save_env)
    game_message.env = @flag_save_env
    @flag_save_env = nil
  end
  def eagle_reset_env 
    v = MESSAGE_EX::S_ID_RESET_ENV
    if v == true || (v.is_a?(Integer) && $game_switches[v] == true)
      game_message.env = '0'
      game_message.load_env('0')
    end
  end
  #--------------------------------------------------------------------------
  # ● 设置/执行hold指令
  #--------------------------------------------------------------------------
  def eagle_check_hold(text)
    @flag_hold = false
    @flag_hold_str = ""
    text.gsub!(/\ehold(\[(.*?)\])/i) { 
      @flag_hold = true
      @flag_hold_str = $1 ? $1.to_s : ""
      "" 
    }
    # 移出已存在的具有该 flag_hold_id 的保留对话框
    if @flag_hold_str != ""
      @eagle_dup_windows.each_with_index do |w, i|
        w.close_clone if w.flag_hold_id == @flag_hold_str
      end
    end
  end
  def eagle_process_hold
    if @flag_hold
      t = self.clone
      t.flag_hold_id = @flag_hold_str
      # 重置之前存储的窗口的z值（确保最近的显示在最上面）
      @eagle_dup_windows.each_with_index do |w, i|
        next if t.close_clone?
        w.z = t.z - (i+1) * 5; w.eagle_reset_z
      end
      @eagle_dup_windows.unshift(t)
      self.openness = 0
      @flag_need_open = true
    else
      eagle_release_hold
    end
  end
  def eagle_release_hold # 所有暂存窗口关闭
    @eagle_dup_windows.each { |w| w.close_clone }
  end
  #--------------------------------------------------------------------------
  # ● 设置instant指令
  #--------------------------------------------------------------------------
  def eagle_check_instant(text)
    text.gsub!(/\e(ins)/i) { "" }
    @flag_instant = $1 ? true : false
  end
  #--------------------------------------------------------------------------
  # ● 设置close指令
  #--------------------------------------------------------------------------
  def eagle_check_close(text)
    text.gsub!(/\e(close)/i) { "" }
    @flag_need_close = $1 ? true : false
  end
  #--------------------------------------------------------------------------
  # ● 设置next指令
  #--------------------------------------------------------------------------
  def eagle_check_next(text)
    text.gsub!(/\e(next)/i) { "" }
    @flag_next = $1 ? true : false
  end
  #--------------------------------------------------------------------------
  # ● 设置eval指令
  #--------------------------------------------------------------------------
  def eagle_check_eval(text)
    @eagle_evals.clear # 清除旧的
    text.gsub!(/\eeval\{(.*?)\}/im) {
      @eagle_evals.push($1) # ID 从 1 开始，防止之后param传入nil出错
      "\eeval[#{@eagle_evals.size}]"
    }
    text.gsub!(/\{\{(.*?)\}\}/m) {
      @eagle_evals.push($1)
      "\eeval[#{@eagle_evals.size}]"
    }
  end

  #--------------------------------------------------------------------------
  # ● 分析【预先】转义符的全部参数（按出现顺序处理）
  #--------------------------------------------------------------------------
  def parse_pre_params(text, sym, hash, default_type = :default)
    params = []
    text.gsub!(/\e#{sym}\[(.*?)\]/i) { params.push($1); "" }
    params.push("") if params.empty?
    params.each { |param| parse_param(hash, param, default_type) }
  end
  #--------------------------------------------------------------------------
  # ● 初始化脸图
  #--------------------------------------------------------------------------
  def eagle_draw_face(text)
    face_params[:ls] = -1 # 设置循环开始编号（递增至le，再从ls循环）
    face_params[:le] = -1 # 设置循环结束编号
    parse_pre_params(text, 'facep', face_params, :dir)
    face_params[:dir] = MESSAGE_EX.check_bool(face_params[:dir])
    face_params[:m] = MESSAGE_EX.check_bool(face_params[:m])
    face_params[:name] = game_message.face_name
    face_params[:i] = game_message.face_index
    reset_eagle_sprite_face
  end
  def reset_eagle_sprite_face
    return eagle_move_out_face if face_params[:name] == ""
    if @eagle_sprite_face
      return if @eagle_sprite_face.no_change?
      eagle_move_out_face
    end
    @eagle_sprite_face = MESSAGE_EX.facepool_new
    @eagle_sprite_face.reset(self)
    @eagle_sprite_face.motion(:fade_in)
  end
  #--------------------------------------------------------------------------
  # ● 初始化姓名框
  #--------------------------------------------------------------------------
  def name_params; game_message.name_params; end
  def eagle_draw_name(text)
    # 用 | 分隔需要绘制的name字符串（其中转义符用<>代替[]）和参数组
    str_name = ""
    text.gsub!(/\ename\[(.*?)\]/i) {
      t = $1.dup
      if t.include?('|')
        s = t.slice!(/.*?\|/).chop
        str_name = s if !s.empty?
        "\ename[#{t}]"
      else
        str_name = t
        ""
      end
    }
    parse_pre_params(text, 'name', name_params, :o)
    name_params[:name] = process_name_string(str_name)
    process_draw_name
  end
  def process_name_string(str)  # 预处理姓名字符串
    return "" if str == ""
    t = str
    # 特别的：如果str仅为数字，且为数据库中有效的角色ID，则将替换为其名称
    v = str.to_i
    if v > 0 and $game_actors[v] != nil
      t = MESSAGE_EX::ACTOR_NAME_PREFIX[v] || ""
      t += $game_actors[v].name 
    end
    # 读取统一的前置文本
    t = MESSAGE_EX::ESCAPE_STRING_NAME_PREFIX + t
    # 将转义符中的 <> 替换回 [] 
    t.gsub!(/<(.*?)>/) { "[" + $1 + "]" }
    # 处理转义符
    t = convert_escape_characters(t)
    return t
  end
  def process_draw_name
    @eagle_window_name.reset if @eagle_window_name
  end
  #--------------------------------------------------------------------------
  # ● 姓名框占用的宽度
  #--------------------------------------------------------------------------
  def eagle_name_width
    return 0 if !game_message.name?
    return 0 if name_params[:do] != 0  # 不是嵌入，则不占用
    return @eagle_window_name.contents.width + \
      @eagle_window_name.rect_real.x + @eagle_window_name.rect_real.width + \
      name_params[:dx]
  end
  #--------------------------------------------------------------------------
  # ● 姓名框占用的高度
  #--------------------------------------------------------------------------
  def eagle_name_height
    return 0 if !game_message.name?
    return 0 if name_params[:do] != 0  # 不是嵌入，则不占用
    return @eagle_window_name.contents.height + \
      @eagle_window_name.rect_real.y + @eagle_window_name.rect_real.height + \
      name_params[:dy] + standard_padding 
  end
  #--------------------------------------------------------------------------
  # ● 设置func参数
  #--------------------------------------------------------------------------
  def func_params; game_message.func_params; end
  def eagle_check_func(text)
    parse_pre_params(text, 'func', func_params)
    func_params[:anim] = MESSAGE_EX.check_bool(func_params[:anim])
    func_params[:aw] = MESSAGE_EX.check_bool(func_params[:aw])
    func_params[:para] = MESSAGE_EX.check_bool(func_params[:para])
  end
  #--------------------------------------------------------------------------
  # ● 子窗口可以嵌入？
  #--------------------------------------------------------------------------
  def child_window_embed_in?
    open? && func_params[:para] == false
  end

  #--------------------------------------------------------------------------
  # ● 控制符的处理
  #     code : 控制符的实际形式（比如“\C[1]”是“C”）
  #     text : 绘制处理中的字符串缓存（字符串可能会被修改）
  #     pos  : 绘制位置 {:x, :y, :new_x, :height}
  #--------------------------------------------------------------------------
  def process_escape_character(code, text, pos)
    return if eagle_call_process_escape(code, text, pos)
    temp_code = code.downcase
    m_c = ("eagle_text_control_" + temp_code).to_sym
    m_e = ("eagle_chara_effect_" + temp_code).to_sym
    if respond_to?(m_c)
      param = obtain_escape_param_string(text)
      method(m_c).call(param)
    elsif respond_to?(m_e)
      param = obtain_escape_param_string(text)
      # 当只传入 0 时，代表关闭该特效
      return eagle_chara_effect_clear(temp_code.to_sym) if param == '0'
      game_message.chara_params[temp_code.to_sym] = param
      method(m_e).call(param)
    else
      super(code, text, pos)
    end
  end
  #--------------------------------------------------------------------------
  # ● 控制符的处理（方便扩展的编写方式）
  #     code : 控制符的实际形式（比如“\C[1]”是“C”）
  #     text : 绘制处理中的字符串缓存（字符串可能会被修改）
  #     pos  : 绘制位置 {:x, :y, :new_x, :height}
  #  返回 true 则代表转义符执行成功，否则继续匹配组件和默认转义符
  #--------------------------------------------------------------------------
  def eagle_call_process_escape(code, text, pos)
    c = code.upcase
    case c
    when '$'
      if @gold_window
        @gold_window.open? ? @gold_window.close : @gold_window.open
      end
      return true
    when '.' ; wait(15);               return true
    when '|' ; wait(60);               return true
    when '!' ; input_pause;            return true
    when '>' ; @line_show_fast = true; return true
    when '<' ; 
      @line_show_fast = false
      eagle_process_draw_update  # 因为之前在快进，此处更新一次排版
      return true
    when '^' ; @pause_skip = true;     return true
    when 'C'
      font_params[:c] = obtain_escape_param_string(text)
      change_color(text_color(font_params[:c]))
      return true
    when "PIC"; process_draw_pic(text, pos); return true
    when "CLC"; process_pos_clc(text, pos);  return true
    end
    return false
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）获取控制符的实际形式（这个方法会破坏原始数据）
  #--------------------------------------------------------------------------
  def obtain_escape_code(text)
    text.slice!(/^[\$\.\|\^!><\{\}\\]|^[\d\w]+/i)
  end
  #--------------------------------------------------------------------------
  # ● 获取控制符的参数（变量参数字符串形式）（这个方法会破坏原始数据）
  #--------------------------------------------------------------------------
  def obtain_escape_param_string(text)
    text.slice!(/^\[[ =\|\$\-\d\w]+\]/i)[1..-2] rescue ""
  end
  #--------------------------------------------------------------------------
  # ● 清除暂存的指定文字特效
  #--------------------------------------------------------------------------
  def eagle_chara_effect_clear(code_sym)
    game_message.chara_params.delete(code_sym)
  end
  #--------------------------------------------------------------------------
  # ● 设置\clc清屏效果
  #--------------------------------------------------------------------------
  def process_pos_clc(text, pos)
    text[0] = '' if text[0] == "\n"
    process_new_line(text, pos)
    oy_1 = self.oy
    oy_d = pos[:y]
    if @flag_draw && !@eagle_force_close
      t = MESSAGE_EX::CLC_CHARAS_OUT_FRAME
      (t+1).times do |i|
        per = i * 1.0 / t
        per = MESSAGE_EX.ease_value(:msg_vp, per)
        self.oy = (oy_1 + oy_d * per).round
        update_moving_charas_oxy
        Fiber.yield
      end
    end
    self.oy = oy_1 + oy_d
    update_moving_charas_oxy
  end

  #--------------------------------------------------------------------------
  # ● 设置font参数
  #--------------------------------------------------------------------------
  def font_params; game_message.font_params; end
  def eagle_text_control_font(param = "")
    parse_param(font_params, param, :size)
    change_color(text_color(font_params[:c]))
    MESSAGE_EX.apply_font_params(self.contents.font, font_params)
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）重置字体设置
  #--------------------------------------------------------------------------
  def reset_font_settings
    font_params[:c] = MESSAGE_EX::DEFAULT_COLOR_INDEX
    font_params[:ca] = 255
    change_color(text_color(font_params[:c]))
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）放大字体尺寸
  #--------------------------------------------------------------------------
  def make_font_bigger
    self.contents.font.size += 4 if self.contents.font.size <= 64
    font_params[:size] = self.contents.font.size
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）缩小字体尺寸
  #--------------------------------------------------------------------------
  def make_font_smaller
    self.contents.font.size -= 4 if self.contents.font.size >= 16
    font_params[:size] = self.contents.font.size
  end

  #--------------------------------------------------------------------------
  # ● 设置win参数
  #--------------------------------------------------------------------------
  def win_params; game_message.win_params; end
  def eagle_text_control_win(param = "")
    parse_param(win_params, param, :o)
    win_params[:hmin]  = eagle_check_param_h(win_params[:hmin])
    win_params[:hmax]  = eagle_check_param_h(win_params[:hmax])
    win_params[:dw]    = MESSAGE_EX.check_bool(win_params[:dw])
    win_params[:fw]    = MESSAGE_EX.check_bool(win_params[:fw])
    win_params[:dh]    = MESSAGE_EX.check_bool(win_params[:dh])
    win_params[:fh]    = MESSAGE_EX.check_bool(win_params[:fh])
    win_params[:cwi]   = 0 if win_params[:cwi] < 0
    win_params[:cwo]   = 0 if win_params[:cwo] < 0
    win_params[:cfast] = MESSAGE_EX.check_bool(win_params[:cfast])
    win_params[:fix]   = MESSAGE_EX.check_bool(win_params[:fix])
    eagle_reset_z
    # 兼容旧版本的设置
    win_params[:cdl] = win_params[:cdx] if win_params[:cdx]
    win_params[:cdr] = win_params[:cdw] if win_params[:cdw]
    win_params[:cdu] = win_params[:cdy] if win_params[:cdy]
    win_params[:cdd] = win_params[:cdh] if win_params[:cdh]
    win_params.delete(:cdx); win_params.delete(:cdy)
    win_params.delete(:cdw); win_params.delete(:cdh)
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）获取基础行高
  #--------------------------------------------------------------------------
  def line_height
    h = win_params[:lh] || Font.default_size
    return h if h > 0
    return super
  end

  #--------------------------------------------------------------------------
  # ● 设置pop参数
  #--------------------------------------------------------------------------
  def pop_params; game_message.pop_params; end
  def eagle_text_control_pop(param = "")
    pop_params[:id] = nil # 重置绑定对象
    pop_params[:mx] = nil
    pop_params[:my] = nil
    parse_param(pop_params, param, :id)
    pop_params[:type] = nil # 清除可能的误设置
    @eagle_pop_obj = eagle_get_pop_obj # 获取所绑定的对象
    return pop_params[:type] = nil if @eagle_pop_obj.nil?
    s = eagle_get_pop_sprite # 获取所绑定对象的精灵
    return pop_params[:type] = nil if s.nil? || (s.x == 0 and s.y == 0)
    eagle_set_pop_sprite_info(s)
    pop_params[:dw]       = MESSAGE_EX.check_bool(pop_params[:dw])
    pop_params[:fw]       = MESSAGE_EX.check_bool(pop_params[:fw])
    pop_params[:dh]       = MESSAGE_EX.check_bool(pop_params[:dh])
    pop_params[:fh]       = MESSAGE_EX.check_bool(pop_params[:fh])
    pop_params[:fix]      = MESSAGE_EX.check_bool(pop_params[:fix])
    pop_params[:with_tag] = show_pop_tag? # 设置pop的tag
    eagle_reset_pop_tag_bitmap if pop_params[:with_tag]
    eagle_pop_update
    if pop_params[:with_tag]
      @eagle_sprite_pop_tag.visible = pop_params[:with_tag]
      @eagle_sprite_pop_tag.opacity = 255
    end
  end
  #--------------------------------------------------------------------------
  # ● 获取pop的弹出对象（需要有x、y、width、height方法）
  #--------------------------------------------------------------------------
  def eagle_get_pop_obj
    if pop_params[:id]
      return eagle_get_pop_obj_m if MESSAGE_EX.in_scene?(:map)
      return eagle_get_pop_obj_b if MESSAGE_EX.in_scene?(:battle)
    end
    return eagle_get_pop_obj_ex
  end
  #--------------------------------------------------------------------------
  # ● 获取pop的对象（地图场景中）（Game_Character的实例）
  #--------------------------------------------------------------------------
  def eagle_get_pop_obj_m
    pop_params[:type] = :map_chara
    id = pop_params[:id]
    if id == 0 # 当前事件
      return $game_map.events[game_message.event_id]
    elsif id > 0 # 第id号事件
      chara = $game_map.events[id]
      chara ||= $game_map.events[game_message.event_id]
      return chara
    elsif id < 0 # 队伍中数据库id号角色（不存在则取队长）
      id = id.abs
      $game_player.followers.each { |f|
        return f if f.actor && f.actor.actor.id == id
      }
      return $game_player
    end
  end
  #--------------------------------------------------------------------------
  # ● 获取pop的对象（战斗场景中）（Sprite_Battler的实例）
  #--------------------------------------------------------------------------
  def eagle_get_pop_obj_b
    pop_params[:type] = :battle_sprite
    id = pop_params[:id]
    return nil if id.nil?
    if id > 0 # 敌人index
      SceneManager.scene.spriteset.battler_sprites.each do |s|
        return s if s.battler && s.battler.enemy? && s.battler.index == id-1
      end
    elsif id < 0 # 我方数据库id
      id = id.abs
      SceneManager.scene.spriteset.battler_sprites.each do |s|
        return s if s.battler && s.battler.actor? && s.battler.id == id
      end
    end
    return nil
  end
  #--------------------------------------------------------------------------
  # ● 获取pop的对象（无 id 设置时）
  #--------------------------------------------------------------------------
  def eagle_get_pop_obj_ex
    if MESSAGE_EX.in_scene?(:map) && pop_params[:mx] && pop_params[:my]
      pop_params[:type] = :map_grid
      return [pop_params[:mx], pop_params[:my]]
    end
    return nil
  end
  #--------------------------------------------------------------------------
  # ● 获取pop对象的精灵（用于计算偏移值）
  #--------------------------------------------------------------------------
  def eagle_get_pop_sprite
    # 地图场景中，所存储的并非精灵，需要再次检索
    if pop_params[:type] == :map_chara
      begin
        SceneManager.scene.spriteset.character_sprites.each do |s|
          return s if s.character == @eagle_pop_obj
        end
      rescue
        p "【对话框扩展 by老鹰】未找到pop转义符绑定事件的精灵！可能存在兼容问题！"
      end
      return nil
    end
    return @eagle_pop_obj
  end
  #--------------------------------------------------------------------------
  # ● 存储用于pop更新的精灵对象的信息
  #--------------------------------------------------------------------------
  def eagle_set_pop_sprite_info(s)
    if s.is_a?(Sprite)
      pop_params[:chara_w] = s.width
      pop_params[:chara_h] = s.height
    end
    if pop_params[:type] == :map_grid
      pop_params[:chara_w] = 32
      pop_params[:chara_h] = 32
    end
  end
  #--------------------------------------------------------------------------
  # ● 可以显示pop的tag？
  #--------------------------------------------------------------------------
  def show_pop_tag?
    game_message.pop_tag? && @background == 0 &&
    pop_params[:do] > 0 && pop_params[:do] < 10
  end
  #--------------------------------------------------------------------------
  # ● 重置tag的位图
  #--------------------------------------------------------------------------
  def eagle_reset_pop_tag_bitmap(tag_id = pop_params[:tag])
    @eagle_sprite_pop_tag.bitmap = MESSAGE_EX.windowtag(tag_id)
    w = @eagle_sprite_pop_tag.bitmap.width
    h = @eagle_sprite_pop_tag.bitmap.height
    @eagle_sprite_pop_tag.src_rect.width = w / 3
    @eagle_sprite_pop_tag.src_rect.height = h / 3
  end

  #--------------------------------------------------------------------------
  # ● 设置face参数
  #--------------------------------------------------------------------------
  def face_params; game_message.face_params; end
  def eagle_text_control_face(param = "")
    return if !@flag_draw
    face_params[:ls] = -1 # 设置循环开始编号（+1直至le，再从ls循环）
    face_params[:le] = -1 # 设置循环结束编号
    if param.include?('|')
      params = param.split('|')
      face_params[:name] = params[0]
      param = params[1]
    end
    parse_param(face_params, param, :i)
    reset_eagle_sprite_face
    @eagle_sprite_face.apply_face_params if @eagle_sprite_face
  end
  #--------------------------------------------------------------------------
  # ● 执行facem
  #--------------------------------------------------------------------------
  def eagle_text_control_facem(param = "")
    return if !@flag_draw
    return if @eagle_sprite_face == nil
    params = param.split('|')
    @eagle_sprite_face.motion(params[0], params[1] || "")
  end
  #--------------------------------------------------------------------------
  # ● 移出脸图
  #--------------------------------------------------------------------------
  def eagle_move_out_face
    return if @eagle_sprite_face.nil?
    @eagle_sprite_face.motion(:fade_out)
    MESSAGE_EX.facepool_push(@eagle_sprite_face) # 由精灵池接管
    @eagle_sprite_face = nil
    @eagle_face_w = @eagle_face_h = 0
  end
  #--------------------------------------------------------------------------
  # ● 脸图占用的宽度
  #--------------------------------------------------------------------------
  def eagle_face_width
    return 0 if !game_message.face?
    return 0 if face_params[:z] < 0
    return @eagle_face_w > 0 ? @eagle_face_w + face_params[:dw] : 0
  end
  #--------------------------------------------------------------------------
  # ● 脸图在左侧占用的宽度（用于调整文字区域的左侧起始位置）
  #--------------------------------------------------------------------------
  def eagle_face_left_width
    return 0 if face_params[:dir] # 显示在右侧时
    v = eagle_face_width + face_params[:dx]
    [v, 0].max
  end
  #--------------------------------------------------------------------------
  # ● 脸图在右侧占用的宽度
  #--------------------------------------------------------------------------
  def eagle_face_right_width
    return 0 if !face_params[:dir] # 显示在左侧时
    v = eagle_face_width - face_params[:dx]
    [v, 0].max
  end
  #--------------------------------------------------------------------------
  # ● 脸图占用的高度
  #--------------------------------------------------------------------------
  def eagle_face_height
    @eagle_face_h || 0
  end
  #--------------------------------------------------------------------------
  # ● 保证脸图完全显示在对话框内？
  #--------------------------------------------------------------------------
  def eagle_face_in_window?
    return false if @eagle_sprite_face == nil
    return MESSAGE_EX::FORCE_WIN_H_BIGGER_THAN_DEFAULT_FACE &&
      @eagle_sprite_face.face_default_size?
  end

  #--------------------------------------------------------------------------
  # ● 设置pause参数
  #--------------------------------------------------------------------------
  def pause_params; game_message.pause_params; end
  def eagle_text_control_pause(param = "")
    parse_param(pause_params, param, :id)
    @eagle_sprite_pause.reset if @eagle_sprite_pause
  end
  #--------------------------------------------------------------------------
  # ● 设置wait参数
  #--------------------------------------------------------------------------
  def eagle_text_control_wait(param = '0')
    wait(param.to_i)
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）等待
  #--------------------------------------------------------------------------
  def wait(duration)
    return if !@flag_draw
    # 如果在对话快速显示的中途进行等待，则执行一次绘制后处理，以进行排版等
    eagle_process_draw_update if show_fast?
    duration.times { 
      break if @eagle_force_close
      break if @pause_skip and check_input?
      Fiber.yield
    }
  end
  #--------------------------------------------------------------------------
  # ● 设置auto参数
  #--------------------------------------------------------------------------
  def eagle_text_control_auto(param = '0')
    game_message.auto = param.to_i
  end
  #--------------------------------------------------------------------------
  # ● 执行shake
  #--------------------------------------------------------------------------
  def eagle_text_control_shake(param = '0')
    return if !@flag_draw || @eagle_force_close
    #      power    speed   duration   direction
    h = { :p => 5, :s => 5, :t => 40,  :y => 0 }
    parse_param(h, param, :t)
    shake = 0 # 对话框的偏移值
    shake_direction = 1 # 下一次位移量
    while h[:t] > 0
      delta = (h[:p] * h[:s] * shake_direction) / 10.0
      if h[:t] <= 1 and shake * (shake + delta) < 0
        shake = 0
      else
        shake += delta
      end
      shake_direction = -1 if shake > h[:p] * 2
      shake_direction = 1  if shake < - h[:p] * 2
      h[:t] -= 1
      h[:y] == 0 ? self.x += shake : self.y += shake
      eagle_after_update_xy
      Fiber.yield
    end
  end
  #--------------------------------------------------------------------------
  # ● 执行move指令
  #--------------------------------------------------------------------------
  def eagle_text_control_move(param = '0')
    return if !@flag_draw
    return if win_params[:do] < 0 || game_message.pop?
    init_x = (win_params[:x] || default_init_x)
    init_y = (win_params[:y] || default_init_y)
    h = { :x => nil, :y => nil, :dx => nil, :dy => nil, :t => 20 }
    parse_param(h, param, :t)
    if h[:x] || h[:y] # 直接指定目的地
      r = Rect.new(0, 0, self.width, self.height)
      if h[:x] == nil  # 不变更
        r.x = self.x
      else
        r.x = (h[:x] == 0 ? init_x : h[:x])
        MESSAGE_EX.reset_xy_origin(r, win_params[:o]) # 依据原点修改成实际位置
      end
      # 依靠 @eagle_offset_x 来额外处理位移，避免与现有的移动冲突
      @eagle_offset_x += r.x - self.x
      if h[:y] == nil # 不变更
        r.y = self.y
      else
        r.y = (h[:y] == 0 ? init_y : h[:y])
        MESSAGE_EX.reset_xy_origin(r, win_params[:o])
      end
      @eagle_offset_y += r.y - self.y
    end
    # 指定偏移量
    @eagle_offset_x += h[:dx] if h[:dx]
    @eagle_offset_y += h[:dy] if h[:dy]
    # 执行移动
    eagle_set_wh({ :t => h[:t] })
  end
  #--------------------------------------------------------------------------
  # ● 执行eval指令
  #--------------------------------------------------------------------------
  def eagle_text_control_eval(param = '0')
    return if !@flag_draw
    id_ = param.to_i
    if id_ > 0 && @eagle_evals[id_ - 1]
      s = $game_switches; v = $game_variables; msg = self
      eval( @eagle_evals[id_ - 1] )
    end
  end
  #--------------------------------------------------------------------------
  # ● 设置set参数
  #--------------------------------------------------------------------------
  def eagle_text_control_set(param = '0')
    return if !@flag_draw
    return @eagle_current_set = nil if param == '0'
    @eagle_current_set = param
    @eagle_chara_sets[@eagle_current_set] ||= []
  end
  def eagle_text_control_setm(param = '0')
    return if !@flag_draw
    params = param.split('|') # [set_sym, effect_sym, param]
    if params[2] == "0"
      chara_set(params[0]) { |s| s.finish_effect(params[1].to_sym) }
    else
      chara_set(params[0]) { |s| s.start_effect(params[1].to_sym, params[2]) }
    end
  end
  #--------------------------------------------------------------------------
  # ● 对指定分组内的文字执行block
  #   传入空字符串或 0 时为全部文字
  #--------------------------------------------------------------------------
  def chara_set(set_sym = nil) # block
    if set_sym.nil? || set_sym.empty? || set_sym == 0 || set_sym == '0'
      @eagle_chara_sprites.each { |s| yield(s) }
      return
    end
    return if @eagle_chara_sets[set_sym].nil?
    @eagle_chara_sets[set_sym].each { |s| yield(s) }
  end
  #--------------------------------------------------------------------------
  # ● 获取最后一个文字的精灵
  #--------------------------------------------------------------------------
  def last_chara
    @eagle_chara_sprites[-1]
  end

  #--------------------------------------------------------------------------
  # ● 设置扩展参数
  #--------------------------------------------------------------------------
  def ex_params; game_message.ex_params; end
  #--------------------------------------------------------------------------
  # ● 设置cg参数 / 渐变绘制预定
  #--------------------------------------------------------------------------
  if defined?(Sion_GradientText)
  def eagle_text_control_cg(param = '0')
    ex_params[:cg].clear
    ex_params[:cg] = param if param != '' && param != '0'
  end
  end

  #--------------------------------------------------------------------------
  # ● 输入处理（此处为全部绘制完成后，判定接下来的输入类型）
  #--------------------------------------------------------------------------
  def process_input
    if game_message.choice?
      input_choice
    elsif game_message.num_input?
      input_number
    elsif game_message.item_choice?
      input_item
    elsif input_pause?
      input_pause
    end
    eagle_process_hold
  end
  #--------------------------------------------------------------------------
  # ● 需要输入等待？
  #--------------------------------------------------------------------------
  def input_pause?
    game_message.input_pause? && !@pause_skip
  end
  #--------------------------------------------------------------------------
  # ● 处理输入等待
  #--------------------------------------------------------------------------
  def input_pause
    return if !@flag_draw
    before_input_pause
    eagle_process_draw_update # 统一更新一次
    @eagle_sprite_pause.bind_last_chara(@eagle_chara_sprites[-1])
    @eagle_sprite_pause.show
    @flag_input_pause = true
    self.pause = true unless MESSAGE_EX::NO_DEFAULT_PAUSE
    process_input_pause
    self.pause = false
    @flag_input_pause = false
    @eagle_sprite_pause.hide
  end
  #--------------------------------------------------------------------------
  # ● 输入等待前的操作
  #--------------------------------------------------------------------------
  def before_input_pause
    # 当pause精灵位于句末且紧靠边界时
    #  增加对话框宽度保证它在对话框内部（不可占用padding）
    if pause_params[:v] != 0 && pause_params[:do] <= 0 &&
       input_pause? && eagle_add_w_by_child_window?
      # 最大可用于文字绘制的宽度 eagle_charas_max_w
      # 全部文字实际绘制的宽度 @eagle_charas_w_final
      # 最后一行所需的绘制宽度 @eagle_next_chara_x
      if @eagle_next_chara_x >= @eagle_charas_w_final
        @eagle_sprite_pause_width_add = @eagle_sprite_pause.width
      else
        d = @eagle_charas_w_final - @eagle_next_chara_x
        d -= @eagle_sprite_pause.width
        @eagle_sprite_pause_width_add = -d if d <= 0
      end
    else
      @eagle_sprite_pause_width_add = 0
    end
  end
  #--------------------------------------------------------------------------
  # ● 执行输入等待
  #--------------------------------------------------------------------------
  def process_input_pause
    @eagle_auto_continue_c = game_message.auto || MESSAGE_EX::WIN_AUTO_T
    recreate_contents_for_charas
    ox_max = [self.ox, @eagle_charas_w - @eagle_chara_viewport.rect.width].max
    oy_max = self.oy
    flag_move = ox_max != 0 || oy_max != 0
    self.arrows_visible = true
    d_oxy = 1; last_input = nil; last_input_c = 0
    @flag_input_loop = true
    while @flag_input_loop
      Fiber.yield
      process_input_pause_auto # 处理自动继续
      process_input_pause_key  # 处理按键继续
      if flag_move # 处理内容滚动
        if last_input == Input.dir4  # 先处理变速，防止同时按多个方向，导致速度不对
          last_input_c += 1
          d_oxy += 1 if last_input_c % 10 == 0
        else
          d_oxy = 1
          last_input_c = 0
        end
        last_input = Input.dir4
        _ox = self.ox; _oy = self.oy
        if Input.press?(:UP)
          self.oy -= d_oxy
          self.oy = 0 if self.oy < 0
        elsif Input.press?(:DOWN)
          self.oy += d_oxy
          self.oy = oy_max if self.oy > oy_max
        elsif Input.press?(:LEFT)
          self.ox -= d_oxy
          self.ox = 0 if self.ox < 0
        elsif Input.press?(:RIGHT)
          self.ox += d_oxy
          self.ox = ox_max if self.ox > ox_max
        end
        update_moving_charas_oxy if _ox != self.ox || _oy != self.oy
      elsif MESSAGE_EX::INPUT_NEXT_WITH_DIR4
        @flag_input_loop = false if Input.dir4 > 0
      end
    end
    self.arrows_visible = false
    Fiber.yield
  end
  #--------------------------------------------------------------------------
  # ● 等待按键时，自动继续的处理
  #--------------------------------------------------------------------------
  def process_input_pause_auto
    if game_message.auto == nil # 如果中途关闭了自动对话，则直接隐藏
      @eagle_auto_continue_c = nil
      @eagle_sprite_pause.reset_auto_countdown_position
    end
    if @eagle_auto_continue_c == nil
      @eagle_auto_continue_c = game_message.auto || MESSAGE_EX::WIN_AUTO_T
    end
    if @eagle_auto_continue_c
      return @flag_input_loop = false if @eagle_auto_continue_c <= 0
      process_while_auto_wait_input_pause(@eagle_auto_continue_c)
      @eagle_auto_continue_c -= 1
    end
  end
  #--------------------------------------------------------------------------
  # ● 等待按键时，启用auto时的额外处理
  #  c 为自动继续的剩余帧数，从 game_message.auto 获取总等待帧数
  #--------------------------------------------------------------------------
  def process_while_auto_wait_input_pause(c)
    @eagle_sprite_pause.redraw_auto_countdown(c)
  end
  #--------------------------------------------------------------------------
  # ● 等待按键时，按键继续的处理
  #--------------------------------------------------------------------------
  def process_input_pause_key
    return show(true) if !self.visible and check_input?
    return @flag_input_loop = false if check_input? || @eagle_force_close
  end
  #--------------------------------------------------------------------------
  # ● 检查输入等待的按键
  #--------------------------------------------------------------------------
  def check_input?
    Input.trigger?(:B) || Input.trigger?(:C)
  end
  #--------------------------------------------------------------------------
  # ● 处理选项的输入（覆盖）
  #--------------------------------------------------------------------------
  def input_choice
    input_wait_until_msg_wh(@choice_window)
    input_wait_while_active(@choice_window)
  end
  #--------------------------------------------------------------------------
  # ● 处理数值的输入（覆盖）
  #--------------------------------------------------------------------------
  def input_number
    input_wait_until_msg_wh(@number_window)
    input_wait_while_active(@number_window)
  end
  #--------------------------------------------------------------------------
  # ● 处理物品的选择（覆盖）
  #--------------------------------------------------------------------------
  def input_item
    input_wait_until_msg_wh(@item_window)
    input_wait_while_active(@item_window)
  end
  #--------------------------------------------------------------------------
  # ● 等待对话框宽高处理结束
  #--------------------------------------------------------------------------
  def input_wait_until_msg_wh(child_window)
    child_window.hide.start
    eagle_set_wh if child_window_embed_in? # 执行因子窗口嵌入而变更的窗口大小
    child_window.show.open.activate
  end
  #--------------------------------------------------------------------------
  # ● 并行等待子窗口处理结束
  #--------------------------------------------------------------------------
  def input_wait_while_active(child_window)
    add_w = game_message.child_window_w_des
    add_h = game_message.child_window_h_des
    while child_window.active
      #break child_window.deactivate.close if @eagle_force_close
      @fiber_para.resume if @fiber_para
      if add_w != game_message.child_window_w_des ||
         add_h != game_message.child_window_h_des
        eagle_set_wh # 执行因子窗口嵌入而变更的窗口大小
        add_w = game_message.child_window_w_des
        add_h = game_message.child_window_h_des
      end
      Fiber.yield
    end
    @fiber_para = nil
  end
end # end of class Window_EagleMessage

#=============================================================================
# ○ 对话框拷贝
#=============================================================================
class Window_EagleMessage_Clone < Window_EagleMessage
  attr_accessor :back_bitmap, :back_sprite
  attr_accessor :eagle_chara_viewport
  attr_accessor :eagle_chara_sprites, :eagle_sprite_pop_tag
  attr_accessor :eagle_sprite_face, :eagle_window_name, :eagle_sprite_pause
  attr_accessor :eagle_pop_obj, :flag_hold_id
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize(game_message)
    @game_message = game_message
    super()
    self.openness = 255
    @fin = false # 结束显示？
    @flag_hold_id = nil
  end
  #--------------------------------------------------------------------------
  # ● 获取主参数
  #--------------------------------------------------------------------------
  def game_message; @game_message; end
  #--------------------------------------------------------------------------
  # ● （覆盖）去除组件，这样在赋值前就不用dispose
  #--------------------------------------------------------------------------
  def eagle_message_init_assets; end
  def create_all_windows ; end
  def dispose_all_windows; end
  def update_all_windows ; end
  #--------------------------------------------------------------------------
  # ● （覆盖）判定是否所有窗口已全部关闭
  #--------------------------------------------------------------------------
  def all_close?; close?; end
  #--------------------------------------------------------------------------
  # ○（拷贝对话框专用）已经关闭？
  #--------------------------------------------------------------------------
  def close_clone  ; @fin = true ; end
  def close_clone? ; @fin == true; end
  #--------------------------------------------------------------------------
  # ● 设置xywh
  #--------------------------------------------------------------------------
  def move(x, y, w, h)
    super
    @eagle_win_des_w = w  # 记录该变量，防止nil时 default_init_y 报错
    @eagle_win_des_h = h
    @eagle_last_x    = x  # 设置上次更新的位置，确保 eagle_set_wh 能用
    @eagle_last_y    = y
  end
  #--------------------------------------------------------------------------
  # ○ 记录文本的宽高（用于更新大小）
  #--------------------------------------------------------------------------
  def eagle_set_chara_wh(w, h, w_final, h_final)
    @eagle_charas_w = w
    @eagle_charas_h = h
    @eagle_charas_w_final = w_final
    @eagle_charas_h_final = h_final
  end
  #--------------------------------------------------------------------------
  # ● 重置单页对话框（覆盖，防止过早移出组件）
  #--------------------------------------------------------------------------
  def eagle_message_reset
    @eagle_sprite_pause_width_add = 0 # 拷贝窗口中不存在pause精灵
  end
  #--------------------------------------------------------------------------
  # ● 更新纤程
  #--------------------------------------------------------------------------
  def update_fiber
    if @fiber
      @fiber.resume
    elsif self.openness >= 255 && !@fin
      @fiber = Fiber.new { fiber_main }
      @fiber.resume
    end
  end
  #--------------------------------------------------------------------------
  # ● 处理纤程的主逻辑
  #--------------------------------------------------------------------------
  def fiber_main
    eagle_set_wh( {:open => true} ) # 由于pause精灵需要去除，增加更新宽高
    loop do
      Fiber.yield
      break if @fin
    end
    eagle_process_before_close
    close_and_wait
    @fiber = nil
  end
end
#=============================================================================
# ○ 对话框拷贝 - 用于环境初始化
#=============================================================================
class Window_EagleMessage_CloneEnv < Window_EagleMessage
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize(game_message)
    @game_message = game_message
    super()
    self.openness = 0
  end
  #--------------------------------------------------------------------------
  # ● 获取主参数
  #--------------------------------------------------------------------------
  def game_message;     @game_message;     end
  def game_message=(g); @game_message = g; end
  #--------------------------------------------------------------------------
  # ● （覆盖）去除组件，这样在赋值前就不用dispose
  #--------------------------------------------------------------------------
  def eagle_message_init_assets; end
  def create_all_windows ; end
  def dispose_all_windows; end
  def update_all_windows ; end
  #--------------------------------------------------------------------------
  # ● 设置game_message
  #  本质上为全部绘制一次（但不真实绘制）
  #  空方法为去除对组件的设置
  #--------------------------------------------------------------------------
  def set_game_message(game_message, text)
    @game_message = game_message
    text_ = text.clone
    text_ = convert_escape_characters(text_)
    pos_  = { :x => 0, :y => 0, :new_x => 0, :height => 0}
    @flag_draw = false
    process_character(text_.slice!(0, 1), text_, pos_) until text_.empty?
  end
  #--------------------------------------------------------------------------
  # ● （覆盖）去除部分不必要的方法
  #--------------------------------------------------------------------------
  def eagle_message_reset; end
  def eagle_reset_z; end
  def update; end
  def eagle_process_draw_end(c_w, c_h, pos); end
  def show_pop_tag?; false; end
end

#=============================================================================
# ○ 金钱框窗口
#=============================================================================
class Window_EagleMsgGold < Window_Gold
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize(window_msg)
    bind_window(window_msg)
    super()
    self.x = Graphics.width - self.width
    self.y = 0
    self.openness = 0
  end
  def bind_window(window); @window_msg = window; end
end

#=============================================================================
# ○ 姓名框窗口
#=============================================================================
class Window_EagleMsgName < Window_Base
  attr_reader  :rect_real
  #--------------------------------------------------------------------------
  # ● 获取文字颜色
  #     n : 文字颜色编号（0..31）
  #--------------------------------------------------------------------------
  def text_color(n); MESSAGE_EX.text_color(n, self.windowskin); end
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize(window_msg)
    bind_window(window_msg)
    super(0, 0, 32, 32)
    self.visible = false # 从 opacity=0 修改为 visible，确保背景框不会闪现
    @back_sprite = Sprite.new
    @flag_use_back_sprite = false
    @params = {}
    # 在背景图片的影响下，姓名框四个方向的增加量
    @rect_real = Rect.new(0, 0, 0, 0)
  end
  def bind_window(window); @window_msg = window; end
  def name_params; @window_msg.name_params; end
  #--------------------------------------------------------------------------
  # ● 释放对象
  #--------------------------------------------------------------------------
  def dispose
    @back_sprite.bitmap.dispose if @back_sprite.bitmap
    @back_sprite.dispose
    super
  end
  #--------------------------------------------------------------------------
  # ● 获取行高
  #--------------------------------------------------------------------------
  def line_height; name_params[:size] || Font.default_size; end
  #--------------------------------------------------------------------------
  # ● 姓名没有变化？
  #--------------------------------------------------------------------------
  def no_change?
    @params[:name] == name_params[:name]
  end
  #--------------------------------------------------------------------------
  # ● 开始
  #--------------------------------------------------------------------------
  def start
    if @flag_use_back_sprite 
      # 显示背景图片时，隐藏默认窗口皮肤
      @back_sprite.visible = true
      self.opacity = 0
      self.back_opacity = 0
    else
      @back_sprite.visible = false
      self.opacity = name_params[:opa]
      self.back_opacity = name_params[:opa]
      if name_params[:do] == 0  # 嵌入时，隐藏背景框
        self.opacity = 0
        self.back_opacity = 0
      end
    end
    self.contents_opacity = 255
    self.show.open
  end
  #--------------------------------------------------------------------------
  # ● 重置
  #--------------------------------------------------------------------------
  def reset
    return close if name_params[:name] == ""
    skin = @window_msg.get_cur_windowskin_index(name_params[:skin])
    self.windowskin = MESSAGE_EX.windowskin(skin)
    #return if open? && no_change?
    @params[:name] = name_params[:name]
    reset_size(name_params[:name])
    redraw(name_params[:name])
    if name_params[:bg] && eagle_draw_bg_pic(self.width, self.height)
      @flag_use_back_sprite = true
      @back_sprite.z = self.z - 1
      @back_sprite.visible = false # 在更新前，先确保背景图片不显示
    else
      @flag_use_back_sprite = false
    end
    reset_rect_real
    #open # 等待对话框中调用 start 方法来显示姓名框
  end
  #--------------------------------------------------------------------------
  # ● 重设窗口大小
  #--------------------------------------------------------------------------
  def reset_size(t)
    reset_font_settings
    w, h = MESSAGE_EX.calculate_text_wh(contents, t)
    w = w + name_params[:cx] + standard_padding * 2
    h = [h, contents.font.size].max + name_params[:cy] + standard_padding * 2
    move(0, 0, w, h)
    create_contents
  end
  #--------------------------------------------------------------------------
  # ● 重绘
  #--------------------------------------------------------------------------
  def redraw(t)
    change_color(text_color(@window_msg.font_params[:c]))
    MESSAGE_EX.apply_font_params(contents.font, @window_msg.font_params)
    draw_text_ex(name_params[:cx], name_params[:cy], t)
  end
  #--------------------------------------------------------------------------
  # ● 重置字体设置
  #--------------------------------------------------------------------------
  def reset_font_settings
    change_color(normal_color)
    contents.font.size = name_params[:size] || Font.default_size
  end
  #--------------------------------------------------------------------------
  # ● 获取控制符的参数（这个方法会破坏原始数据）
  #--------------------------------------------------------------------------
  def obtain_escape_param_string(text)
    text.slice!(/^\[[\|\$\-\d\w]+\]/)[1..-2] rescue ""
  end
  #--------------------------------------------------------------------------
  # ● 控制符的处理
  #     code : 控制符的实际形式（比如“\C[1]”是“C”）
  #     text : 绘制处理中的字符串缓存（字符串可能会被修改）
  #     pos  : 绘制位置 {:x, :y, :new_x, :height}
  #--------------------------------------------------------------------------
  def process_escape_character(code, text, pos)
    if code.upcase == 'C'
      change_color(text_color(obtain_escape_param_string(text)))
      return
    end
    super(code, text, pos)
  end
  #--------------------------------------------------------------------------
  # ● 绘制背景图片
  #--------------------------------------------------------------------------
  def eagle_draw_bg_pic(w, h)
    _bitmap = MESSAGE_EX.namebg(name_params[:bg], w, h)
    if _bitmap != nil
      @back_sprite.bitmap = _bitmap
      return true
    end
    return false
  end
  #--------------------------------------------------------------------------
  # ● 计算四方向上的增量（因为背景图片可能大于文字区域）
  #--------------------------------------------------------------------------
  def reset_rect_real
    if @flag_use_back_sprite
      update_back_sprite
      xw = self.x + standard_padding; ww = self.width - standard_padding * 2
      yw = self.y + standard_padding; hw = self.height - standard_padding * 2
      xp = @back_sprite.x - @back_sprite.ox
      yp = @back_sprite.y - @back_sprite.oy
      @rect_real.x = 0
      @rect_real.x = xw - xp if xp < xw
      @rect_real.y = 0
      @rect_real.y = yw - yp if yp < yw
      t = xp + @back_sprite.width - xw - ww
      @rect_real.width = 0
      @rect_real.width = t if t > 0
      t = yp + @back_sprite.height - yw - hw
      @rect_real.height = 0
      @rect_real.height = t if t > 0
    else
      @rect_real = Rect.new(0, 0, 0, 0)
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新（在 eagle_win_update 中调用）
  #--------------------------------------------------------------------------
  def update_with_msg
    update_position
    update_back_sprite if @flag_use_back_sprite
  end
  #--------------------------------------------------------------------------
  # ● 更新位置
  #  尽管已经更新了姓名框位置，但保留此处用于扩展
  #--------------------------------------------------------------------------
  def update_position
  end
  #--------------------------------------------------------------------------
  # ● 更新背景精灵
  #--------------------------------------------------------------------------
  def update_back_sprite
    MESSAGE_EX.reset_xy_dorigin(@back_sprite, self, name_params[:bgo])
    MESSAGE_EX.reset_sprite_oxy(@back_sprite, name_params[:bgo])
    @back_sprite.z = self.z - 1
  end
  #--------------------------------------------------------------------------
  # ● 显示
  #--------------------------------------------------------------------------
  def show
    @back_sprite.visible = true if @flag_use_back_sprite
    super
  end
  #--------------------------------------------------------------------------
  # ● 隐藏
  #--------------------------------------------------------------------------
  def hide
    @back_sprite.visible = false if @flag_use_back_sprite
    super
  end
  #--------------------------------------------------------------------------
  # ● 更新（每帧调用）
  #--------------------------------------------------------------------------
  def update
    super
    @back_sprite.opacity = get_back_sprite_opacity if @flag_use_back_sprite
  end
  #--------------------------------------------------------------------------
  # ● 更新背景图片的透明度
  #--------------------------------------------------------------------------
  def get_back_sprite_opacity
    return 0 if self.visible == false
    return 0 if self.contents_opacity == 0
    return self.openness
  end
end

#=============================================================================
# ○ 等待按键的精灵
#=============================================================================
class Sprite_EaglePauseTag < Sprite
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize(window_bind)
    super(nil)
    bind_window(window_bind)
    @type_source = 0 # 记录当前源位图的类型（见module中对应【设置】）
    @type_pos = 0 # 记录当前相对于对话框的位置类型
    @last_chara = nil
    @last_pause_index = ""
    init_auto_countdown
    reset
    hide
  end
  def bind_window(window_bind); @window_bind = window_bind; end
  def params; @window_bind.pause_params; end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    @sprite_auto.bitmap.dispose if @sprite_auto.bitmap
    @sprite_auto.dispose
    @s_bitmap.dispose
    self.bitmap.dispose
    super
  end
  #--------------------------------------------------------------------------
  # ● 绑定文末精灵
  #--------------------------------------------------------------------------
  def bind_last_chara(sprite_chara)
    @last_chara = sprite_chara
    reset_position
  end
  #--------------------------------------------------------------------------
  # ● 重置
  #--------------------------------------------------------------------------
  def reset
    reset_source if @last_pause_index != params[:id]
    reset_bitmap
  end
  #--------------------------------------------------------------------------
  # ● 重置源位图
  #--------------------------------------------------------------------------
  def reset_source
    @s_bitmap.dispose if @s_bitmap
    @last_pause_index = params[:id]
    params[:v] = @last_pause_index == -1 ? 0 :1
    
    _params = MESSAGE_EX.pause_params(@last_pause_index)
    if _params[0].nil?
      _bitmap = @window_bind.windowskin
    else
      _bitmap = Cache.system(_params[0])
    end
    _rect = _params[1].nil? ? _bitmap.rect : _params[1]
    @s_bitmap_row = _params[2] # 源位图中一行中帧数目
    @s_bitmap_col = _params[3] # 源位图中一列中帧数目
    @s_bitmap_n = @s_bitmap_row * @s_bitmap_col # 总帧数

    @s_bitmap = Bitmap.new(_rect.width, _rect.height)
    @s_bitmap.blt(0, 0, _bitmap, _rect)
    @s_rect = Rect.new(0, 0, @s_bitmap.width / @s_bitmap_row,
      @s_bitmap.height / @s_bitmap_col)

    self.bitmap.dispose if self.bitmap
    self.bitmap = Bitmap.new(@s_rect.width, @s_rect.height)
    @index = 0 # 当前index
  end
  #--------------------------------------------------------------------------
  # ● 重绘位图
  #--------------------------------------------------------------------------
  def reset_bitmap
    self.bitmap.clear
    @s_rect.x = (@index % @s_bitmap_row) * @s_rect.width
    @s_rect.y = (@index / @s_bitmap_row) * @s_rect.height
    self.bitmap.blt(0, 0, @s_bitmap, @s_rect)
    @count = 0
  end
  #--------------------------------------------------------------------------
  # ● 更新位置
  #--------------------------------------------------------------------------
  def reset_position
    self.viewport = nil
    if params[:do] > 0
      MESSAGE_EX.reset_xy_dorigin(self, @window_bind, params[:do])
    elsif @last_chara
      self.viewport = @window_bind.eagle_chara_viewport
      self.x = @last_chara._x + @last_chara.width - @window_bind.eagle_charas_ox
      self.y = @last_chara._y + @last_chara.height/2 - @window_bind.eagle_charas_oy
    else
      self.x = @window_bind.eagle_charas_x0
      self.y = @window_bind.eagle_charas_y0
    end
    self.x += params[:dx]
    self.y += params[:dy]
    MESSAGE_EX.reset_xy_origin(self, params[:o])
    reset_auto_countdown_position
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
    update_index
    reset_position if self.viewport && @last_chara
  end
  #--------------------------------------------------------------------------
  # ● 更新帧动画
  #--------------------------------------------------------------------------
  def update_index
    return if (@count += 1) < params[:t]
    @index = (@index + 1) % @s_bitmap_n
    reset_bitmap
  end
  #--------------------------------------------------------------------------
  # ● 显示
  #--------------------------------------------------------------------------
  def show
    return if params[:v] == 0
    reset_position
    self.visible = true
    self
  end
  #--------------------------------------------------------------------------
  # ● 隐藏
  #--------------------------------------------------------------------------
  def hide
    @sprite_auto.visible = false
    self.visible = false
    self
  end
  #--------------------------------------------------------------------------
  # ● 初始化自动倒计时
  #--------------------------------------------------------------------------
  def init_auto_countdown
    @sprite_auto = Sprite.new
    @sprite_auto.bitmap = Bitmap.new(MESSAGE_EX::WIN_AUTO_W,
      MESSAGE_EX::WIN_AUTO_H)
    @sprite_auto.bitmap.font.color = MESSAGE_EX::WIN_AUTO_TEXT_COLOR1
    @sprite_auto.bitmap.font.shadow = false
    @sprite_auto.bitmap.font.outline = false
    # 用于复制的白色文字
    @auto_temp_bitmap = Bitmap.new(@sprite_auto.width, @sprite_auto.height)
    @auto_temp_bitmap.font.color = MESSAGE_EX::WIN_AUTO_TEXT_COLOR2
    @auto_temp_bitmap.font.shadow = false
    @auto_temp_bitmap.font.outline = false
    t = MESSAGE_EX::WIN_AUTO_TEXT
    @auto_temp_bitmap.draw_text(0, 0, @sprite_auto.width, @sprite_auto.height, t, 1)
  end
  #--------------------------------------------------------------------------
  # ● 重置自动倒计时的位置
  #--------------------------------------------------------------------------
  def reset_auto_countdown_position
    MESSAGE_EX.reset_sprite_oxy(@sprite_auto, MESSAGE_EX::WIN_AUTO_O)
    MESSAGE_EX.reset_xy_dorigin(@sprite_auto, @window_bind, MESSAGE_EX::WIN_AUTO_DO)
    @sprite_auto.x += MESSAGE_EX::WIN_AUTO_DX
    @sprite_auto.y += MESSAGE_EX::WIN_AUTO_DY
    @sprite_auto.z = self.z + 1
    @sprite_auto.bitmap.clear
    @sprite_auto.visible = @window_bind.openness > 0 && @window_bind.game_message.auto != nil
  end
  #--------------------------------------------------------------------------
  # ● 重绘自动倒计时
  #--------------------------------------------------------------------------
  def redraw_auto_countdown(cd)
    count_rate = cd * 1.0 / @window_bind.game_message.auto
    b = @sprite_auto.bitmap
    b.clear
    b.fill_rect(0, 0, b.width, b.height, MESSAGE_EX::WIN_AUTO_BG_COLOR1)
    _x = (b.width-2) * (1-count_rate)
    r = Rect.new(1+_x, 1, b.width-2-_x, b.height-2)
    b.fill_rect(r, MESSAGE_EX::WIN_AUTO_BG_COLOR2)
    # 绘制黑色文字
    t = MESSAGE_EX::WIN_AUTO_TEXT
    b.draw_text(0, 0, b.width, b.height, t, 1)
    # 绘制白色文字
    r2 = Rect.new(_x, 0, b.width, b.height)
    b.blt(_x, 0, @auto_temp_bitmap, r2)
  end
end

#==============================================================================
# ○ 精灵池（更新需要延迟消失的精灵）
#==============================================================================
module MESSAGE_EX
  #--------------------------------------------------------------------------
  # ● 定义全局数组
  #--------------------------------------------------------------------------
  @pool_charas = [] # 文字精灵池
  @pool_faces  = [] # 脸图精灵池
  def self.get_pool(type)
    return @pool_charas if type == :chara
    return @pool_faces  if type == :face
  end
  def self.all_pools
    [:chara, :face]
  end
  #--------------------------------------------------------------------------
  # ● 重置
  #--------------------------------------------------------------------------
  def self.pools_reset
    all_pools.each do |type|
      get_pool(type).each { |s| s.dispose }
      get_pool(type).clear
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def self.pools_update
    all_pools.each do |type|
      get_pool(type).each { |s| s.update if !s.disposed? && !s.finish? }
    end
  end
  #--------------------------------------------------------------------------
  # ● 从指定池子中取出一个可用的精灵（失败则返回nil）
  #--------------------------------------------------------------------------
  def self.pool_new(type)
    while true
      s = get_pool(type).shift
      return nil if s.nil?
      next if s.disposed?
      if !s.finish?
        get_pool(type).unshift(s)
        return nil
      end
      return s
    end
  end
  #--------------------------------------------------------------------------
  # ● 将指定精灵放入指定池子
  # 【注】精灵需要存在 finish? 方法，该方法返回 true 代表可以被重置复用
  #      返回 false 代表需要继续 update
  #--------------------------------------------------------------------------
  def self.pool_push(type, s)
    return if s.disposed?
    return get_pool(type).unshift(s) if s.finish?
    get_pool(type).push(s)
  end
  #--------------------------------------------------------------------------
  # ● 对文字精灵池的操作
  #--------------------------------------------------------------------------
  def self.charapool_push(s)
    pool_push(:chara, s)
  end
  def self.charapool_new(window, font, x,y,w,h, viewport)
    s = pool_new(:chara)
    return Sprite_EagleCharacter.new(window, font, x,y,w,h, viewport) if s.nil?
    s.bind_viewport(viewport)
    s.bind_window(window)
    s.bind_font(font)
    s.reset(x,y,w,h)
    s
  end
  #--------------------------------------------------------------------------
  # ● 对脸图精灵池的操作
  #--------------------------------------------------------------------------
  def self.facepool_push(s)
    pool_push(:face, s)
  end
  def self.facepool_new
    s = pool_new(:face)
    return Sprite_EagleFace.new if s.nil?
    s
  end
end
#=============================================================================
# ○ Scene_Base
#=============================================================================
class Scene_Base
  #--------------------------------------------------------------------------
  # ● 开始处理
  #--------------------------------------------------------------------------
  alias eagle_message_pool_start start
  def start
    MESSAGE_EX.pools_reset
    eagle_message_pool_start
  end
  #--------------------------------------------------------------------------
  # ● 更新画面（基础）
  #--------------------------------------------------------------------------
  alias eagle_message_pool_update_basic update_basic
  def update_basic
    eagle_message_pool_update_basic
    MESSAGE_EX.pools_update
  end
  #--------------------------------------------------------------------------
  # ● 结束处理
  #--------------------------------------------------------------------------
  alias eagle_message_pool_terminate terminate
  def terminate
    eagle_message_pool_terminate
    MESSAGE_EX.pools_reset
  end
end

#=============================================================================
# ○ 脸图精灵
#=============================================================================
class Sprite_EagleFace < Sprite
  attr_accessor :opa
  #--------------------------------------------------------------------------
  # ● 绑定
  #--------------------------------------------------------------------------
  def bind_window(w); @window = w; end
  def face_params; @window.face_params; end
  #--------------------------------------------------------------------------
  # ● 已经结束使用？
  #--------------------------------------------------------------------------
  def finish?
    @flag_fin == true
  end
  #--------------------------------------------------------------------------
  # ● 初始化/重置
  #--------------------------------------------------------------------------
  def reset(window)
    bind_window(window)
    init_params
    apply_face_bitmap
    apply_face_params
  end
  #--------------------------------------------------------------------------
  # ● 初始化参数
  #--------------------------------------------------------------------------
  def init_params
    @params = {}   # 自用参数组
    @flag_fin = false  # 可复用的标志
    @fiber = nil # 移动用 fiber
    @fiber_tmp = nil # 若fiber未执行完，则只预存一个 fiber
    # 为了更好的扩展性，不直接使用默认属性，而是利用中间变量去赋值
    @x0 = @y0 = 0 # 因绑定对话框而获得的基础坐标
    @x1 = @y1 = 0 # 因为移动而增加的偏移
    @opa = 0 # 不透明度
  end
  #--------------------------------------------------------------------------
  # ● 脸图未更改？
  #--------------------------------------------------------------------------
  def no_change?
    self.bitmap && !self.bitmap.disposed? &&
    @params[:name] == face_params[:name] && 
    @params[:i] == face_params[:i] 
  end
  #--------------------------------------------------------------------------
  # ● 设置脸图文件
  #--------------------------------------------------------------------------
  def apply_face_bitmap
    @params[:name] = face_params[:name]
    self.bitmap = Cache.face(@params[:name])
    @params[:name] =~ /_(\d+)x(\d+)_?/i  # 从文件名获取行数和列数（默认为2行4列）
    @params[:num_line] = $1 ? $1.to_i : face_default_line
    @params[:num_col] = $2 ? $2.to_i : face_default_col
    @params[:num] = @params[:num_line] * @params[:num_col]
    @params[:sole_w] = self.bitmap.width / @params[:num_col]
    @params[:sole_h] = self.bitmap.height / @params[:num_line]
    # 传出脸图宽高，用于对话框中的文字位移
    @window.eagle_face_w = @params[:sole_w]
    @window.eagle_face_h = @params[:sole_h]
    # 脸图以底部中心为显示原点
    self.ox = @params[:sole_w] / 2
    self.oy = @params[:sole_h]
  end
  #--------------------------------------------------------------------------
  # ● 脸图默认规格（行和列）
  #--------------------------------------------------------------------------
  def face_default_line; 2; end
  def face_default_col;  4; end
  #--------------------------------------------------------------------------
  # ● 默认大小的脸图？
  #--------------------------------------------------------------------------
  def face_default_size?
    @params[:sole_w] == 96 && @params[:sole_h] == 96
  end
  #--------------------------------------------------------------------------
  # ● 导入face参数
  #--------------------------------------------------------------------------
  def apply_face_params
    # 移入移出的参数
    @params[:it] = face_params[:it]
    @params[:ot] = face_params[:ot]

    # 判断是否需要循环的flag
    @params[:flag_l] = (face_params[:ls] > -1 && face_params[:le] > face_params[:ls])
    @params[:ls] = face_params[:ls]
    @params[:lt] = face_params[:lt]
    @params[:lw] = face_params[:lw]
    @params[:li_c] = face_params[:ls] # 循环用index计数
    @params[:lt_c] = face_params[:lt] # 循环用time计数
    @params[:lw_c] = face_params[:lw] # 循环后wait计数

    @params[:i] = face_params[:i]
    apply_index
  end
  #--------------------------------------------------------------------------
  # ● 应用当前帧
  #--------------------------------------------------------------------------
  def apply_index
    return if @params[:i] == nil
    @params[:i] = 0 if @params[:i] >= @params[:num]
    w = @params[:sole_w]
    h = @params[:sole_h]
    x = @params[:i] % @params[:num_col] * w
    y = @params[:i] / @params[:num_col] * h
    rect = Rect.new(x, y, w, h)
    self.src_rect = rect
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
    @fiber.resume if @fiber
    update_position
    update_pattern
  end
  #--------------------------------------------------------------------------
  # ● 更新位置
  #--------------------------------------------------------------------------
  def update_position
    if @window
      if face_params[:dir] # 脸图放置于右侧时
        @x0 = @window.x + @window.width - @window.standard_padding - self.ox
      else # 脸图放置于左侧时
        @x0 = @window.x + @window.standard_padding + self.ox
      end
      @x0 += face_params[:dx]
      # 如果脸图高度小于对话框，居中显示，否则底部对齐
      if @params[:sole_h] < @window.height - 2*@window.standard_padding
        dh = (@window.height-2*@window.standard_padding - @params[:sole_h])/2
        @y0 = @window.y + @window.standard_padding + dh + @params[:sole_h]
      else # 因为脸图是底部中点为原点，可以直接底部对齐
        @y0 = @window.y + @window.height - @window.standard_padding
      end
      @y0 += face_params[:dy]
      self.mirror = face_params[:m]
      self.z = @window.z + face_params[:z]
    end
    self.x = @x0 + @x1
    self.y = @y0 + @y1
    self.opacity = @opa
  end
  #--------------------------------------------------------------------------
  # ● 更新自动播放
  #--------------------------------------------------------------------------
  def update_pattern
    if @params[:flag_l]
      if @params[:li_c] >= @params[:le]
        # 每次loop之间的等待
        return if @params[:lw].nil?
        @params[:lw_c] -= 1
        return if @params[:lw_c] > 0
        @params[:lw_c] = @params[:lw]
        @params[:li_c] = @params[:ls]
      else
        # 每帧之间的等待
        @params[:lt_c] -= 1
        return if @params[:lt_c] > 0
        @params[:lt_c] = @params[:lt]
        @params[:li_c] += 1
      end
      @params[:i] = @params[:li_c]
      apply_index
    end
  end
  #--------------------------------------------------------------------------
  # ● 执行动作
  #--------------------------------------------------------------------------
  def motion(type, param_str = "")
    m_c = ("fiber_#{type}").to_sym
    if respond_to?(m_c)
      @fiber = nil if type == :fade_out
      if @fiber
        @fiber_tmp = Fiber.new { fiber_main(m_c, param_str) }
      else
        @fiber = Fiber.new { fiber_main(m_c, param_str) }
      end
    else
      p "对话框中 \\facem 转义符，指令 #{type} 无效！请检查指令名称及其大小写！"
    end
  end
  #--------------------------------------------------------------------------
  # ● Fiber主逻辑
  #--------------------------------------------------------------------------
  def fiber_main(m_c, param_str)
    method(m_c).call(param_str)
    @fiber = nil
    @fiber = @fiber_tmp if @fiber_tmp
    @fiber_tmp = nil
  end
  #--------------------------------------------------------------------------
  # ● 动作：淡入
  #--------------------------------------------------------------------------
  def fiber_fade_in(param_str = "")
    v = 255.0 / @params[:it]
    while(@opa < 255)
      @opa += v
      yield self if block_given?
      Fiber.yield
    end
  end
  def fiber_in(param_str = "")
    h = {}
    MESSAGE_EX.parse_param(h, param_str, :it)
    @params[:it] = h[:it] if h[:it]
    fiber_fade_in(param_str)
  end
  #--------------------------------------------------------------------------
  # ● 动作：淡出
  #--------------------------------------------------------------------------
  def fiber_fade_out(param_str = "")
    bind_window(nil)
    v = 255.0 / @params[:ot]
    while(@opa > 0)
      @opa -= v
      yield self if block_given?
      Fiber.yield
    end
    @flag_fin = true
  end
  def fiber_out(param_str = "")
    h = {}
    MESSAGE_EX.parse_param(h, param_str, :ot)
    @params[:ot] = h[:ot] if h[:ot]
    fiber_fade_out(param_str)
  end
  #--------------------------------------------------------------------------
  # ● 动作：跳跃
  #--------------------------------------------------------------------------
  def fiber_jump(param_str = "")
    t = 0
    while t <= 10
      @y1 = (t-5)**2 * 40 * 1.0/25 - 40
      yield self if block_given?
      Fiber.yield
      t += 1
    end
  end
  #--------------------------------------------------------------------------
  # ● 动作：移动
  #--------------------------------------------------------------------------
  def fiber_move(param_str = "")
    h = { :x => nil, :y => nil, :dx => nil, :dy => nil, :t => 30 }
    MESSAGE_EX.parse_param(h, param_str, :t)

    init_x1 = @x1
    des_x = init_x1
    des_x = init_x1 + h[:dx] if h[:dx]
    des_x = h[:x] if h[:x]
    init_y1 = @y1
    des_y = init_y1
    des_y = init_y1 + h[:dy] if h[:dy]
    des_y = h[:y] if h[:y]
    return if init_x1 == des_x && init_y1 == des_y
    d_x = des_x - init_x1
    d_y = des_y - init_y1

    _i = 0; _t = h[:t]
    while(true)
      break if _i > _t
      per = _i * 1.0 / _t
      per = (_i == _t ? 1 : MESSAGE_EX.ease_value(:face_xy, per))
      @x1 = (init_x1 + d_x * per).round
      @y1 = (init_y1 + d_y * per).round
      yield self if block_given?
      Fiber.yield
      _i += 1
    end
  end
end

#=============================================================================
# ○ 文字绘制类
#=============================================================================
class Font_EagleCharacter
  attr_reader   :text  # 绘制的文本
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(font_params)
    @params = font_params.dup
    @text = ""
  end
  #--------------------------------------------------------------------------
  # ● 设置参数
  #--------------------------------------------------------------------------
  def set_param(sym, value)
    @params[sym] = value
  end
  #--------------------------------------------------------------------------
  # ● 获取文字颜色
  #     n : 文字颜色编号（0..31）
  #--------------------------------------------------------------------------
  def text_color(n)
    MESSAGE_EX.text_color(n, MESSAGE_EX.windowskin(@params[:skin]))
  end
  #--------------------------------------------------------------------------
  # ● 获取渐变色数组
  #--------------------------------------------------------------------------
  def get_gradient_color(str)
    result = []
    param = str.downcase
    while(param != "")
      param.slice!(/\D+/)
      result.push((param.slice!(/\d+/)).to_i)
    end
    result
  end
  #--------------------------------------------------------------------------
  # ● 执行文字绘制
  #--------------------------------------------------------------------------
  def draw(bitmap, x, y, w, h, c, ali = 0)
    @text = c
    bitmap.font.color = text_color(@params[:c])
    MESSAGE_EX.apply_font_params(bitmap.font, @params)

    draw_param_p(bitmap, x, y, w, h) if @params[:p]
    draw_param_l(bitmap, x, y, w, h, c, ali) if @params[:l]
    if defined?(Sion_GradientText) && @params[:ex_cg] && @params[:ex_cg] != ''
      grad_cs = get_gradient_color(@params[:ex_cg])
      Sion_GradientText.draw_text(bitmap,x,y,w*2,h,c,ali,grad_cs)
    else
      bitmap.draw_text(x, y, w*2, h, c, ali)
    end
    draw_param_m(bitmap, x, y, w, h) if @params[:m]
    draw_param_k(bitmap, x, y, w, h) if @params[:k]
    draw_param_d(bitmap) if @params[:d]
    draw_param_u(bitmap) if @params[:u]
  end
  #--------------------------------------------------------------------------
  # ● 执行图标绘制
  #--------------------------------------------------------------------------
  def draw_icon(bitmap, x, y, icon_index)
    draw_param_p(bitmap, x, y, 24, 24) if @params[:p]
    draw_param_l_rect(bitmap, x, y, 24, 24) if @params[:l]
    _bitmap = Cache.system("Iconset")
    rect = Rect.new(icon_index % 16 * 24, icon_index / 16 * 24, 24, 24)
    bitmap.blt(x, y, _bitmap, rect, 255)
    draw_param_m(bitmap, x, y, 24, 24) if @params[:m]
    draw_param_k(bitmap, x, y, 24, 24) if @params[:k]
    draw_param_d(bitmap) if @params[:d]
    draw_param_u(bitmap) if @params[:u]
  end
  #--------------------------------------------------------------------------
  # ● 绘制底纹
  #--------------------------------------------------------------------------
  def draw_param_p(bitmap, x, y, w, h)
    color = text_color(@params[:pc])
    case @params[:p]
    when 1 # 边框
      bitmap.fill_rect(x, y, w, h, color)
      bitmap.clear_rect(x+1, y+1, w-2, h-2)
    when 2 # 纯色方块
      bitmap.fill_rect(x, y, w, h, color)
    end
  end
  #--------------------------------------------------------------------------
  # ● 绘制外发光
  #--------------------------------------------------------------------------
  def draw_param_l(bitmap, x, y, w, h, c, ali)
    bitmap.font.outline = false
    bitmap.font.shadow = false
    color = bitmap.font.color.dup
    bitmap.font.color = text_color(@params[:lc])
    @params[:lp].times do
      bitmap.draw_text(x, y, w+4, h, c, ali)
      bitmap.blur
    end
    bitmap.font.color = color
  end
  def draw_param_l_rect(bitmap, x, y, w, h)
    c = text_color(@params[:lc])
    bitmap.fill_rect(x, y, w, h, c)
    bitmap.blur
  end
  #--------------------------------------------------------------------------
  # ● 绘制删除线
  #--------------------------------------------------------------------------
  def draw_param_d(bitmap)
    c = text_color(@params[:dc])
    bitmap.fill_rect(0, bitmap.height/2 - 1, bitmap.width, 1, c)
  end
  #--------------------------------------------------------------------------
  # ● 绘制下划线
  #--------------------------------------------------------------------------
  def draw_param_u(bitmap)
    c = text_color(@params[:uc])
    bitmap.fill_rect(0, bitmap.height - 1, bitmap.width, 1, c)
  end
  #--------------------------------------------------------------------------
  # ● 绘制叠加文字
  #--------------------------------------------------------------------------
  def draw_param_m(bitmap, x, y, w, h)
    color = bitmap.font.color.dup
    bitmap.font.color = text_color(@params[:mc]) if @params[:mc] >= 0
    @params[:m].each do |c|
      if c.is_a?(Integer)
        _bitmap = Cache.system("Iconset")
        rect = Rect.new(c % 16 * 24, c / 16 * 24, 24, 24)
        bitmap.blt(x+w/2-12, y+h/2-12, _bitmap, rect, 255)
      else
        bitmap.draw_text(x, y, w, h, c, 1)
      end
    end
    bitmap.font.color = color
  end
  #--------------------------------------------------------------------------
  # ● 文字破碎
  #--------------------------------------------------------------------------
  def draw_param_k(bitmap, x, y, w, h)
    v = @params[:kv]
    if v >= 100
      bitmap.clear_rect(x, y, w, h)
      return
    end
    for xi in x...(x + w)
      for yi in y...(y + h)
        c = bitmap.get_pixel(xi, yi)
        next if c.alpha == 0
        bitmap.set_pixel(xi, yi, Color.new(255,255,255, 0)) if rand(100) < v
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 执行图片绘制
  #--------------------------------------------------------------------------
  def draw_pic(bitmap, pic_bitmap, h)
    bitmap.stretch_blt(bitmap.rect, pic_bitmap, pic_bitmap.rect, h[:opa])
  end
end
#=============================================================================
# ○ 单个文字的精灵
#=============================================================================
class Sprite_EagleCharacter < Sprite
  attr_reader :origin_x, :origin_y, :_x, :_y, :eagle_font
  attr_accessor :flag_update_pos
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #  window_bind ：所绑定的显示窗口，需要有以下方法
  #    .z 返回窗口的z值（当前文字精灵将高于该值）
  #    .eagle_charas_x0 .eagle_charas_y0 返回文字显示区域的左上角坐标（屏幕坐标）
  #    .eagle_charas_ox .eagle_charas_oy 返回文字显示区域的显示原点（文字区域坐标）
  #    .eagle_charas_max_h 返回文字区域的最大高度
  #  font_bind ：所绑定的字符绘制类 Font_EagleCharacter 的对象
  #--------------------------------------------------------------------------
  def initialize(window_bind, font_bind, x, y, w, h, viewport = nil)
    super(viewport)
    bind_viewport(viewport)
    bind_window(window_bind)
    bind_font(font_bind)
    reset(x, y, w, h)
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    self.bitmap.dispose if !self.bitmap.disposed?
    super
  end
  #--------------------------------------------------------------------------
  # ● 获取文字在屏幕上的碰撞矩形（计算了绑定的viewport的位置）
  #--------------------------------------------------------------------------
  def screen_rect
    r = Rect.new(self.x - self.ox, self.y - self.oy, self.width, self.height)
    if self.viewport
      r.x += self.viewport.rect.x
      r.y += self.viewport.rect.y
    end
    r
  end
  #--------------------------------------------------------------------------
  # ● 文字中心点是否在视图内部？
  #--------------------------------------------------------------------------
  def in_viewport?
    return true if self.viewport.nil?
    lux = self.x; luy = self.y
    rdx = lux + self.width; rdy = luy + self.height
    return false if lux < 0 || rdx > self.viewport.rect.width
    return false if luy < 0 || rdy > self.viewport.rect.height
    return true
  end
  #--------------------------------------------------------------------------
  # ● 设置绑定的视图
  #--------------------------------------------------------------------------
  def bind_viewport(vp)
    @viewport_bind = vp
    self.viewport = vp
  end
  # 临时解绑与再绑定
  def unbind_viewport
    self.viewport = nil
  end
  def rebind_viewport
    self.viewport = @viewport_bind
  end
  #--------------------------------------------------------------------------
  # ● 设置绑定的窗口
  #--------------------------------------------------------------------------
  def bind_window(window_bind)
    @window_bind = window_bind
    self.z = @window_bind.z + 1 if @window_bind
  end
  #--------------------------------------------------------------------------
  # ● 设置绑定的绘制参数
  #--------------------------------------------------------------------------
  def bind_font(font_bind)
    @eagle_font = font_bind
  end
  #--------------------------------------------------------------------------
  # ● 在位置不变的情况下，文字精灵不再受限于对话框
  #--------------------------------------------------------------------------
  def free_from_msg
    reset_oxy(7)
    bind_viewport(nil) # 取消视图，确保不会出现资源崩溃，且不再限制可见范围
    update_position    # 更新一次位置，用于刷新保存的@x0和@_ox
    @window_bind = nil # 取消窗口的绑定
  end
  #--------------------------------------------------------------------------
  # ● 重置
  #--------------------------------------------------------------------------
  def reset(x, y, w, h)
    self.bitmap.dispose if self.bitmap
    self.bitmap = Bitmap.new(w, h)
    # (x0,y0) 当前的文字显示区域的左上角的屏幕坐标
    @x0 = 0; @y0 = 0
    # (_ox,_oy) 当前的文字显示区域的显示原点位置（对话框内部坐标系）
    @_ox = 0; @_oy = 0
    # 左对齐时，本文字的显示位置（存储为标准位置，方便对齐）
    @origin_x = x; @origin_y = y
    # 设置本文字的显示位置
    reset_xy(x, y)
    reset_oxy(7)
    # 重置参数
    @dx = 0; @dy = 0 # 动态移动时的偏移值
    @flag_first_move_in = true # 第一次移入？
    @flag_update_pos = true # 需要更新位置？
    @flag_move = nil # 在移动中？
    # 重置特效参数
    @effects = {} # effect_sym => param_string
    @effect_params = {} # effect_sym => param_has
    # 重置精灵参数
    self.src_rect = Rect.new(0,0,self.width,self.height)
    self.zoom_x = self.zoom_y = 1.0
    self.angle = 0
    self.wave_amp    = 0
    self.wave_length = 0
    self.wave_speed  = 0
    self.wave_phase  = 0
    self.mirror = false
    self.blend_type = 0
    self.color = Color.new(255,255,255,0)
    self.opacity = 255
    self.visible = true
  end
  #--------------------------------------------------------------------------
  # ● 设置相对偏移值（以对话框中的文字显示区域的屏幕左上角为原点）
  #--------------------------------------------------------------------------
  def reset_xy(x = nil, y = nil)
    @_x = x if x # 存储文字相对对话框左上角的显示位置
    @_y = y if y
  end
  #--------------------------------------------------------------------------
  # ● 设置移动增量
  #--------------------------------------------------------------------------
  def reset_dxy(dx = nil, dy = nil)
    @dx = dx if dx
    @dy = dy if dy
  end
  #--------------------------------------------------------------------------
  # ● 设置显示原点
  #--------------------------------------------------------------------------
  def reset_oxy(o)
    MESSAGE_EX.reset_sprite_oxy(self, o)
  end
  #--------------------------------------------------------------------------
  # ● 设置显示视图的原点位置
  # （当在移入移出时，若所绑定窗口的内容原点变动，靠此方法强制移动）
  #--------------------------------------------------------------------------
  def reset_window_oxy(ox = nil, oy = nil)
    @_ox = ox if ox
    @_oy = oy if oy
  end
  #--------------------------------------------------------------------------
  # ● 结束
  #--------------------------------------------------------------------------
  def finish
    @flag_move = :end
    self.opacity = 0
  end
  #--------------------------------------------------------------------------
  # ● 结束使命？（在文字池中使用，进行文字精灵的复用）
  #--------------------------------------------------------------------------
  def finish?
    @flag_move == :end
  end

  #--------------------------------------------------------------------------
  # ● 解析参数
  #--------------------------------------------------------------------------
  def parse_param(params, param_s, default_type = "default")
    MESSAGE_EX.parse_param(params, param_s, default_type)
  end
  #--------------------------------------------------------------------------
  # ● 初始化特效的默认参数
  #--------------------------------------------------------------------------
  def init_effect_params(sym)
    MESSAGE_EX.get_default_params(sym)
  end
  #--------------------------------------------------------------------------
  # ● 开始特效（整合）
  #--------------------------------------------------------------------------
  def start_effects(effects)
    @effects = {} # code_symbol => param_string
    effects.each { |sym, param_s| start_effect(sym, param_s) }
  end
  #--------------------------------------------------------------------------
  # ● 开始特效
  #--------------------------------------------------------------------------
  def start_effect(sym, param_s)
    @effects[sym] = param_s
    @effect_params[sym] = init_effect_params(sym).dup # 初始化
    m = ("start_effect_" + sym.to_s).to_sym
    method(m).call(@effect_params[sym], param_s.dup) if respond_to?(m)
  end
  # def start_effect_code(param)  code → 转义符
  # end
  #--------------------------------------------------------------------------
  # ● 更新特效（整合）
  #--------------------------------------------------------------------------
  def update_effects
    @effects.each { |sym, param_s|
      m = ("update_effect_" + sym.to_s).to_sym
      method(m).call(@effect_params[sym]) if respond_to?(m)
    }
  end
  # def update_effect_code(param)  code → 转义符
  # end
  #--------------------------------------------------------------------------
  # ● 结束特效（整合）
  #--------------------------------------------------------------------------
  def finish_effects
    @effects.each { |sym, param|
      m = ("finish_effect_" + sym.to_s).to_sym
      method(m).call(@effect_params[sym]) if respond_to?(m)
    }
    @effects.clear
  end
  #--------------------------------------------------------------------------
  # ● 结束特效
  #--------------------------------------------------------------------------
  def finish_effect(sym)
    return if !@effects.include?(sym)
    m = ("finish_effect_" + sym.to_s).to_sym
    method(m).call(@effect_params[sym]) if respond_to?(m)
    @effects.delete(sym)
  end
  # def finish_effect_code(param)  code → 转义符
  # end

  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    return if finish?
    update_position if @flag_update_pos
    return move_update(@flag_move) if @flag_move
    if update_effects?
      super
      update_effects
    end
  end
  #--------------------------------------------------------------------------
  # ● 可以更新特效？
  #--------------------------------------------------------------------------
  def update_effects?
    self.visible && !finish? && !@effects.empty?
  end
  #--------------------------------------------------------------------------
  # ● 更新位置
  #--------------------------------------------------------------------------
  def update_position
    self.x = @_x + @dx + self.ox
    self.y = @_y + @dy + self.oy
    if @window_bind
      @x0 = @window_bind.eagle_charas_x0
      @y0 = @window_bind.eagle_charas_y0
      if self.viewport
        @_ox = @window_bind.eagle_charas_ox
        @_oy = @window_bind.eagle_charas_oy
        self.x -= self.viewport.rect.x
        self.y -= self.viewport.rect.y
      end
    end
    self.x += (@x0 - @_ox)
    self.y += (@y0 - @_oy)
  end
  #--------------------------------------------------------------------------
  # ● 更新移动
  #--------------------------------------------------------------------------
  def move_update(sym = :cin) # 只有移动结束时，才进行其他更新
    params = @effect_params[sym]
    params[:tc] += 1

    per = params[:tc] * 1.0 / params[:t]
    per = (params[:tc] == params[:t] ? 1 : MESSAGE_EX.ease_value(:chara_xy, per))
    @dx = (params[:dx_init] + params[:dx_d] * per).round
    @dy = (params[:dy_init] + params[:dy_d] * per).round

    if (params[:rxc] += 1) == params[:rxt]
      params[:rxc] = 0
      self.src_rect.x += params[:rx]
    end
    if (params[:ryc] += 1) == params[:ryt]
      params[:ryc] = 0
      self.src_rect.y += params[:ry]
    end
    (params[:vzc] = 0;@_zoom += params[:vz]) if (params[:vzc] += 1) == params[:vzt]
    self.zoom_x = self.zoom_y = 1.0 + @_zoom/100.0
    self.angle -= params[:vd] * params[:va]
    self.opacity += params[:vo]
    
    update_effect_ctog(params)
    
    move_end(sym) if params[:tc] == params[:t]
  end
  def move_end(sym = :cin)
    @flag_move = nil
    rebind_viewport
    reset_oxy(7)
    finish_effect_ctog(@effect_params[sym])
    if sym == :cin
      @dx = @dy = 0
      update_position
      self.zoom_x = self.zoom_y = 1.0
      self.opacity = 255
      @flag_first_move_in = false
    elsif sym == :cout
      finish
      @flag_move = :end
    end
  end
  #--------------------------------------------------------------------------
  # ● 正在进行移入移出？
  #--------------------------------------------------------------------------
  def move_updating?
    @flag_move != nil
  end

  #--------------------------------------------------------------------------
  # ● 移入
  #--------------------------------------------------------------------------
  def start_effect_cin(params, param_s, flag_move_in = true)
    parse_param(params, param_s)
    params[:t] = 1 if params[:t] < 1
    params[:vzc] = 0 # 计数用
    params[:vzt] = 1 if params[:vzt] < 1
    rand_cin(params, param_s) if params[:r] != 0
    params[:vd] ||= 0
    if params[:vd] == 0
      params[:vd] = rand > 0.5 ? 1 : -1
    else 
      params[:vd] = params[:vd] / params[:vd].abs
    end
    _vo = 255 / params[:t] # 移入时每帧不透明度增量
    params[:vo] = [_vo, params[:vo], 1].max
    params[:rxc] = 0; params[:ryc] = 0
    params[:rxt] = 1 if params[:rxt] < 1
    params[:ryt] = 1 if params[:ryt] < 1
    
    charas = MESSAGE_EX.get_charas_array(:ctog, params[:togi], params[:togn])
    init_charas_tog(params, charas, params[:togt], params[:togr])
    
    move_in if flag_move_in
  end
  #--------------------------------------------------------------------------
  # ● 随机移入
  #--------------------------------------------------------------------------
  RAND_V = lambda { |v| rand(v * 2 + 1) - v }
  def rand_cin(params, param_s)
    params[:t] = rand(params[:t]) + 1
    params[:vz] = RAND_V.call(params[:vz])
    params[:vzt] = rand(params[:vzt]) + 1
    params[:va] = RAND_V.call(params[:va])
    params[:dx] = RAND_V.call(params[:dx])
    params[:dy] = RAND_V.call(params[:dy])
  end
  #--------------------------------------------------------------------------
  # ● 执行移入
  #--------------------------------------------------------------------------
  def move_in
    params = @effect_params[:cin]
    rebind_viewport # 重新绑定视图
    update_position # 记录包含视图位移的值
     # 如果没有定义移入特效 或 不是首次移入且在视图外
    if params.nil? || (!@flag_first_move_in && !in_viewport?)
      self.opacity = 255 # 直接指定不透明度
      @flag_move = nil
      return
    end
    unbind_viewport # 为了移入，先取消视图
    @dx = @dy = 0
    update_position # 用于获取实际的最终显示位置（屏幕坐标）

    _rect = Rect.new(self.x, self.y, self.width, self.height)
    if params[:do] != 0
      MESSAGE_EX.reset_xy_dorigin(_rect, @window_bind, params[:do])
    end
    @dx = params[:dx_init] = _rect.x + params[:dx] - self.x
    @dy = params[:dy_init] = _rect.y + params[:dy] - self.y
    params[:dx_d] = self.x - (_rect.x + params[:dx])
    params[:dy_d] = self.y - (_rect.y + params[:dy])

    @_zoom = -(params[:t]/params[:vzt]) * params[:vz]
    self.angle = params[:vd] * params[:va] * params[:t]
    self.src_rect.x = -(params[:t]/params[:rxt]) * params[:rx]
    self.src_rect.y = -(params[:t]/params[:ryt]) * params[:ry]
    self.zoom_x = self.zoom_y = 1.0 + @_zoom/100.0
    self.opacity = 0
    reset_oxy(5)
    params[:tc] = 0
    @flag_move = :cin
  end
  #--------------------------------------------------------------------------
  # ● 移出
  #--------------------------------------------------------------------------
  def start_effect_cout(params, param_s)
    start_effect_cin(params, param_s, false)
    params[:vo] *= -1
  end
  #--------------------------------------------------------------------------
  # ● 执行移出（外部调用的方法）
  #--------------------------------------------------------------------------
  def move_out
    finish_effects # 先结束全部特效
    finish if !in_viewport? # 若精灵在视图外，则会直接结束
    if !finish?
      process_move_out  # 处理移出模式
    end
    free_from_msg  # 不再受限于对话框内，但位置保持不变
    MESSAGE_EX.charapool_push(self) # 由文字池接管
  end
  #--------------------------------------------------------------------------
  # ● 执行移出（外部调用的方法）（临时移出，之后可以再执行move_in）
  #--------------------------------------------------------------------------
  def move_out_temp
    finish if !in_viewport? # 若精灵在视图外，则会直接结束
    unbind_viewport
    if !finish?
      process_move_out
      update_position
    end
  end
  #--------------------------------------------------------------------------
  # ● 处理移出模式
  #--------------------------------------------------------------------------
  def process_move_out
    if @effect_params[:cout] && !@effect_params[:cout].empty?
      return move_out_cout(@effect_params[:cout]) 
    end
    if @effect_params[:uout] && !@effect_params[:uout].empty?
      return move_out_uout(@effect_params[:uout]) 
    end
    finish # 如果未设置任何移出模式，则直接结束显示
  end
  #--------------------------------------------------------------------------
  # ● 执行默认移出
  #--------------------------------------------------------------------------
  def move_out_cout(params)
    _x = self.x; _y = self.y
    if(self.viewport)
      _x += self.viewport.rect.x; _y += self.viewport.rect.y
    end
    _rect = Rect.new(_x, _y, self.width, self.height)
    if params[:do] != 0
      MESSAGE_EX.reset_xy_dorigin(_rect, @window_bind, params[:do])
      MESSAGE_EX.reset_xy_origin(_rect, 5)
    end
    params[:dx_init] = 0
    params[:dy_init] = 0
    params[:dx_d] = (_rect.x + params[:dx]) - _x
    params[:dy_d] = (_rect.y + params[:dy]) - _y

    @dx = @dy = @_zoom = 0
    reset_oxy(5)
    params[:tc] = 0
    @flag_move = :cout
  end
  #--------------------------------------------------------------------------
  # ● 消散移出
  #--------------------------------------------------------------------------
  def start_effect_uout(params, param_s)
    parse_param(params, param_s)
    params[:dir] = MESSAGE_EX::CU_PARAM_DIR[ params[:dir] ]
    params[:s] = MESSAGE_EX::CU_PARAM_S[ params[:s] ]
  end
  def move_out_uout(params)
    _x = self.x; _y = self.y
    if(self.viewport)
      _x += self.viewport.rect.x; _y += self.viewport.rect.y
    end
    Unravel_Bitmap.new(_x, _y, self.bitmap.clone, 0, 0, self.width,
      self.height, params[:n], params[:d], params[:o], params[:dir], params[:s])
    finish
  end
  #--------------------------------------------------------------------------
  # ● 正弦扭曲特效
  #--------------------------------------------------------------------------
  def start_effect_csin(params, param_s)
    parse_param(params, param_s)
    self.wave_amp    = params[:a]
    self.wave_length = params[:l]
    self.wave_speed  = params[:s]
    self.wave_phase  = params[:p]
  end
  #--------------------------------------------------------------------------
  # ● 波浪特效
  #--------------------------------------------------------------------------
  def start_effect_cwave(params, param_s)
    params[:tc] = 0  # 移动计数用初值（一次性）
    parse_param(params, param_s)
  end
  def update_effect_cwave(params)
    return if (params[:tc] += 1) < params[:t]
    params[:tc] = 0
    @dy += params[:vy]
    params[:vy] *= -1 if @dy < -params[:h] || @dy > params[:h]
  end
  #--------------------------------------------------------------------------
  # ● 抖动特效
  #--------------------------------------------------------------------------
  def start_effect_cshake(params, param_s)
    params[:vxc] = 0  # 移动计数用初值（一次性）
    params[:vyc] = 0  # 移动计数用初值（一次性）
    parse_param(params, param_s)
    params[:vx] = rand(2) * 2 - 1 if params[:vx] == 0
    params[:vy] = rand(2) * 2 - 1 if params[:vy] == 0
  end
  def update_effect_cshake(params)
    if (params[:vxc] += 1) > params[:vxt]
      params[:vxc] = 0
      @dx += params[:vx]
      params[:vx] *= -1 if @dx < -params[:l] || @dx > params[:r]
    end
    if (params[:vyc] += 1) > params[:vyt]
      params[:vyc] = 0
      @dy += params[:vy]
      params[:vy] *= -1 if @dy < -params[:u] || @dy > params[:d]
    end
  end
  #--------------------------------------------------------------------------
  # ● 抖动特效2
  #--------------------------------------------------------------------------
  def start_effect_cshake2(params, param_s)
    parse_param(params, param_s)
  end
  def update_effect_cshake2(params)
    @dx = (-1.0 + params[:l] * rand()) * params[:dx]
    @dy = (-1.0 + params[:l] * rand()) * params[:dy]
  end
  #--------------------------------------------------------------------------
  # ● 摇摆特效
  #--------------------------------------------------------------------------
  def start_effect_cswing(params, param_s)
    params[:ac] = 0 # 当前偏移角度和
    params[:tc] = 0
    parse_param(params, param_s)
    params[:init] = false  # 为了避免文字移入将设置覆盖，在更新时才初始化
  end
  def update_effect_cswing(params)
    return if (params[:tc] -= 1) > 0
    if !params[:init]
      reset_oxy(params[:o])
      self.angle = 0
      params[:init] = true
    end
    if params[:d] == 0
      params[:ac] = self.angle == 0 ? rand(2)*2-1 : (self.angle > 0 ? -1 : 1)
      params[:ac] *= params[:a]
    else
      params[:ac] += params[:d]
      params[:tc] = params[:t]
    end
    if params[:ac].abs >= params[:a]
      params[:ac] = params[:a] * (params[:ac] > 0 ? 1 : -1)
      params[:d] *= -1
      params[:tc] = params[:t2]
    end
    self.angle = params[:ac]
  end
  #--------------------------------------------------------------------------
  # ● 缩放特效
  #--------------------------------------------------------------------------
  def start_effect_czoom(params, param_s)
    params[:tc] = 0 # 计时
    parse_param(params, param_s)
    params[:zoom_x] = 100 # 初始的总缩放量
    params[:zoom_y] = 100
    params[:init] = false
  end
  def update_effect_czoom(params)
    return if (params[:tc] -= 1) > 0
    if !params[:init]
      reset_oxy(params[:o])
      params[:init] = true
    end
    params[:tc] = params[:t]
    if params[:dx] != 0
      params[:zoom_x] += params[:dx]
      params[:dx] *= -1 if params[:zoom_x] > params[:max] || params[:zoom_x] < params[:min]
      self.zoom_x = params[:zoom_x] * 1.0 / 100
    end
    if params[:dy] != 0
      params[:zoom_y] += params[:dy]
      params[:dy] *= -1 if params[:zoom_y] > params[:max] || params[:zoom_y] < params[:min]
      self.zoom_y = params[:zoom_y] * 1.0 / 100
    end
  end
  #--------------------------------------------------------------------------
  # ● 闪烁特效
  #--------------------------------------------------------------------------
  def start_effect_cflash(params, param_s)
    params[:tc] = 0  # 闪烁后的等待时间计数
    parse_param(params, param_s)
    params[:color] = Color.new(params[:r], params[:g], params[:b], params[:a])
  end
  def update_effect_cflash(params)
    return if (params[:tc] -= 1) > 0
    params[:tc] = params[:t] + params[:d]
    self.flash(params[:color], params[:d])
  end
  #--------------------------------------------------------------------------
  # ● 镜像特效
  #--------------------------------------------------------------------------
  def start_effect_cmirror(params, param_s)
    params[:b]  = '0'
    parse_param(params, param_s, :b)
    params[:init] = false
  end
  def update_effect_cmirror(params)
    if !params[:init]
      self.mirror = (params[:b] == '0' ? false : true)
      params[:init] = true
    end
  end
  def finish_effect_cmirror(params)
    self.mirror = false
  end
  #--------------------------------------------------------------------------
  # ● 消散特效
  #--------------------------------------------------------------------------
  def start_effect_cu(params, param_s)
    params[:t_c] = 0 # 间隔计数
    parse_param(params, param_s)
    params[:dir] = MESSAGE_EX::CU_PARAM_DIR[ params[:dir] ]
    params[:s] = MESSAGE_EX::CU_PARAM_S[ params[:s] ]
  end
  def update_effect_cu(params)
    return if !in_viewport?
    return if (params[:t_c] += 1) < params[:t]
    params[:t_c] = 0
    _x = self.x; _y = self.y
    if(self.viewport)
      _x += self.viewport.rect.x; _y += self.viewport.rect.y
    end
    Unravel_Bitmap.new(_x, _y, self.bitmap.clone, 0, 0, self.width,
      self.height, params[:n], params[:d], params[:o], params[:dir], params[:s])
  end
  #--------------------------------------------------------------------------
  # ● 位图切换特效
  #--------------------------------------------------------------------------
  def start_effect_ctog(params, param_s)
    parse_param(params, param_s)
    charas = MESSAGE_EX.get_charas_array(:ctog, params[:i], params[:n])
    init_charas_tog(params, charas, params[:t], params[:r])
  end
  def init_charas_tog(params, charas, t, r)
    return if charas == nil or charas.empty?
    # t 为每次切换的时间间隔，r=0为顺序切换，r=1为随机切换
    params[:bitmaps] = get_charas_bitmaps(charas)
    params[:bitmaps].unshift(self.bitmap)
    params[:tog_i_cur] = 0
    params[:tog_i_max] = params[:bitmaps].size
    params[:tog_tc] = 0
    params[:tog_t] = t
    params[:tog_r] = r
    params[:flag_tog] = true
  end
  def get_charas_bitmaps(charas)  # 绘制字符数组中每个文字的位图（数字为图标）
    bitmaps = []
    charas.each do |c|
      s = Bitmap.new(self.width, self.height)
      if c.is_a?(Integer)
        @eagle_font.draw_icon(s, 0+self.width/2-12, 0+self.height/2-12, c)
      else
        r = s.text_size(c)
        @eagle_font.draw(s, (self.width-r.width)/2, (self.height-r.height)/2,
          self.width, self.height, c, 0)
      end
      bitmaps.push(s)
    end
    return bitmaps
  end
  def update_effect_ctog(params)
    return if params[:flag_tog] != true
    return if (params[:tog_tc] += 1) < params[:tog_t]
    params[:tog_tc] = 0
    if(params[:tog_r] > 0)
      params[:tog_i_cur] = rand(params[:tog_i_max])
    else
      params[:tog_i_cur] += 1
      params[:tog_i_cur] %= params[:tog_i_max]
    end
    self.bitmap = params[:bitmaps][params[:tog_i_cur]]
  end
  def finish_effect_ctog(params)
    return if params[:flag_tog] != true
    self.bitmap = params[:bitmaps].shift
    params[:bitmaps].each { |b| b.dispose }
    params[:bitmaps].clear
  end
  #--------------------------------------------------------------------------
  # ● 霓虹灯特效
  #--------------------------------------------------------------------------
  def start_effect_cneon(params, param_s)
    params[:c] = []
    s = param_s.downcase
    while(s != "")
      sym = s.slice!(/\D+/)
      v = (s.slice!(/\d+/)).to_i
      next params[:c].push(v) if sym == "c"
      params[sym.to_sym] = v
    end
    params[:tc] = 0
    params[:c1] = self.color
    params[:c1].alpha = 255
    params[:c2] = @window_bind.text_color(params[:c][0])
    params[:i] = 0
  end
  def update_effect_cneon(params)
    return if @window_bind.nil?
    params[:tc] += 1
    self.color.red = params[:c1].red +
      (params[:c2].red - params[:c1].red)*1.0/ params[:t] * params[:tc]
    self.color.green = params[:c1].green +
      (params[:c2].green - params[:c1].green)*1.0 / params[:t] * params[:tc]
    self.color.blue = params[:c1].blue +
      (params[:c2].blue - params[:c1].blue)*1.0 / params[:t] * params[:tc]

    if params[:tc] >= params[:t]
      params[:c1] = @window_bind.text_color(params[:c][params[:i]])
      params[:i] += 1
      params[:i] = 0 if params[:i] >= params[:c].size
      params[:c2] = @window_bind.text_color(params[:c][params[:i]])
      params[:tc] = 0
    end
  end
  #--------------------------------------------------------------------------
  # ● 文字叠加绘制
  #--------------------------------------------------------------------------
  def start_effect_cmc(params, param_s)
    parse_param(params, param_s)
    charas = MESSAGE_EX.get_charas_array(:cmc, params[:i], params[:n])
    @eagle_font.set_param(:m, charas)
    @eagle_font.set_param(:mc, params[:c])
  end
  #--------------------------------------------------------------------------
  # ● 跳跃特效
  #--------------------------------------------------------------------------
  def start_effect_cjump(params, param_s)
    parse_param(params, param_s)
    params[:tc] *= -1
    # 二次函数的x项系数
    params[:A] = (4.0 * params[:h]) / (params[:t] * params[:t])
  end
  def update_effect_cjump(params)
    if params[:tc] < 0 # 等待中
    elsif params[:tc] <= params[:t] # 跳跃中
      @dy = (params[:tc]-params[:t]/2)**2 * params[:A] - params[:h]
    elsif params[:w] && params[:tc] >= params[:t] + params[:w]
      # 跳跃后的等待结束
      params[:tc] = 0
    end
    params[:tc] += 1
  end
  #--------------------------------------------------------------------------
  # ● 明灭特效
  #--------------------------------------------------------------------------
  def start_effect_cfk(params, param_s)
    parse_param(params, param_s)
    params[:c] = 0
    params[:wait] = 0
  end
  def update_effect_cfk(params)
    return if params[:wait] == nil || (params[:wait] -= 1) > 0
    if params[:c] == 0
      self.opacity = 255
      if params[:t] > 0
        params[:t_] = params[:t]
        params[:dopa] = 255.0 / params[:t_]
      elsif params[:t] == 0
        params[:t_] = MESSAGE_EX::CFK_T0_WAIT
        params[:dopa] = 255
      else
        params[:t_] = rand(-params[:t])
        params[:dopa] = 255.0 / params[:t_]
      end
    end
    params[:c] += 1
    self.opacity += (params[:c]<=params[:t_] ? -params[:dopa] : params[:dopa])
    if params[:h] == 1 && self.opacity >= 255 ||
       params[:h] == 0 && self.opacity <= 0
      params[:c] = 0
      params[:wait] = params[:w] 
    end
  end
  #--------------------------------------------------------------------------
  # ● 精确渐隐特效
  #--------------------------------------------------------------------------
  def start_effect_cfade(params, param_s)
    parse_param(params, param_s)
    params[:c] = params[:t]
  end
  def update_effect_cfade(params)
    return if params[:c] <= 0
    self.opacity -= params[:v]
    params[:c] -= 1 
  end
end

#=============================================================================
# ○ 兼容模式
#=============================================================================
module MESSAGE_EX::COMPA_MODE
  #--------------------------------------------------------------------------
  # ● 更新画面
  #--------------------------------------------------------------------------
  def update_all_windows
    if @flag_last_eagle_message == true && $game_message.eagle_message == false
      @message_window.process_before_switch_to_other_message
    end
    if $game_message.eagle_message == true
      @message_window = @msg_windows[1]
    else
      @message_window = @msg_windows[0]
    end
    @flag_last_eagle_message = $game_message.eagle_message
    eagle_message_ex_compa_mode_update_all_windows
  end
  #--------------------------------------------------------------------------
  # ● 释放所有窗口
  #--------------------------------------------------------------------------
  def dispose_all_windows
    @msg_windows.each { |w| w.dispose }
    @message_window = nil
    eagle_message_ex_compa_mode_dispose_all_windows
  end
end
class Window_EagleMessage
  #--------------------------------------------------------------------------
  # ● 兼容模式中，切换到其它对话框时的处理
  #--------------------------------------------------------------------------
  def process_before_switch_to_other_message
  end
end
#=============================================================================
# ○ Scene_Map
#=============================================================================
class Spriteset_Map; attr_reader :character_sprites; end
class Scene_Map
  attr_reader :spriteset, :message_window
if EAGLE_MSG_EX_COMPAT_MODE == true
  alias eagle_message_ex_compa_mode_update_all_windows update_all_windows
  alias eagle_message_ex_compa_mode_dispose_all_windows dispose_all_windows
  include MESSAGE_EX::COMPA_MODE
  #--------------------------------------------------------------------------
  # ● 生成信息窗口
  #--------------------------------------------------------------------------
  alias eagle_message_ex_compa_mode_create_message_window create_message_window
  def create_message_window
    eagle_message_ex_compa_mode_create_message_window
    @msg_windows = [@message_window, Window_EagleMessage.new]
  end
else
  #--------------------------------------------------------------------------
  # ● 生成信息窗口
  #--------------------------------------------------------------------------
  def create_message_window
    @message_window = Window_EagleMessage.new
  end
end
end
#=============================================================================
# ○ Scene_Battle
#=============================================================================
class Scene_Battle
  attr_reader :spriteset, :message_window
if EAGLE_MSG_EX_COMPAT_MODE == true
  alias eagle_message_ex_compa_mode_update_all_windows update_all_windows
  alias eagle_message_ex_compa_mode_dispose_all_windows dispose_all_windows
  include MESSAGE_EX::COMPA_MODE
  #--------------------------------------------------------------------------
  # ● 生成信息窗口
  #--------------------------------------------------------------------------
  alias eagle_message_ex_compa_mode_create_message_window create_message_window
  def create_message_window
    eagle_message_ex_compa_mode_create_message_window
    @msg_windows = [@message_window, Window_EagleMessage.new]
  end
else
  #--------------------------------------------------------------------------
  # ● 生成信息窗口
  #--------------------------------------------------------------------------
  def create_message_window
    @message_window = Window_EagleMessage.new
  end
end
  #--------------------------------------------------------------------------
  # ● 信息窗口打开时的更新
  #  覆盖：对话框打开时，不再关闭状态窗口
  #--------------------------------------------------------------------------
  def update_message_open
  end
end
