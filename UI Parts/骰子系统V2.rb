#==============================================================================
# ■ 骰子系统V2 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【组件-通用方法汇总 by老鹰】与
#  【组件-位图绘制转义符文本 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-Dice"] = "2.0.0"
#==============================================================================
# - 2026.5.30.114 重构基本框架
#==============================================================================
# - 本插件增加了一套独立的骰子系统，能够在任意时刻投掷并返回结果
#------------------------------------------------------------------------------
# 【使用：投掷六面骰】
#
#  v, ps = DICE.d6(n = 1, ps={})
#
#    其中 n 为骰子数量，若不传入，则为 1
#    其中 ps 为可选参数：
#
#   （传入参数）
#     :ui => 布尔量,    # 若传入 false，则不显示投掷界面，直接返回结果（默认 true）
#     :t => 字符串,     # 显示在屏幕顶端的文字，转义符请用 \\ 代替 \
#     :auto => 布尔量,  # 若传入 true，则不可操作，自动投掷结束（默认 false）
#     :reroll => 数字,  # 允许进行重投掷的次数（默认0）
#     :type => 数字,    # 投掷结果的计算方式，默认 0 计算和
#                         0 计算和，1 计算最大值，2 计算最小值，3 计算极差
#     :num => 数字,     # 在最终结果中参与计算的骰子的数量
#                         默认取骰子总数，若小于总数，则需要选取相应数量的骰子
#     :in_x => 字符串,    # 骰子的初始位置（eval后需要返回数字）
#     :in_y => 字符串,
#     :in_dx => 字符串,   # 骰子的初始位置增量（eval后需要返回数字）
#     :in_dy => 字符串,
#     :in_t => 字符串，   # 骰子从初始位置移动到增量后位置的时间（每颗骰子独立计算）
#     :out_t => 字符串，  # 骰子移出的时间（每颗骰子独立计算）
#     :fin_x => 字符串,   # 骰子结算UI的位置（eval后需要返回数字）
#     :fin_y => 字符串, 
#
#   （传出参数）
#     :results => 数组,   # 在投掷完成后，生效的全部骰子的值
#     :value   => 数字，  # 在投掷完成后，依据 :type 类型计算得到的最终结果值
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
#  v, ps = DICE.d_actor(id, ps = {})
#  v, ps = DICE.d_enemy(id, ps = {})
#
#    其中 id 为数据库中角色的id，或 Game_Actor 的实例对象
#            为数据库敌人的id，或 Game_Enemy 的实例对象
#    其中 ps 与之上的一致，部分新增如下：
#   （传入参数）
#     :init => 二维数组     # 设置初始骰子
#                      比如 [ [1,2,3],[1,2,3] ] 就是设置两个三面骰。
#     :min  => 数字         # 设置最后返回的骰子的最少数量
#                      如果骰子数少于该值，则会自动补足 DICE_BATTLER_DEFAULT 骰子。
#
# - 示例：
#
#    条件分歧-脚本
#      DICE.d_actor(1,{:t=>"艾里克进行投掷！\n需要点数大于3才能成功哦。"}) > 3
#        → 查找1号角色的骰子进行投掷，和大于3时才会进入事件的当前分歧
#
#-----------------------------------------------------------
# 1. 设置角色的骰子：
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
#                     但如果设置了该项，则为查找 Dice_BG_字符串 的图片。
#                   同理，对于被选中骰子的遮挡图片，默认使用 Dice_Chosen 图片，
#                     但如果设置了该项，则为查找 Dice_Chosen_字符串 的图片。
#      name=字符串  # 骰子的显示名称
#                     默认使用 DICE_DEFAULT_NAME 设置的值。
#                     在 DICE_INFO 中还可以设置该名称的背景图片后缀、介绍。
#                     但如果同时设置了 bg=字符串 ，则DICE_INFO中的背景图片后缀无效。 
#
# - 注意：
#
#     如果没有任何设置，则默认投掷一颗六面骰。
#
# - 示例：
#
#    <dice 1 2 3> → 增加一个只有 1/2/3 三面的骰子
#
#    <dice 3 {bg=1}> → 增加一个只有 3 一面的骰子，背景图片为 Dice_BG_1
#
#-----------------------------------------------------------
# 2. 设置骰子的变化：
#
#   在数据库的备注栏中填入下式，可以设置骰子值的变化。
#   将按照 状态 > 角色/敌人 > 职业 > 装备 的顺序进行检索。
#   如果骰子的面已经发生变化，则不会再次发生变化。
#
#     <change 数量 Dice 旧值 to 新值>
#
#    其中 数量 为受到该条影响的骰子的数量
#    其中 旧值 为骰子变化前的值
#    其中 新值 为骰子变化后的值
#
# - 示例：
#
#    <change 2 Dice 1 to 2> → 将2个骰子的全部1修改为2。
#
#-----------------------------------------------------------
# 3. 设置投掷的参数：
#
#   在数据库的备注栏中填入下式，可以设置投掷的参数。
#   将按照 状态 > 角色/敌人 > 职业 > 装备 的顺序进行检索。
#
#     <dicep params>
#
#    其中 params 为变量参数字符串，由以下项任意组成（空格分隔）
# 
#      reroll=数字   → 增加重投掷次数
#      type=数字     → 结果的计算方式（取第一个查找到的设置）
#                       0 为和，1 为最大值，2 为最小值，3 为极差
#      num=数字      → 参与结果计算的骰子的数量（取第一个查找到的设置）
#                       默认取实际骰子数，若设置的 num 小于实际骰子数，
#                         则需要玩家手动选择相应数量的参与结果计算的骰子。
#
# - 示例：
#
#    <dicep reroll=1> - 增加 1 次重投掷次数
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
v, ps = DICE.call(ds, ps)

=end
#
#=============================================================================
module DICE
  #--------------------------------------------------------------------------
  # ● 骰子绘制相关
  #--------------------------------------------------------------------------
  # 骰子的背景图片
  #   可省略后缀名，需放置于 Graphics/System 目录下
  #   如果图片不存在，则自动绘制白底黑框
  BG_DEFAULT = "Dice_BG"
  
  # 背景图片不存在时，显示白底黑框
  #  → 宽度高度
  BG_DEFAULT_WH = 36
  #  → 边框宽度
  BG_DEFAULT_BORDER_WH = 2
  
  # 骰子被选择时的前景图片
  #  可省略后缀名，需放置于 Graphics/System 目录下
  BG_CHOSEN = "Dice_Chosen"
  BG_CHOSEN_OPACITY = 255  # 该前景图片的不透明度
  #  如果图片不存在，则绘制该纯色遮挡
  BG_CHOSEN_COLOR = Color.new(100,255,255,150)

  # 骰子中文字的颜色
  TEXT_COLOR = Color.new(0,0,0)
  # 骰子中文字的描边颜色
  TEXT_OUT_COLOR = Color.new(255,255,255,255)

  #--------------------------------------------------------------------------
  # ● 骰子名称相关
  #--------------------------------------------------------------------------
  # 未设置 name=字符串 时，骰子所显示的名称
  DICE_DEFAULT_NAME = "普通的骰子"
  
  # 预设骰子名称 及 对应的背景图片后缀bg 和 显示的简介
  DICE_INFO = {
  # 骰子的显示名称 => [骰子的背景图片的后缀名, 骰子的介绍]
    "普通的骰子" => [nil, "一颗平平无奇的骰子。"],  # 默认
    "临时的骰子" => [nil, "一颗临时借用的骰子。"],
    
    # 对于设置了 <dice 1,2,3,4,5,6 {name=勇者之骰}> 的骰子，
    #   则会查找 Dice_BG_brave 和 Dice_Chosen_brave 两张图片，没找到就用默认的。
    "勇者之骰"  => ["brave", "奇妙花纹的骰子，其上有专属签名。"],
  }

  #--------------------------------------------------------------------------
  # ● 骰子位置相关
  #--------------------------------------------------------------------------
  # 骰子的初始位置
  #   如果未设置 ps 中的相关参数，则使用此处设置（eval后获得整数）
  #  → 骰子移入时的初始位置  :in_x 和 :in_y 
  INIT_X   = "Graphics.width / 2"
  INIT_Y   = "Graphics.height / 2"
  #  → 骰子移入过程中的目的地  :in_dx 和 :in_dy
  INIT_DX  = "rand(241) - 120"
  INIT_DY  = "rand(201) - 100"
  #  → 移入移出所需帧数  :in_t 和 :out_t
  TIME_MOVE_IN  = 15
  TIME_MOVE_OUT = 15
  #  → 结算UI的位置  :fin_x 和 :fin_y 
  #     自动投掷时，骰子移出的目的地
  FIN_X    = "Graphics.width / 2"
  FIN_Y    = "Graphics.height / 2"

  #--------------------------------------------------------------------------
  # ● UI相关
  #--------------------------------------------------------------------------
  # 基础Z值
  BASE_Z = 200
  
  # 底部按键提示文本的字体大小
  HINT_FONT_SIZE = 14
  
  #  骰子在统一投掷前的等待帧数
  TIME_BEFORE_ROLL = 15
  
  # 重新投掷的按钮
  #  → UI的所在位置
  REROLL_X = "Graphics.width / 2"
  REROLL_Y = "Graphics.height - 150"
  #  → 初始的重投掷次数
  REROLL_INIT_COUNT = 0
  #  → 重投掷次数为0时，结束投掷前的等待帧数
  REROLL_END_WAIT = 20
  
  #--------------------------------------------------------------------------
  # ● 战斗相关
  #--------------------------------------------------------------------------
  # 给战斗者临时补充的骰子
  DICE_BATTLER_DEFAULT = [1,2,3,4,5,6]
  DICE_BATTLER_DEFAULT_NAME = "临时的骰子"
  
  #--------------------------------------------------------------------------
  # ● 正则表达式
  #--------------------------------------------------------------------------
  # 新增骰子
  #   如：<Dice: 1 2,0 1,1,0> - 增加一个 1/2/0/1/1/0 六个面的骰子
  # 【可选】在最后利用 {string} 来为骰子设置属性
  #   如：<dice 1 3 5 {bg=w1}> - 该骰子使用 Dice_BG_w1 作为背景图
  REGEXP_DICE_ADD = /<(?i:DICE):? ?([\d, -]*?) *(\{.*?\})?>/m

  # 修改指定数目骰子的全部数字为另一数字
  #  如： <change 2 Dice 1 to 2> - 将2个骰子的全部1修改为2
  REGEXP_DICE_CHANGE = /<change (\d+) dice:? ?([-\d]+) to ([-\d]+)>/i

  # 设置投掷的参数
  #  如： <dicep reroll=1> - 设置重投掷次数+1 
  REGEXP_DICE_PARAMS = /<dicep (.*?)>/i

  #--------------------------------------------------------------------------
  # ● 公共接口
  #--------------------------------------------------------------------------
  module_function

  #--------------------------------------------------------------------------
  # ● 投掷六面骰
  #--------------------------------------------------------------------------
  def d6(n = 1, ps = {}, box=RollBox_Base)
    ds = [[1,2,3,4,5,6]] * n
    data = []
    ds.each do |d|
      _d = Data_Dice.new(d)
      data.push(_d)
    end
    call(data, ps, box)
  end

  #--------------------------------------------------------------------------
  # ● 根据战斗角色所持骰子投掷
  #--------------------------------------------------------------------------
  def d_actor(b, ps = {}, box=RollBox_Base)
    b = get_battler(b, true)
    d_battler(b, ps, box)
  end
  def d_enemy(b, ps = {}, box=RollBox_Base)
    b = get_battler(b, false)
    d_battler(b, ps, box)
  end
  
  # 根据指定战斗者所持骰子投掷
  #   如果 battler 为数字，则默认为我方 ID 号角色
  def d_battler(battler, ps={}, box=RollBox_Base)
    b = get_battler(battler, true)
    data, ps2 = get_dices(b, ps[:init], ps[:min])
    ps = ps2.merge!(ps)
    call(data, ps, box)
  end
  
  # 根据多个战斗者所持骰子投掷
  #  战斗者自己的 dice_params 均无效
  #  battlers 数组中如果有数字，则为我方 ID 号角色
  def d_battlers(battlers, ps={}, box=RollBox_Base)
    data = []
    battlers.each do |b|
      battler = get_battler(b, actor=true)
      _data, ps2 = get_dices(battler, ps[:init], 0)
      data = data + _data
    end
    add_default_dices(data, ps[:min])
    call(data, ps, box)
  end
  
  # 获取战斗者实例
  def get_battler(b, actor=true)
    if actor
      b = $game_actors[b] if b.is_a?(Integer)
    else
      b = Game_Enemy.new(-1, b) if b.is_a?(Integer)
    end
    return b
  end
  
  # 获取战斗者的骰子组
  def get_dices(battler, init_dices=nil, min_num=1)
    datas = [] # [Data_Dice]
    changes = {} # obj => change_array
    params_array = []  # [ {}, {} ]
    if init_dices  # 初始骰子 [ [1,2,3,4,5,6], [1,2,3,4,5,6] ]
      init_dices.each { |d| datas.push(Data_Dice.new(d)) }
    end
    # 优先级： 状态 > 角色/敌人 > 职业 > 装备
    battler.feature_objects.each do |obj|
      next if obj.nil?
      obj.note.scan(REGEXP_DICE_ADD).each do |param|
        d = param[0].split(/[ ,]/).collect { |id| id.to_i }
        ps = param[1] ? EAGLE_COMMON.parse_tags(param[1][1...-1]) : {}
        datas.push(Data_Dice.new(d, ps))
      end
      obj.note.scan(REGEXP_DICE_CHANGE).each do |param|
        changes[obj] ||= []
        changes[obj].push(param)
      end
      obj.note.scan(REGEXP_DICE_PARAMS).each do |param|
        ps = EAGLE_COMMON.parse_tags(param[0])
        params_array.push(ps)
      end
    end
    # 之前的骰子可以应用持有人
    datas.each { |d| d.owner = battler }
    # 补足至最少数量的骰子
    add_default_dices(datas, min_num)
    # 应用更改
    changes.each do |obj, params|
      params.each do |param|  # 数量 更改前的值 更改后的值
        count = param[0].to_i; old_id = param[1].to_i; new_id = param[2].to_i
        datas.each do |data|
          #i = data.ids_init.index { |id| id == old_id }
          #p [i, old_id]
          #next if i.nil?
          data.ids_init.each_with_index do |id, i|
            next if id != old_id
            break if data.changed?(i)  # 存在变更，则不再变动
            data.add_change(i, obj, new_id)
          end
          count -= 1
          break if count == 0
        end
      end
    end
    # 获取投掷参数
    ps = { :reroll => get_init_reroll(battler), :type => nil, :num => nil }
    params_array.each do |h|
      ps[:reroll] += h[:reroll].to_i if h[:reroll]
      ps[:type]    = h[:type].to_i   if h[:type] and ps[:type].nil?
      ps[:num]     = h[:num].to_i    if h[:num]  and ps[:num].nil?
    end
    ps[:type] ||= 0
    ps[:num]  ||= 0
    return datas, ps
  end
  
  # 如果骰子数少于 min_num ，则补足至 min_num 数量
  def add_default_dices(datas, min_num)
    if min_num and min_num > 0 and datas.size < min_num 
      ps = { :name => DICE_BATTLER_DEFAULT_NAME }
      (min_num - datas.size).times do |i|
        datas.push(Data_Dice.new(DICE_BATTLER_DEFAULT, ps))
      end
    end
  end

  # 获取战斗者的初始重投掷次数
  def get_init_reroll(battler)
    REROLL_INIT_COUNT
  end

  #--------------------------------------------------------------------------
  # ● 投掷，返回 [骰子和, 投掷结果参数组]
  #  同时在 ps[:results] 存储了所有骰子结果的数组，如 [2,3,1...]
  #  data 为 Data_Dice 的实例数组
  #  box  为 使用的投掷工具类
  #--------------------------------------------------------------------------
  def call(data, ps = {}, box=RollBox_Base)
    return 0 if data.empty?
    rollbox = box.new
    rollbox.setup(data, ps)
    while true
      rollbox.update
      update_basic
      break if rollbox.finish?
    end
    ps[:results] = rollbox.results
    rollbox.dispose
    return ps[:value] || 0, ps
  end

  # 基础更新
  def update_basic
    SceneManager.scene.update_basic
  end

  # 辅助：eval表达式（安全转换）
  def eval_expr(expr, default = 0)
    return EAGLE_COMMON.eagle_eval(default).to_i unless expr
    EAGLE_COMMON.eagle_eval(expr).to_i rescue EAGLE_COMMON.eagle_eval(default).to_i
  end
end

#==============================================================================
# ■ Data_Dice – 骰子数据模型
#==============================================================================
class DICE::Data_Dice
  attr_reader   :ids_init, :ids, :changes, :params
  attr_accessor :owner

  # 初始化
  def initialize(ids, params = {})
    # 按序存储各面数值的数组（顺序不会变动）
    @ids_init = ids # 初始id数组
    @ids = ids.dup # 最终id数组
    @changes = {} # 面index => [old_id, new_id, obj]
    @params = params # 存储一些额外的参数
    @owner = nil # 持有角色
  end
  
  # 增加指定面的修改
  def add_change(index, obj, new_id)
    @changes[index] = [@ids_init[index], new_id, obj]
    @ids[index] = new_id
  end

  # 指定面存在修改？
  def changed?(index)
    @changes[index] != nil
  end

  # 指定面被含有图标的obj所修改？
  def changed_with_icon?(index)
    changed?(index) && @changes[index][2].icon_index
  end
end

#==============================================================================
# ■ Sprite_Dice – 单个骰子精灵
#==============================================================================
class DICE::Sprite_Dice < Sprite
  include DICE

  attr_reader  :data, :index_cur

  #--------------------------------------------------------------------------
  # ● 简化调用
  #--------------------------------------------------------------------------
  # 与指定精灵重叠？
  def overlap?(s)
    EAGLE_COMMON.sprite_on_sprite?(self, s)
  end
  
  # 指定点在自身内部？
  def point_in?(x, y)
    EAGLE_COMMON.point_in_sprite?(x, y, self, false)
  end

  #--------------------------------------------------------------------------
  # ● 外部调用方法
  #--------------------------------------------------------------------------
  def index     ; @index_cur;            end # 当前面的序号
  def v         ; @data.ids[@index_cur]; end # 当前面的值
  def owner     ; @data.owner;           end # 骰子持有者
  def name      ; @data.params[:name];   end # 骰子的显示名称

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

  # 初始化参数
  def init_params
    # 标志用变量
    @state = :init
    @chosen = false # 光标停留？（spriteset内变更该flag）
    # 移动用变量
    @pos = {}
    @x_f = @y_f = @opa_f = 0.0
    @des_x = @des_y = @des_opa = 0
    @v_x = @v_y = @v_opa = 0
    # 计数用
    @frame_count = 0 # 帧计数
    @frame_max = rand(8) + 5 # 每隔该帧数骰子面切换
    # 骰子面参数
    @index_max = @data.ids.size # 最大面数
    @index_cur = rand(@index_max) # 初始面
    # 投掷后的目标点数（如果nil则不设置，如果没有对应点数则无效）
    @v_set = nil

    # 骰子面切换顺序类型
    @index_order = :rand
    # 骰子所读取图片的后缀名
    @bg_surfix = @data.params[:bg]
    # 如果设置了名称，但没设置背景，则读取预设的背景
    if @bg_surfix == nil and self.name
      @bg_surfix = DICE_INFO[self.name][0]
    end
  end

  # 初始化各面位图
  def init_bitmaps
    @bitmaps = [] # 按序存储各个面的位图
    @data.ids.each_with_index do |id, index|
      t_bitmap = get_dice_bg_bitmap
      t = "#{id}"
      # 如果存在数值变动
      if @data.changed_with_icon?(index)
        t2 = @data.changes[index][0].to_s
        r = t_bitmap.text_size(t2)
        _y = -2
        _w = 10
        color = TEXT_COLOR
        t_bitmap.draw_text(0, _y, t_bitmap.width-_w, t_bitmap.height, t2, 1)
        t_bitmap.fill_rect((t_bitmap.width-_w-r.width)/2-1,
          t_bitmap.height/2+_y, r.width+2, 1, color)
        t_bitmap.draw_text(_w, _y*-1, t_bitmap.width-_w, t_bitmap.height, t, 1)
      else
        t_bitmap.draw_text(0, 0, t_bitmap.width+2, t_bitmap.height, t, 1)
      end
      @bitmaps.push(t_bitmap)
    end
  end

  # 切换位图（切换面时调用）
  def update_bitmap
    self.bitmap = @bitmaps[@index_cur]
    self.ox = self.width / 2
    self.oy = self.height / 2
  end

  # 获取各个面的背景
  def get_dice_bg_bitmap
    begin
      if @bg_surfix
        t_bitmap = Cache.system(BG_DEFAULT+"_#{@bg_surfix}").dup
      else
        t_bitmap = Cache.system(BG_DEFAULT).dup
      end
    rescue
      w = h = BG_DEFAULT_WH
      b = BG_DEFAULT_BORDER_WH
      t_bitmap = Bitmap.new(w, h)
      t_bitmap.fill_rect(0,0,w,h, Color.new(0,0,0))
      t_bitmap.fill_rect(b,b,w-2*b,h-2*b, Color.new(255,255,255))
    end
    t_bitmap.font.color = TEXT_COLOR
    t_bitmap.font.outline = true
    t_bitmap.font.out_color = TEXT_OUT_COLOR
    t_bitmap.font.shadow = false
    t_bitmap
  end

  # 初始化遮挡精灵
  def init_layer
    @sprite_layer_chosen = Sprite.new
    begin
      if @bg_surfix
        @sprite_layer_chosen.bitmap = Cache.system(BG_CHOSEN+"_#{@bg_surfix}") rescue nil
      end
      @sprite_layer_chosen.bitmap = Cache.system(BG_CHOSEN) if @sprite_layer_chosen.bitmap == nil
    rescue
      w = h = BG_DEFAULT_WH
      b = BG_DEFAULT_BORDER_WH
      t_bitmap = Bitmap.new(w, h)
      t_bitmap.fill_rect(b,b,w-2*b,h-2*b, BG_CHOSEN_COLOR)
      @sprite_layer_chosen.bitmap = t_bitmap
    end
    @sprite_layer_chosen.ox = @sprite_layer_chosen.width / 2
    @sprite_layer_chosen.oy = @sprite_layer_chosen.height / 2
    @sprite_layer_chosen.visible = @chosen
  end

  #--------------------------------------------------------------------------
  # ● 投掷用方法
  #--------------------------------------------------------------------------
  def run(v_set=nil)
    @state = :run
    # 设置目标点数
    @v_set = v_set
    # 设置抛起和掉落用到的参数
    @z_f = 0 # 用于计算放缩倍率
    @v_z = 9 + rand * 7 # 垂直向上的z值增速
    @a_z = -(rand / 2 + 0.5) # z的加速度
    # 设置一个小的随机xy偏移量
    set_des_xy(self.x + rand(51) - 25, self.y + rand(51) - 25, -(@v_z / @a_z)*2)
  end

  def running?  ; @state == :run;  end   # 投掷中？
  def wait      ; @state = :wait;  end   # 停止投掷
  def waiting?  ; @state == :wait; end   # 停止投掷了？
  def finish  ; @state = :finish; end    # 结算
  def finish? ; @state == :finish;end    # 结算中？
  def start ; self.visible = true; @state = :start; end  # 在finish后，重新移入
  def start?  ;  @state == :start; end   # 已经在移入？

  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
    case @state
    when :run
      update_up_and_drop
      update_frame
    when :wait
    when :finish 
      update_finish
    when :start
      update_start
    end
    update_position
  end

  #--------------------------------------------------------------------------
  # ● 直接设置xy
  #--------------------------------------------------------------------------
  def set_xy(x = self.x, y = self.y)
    self.x = @x_f = @des_x = x
    self.y = @y_f = @des_y = y
    update_layer
  end

  #--------------------------------------------------------------------------
  # ● 设置移动目的地xy、opa
  #--------------------------------------------------------------------------
  def set_des_xy(x = self.x, y = self.y, t = 30)
    @pos[:x0] = self.x
    @pos[:x1] = [[x, 0+self.width/2].max, Graphics.width-self.width/2].min
    @pos[:dx] = @pos[:x1] - @pos[:x0]
    @pos[:y0] = self.y
    @pos[:y1] = [[y, 0+self.height/2].max, Graphics.height-self.height/2].min
    @pos[:dy] = @pos[:y1] - @pos[:y0]
    @pos[:t] = t.to_i
    @pos[:c] = 0
    @pos[:ease] = "easeInSine"
  end

  def set_des_opa(opa = 0, t = 30)
    @pos[:opa0] = self.opacity
    @pos[:opa1] = opa 
    @pos[:dopa] = @pos[:opa1] - @pos[:opa0]
    @pos[:opat] = t.to_i
    @pos[:opac] = 0
    @pos[:opa_ease] = "easeInSine"
  end
  #--------------------------------------------------------------------------
  # ● 更新xy与透明度
  #--------------------------------------------------------------------------
  def update_position
    if @pos[:c]
      @pos[:c] += 1
      x = @pos[:c] * 1.0 / @pos[:t]
      if $imported["EAGLE-EasingFunction"]
        v = EasingFuction.call(@pos[:ease], x)
      else
        v = 1 - 2**(-10 * x)
      end
      self.x = @pos[:x0] + @pos[:dx] * v
      self.y = @pos[:y0] + @pos[:dy] * v
      @pos[:c] = nil if @pos[:c] == @pos[:t] 
    end
    if @pos[:opac]
      @pos[:opac] += 1
      x = @pos[:opac] * 1.0 / @pos[:opat]
      if $imported["EAGLE-EasingFunction"]
        v = EasingFuction.call(@pos[:opa_ease], x)
      else
        v = 1 - 2**(-10 * x)
      end
      self.opacity = @pos[:opa0] + @pos[:dopa] * v
      @pos[:opac] = nil if @pos[:opac] == @pos[:opat] 
    end
    update_layer
  end

  # 更新遮挡精灵
  def update_layer
    @sprite_layer_chosen.visible = @chosen
    if @sprite_layer_chosen.visible
      @sprite_layer_chosen.x = self.x
      @sprite_layer_chosen.y = self.y
      @sprite_layer_chosen.z = self.z + 1
      @sprite_layer_chosen.opacity = [self.opacity, BG_CHOSEN_OPACITY].min
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
      process_dice_end
    end
    update_zoom_with_z
    @sprite_layer_chosen.zoom_x = @sprite_layer_chosen.zoom_y = self.zoom_x
  end

  # 投掷完成后的处理
  def process_dice_end
    if @v_set
      _i = @data.ids.index(@v_set)
      @index_cur = _i if _i  # 如果找到了预设的点数，则置为其序号
      update_bitmap
    end
  end

  # 更新缩放
  def update_zoom_with_z
    # @z_f → zoom
    # 0 → 1.00； 100 → 2.00
    zoom = @z_f * 0.01 + 1.0
    self.zoom_x = self.zoom_y = zoom
  end

  #--------------------------------------------------------------------------
  # ● 更新当前面的显示
  #--------------------------------------------------------------------------
  def update_frame
    return if waiting?
    @frame_count += 1
    return if @frame_count < @frame_max
    @frame_count = 0
    process_change_index
    update_bitmap
  end

  # 处理选择下一面
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
  # ● 更新结算移出
  #--------------------------------------------------------------------------
  def update_finish
    return if !self.visible
    self.angle += 13
    self.zoom_x -= 0.05
    self.zoom_y -= 0.05
    self.visible = false if self.zoom_x <= 0
  end

  #--------------------------------------------------------------------------
  # ● 更新旋转放大移入（finish后重新移入）
  #--------------------------------------------------------------------------
  def update_start
    return wait if self.zoom_x >= 1.00
    self.angle -= 13
    self.zoom_x += 0.05
    self.zoom_y += 0.05
  end

  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    dispose_layer
    @bitmaps.each { |b| b.dispose }
    super
  end

  # 释放遮挡精灵
  def dispose_layer
    @sprite_layer_chosen.dispose
  end
end

#==============================================================================
# ■ Sprite_Dice_Player – 光标精灵
#==============================================================================
class DICE::Sprite_Dice_Player < Sprite
  include DICE

  # 初始化
  def initialize(vp = nil)
    super(vp)
    reset_bitmap
    reset_position
  end

  # 释放
  def dispose
    self.bitmap.dispose if self.bitmap
    super
  end

  # 重绘位图
  def reset_bitmap
    w = 5
    h = 5
    self.bitmap = Bitmap.new(w, h)
    [[0,2],[1,2],[2,2],[3,2],[4,2],[2,0],[2,1],[2,3],[2,4]].each do |p|
      self.bitmap.set_pixel(p[0], p[1], Color.new(255,100,100,255))
    end
    self.zoom_x = self.zoom_y = 2.0
  end

  # 重置位置
  def reset_position
    self.ox = self.width / 2
    self.oy = self.height / 2
    self.x = Graphics.width / 2 + self.ox
    self.y = Graphics.height / 2 + self.oy
  end
end

#==============================================================================
# ■ RollBox_Base – 骰子投掷界面与逻辑
#==============================================================================
class DICE::RollBox_Base
  include DICE

  attr_reader   :results
  
  #--------------------------------------------------------------------------
  # ● 通用方法
  #--------------------------------------------------------------------------
  # 获取文字颜色
  #     n : 文字颜色编号（0..31）
  def text_color(n)
    Cache.system("Window").get_pixel(64 + (n % 8) * 8, 96 + (n / 8) * 8)
  end
  
  # 获取各种文字颜色
  def normal_color;      text_color(0);   end;    # 普通
  def system_color;      text_color(16);  end;    # 系统
    
  # 绘制图标
  #     enabled : 有效的标志。false 的时候使用半透明效果绘制
  def draw_icon(bitmap, icon_index, x, y, enabled = true)
    _b = Cache.system("Iconset")
    rect = Rect.new(icon_index % 16 * 24, icon_index / 16 * 24, 24, 24)
    bitmap.blt(x, y, _b, rect, enabled ? 255 : 120)
  end
  
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize
    @data = []
    @ps = {}
    @sprite_dices = []
    @buttons = {}  # sprite => method(sprite_button, sprite_dice)
    @results = []
    @active = false  # 玩家可操作？
  end

  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    @sprite_dices.clear
    @buttons.clear
  end

  #--------------------------------------------------------------------------
  # ● 启动
  #--------------------------------------------------------------------------
  def setup(data, ps)  # data 为 Data_Dice 的数组
    @data = data
    @ps = ps
    check_params
    check_fiber
  end
  
  # 处理参数
  def check_params
    # 最终用于结果计算的骰子的数量
    @ps[:num] = @data.size if @ps[:num].nil? or @ps[:num] <= 0
  end
  
  # 处理投掷用fiber
  def check_fiber
    return fiber_no_ui if @ps[:ui] == false
    @fiber = Fiber.new { fiber_main }
  end

  # 投掷完成？
  def finish?;  @fiber == nil;  end

  # 最大重投掷次数
  def num_reroll
    @ps[:reroll].to_i rescue 0
  end
  
  #--------------------------------------------------------------------------
  # ● 主线程（无UI）
  #--------------------------------------------------------------------------
  def fiber_no_ui
    # 每个骰子获得一个随机值
    vs = @data.collect { |d| d.ids.sample(1)[0] }
    # 挑选出指定数量的骰子
    vs = vs.sample(@ps[:num]) if @ps[:num] < vs.size
    @results = vs
    compute_result
    @fiber = nil
  end

  # 从 @results 计算投掷结果
  def compute_result
    case @ps[:type]
    when 1 ; @ps[:value] = @results.max  # 返回最大值
    when 2 ; @ps[:value] = @results.min  # 返回最小值
    when 3 ; @ps[:value] = @results.max - @results.min  # 返回极差
    else   ; @ps[:value] = @results.inject(0) { |v, s| s += v }  # 返回和
    end
    @ps[:results] = @results
  end
  
  #--------------------------------------------------------------------------
  # ● 主线程
  #--------------------------------------------------------------------------
  def fiber_main
    init_data
    init_ui
    init_dices
    init_dice_buttons
    move_in
    roll_all
    wait_for_player
    compute_result
    move_out
    dispose_dices
    dispose_ui
    @fiber = nil
  end

  # 初始化数据
  def init_data
    @max_reroll = num_reroll
    @remaining_reroll = @max_reroll
    @n_finish = 0  # 已经确定的骰子数量
  end

  #--------------------------------------------------------------------------
  # ● UI-初始化
  #--------------------------------------------------------------------------
  def init_ui
    @sprite_bg = create_background
    @sprite_bg_info = create_info_sprite
    @sprite_hint = create_hint_sprite
    @sprite_player = Sprite_Dice_Player.new
    @sprite_player.z = BASE_Z + 100
    @sprite_player.visible = false
    @sprite_info2 = Sprite.new  # 骰子信息展示板（当前选中骰子）
    @sprite_info2.z = BASE_Z + 30
    @sprite_info3 = create_text_sprite(@ps[:t])  # 信息文本，由 ps[:t] 传入
    
    @drag_token = nil
    @drag_dx = @drag_dy = 0
    @player_state = { :last_input => nil, :last_input_c => 0, :d => 1 }
    @selected_token = nil
  end

  # 背景
  def create_background
    bg = Sprite.new
    bg.z = BASE_Z
    bg.bitmap = Bitmap.new(ui_max_x, ui_max_y)
    bg.bitmap.fill_rect(0, 0, bg.width, bg.height, Color.new(0,0,0,120))
    bg
  end
  def ui_max_x; Graphics.width; end
  def ui_max_y; Graphics.height; end

  # 背景字
  def create_info_sprite
    sp = Sprite.new
    sp.z = BASE_Z + 1
    sp.zoom_x = sp.zoom_y = 3.0
    sp.bitmap = Bitmap.new(Graphics.height, Graphics.height)
    sp.bitmap.font.size = 48
    sp.bitmap.font.color = Color.new(255,255,255,10)
    sp.bitmap.draw_text(0,0,sp.width,64, "ROLL", 0)
    sp.angle = -90
    sp.x = Graphics.width + 48
    sp.y = 0
    sp
  end

  # 底部按键提示文本
  def create_hint_sprite
    sp = Sprite.new
    sp.z = BASE_Z + 20
    sp.bitmap = Bitmap.new(Graphics.width, 24)
    sp.bitmap.font.size = HINT_FONT_SIZE
    sp.oy = sp.height
    sp.y = Graphics.height
    update_hint_text(sp)
    sp
  end
  # 重绘按键提示
  def update_hint_text(sprite)
    text = "方向键 - 移动光标 | "
    text += "确定键 - 拿起/放下 | " if @selected_token
    text += "取消键 - 自动完成投掷"
    text = "- 自动投掷，不可操作 -" if auto_mode?
    sprite.bitmap.clear
    sprite.bitmap.draw_text(0, 2, sprite.width, sprite.height, text, 1)
    sprite.bitmap.fill_rect(0, 0, sprite.width, 1, Color.new(255,255,255,120))
  end

  # 文本精灵
  def create_text_sprite(text)
    return Sprite.new if text.nil? || text.empty?
    sp = Sprite.new
    sp.z = BASE_Z + 5
    sp.bitmap = Bitmap.new(300, 64)
    sp.bitmap.clear
    sp.x = Graphics.width / 2
    sp.y = 32
    sp.ox = sp.width / 2
    sp.oy = 0
    draw_text_ex(sp.bitmap, text, 16, 1)
    sp
  end
  # 绘制文本
  def draw_text_ex(bitmap, text, font_size = 16, align = 1)
    ps = { font_size: font_size, x0: 0, y0: 0, w: bitmap.width, lhd: 2,
           font_color: Color.new(255,255,255), ali: align }
    d = Process_DrawTextEX.new(text, ps, bitmap)
    d.run(true)
  end

  #--------------------------------------------------------------------------
  # ● UI-重绘骰子信息面板
  #--------------------------------------------------------------------------
  def redraw_dice_info_panel
    s = @sprite_info2
    s.bitmap.clear if s.bitmap
    return if @selected_token == nil

    text = get_dice_info_text(@selected_token)
    ps = { :font_size => 18, :x0 => 8, :y0 => 8, :lhd => 2, :ali => 1 }
    ps[:font_color] = Color.new(255,255,255)
    d = Process_DrawTextEX.new(text, ps)
    d.run(false)
    
    s.bitmap.dispose if s.bitmap
    s.bitmap = Bitmap.new(d.width+ps[:x0]*2, d.height+ps[:y0]+4)
    if $imported["EAGLE-UtilsDrawing2"]
      # 绘制圆角矩形
      s.bitmap.fill_rounded_rect(0, 0, s.width, s.height-4, 4, Color.new(0,0,0,220))
    else
      # 绘制普通矩形
      s.bitmap.fill_rect(0, 0, s.width, s.height-4, Color.new(0,0,0,220))
    end
    
    d.bind_bitmap(s.bitmap)
    d.run(true)
    
    # 绘制底部箭头
    [ [-3,1, 7], [-2,2, 5], [-1,3, 3], [0,4, 1] ].each do |xyw|
      s.bitmap.fill_rect(s.width / 2 + xyw[0], s.height - 5 + xyw[1], xyw[2], 1, 
        Color.new(0,0,0,150))
    end
    
    update_dice_info_position(@selected_token)
  end

  # 获取指定骰子的信息文本
  def get_dice_info_text(dice_sprite)
    text = ""
    
    # 骰子的名称和各面的值
    name = dice_sprite.data.params[:name]
    name ||= DICE::DICE_DEFAULT_NAME
    
    t = ""
    dice_sprite.data.ids.each_with_index do |_v, _i|
      _c = _i == dice_sprite.index_cur ? 17 : 7
      t += "\ec[#{_c}]#{_v}\ec[0] "
    end
    t[-1] = ''
    text += " 「" + name + "」(" + t + ") "
    
    # 如果不在战斗中，则显示骰子来源
    if !SceneManager.scene_is?(Scene_Battle) and dice_sprite.owner
      t1 = ""
      t1 += "[持有者]\ec[17]#{dice_sprite.owner.name}\ec[0]"
      text += "\\ln" + t1 if t1 != ""
    end
    
    # 如果有数值改变，则加入
    change = dice_sprite.data.changes[dice_sprite.index]
    if change
      t1 = ""
      # change = [old_id, new_id, obj]
      icon = change[2].icon_index rescue 0
      t1 += "[变化]\\i[#{icon}]#{change[2].name}"
      t1 += " \ec[7]#{change[0]}\ec[0] → \ec[17]#{change[1]}\ec[0]"
      text += "\\ln" + t1 if t1 != ""
    end
    
    # 如果有说明，则加入
    description = DICE::DICE_INFO[name][1] || ""
    text += "\\ln\ec[8]" + description + "\ec[0]" if description != ""
    
    return text
  end

  # 更新骰子信息精灵的位置
  def update_dice_info_position(dice_sprite)
    s = @sprite_info2
    return @sprite_info2.visible = false if dice_sprite == nil
    @sprite_info2.visible = true
    s.ox = s.width / 2
    s.oy = s.height
    s.x = dice_sprite.x - dice_sprite.ox + dice_sprite.width / 2
    s.y = dice_sprite.y - dice_sprite.oy - 4
  end
  
  #--------------------------------------------------------------------------
  # ● 初始化骰子
  #--------------------------------------------------------------------------
  def init_dices
    @sprite_dices = @data.collect { |d| Sprite_Dice.new(d) }
  end

  # 临时新增一颗骰子，并等待移入完成
  def add_dice(data_dice, x, y, dx, dy, t=20)
    s = Sprite_Dice.new(data_dice)
    s.z = BASE_Z + 10
    s.set_xy(x, y)
    s.set_des_opa(255, t)
    s.set_des_xy(x + dx, y + dy, t)
    @sprite_dices.push(s)
    @n_finish -= 1
    t.times { Fiber.yield }
    return s
  end

  # 骰子移入
  def move_in
    ts = []
    @sprite_dices.each do |s|
      s.z = BASE_Z + 10
      t = eval_expr(@ps[:in_t], TIME_MOVE_IN)
      ts.push(t)
      x0 = eval_expr(@ps[:in_x], INIT_X)
      y0 = eval_expr(@ps[:in_y], INIT_Y)
      s.set_xy(x0, y0)
      dx = eval_expr(@ps[:in_dx], INIT_DX)
      dy = eval_expr(@ps[:in_dy], INIT_DY)
      s.set_des_xy(x0 + dx, y0 + dy, t)
      s.set_des_opa(255, t)
    end
    ts.max.times { Fiber.yield }
  end

  # 骰子移出
  def move_out(t_min=40)
    ts = [t_min]
    @sprite_dices.each do |s|
      next if s.finish?
      t = eval_expr(@ps[:out_t], TIME_MOVE_OUT)
      ts.push(t)
      s.set_des_opa(0, t)
    end
    ts.max.times { Fiber.yield }
  end
  
  # 等待指定骰子移出动画结束
  def update_until_dice_finish(dice_sprite)
    dice_sprite.finish
    loop do
      Fiber.yield
      break if !dice_sprite.visible
    end
  end

  #--------------------------------------------------------------------------
  # ● 初始化可以与骰子交互的精灵
  #--------------------------------------------------------------------------
  def init_dice_buttons
    init_sprite_reroll
    init_sprite_finish
  end
  
  # 注册骰子可以激活的按钮精灵
  def register_button(sprite_button, method)
    @buttons[sprite_button] = method
  end
  
  # 取消注册指定按钮精灵
  def delete_button(sprite_button)
    @buttons.delete(sprite_button)
  end
  
  # 对全部已注册的按钮精灵进行统一处理
  def all_buttons 
    @buttons.each { |s, m| yield s if s and block_given? }
  end
  
  # 显示/隐藏按钮
  def show_all_buttons
    all_buttons { |s| s.visible = true  }
  end
  def hide_all_buttons
    all_buttons { |s| s.visible = false  }
  end
  
  # 绘制按钮的矩形底，带有上下两个标题
  def draw_button_rect(bitmap, text_top="", text_down="", 
     border_color=Color.new(255,255,255,255), border_w=1, 
     bg_color=Color.new(0,0,0,150), offset=8)
    # text_top 为顶部居中显示的文字
    # text_down 为底部居中显示的文字
    # border_color 为矩形边框的颜色
    # border_w 为矩形边框的宽度
    # bg_color 为矩形背景的颜色
    # offset 为上下左右的留空像素宽度
    # 先绘制一层边框颜色的底，再绘制中间的背景颜色
    if $imported["EAGLE-UtilsDrawing2"]
      # 绘制圆角矩形
      bitmap.fill_rounded_rect(offset, offset, bitmap.width-offset*2, bitmap.height-offset*2, 4, border_color)
      bitmap.fill_rounded_rect(offset+border_w, offset+border_w, 
        bitmap.width-offset*2-border_w*2, bitmap.height-offset*2-border_w*2, 3, bg_color)
    else
      # 绘制普通矩形
      bitmap.fill_rect(offset, offset, bitmap.width-offset*2, bitmap.height-offset*2,
        border_color)
      r_bg = Rect.new(offset + border_w, offset + border_w, 
        bitmap.width - offset*2 - border_w*2, bitmap.height - offset*2 - border_w*2)
      bitmap.fill_rect(r_bg, bg_color)
    end
    if text_top and text_top != ""
      # 计算文字宽度高度
      r_t = bitmap.text_size(text_top)
      _h = r_t.height
      # 计算实际绘制位置，且左右增加点宽度
      _d = 2
      r_t.x = bitmap.width / 2 - r_t.width / 2 - _d
      r_t.y = offset
      r_t.width = r_t.width + _d * 2
      r_t.height = border_w
      # 清除文字区域的边框（背景颜色不清除）
      bitmap.clear_rect(r_t)
      # 文字绘制
      bitmap.font.color = border_color
      bitmap.draw_text(0, 0, bitmap.width, _h, text_top, 1)
    end
    if text_down and text_down != ""
      # 计算文字宽度高度
      r_t = bitmap.text_size(text_down)
      _h = r_t.height
      # 计算实际绘制位置，且左右增加点宽度
      _d = 2
      r_t.x = bitmap.width / 2 - r_t.width / 2 - _d
      r_t.y = bitmap.height - offset - border_w
      r_t.width = r_t.width + _d * 2
      r_t.height = border_w
      # 清除文字区域的边框（背景颜色不清除）
      bitmap.clear_rect(r_t)
      # 文字绘制
      bitmap.font.color = border_color
      bitmap.draw_text(0, bitmap.height-_h, bitmap.width, _h, text_down, 1)
    end
  end

  #--------------------------------------------------------------------------
  # ● 按钮：重新投掷
  #--------------------------------------------------------------------------
  def init_sprite_reroll
    @sprite_reroll = Sprite.new 
    @sprite_reroll.x = eval_expr(REROLL_X)
    @sprite_reroll.y = eval_expr(REROLL_Y)
    @sprite_reroll.z = BASE_Z + 3
    @sprite_reroll.bitmap = Bitmap.new(160, 64)
    @sprite_reroll.ox = @sprite_reroll.width / 2
    @sprite_reroll.oy = @sprite_reroll.height / 2
    redraw_reroll if @max_reroll > 0
    register_button(@sprite_reroll, method(:button_method_reroll))
  end
  def redraw_reroll
    s = @sprite_reroll
    s.bitmap.clear
    s.bitmap.font.size = 18
    draw_button_rect(s.bitmap, "重新投掷", "剩 #{@remaining_reroll} 次", Color.new(255,255,153,255))
    _y = s.bitmap.height / 2 - 18 / 2
    s.bitmap.font.color = normal_color
    s.bitmap.font.color.alpha = 80
    s.bitmap.draw_text(0, _y, s.width, 18, "拖动骰子到此处", 1)
  end
  def button_method_reroll(button_sprite, dice_sprite)
    if process_dice_reroll?(dice_sprite)
      process_dice_reroll(dice_sprite)
    end
  end
  def process_dice_reroll?(dice_sprite)
    return false if @remaining_reroll <= 0
    return true
  end
  def process_dice_reroll(dice_sprite)
    process_player_finish
    @remaining_reroll -= 1
    reroll(dice_sprite)
    redraw_reroll
    process_player_start
  end

  #--------------------------------------------------------------------------
  # ● 按钮：结算
  #--------------------------------------------------------------------------
  def init_sprite_finish
    @sprite_finish = Sprite.new 
    @sprite_finish.x = @ps[:fin_x] ? eval_expr(@ps[:fin_x]) : eval_expr(FIN_X)
    @sprite_finish.y = @ps[:fin_y] ? eval_expr(@ps[:fin_y]) : eval_expr(FIN_Y)
    @sprite_finish.z = BASE_Z + 3
    @sprite_finish.bitmap = Bitmap.new(96, 80)
    @sprite_finish.ox = @sprite_finish.width / 2
    @sprite_finish.oy = @sprite_finish.height / 2
    redraw_finish
    register_button(@sprite_finish, method(:button_method_finish))
  end
  def redraw_finish
    compute_result
    type_str = case @ps[:type]
               when 1 then "（最大值）"
               when 2 then "（最小值）"
               when 3 then "（极差）"
               else "（和）"
               end
    s = @sprite_finish
    s.bitmap.clear
    s.bitmap.font.size = 18
    draw_button_rect(s.bitmap, "结算", "(#{@n_finish}/#{@ps[:num]})")
    
    s.bitmap.draw_text(0, 18, s.width, 18, type_str, 1)
    s.bitmap.font.size = 24
    s.bitmap.draw_text(0, 20, s.width, s.height-20, "#{@ps[:value]}", 1)
  end
  def button_method_finish(button_sprite, dice_sprite)
    process_player_finish
    @results.push(dice_sprite.v)
    @n_finish += 1
    redraw_finish
    update_until_dice_finish(dice_sprite)
    process_player_start
  end

  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    @fiber.resume if @fiber
    update_dices
    update_ui if @active
  end

  # 骰子更新
  def update_dices
    @sprite_dices.each { |s| s.update }
  end

  # UI更新
  def update_ui
  end
  
  #--------------------------------------------------------------------------
  # ● 骰子投掷
  #--------------------------------------------------------------------------
  # 投掷全部骰子
  def roll_all
    TIME_BEFORE_ROLL.times { Fiber.yield }
    roll
  end
  
  # 投掷指定骰子
  def roll(s = nil)
    f = @active
    @active = false
    if s == nil
      @sprite_dices.each { |s| s.run }
    else
      s.unchoose
      s.run
    end
    Fiber.yield until all_dices_stopped?
    @active = f
  end

  # 重新投掷指定骰子，可以指定值
  def reroll(s, v=nil) # v 为重投掷后必定投出的值
    f = @active
    @active = false
    s.unchoose
    s.run(v)
    Fiber.yield until all_dices_stopped?
    @active = f
  end

  # 全部骰子均投掷完成？
  def all_dices_stopped?
    @sprite_dices.none?(&:running?)
  end

  #--------------------------------------------------------------------------
  # ● 处理玩家操作
  #--------------------------------------------------------------------------
  def wait_for_player
    if auto_mode?
      process_auto_finish
      return
    end
    @flag_player_key_finish = false
    process_player_start
    loop do
      Fiber.yield
      break if @flag_player_key_finish
      update_when_process_key
      update_cursor_movement
      update_cursor_states
      handle_input
    end
    process_player_finish
  end

  # 自动模式？
  def auto_mode?
    return true if @ps[:auto] == true 
    return false if @ps[:num] < @data.size
    return @max_reroll == 0
  end

  # 玩家操作开始/结束
  def process_player_start
    @active = true
    @sprite_player.visible = true
  end
  def process_player_finish
    @active = false
    @sprite_player.visible = false
    update_dice_info_position(nil)
  end

  # 玩家处理时的每帧更新
  def update_when_process_key
    @flag_player_key_finish = true if @n_finish >= @ps[:num]
    @flag_player_key_finish = true if !@sprite_dices.any? { |s| s.waiting? }
  end

  # 更新光标
  def update_cursor_movement
    s = @sprite_player
    if @player_state[:last_input] == Input.dir4
      @player_state[:last_input_c] += 1
      @player_state[:d] += 1 if @player_state[:last_input_c] % 5 == 0
    else
      @player_state[:d] = 1
      @player_state[:last_input] = Input.dir4
      @player_state[:last_input_c] = 0
    end
    d = @player_state[:d]
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
    # 更新鼠标
    if $imported["EAGLE-MouseEX"] && MOUSE_EX.in?
      s.x = MOUSE_EX.x
      s.y = MOUSE_EX.y
    end
  end

  # 更新骰子选择状态
  def update_cursor_states
    s = @sprite_player
    # 处理拖拽中
    if @drag_token
      @drag_token.set_xy(s.x - @drag_dx, s.y - @drag_dy)
      update_dice_info_position(@drag_token)
      return
    end
    # 处理骰子被选中
    if @selected_token && @selected_token.point_in?(s.x, s.y)
      # 之前选中的还是处于被选中状态
    else
      # 选中了一个新的
      last_selected = @selected_token
      @selected_token = nil
      @sprite_dices.each do |sd|
        break @selected_token = sd if sd.point_in?(s.x, s.y)
      end
      last_selected.unchoose if last_selected
      if @selected_token # 选中
        @selected_token.choose
        Sound.play_cursor
        update_hint_text(@sprite_hint)
      elsif last_selected  # 从选中变成没有选中
        update_hint_text(@sprite_hint)
      end
      redraw_dice_info_panel
      update_dice_info_position(@selected_token)
    end
  end

  # 处理玩家按键
  def handle_input
    f = Input.trigger?(:C)
    f |= MOUSE_EX.up?(:ML) if $imported["EAGLE-MouseEX"]
    handle_input_ok if f
    f = Input.trigger?(:B)
    f |= MOUSE_EX.up?(:MR) if $imported["EAGLE-MouseEX"]
    handle_input_cancel if f
  end
  
  # 按下了确定键 →
  def handle_input_ok
    if @drag_token
      # 如果在拖拽中，则放下骰子
      process_dice_drag_end
      @drag_token = nil
    elsif @selected_token
      # 如果选中了一颗骰子，则开始拖拽
      @drag_token = @selected_token
      @drag_dx = @sprite_player.x - @drag_token.x
      @drag_dy = @sprite_player.y - @drag_token.y
      process_dice_drag_start
    end
  end
  
  # 按下了取消键 →
  def handle_input_cancel
    if process_key_check_finish?
      # 处理自动结算
      process_auto_finish
      @flag_player_key_finish = true  # 结束玩家操控环节
    end
  end

  # 开始拖动骰子时
  #   @drag_token 为被拖起来的骰子精灵
  def process_dice_drag_start
  end

  # 放下骰子时
  #   @drag_token 为被放下的骰子精灵
  def process_dice_drag_end
    @buttons.each do |s, m|
      next if !s.visible 
      next if !EAGLE_COMMON.point_in_sprite?(@sprite_player.x, @sprite_player.y, s)
      process_dice_drag_end_success1
      m.call(s, @drag_token) # 调用之前注册的方法
      process_dice_drag_end_success2
    end
  end
  def process_dice_drag_end_success1
    # 激活了任一按钮，取消骰子的选中状态
    @selected_token.unchoose if @selected_token
    @selected_token = nil
  end
  def process_dice_drag_end_success2
  end

  # 自动结算
  def process_key_check_finish?
    return true
  end
  def process_auto_finish
    v = @ps[:num] - @n_finish
    s = @sprite_dices.select { |s| s.waiting? }
    s_results = s.sample(v)
    t = 20
    s_results.each { |s| 
      s.set_des_xy(@sprite_finish.x, @sprite_finish.y, t)
      @results.push(s.v)
      @n_finish += 1
    }
    t.times { Fiber.yield }
    redraw_finish
    s_results.each { |s| s.finish }
  end

  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose_dices
    @sprite_dices.each { |s| s.dispose }
    @sprite_dices.clear
  end
  
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
  # ● 扩展用
  #--------------------------------------------------------------------------
  # UI-渐隐
  def ui_fade_out(d_opa=-13, t=20)
    t.times do |i|
      Fiber.yield
      ui_change_opacity(d_opa)
    end
  end
  
  # UI-渐显
  def ui_fade_in(d_opa=+13, t=20)
    t.times do |i|
      Fiber.yield
      ui_change_opacity(d_opa)
    end
  end

  # UI-更改不透明度（骰子不受影响）
  def ui_change_opacity(d_opa)
    instance_variables.each do |varname|
      ivar = instance_variable_get(varname)
      if ivar.is_a?(Sprite) && !ivar.disposed?
        ivar.opacity += d_opa
      end
    end
  end
end
