#==============================================================================
# ■ Add-On 序列对话 by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【对话框扩展 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-MessagePara"] = true
#==============================================================================
# - 2020.6.18.20
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
#     n → 同时最多存在的序列对话框数目（超出时，旧的将关闭）
#   dir → 自动偏移的方向（1向下偏移，-1向上偏移，0不偏移）
#    dy → 额外的偏移增量
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
    :t => 120, # 每隔 t 帧关闭一个序列对话框（若为nil，则不会随时间关闭）
    :n => 5, # 同时最多存在的序列对话框数目（超出时，旧的将关闭）
    :dir => -1, # 自动偏移的方向（1向下偏移，-1向上偏移，0不偏移）
    :dy => 0, # 额外的偏移增量
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
# ○ Window_Message
#==============================================================================
class Window_Message
  def seq_params; game_message.seq_params; end
  #--------------------------------------------------------------------------
  # ● 初始化组件
  #--------------------------------------------------------------------------
  alias eagle_seq_message_init_assets eagle_message_init_assets
  def eagle_message_init_assets
    eagle_seq_message_init_assets
    @eagle_seq_windows ||= [] # 时间正序存储
  end
  #--------------------------------------------------------------------------
  # ● 打开直至完成（当有文字绘制完成时执行）
  #--------------------------------------------------------------------------
  alias eagle_seq_open_and_wait eagle_open_and_wait
  def eagle_open_and_wait
    eagle_seq_open_and_wait
    @eagle_seq_windows.each { |w| w.add_new_window_h(self.height) }
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
      seq_params[:tc] += 1
      eagle_pop_seq_window if @eagle_seq_windows.size > seq_params[:n]
      eagle_pop_seq_window if seq_params[:t] && seq_params[:tc] > seq_params[:t]
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
    seq_params[:act] = MESSAGE_EX.check_bool(seq_params[:act])
    seq_params[:tc] = 0
    # 若变更为了序列对话，则阻止hold
    game_message.hold = false if seq_params[:act]
  end
  #--------------------------------------------------------------------------
  # ● 执行seq转义符（在 process_input 之后）
  #--------------------------------------------------------------------------
  alias eagle_seq_process_hold eagle_process_hold
  def eagle_process_hold
    eagle_seq_process_hold
    seq_params[:act] ? eagle_push_seq_window : eagle_clear_seq_window
  end
  #--------------------------------------------------------------------------
  # ● 新增一个序列对话框
  #--------------------------------------------------------------------------
  def eagle_push_seq_window
    t = self.clone(Window_Message_Seq_Clone)
    # 重置之前存储的窗口的z值（确保最近的显示在最上面）
    @eagle_seq_windows.each_with_index do |w, i|
      w.z = t.z - (@eagle_seq_windows.size-i) * 5; w.eagle_reset_z
    end
    @eagle_seq_windows.push(t)
    self.opacity = 0
    self.openness = 0
  end
  #--------------------------------------------------------------------------
  # ● 移出一个序列对话框
  #--------------------------------------------------------------------------
  def eagle_pop_seq_window
    seq_params[:tc] = 0
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
class Window_Message_Seq_Clone < Window_Message_Clone
  #--------------------------------------------------------------------------
  # ● 初始化组件
  #--------------------------------------------------------------------------
  def eagle_message_init_assets
    super
    @seq_des_dy = 0 # y的最终偏移值
    @seq_dy = 0     # y的实际偏移值
  end
  #--------------------------------------------------------------------------
  # ● 增加偏移量
  #--------------------------------------------------------------------------
  def add_new_window_h(h)
    @seq_des_dy += h
  end
  #--------------------------------------------------------------------------
  # ● 更新xy后的处理
  #--------------------------------------------------------------------------
  def eagle_after_update_xy
    if seq_params[:dir] > 0
      self.y += @seq_dy
    elsif seq_params[:dir] < 0
      self.y -= @seq_dy
    end
    self.y += seq_params[:dy]
    super
  end
  #--------------------------------------------------------------------------
  # ● 更新自身作为序列窗口的位置
  #--------------------------------------------------------------------------
  def reset_seq_window_xy
    d_y = @seq_des_dy - @seq_dy
    return if d_y == 0
    seq_dy_init = @seq_dy # 记录开始偏移时的y已有的偏移值
    _i = 0; _t = 20
    while(true)
      break if _i >= _t
      per = _i * 1.0 / _t
      per = (_i == _t ? 1 : (1 - 2**(-10 * per)))
      @seq_dy = (seq_dy_init + d_y * per)
      _i += 1
      eagle_win_update
      Fiber.yield
    end
  end
  #--------------------------------------------------------------------------
  # ● 处理纤程的主逻辑
  #--------------------------------------------------------------------------
  def fiber_main
    eagle_set_wh # 由于pause精灵需要去除，增加更新宽高
    loop do
      Fiber.yield
      reset_seq_window_xy
      break if @fin
    end
    close_and_wait
    @fiber = nil
  end
end
