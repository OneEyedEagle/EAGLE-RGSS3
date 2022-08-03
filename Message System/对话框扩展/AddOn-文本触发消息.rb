#==============================================================================
# ■ Add-On 文本触发消息 by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【对话框扩展 by老鹰】与【事件消息机制 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-MessageCallMsg"] = "1.0.0"
#==============================================================================
# - 2022.7.23.21
#==============================================================================
# - 本插件为对话框新增了文字选择模式，并且可以触发当前事件页的消息
#----------------------------------------------------------------------------
# 【文字选择模式】
#
# - 在对话框显示完全部文本，等待按键继续时，按下 SHIFT 键将进入文字选择模式：
#
#  1. 对话框中心出现一个方框光标，利用方向键进行移动
#
#  2. 按下确定键（空格键）时将会触发当前被选中的文字
#
#  3. 如果文字有设置消息属性，则会触发当前页中对应的消息，并等待消息执行结束
#
#  4. 如果文字没有设置消息，则会在轻微抖动后结束
#
#  5. 按下 SHIFT 键将回到等待按键继续的状态
#
#----------------------------------------------------------------------------
# 【设置消息属性】
#
# - 编写转义符组 \msg[消息]文本\msg[0] 将为其中的 文本 设置对应的消息
#
#  · 在被光标选中并触发时，将查找当前事件页中的标签内容为“消息”的指令，
#       并等待执行结束，才能继续进行文字选择；
#     如果未找到对应的消息，则不会有任何动作
#
#  · “文本”将会被增加一些绘制属性，用于特别标识
#
#----------------------------------------------------------------------------
# 【示例】
#
# - 显示文本：
#
#     这是一句\msg[消息触发]测试用\msg[0]的文本，没有什么特别的。
#
# - 实际操作：
#
#     文字显示完后，按下 SHIFT 键，并把光标移动到 测试用 之上，按下确定键，
#     将触发当前事件页中的“消息触发”的消息，并等待消息执行结束
#
#----------------------------------------------------------------------------
# 【注意】
#
# - 由于在触发消息时，对话框还在等待中（并未关闭），所以消息中不要使用对话框！
#   否则会直接卡住事件流程，无法再继续！
#
# - 可以使用类似于【并行式对话 by老鹰】或【聊天式对话 by老鹰】等新类型的对话
#
#==============================================================================
module MESSAGE_EX
  #--------------------------------------------------------------------------
  # ○ 按键进入/退出文本选择模式
  #--------------------------------------------------------------------------
  def self.selcha_call?
    Input.trigger?(:A)
  end
  #--------------------------------------------------------------------------
  # ○ 在文本选择模式中，按键触发当前选中文字的消息
  #--------------------------------------------------------------------------
  def self.selcha_activate_msg?
    Input.trigger?(:C)
  end

  #--------------------------------------------------------------------------
  # ○ 针对\msg[消息]转义符，额外增加的文本
  # （转义符需要用 \\ 代替 \）（用来明显表现这个词语可以被触发）
  #--------------------------------------------------------------------------
  SELCHA_TEXT_PREFIX = "\\font[u1]"
  #--------------------------------------------------------------------------
  # ○ 针对\msg[0]转义符，额外增加的文本
  # （转义符需要用 \\ 代替 \）（用来关闭上一个常量的特效）
  #--------------------------------------------------------------------------
  SELCHA_TEXT_SURFIX = "\\font[u0]"

  #--------------------------------------------------------------------------
  # ○ 选择光标的宽、高、边框宽度、边框颜色
  #--------------------------------------------------------------------------
  SELCHA_CURSOR_W = 20
  SELCHA_CURSOR_H = 20
  SELCHA_CURSOR_D = 2
  SELCHA_CURSOR_C = Color.new(255,25,25,255)

  #--------------------------------------------------------------------------
  # ○ 对于存在消息的文本，在触发消息时将执行的方法
  #--------------------------------------------------------------------------
  #  charas 为 [具有相同msg的全部文字精灵的数组]
  def self.selcha_activate_chara_effects(charas)
    # 开启闪烁
    charas.each { |s| s.start_effect("cflash".to_sym, "r255g255b0d60t10") }
  end
  #--------------------------------------------------------------------------
  # ○ 消息执行结束时，文本将执行的方法
  #--------------------------------------------------------------------------
  def self.selcha_deactivate_chara_effects(charas)
    # 关闭闪烁
    charas.each { |s| s.finish_effect("cflash".to_sym);
      s.flash(Color.new(255,255,255,0), 1) }
  end
  #--------------------------------------------------------------------------
  # ○ 对于不存在消息的文本，在触发时将执行的方法
  #--------------------------------------------------------------------------
  #  chara 为 被选中的文字精灵
  def self.selcha_activate_chara_effects_no_msg(chara)
    # 抖动，等待10帧后关闭特效
    chara.start_effect("cshake".to_sym, "l2r2u0d0vxt1")
    10.times { Fiber.yield }
    chara.finish_effect("cshake".to_sym)
    chara.reset_dxy(0, 0)
  end
end

class Window_EagleMessage
  #--------------------------------------------------------------------------
  # ● 初始化组件
  #--------------------------------------------------------------------------
  alias eagle_msg_select_charas_init_params eagle_message_init_params
  def eagle_message_init_params
    @eagle_msgs = [] # [msg]
    eagle_msg_select_charas_init_params
  end
  #--------------------------------------------------------------------------
  # ● 重置对话框（对话框不关闭，清空全部设置，并继续显示）
  #--------------------------------------------------------------------------
  alias eagle_msg_select_charas_reset_continue eagle_message_reset_continue
  def eagle_message_reset_continue
    @eagle_msgs.clear
    eagle_msg_select_charas_reset_continue
  end
  #--------------------------------------------------------------------------
  # ● 替换转义符（此时依旧是 \\ 开头的转义符）
  #--------------------------------------------------------------------------
  alias eagle_msg_select_charas_process_conv eagle_process_conv
  def eagle_process_conv(text)
    text = eagle_msg_select_charas_process_conv(text)
    @eagle_msgs.push(0)  # 首位固定不使用
    text.gsub!(/\\msg\[(.*?)\]/i) {
      if $1 != '0'
        @eagle_msgs.push($1)
        "\\msg[#{@eagle_msgs.size-1}]" + MESSAGE_EX::SELCHA_TEXT_PREFIX
      else
        "\\msg[0]" + MESSAGE_EX::SELCHA_TEXT_SURFIX
      end
    }
    text
  end
  #--------------------------------------------------------------------------
  # ● 绘制完成时的处理
  #--------------------------------------------------------------------------
  alias eagle_msg_select_charas_process_draw_end eagle_process_draw_end
  def eagle_process_draw_end(c_w, c_h, pos)
    eagle_msg_select_charas_process_draw_end(c_w, c_h, pos)
    if @flag_draw && @eagle_cur_msg
      @eagle_chara_sprites[-1].msg = @eagle_cur_msg
    end
  end
  #--------------------------------------------------------------------------
  # ● 处理msg转义符
  #--------------------------------------------------------------------------
  def eagle_text_control_msg(param = '0')
    return if !@flag_draw
    return @eagle_cur_msg = nil if param == '0'
    @eagle_cur_msg = @eagle_msgs[param.to_i]
  end
  #--------------------------------------------------------------------------
  # ● 等待按键时，按键继续的处理
  #--------------------------------------------------------------------------
  alias eagle_msg_select_charas_process_input_pause_key process_input_pause_key
  def process_input_pause_key
    process_select_charas if MESSAGE_EX.selcha_call?
    eagle_msg_select_charas_process_input_pause_key
  end
  #--------------------------------------------------------------------------
  # ● 处理文字选择
  #--------------------------------------------------------------------------
  def process_select_charas
    s_player = Sprite_MsgSelectCharas_Cursor.new(@eagle_chara_viewport)
    rect_max = @eagle_chara_viewport.rect
    params_player = {}
    last_chara = nil
    last_chara_i = 0
    Input.update
    while true
      Fiber.yield
      break if MESSAGE_EX.selcha_call?
      # 更新移动
      s = s_player
      if params_player[:last_input] == Input.dir4
        params_player[:last_input_c] += 1
        params_player[:d] += 1 if params_player[:last_input_c] % 5 == 0
      else
        params_player[:d] = 1
        params_player[:last_input] = Input.dir4
        params_player[:last_input_c] = 0
      end
      d = params_player[:d]
      if Input.press?(:UP)
        s.y -= d
        s.y = s.oy if s.y - s.oy < 0
      elsif Input.press?(:DOWN)
        s.y += d
        s.y = rect_max.height - s.height + s.oy if s.y - s.oy + s.height > rect_max.height
      elsif Input.press?(:LEFT)
        s.x -= d
        s.x = s.ox if s.x - s.ox < 0
      elsif Input.press?(:RIGHT)
        s.x += d
        s.x = rect_max.width - s.width + s.ox if s.x - s.ox + s.width > rect_max.width
      end
      # 更新选中
      if last_chara && s.overlap?(last_chara)
      else
        last_chara = nil
        @eagle_chara_sprites.each_with_index do |c, i|
          next if !s.overlap?(c)
          last_chara_i = i
          break last_chara = c
        end
      end
      next if last_chara == nil
      # 更新功能按键
      if MESSAGE_EX.selcha_activate_msg?
        m = last_chara.msg
        if m
          # 查找拥有相同msg的文字
          charas_ = search_charas_with_same_msg(last_chara, last_chara_i)
          # 开启文字特效
          MESSAGE_EX.selcha_activate_chara_effects(charas_)
          Fiber.yield
          # 触发对应消息
          e = $game_map.events[game_message.event_id]
          e.msg(last_chara.msg)
          Fiber.yield
          Fiber.yield while e.msg?(last_chara.msg)
          # 关闭文字特效
          MESSAGE_EX.selcha_deactivate_chara_effects(charas_)
          Fiber.yield
        else # 不存在msg
          MESSAGE_EX.selcha_activate_chara_effects_no_msg(last_chara)
        end
      end
    end
    Input.update
    s_player.dispose
  end
  #--------------------------------------------------------------------------
  # ● 寻找有相同msg的文字精灵
  #--------------------------------------------------------------------------
  def search_charas_with_same_msg(start_chara, start_index)
    m = start_chara.msg
    charas = [start_chara]
    i = start_index
    while i >= 0
      i -= 1
      if @eagle_chara_sprites[i].msg == m
        charas.unshift(@eagle_chara_sprites[i])
      end
    end
    i = start_index
    while i < @eagle_chara_sprites.size
      i += 1
      if @eagle_chara_sprites[i] && @eagle_chara_sprites[i].msg == m
        charas.push(@eagle_chara_sprites[i])
      end
    end
    return charas
  end
end
#==============================================================================
# ■ 光标精灵
#==============================================================================
class Sprite_MsgSelectCharas_Cursor < Sprite
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(vp)
    super(vp)
    reset_bitmap
    reset_position
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    self.bitmap.dispose
    super
  end
  #--------------------------------------------------------------------------
  # ● 重绘位图
  #--------------------------------------------------------------------------
  def reset_bitmap
    w = MESSAGE_EX::SELCHA_CURSOR_W
    h = MESSAGE_EX::SELCHA_CURSOR_H
    self.bitmap = Bitmap.new(w, h)
    self.bitmap.fill_rect(0, 0, w, h, MESSAGE_EX::SELCHA_CURSOR_C)
    d = MESSAGE_EX::SELCHA_CURSOR_D
    self.bitmap.clear_rect(d, d, w-d*2, h-d*2)
  end
  #--------------------------------------------------------------------------
  # ● 重置位置
  #--------------------------------------------------------------------------
  def reset_position
    self.ox = self.width / 2
    self.oy = self.height / 2
    self.x = self.viewport.rect.width / 2
    self.y = self.viewport.rect.height / 2
    self.z = 500
  end
  #--------------------------------------------------------------------------
  # ● 指定sprite位于当前精灵上？
  #  （需要确保在同一 viewport 中）
  #--------------------------------------------------------------------------
  def overlap?(sprite)
    pos_x = sprite.x - sprite.ox + sprite.width / 2
    pos_y = sprite.y - sprite.oy + sprite.height / 2
    return false if pos_x < self.x - self.ox
    return false if pos_y < self.y - self.oy
    return false if pos_x > self.x - self.ox + self.width
    return false if pos_y > self.y - self.oy + self.height
    return true
  end
end
#==============================================================================
# ■ 文字精灵
#==============================================================================
class Sprite_EagleCharacter < Sprite
  attr_accessor  :msg
  #--------------------------------------------------------------------------
  # ● 重置
  #--------------------------------------------------------------------------
  alias eagle_msg_select_charas_reset reset
  def reset(x, y, w, h)
    eagle_msg_select_charas_reset(x, y, w, h)
    @msg = nil
  end
end
