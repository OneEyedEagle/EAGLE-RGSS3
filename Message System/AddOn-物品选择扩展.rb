#==============================================================================
# ■ Add-On 物品选择框扩展 by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【对话框扩展 by老鹰】之下
#==============================================================================
# - 2019.6.7.23 嵌入后将跟随对话框移动
#==============================================================================
# - 在对话框中利用 \keyitem[param] 对物品选择框进行部分参数设置：
#     type → 【默认】物品选择范围的类型index（见 index → 物品种类的符号数组 的映射）
#     o → 物品选择框的显示原点类型（九宫格小键盘）（默认7）（嵌入时固定为7）
#     x/y → 直接指定物品选择框的坐标（默认不设置）（利用参数重置进行清除）
#     do → 物品选择框的显示位置类型（覆盖x/y）（默认-10无效）
#         （0为嵌入；1~9对话框外边界的九宫格位置；-1~-9屏幕外框的九宫格位置）
#         （当对话框关闭时，0~9的设置均无效）
#     dx/dy → x/y坐标的偏移增量（默认0）
#     wmin → 物品选择框的最小宽度
#     w → 物品选择框的宽度（默认0不设置）（嵌入时该设置无效）
#     h → 物品选择框的高度（默认0不设置）（若小于行高，则认定为行数）
#     opa → 选择框的背景不透明度（默认255）（文字内容不透明度固定为255）
#         （嵌入时不显示窗口背景）
#     skin → 选择框皮肤类型（每次默认取对话框皮肤）（见index → windowskin名称 的映射）
#
#------------------------------------------------------------------------------
# - 在 事件脚本 中利用 $game_message.keyitem_params[sym] = value 对指定参数赋值
#   示例：
#     $game_message.keyitem_params[:type] = 4
#     # 物品选项框的物品范围变为4号指定范围（全部持有的普通道具和关键道具）
#------------------------------------------------------------------------------
# - 参数重置（具体见 对话框扩展 中的注释）
#     $game_message.reset_params(:keyitem, code_string)
#------------------------------------------------------------------------------
# - 注意：
#    ·VA默认物品选择框为4行2列，而此处改为了n行1列，
#       本插件将物品选择框的默认位置改成了o7时屏幕居中偏下位置
#==============================================================================

#==============================================================================
# ○ 【设置部分】
#==============================================================================
module MESSAGE_EX
  #--------------------------------------------------------------------------
  # ● 【设置】定义转义符各参数的预设值
  # （对于bool型变量，0与false等价，1与true等价）
  #--------------------------------------------------------------------------
  KEYITEM_PARAMS_INIT = {
  # \keyitem[]
    :type => 0, # 所选择物品的种类
    :o => 7, # 原点类型
    :x => nil,
    :y => nil,
    :do => 0, # 显示位置类型
    :dx => 0,
    :dy => 0,
    :wmin => Graphics.width / 3, # 最小宽度
    :w => 0,
    :h => 0,
    :opa => 255, # 背景不透明度
    :skin => nil, # 皮肤类型（nil时代表跟随对话框）
  }
  #--------------------------------------------------------------------------
  # ● 【设置】定义 index → 选择物品类型数组 的映射
  # （默认只有 :item/:weapon/:armor/:key_item 四种类型）
  #--------------------------------------------------------------------------
  INDEX_TO_KEYITEM_TYPE = {
    0 => [:item],
    1 => [:weapon],
    2 => [:armor],
    3 => [:key_item], # 默认类型
    4 => [:item, :key_item],
  }
end

#==============================================================================
# ○ 读取设置
#==============================================================================
module MESSAGE_EX
  #--------------------------------------------------------------------------
  # ● 获取选择物品的种类数组
  #--------------------------------------------------------------------------
  def self.keyitem_type(index)
    INDEX_TO_KEYITEM_TYPE[index] || INDEX_TO_KEYITEM_TYPE[3]
  end
end
#==============================================================================
# ○ Game_Message
#==============================================================================
class Game_Message
  attr_accessor :keyitem_params
  #--------------------------------------------------------------------------
  # ● 获取全部可保存params的符号的数组
  #--------------------------------------------------------------------------
  alias eagle_keyitem_ex_params eagle_params
  def eagle_params
    eagle_keyitem_ex_params + [:keyitem]
  end
end
#==============================================================================
# ○ Window_Message
#==============================================================================
class Window_Message
  #--------------------------------------------------------------------------
  # ● 额外增加的窗口宽度高度
  #--------------------------------------------------------------------------
  alias eagle_keyitem_ex_window_width_add eagle_window_width_add
  def eagle_window_width_add(cur_width)
    w = eagle_keyitem_ex_window_width_add(cur_width)
    w += @item_window.message_window_w_add if game_message.item_choice?
    w
  end
  alias eagle_keyitem_ex_window_height_add eagle_window_height_add
  def eagle_window_height_add(cur_height)
    h = eagle_keyitem_ex_window_height_add(cur_height)
    h += @item_window.message_window_h_add if game_message.item_choice?
    h
  end
  #--------------------------------------------------------------------------
  # ● 设置keyitem参数
  #--------------------------------------------------------------------------
  def eagle_text_control_keyitem(param = "")
    parse_param(game_message.keyitem_params, param, :type)
  end
end
#==============================================================================
# ○ Window_KeyItem
#==============================================================================
class Window_KeyItem < Window_ItemList
  attr_reader :message_window_w_add, :message_window_h_add
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  alias eagle_keyitem_ex_init initialize
  def initialize(message_window)
    @item_max_width = 0 # 最大的选项宽度
    @message_window_w_add = @message_window_h_add = 0
    eagle_keyitem_ex_init(message_window)
  end
  #--------------------------------------------------------------------------
  # ● 获取列数
  #--------------------------------------------------------------------------
  def col_max
    return 1
  end
  #--------------------------------------------------------------------------
  # ● 关闭
  #--------------------------------------------------------------------------
  alias eagle_keyitem_ex_close close
  def close
    @message_window_w_add = @message_window_h_add = 0 # 重置对话框wh增量
    eagle_keyitem_ex_close
  end
  #--------------------------------------------------------------------------
  # ● 开始输入的处理
  #--------------------------------------------------------------------------
  def start
    reset_width_min
    update_category
    update_size
    refresh
    update_placement
    update_params_ex
    select(0)
    open
    activate
  end
  #--------------------------------------------------------------------------
  # ● 重设最小宽度
  #--------------------------------------------------------------------------
  def reset_width_min
    return if self.width == $game_message.keyitem_params[:wmin]
    self.width = $game_message.keyitem_params[:wmin]
    self.height = fitting_height(1)
    create_contents
  end
  #--------------------------------------------------------------------------
  # ● 更新物品种类
  #--------------------------------------------------------------------------
  def update_category
    @categories = MESSAGE_EX.keyitem_type($game_message.keyitem_params[:type])
  end
  #--------------------------------------------------------------------------
  # ● 查询列表中是否含有此物品
  #--------------------------------------------------------------------------
  def include?(item)
    @categories.each do |c|
      case c
      when :item;     return true if item.is_a?(RPG::Item) && !item.key_item?
      when :weapon;   return true if item.is_a?(RPG::Weapon)
      when :armor;    return true if item.is_a?(RPG::Armor)
      when :key_item; return true if item.is_a?(RPG::Item) && item.key_item?
      end
    end
    return false
  end
  #--------------------------------------------------------------------------
  # ● 查询此物品是否可用
  #--------------------------------------------------------------------------
  def enable?(item)
    true#$game_party.usable?(item)
  end
  #--------------------------------------------------------------------------
  # ● 检查高度参数
  #--------------------------------------------------------------------------
  def eagle_check_param_h(h)
    return 0 if h <= 0
    # 如果h小于行高，则判定其为行数
    return line_height * h if h < line_height
    return h
  end
  #--------------------------------------------------------------------------
  # ● 更新窗口的大小
  #--------------------------------------------------------------------------
  def update_size
    # 宽度
    self.width = $game_message.keyitem_params[:w] if $game_message.keyitem_params[:w] > self.width
    # 嵌入时宽度最小值（不含边界）
    width_min = self.width - standard_padding * 2
    # 高度
    h = eagle_check_param_h($game_message.keyitem_params[:h])
    self.height = h + standard_padding * 2 if h > 0
    # 嵌入对话框时的特别处理
    if @message_window.open? && $game_message.keyitem_params[:do] == 0
      self.openness = 255
      win_w = @message_window.eagle_charas_w
      if @message_window.eagle_dynamic_w?
        d = width_min - win_w
        if d > 0
          @message_window_w_add = d # 扩展对话框的宽度
        else # 宽度 = 文字区域宽度
          self.width = win_w + standard_padding * 2
        end
      else # 宽度 = 对话框宽度 - 脸图占用宽度
        self.width = @message_window.width - @message_window.eagle_face_width
      end
      win_h = @message_window.height - @message_window.eagle_charas_h
      # 如果对话框内容高度为0，或动态高度对话框，则扩展对话框的高度
      if @message_window.eagle_dynamic_h? || @message_window.eagle_charas_h == 0
        d = self.height - win_h
        d += standard_padding if @message_window.eagle_charas_h > 0
        @message_window_h_add = d if d > 0
      else # 压缩高度
        self.height = [[height, win_h].min-standard_padding*2, item_height].max
        # 确保是行高的正整数倍数
        self.height = self.height/item_height*item_height + standard_padding*2
      end
      @message_window.eagle_process_draw_update
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新窗口的位置
  #--------------------------------------------------------------------------
  def update_placement
    self.x = (Graphics.width - width) / 2 # 默认位置
    self.y = Graphics.height - 100 - height

    self.x = $game_message.keyitem_params[:x] if $game_message.keyitem_params[:x]
    self.y = $game_message.keyitem_params[:y] if $game_message.keyitem_params[:y]
    o = $game_message.keyitem_params[:o]
    if (d_o = $game_message.keyitem_params[:do]) < 0 # 相对于屏幕
      MESSAGE_EX.reset_xy_dorigin(self, nil, d_o)
    else
      if @message_window.open?
        if d_o == 0 # 嵌入对话框
          self.x = @message_window.eagle_charas_x0 - standard_padding
          self.y = @message_window.eagle_charas_y0 + @message_window.eagle_charas_h
          self.y -= standard_padding if @message_window.eagle_charas_h == 0
          o = 7
        else
          MESSAGE_EX.reset_xy_dorigin(self, @message_window, d_o)
        end
      end
    end
    MESSAGE_EX.reset_xy_origin(self, o)
    self.x += $game_message.keyitem_params[:dx]
    self.y += $game_message.keyitem_params[:dy]
    self.z = @message_window.z + 10
  end
  #--------------------------------------------------------------------------
  # ● 更新其他属性
  #--------------------------------------------------------------------------
  def update_params_ex
    skin = $game_message.keyitem_params[:skin]
    if $game_message.pop? && !$game_message.pop_params[:skin].nil?
      skin ||= $game_message.pop_params[:skin]
    else
      skin ||= $game_message.win_params[:skin]
    end
    self.windowskin = MESSAGE_EX.windowskin(skin)
    self.opacity = $game_message.keyitem_params[:opa]
    self.opacity = 0 if $game_message.keyitem_params[:do] == 0
    self.contents_opacity = 255
  end

  #--------------------------------------------------------------------------
  # ● 更新（覆盖）
  #--------------------------------------------------------------------------
  def update
    super
    update_placement if @message_window.open? && $game_message.choice_params[:do] == 0
  end
end
