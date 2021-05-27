#==============================================================================
# ■ Add-On 序列对话 by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【对话框扩展 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-MessageSeq"] = true
#==============================================================================
# - 2021.5.27.23 修复pop的tag可能错位的bug
#==============================================================================
# - 本插件为对话框新增了自动向上/下移动的序列对话模式
#----------------------------------------------------------------------------
# 【序列对话模式】
#
#   启用时，当前对话框将保留，并且在新对话框开启时向上/下移动，
#   在一定时间后，或保留的对话框数目超过一定量时，旧的对话框将自动关闭。
#
# 【使用】
#
#   在对话框中，利用转义符 \seq[param] 来进行功能的启用/关闭。
#
# 【参数一览】
#
#   act →【默认】当传入1时，代表开启序列对话模式，传入0时，关闭该模式
#     t → 每 t 帧自动关闭一个旧对话框（若为nil，则不自动关闭）
#     n → 同时最多存在的序列对话框数目（超出时，旧的将关闭）
#   dir → 自动偏移的方向（1向下偏移，-1向上偏移，0不偏移）
#    dy → 额外的全局偏移增量
#
# 【示例】
#
#    显示对话： \pop[0]这是我要说的第一句话\seq[1]
#    显示对话： \pop[0]我还没说完呢，你别走啊
#    显示对话： \pop[0]好啦好啦，这次我说完了，你可以走了\seq[0]
#
#==============================================================================
module MESSAGE_EX
  #--------------------------------------------------------------------------
  # ● 【设置】定义转义符各参数的预设值
  # （对于bool型变量，0与false等价，1与true等价）
  #--------------------------------------------------------------------------
  SEQ_PARAMS_INIT = {
    :t => nil, # 每隔 t 帧关闭一个序列对话框（若为nil，则不会随时间关闭）
    :n => 5, # 同时最多存在的序列对话框数目（超出时，旧的将关闭）
    :dir => -1, # 自动偏移的方向（1向下偏移，-1向上偏移，0不偏移）
    :dy => 0, # 额外的全局偏移增量
  }
end
#==============================================================================
# ○ Game_Message
#==============================================================================
class Game_Message
  attr_accessor :seq_params
  #--------------------------------------------------------------------------
  # ● 获取全部可保存params的符号的数组
  #--------------------------------------------------------------------------
  alias eagle_seq_params eagle_params
  def eagle_params
    eagle_seq_params + [:seq]
  end
end
#==============================================================================
# ○ Window_EagleMessage
#==============================================================================
class Window_EagleMessage
  def seq_params; game_message.seq_params; end
  #--------------------------------------------------------------------------
  # ● 初始化参数
  #--------------------------------------------------------------------------
  alias eagle_seq_message_init_params eagle_message_init_params
  def eagle_message_init_params
    eagle_seq_message_init_params
    @flag_seq = false # 当为 true 时，当前对话框会被拷贝保留，并同步更新
    @eagle_count_seq = 0
    @eagle_seq_windows ||= [] # 时间正序存储
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  alias eagle_seq_message_dispose dispose
  def dispose
    eagle_seq_message_dispose
    @eagle_seq_windows.each { |w| w.dispose if !w.disposed? }
  end
  #--------------------------------------------------------------------------
  # ● 显示（扩展用）
  #--------------------------------------------------------------------------
  alias eagle_seq_message_show_ex show_ex
  def show_ex
    eagle_seq_message_show_ex
    @eagle_seq_windows.each { |w| w.show }
  end
  #--------------------------------------------------------------------------
  # ● 隐藏（扩展用）
  #--------------------------------------------------------------------------
  alias eagle_seq_message_hide_ex hide_ex
  def hide_ex
    eagle_seq_message_hide_ex
    @eagle_seq_windows.each { |w| w.hide }
  end
  #--------------------------------------------------------------------------
  # ● 应用对话框xywh的参数Hash的预修改
  #--------------------------------------------------------------------------
  alias eagle_seq_apply_params_xywh eagle_apply_params_xywh
  def eagle_apply_params_xywh(_p = {})
    eagle_seq_apply_params_xywh(_p)
    if _p[:open] && _p[:h] > 1 && @eagle_seq_windows.size > 0
      # 已知对话框的初始xywh和最终wh，依据o计算出它的最终xy
      r = Rect.new(self.x, self.y, self.width, self.height)
      r2 = Rect.new(0, 0, _p[:w], _p[:h])
      o = win_params[:o]
      if game_message.pop?
        o = pop_params[:o]
        o ||= 10 - pop_params[:do]
      end
      case o
      when 1,4,7
        r2.x = r.x
      when 2,5,8
        r2.x = r.x - (r2.width - r.width) / 2
      when 3,6,9
        r2.x = r.x - (r2.width - r.width)
      end
      case o
      when 7,8,9
        r2.y = r.y
      when 4,5,6
        r2.y = r.y - (r2.height - r.height) / 2
      when 1,2,3
        r2.y = r.y - (r2.height - r.height)
      end
      # 根据当前对话框的最终xy，预先将seq对话框进行移动
      @eagle_seq_windows[-1].before_set_seq_y # 进行一些预处理
      @eagle_seq_windows[-1].set_seq_y(r2.y, _p[:h])
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新复制对话框
  #--------------------------------------------------------------------------
  alias eagle_seq_update_dup_windows eagle_update_dup_windows
  def eagle_update_dup_windows
    eagle_seq_update_dup_windows
    eagle_update_seq_windows
  end
  #--------------------------------------------------------------------------
  # ● 更新序列对话框
  #--------------------------------------------------------------------------
  def eagle_update_seq_windows
    if @eagle_seq_windows.size > 0
      @eagle_seq_windows.each { |w| w.update }
      @eagle_count_seq += 1
      eagle_pop_seq_window if @eagle_seq_windows.size > seq_params[:n]
      eagle_pop_seq_window if seq_params[:t] && @eagle_count_seq > seq_params[:t]
      if @eagle_seq_windows[0].openness <= 0
        t = @eagle_seq_windows.shift
        t.dispose
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 设置/执行hold指令
  #--------------------------------------------------------------------------
  alias eagle_seq_check_hold eagle_check_hold
  def eagle_check_hold(text)
    eagle_seq_check_hold(text)
    eagle_check_seq(text)
  end
  #--------------------------------------------------------------------------
  # ● 检查seq转义符
  #--------------------------------------------------------------------------
  def eagle_check_seq(text)
    parse_pre_params(text, 'seq', seq_params, :act)
    if seq_params[:act]
      @flag_seq = MESSAGE_EX.check_bool(seq_params[:act])
      @eagle_count_seq = 0
      # 若变更为序列对话，则阻止hold
      @flag_hold = false if @flag_seq
      seq_params[:act] = nil
    end
  end
  #--------------------------------------------------------------------------
  # ● 执行seq转义符（在 process_input 之后）
  #--------------------------------------------------------------------------
  alias eagle_seq_process_hold eagle_process_hold
  def eagle_process_hold
    eagle_seq_process_hold
    @flag_seq ? eagle_push_seq_window : eagle_clear_seq_window
  end
  #--------------------------------------------------------------------------
  # ● 新增一个序列对话框
  #--------------------------------------------------------------------------
  def eagle_push_seq_window
    t = self.clone(Window_EagleMessage_Seq_Clone)
    # 重置之前存储的窗口的z值（确保最近的显示在最上面）
    @eagle_seq_windows.each_with_index do |w, i|
      w.z = t.z - (@eagle_seq_windows.size-i) * 5; w.eagle_reset_z
    end
    if w = @eagle_seq_windows[-1]
      t.last_window = w
      w.next_window = t
    end
    t.next_window = self
    @eagle_seq_windows.push(t)
    self.openness = 0
    @flag_need_open = true
  end
  #--------------------------------------------------------------------------
  # ● 移出一个序列对话框
  #--------------------------------------------------------------------------
  def eagle_pop_seq_window
    @eagle_count_seq = 0
    @eagle_seq_windows[0].close_clone if @eagle_seq_windows[0]
  end
  #--------------------------------------------------------------------------
  # ● 关闭全部序列对话框
  #--------------------------------------------------------------------------
  def eagle_clear_seq_window
    @eagle_seq_windows.each { |w| w.close_clone }
  end
end
#=============================================================================
# ○ 对话框拷贝
#=============================================================================
class Window_EagleMessage_Seq_Clone < Window_EagleMessage_Clone
  attr_accessor :last_window, :next_window
  #--------------------------------------------------------------------------
  # ● 初始化参数（只需要最初执行一次）
  #--------------------------------------------------------------------------
  def eagle_message_init_params
    super
    @seq_y = 0     # y的实际偏移值
    @flag_seq_need_update = false
    @last_window = nil # 存储上一个对话框
    @next_window = nil # 存储下一个对话框
  end
  #--------------------------------------------------------------------------
  # ● 设置xywh
  #--------------------------------------------------------------------------
  def move(x, y, w, h)
    super
    @seq_y = y
  end
  #--------------------------------------------------------------------------
  # ● 设置目的y值
  #--------------------------------------------------------------------------
  def set_seq_y(next_window_y, next_window_h)
    if seq_params[:dir] > 0
      @seq_y = next_window_y + next_window_h
    elsif seq_params[:dir] < 0
      @seq_y = next_window_y - self.height
    end
    @flag_seq_need_update = true
  end
  #--------------------------------------------------------------------------
  # ● 设置目的y值前的处理
  #--------------------------------------------------------------------------
  def before_set_seq_y
    # 隐藏掉pop的tag
    @eagle_sprite_pop_tag.visible = false
  end
  #--------------------------------------------------------------------------
  # ● 应用对话框xywh的参数Hash的预修改
  #--------------------------------------------------------------------------
  def eagle_apply_params_xywh(_p = {})
    super(_p)
    @last_window.set_seq_y(self.y, self.height) if @last_window
  end
  #--------------------------------------------------------------------------
  # ● 更新xy后的操作
  #--------------------------------------------------------------------------
  def eagle_after_update_xy
    self.y = @seq_y + seq_params[:dy] + @eagle_move_y
    super
  end
  #--------------------------------------------------------------------------
  # ● 处理纤程的主逻辑
  #--------------------------------------------------------------------------
  def fiber_main
    loop do
      if @flag_seq_need_update
        @flag_seq_need_update = false
        eagle_set_wh
      end
      Fiber.yield
      break if @fin
    end
    close_and_wait
    @fiber = nil
  end
end
