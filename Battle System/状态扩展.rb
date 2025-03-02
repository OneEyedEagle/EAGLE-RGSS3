#==============================================================================
# ■ 状态扩展 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【组件-通用方法汇总 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-StateEX"] = "1.0.1"
#==============================================================================
# - 2025.2.5.8 
#==============================================================================
# - 本插件针对状态系统进行了扩展，可能需要一些脚本知识以兼容其他战斗系统
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# ● 对 数据库-状态 的扩展
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# 【状态的最大叠加层数】
#
# - 现在 状态 可以反复附加，直至达到预设的上限。
#
# - 在 数据库-状态 的备注中填写：
# 
#      <层数 数字> 或 <level 数字>
#
#   来设置该状态最多可被添加的层数
#
# - 注意：
#
#  1. 状态在成功叠加后，将刷新其回合计数。
# 
#  2. 同ID的状态共用一个回合计数，
#     即不管目前有多少层，都会在回合计数归零时一起消除。
#     调用 battler.remove_state(state_id) 也会将全部层数一起消除。
#     如果想减少层，请使用 battler.reduce_state_level(state_id, v) 来指定消除层数。
#
#  3. 数据库-状态的特殊能力、添加能力等都会按层数进行倍增、倍乘。
#
# - 战斗者Battler 新增方法：
#
#  获取已附加状态的层数：
#
#    .state_level(state_id)
#
#  减少指定状态的指定层数：
#
#    .reduce_state_level(state_id, v)
#
#      其中 v 为层数，如果传入 nil 或不传入或大于已有层数，则消除全部层数。
#
#------------------------------------------------------------------
# 【状态的附加属性】
#
# - 现在 状态 可以像装备一样，给角色附加额外的属性值了。
#
# - 在 数据库-状态 的备注中填写：
#
#     <params>...</params>
#
#   其中 ... 替换为 属性名=数字 的反复组合
#    （数据库中的八项属性的名称分别为 mhp mmp atk def mat mdf agi luk）
#    （数字可以为负数，也可以为百分数）
#
#   如 <params>mhp=50</params> 代表 最大生命值+50点
#   如 <params>mhp=5%</params> 代表 最大生命值+5%
#   如 <params>mat=5 luk=-3</params> 代表 魔法攻击+5点、幸运-3点
#
# - 注意：
#
#  1. 状态附加的属性值，将在全部计算完成后附加，
#     即不受到 数据库中普通能力-属性倍率、战斗中属性buff 的影响
#
#  2. 状态附加的百分比属性值，将与 战斗中属性buff 进行累加，作为最终的倍率
#     即属性的倍率 = 1 + 该属性战斗中buff层数 x 0.25 + 状态的属性倍率和
#
#     如 被附加了带有<params>mhp=5%</params>的状态，且 MHP 的buff层数为 0，
#        则该角色的最终MHP = 原始MHP * (1 + 0 x 0.25 + 0.05)
#
#------------------------------------------------------------------
# 【状态的计数】
#
# - 现在 状态 的回合计数将会在更准确的时机进行减少。
#
# - 针对 数据库-状态 中设置了 回合结束时消除 的状态，将在回合结束时计数-1。
#
# - 针对 数据库-状态 中设置了 行动结束时消除 的状态，将在行动结束时计数-1。
#
# - 特别的，如果是本回合/本次行动才附加的状态，则不会进行计数-1。
#
#------------------------------------------------------------------
# 【死亡时也保留的状态】
#
# - 现在可以设置 状态 在角色死亡时是否保留了。
#
# - 在 数据库-状态 的备注中填写：
#
#     <死亡保留> 或者 <reserve when die>
#
#   则该状态在角色死亡时，将不会被清除。
#
#------------------------------------------------------------------
# 【高级：状态的自动减少时机的扩展】
#
# - 在默认中，状态的自动减少时机仅有两种，分别为 1 行动结束时，2 回合结束时
#
# - 此处新增给状态设置全新的自动减少时机的数字，
#   在 数据库-状态 的备注中填写：
#
#     <set timing 数字>
#
#   然后，你可以在对应时机中调用战斗者的 update_state_turns_ex(数字) 方法，
#     在该时机将对应的全部状态进行 计数-1 处理。
#
# - 注意：
#
#     本插件中，对于当前行动/回合中附加的新状态，将不会处理 计数-1，
#       但如果你自己添加的时机在 on_action_end（其中清除了附加新状态的信息）后，
#       那么依然会执行 计数-1 。
#
#     你可以先调用 eagle_restore_added_states ，
#       将 on_action_end 清除前的附加新状态信息再读取出来，
#     之后再调用你的 update_state_turns_ex(数字) 方法，
#     最后调用 @result.added_states.clear 清除，
#       这样你添加的时机也能让新附加状态不处理 计数-1 了。
#
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# ● 全新设计！新的状态对象
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#
# - 由于在默认的 Game_BattlerBase 中，仅存储了状态ID，连状态回合计数都是独立存储，
#   这导致无法利用状态来计算伤害，只能依靠回合结束时的自动回复来做中毒。
#
# - 本插件新增了全新设计的 Data_StateEX 状态对象，与默认的状态分别处理，
#   不仅兼容上述的全部功能，还可以各自独立计数，并编写伤害公式进行伤害处理。
#
# - 注意：本状态对象与默认状态互不干扰，仅 state?(state_id) 修改为两类状态都检索。
#
# - 战斗者Battler 新增方法：
#
#  附加 1 个状态对象：
#
#   .add_state_ex(state_id, battler_from=nil, count=nil, ps={})
#
#      其中 state_id 为数据库-状态的ID，
#              本质还是基于数据库中的状态设置，但增加了一些在备注栏中编写的设置。
#
#      其中 battler_from 为主动附加该状态的战斗者，比如在伤害公式中传入 a 技能使用者，
#              在设计基于使用者的攻击等属性进行中毒伤害计算时会有用处。
#
#      其中 count 为计数，每次行动结束/回合结束时 -1 ，当为0时该状态解除，
#              （注意：当状态不可叠加时，将作为新的状态附加，并独立计数。）
#              如果传入 nil，则取 数据库-状态 中的回合数的数字。
#
#      其中 ps 为后续扩展用Hash。
#
#  解除指定ID的状态对象 v 个或 v 层：
#
#   .remove_state_ex(state_id, v=nil)
#
#      其中 state_id 为数据库-状态的ID。
#
#      其中 v 为解除的数量，如果传入 nil，则解除全部该ID的状态对象；
#         （对于可叠加的状态）为解除的层数，nil时将解除该ID的状态对象的全部层数。
#
#  是否已经附加了v个指定ID的状态对象？
#
#   .state_ex?(state_id, v=1)
#
#  获取指定ID的状态对象的已附加的层数（取最大值）：
#
#   .state_ex_level(state_id)
#
#------------------------------------------------------------------
# 【状态的最大叠加层数】
#
# - 设置同上。
#
# - 注意：
#
#  1. 如果设置了最大层数，则同一时刻只会有一个该状态存在，
#     附加新的同ID状态时，不论层数是否增加，都将覆盖 battler_from、count、ps 变量。
#
#  2. 如果 没有设置层数 或设置了<层数 0>，则会作为新的一个独立状态附加，而不会叠加。
#
#     该特性允许了多个相同ID的状态独立计数，方便制作比如很多层的中毒。
#
#------------------------------------------------------------------
# 【状态的附加属性】
#
# - 设置同上。
#
#------------------------------------------------------------------
# 【死亡时也保留的状态】
#
# - 设置同上。
#
#------------------------------------------------------------------
# 【状态的伤害计算】
#
# - 现在可以给中毒状态设置更具体的数值了。
#
# - 在 数据库-状态 的备注中填写：
#
#    <timing 类型>...</timing>
#
#   其中 类型 替换为 1，代表行动结束时触发，
#             替换为 2，代表回合结束时触发。
#      特别新增，-1 代表状态被附加时触发，
#               -2 代表状态被解除时触发。
#
#   其中 ... 替换为伤害公式，
#         可以用 a 代表施加该状态的战斗者，b 代表当前结算该状态的战斗者，
#                s 代表开关组，v 代表变量组，l 代表当前状态的层数
#
#   如 <timing 1>a.atk * 0.5</timing> 代表
#         战斗者行动结束时，受到施加状态者的0.5倍atk的伤害。
#
#   如 <timing 2>b.mhp * 0.05</timing> 代表
#         战斗者行动结束时，受到自身最大生命值5%的伤害。
#
# - 注意：
#
#  1. 可以反复填写多次，以对不同类型进行设置。
#     对同一类型填写多次时，取最后一次的设置。
#
#  2. 状态的自动消除时机与该伤害计算为独立处理，
#     即哪怕是回合结束时才自动消除，只要有<timing 1>...</timing>的设置，
#       在行动结束时也会进行伤害计算。
#
#  3. 目前版本中，造成的伤害为真实伤害，不会暴击，不受其它减伤影响。
#
#  4. 当前仅兼容了YEA-Ace Battle Engine的伤害pop，
#     如果你有其他伤害pop需要兼容，请自己在 process_timing_formula 方法中编写。
#
#------------------------------------------------------------------
# 【高级：状态的自动减少时机的扩展】
#
# - 设置同上。
#
# - 可以编写 <timing 数字>...</timing> 来增加新时机的伤害处理。
#
# - 记得要自己在对应时机中调用战斗者的 update_state_turns_ex(数字) 方法哦！
#   不然状态永远也不会自动消除了。
#
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# ● 一些便捷用方法
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# - 获取状态的帮助文本：
#
#      STATE_EX.get_state_help(_state, _battler=nil) 
#
#   其中 _state 为 数据库-状态 ID 或者 $data_states[id] 或者 Data_StateEX 对象。
#   其中 _battler 为 战斗者，在战斗中将增加一些实时信息。
#
#   注意：
#
#    1. 状态名字中的 (..) 或 [..] 将识别为备注信息，自动删去。
#    2. 状态备注栏中可以编写 <help>...</help> 来增加帮助文本。
#
# - 获取指定战斗者当前全部状态的帮助文本：
#
#      STATE_EX.get_states_help_text(battler)
#
#==============================================================================

module STATE_EX 
  #--------------------------------------------------------------------------
  # ○【常量】基础属性与对应ID
  #--------------------------------------------------------------------------
  PARAMS_TO_ID = {
    :mhp => 0, :mmp => 1, :atk => 2, :def => 3,
    :mat => 4, :mdf => 5, :agi => 6, :luk => 7,
  }
  #--------------------------------------------------------------------------
  # ○ 读取数据库中设置的状态最大叠加层数
  #--------------------------------------------------------------------------
  def self.read_note_level(t)
    t =~ /<(层数|level) *(\d+)>/i
    return $2 ? $2.to_i : 0
  end
  #--------------------------------------------------------------------------
  # ○ 读取数据库中设置的状态附加属性值
  #--------------------------------------------------------------------------
  def self.read_note_params(t, param_rate, param_plus)
    t.scan(/<params>(.*?)<\/params>/mi).each do |params|
      h = EAGLE_COMMON.parse_tags(params[0])
      h.each do |sym, v|
        param_id = STATE_EX::PARAMS_TO_ID[sym]
        if v[-1] == '%'
          param_rate[param_id] += v[0..-1].to_i * 0.01
        else
          param_plus[param_id] += v.to_i
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # ○ 读取数据库中设置的状态在指定时机执行的公式
  #--------------------------------------------------------------------------
  def self.read_note_timings(t, timing_evals)
    t.scan(/<timing ?([-\d]+)>(.*?)<\/timing>/mi).each do |params|
      timing = params[0].to_i
      timing_evals[timing] = params[1] 
    end
  end
  #--------------------------------------------------------------------------
  # ○ 读取数据库中设置的状态自动解除时机
  #--------------------------------------------------------------------------
  def self.read_note_set_timing(t)
    t =~ /<set timing ?(\d+)>/i
    return $1 ? $1.to_i : 0
  end
  #--------------------------------------------------------------------------
  # ○ 读取数据库中设置的死亡后也保留状态的标志
  #--------------------------------------------------------------------------
  def self.read_note_reserve_when_die(t)
    return (t =~ /<死亡保留|reserve when die>/i) != nil
  end
  
  #--------------------------------------------------------------------------
  # ○ 获取指定战斗者全部状态的帮助文本
  #--------------------------------------------------------------------------
  def self.get_states_help_text(battler)
    t = ""
    battler.states.uniq.each do |state|
      t += get_state_help(state, battler)
      t += "\n"
    end
    battler.states_ex.each do |state|
      t += get_state_help(state, battler)
      t += "\n"
    end
    return t
  end
  #--------------------------------------------------------------------------
  # ○ 获取指定战斗者全部状态的帮助文本
  #--------------------------------------------------------------------------
  def self.get_state_help(_state, _battler=nil) 
    # RPG::State 或 STATE_EX::Data_StateEX 或 state_id
    rgss_state = nil
    if _state.is_a?(Integer)
      rgss_state = $data_states[_state]
      data_state = nil
    elsif _state.is_a?(RPG::State)
      rgss_state = _state
      data_state = nil
    elsif _state.is_a?(STATE_EX::Data_StateEX)
      rgss_state = _state.state
      data_state = _state
    else
      return ""
    end
    t = ""
    name = rgss_state.name
    # 特别的，状态名字中的 (..) 或 [..] 为备注信息，需要去除
    name.gsub!(/\(.*\)|\[.*\]/) { "" }
    t += "【\ei[#{rgss_state.icon_index}]#{name}】"
    
    # 如果传入了battler，则增加层数、解除时机
    if _battler
      # 叠加层数
      v = 0 
      if data_state # 如果是状态对象
        v = _battler.state_ex_level(rgss_state.id)
      else # 默认的状态
        v = _battler.state_level(rgss_state.id)
      end
      if v > 1
        t += "(\ec[16]#{v}\ec[0]层)"
      end
      # 自动解除时机
      v = 0  # 状态计数
      if data_state # 如果是状态对象
        v = data_state.count
        type = data_state.count_type
      else # 默认的状态
        v = _battler.state_turns[rgss_state.id] || 0
        type = rgss_state.auto_removal_timing
      end
      if v > 0
        case type
        when 1; t += "(\ec[16]#{v}\ec[0]次行动)"
        when 2; t += "(\ec[16]#{v}\ec[0]回合)"
        # 此为自定义的时机
        #  需要自己把 battler.update_state_turns_ex(3) 放到脚本中对应位置
        when 3; t += "(\ec[16]#{v}\ec[0]次投掷)"
        end
      end
      # 受伤解除
      if rgss_state.remove_by_damage
        t += "(受伤\ec[16]#{rgss_state.chance_by_damage}%\ec[0]解除)"
      end
    end
    # 备注中的帮助文本
    rgss_state.note.scan(/<help>(.*?)<\/help>/mi).each do |_params|
      _t = _params[0]
      _t.gsub!(/\\n/i) { "\n" }
      _t.gsub!(/\r/i) { "" }
      t += _t
    end
    return t
  end
  
#==============================================================================
# ■ 数据类
#==============================================================================
class Data_StateEX
  attr_reader  :id, :level, :count, :count_type
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(state_id, battler_from, battler, count, ps={})
    @flag_new = true  # 是否为新附加状态
    
    # 数据库中的状态ID原型
    @id = state_id
    # 附加该状态的来源战斗者
    @battler_from = battler_from
    # 状态附加的战斗者
    @battler = battler 
    # 状态在该计数为0时解除
    reset_count(count)
    # 状态计数减一的时机
    @count_type = state.auto_removal_timing # 0无，1行动结束，2回合结束
    # 当前叠加层数
    @level = 1
    # 其他扩展用
    @ps = ps

    # 八项基础属性的倍率增减
    @param_rate = [0] * 8  # 8维属性的增量
    # 八项基础属性的数值增减
    @param_plus = [0] * 8  # 8维属性的增量
    STATE_EX.read_note_params(state.note, @param_rate, @param_plus)
  end
  #--------------------------------------------------------------------------
  # ● 获取该状态附加的属性（最后计算的增减值）
  #--------------------------------------------------------------------------
  def param_plus(param_id)
    @param_plus[param_id] * @level
  end
  #--------------------------------------------------------------------------
  # ● 获取该状态附加的属性倍率（与buff进行增量叠加）
  #--------------------------------------------------------------------------
  def param_rate(param_id)
    @param_rate[param_id] * @level
  end
  #--------------------------------------------------------------------------
  # ● 获取对应的数据库状态及其数据
  #--------------------------------------------------------------------------
  def state
    $data_states[@id]
  end
  def features
    state.features
  end
  def note
    state.note
  end
  #--------------------------------------------------------------------------
  # ● 用于计算特性
  #--------------------------------------------------------------------------
  def feature_objects
    [state] * @level
  end
  #--------------------------------------------------------------------------
  # ● 叠加一层该状态
  #  如果已经最高层数了，则只更新计数
  #--------------------------------------------------------------------------
  def add_up(battler_from, count, ps)
    @flag_new = true
    f = false
    if add_up? 
      @level += 1
      f = true
    end
    @battler_from = battler_from
    reset_count(count)
    @ps = ps
    return f  # 返回是否成功叠加了一层
  end
  #--------------------------------------------------------------------------
  # ● 可以再叠加？
  #--------------------------------------------------------------------------
  def add_up?
    state.level > @level
  end
  #--------------------------------------------------------------------------
  # ● 减少v层该状态
  #  如果v为nil，则移除全部层数
  #  如果已经0层了，则移除
  #  返回实际减少的层数
  #--------------------------------------------------------------------------
  def reduce(v=nil)
    c = 0
    v = @level if v.nil?
    v.times do
      @level -= 1
      c += 1
      break @count = 0 if @level <= 0
    end
    return c
  end
  #--------------------------------------------------------------------------
  # ● 可以移除该状态？
  #--------------------------------------------------------------------------
  def remove?
    @count <= 0
  end
  #--------------------------------------------------------------------------
  # ● 重置计数
  #--------------------------------------------------------------------------
  def reset_count(v)
    @count = v
    if @count == nil
      variance = 1 + [state.max_turns - state.min_turns, 0].max
      @count = state.min_turns + rand(variance)
    end
  end
  #--------------------------------------------------------------------------
  # ● 依据状态更新时机来更新计数
  #  如果传入的 timing 为 nil，则任意时刻的状态都要减少
  #--------------------------------------------------------------------------
  def update_count(timing, added_states=[])
    # 执行该时机的伤害公式
    process_timing_formula(timing)
    # 0 表示一直存在的状态，没有计数，不用减少
    return if @count_type == 0
    # 查看是否要在该时机让计数减少，若 timing 为 nil，则必定处理减少
    return if timing != nil and timing != @count_type
    f = @flag_new
    @flag_new = false
    # 如果为新附加状态，且在例外状 态数组中，比如本次行动才被附加的状态，则不减一
    return if f && added_states && added_states.include?(@id)
    @count -= 1
  end
  #--------------------------------------------------------------------------
  # ● 处理指定时机的结算公式
  #--------------------------------------------------------------------------
  def process_timing_formula(timing)
    formula = state.timing_evals[timing]
    return if formula.nil?
    a = @battler_from 
    b = @battler
    v = $game_variables
    s = $game_switches
    l = @level
    value = Kernel.eval(formula).floor rescue 0
    @battler.result.hp_damage = value
    @battler.hp -= value
    if $imported["YEA-BattleEngine"]
      @battler.make_damage_popups(a)
    end
  end
end

end # end of module

#==============================================================================
# ■ 数据库-状态类
#==============================================================================
class RPG::State
  attr_reader  :level, :timing_evals, :reserve_when_die
  #--------------------------------------------------------------------------
  # ● 进入游戏时读取备注栏
  #--------------------------------------------------------------------------
  def reset_state_ex
    # 读取可叠加的层数
    @level = STATE_EX.read_note_level(note)
    
    # 八项基础属性的倍率增减
    @param_rate = [0] * 8  # 8维属性的增量
    # 八项基础属性的数值增减
    @param_plus = [0] * 8  # 8维属性的增量
    STATE_EX.read_note_params(note, @param_rate, @param_plus)
    
    # 战斗时机的数字 => 执行的脚本
    @timing_evals = {}
    STATE_EX.read_note_timings(note, @timing_evals)
    
    # 状态计数减一的时机
    @raw_auto_removal_timing = @auto_removal_timing # 0无，1行动结束，2回合结束
    type = STATE_EX.read_note_set_timing(note)
    @auto_removal_timing = type == 0 ? @raw_auto_removal_timing : type
    
    # 死亡也保留的状态
    @reserve_when_die = STATE_EX.read_note_reserve_when_die(note)
  end
  #--------------------------------------------------------------------------
  # ● 获取该状态附加的属性（最后计算的增减值）
  #--------------------------------------------------------------------------
  def param_plus(param_id)
    @param_plus[param_id]
  end
  #--------------------------------------------------------------------------
  # ● 获取该状态附加的属性倍率（与buff进行增量叠加）
  #--------------------------------------------------------------------------
  def param_rate(param_id)
    @param_rate[param_id]
  end
end
#==============================================================================
# ■ DataManager
#==============================================================================
class << DataManager
  #--------------------------------------------------------------------------
  # ● 读取数据库备注，进行额外设置
  #--------------------------------------------------------------------------
  alias eagle_state_ex_load_database load_database
  def load_database
    eagle_state_ex_load_database
    $data_states.each { |s| s.reset_state_ex if s }
  end
end

#==============================================================================
# ■ Game_BattlerBase
#==============================================================================
class Game_BattlerBase
  attr_reader  :state_turns, :states_ex
  #--------------------------------------------------------------------------
  # ● 获取普通能力
  #--------------------------------------------------------------------------
  def param(param_id)
    # 数据库-角色/敌人 中设置的基础数值
    value = param_base(param_id) 
    # 数据库-武器/护甲、游戏过程中事件-增减属性值 中额外的增加值
    value += param_plus(param_id)
    # 数据库中设置的 角色/职业/武器/护甲/敌人/状态 的普通能力倍率变化
    #  连乘后的倍率
    value *= param_rate(param_id) 
    # 战斗中的buff影响的倍率
    value *= param_buff_rate(param_id)
    # （新增）因为 状态扩展 而额外增减的属性值
    value += states.compact.inject(0) { |r, item|
      r += item.param_plus(param_id) }
    value += @states_ex.compact.inject(0) { |r, item|
      r += item.param_plus(param_id) }
    # 确保在范围内
    [[value, param_max(param_id)].min, param_min(param_id)].max.to_i
  end
  #--------------------------------------------------------------------------
  # ● 获取普通能力的强化／弱化变化率
  #--------------------------------------------------------------------------
  alias eagle_state_ex_param_buff_rate param_buff_rate
  def param_buff_rate(param_id)
    v = eagle_state_ex_param_buff_rate(param_id)
    # （新增）因为 状态扩展 而额外增减的属性倍率值
    v += states.compact.inject(0) { |r, item|
      r += item.param_rate(param_id) }
    v += @states_ex.compact.inject(0) { |r, item|
      r += item.param_rate(param_id) }
    v 
  end

  #--------------------------------------------------------------------------
  # ● 获取所有拥有特性的实例的数组
  #--------------------------------------------------------------------------
  alias eagle_states_ex_feature_objects feature_objects
  def feature_objects
    eagle_states_ex_feature_objects + @states_ex.collect { |s| s.feature_objects }.flatten
  end
  #--------------------------------------------------------------------------
  # ● 清除状态信息
  #--------------------------------------------------------------------------
  alias eagle_states_ex_clear_states clear_states
  def clear_states
    eagle_states_ex_clear_states
    @states_ex = [] # Data_StateEX
  end
  #--------------------------------------------------------------------------
  # ● 检査是否含有某状态
  #--------------------------------------------------------------------------
  alias eagle_state_ex? state?
  def state?(state_id)
    eagle_state_ex?(state_id) || state_ex?(state_id)
  end
  def state_ex?(state_id, v=1)
    @states_ex = [] if @states_ex.nil?
    @states_ex.count {|s| s.id == state_id } >= v
  end
  #--------------------------------------------------------------------------
  # ● 获取指定id的状态，用于叠加层数
  #--------------------------------------------------------------------------
  def get_state_ex(state_id)
    @states_ex.each {|s| return s if s.id == state_id }
  end
  #--------------------------------------------------------------------------
  # ● 获取指定id的状态的已叠加层数
  #--------------------------------------------------------------------------
  def state_level(state_id)
    @states.count(state_id)
  end
  def state_ex_level(state_id)
    v = 0
    @states_ex.each {|s| v = s.level if s.id == state_id && s.level > v }
    return v
  end
  #--------------------------------------------------------------------------
  # ● 获取当前状态的图标编号数组
  #--------------------------------------------------------------------------
  def state_icons
    # 先合到一起排序，再导出图标
    s1 = states.uniq
    s2 = @states_ex.collect { |data| data.state }
    ss = (s1+s2).sort_by {|s| [-s.priority, s.id] }
    icons = ss.collect {|s| s.icon_index }
    icons.delete(0)
    icons
  end
  #--------------------------------------------------------------------------
  # ● 获取限制状态
  #    从当前附加的状态中获取限制最大的状态 
  #--------------------------------------------------------------------------
  alias eagle_state_ex_restriction restriction
  def restriction
    v = eagle_state_ex_restriction
    v2 = @states_ex.collect {|s| s.state.restriction }.push(0).max
    [v, v2].max
  end
end

#==============================================================================
# ■ Game_Battler
#==============================================================================
class Game_Battler < Game_BattlerBase
  #--------------------------------------------------------------------------
  # ● 附加状态
  #--------------------------------------------------------------------------
  def add_state(state_id)
    if state_addable?(state_id)
      # 如果可以叠层，或者未附加
      if (eagle_state_ex?(state_id) && $data_states[state_id].level > 1) || 
        !eagle_state_ex?(state_id)
        add_new_state(state_id)
      end
      reset_state_counts(state_id)
      @result.added_states.push(state_id).uniq!
    end
  end
  #--------------------------------------------------------------------------
  # ● 减少状态层数
  #--------------------------------------------------------------------------
  def reduce_state_level(state_id, v=nil)
    if state?(state_id)
      revive if state_id == death_state_id
      if eagle_state_ex?(state_id) && $data_states[state_id].level > 1
        # 如果可以叠层，则减去对应层数
        v = state_level(state_id) if v.nil?
        v.times { @states.delete(state_id) }
      else # 否则，全部清除
        erase_state(state_id)
      end
      refresh
      @result.removed_states.push(state_id).uniq!
      if $imported["YEA-BattleEngine"]
        make_state_popup(state_id, :rem_state)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 附加状态（扩展）
  #--------------------------------------------------------------------------
  def add_state_ex(state_id, battler_from=nil, count=nil, ps={})
    if state_addable?(state_id)
      die if state_id == death_state_id
      if state_ex?(state_id) && $data_states[state_id].level >= 1
        # 可叠层的状态，同时仅会存在一个，找到它，进行层数增加
        d = get_state_ex(state_id)
        d.add_up(battler_from, count, ps)
        d.process_timing_formula(-1)
      else # 不可叠层的，则直接增加一个新的状态对象
        d = STATE_EX::Data_StateEX.new(state_id, battler_from, self, count, ps)
        @states_ex.push(d)
        d.process_timing_formula(-1)
      end
      on_restrict if restriction > 0
      sort_states_ex
      refresh
      @result.added_states.push(state_id).uniq!
      if $imported["YEA-BattleEngine"]
        make_state_popup(state_id, :add_state)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 行动受到限制时的处理
  #--------------------------------------------------------------------------
  alias eagle_state_ex_on_restrict on_restrict
  def on_restrict
    eagle_state_ex_on_restrict
    @states_ex.each do |s|
      remove_state_ex(s.state.id) if s.state.remove_by_restriction
    end
  end
  #--------------------------------------------------------------------------
  # ● 状态排序（扩展）
  #    依照优先度排列数组 @states，高优先度显示的状态排在前面。
  #--------------------------------------------------------------------------
  def sort_states_ex
    @states_ex = @states_ex.sort_by {|d| [-$data_states[d.id].priority, d.id] }
  end
  #--------------------------------------------------------------------------
  # ● 解除状态（扩展）
  #--------------------------------------------------------------------------
  def remove_state_ex(state_id, v=nil)
    if state_ex?(state_id)
      revive if state_id == death_state_id
      if state_ex?(state_id) && $data_states[state_id].level >= 1
        # 可叠层的状态，同时仅会存在一个，找到它，进行层数减少
        d = get_state_ex(state_id)
        c = d.reduce(v) # 返回实际减少的层数
        c.times { d.process_timing_formula(-2) }
        # 如果计数为 0 则删去
        @states_ex.delete(d) if d.remove?
      else # 不可叠层的状态，则按个数删
        c = @states_ex.count { |s| s.id == state_id } if v.nil?
        c.times do 
          _i = @states_ex.index { |s| s.id == state_id }
          break if _i == nil
          @states_ex[_i].process_timing_formula(-2)
          @states_ex.delete_at(_i)
        end
      end
      refresh
      @result.removed_states.push(state_id).uniq!
      if $imported["YEA-BattleEngine"]
        make_state_popup(state_id, :rem_state)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 战斗行动结束时的处理
  #--------------------------------------------------------------------------
  alias eagle_state_ex_on_action_end on_action_end
  def on_action_end
    # 新增：对于按行动次数计数的状态，此处要减1
    update_state_turns_ex(1)
    @last_result_added_states = @result.added_states
    eagle_state_ex_on_action_end  # 此处将 @result 中的 added_states 清空了
  end
  #--------------------------------------------------------------------------
  # ● 将存储的附加状态信息重新应用
  #--------------------------------------------------------------------------
  def eagle_restore_added_states
    @result.added_states = @last_result_added_states
  end
  #--------------------------------------------------------------------------
  # ● 回合结束处理
  #--------------------------------------------------------------------------
  alias eagle_state_ex_on_turn_end on_turn_end
  def on_turn_end
    # 新增：对于按回合计数的状态，此处要减1
    update_state_turns_ex(2)
    eagle_state_ex_on_turn_end
  end
  #--------------------------------------------------------------------------
  # ● 更新状态的回合数
  #--------------------------------------------------------------------------
  def update_state_turns
    # 不再需要该方法了，清空
  end
  #--------------------------------------------------------------------------
  # ● 更新状态的计数（扩展）
  #  1 行动结束时
  #  2 回合结束时
  #--------------------------------------------------------------------------
  def update_state_turns_ex(timing = 1) # 针对rgss的状态
    states.uniq.each do |state|
      # 如果是本次行动增加的状态，则不减1
      next if state.nil?
      next if @result.added_states && @result.added_states.include?(state.id)
      if state.auto_removal_timing == timing
        @state_turns[state.id] -= 1
        remove_state(state.id) if @state_turns[state.id] == 0
      end
    end
    update_state_ex_counts(timing)
  end
  def update_state_ex_counts(timing = 1) # 针对 Data_StateEX的状态对象
    @states_ex.each { |data| data.update_count(timing, @result.added_states) }
    # 删去计数为 0 的状态
    @states_ex.delete_if { |data| 
      f = data.remove?
      if f
        data.process_timing_formula(-2)
        if $imported["YEA-BattleEngine"]
          make_state_popup(data.id, :rem_state)
        end
      end
      f
    }
  end
  #--------------------------------------------------------------------------
  # ● 死亡
  #--------------------------------------------------------------------------
  alias eagle_state_ex_die die
  def die
    # 对于RGSS状态
    s1 = @states.select { |sid| $data_states[sid].reserve_when_die == true } 
    s1_turns = @state_turns.select { |sid, v| s1.include?(sid) }
    s1_steps = @state_steps.select { |sid, v| s1.include?(sid) }
    # 对于状态对象
    s2 = @states_ex.select { |data| data.state.reserve_when_die == true }
    eagle_state_ex_die
    @states = s1
    @state_turns = s1_turns
    @state_steps = s1_steps
    @states_ex = s2
  end
  #--------------------------------------------------------------------------
  # ● 战斗结束时解除状态
  #--------------------------------------------------------------------------
  alias eagle_state_ex_remove_battle_states remove_battle_states
  def remove_battle_states
    eagle_state_ex_remove_battle_states
    @states_ex.each do |data|
      remove_state_ex(data.state.id) if data.state.remove_at_battle_end
    end
  end
  #--------------------------------------------------------------------------
  # ● 受到伤害时解除状态
  #--------------------------------------------------------------------------
  alias eagle_state_ex_remove_states_by_damage remove_states_by_damage
  def remove_states_by_damage
    eagle_state_ex_remove_states_by_damage
    @states_ex.each do |data|
      if data.state.remove_by_damage && rand(100) < data.state.chance_by_damage
        remove_state_ex(data.state.id)
      end
    end
  end
end
