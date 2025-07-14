# 角色属性对应： 
#  魔力上限 - 精力
#  物理攻击 - 力
#  魔法攻击 - 智
#  敏捷 - 敏

module TASK


  @@flag_init = false
  def self.init
    return if @@flag_init 
    @@flag_init = true
    @data_raw = [] 
    CSV.foreach("1.csv") do |row|
      # use row here...
      @data_raw.push(row)
    end
    $game_party.tasks ||= [] 
    $game_party.tasks.each do |d|
      row = @data_raw[d.id]
      d.parse(row)
    end
  end

  def self.new_data(id)
    d = Data.new(id)
    d.parse(@data_raw[id])
    return d
  end

  def self.new_day 
    TASK.init
    $game_party.tasks ||= [] 
    $game_party.tasks.delete_if do |d|
      ! d.flag_check
    end

    $game_party.tasks.each do |d|
      d.on_new_day
    end
    3.times do |i| 
      $game_party.tasks.push(TASK.new_data(i+1))
    end
  end 

class Data 
  attr_reader   :id
  attr_accessor :name, :intro, :label, :cond, :level, :cost
  attr_accessor :flag_delay, :delay_count, :flag_check
  attr_accessor :result, :result_actor
  def initialize(id)
    @id = id 
    @flag_delay = false
    @flag_check = false 
    @result = nil
    @result_actor = nil

    @delay_count = 0 # 已推延次数
    @delay_need = [0,0,0] # 因为推延而增加的属性要求
    @delay_reward_exp  = 0 # 因为推延而增加的奖励-经验
    @delay_reward_gold = 0 # 因为推延而增加的奖励-金币
    @delay_reward_item_add = [] # 因为推延而增加的物品
    @delay_reward_item_lose = [] # 因为推延而减少的物品
  end 
  def parse(row)
    return if row[0].to_i != @id
    @name = row[1] || ""
    @intro = row[2] || ""
    @label = []
    @label = row[3].split('|') if row[3]
    @cond = row[4] || ""
    @level = 0
    @level = row[5].to_i if row[5]
    @cost = 1
    @cost = row[6].to_i if row[6]
    @need = [0,0,0]
    @need[0] = row[7].to_i if row[7]
    @need[1] = row[8].to_i if row[8]
    @need[2] = row[9].to_i if row[9]
    @eval_finish = row[10] || ""
    @reward_exp = 0
    @reward_exp = row[11].to_i if row[11]
    @reward_gold = 0
    @reward_gold = row[12].to_i if row[12]
    @reward_item = []
    if row[13]
    end
    @eval_delay = row[14] || ""
    @max_delay = 0
    @max_delay = row[15].to_i if row[15]
    @eval_fail = row[16] || ""
  end

  def on_new_day
    @flag_delay = false
    @flag_check = false 
    @result = nil
    @result_actor = nil
  end

  attr_reader :need, :delay_need
  def get_need(id=0)
    @need[id] + @delay_need[id]
  end

  attr_reader :reward_exp, :delay_reward_exp, :reward_gold, :delay_reward_gold
  def get_reward(type=:exp)
    case type 
    when :exp 
      return [@reward_exp + @delay_reward_exp, 0].max
    when :gold 
      return [@reward_gold + @delay_reward_gold, 0].max
    end
  end

  def run_eval(type=:success, actor=nil)
    v = $game_variables
    s = $game_switches
    case type 
    when :success
      eval(@eval_finish)
    when :fail
      eval(@eval_fail)
    when :delay
      eval(@eval_delay)
    end
  end

  def add_need(id, v)
    @delay_need[id] += v
  end
  def add_exp(v)
    @delay_reward_exp += v 
  end 
  def add_gold(v)
    @delay_reward_gold += v 
  end
end 
end # end of module

class Sprite_Task < Sprite 
  attr_reader  :data, :_x, :_y
  def initialize(data)  # TASK::Data
    super(nil)
    self.bitmap = Cache.system("bg")
    @sprite_layer = Sprite.new
    @sprite_layer.bitmap = Bitmap.new(self.width, self.height)
    @sprite_layer.ox = @sprite_layer.width / 2
    @sprite_layer.oy = @sprite_layer.height / 2
    @sprite_layer2 = Sprite.new
    @sprite_layer2.bitmap = Bitmap.new(Graphics.width, self.height)
    @sprite_layer2.ox = @sprite_layer2.width / 2
    @sprite_layer2.oy = @sprite_layer2.height / 2
    @data = data
    reset
  end

  def dispose 
    @sprite_layer.bitmap.dispose if @sprite_layer.bitmap
    @sprite_layer.dispose
    @sprite_layer2.bitmap.dispose if @sprite_layer2.bitmap
    @sprite_layer2.dispose 
    self.bitmap.dispose if self.bitmap
    super
  end

  def set_xy(x, y)
    @_x = x
    @_y = y
  end

  def reset
    bind_actor(nil)
  end

  def bind_actor(actor = nil)
    @actor = actor
    cancel_delay
    refresh
  end

  def update_position
    @sprite_layer.x = self.x 
    @sprite_layer.y = self.y
    @sprite_layer2.x = self.x 
    @sprite_layer2.y = self.y
  end

  # 获取附加值的带颜色的字符串
  def get_add_value_string(v,color_add=1,color_minus=10)
    return "" if v == 0
    return "\ec[#{color_add}]+#{v}\ec[0]" if v > 0
    return "\ec[#{color_minus}]-#{v.abs}\ec[0]" if v < 0
  end

  def refresh
    @sprite_layer.bitmap.clear
    @sprite_layer2.bitmap.clear

    padding = 12

    # 左上角绘制任务名称
    @sprite_layer.bitmap.font.size = 24
    @sprite_layer.bitmap.draw_text(padding,padding,200,32, @data.name)

    # 右上角绘制要求及消耗
    t = []
    v = @data.get_need(0)  # 力
    if v > 0
      _t = "\ei[116]>#{@data.need[0]}"
      _t += get_add_value_string(@data.delay_need[0],10,1)
      t.push(_t) 
    end
    v = @data.get_need(1)  # 智
    if v > 0
      _t = "\ei[117]>#{@data.need[1]}"
      _t += get_add_value_string(@data.delay_need[1],10,1)
      t.push(_t) 
    end
    v = @data.get_need(2)  # 敏
    if v > 0
      _t = "\ei[12]>#{@data.need[2]}"
      _t += get_add_value_string(@data.delay_need[2],10,1)
      t.push(_t) 
    end
    t.push("\ei[674]-#{@data.cost}")
    t = t.join(' ')
    size = 18
    w = @sprite_layer.width - padding * 2
    ps = { :font_size => size, :x0 => padding, :y0 => padding, 
      :lhd => 4, :w => w, :ali => 2 }
    d = Process_DrawTextEX.new(t, ps, @sprite_layer.bitmap)
    d.run(true)

    # 第二、三行绘制任务介绍文本
    t = @data.intro
    size = 18
    ps = { :font_size => size, :x0 => padding, :y0 => padding+32, 
      :lhd => 4, :w => w, :ali => 0 }
    d = Process_DrawTextEX.new(t, ps, @sprite_layer.bitmap)
    d.run(true)

    # 第四行绘制奖励
    t = ""
    t += "\ei[228]x#{@data.reward_exp}"+get_add_value_string(@data.delay_reward_exp)
    t += " "
    t += "\ei[881]x#{@data.reward_gold}"+get_add_value_string(@data.delay_reward_gold)  
    size = 18
    ps = { :font_size => size, :x0 => padding, 
      :y0 => @sprite_layer.height-24-padding, 
      :lhd => 4, :w => w, :ali => 0 }
    d = Process_DrawTextEX.new(t, ps, @sprite_layer.bitmap)
    d.run(true)

    # layer2绘制执行计划
    t = ""
    if @data.flag_delay
      t = "拖一天！"
    end
    if @actor 
      t = @actor.name
      draw_face(@sprite_layer2.bitmap, @actor.face_name, @actor.face_index, 
        Graphics.width/2+@sprite_layer.width/2+12, 0)
    end
    if @data.result
      case @data.result
      when :success; t = "<任务成功>"
      when :fail;    t = "<任务失败>"
      when :delay;   t = "<已推迟>"
      end
    end
    size = 24
    ps = { :font_size => size, 
      :x0 => Graphics.width/2+@sprite_layer.width/2+12, 
      :y0 => @sprite_layer2.height-24-padding, 
      :lhd => 4, :w => w, :ali => 2 }
    d = Process_DrawTextEX.new(t, ps, @sprite_layer2.bitmap)
    d.run(true)
  end
  #--------------------------------------------------------------------------
  # ● 绘制角色肖像图
  #     enabled : 有效的标志。false 的时候使用半透明效果绘制
  #--------------------------------------------------------------------------
  def draw_face(bitmap, face_name, face_index, x, y, enabled = true)
    b = Cache.face(face_name)
    rect = Rect.new(face_index % 4 * 96, face_index / 4 * 96, 96, 96)
    bitmap.blt(x, y, b, rect, enabled ? 255 : 120)
  end

  def delay?
    @data.flag_delay
  end

  def delay 
    return if @data.flag_delay
    @data.flag_delay = true 
    refresh
  end

  def cancel_delay
    return if !@data.flag_delay
    @data.flag_delay = false 
    refresh
  end

  def active?
    !@data.flag_check
  end

  def todo?
    @actor != nil
  end

  def check
    return false if @data.flag_check
    if @actor
      @data.flag_check = true
      f = true 
      if @actor.mp < @data.cost
        f = false
      end
      @actor.mp -= @data.cost
      v = @data.get_need(0)
      f = false if f and v > 0 and @actor.atk < v
      v = @data.get_need(1)
      f = false if f and v > 0 and @actor.mat < v
      v = @data.get_need(2)
      f = false if f and v > 0 and @actor.agi < v
      f ? check_success : check_fail 
      return true
    end
    if @data.flag_delay
      @data.flag_check = true
      check_delay
      return true 
    end
    return false
  end

  def check_success
    v = @data.get_reward(:exp)
    @actor.gain_exp(v)
    v = @data.get_reward(:gold)
    $game_party.gain_gold(v)
    @data.result = :success
    @data.result_actor = @actor
    @data.run_eval(@data.result, @actor)
    bind_actor(nil)
    $game_party.tasks.delete(@data)
  end
  def check_fail 
    @data.result = :fail
    @data.run_eval(@data.result, @actor)
    bind_actor(nil)
    $game_party.tasks.delete(@data)
  end
  def check_delay
    @data.delay_count += 1
    @data.result = :delay
    @data.run_eval(@data.result, @actor)
    bind_actor(nil)
  end
end

class Window_Task_Select < Window_Selectable
  attr_reader :task 
  def initialize()
    super(0,0,300,fitting_height(10))
    refresh
  end
  def set_task(task)
    @task = task
  end
  #--------------------------------------------------------------------------
  # ● 获取项目的高度
  #--------------------------------------------------------------------------
  def item_height
    line_height * 2.5
  end
  #--------------------------------------------------------------------------
  # ● 获取项目数
  #--------------------------------------------------------------------------
  def item_max
    @data ? @data.size : 0
  end

  def item
    @data[@index]
  end
  #--------------------------------------------------------------------------
  # ● 刷新
  #--------------------------------------------------------------------------
  def refresh
    @data = [nil] + $game_party.members
    contents.clear
    draw_all_items
  end
  #--------------------------------------------------------------------------
  # ● 绘制项目
  #--------------------------------------------------------------------------
  def draw_item(index)
    r = item_rect(index)
    r.y += 4
    actor = @data[index]

    contents.font.size = 24

    if actor == nil 
      contents.draw_text(r.x, r.y+12, r.width, line_height, "<取消安排>", 1)
      return 
    end

    contents.draw_text(r.x, r.y, r.width, line_height, actor.name)
    
    t = []
    t.push("\ei[116]#{actor.atk}") # 力
    t.push("\ei[117]#{actor.mat}") # 智
    t.push("\ei[12]#{actor.agi}") # 敏
    t.push("\ei[674]#{actor.mp}")
    t = t.join(' ')
    size = 18
    ps = { :font_size => size, :x0 => r.x, :y0 => r.y, 
      :lhd => 4, :w => r.width, :ali => 2 }
    d = Process_DrawTextEX.new(t, ps, contents)
    d.run(true)

    t = "\ei[228] #{actor.exp} / #{actor.next_level_exp}"
    size = 18
    ps = { :font_size => size, :x0 => r.x, :y0 => r.y+24, 
      :lhd => 4, :w => r.width, :ali => 0 }
    d = Process_DrawTextEX.new(t, ps, contents)
    d.run(true)
  end
  
end

class Game_Party
  attr_accessor :tasks
end

class Scene_BraveTask < Scene_MenuBase
  def start
    TASK.init
    super
    @sprites = []
    @current = nil
    @dy = 0

    $game_party.tasks.each_with_index do |d, i|
      s = Sprite_Task.new(d)
      @sprites.push(s)
      s.ox = s.bitmap.width / 2
      s.oy = s.bitmap.height / 2
      s.x = Graphics.width / 2
      s.y = Graphics.height / 2 + i * (s.height + 20)
      s.set_xy(s.x, s.y)
    end
    @window_select = Window_Task_Select.new
    @window_select.openness = 0
    @window_select.set_handler(:ok,     method(:on_select_ok))
    @window_select.set_handler(:cancel, method(:on_select_cancel))
  end
  #--------------------------------------------------------------------------
  # ● 结束前处理
  #--------------------------------------------------------------------------
  def pre_terminate
    super 
    @sprites.each { |s| s.dispose }
  end

  def update_basic
    super
    @current = nil
    update_tasks
  end

  def update 
    super 
    return if @window_select.active
    update_moves
    update_mouse if @current
    update_return 
    update_check
  end

  def update_moves
    @last_mouse_scroll ||= 0
    @dy_add = 0
    if MOUSE_EX.scroll_up?
      return if @sprites[-1].y < 0 + @sprites[0].height
      if @last_mouse_scroll == -1
        @dy_add += 1 
      else 
        @dy_add = 0
      end
      @dy -= (4 + @dy_add) 
      @last_mouse_scroll = -1
    elsif MOUSE_EX.scroll_down?
      return if @sprites[0].y > Graphics.height - @sprites[0].height
      if @last_mouse_scroll == 1
        @dy_add += 1 
      else 
        @dy_add = 0
      end
      @dy += 4 
      @last_mouse_scroll = 1
    end
  end
  
  def update_tasks
    @sprites.each do |s| 
      s.y = s._y + @dy
      s.update_position
      @current = s if s.active? and s.mouse_in?
    end
  end
  
  def update_mouse
    if MOUSE_EX.up?(:ML)
      return Sound.play_buzzer if @current.delay?
      @window_select.set_task(@current)
      @window_select.x = Graphics.width/2 - @window_select.width / 2
      @window_select.y = Graphics.height/2 - @window_select.height / 2
      @window_select.refresh
      @window_select.open.activate
    elsif MOUSE_EX.up?(:MR)
      return Sound.play_buzzer if @current.todo?
      @current.delay? ? @current.cancel_delay : @current.delay
    end
  end
  
  def on_select_ok
    @window_select.close
    @window_select.task.bind_actor(@window_select.item)
    @window_select.set_task(nil)
  end
  def on_select_cancel
    @window_select.close
    @window_select.set_task(nil)
  end

  def update_return
    return_scene if INPUT_EX.up?(:ESC)
  end

  def update_check
    process_check if INPUT_EX.up?(:SPACE)
  end

  def process_check
    @sprites.each do |s| 
      y2 = Graphics.height/2 - s._y; y1 = @dy
      20.times { |i|
        update_basic
        v = EasingFuction.call("easeInSine", i*1.0/20)
        @dy = y1 + (y2-y1) * v
      }
      f = s.check
      30.times {update_basic} if f
    end
  end
  
end
