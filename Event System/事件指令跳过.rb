#==============================================================================
# ■ 事件指令跳过 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
$imported ||= {}
$imported["EAGLE-EventCommandSkip"] = true
#==============================================================================
# - 2020.7.26.19 优化
#==============================================================================
# - 本插件利用标签，新增了事件指令的跳过
#--------------------------------------------------------------------------
# - 在开始跳过判定的指令前新增标签，内容为 SKIP ，
#   在结束跳过判定的指令后新增标签，内容为 SKIPEND ，
#   则在执行 SKIP 与 SKIPEND 之间的指令时，按下按键即可快速跳过中间的指令。
#
# - 示例：
#    当前地图的 1 号事件的第 1 页中指令列表
#    |- 标签：SKIP
#    |- 显示文字：测试语句1
#    |- 显示心情：惊讶
#    |- 显示文字：测试语句2
#    |- 标签：SKIPEND
#    |- 显示文字：测试语句3
#
#    在一般执行时，依次显示 测试语句1、惊讶、测试语句2、测试语句3 ；
#    若在显示 测试语句1 时按下按键（脚本预设为Shift键），则跳过之间指令，
#      而继续显示 测试语句3 。
#
# - 在判定跳过成功时，需要执行的指令前新增标签，内容为 SKIPTHEN ，
#   若成功跳过，转而执行 SKIPTHEN 与 SKIPEND 之间的指令，
#   若未跳过，则不执行之间的指令。
#
# - 示例：
#    当前地图的 1 号事件的第 2 页中指令列表
#    |- 标签：SKIP
#    |- 显示文字：测试语句1
#    |- 显示文字：测试语句2
#    |- 标签：SKIPTHEN
#    |- 显示文字：测试语句3
#    |- 标签：SKIPEND
#    |- 显示文字：测试语句4
#
#    在一般执行时，依次显示 测试语句1、测试语句2、测试语句4 ；
#    若在显示 测试语句1 时按下按键（脚本预设为Shift键），
#      则跳过 测试语句2，显示 测试语句3 ，并继续显示 测试语句4。
#
# - 【推荐】若同时使用了【对话框扩展 by老鹰】，将在按键时立即关闭当前对话框
#     （含选择框、数值输入框、物品选择框、金钱框）
# - 【推荐】若同时使用了【显示动画扩展 by老鹰】，将在按键时立即中止全部动画
#==============================================================================

module COMMAND_SKIP
  #--------------------------------------------------------------------------
  # ● 【常量】跳过开始的标签内容（完全匹配）
  #--------------------------------------------------------------------------
  LABEL_SKIP = "SKIP"
  #--------------------------------------------------------------------------
  # ● 【常量】跳过时需要执行的标签内容（完全匹配）
  #--------------------------------------------------------------------------
  LABEL_THEN = "SKIPTHEN"
  #--------------------------------------------------------------------------
  # ● 【常量】跳过结束的标签内容（完全匹配）
  #--------------------------------------------------------------------------
  LABEL_END = "SKIPEND"
  #--------------------------------------------------------------------------
  # ● 判定按键
  #--------------------------------------------------------------------------
  def self.trigger?
    Input.trigger?(:A) || @need_skip
  end
  #--------------------------------------------------------------------------
  # ● 设置提示文本精灵
  #--------------------------------------------------------------------------
  def self.set_skip_hint(sprite)
    text = "按 Shift 跳过"
    w = 16 * 9
    sprite.bitmap = Bitmap.new(w, 18)
    sprite.bitmap.font.size = 16
    sprite.bitmap.fill_rect(0,17,w,1, Color.new(255,255,255,220))
    sprite.bitmap.draw_text(0,1,sprite.width,sprite.height,text, 1)

    sprite.x = 15
    sprite.y = 15
  end
  #--------------------------------------------------------------------------
  # ● 精灵操作
  #--------------------------------------------------------------------------
  class << self
    attr_reader :sprite_hint
  end
  def self.init_hint
    if @hint_show_count.nil?
      @sprite_hint.dispose if @sprite_hint
      @sprite_hint = Sprite.new
      set_skip_hint(@sprite_hint)
      @sprite_hint.visible = false
    end
  end
  def self.show_hint
    @sprite_hint.visible = true
    @need_skip = false
  end
  def self.hide_hint
    @sprite_hint.visible = false
    @need_skip = nil
  end
  #--------------------------------------------------------------------------
  # ● 能够执行跳过？
  #--------------------------------------------------------------------------
  def self.skippable?
    @need_skip != nil
  end
  #--------------------------------------------------------------------------
  # ● 执行跳过
  #--------------------------------------------------------------------------
  @need_skip = nil
  def self.call
    @need_skip = true
  end
end
#=============================================================================
# ○ Game_Interpreter
#=============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 执行
  #--------------------------------------------------------------------------
  alias eagle_skip_run run
  def run
    COMMAND_SKIP.init_hint
    @eagle_skip_begin_i = nil # 记录skip开始标签的指令位置
    eagle_skip_run
  end
  #--------------------------------------------------------------------------
  # ● 更新画面
  #--------------------------------------------------------------------------
  alias eagle_skip_update update
  def update
    eagle_skip_update
    eagle_process_skip if @eagle_skip_begin_i && COMMAND_SKIP.trigger?
  end
  #--------------------------------------------------------------------------
  # ● 添加标签
  #--------------------------------------------------------------------------
  alias eagle_skip_command_118 command_118
  def command_118
    if @params[0] == COMMAND_SKIP::LABEL_SKIP
      COMMAND_SKIP.show_hint
      @eagle_skip_begin_i = @index
    elsif @eagle_skip_begin_i && @params[0] == COMMAND_SKIP::LABEL_THEN
      eagle_goto_label(COMMAND_SKIP::LABEL_END)
      COMMAND_SKIP.hide_hint
      @eagle_skip_begin_i = nil
    elsif @params[0] == COMMAND_SKIP::LABEL_END
      COMMAND_SKIP.hide_hint
    end
    eagle_skip_command_118
  end
  #--------------------------------------------------------------------------
  # ● 跳转标签（限定范围）
  #--------------------------------------------------------------------------
  def eagle_goto_label(label_name, i_begin = @index, i_end = @list.size-1)
    i = i_begin
    while i <= i_end
      if @list[i].code == 118 && @list[i].parameters[0] == label_name
        @index = i
        return true
      end
      i += 1
    end
    return false
  end
  #--------------------------------------------------------------------------
  # ● 处理跳过
  #--------------------------------------------------------------------------
  def eagle_process_skip
    @eagle_skip_begin_i = nil
    if !eagle_goto_label(COMMAND_SKIP::LABEL_THEN)
      eagle_goto_label(COMMAND_SKIP::LABEL_END)
    end
    COMMAND_SKIP.hide_hint
    if $imported["EAGLE-MessageEX"]
      window = SceneManager.scene.message_window
      window.force_close if window.open?
    end
    if $imported["EAGLE-AnimEX"]
      ANIM_EX.all_chara_sprites.each { |s| s.stop_animation }
      ANIM_EX.stop_all
    end
  end
end
