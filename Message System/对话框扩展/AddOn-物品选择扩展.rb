#==============================================================================
# ■ Add-On 物品选择框扩展 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【鹰式对话框扩展 V2.0】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-ItemChoiceEX"] = "2.2.0"
#=============================================================================
# - 2026.2.22.11 随对话框更新
#==============================================================================
# 【说明】
#
# - VA 中默认的物品选择框为4行2列，本插件改为了n行1列
#
# - VA 中默认的物品选择框位于顶部，本插件改为了屏幕居中偏下位置
#
#------------------------------------------------------------------------------
module MESSAGE_EX
#╔════════════════════════════════════════╗
# A■ 物品选择框设置                                                  \KEYITEM ■
#  ────────────────────────────────────────

#  ● \keyitem[param]

#     ---------------------------------------------------------------------
#  ◇ 预设参数         ▼ [param]“参数串”一览（字母+数字组合）
  KEYITEM_PARAMS_INIT = {

    :type => 0,   # 【默认】物品范围的类型序号
                  # （在 INDEX_TO_KEYITEM_TYPE 中设置数字所对应的物品范围）
    :o => 7,      # 窗口的原点类型（对应小键盘九宫格 | 默认值为7 左上角）
    :x => nil,    # 窗口的显示位置（屏幕坐标）
    :y => nil,
    :do => 0,     # 窗口的显示位置（覆盖 :x 和 :y 的设置）
                  #  * 0 → 嵌入对话框，此时 :o 锁定为 7，:opa 锁定为 0
                  #  * 1~9 → 对话框外边界的九宫格位置
                  #  * -1~-9 → 屏幕外框的九宫格位置
                  #（当对话框关闭时，0~9 的显示位置无效）
    :dx => 0,     # 窗口位置的左右偏移值（正数往右、负数往左）
    :dy => 0,     # 窗口位置的上下偏移值（正数往下、负数往上）
    :w => 0,      # 窗口的宽度（0 取默认值，嵌入时该设置无效）
    :h => 0,      # 窗口的高度（0 取默认值，嵌入时该设置无效）
                  #  * 若 :h 的值小于行高，则会将值变为 :h 乘以行高
    :wmin => 200, # 窗口的最小宽度，避免物品名称显示不全
    :opa => 255,  # 背景的不透明度（文字的不透明度固定为255）
    :skin => nil, # 窗口皮肤（默认取对话框皮肤）
                  #  * 具体见 INDEX_TO_WINDOWSKIN 
  }

#     ---------------------------------------------------------------------
#  ◇ 物品范围的类型序号

  # 默认只有 :item/:weapon/:armor/:key_item 四种类型
  INDEX_TO_KEYITEM_TYPE = {
    0 => [:item],
    1 => [:weapon],
    2 => [:armor],
    3 => [:key_item],  # 默认RGSS中的设置
    4 => [:item, :key_item],
  }

#╚════════════════════════════════════════╝

#==============================================================================
#                                 × 设定完毕 × 
#==============================================================================

  # 获取选择物品的种类数组
  def self.keyitem_type(index)
    INDEX_TO_KEYITEM_TYPE[index] || INDEX_TO_KEYITEM_TYPE[3]
  end
end

#==============================================================================
# ○ 绑定 \keyitem 转义符
#==============================================================================
class Game_Message
  attr_accessor :keyitem_params
  #--------------------------------------------------------------------------
  # ● 新增 keyitem 的参数hash
  #--------------------------------------------------------------------------
  alias eagle_keyitem_ex_params eagle_params
  def eagle_params
    eagle_keyitem_ex_params + [:keyitem]
  end
end
class Window_EagleMessage
  #--------------------------------------------------------------------------
  # ● \keyitem
  #--------------------------------------------------------------------------
  def eagle_text_control_keyitem(param = "")
    parse_param(game_message.keyitem_params, param, :type)
  end
end

#==============================================================================
# ○ Window_KeyItem
#==============================================================================
class Window_EagleKeyItem < Window_ItemList
  def keyitem_params; $game_message.keyitem_params; end
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize(message_window)
    @message_window = message_window
    super(0, 0, Graphics.width, fitting_height(4))
    self.openness = 0
    deactivate
    set_handler(:ok,     method(:on_ok))
    set_handler(:cancel, method(:on_cancel))
  end

  # 获取列数
  def col_max
    return 1
  end

  #--------------------------------------------------------------------------
  # ● 开始输入的处理
  #--------------------------------------------------------------------------
  def start
    update_category
    update_size
    refresh
    update_placement
    update_params_ex
    select(0)
    hide
    #open
    #activate
  end

  # 更新物品种类
  def update_category
    @categories = MESSAGE_EX.keyitem_type(keyitem_params[:type])
  end

  # 查询列表中是否含有此物品
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

  # 查询此物品是否可用
  def enable?(item)
    true #$game_party.usable?(item)
  end

  #--------------------------------------------------------------------------
  # ● 更新窗口的大小
  #--------------------------------------------------------------------------
  def update_size
    reset_width_min
    self.width = keyitem_params[:w] if keyitem_params[:w] > self.width
    h = eagle_check_param_h(keyitem_params[:h])
    self.height = h + standard_padding * 2 if h > 0

    # 处理嵌入的特殊情况
    @flag_in_msg_window = @message_window.child_window_embed_in? && keyitem_params[:do] == 0
    new_w = self.width
    if @flag_in_msg_window
      # 嵌入时对话框所需宽度最小值（不含边界）
      width_min = self.width - standard_padding * 2
      # 对话框实际能提供的宽度（文字区域宽度）
      win_w = @message_window.eagle_charas_max_w
      d = width_min - win_w
      if d > 0
        if @message_window.eagle_add_w_by_child_window?
          $game_message.child_window_w_des = d # 扩展对话框的宽度
        else
          @flag_in_msg_window = false
        end
      else # 宽度 = 文字区域宽度
        new_w = win_w + standard_padding * 2
      end
      win_h = @message_window.height - standard_padding * 2
      charas_h = @message_window.eagle_charas_y0 - @message_window.y - standard_padding +
        @message_window.eagle_charas_h - @message_window.eagle_charas_oy
      self_h = self.height - (charas_h > 0 ? 1 : 2) * standard_padding
      d = self_h - (win_h - charas_h)
      if d > 0
        if @message_window.eagle_add_h_by_child_window?
          $game_message.child_window_h_des = d # 扩展对话框的高度
        else
          @flag_in_msg_window = false
        end
      end
    end
    self.width = new_w if @flag_in_msg_window
  end

  # 重设最小宽度
  def reset_width_min
    return if self.width == keyitem_params[:wmin]
    self.width = keyitem_params[:wmin]
    self.height = fitting_height(1)
    create_contents
  end

  # 检查高度参数
  def eagle_check_param_h(h)
    return 0 if h <= 0
    # 如果h小于行高，则判定其为行数
    return line_height * h if h < line_height
    return h
  end

  #--------------------------------------------------------------------------
  # ● 更新窗口的位置
  #--------------------------------------------------------------------------
  def update_placement
    self.x = (Graphics.width - width) / 2 # 默认位置
    self.y = Graphics.height - 100 - height

    self.x = keyitem_params[:x] if keyitem_params[:x]
    self.y = keyitem_params[:y] if keyitem_params[:y]
    o = keyitem_params[:o]
    if (d_o = keyitem_params[:do]) < 0 # 相对于屏幕
      MESSAGE_EX.reset_xy_dorigin(self, nil, d_o)
    elsif @message_window.open?
      if d_o == 0 # 嵌入对话框
        if @flag_in_msg_window
          self.x = @message_window.eagle_charas_x0 - standard_padding
          self.y = @message_window.eagle_charas_y0 + @message_window.eagle_charas_h
          self.y -= standard_padding if @message_window.eagle_charas_h == 0
          o = 7
        end
      else
        MESSAGE_EX.reset_xy_dorigin(self, @message_window, d_o)
      end
    end
    MESSAGE_EX.reset_xy_origin(self, o)
    self.x += keyitem_params[:dx]
    self.y += keyitem_params[:dy]
    self.z = @message_window.z + 10
  end

  #--------------------------------------------------------------------------
  # ● 更新其他属性
  #--------------------------------------------------------------------------
  def update_params_ex
    skin = @message_window.get_cur_windowskin_index(keyitem_params[:skin])
    self.windowskin = MESSAGE_EX.windowskin(skin)
    self.opacity = self.back_opacity = keyitem_params[:opa]
    self.contents_opacity = 255

    if @flag_in_msg_window # 如果嵌入，则不执行打开
      self.opacity = 0
      self.openness = 255
    end
  end

  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
    update_placement if @message_window.open? && keyitem_params[:do] == 0
  end

  # 确定时的处理
  def on_ok
    result = item ? item.id : 0
    $game_variables[$game_message.item_choice_variable_id] = result
    close
  end

  # 取消时的处理
  def on_cancel
    $game_variables[$game_message.item_choice_variable_id] = 0
    close
  end
end

#==============================================================================
# ○ 追加一个帮助窗口
#==============================================================================
class Window_EagleKeyItem
  # 初始化对象
  alias eagle_keyitem_help_init initialize
  def initialize(message_window)
    eagle_keyitem_help_init(message_window)
    self.help_window = Window_Help.new(2)
    @help_window.openness = 0
  end

  # 打开
  def open
    if @help_window
      if self.y < Graphics.height / 2
        @help_window.y = Graphics.height - @help_window.height
      else
        @help_window.y = 0
      end
      @help_window.windowskin = self.windowskin
      @help_window.open
    end
    super
  end

  # 关闭
  def close
    @help_window.close if @help_window
    super
  end

  # 更新
  alias eagle_keyitem_help_update update
  def update
    eagle_keyitem_help_update
    @help_window.update if @help_window
  end
end
