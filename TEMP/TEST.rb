# 角色选择框

module SELECT_ACTOR

  COMMENT_SELECT_ACTOR = /^选人\|(.*)/mi
  
  PARAMS = {}
  
  PARAMS["default"] = {
    # 需要选择的角色数量
    :n   => 1,
    
    # 是否从全数据库角色中挑选（1全数据库，0仅队伍中角色）
    :all => 0,
    
    # 角色的数据库备注栏中【必须】有的字符串
    :tag => [], # ["<男>", "<喜好：主角>"] ← 这样填写
    
    # 角色的数据库备注栏中【不能】有的字符串
    :no_tag => [],  # ["<肥胖>", "<喜好：榴莲>"] ← 有这些字符串的角色不会出现
    
    # 角色需要满足的条件
    #  如果不是nil，那 eval 后返回 true 才算满足条件
    #  其中可以用 a 代表当前角色 $data_actors[ID]
    :cond => nil,
      
    # 背景的z值
    :z => 100,
    # 显示在顶上的帮助文本，可以有两行
    :title => "※ 请选择角色：",
    # 根据角色ID，显示不同的帮助文本，可以有两行
    :help => {
      0 => "「选我！」",  # 如果没找到对应角色的，则取这个帮助文本
    },
      
    # 选择完成后，第一个选择的角色的ID将存入该变量
    :vid => 0,
  }
  
  PARAMS["温泉"] = {
    :title => "※ 请决定由谁体验温泉：\n   （对应角色将获得 \ec[17]500\ec[0] 点经验）",
    :vid => 40,
    :help => {
      0 => "「选我！」",
      1 => "「好久没泡温泉啦~」",
    },
  }
  
  HELP_WINDOW_WIDTH = Graphics.width - 64
  ACTOR_WINDOW_WIDTH = 300
  
  ACTOR_WINDOW_LINE_MAX = 8
  
  COMMAND_TEXT_FINISH = "→ 完成 " # 将自动加上已选人数和可选人数
  HELP_TEXT_FINISH    = "完成角色选择。"
  

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
  
  def self.run(params = {}) # { 用于等待1帧的方法 }
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
  
  def self.run_init
    w = SELECT_ACTOR::HELP_WINDOW_WIDTH
    @w_title = Window_EagleActorListTitle.new(w)
    @w_title.refresh(@params[:title])
    
    w = SELECT_ACTOR::ACTOR_WINDOW_WIDTH
    @w_list = Window_EagleActorList.new(0,0,w,32)
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
  
  def self.method_empty
  end
  def self.method_finish
    @flag_finish = true
  end
  
  
  def self.run_reset_position
    @s_bg.opacity = 0
    @s_bg.x = (Graphics.width - @s_bg.width) / 2
    @s_bg.y = (Graphics.height - @s_bg.height) / 2
    @s_bg.z = @params[:z]
    
    @w_title.x = @s_bg.x
    @w_title.y = @s_bg.y
    @w_title.z = @s_bg.z + 1
    @w_title.opacity = @w_title.contents_opacity = 0
    
    @w_list.x = (Graphics.width - @w_list.width) / 2
    @w_list.y = @w_title.y + @w_title.height
    @w_list.z = @s_bg.z + 1
    @w_list.opacity = @w_list.contents_opacity = 0
    
    @w_help.x = @w_title.x
    @w_help.y = @w_list.y + @w_list.height
    @w_help.z = @s_bg.z + 1
    @w_help.opacity = @w_help.contents_opacity = 0
    
    [ Rect.new(@w_title.x-@s_bg.x+12,@w_title.y-@s_bg.y+@w_title.height,@w_title.width-24,1),
      Rect.new(@w_help.x-@s_bg.x+12,@w_help.y-@s_bg.y,@w_help.width-24,1),
    ].each do |r|
      @s_bg.bitmap.fill_rect(r, Color.new(255,255,255,150))
    end
  end
  
  def self.run_start
    @flag_state = :in
    @w_list.activate
  end
  
  def self.run_update
    run_update_raw
    case @flag_state
    when :in;   run_update_in
    when :wait; run_update_wait
    when :out;  run_update_out
    end
  end
  
  def self.run_update_raw
    @w_list.update
  end
  
  def self.run_update_in
    v = 12
    @s_bg.opacity += v
    @w_list.contents_opacity += v
    @w_title.contents_opacity += v
    @w_help.contents_opacity += v
    @flag_state = :wait if @s_bg.opacity >= 255
  end
  
  def self.run_update_wait
  end
  
  def self.run_update_out
    v = 15
    @s_bg.opacity -= v
    @w_list.contents_opacity -= v
    @w_title.contents_opacity -= v
    @w_help.contents_opacity -= v
    @flag_state = :wait if @s_bg.opacity <= 0
  end
  
  def self.run_finish?
    @flag_finish == true
  end
  
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
  
  def self.run_dispose
    @s_bg.bitmap.dispose
    @s_bg.dispose
    @w_list.dispose
    @w_title.dispose
    @w_help.dispose
  end
  

  class << self; attr_accessor :last_select; end
  def self.last_select
    @last_select ||= []
    @last_select
  end
  
  def self.cond_tag(a, array)
    array.each do |t|
      # 如果没有指定文本，则直接返回false
      return false if check_tag(a, t) == false
    end
    return true
  end
  
  def self.cond_no_tag(a, array)
    array.each do |t|
      # 如果有指定文本，则直接返回false
      return false if check_tag(a, t) == true
    end
    return true
  end
  
  # 检查备注栏里是否有指定文本
  def self.check_tag(a, t)
    i = a.note =~ /#{t}/mi
    return i ? true : false
  end
  
  def self.cond_eval(a, t)
    eval(t) == true
  end

class Window_EagleActorList < Window_Selectable
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize(x, y, width, height)
    super
    @data = []
  end

  # 获取列数
  def col_max
    return 1
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
    @params[:all] == true ? $data_actors : $game_party.members
  end

  # 查询列表中是否含有此角色
  def include?(actor)
    return false if actor == nil
    return false if actor.name == ""
    return false if !@params[:tag].empty? and !SELECT_ACTOR.cond_tag(actor, @params[:tag])
    return false if !@params[:no_tag].empty? and !SELECT_ACTOR.cond_no_tag(actor, @params[:no_tag])
    return false if @params[:cond] and !SELECT_ACTOR.cond_eval(actor, @params[:cond])
    true
  end
  
  # 获取显示行数
  def visible_line_number
    [item_max, SELECT_ACTOR::ACTOR_WINDOW_LINE_MAX].min
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
    rect.width -= 4
    actor = @data[index]
    if actor == nil
      change_color(text_color(17))
      t = SELECT_ACTOR::COMMAND_TEXT_FINISH
      t += "(#{SELECT_ACTOR.last_select.size}/#{@params[:n]})"
      draw_text(rect.x, rect.y, rect.width, item_height, t, 1)
      return
    end
    change_color(normal_color)
    if SELECT_ACTOR.last_select.include?(item)
      change_color(text_color(17))
    end
    draw_text(rect.x, rect.y, rect.width, item_height, actor.name, 1)
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
  end
end


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
