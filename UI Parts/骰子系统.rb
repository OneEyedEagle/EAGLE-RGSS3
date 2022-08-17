#==============================================================================
# ■ 骰子系统 by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【组件-通用方法汇总 by老鹰】与
#  【组件-位图绘制转义符文本 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-Dice"] = "1.0.1"
#==============================================================================
# - 2022.8.16.22
#==============================================================================
# - 本插件增加了一套独立的骰子系统，能够在任意时刻投掷并返回结果
#------------------------------------------------------------------------------
# 【使用：投掷六面骰】
#
# - DICE.d6(n = 1, ps={})
#
#    其中 n 为骰子数量，若不传入，则为 1
#    其中 ps 为可选参数：
#
#     :t => 字符串,      # 显示在屏幕顶端的文字，转义符请用 \\ 代替 \
#     :auto => 布尔量,   # 若传入 true，则不可操作，投掷直接结束（默认不启用）
#     :reroll => 数字,   # 允许进行重投掷的次数（默认0）
#
#     :results => 数组,  # 在投掷完成后，所有骰子的值将存入该数组，方便后续使用
#
# - 示例：
#
#    $game_variables[1] = DICE.d6  → 投掷一个六面骰，并返回结果值存入1号变量中
#
#    条件分歧-脚本
#      DICE.d6(3, {:t=>"只有投掷到12以上，才能打破这面墙……", :reroll=>3}) > 12
#        → 投掷三个六面骰，有3次重投掷机会，和大于12时才会进入事件的当前分歧
#
#------------------------------------------------------------------------------
# 【使用：投掷角色骰】
#
# - DICE.d_actor(actor_id, ps = {})
#
#    其中 actor_id 为队伍中角色的id，若不在队伍，则投掷无效并返回 0
#    其中 ps 与之上的一致
#
# - 示例：
#
#    条件分歧-脚本
#      DICE.d_actor(1,{:t=>"艾里克进行投掷！\n需要点数大于3才能成功哦。"}) > 3
#        → 查找1号角色的骰子进行投掷，和大于3时才会进入事件的当前分歧
#
#-----------------------------------------------------------
# - 设置角色的骰子：
#
#   在数据库的备注栏中填入下式，可以设置增加的骰子
#   将按照 状态 > 角色/敌人 > 职业 > 装备 的顺序进行检索
#
#     <Dice: 数字串 {参数}>
#
#    其中 Dice: 为标识符，大小写随意，英语冒号可以省略
#    其中 数字串 为骰子各个面，面数随意，用英语逗号或空格区分不同面
#    其中 {参数} 可选，用于设置该骰子的特别参数，不同参数用空格区分：
#
#      bg=字符串  # 骰子使用的背景图片的后缀
#                   默认使用 BG_DEFAULT 设置的，即 Dice_BG 图片，
#                   但如果设置了该项，则为查找 Dice_BG_字符串 的图片
#
# - 示例：
#
#    <dice 1 2 3> → 增加一个只有 1/2/3 三面的骰子
#
#    <dice 3 {bg=1}> → 增加一个只有 3 一面的骰子，背景图片为 Dice_BG_1
#
#-----------------------------------------------------------
# - 设置骰子的变化：
#
#   在数据库的备注栏中填入下式，可以设置骰子值的变化
#   将按照 状态 > 角色/敌人 > 职业 > 装备 的顺序进行检索
#   如果骰子的面已经发生变化，则不会再次变化
#
#     <change 数量 Dice 旧值 to 新值>
#
#    其中 数量 为受到该条影响的骰子的数量
#    其中 旧值 为骰子变化前的值
#    其中 新值 为骰子变化后的值
#
# - 示例：
#
#    <change 2 Dice 1 to 2> - 将2个骰子的全部1修改为2
#
#------------------------------------------------------------------------------
# 【使用：自定义骰子】
#
=begin

# 首先需要有骰子各个面的值的数组
arr = [1,2,6]
# 然后预设一个参数Hash，其中可以增加骰子自身的参数设置，如 :bg=>"图片后缀名"
ps = {}
# 调用类生成实例
d = DICE::Data_Dice.new(arr, ps)

# 重复以上步骤后，获得全部骰子的数组
ds = [d]
# 预设一个投掷的参数Hash，可以设置【使用：投掷六面骰】中的参数
ps = { :reroll => 1 }
# 进行投掷
DICE.call(ds, ps)

=end
#
#=============================================================================
module DICE
  #--------------------------------------------------------------------------
  # ●【常量】显示的基础Z值
  #--------------------------------------------------------------------------
  BASE_Z = 200
  #--------------------------------------------------------------------------
  # ●【常量】骰子的初始位置
  #--------------------------------------------------------------------------
  INIT_X = Graphics.width / 2
  INIT_Y = Graphics.height / 2
  #--------------------------------------------------------------------------
  # ●【常量】骰子的初始位置增量
  #--------------------------------------------------------------------------
  INIT_DX = "rand(241) - 120"
  INIT_DY = "rand(201) - 100"
  #--------------------------------------------------------------------------
  # ●【常量】骰子的结束位置
  #--------------------------------------------------------------------------
  END_X = Graphics.width / 2
  END_Y = Graphics.height / 2
  #--------------------------------------------------------------------------
  # ●【常量】骰子的背景图片
  #  可省略后缀名，需放置于 Graphics/System 目录下
  #  如果图片不存在，则自动绘制白底黑框
  #--------------------------------------------------------------------------
  BG_DEFAULT = "Dice_BG"
  #--------------------------------------------------------------------------
  # ●【常量】骰子被选择时的前景图片
  #  可省略后缀名，需放置于 Graphics/System 目录下
  #  如果图片不存在，则自动绘制黄色半透明
  #--------------------------------------------------------------------------
  BG_CHOSEN = "Dice_Chosen"
  #--------------------------------------------------------------------------
  # ●【常量】骰子中文字的颜色
  #--------------------------------------------------------------------------
  TEXT_COLOR = Color.new(0,0,0)

  #--------------------------------------------------------------------------
  # ● 投掷六面骰
  #--------------------------------------------------------------------------
  def self.d6(n = 1, ps = {})
    ds = [[1,2,3,4,5,6]] * n
    data = []
    ds.each do |d|
      _d = Data_Dice.new(d)
      data.push(_d)
    end
    call(data, ps)
  end

  #--------------------------------------------------------------------------
  # ● 以队伍中的某位角色进行投掷
  # 如果该角色不在队伍里，则返回 0
  #--------------------------------------------------------------------------
  def self.d_actor(actor_id, ps = {})
    b = nil
    $game_party.all_members.each do |actor|
      break b = actor if actor.id == actor_id
    end
    return 0 if b == nil
    data = get_dices(b)
    call(data, ps)
  end

  #--------------------------------------------------------------------------
  # ●【常量】新增骰子的正则
  #       如：<Dice: 1 2,0 1,1,0> - 增加一个 1/2/0/1/1/0 六个面的骰子
  #   【可选】在最后利用 {string} 来为骰子设置属性
  #       如：<dice 1 3 5 {bg=w1}> - 该骰子使用 Dice_BG_w1 作为背景图
  #--------------------------------------------------------------------------
  REGEXP_DICE_ADD = /<(?i:DICE):? ?([\d, ]*?) ?(\{.*?\})?>/
  #--------------------------------------------------------------------------
  # ●【常量】修改指定数目骰子的全部数字为另一数字
  #  如： <change 2 Dice 1 to 2> - 将2个骰子的全部1修改为2
  #--------------------------------------------------------------------------
  REGEXP_DICE_CHANGE = /change (\d+) dice:? ?(\d+) to (\d+)/i
  #--------------------------------------------------------------------------
  # ● 获取战斗者的骰子组
  #--------------------------------------------------------------------------
  def self.get_dices(battler)
    datas = [] # [Data_Dice]
    changes = {} # obj => change_array
    # 优先级： 状态 > 角色/敌人 > 职业 > 装备
    battler.feature_objects.each do |obj|
      next if obj.nil?
      obj.note.scan(REGEXP_DICE_ADD).each do |param|
        d = param[0].split(/[ ,]/).collect { |id| id.to_i }
        ps = param[1] ? EAGLE_COMMON.parse_tags(param[1]) : {}
        datas.push(Data_Dice.new(d, ps))
      end
      obj.note.scan(REGEXP_DICE_CHANGE).each do |param|
        changes[obj] ||= []
        changes[obj].push(param)
      end
    end
    # 应用更改
    changes.each do |obj, params|
      params.each do |param|  # 数量 更改前的值 更改后的值
        count = param[0].to_i; old_id = param[1].to_i; new_id = param[2].to_i
        datas.each do |data|
          i = data.ids_init.index { |id| id == old_id }
          next if i.nil?
          next if data.changed?(i)  # 存在变更，则不再变动
          data.add_change(i, obj, new_id)
          count -= 1
          break if count == 0
        end
      end
    end
    return datas
  end

  #--------------------------------------------------------------------------
  # ● 投掷，并返回骰子总和
  #  同时在 ps[:results] 存储了所有骰子结果的数组，如 [2,3,1...]
  #  data 为 Data_Dice 的实例数组
  #--------------------------------------------------------------------------
  def self.call(data, ps = {})
    return 0 if data.empty?
    s = Spriteset_Dices.new
    s.setup(data, ps)
    while true
      s.update
      update_basic
      break if s.finish?
    end
    s.dispose
    ps[:result] = s.results
    return s.sum
  end
  #--------------------------------------------------------------------------
  # ● 基础更新
  #--------------------------------------------------------------------------
  def self.update_basic
    SceneManager.scene.update_basic
  end

#==============================================================================
# ■ Spriteset_Dices
#==============================================================================
class Spriteset_Dices
  include DICE
  attr_reader   :results, :sum
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize
    @data = []
    @ps = {}
    @sprite_dices = []
    @results = []
    @sum = 0
    @active = false  # 玩家可操作？
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    @fiber.resume if @fiber
    update_dices
    update_ui if @active
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
  end
  #--------------------------------------------------------------------------
  # ● 启动
  #--------------------------------------------------------------------------
  # data 为 Data_Dice 实例的数组
  def setup(data, ps)
    @data = data
    @ps = ps
    @fiber = Fiber.new { fiber_main }
  end
  #--------------------------------------------------------------------------
  # ● 完成？
  #--------------------------------------------------------------------------
  def finish?
    @fiber == nil
  end
  #--------------------------------------------------------------------------
  # ● 自动模式？
  #--------------------------------------------------------------------------
  def auto?
    @ps[:auto] == true
  end
  #--------------------------------------------------------------------------
  # ● 最大重投掷次数
  #--------------------------------------------------------------------------
  def num_reroll
    @ps[:reroll].to_i rescue 0
  end

  #--------------------------------------------------------------------------
  # ● 主线程
  #--------------------------------------------------------------------------
  def fiber_main
    init_ui
    init_dices
    move_in
    process_start
    process_key
    process_finish
    move_out
    dispose_dices
    dispose_ui
    @fiber = nil
  end
  #--------------------------------------------------------------------------
  # ● 初始化骰子
  #--------------------------------------------------------------------------
  def init_dices
    @sprite_dices = @data.collect { |d| Sprite_Dice.new(d) }
  end
  #--------------------------------------------------------------------------
  # ● 更新骰子
  #--------------------------------------------------------------------------
  def update_dices
    @sprite_dices.each { |s| s.update }
  end
  #--------------------------------------------------------------------------
  # ● 释放骰子
  #--------------------------------------------------------------------------
  def dispose_dices
    @sprite_dices.each { |s| s.dispose }
    @sprite_dices.clear
  end
  #--------------------------------------------------------------------------
  # ● 骰子移入
  #--------------------------------------------------------------------------
  def move_in
    t = 30
    @sprite_dices.each do |s|
      s.z = BASE_Z + 10
      s.set_xy(INIT_X, INIT_Y)
      s.set_des_opa(255, t)
      s.set_des_xy(INIT_X + eval(INIT_DX).to_i, INIT_Y + eval(INIT_DY).to_i, t)
    end
    t.times { Fiber.yield }
  end
  #--------------------------------------------------------------------------
  # ● 处理骰子第一次投掷
  #--------------------------------------------------------------------------
  def process_start
    20.times { Fiber.yield }
    roll
  end
  #--------------------------------------------------------------------------
  # ● 处理玩家按键
  #--------------------------------------------------------------------------
  def process_key
    if auto?
      60.times { Fiber.yield }
      return
    end
    @n_reroll = num_reroll
    process_player_start
    while true
      Fiber.yield
      if @selected_token && Input.trigger?(:C)
        if @n_reroll > 0
          @n_reroll -= 1
          redraw_hint(@sprite_hint)
          roll(@selected_token)
        else
          Sound.play_buzzer
        end
      end
      break Sound.play_cancel if Input.trigger?(:B)
    end
    process_player_finish
  end
  #--------------------------------------------------------------------------
  # ● 处理骰子第一次投掷结束
  #--------------------------------------------------------------------------
  def process_finish
  end
  #--------------------------------------------------------------------------
  # ● 骰子移出
  #--------------------------------------------------------------------------
  def move_out
    t = 30
    @sprite_dices.each do |s|
      s.set_des_opa(0, t)
      s.set_des_xy(END_X, END_Y, t)
    end
    t.times { Fiber.yield }
  end
  #--------------------------------------------------------------------------
  # ● 指定骰子投掷
  #--------------------------------------------------------------------------
  def roll(s = nil)
    f = @active
    @active = false
    if s == nil
      @sprite_dices.each { |s| s.run }
    else
      s.run
    end
    Fiber.yield until waiting?
    @active = f
    @results = @sprite_dices.collect { |s| s.v }
    @sum = @results.inject(0) { |v, s| s += v }
    redraw_info
    redraw_dice_info
  end
  #--------------------------------------------------------------------------
  # ● 全部骰子均投掷完成？
  #--------------------------------------------------------------------------
  def waiting?
    f = @sprite_dices.any? { |s| !s.waiting? }
    !f
  end

  #--------------------------------------------------------------------------
  # ● UI-最大的宽高
  #--------------------------------------------------------------------------
  def ui_max_x
    Graphics.width
  end
  def ui_max_y
    Graphics.height
  end
  #--------------------------------------------------------------------------
  # ● UI-初始化
  #--------------------------------------------------------------------------
  def init_ui
    # 背景
    @sprite_bg = Sprite.new
    @sprite_bg.z = BASE_Z
    @sprite_bg.bitmap = Bitmap.new(ui_max_x, ui_max_y)
    @sprite_bg.bitmap.fill_rect(0, 0, @sprite_bg.width, @sprite_bg.height,
      Color.new(0,0,0,120))

    # 背景字
    @sprite_bg_info = Sprite.new
    @sprite_bg_info.z = BASE_Z + 1
    set_sprite_info(@sprite_bg_info)

    # 底部按键提示
    @sprite_hint = Sprite.new
    @sprite_hint.z = @sprite_bg.z + 20
    set_sprite_hint(@sprite_hint)

    # 光标
    @sprite_player = Sprite_Dice_Player.new
    @sprite_player.z = BASE_Z + 100
    @sprite_player.visible = false
    @params_player = { :last_input => nil, :last_input_c => 0, :d => 1 }
    @selected_token = nil

    # 信息展示（投掷结果）
    @sprite_info1 = Sprite.new
    @sprite_info1.z = BASE_Z + 3
    @sprite_info1.x = 16
    @sprite_info1.y = 16

    # 信息展示（当前选中骰子）
    @sprite_info2 = Sprite.new
    @sprite_info2.z = BASE_Z + 4

    # 信息展示（投掷目的文本，由 ps[:t] 传入）
    @sprite_info3 = Sprite.new
    @sprite_info3.z = BASE_Z + 4
    set_sprite_info3(@sprite_info3)
  end
  #--------------------------------------------------------------------------
  # ● UI-设置LOG标题精灵
  #--------------------------------------------------------------------------
  def set_sprite_info(sprite)
    sprite.zoom_x = sprite.zoom_y = 3.0
    sprite.bitmap = Bitmap.new(Graphics.height, Graphics.height)
    sprite.bitmap.font.size = 48
    sprite.bitmap.font.color = Color.new(255,255,255,10)
    sprite.bitmap.draw_text(0,0,sprite.width,64, "ROLL", 0)
    sprite.angle = -90
    sprite.x = Graphics.width + 48
    sprite.y = 0
  end
  #--------------------------------------------------------------------------
  # ● UI-设置按键提示精灵
  #--------------------------------------------------------------------------
  def set_sprite_hint(sprite)
    sprite.bitmap = Bitmap.new(Graphics.width, 24)
    sprite.bitmap.font.size = ABILITY_LEARN::HINT_FONT_SIZE
    redraw_hint(sprite)
    sprite.oy = sprite.height
    sprite.y = Graphics.height
  end
  #--------------------------------------------------------------------------
  # ● UI-重绘按键提示
  #--------------------------------------------------------------------------
  def redraw_hint(sprite)
    t = "方向键 - 移动 | "
    if @selected_token
      t += "确定键 - 重投掷（剩 #{@n_reroll} 次） | "
    end
    t += "取消键 - 结束投掷"
    if auto?
      t = "- 自动投掷，不可操作 -"
    end
    sprite.bitmap.clear
    sprite.bitmap.draw_text(0, 2, sprite.width, sprite.height, t, 1)
    sprite.bitmap.fill_rect(0, 0, sprite.width, 1,
      Color.new(255,255,255,120))
  end
  #--------------------------------------------------------------------------
  # ● UI-重绘投掷目的提示
  #--------------------------------------------------------------------------
  def set_sprite_info3(sprite)
    return if @ps[:t] == nil || @ps[:t].empty?
    sprite.bitmap ||= Bitmap.new(300, 64)
    sprite.bitmap.clear

    sprite.x = Graphics.width / 2
    sprite.y = 32
    sprite.ox = sprite.width / 2
    sprite.oy = 0

    ps = { :font_size => 16, :x0 => 0, :y0 => 0, :w => sprite.width, :lhd => 2}
    ps[:font_color] = Color.new(255,255,255)
    ps[:ali] = 1
    d = Process_DrawTextEX.new(@ps[:t], ps, sprite.bitmap)
    d.run(true)
  end
  #--------------------------------------------------------------------------
  # ● UI-更新
  #--------------------------------------------------------------------------
  def update_ui
    update_player if @sprite_player.visible
  end
  #--------------------------------------------------------------------------
  # ● UI-释放
  #--------------------------------------------------------------------------
  def dispose_ui
    instance_variables.each do |varname|
      ivar = instance_variable_get(varname)
      if ivar.is_a?(Sprite) && !ivar.disposed?
        ivar.bitmap.dispose if ivar.bitmap
        ivar.dispose
      end
    end
  end

  #--------------------------------------------------------------------------
  # ● UI-处理玩家操作开始/结束
  #--------------------------------------------------------------------------
  def process_player_start
    @active = true
    @sprite_player.visible = true
  end
  def process_player_finish
    @active = false
    @sprite_player.visible = false
  end
  #--------------------------------------------------------------------------
  # ● UI-更新光标
  #--------------------------------------------------------------------------
  def update_player
    # 更新移动
    s = @sprite_player
    if @params_player[:last_input] == Input.dir4
      @params_player[:last_input_c] += 1
      @params_player[:d] += 1 if @params_player[:last_input_c] % 5 == 0
    else
      @params_player[:d] = 1
      @params_player[:last_input] = Input.dir4
      @params_player[:last_input_c] = 0
    end
    d = @params_player[:d]
    if Input.press?(:UP)
      s.y -= d
      s.y = s.oy if s.y - s.oy < 0
    elsif Input.press?(:DOWN)
      s.y += d
      s.y = ui_max_y - s.height + s.oy if s.y - s.oy + s.height > ui_max_y
    elsif Input.press?(:LEFT)
      s.x -= d
      s.x = s.ox if s.x - s.ox < 0
    elsif Input.press?(:RIGHT)
      s.x += d
      s.x = ui_max_x - s.width + s.ox if s.x - s.ox + s.width > ui_max_x
    end

    # 更新是否有选中的token
    if @selected_token && @selected_token.point_in?(s.x, s.y)
      # 之前的还是被选中的状态
    else
      last_selected = @selected_token
      @selected_token = nil
      @sprite_dices.each do |sd|
        break @selected_token = sd if sd.point_in?(s.x, s.y)
      end
      last_selected.unchoose if last_selected
      if @selected_token # 选中
        @selected_token.choose
        Sound.play_cursor
        redraw_hint(@sprite_hint)
      elsif last_selected  # 从选中变成没有选中
        redraw_hint(@sprite_hint)
      end
      redraw_dice_info
    end
  end
  #--------------------------------------------------------------------------
  # ● UI-重绘左上角统计信息
  #--------------------------------------------------------------------------
  def redraw_info
    s = @sprite_info1
    s.bitmap ||= Bitmap.new(160, 100)
    s.bitmap.clear

    w = 48
    s.bitmap.draw_text(0,0,w,32,"统计", 1)
    s.bitmap.fill_rect(w,16-1,s.width-w,1, Color.new(255,255,255))
    s.bitmap.fill_rect(16,32,1,s.height-32, Color.new(255,255,255))

    text = ""
    text += @results.inject("") { |s, v| s = s + " " + v.to_s }
    text += "\n"
    text += "和 = #{@sum}"

    ps = { :font_size => 16, :x0 => 32, :y0 => 32, :w => s.width-32, :lhd => 2}
    ps[:font_color] = Color.new(255,255,255)
    ps[:ali] = 1
    d = Process_DrawTextEX.new(text, ps, s.bitmap)
    d.run(true)
  end
  #--------------------------------------------------------------------------
  # ● UI-重绘骰子信息
  #--------------------------------------------------------------------------
  def redraw_dice_info
    s = @sprite_info2
    s.bitmap ||= Bitmap.new(300, 32)
    s.bitmap.clear
    return if @selected_token == nil

    s.x = Graphics.width / 2
    s.y = Graphics.height - 32
    s.ox = s.width / 2
    s.oy = s.height

    text = "当前面：#{@selected_token.v}"

    change = @selected_token.data.changes[@selected_token.index]
    if change
      # change = [old_id, new_id, obj]
      icon = change[2].icon_index rescue return
      text = "\n\\i[#{icon}]#{change[2].name} 特性："
      text += "由 #{change[0]} 变为了 #{change[1]}"
    end

    ps = { :font_size => 16, :x0 => 0, :y0 => 0, :w => s.width, :lhd => 2}
    ps[:font_color] = Color.new(255,255,255)
    ps[:ali] = 1
    d = Process_DrawTextEX.new(text, ps, s.bitmap)
    d.run(true)
  end
end

#==============================================================================
# ■ 存储单个骰子的数据
#==============================================================================
class Data_Dice
  attr_reader   :ids_init, :ids, :changes
  attr_accessor :params
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(ids, params = {})
    # 按序存储各面数值的数组（顺序不会变动）
    @ids_init = ids # 初始id数组
    @ids = ids.dup # 最终id数组
    @changes = {} # 面index => [old_id, new_id, obj]
    @params = params # 存储一些额外的参数
  end
  #--------------------------------------------------------------------------
  # ● 增加指定面的修改
  #--------------------------------------------------------------------------
  def add_change(index, obj, new_id)
    @changes[index] = [@ids_init[index], new_id, obj]
    @ids[index] = new_id
  end
  #--------------------------------------------------------------------------
  # ● 指定面存在修改？
  #--------------------------------------------------------------------------
  def changed?(index)
    @changes[index] != nil
  end
  #--------------------------------------------------------------------------
  # ● 指定面被含有图标的obj所修改？
  #--------------------------------------------------------------------------
  def changed_with_icon?(index)
    changed?(index) && @changes[index][2].icon_index
  end
end

#==============================================================================
# ■ 处理单个骰子的精灵
#==============================================================================
class Sprite_Dice < Sprite
  include DICE
  attr_reader  :data
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(data)
    super(nil)
    self.opacity = 0
    @data = data
    init_params
    init_bitmaps
    init_layer
    update_bitmap
    update_layer
  end
  #--------------------------------------------------------------------------
  # ● 初始化参数
  #--------------------------------------------------------------------------
  def init_params
    # 标志用变量
    @state = :init
    @chosen = false # 光标停留？（spriteset内变更该flag）
    # 移动用变量
    @x_f = @y_f = @opa_f = 0.0
    @des_x = @des_y = @des_opa = 0
    @v_x = @v_y = @v_opa = 0
    # 计数用
    @frame_count = 0 # 帧计数
    @frame_max = rand(8) + 5 # 每隔该帧数骰子面切换
    # 骰子面参数
    @index_max = @data.ids.size # 最大面数
    @index_cur = rand(@index_max) # 初始面

    # 骰子面切换顺序类型
    @index_order = :rand
    # 骰子所读取图片的后缀名
    @bg_surfix = @data.params[:bg]
  end
  #--------------------------------------------------------------------------
  # ● 初始化各面位图
  #--------------------------------------------------------------------------
  def init_bitmaps
    @bitmaps = [] # 按序存储各个面的位图
    @data.ids.each_with_index do |id, index|
      begin
        t_bitmap = Cache.system(BG_DEFAULT).dup
        t_bitmap = Cache.system(BG_DEFAULT+"_#{@bg_surfix}").dup if @bg_surfix
      rescue
        w = h = 36
        b = 2
        t_bitmap = Bitmap.new(w, h)
        t_bitmap.fill_rect(0,0,w,h, Color.new(0,0,0))
        t_bitmap.fill_rect(b,b,w-2*b,h-2*b, Color.new(255,255,255))
      end
      t_bitmap.font.color = TEXT_COLOR
      t_bitmap.font.outline = false
      t_bitmap.font.shadow = false
      # 如果存在数值变动
      if @data.changed_with_icon?(index)
        t = @data.changes[index][0].to_s
        r = t_bitmap.text_size(t)
        _y = -2
        _w = 10
        color = TEXT_COLOR
        t_bitmap.draw_text(0, _y, t_bitmap.width-_w, t_bitmap.height, t, 1)
        t_bitmap.fill_rect((t_bitmap.width-_w-r.width)/2-1,
          t_bitmap.height/2+_y, r.width+2, 1, color)
        t_bitmap.draw_text(_w, _y*-1, t_bitmap.width-_w, t_bitmap.height, id, 1)
      else
        t_bitmap.draw_text(0, 0, t_bitmap.width, t_bitmap.height, id, 1)
      end
      @bitmaps.push(t_bitmap)
    end
  end
  #--------------------------------------------------------------------------
  # ● 初始化遮挡精灵
  #--------------------------------------------------------------------------
  def init_layer
    @sprite_layer_chosen = Sprite.new
    begin
      @sprite_layer_chosen.bitmap = Cache.system(BG_CHOSEN)
    rescue
      w = h = 36
      b = 2
      t_bitmap = Bitmap.new(w, h)
      t_bitmap.fill_rect(b,b,w-2*b,h-2*b, Color.new(100,255,255,150))
      @sprite_layer_chosen.bitmap = t_bitmap
    end
    @sprite_layer_chosen.ox = @sprite_layer_chosen.width / 2
    @sprite_layer_chosen.oy = @sprite_layer_chosen.height / 2
    @sprite_layer_chosen.visible = @chosen
  end
  #--------------------------------------------------------------------------
  # ● 更新位图（当切换面时调用）
  #--------------------------------------------------------------------------
  def update_bitmap
    self.bitmap = @bitmaps[@index_cur]
    self.ox = self.width / 2
    self.oy = self.height / 2
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    dispose_layer
    @bitmaps.each { |b| b.dispose }
    super
  end
  #--------------------------------------------------------------------------
  # ● 释放遮挡精灵
  #--------------------------------------------------------------------------
  def dispose_layer
    @sprite_layer_chosen.dispose
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
    case @state
    when :run
      update_frame
      update_up_and_drop
    when :wait
    end
    update_position
  end
  #--------------------------------------------------------------------------
  # ● 直接设置xy
  #--------------------------------------------------------------------------
  def set_xy(x = self.x, y = self.y)
    self.x = @x_f = @des_x = x
    self.y = @y_f = @des_y = y
  end
  #--------------------------------------------------------------------------
  # ● 设置目标xy与移速
  #--------------------------------------------------------------------------
  def set_des_xy(x = self.x, y = self.y, t = 30)
    @des_x = x
    @des_y = y
    @v_x = (@des_x - @x_f) * 1.0 / t
    @v_y = (@des_y - @y_f) * 1.0 / t
  end
  #--------------------------------------------------------------------------
  # ● 设置目标透明度与增量
  #--------------------------------------------------------------------------
  def set_des_opa(opa = 0, t = 30)
    @des_opa = opa
    @opa_f = self.opacity
    @v_opa = (@des_opa - @opa_f) * 1.0 / t
  end
  #--------------------------------------------------------------------------
  # ● 更新xy与透明度
  #--------------------------------------------------------------------------
  def update_position
    @v_x = 0 if (@des_x - @x_f).abs < 1
    @v_y = 0 if (@des_y - @y_f).abs < 1
    @v_opa = 0 if @des_opa == @opa_f.to_i
    @x_f += @v_x
    @y_f += @v_y
    @opa_f += @v_opa
    self.x = @x_f.to_i
    self.y = @y_f.to_i
    self.opacity = @opa_f.to_i
    update_layer
  end
  #--------------------------------------------------------------------------
  # ● 更新遮挡精灵
  #--------------------------------------------------------------------------
  def update_layer
    @sprite_layer_chosen.visible = @chosen
    if @sprite_layer_chosen.visible
      @sprite_layer_chosen.x = self.x
      @sprite_layer_chosen.y = self.y
      @sprite_layer_chosen.z = self.z + 1
      @sprite_layer_chosen.opacity = self.opacity
    end
  end

  #--------------------------------------------------------------------------
  # ● 开始投掷
  #--------------------------------------------------------------------------
  def run
    @state = :run
    # 设置抛起和掉落用到的参数
    @z_f = 0 # 用于计算放缩倍率
    @v_z = 9 + rand * 7 # 垂直向上的z值增速
    @a_z = -(rand / 2 + 0.5) # z的加速度
    # 设置一个小的随机xy偏移量
    set_des_xy(self.x + rand(51) - 25, self.y + rand(51) - 25, -(@v_z / @a_z)*2)
  end
  #--------------------------------------------------------------------------
  # ● 更新面的显示
  #--------------------------------------------------------------------------
  def update_frame
    @frame_count += 1
    return if @frame_count < @frame_max
    @frame_count = 0
    process_change_index
    update_bitmap
  end
  #--------------------------------------------------------------------------
  # ● 处理选择下一面
  #--------------------------------------------------------------------------
  def process_change_index
    case @index_order
    when :order # 正序切换
      @index_cur = (@index_cur + 1) % @index_max
    when :order_r # 逆序切换
      @index_cur = (@index_cur - 1 + @index_max) % @index_max
    when :rand # 随机切换
      @index_cur = rand(@index_max)
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新抛起和掉落
  #--------------------------------------------------------------------------
  def update_up_and_drop
    @z_f += @v_z
    @v_z += @a_z
    if @z_f <= 0 # 停止更新 进入选择
      @z_f = 0
      wait
    end
    update_zoom_with_z
    @sprite_layer_chosen.zoom_x = @sprite_layer_chosen.zoom_y = self.zoom_x
  end
  #--------------------------------------------------------------------------
  # ● 更新缩放
  #--------------------------------------------------------------------------
  def update_zoom_with_z
    # @z_f → zoom
    # 0 → 1.00； 100 → 2.00
    zoom = @z_f * 0.01 + 1.0
    self.zoom_x = self.zoom_y = zoom
  end
  #--------------------------------------------------------------------------
  # ● 停止随机
  #--------------------------------------------------------------------------
  def wait
    @state = :wait
  end
  #--------------------------------------------------------------------------
  # ● 停止中？
  #--------------------------------------------------------------------------
  def waiting?
    @state == :wait
  end
  #--------------------------------------------------------------------------
  # ● 处理选中
  #--------------------------------------------------------------------------
  def choose
    return if @chosen
    @chosen = true
    self.z += 10
  end
  def unchoose
    return if !@chosen
    @chosen = false
    self.z -= 10
  end
  #--------------------------------------------------------------------------
  # ● 获取当前面的序号
  #--------------------------------------------------------------------------
  def index
    @index_cur
  end
  #--------------------------------------------------------------------------
  # ● 获取当前面的数值
  #--------------------------------------------------------------------------
  def v
    @data.ids[@index_cur]
  end
  #--------------------------------------------------------------------------
  # ● 与指定精灵重叠？
  #--------------------------------------------------------------------------
  def overlap?(s)
    EAGLE_COMMON.sprite_on_sprite?(self, s)
  end
  #--------------------------------------------------------------------------
  # ● 指定点在自身内部？
  #--------------------------------------------------------------------------
  def point_in?(x, y)
    EAGLE_COMMON.point_in_sprite?(x, y, self, false)
  end
end

#==============================================================================
# ■ 玩家光标精灵
#==============================================================================
class Sprite_Dice_Player < Sprite
  include DICE
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(vp = nil)
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
    w = 5
    h = 5
    self.bitmap = Bitmap.new(w, h)
    [[0,2],[1,2],[2,2],[3,2],[4,2],[2,0],[2,1],[2,3],[2,4]].each do |p|
      self.bitmap.set_pixel(p[0], p[1], Color.new(255,100,100,255))
    end
    self.zoom_x = self.zoom_y = 2.0
  end
  #--------------------------------------------------------------------------
  # ● 重置位置
  #--------------------------------------------------------------------------
  def reset_position
    self.ox = self.width / 2
    self.oy = self.height / 2
    self.x = Graphics.width / 2 + self.ox
    self.y = Graphics.height / 2 + self.oy
  end
end

end # end of Module DICE
