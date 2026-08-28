# 角色选择框

module SELECT_ACTOR

  COMMENT_SELECT_ACTOR = /^选人\|(.*)/mi
  
  def self.run_init_params(params)
    @params = params
    @params[:n] ||= 1 # 需要选择的角色数量
    @params[:n] = @params[:n].to_i
    @params[:all] ||= true # 是否从全数据库角色中挑选，若false，则从队伍中角色
    @params[:all] = @params[:all] == "1" ? true : false
    
    @params[:tag] ||= [] # 角色备注栏中需要有的tag
    @params[:no_tag] ||= [] # 角色备注栏中不能有的tag
    @params[:cond] ||= nil # 角色需要满足的条件
    
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
    30.times { 
      run_update
      yield
    } if block_given? and !last_select.empty?
    run_finish
    30.times { 
      run_update
      yield
    } if block_given? 
    run_dispose
  end
  
  def self.run_init
    w = 300
    @w_title = Window_EagleActorListTitle.new(w)
    @w_title.refresh(@params[:n])
    
    @w_list = Window_EagleActorList.new(0,0,w,32)
    @w_list.set_handler(:ok, SELECT_ACTOR.method(:method_empty))
    @w_list.set_handler(:cancel, SELECT_ACTOR.method(:method_finish))
    @w_list.title_window = @w_title
    @w_list.reset(@params)
  end
  
  def self.run_reset_position
    @w_list.x = Graphics.width / 2 - @w_list.width / 2
    @w_list.y = Graphics.height / 2 - @w_list.height / 2
    
    @w_title.x = @w_list.x
    @w_title.y = @w_list.y - @w_title.height
  end
  
  def self.run_start
    @w_list.open
  end
  
  def self.run_update
    @w_list.update
    @w_title.update
  end
  
  def self.run_finish?
    @flag_finish
  end
  
  def self.run_finish
    @w_list.close
    @w_title.close
  end
  
  def self.run_dispose
    @w_list.dispose
    @w_title.dispose
  end

  class << self; attr_accessor :last_select; end
  def self.last_select
    @last_select ||= []
    @last_select
  end
  
  def self.method_empty
  end
  def self.method_finish
    @flag_finish = true
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
  attr_accessor  :title_window
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize(x, y, width, height)
    super
    self.openness = 0
    @data = []
    @title_window = nil
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
    [item_max, 9].min
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
      draw_text(rect.x, rect.y, rect.width, item_height, "→ 完成选择 ←", 1)
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
    @title_window.refresh
  end

  #--------------------------------------------------------------------------
  # ● 更新帮助内容
  #--------------------------------------------------------------------------
  def update_help
    @help_window.set_item(item)
  end
end


class Window_EagleActorListTitle < Window_Base
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize(w, line_number = 2)
    super(0, 0, w, fitting_height(line_number))
    @n = nil
  end
  #--------------------------------------------------------------------------
  # ● 刷新
  #--------------------------------------------------------------------------
  def refresh(n = nil)
    @n = n if n
    contents.clear
    t = "※ 请选择角色：\n"
    t += "（最多 \ec[17]#{@n}\ec[0]，已选 \ec[17]#{SELECT_ACTOR.last_select.size}\ec[0]）"
    draw_text_ex(4, 0, t)
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

