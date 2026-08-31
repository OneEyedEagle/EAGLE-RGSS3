#==============================================================================
# ■ 角色选择界面 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【组件-通用方法汇总 by老鹰】与
#   【组件-位图绘制转义符文本 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-SelectActor"] = "1.0.0"
#==============================================================================
# - 2026.8.31.11 
#==============================================================================
module SELECT_ACTOR
#==============================================================================
# 【使用：在事件中选人】
#==============================================================================
#
# - 在事件指令-注释中，编写该样式文本（需作为行首）
#
#       选人|tag字符串
#
#    其中 选人 为固定的识别文本，不可缺少。
#
#    其中 tag字符串 可以为以下类型文本的任意组合，用空格分隔（可不写）：
#
#       id=所使用的模板的id（若不填，则取 default ）
#
#       模板中的其它参数，如果不含空格、只是文本，也能在此进行设置，
#       且该设置将覆写模板中的对应设置。
#       如：
#            n=4   ← 设置最多可选 4 人 
#
#------------------------------------------------
# 【常量：正则匹配表达式】
COMMENT_SELECT_ACTOR = /^选人\|(.*)/mi
  
#------------------------------------------------
# 【常量：默认模版】
PARAMS = {}  # 别删

# "default" 是一切模板的基础，此处的改动可能会作用于全部模板。
#  故实际使用时请额外增加新模板，而不是更改此处参数。
PARAMS["default"] = {
  #=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  # 【可选角色的设置】
  #=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  # - 最多能够选择的角色数量。
  :n => 1,
  #------------------------------------
  # - 是否从数据库的全部角色中挑选。
  # （1-数据库全部角色，0-仅当前队伍中角色）
  :all => 0,
  #------------------------------------
  # - 角色需符合的条件A：数据库-角色的备注栏中【必须】有其一的字符串。
  :tag => [], 
  # :tag => ["<男>", "<喜好：主角>"] 
  #  → 这样填，备注栏里有 <男> 或 <喜好：主角> 的角色才会进入可选范围。
  #------------------------------------
  # - 角色需符合的条件B：数据库-角色的备注栏中【不能】有的字符串。
  :no_tag => [],
  # :no_tag => ["<肥胖>", "<喜好：榴莲>"]
  #  → 这样填，备注栏里有 <肥胖> 或 <喜好：榴莲> 的角色不会出现在可选范围内。
  #------------------------------------
  # - 角色需符合的条件C：需要满足的脚本。
  #  如果不是nil，那 eval 后返回 true 才算满足了条件。
  #  其中可以用 a 代表当前角色 $game_actors[ID]
  :cond => nil,

  #=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  # 【UI的设置】
  #=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  # - 背景的z值。
  :z => 100,
  #------------------------------------
  # - 显示在上方的帮助文本，左对齐，可以有两行，用\n换行。
  :title => "※ 请选择角色：",
  #------------------------------------
  # - 显示在下方的帮助文本，居中对齐，可以有两行。
  #   根据角色ID会显示不同的文本，
  #   如果未设置对应角色的，则取 0 对应的文本。
  :help => {
    0 => "「选我！」",
  },
      
  #=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  # 【结果的设置】
  #=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  # - 选人结束后，第一个选择的角色的ID将存入该变量。
  #   注意：与显示顺序无关，仅看选中的先后顺序。
  :vid => 0,
}
  
#------------------------------------------------
# 【常量：一些可用的预设模版】

# 事件注释里写  选人|id=技能学习  就能使用了！
#  还可以写  选人|id=技能学习 vid=3  来设置用3号变量存储第一个选中角色的ID。
PARAMS["技能学习"] = {
  :title => "※ 请决定将技能书给谁学习：\n  （已筛选符合条件的角色：使用剑）",
  :tag => ["<武器：剑>"],  # 这样就只有备注栏里有 <武器：剑> 的角色才能选了
  :help => {
    0 => "「不会让您失望的！」",
  },
}

# 事件注释里写  选人|id=温泉  就能使用了！
PARAMS["温泉"] = {
  :title => "※ 请决定谁泡温泉：\n  （对应角色将获得 \ec[17]500\ec[0] 点经验）",
  :vid => 40,
  :help => {
    0 => "「让我去，求求了！」",
    1 => "「好久没泡温泉啦。」",
  },
}

#==============================================================================
# 【使用：在脚本中选人】
#==============================================================================
#
# - 在脚本中，调用全局脚本即可：
#
#       SELECT_ACTOR.run(params={}) { block }
#
#    其中 params 与模板中的设置一致，
#                可传入 :id 来直接使用对应的预设模板。
# 
#    其中 block 为 等待1帧 的脚本，
#         在事件中调用时，为 { Fiber.yield }
#         在Scene中调用时，为 { SceneManager.scene.update_basic }
#

#==============================================================================
# 【使用：获取选人结果】
#==============================================================================
#
# - 利用全局脚本，可以获得选人的结果：
#
#     SELECT_ACTOR.actor1   →  获取第一个选择的角色 $game_actors[ID]
#     SELECT_ACTOR.actor2   →  获取第二个选择的角色 $game_actors[ID]
#     SELECT_ACTOR.actor3   →  获取第三个选择的角色 $game_actors[ID]
#     SELECT_ACTOR.actor4   →  获取第四个选择的角色 $game_actors[ID]
#
#   如果想获得角色ID，则可以 SELECT_ACTOR.actor1.id 
#
#   如果同时还选了第五个、第六个等等，则可以直接读取选人结果的数组：
#
#     SELECT_ACTOR.last_select  → 按顺序存储了全部已选择角色
#
#   以上保存的结果将在下一次选人时清除。
#

#==============================================================================
# 【常量设置】
#==============================================================================
# 【常量：上方帮助窗口的宽度】
# （下方帮助窗口也是这个宽度）
  HELP_WINDOW_WIDTH = Graphics.width - 64

#------------------------------------------------
# 【常量：角色列表窗口的设置】
# 宽度
  ACTOR_WINDOW_WIDTH = 400

# 最大显示行数
  ACTOR_WINDOW_LINE_MAX = 8

# 显示列数
  ACTOR_WINDOW_COL_MAX = 2
  
#------------------------------------------------
# 【常量：角色列表中，已选角色的显示颜色】
# （窗口皮肤的颜色索引数字 或 Color.new）
  ACTOR_WINDOW_SELECTED_COLOR = 1

#------------------------------------------------
# 【常量：角色列表中，用于完成选择的项】

# 该项将自动添加到角色最后一行
# 文本末尾将自动加上已选人数和可选人数的统计
  ACTOR_WINDOW_FINISH = "完成√\ec[0]"

# 该项的显示颜色
# （窗口皮肤的颜色索引数字 或 Color.new）
  ACTOR_WINDOW_FINISH_COLOR = 17

# 该项的帮助文本
  HELP_TEXT_FINISH    = "完成角色选择。"

#==============================================================================
#                                 × 帮助完毕 × 
#==============================================================================

  #--------------------------------------------------------------------------
  # ● 初始化参数
  #--------------------------------------------------------------------------
  def self.run_init_params(params)
    ps0 = PARAMS["default"].dup
    
    id = params[:id]
    ps1 = PARAMS[id] || {} if id != "default"
    ps0 = ps0.merge!(ps1) if ps1
    ps0 = ps0.merge!(params)
    
    ps0[:n]   = ps0[:n].to_i
    ps0[:all] = ps0[:all].to_i == 1 ? true : false
    ps0[:z]   = ps0[:z].to_i
    ps0[:vid] = ps0[:vid] ? ps0[:vid].to_i : 0

    @params = ps0
    @flag_state = nil
    @flag_finish = false
    last_select.clear
  end
  
  #--------------------------------------------------------------------------
  # ● 执行
  #--------------------------------------------------------------------------
  def self.run(params = {}) # { 等待1帧的方法 }
    run_init_params(params)
    run_init
    run_reset_position
    run_start
    while true 
      run_update
      yield if block_given?
      break if run_finish?
    end
    run_finish
    while true 
      run_update
      yield
      break if @s_bg.opacity <= 0
    end if block_given? 
    run_dispose
  end

  #--------------------------------------------------------------------------
  # ● 全流程方法
  #--------------------------------------------------------------------------
  # 初始化
  def self.run_init
    w = SELECT_ACTOR::HELP_WINDOW_WIDTH
    @w_title = Window_EagleActorListTitle.new(w)
    @w_title.refresh(@params[:title])
    
    w = SELECT_ACTOR::ACTOR_WINDOW_WIDTH
    @w_list = Window_EagleActorList.new(0,0,w)
    @w_list.set_handler(:ok, SELECT_ACTOR.method(:method_empty))
    @w_list.set_handler(:cancel, SELECT_ACTOR.method(:method_finish))
    @w_list.reset(@params)
    
    @w_help = Window_EagleActorListHelp.new
    @w_list.help_window = @w_help
    
    @s_bg = Sprite.new
    h = @w_title.height + @w_list.height + @w_help.height
    @s_bg.bitmap = Bitmap.new(HELP_WINDOW_WIDTH, h)
    c = Color.new(0,0,0,150)
    if $imported["EAGLE-UtilsDrawing2"]
      # 如果使用了【组件-形状绘制2】，则改为圆角矩形
      @s_bg.bitmap.fill_rounded_rect(0,0,@s_bg.width,@s_bg.height, 4, c)
    else
      @s_bg.bitmap.fill_rect(0,0,@s_bg.width,@s_bg.height, c)
    end
  end
  # 角色选择框的绑定方法
  def self.method_empty
  end
  def self.method_finish
    @flag_finish = true
  end
  
  # 重设UI位置
  def self.run_reset_position
    @s_bg.opacity = 0
    @s_bg.x = (Graphics.width - @s_bg.width) / 2
    @s_bg.y = (Graphics.height - @s_bg.height) / 2
    @s_bg.z = @params[:z]
    
    @w_title.x = @s_bg.x
    @w_title.y = @s_bg.y
    @w_title.z = @s_bg.z + 10
    @w_title.opacity = @w_title.contents_opacity = 0
    
    @w_list.x = (Graphics.width - @w_list.width) / 2
    @w_list.y = @w_title.y + @w_title.height
    @w_list.z = @s_bg.z + 10
    @w_list.opacity = @w_list.contents_opacity = 0
    
    @w_help.x = @w_title.x
    @w_help.y = @w_list.y + @w_list.height
    @w_help.z = @s_bg.z + 10
    @w_help.opacity = @w_help.contents_opacity = 0
    
    [ Rect.new(@w_title.x-@s_bg.x+12,@w_title.y-@s_bg.y+@w_title.height,@w_title.width-24,1),
      Rect.new(@w_help.x-@s_bg.x+12,@w_help.y-@s_bg.y,@w_help.width-24,1),
    ].each do |r|
      @s_bg.bitmap.fill_rect(r, Color.new(255,255,255,150))
    end
  end
  
  # 开始等待玩家操作
  def self.run_start
    @flag_state = :in
    @w_list.activate
  end
  # 更新UI移入
  def self.run_update_in
    v = 12
    @s_bg.opacity += v
    @w_list.contents_opacity += v
    @w_title.contents_opacity += v
    @w_help.contents_opacity += v
    @flag_state = :wait if @s_bg.opacity >= 255
  end
  
  # 更新
  def self.run_update
    run_update_raw
    case @flag_state
    when :in;   run_update_in
    when :wait; run_update_wait
    when :out;  run_update_out
    end
  end
  # 每帧更新（基础）
  def self.run_update_raw
    @w_list.update
    if @w_list.flag_cursor_change
      @w_list.flag_cursor_change = false
      run_update_when_change 
    end
  end
  # 更新UI等待
  def self.run_update_wait
  end
  # 角色选择框光标移动后执行一次
  def self.run_update_when_change
  end
  
  # UI开始移出？
  def self.run_finish?
    @flag_finish == true
  end
  # UI移出
  def self.run_finish
    @flag_state = :out
    if @params[:vid] and @params[:vid] > 0
      if last_select[0]
        $game_variables[@params[:vid]] = last_select[0].id
      else
        $game_variables[@params[:vid]] = 0
      end
    end
  end
  # 更新UI移出
  def self.run_update_out
    v = 15
    @s_bg.opacity -= v
    @w_list.contents_opacity -= v
    @w_title.contents_opacity -= v
    @w_help.contents_opacity -= v
    @flag_state = :wait if @s_bg.opacity <= 0
  end
  
  # 释放UI
  def self.run_dispose
    @s_bg.bitmap.dispose
    @s_bg.dispose
    @w_list.dispose
    @w_title.dispose
    @w_help.dispose
  end
  
=begin 
# 扩展用
class << SELECT_ACTOR
  alias eagle_select_actor_run_init run_init
  def run_init  # 初始化
    eagle_select_actor_run_init
  end
  alias eagle_select_actor_run_reset_position run_reset_position
  def run_reset_position # 设置位置
    eagle_select_actor_run_reset_position
  end

  alias eagle_select_actor_run_start run_start
  def run_start # UI移入
    eagle_select_actor_run_start
  end
  alias eagle_select_actor_run_update_in run_update_in
  def run_update_in # 更新UI移入
    eagle_select_actor_run_update_in
  end

  alias eagle_select_actor_run_start run_start
  def run_update_raw # UI基础更新
    eagle_select_actor_run_start
  end
  alias eagle_select_actor_run_update_wait run_update_wait
  def run_update_wait # UI移动结束后更新
    eagle_select_actor_run_update_wait
  end
  alias eagle_select_actor_run_update_when_change run_update_when_change
  def run_update_when_change # 角色光标移动后执行一次
    eagle_select_actor_run_update_when_change
  end

  alias eagle_select_actor_run_finish run_finish
  def run_update_run_finish # UI移出
    eagle_select_actor_run_finish
  end
  alias eagle_select_actor_run_update_out run_update_out
  def run_update_out # 更新UI移出
    eagle_select_actor_run_update_out
  end

  alias eagle_select_actor_run_dispose run_dispose
  def run_dispose # 释放UI
    eagle_select_actor_run_dispose
  end
end
=end

  #--------------------------------------------------------------------------
  # ● 选人结果
  #--------------------------------------------------------------------------
  class << self; attr_accessor :last_select; end
  # 结果数组
  def self.last_select
    @last_select ||= []
    @last_select
  end

  # 具体获得选择的第几个角色
  def self.actor1;  last_select[0];  end
  def self.actor2;  last_select[1];  end
  def self.actor3;  last_select[2];  end
  def self.actor4;  last_select[3];  end

  #--------------------------------------------------------------------------
  # ● 读取颜色
  #--------------------------------------------------------------------------
  def self.text_color(n, windowskin = Cache.system("Window"))
    return n if n.is_a?(Color)
    n_ = n.to_i
    windowskin.get_pixel(64 + (n_ % 8) * 8, 96 + (n_ / 8) * 8)
  end
  
  #--------------------------------------------------------------------------
  # ● 判定角色条件
  #--------------------------------------------------------------------------
  # 必须有任一字符串
  def self.cond_tag(a, array)
    array.each do |t|
      # 如果有任一文本，则直接返回true
      return true if check_tag(a, t) == true
    end
    return false
  end
  
  # 不能有任一
  def self.cond_no_tag(a, array)
    array.each do |t|
      # 如果有任一文本，则直接返回false
      return false if check_tag(a, t) == true
    end
    return true
  end
  
  # 检查备注栏里是否有指定文本
  def self.check_tag(a, t)
    i = a.actor.note =~ /#{t}/mi
    return i ? true : false
  end
  
  # 脚本条件
  def self.cond_eval(a, t)
    eval(t) == true
  end

#===============================================================================
# ○ 角色选择框的窗口
#===============================================================================
class Window_EagleActorList < Window_Selectable
  attr_accessor :flag_cursor_change
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize(x, y, width, height=fitting_height(1))
    super
    @data = []
    @flag_cursor_change = true
  end

  # 获取列数
  def col_max
    return SELECT_ACTOR::ACTOR_WINDOW_COL_MAX
  end
  # 行间距的宽度
  def spacing
    return 4
  end

  # 计算窗口显示指定行数时的应用高度
  def fitting_height(line_number)
    line_number * item_height + standard_padding * 2
  end

  # 获取项目的高度
  def item_height
    line_height * 1.5
  end

  #--------------------------------------------------------------------------
  # ● 设置属性、、
  #--------------------------------------------------------------------------
  def reset(params={})
    @params = params
    refresh
  end

  # 刷新
  def refresh
    self.oy = 0
    make_item_list
    self.height = fitting_height(visible_line_number)
    create_contents
    draw_all_items
    activate
    select(0)
  end

  # 生成列表
  def make_item_list
    @data = database.select {|actor| include?(actor) }
    @data.push(nil)
  end

  # 全部角色
  def database
    if @params[:all] == true
      return $data_actors.select { |a| 
        a and a.name != "" 
      }.collect{ |a| $game_actors[a.id] }
    else 
      return $game_party.members
    end
  end

  # 查询列表中是否含有此角色
  def include?(actor)
    return false if actor == nil
    return false if !@params[:tag].empty? and !SELECT_ACTOR.cond_tag(actor, @params[:tag])
    return false if !@params[:no_tag].empty? and !SELECT_ACTOR.cond_no_tag(actor, @params[:no_tag])
    return false if @params[:cond] and !SELECT_ACTOR.cond_eval(actor, @params[:cond])
    true
  end
  
  # 获取显示行数
  def visible_line_number
    v = item_max / col_max
    v += 1 if item_max % col_max > 0
    [v, SELECT_ACTOR::ACTOR_WINDOW_LINE_MAX].min
  end

  # 获取项目数
  def item_max
    @data ? @data.size : 1
  end

  # 获取当前角色
  def item
    @data && index >= 0 ? @data[index] : nil
  end

  # 查询此物品是否可用
  def enable?(item)
    true
  end

  # 获取选择项目的有效状态
  def current_item_enabled?
    true
  end

  #--------------------------------------------------------------------------
  # ● 绘制项目
  #--------------------------------------------------------------------------
  def draw_item(index)
    rect = item_rect(index)
    rect.x += 2
    y = rect.y + (item_height - contents.font.size) / 2
    rect.width -= 4
    actor = @data[index]
    if actor == nil
      c = SELECT_ACTOR.text_color(SELECT_ACTOR::ACTOR_WINDOW_FINISH_COLOR, self.windowskin)
      t = SELECT_ACTOR::ACTOR_WINDOW_FINISH
      t += "(#{SELECT_ACTOR.last_select.size}/#{@params[:n]})"
      ps = { :x0 => rect.x, :y0 => y, :w => rect.width, :ali => 1 }
      ps[:font_color] = c
      d = Process_DrawTextEX.new(t, ps, contents)
      d.run
      return
    end
    c = normal_color
    if SELECT_ACTOR.last_select.include?(item)
      c = SELECT_ACTOR.text_color(SELECT_ACTOR::ACTOR_WINDOW_SELECTED_COLOR, self.windowskin)
    end
    ps = { :x0 => rect.x, :y0 => y, :w => rect.width, :ali => 1 }
    ps[:font_color] = c
    d = Process_DrawTextEX.new(actor.name, ps, contents)
    d.run
  end

  #--------------------------------------------------------------------------
  # ● 调用“确定”的处理方法
  #--------------------------------------------------------------------------
  def call_ok_handler
    activate
    call_handler(:ok)
    if item == nil
      call_cancel_handler
      return
    end
    if SELECT_ACTOR.last_select.include?(item)
      SELECT_ACTOR.last_select.delete(item)
    else
      if SELECT_ACTOR.last_select.size >= @params[:n]
        Sound.play_buzzer
        return
      else
        SELECT_ACTOR.last_select.push(item)
      end
    end
    redraw_current_item
    redraw_item(item_max-1)
  end

  #--------------------------------------------------------------------------
  # ● 更新帮助内容
  #--------------------------------------------------------------------------
  def update_help
    @help_window.set_actor(@params, item)
    @flag_cursor_change = true
  end
end
#===============================================================================
# ○ 上方的帮助窗口
#===============================================================================
class Window_EagleActorListTitle < Window_Base
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize(w, line_number = 2)
    super(0, 0, w, fitting_height(line_number))
  end
  #--------------------------------------------------------------------------
  # ● 刷新
  #--------------------------------------------------------------------------
  def refresh(t)
    contents.clear
    ps = { :x0 => 4, :y0 => 0, :lhd => 4 }
    d = Process_DrawTextEX.new(t, ps, contents)
    d.run
  end
end
#===============================================================================
# ○ 下方的帮助窗口
#===============================================================================
class Window_EagleActorListHelp < Window_Base
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize(line_number = 2)
    super(0, 0, SELECT_ACTOR::HELP_WINDOW_WIDTH, fitting_height(line_number))
  end
  #--------------------------------------------------------------------------
  # ● 设置内容
  #--------------------------------------------------------------------------
  def set_text(text)
    if text != @text
      @text = text
      refresh
    end
  end
  #--------------------------------------------------------------------------
  # ● 清除
  #--------------------------------------------------------------------------
  def clear
    set_text("")
  end
  #--------------------------------------------------------------------------
  # ● 设置物品
  #     item : 技能、物品等
  #--------------------------------------------------------------------------
  def set_actor(params, actor)
    if actor == nil
      t = SELECT_ACTOR::HELP_TEXT_FINISH 
    elsif params[:help]
      t = params[:help][actor.id] 
      t = params[:help][0] if t == nil
      t = "" if t == nil
    end
    set_text(t)
  end
  #--------------------------------------------------------------------------
  # ● 刷新
  #--------------------------------------------------------------------------
  def refresh
    contents.clear
    ps = { :x0 => 4, :y0 => 0, :lhd => 4, :w => contents.width, :ali => 1 }
    d = Process_DrawTextEX.new(@text, ps, contents)
    d.run
  end
end

end # end of module

#===============================================================================
# ○ Game_Interpreter
#===============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 添加注释
  #--------------------------------------------------------------------------
  alias eagle_select_actor_command_108 command_108
  def command_108
    eagle_select_actor_command_108
    t = @comments.inject { |t, v| t = t + "\n" + v }
    t.scan(SELECT_ACTOR::COMMENT_SELECT_ACTOR).each do |v|
      ps = v[0].lstrip.rstrip  # tags string  # 去除前后空格
      ps = EAGLE_COMMON.parse_tags(ps)
      ps[:cur_event_id] = @event_id
      SELECT_ACTOR.run(ps) { Fiber.yield }
    end
  end
end
