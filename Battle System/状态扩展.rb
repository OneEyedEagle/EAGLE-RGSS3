#==============================================================================
# ■ 状态扩展 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【组件-通用方法汇总 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-StateEX"] = "1.3.2"
#==============================================================================
# - 2026.1.31.0 方便扩展
#==============================================================================
# - 本插件扩展了默认战斗中的状态，如需兼容其他战斗系统，请自行按注释修改
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#
# - 由于在默认的 Game_BattlerBase 中，仅存储了状态ID，状态回合计数都是另外存储，
#   这导致无法利用状态来计算伤害，只能依靠回合结束时的自动回复来做中毒。
#
# - 本插件新增了全新设计的状态对象，与默认的状态分别处理，
#   不仅兼容默认的全部功能，还可以各自独立计数，并编写伤害公式进行伤害处理。
#
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# ● 什么是 状态对象（Data_StateEX）
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#
#  1. 状态对象 是能够处理更多样的 自动消除时机 与 中毒伤害计算 的状态。
#
#  2. 为了最大限度保证兼容性，状态对象 与 默认状态 互相独立存在，互不冲突。
#     你可以通过设置下面的常量自由决定是否要用 状态对象 覆盖 默认状态 。
#
#------------------------------------------------
# 【设置：是否禁用默认状态】
#
FLAG_NO_RGSS3_STATE = true 
#
#  若设置为 true ，则不再使用 默认状态，仅使用 状态对象。
#
#    1) 默认系统中的全部 附加状态 都将改为附加 状态对象。
#
#    2) 对于 事件-附加状态，其 来源战斗者 为空，请不要在伤害计算中使用 a 。
#
#  若设置为 false ，则 默认状态 和 状态对象 互相独立存在。
#
#    1) 默认系统中的全部 附加状态 仍然附加 默认状态。
#
#    2) 请自行调用 .add_state_ex 方法来附加 状态对象。
#
#       例如，在技能公式中填写 b.add_state_ex(2, a) 来给目标b附加一个2号状态，
#       同时在2号状态的数据库备注栏里写 <timing 1>a.atk</timing>，
#       就会在 b 行动结束时受到一次 a的当前攻击力 的真实伤害。
#
#    3) 对于 事件-附加状态，其附加的依然是默认状态，无法进行本插件的伤害处理。
#
#------------------------------------------------
# 【帮助：战斗者Battler的可使用方法】
#
#
#  1. 是否附加了一个以上（或一层以上）的指定id的 默认状态 或 状态对象：
#
#     .state?(state_id) 
#
#  2. 附加 1 个状态对象：
#
#     .add_state_ex(state_id, battler_from=nil, count=nil, ps={})
#
#       其中 state_id 为数据库-状态的ID，
#          本质还是基于数据库中的状态设置，但增加了一些在备注栏中编写的设置。
#
#       其中 battler_from 为该状态的来源战斗者，在伤害公式中可传入技能使用者 a，
#          在设计基于状态来源的攻击等属性进行中毒伤害计算时会有用处。
#
#       其中 count 为计数，每次行动结束/回合结束时 -1 ，当为0时该状态解除，
#           （注意：当状态最大层数为0时，将作为新的状态附加，并独立计数。）
#          如果传入 nil，则取 数据库-状态 中的预设回合数。
#
#       其中 ps 为后续扩展用Hash。
#
#    （与默认方法对比）附加 1 个默认状态：
#
#     .add_state(state_id) 
#
#       其中 state_id 为数据库-状态的ID。
#
#  3. 解除v 个或 v 层指定ID的状态对象：
#
#     .remove_state_ex(state_id, v=nil)
#
#       其中 state_id 为数据库-状态的ID。
#
#       其中 v 为解除的数量，如果传入 nil，则解除全部该ID的状态对象；
#        （对于可叠加的状态）为解除的层数，nil时将解除该ID的状态对象的全部层数。
#

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# ● 新增功能一览
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#
#  如果标题后备注【RGSS状态和状态对象】，代表 默认状态 和 状态对象 均生效。
#
#  如果标题后备注【仅状态对象】，代表仅对 状态对象 生效。
#
#---------------------------------------------------------------------
# △ 死亡也保留的状态                            【RGSS状态和状态对象】
#---------------------------------------------------------------------
#
# - 现在可以设置 状态 在角色死亡时是否保留了。
#
# - 在 数据库-状态 的备注中填写：
#
#      <死亡保留> 或者 <reserve when die>
#
#   则在角色死亡时，该状态将不会被清除。
#
#---------------------------------------------------------------------
# △ 状态的最大叠加层数                          【RGSS状态和状态对象】
#---------------------------------------------------------------------
#
# - 现在 状态 可以反复附加，直至达到预设的上限。
#
# - 在 数据库-状态 的备注中填写：
# 
#      <层数 数字> 或 <level 数字>
#
#   其中 数字 为 正整数，来设置该状态最多可被添加的层数。
#
# - 注意：
#
#  1. 状态在成功叠加后，将刷新其回合计数。
# 
#  2. 对于默认的状态（利用 add_state 添加的状态）：
#
#    1）同ID的状态共用一个回合计数。
#
#    2）使用 battler.remove_state(state_id) 将消除全部层数。
#
#    3）使用 battler.reduce_state_level(state_id, v) 能指定消除层数。
#
#  3. 对于状态对象（利用 add_state_ex 添加的状态）：
#
#    1）同一时刻只会有一个该状态存在。
#
#    2) 再次附加时，不论层数是否成功增加，
#       都将覆盖当前状态对象的 battler_from、count、ps 。
#
#  4. 数据库-状态的特殊能力、添加能力等都会按层数进行倍增、倍乘。
#
#------------------------------------------------
# - 战斗者Battler 新增方法：
#
#    .state_level(state_id)               →  获取 默认状态 的已附加层数
#    .reduce_state_level(state_id, v)     →  指定 默认状态 减少 v 层
#                              如果v为 nil 或不传入或大于已有层数，则消除全部层数
#
#    .state_ex_level(state_id)            →  获取 状态对象 的已附加层数
#
#---------------------------------------------------------------------
# △ 状态的最多同时存在个数                              【仅状态对象】
#---------------------------------------------------------------------
# 
# - 现在 状态 可以反复附加，直至达到同时存在的上限。
#
# - 在 数据库-状态 的备注中填写：
#
#      <层数 0> 或 <level 0> 或 不填写
#
#   同时也在备注中填写：
#
#      <个数 数字> 或 <max 数字>
#
#   来设置该状态的最多同时存在个数。
#
# - 注意：
#
#  1. 状态在附加前会判定当前数量，如果已经达到数量上限，则附加失败。
#
#  2. 如果设置了 <层数 数字> ，且数字为正整数，则该功能失效。
#     状态每次重复附加会变为给已有状态层数+1，而不会附加新的独立状态。
#
#  3. 如果未设置 <个数 数字>，则同时存在的数量无上限。
#
#------------------------------------------------
# - 战斗者Battler 新增方法：
#
#    .state_ex_sum(state_id)         →  获取已附加的状态对象的个数
#    .state_ex?(state_id, v=1)       →  是否已附加至少v个状态对象
#
#---------------------------------------------------------------------
# △ 状态的附加属性                              【RGSS状态和状态对象】
#---------------------------------------------------------------------
#
# - 现在 状态 可以像装备一样，给角色附加额外的属性值了。
#
# - 在 数据库-状态 的备注中填写：
#
#     <params>...</params>
#
#   其中 ... 替换为 属性名=数字 的反复组合，各个属性只能写一次
#
#     1) 属性名 为 mhp mmp atk def mat mdf agi luk ，依次为八维属性。
#
#     2) 数字   为 正整数 或 负整数 或 带 % 的百分数。
#
#   如 <params>mhp=50</params> 代表 最大生命值+50点
#   如 <params>mhp=5%</params> 代表 最大生命值+5%
#   如 <params>mat=5 luk=-3</params> 代表 魔法攻击+5点、幸运-3点
#
# - 注意：
#
#  1. 状态如果存在多层，则每一层都会累加一次属性值。
#
#  2. 状态附加的固定属性值，将在全部附加属性计算完成后增加，
#     即不受到数据库中普通能力-属性倍率、战斗中属性buff的影响。
#
#  3. 状态附加的百分比属性值，将与 战斗中属性buff 进行累加，作为最终的倍率。
#     即属性的倍率 = 1 + 该属性战斗中buff层数 x 0.25 + 状态的属性倍率和。
#
#     如 被附加了带有 <params>mhp=5%</params> 的状态A 和
#        带有 <params>mhp=15</params>的状态B，且 MHP 的buff层数为 0，
#        则该角色的最终MHP = 原始MHP * (1 + 0 x 0.25 + 0.05) + 15
#
#---------------------------------------------------------------------
# △ 状态的伤害计算                                      【仅状态对象】
#---------------------------------------------------------------------
#
# - 现在可以给中毒之类的状态设置更灵活的伤害数值了。
#
# - 在 数据库-状态 的备注中填写：
#
#    <timing 类型>...</timing>
#
#   其中 类型 为该伤害计算的触发时机的数字，
#         1 → 行动结束时     2 → 回合结束时
#         3 → 造成伤害时     4 → 受到伤害时
#        -1 → 状态被附加时  -2 → 状态被解除时
#
#   其中 ... 替换为伤害公式，
#         可以用 a 代表施加该状态的战斗者，b 代表当前结算该状态的战斗者，
#                s 代表开关组，v 代表变量组，
#               id 代表当前状态的id，l 代表当前状态的层数
#
#   如 <timing 1>a.atk * 0.5</timing> 代表
#         战斗者行动结束时，受到施加状态者的0.5倍atk的伤害。
#
#   如 <timing 2>b.mhp * 0.05</timing> 代表
#         战斗者回合结束时，受到自身最大生命值5%的伤害。
#
# - 注意：
#
#  1. 如果状态的最大层数为0，即不可叠加，则每个状态都会触发一次伤害计算。
#
#     如果状态的最大层数为正数，则只会触发一次伤害计算，
#       请自己在伤害公式中利用 l 来处理状态层数对伤害的影响。
#
#  2. 可以反复填写多次，以对不同时机进行设置。
#     对同一时机填写多次时，取最后一次的设置。
#
#  3. 状态的自动减少时机与该伤害计算互相独立处理，
#     如状态设置为回合结束时消除，但备注栏设置 <timing 1>...</timing> ，
#       那么在角色行动结束时同样会进行伤害计算。
#
#  4. 目前版本中，造成的伤害为真实伤害，不会暴击，不受其它减伤影响。
#
#  5. 当前仅兼容了YEA-Ace Battle Engine的伤害数字pop显示，
#     如果你有其他显示伤害方式需要兼容，请在 process_timing_formula 方法中添加。
#
#------------------------------------------------
# - 战斗者Battler 新增方法：
#
#    .trigger_state_ex(state_id, timing)   → 触发指定状态对象指定类型的伤害计算
#            state_id 为 nil 时，将触发全部状态对象
#                     为 数字 时，将触发ID为该数字的状态对象
#                     为 数组 时，将触发ID在该数组内的状态对象
#            timing   为 nil 时，将触发状态的全部类型的伤害计算
#                     为 数字 时，将触发类型为该数字的伤害计算
#                     为 数组 时，将触发类型在该数组内的伤害计算
#
#---------------------------------------------------------------------
# △ 状态的自动减少时机                          【RGSS状态和状态对象】
#---------------------------------------------------------------------
#
# - 在默认系统中，状态的自动减少时机仅有 行动结束时 和 回合结束时，
#   受伤解除 和 战斗解除 都是无视计数直接消除状态，不属于自动减少。
#
# - 现在可以给状态设置全新的自动减少时机了。
#
# - 在 数据库-状态 的备注中填写：
#
#      <set timing 时机数字>
#
#  “时机数字”替换为下列数字，以设置该状态的计数自动减1的时机：
#
#       1 → 角色自身行动结束时   2 → 战斗回合结束时
#       3 → 角色造成伤害时       4 → 角色受到伤害时
#       （3和4都随 on_damage 方法计数，如果使用【技能多段伤害】，则会多次计数）
#
# - 注意：
#
#  1. 数据库-状态中设置的 自动解除时机 将失效！
#
#
# - 高级-编写你的“时机数字”：
#
#  1. “时机数字”不仅仅局限于上述 4 个，你也可以编写属于自己的时机。
#
#    假如你想编写 时机数字5 ，代表 击杀敌人时 ，则需要以下几步：
#
#    1) 数据库-状态的备注栏中填写 <set timing 5>
#
#    2) 由于 Game_Battler 的 execute_damage(user) 方法应用了受到的伤害，
#       可以在方法中的最后增加判定自身 hp 是否为 0，
#       如果为0则调用 user.update_state_turns_ex(5) ，
#       这样就会将攻击方的全部时机为5的状态 计数-1 ，且当计数为0时，将自动解除。
#
#    3) 同样可以编写 <timing 5>...</timing> 来处理击杀敌人时的伤害公式。
#
#  2. 对于当前行动/回合中才附加的新状态，在行动结束/回合结束时不处理 计数-1 。
#
#     但如果你添加的时机在 battler.on_action_end 方法后，
#       由于这个方法中清空了附加新状态的数组，
#       导致会多执行一次 计数-1 ，即状态持续数额外少了 1。
#
#     为了避免该问题，你可以按以下顺序操作：
#
#    1) 调用 battler.eagle_restore_added_states，
#        将 on_action_end 执行前的“附加新状态信息”再读取出来。
#
#    2) 调用 update_state_turns_ex(时机数字) ，处理状态的伤害计算。
#
#    3) 调用 battler.result.added_states.clear 重置“附加新状态信息”。
#
#---------------------------------------------------------------------
# △ 状态的自动减少与最大叠加层数的交互                  【仅状态对象】
#---------------------------------------------------------------------
#
# - 在默认系统中，状态的回合计数减少到 0 时，将消除全部同ID的状态。
#   本插件中的默认状态同理，不管目前多少层，都会在回合计数归零时一起消除。
#
# - 现在 状态对象 可以用 减少层数 来代替 全部消除 了。
#
# - 在 数据库-状态 的备注中填写：
#
#     <层数抵扣消除>  或者  <reduce one level>
#
#   那么对于设置了 <层数 数字> 且数字为正数的状态，
#     如果目前层数大于1，将在计数为0时，仅减少1层，而不消除全部层数，且计数重置。
#
#---------------------------------------------------------------------
# △ 状态的帮助文本                              【RGSS状态和状态对象】
#---------------------------------------------------------------------
#
# - 利用全局方法获取指定状态的帮助文本：
#
#      STATE_EX.get_state_help(_state, _battler=nil) 
#
#   其中 _state 为 数据库-状态 ID 或者 $data_states[id] 或者 Data_StateEX 对象。
#   其中 _battler 为 战斗者，在战斗中将增加一些实时信息。
#
# - 注意：
#
#    1. 状态名字中的 (..) 或 [..] 将识别为备注信息，自动删去。
#    2. 状态备注栏中可以编写 <help>...</help> 来增加帮助文本。
#
# - 获取指定战斗者全部状态的帮助文本：
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
  # ○ 读取数据库中设置的状态最多同时存在个数
  #--------------------------------------------------------------------------
  def self.read_note_max(t)
    t =~ /<(个数|max) *(\d+)>/i
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
  # ○ 读取数据库中设置的层数抵扣消除的标志
  #--------------------------------------------------------------------------
  def self.read_note_level_reduce(t)
    return (t =~ /<层数抵扣消除|reduce one level>/i) != nil 
  end
  
  #--------------------------------------------------------------------------
  # ○ 根据传入的值，返回RGSS状态对象和StateEX状态对象
  #  传入 RPG::State 或 STATE_EX::Data_StateEX 或 状态的数据库id
  #--------------------------------------------------------------------------
  def self.get_rgss_state_data_state(_state)
    rgss_state = nil
    data_state = nil
    if _state.is_a?(Integer)
      rgss_state = $data_states[_state]
      data_state = nil
    elsif _state.is_a?(RPG::State)
      rgss_state = _state
      data_state = nil
    elsif _state.is_a?(STATE_EX::Data_StateEX)
      rgss_state = _state.state
      data_state = _state
    end
    return rgss_state, data_state
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
    rgss_state, data_state = get_rgss_state_data_state(_state)
    return "" if rgss_state == nil
    t = ""
    name = rgss_state.name
    # 特别的，状态名字中的 (..) 或 [..] 为备注信息，需要去除
    name.gsub!(/\(.*\)|\[.*\]/) { "" }
    t += get_state_help_text_name(rgss_state.icon_index, name)
    # 如果传入了battler，则增加层数、解除时机
    if _battler
      # 叠加层数
      v = 0 
      if data_state # 如果是状态对象
        v = _battler.state_ex_level(rgss_state.id)
      else # 默认的状态
        v = _battler.state_level(rgss_state.id)
      end
      t += get_state_help_text_level(v) 
      # 自动解除时机
      v2 = 0  # 状态计数
      if data_state # 如果是状态对象
        v2 = data_state.count
        type = data_state.count_type
      else # 默认的状态
        v2 = _battler.state_turns[rgss_state.id] || 0
        type = rgss_state.auto_removal_timing
      end
      t += get_state_help_text_count(type, v2)
      # 层数大于1时，抵扣解除
      t += get_state_help_text_level_for_erase(v, rgss_state)
      # 受伤解除
      t += get_state_help_text_on_damage(rgss_state) 
    end
    # 备注中的帮助文本
    t += get_state_help_text_note(rgss_state.note)
    return t
  end
  #--------------------------------------------------------------------------
  # ○ 获取状态各个属性的帮助文本
  #--------------------------------------------------------------------------
  def self.get_state_help_text_name(icon_index, name) # 图标和名称
    "【\ei[#{icon_index}]#{name}】"
  end
  def self.get_state_help_text_level(v) # 叠加层数
    if v > 1
      "(\ec[16]#{v}\ec[0]层)"
    else
      ""
    end
  end
  def self.get_state_help_text_count(type, v) # 自动减少的时机
    if v > 0
      case type
      when 1; return "(\ec[16]#{v}\ec[0]次行动解除)"
      when 2; return "(\ec[16]#{v}\ec[0]回合解除)"
      when 3; return "(造成\ec[16]#{v}\ec[0]次伤害解除)"
      when 4; return "(受到\ec[16]#{v}\ec[0]次伤害解除)"
      # 此为自定义的时机
      #  需要自己把 battler.update_state_turns_ex(10) 放到脚本中对应位置
      when 10; return "(\ec[16]#{v}\ec[0]次投掷解除)"
      end
    end
    return "(不自动解除)"
  end
  def self.get_state_help_text_level_for_erase(v, rgss_state) # 自动减少时，用层数抵扣
    if v > 1
      if rgss_state.reduce_one_level
        return "（单次解除\ec[16]1\ec[0]层）"
      else
        return "（单次全部解除）"
      end
    end
    return ""
  end
  def self.get_state_help_text_on_damage(rgss_state) # 受伤概率解除
    if rgss_state.remove_by_damage
      v = rgss_state.chance_by_damage
      return "(受伤时\ec[16]#{v}%\ec[0]解除)"
    end
    return ""
  end
  def self.get_state_help_text_note(note)  # 备注栏新增的帮助文本
    t = ""
    note.scan(/<help>(.*?)<\/help>/mi).each do |_params|
      _t = _params[0]
      _t.gsub!(/\\n/i) { "\n" }
      _t.gsub!(/\r/i) { "" }
      t += _t
    end
    return t
  end
  
  #--------------------------------------------------------------------------
  # ● 【扩展用】方便撰写popup
  #--------------------------------------------------------------------------
  def self.state_ex_when_add(state_ex)  # 状态附加时执行的内容
  end
  def self.state_ex_when_remove(state_ex) # 状态解除时执行的内容
  end
  def self.state_ex_when_trigger(state_ex) # 状态被触发时执行的内容 
    # 此时 state_ex.battler.result.hp_damage 为已经造成的伤害值或治疗值
    # 兼容：YEA战斗系统的伤害pop
    state_ex.battler.make_damage_popups(state_ex.battler_from) if $imported["YEA-BattleEngine"]
  end
  
#==============================================================================
# ■ 数据类
#==============================================================================
class Data_StateEX
  attr_reader  :id, :level, :count, :count_type, :battler_from, :battler
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
    v = @level if v == nil
    v.times do
      @level -= 1
      c += 1
      break @count = 0 if @level <= 0
    end
    return c
  end
  #--------------------------------------------------------------------------
  # ● 自动减少时，可以用层数抵消移除？
  #--------------------------------------------------------------------------
  def reduce_level_for_erase?
    self.state.reduce_one_level and @level > 1
  end
  def reduce_level_for_erase
    reset_count(@count_last)
    reduce(1)
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
    @count_last = v
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
    # 如果为新附加状态，且在例外状态数组中，比如本次行动才被附加的状态，则不减一
    return if f && added_states && added_states.include?(@id)
    @count -= 1
  end
  #--------------------------------------------------------------------------
  # ● 处理指定时机的结算公式
  #--------------------------------------------------------------------------
  def process_timing_formula(timing)
    STATE_EX.state_ex_when_add(self)    if timing == -1 # 状态附加时执行的内容
    STATE_EX.state_ex_when_remove(self) if timing == -2 # 状态解除时执行的内容
    formula = state.timing_evals[timing]
    return if formula.nil?
    a = @battler_from 
    b = @battler
    v = $game_variables
    s = $game_switches
    l = @level 
    id = @id
    begin
      value = Kernel.eval(formula).floor
    rescue
      p "【错误】处理 #{@battler.name} 的 #{id} 号状态[#{state.name}]的 timing 脚本时报错：" 
      p $!
      value = 0
    end
    if value != 0
      @battler.result.clear_damage_values
      @battler.result.hp_damage = value
      @battler.hp -= value
    end
    STATE_EX.state_ex_when_trigger(self)
  end
  #--------------------------------------------------------------------------
  # ● 获取绑定了伤害计算的时机数字的数组
  #--------------------------------------------------------------------------
  def timings
    state.timing_evals.keys
  end
end

end # end of module

#==============================================================================
# ■ 数据库-状态类
#==============================================================================
class RPG::State
  attr_reader :level, :max, :timing_evals, :reserve_when_die, :reduce_one_level
  #--------------------------------------------------------------------------
  # ● 进入游戏时读取备注栏
  #--------------------------------------------------------------------------
  def reset_state_ex
    # 读取可叠加的层数
    @level = STATE_EX.read_note_level(note)
    # 读取可同时存在的数量上限
    @max = STATE_EX.read_note_max(note)
    
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

    # 用层数来抵扣消除的标记
    @reduce_one_level = STATE_EX.read_note_level_reduce(note)
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
  # ● 初始化对象
  #--------------------------------------------------------------------------
  alias eagle_states_ex_initialize initialize
  def initialize
    eagle_states_ex_initialize
    @hp = 1  # 避免在初始化时 refresh 后附加死亡状态
  end
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
  # ● 获取指定id的状态的已附加个数
  #--------------------------------------------------------------------------
  def state_ex_sum(state_id)
    return @states_ex.count {|s| s.id == state_id }
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
        v = state_ex_sum(state_id); maxv = $data_states[state_id].max
        return if maxv > 0 and v >= maxv
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
        v = @states_ex.count { |s| s.id == state_id } if v.nil?
        v.times do 
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
  # ● 触发状态对象的伤害计算（计数不减少）
  #--------------------------------------------------------------------------
  def trigger_state_ex(state_id=nil, timing=nil)
    @states_ex.each do |s|
      if (state_id.is_a?(Integer) and state_id != s.id) or 
         (state_id.is_a?(Array) and !state_id.include?(s.id))
        next
      end
      s.timings.each do |t|
        if timing == nil or
          (timing.is_a?(Integer) and timing == t) or
          (timing.is_a?(Array) and timing.include?(t))
          s.process_timing_formula(t)
        end
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
        if data.reduce_level_for_erase?  # 用1层替代移除
          data.reduce_level_for_erase
          f = false
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
  # ● 处理伤害
  #    调用前需要设置好
  #    @result.hp_damage   @result.mp_damage 
  #    @result.hp_drain    @result.mp_drain
  #--------------------------------------------------------------------------
  alias eagle_state_ex_execute_damage execute_damage
  def execute_damage(user)
    v = @result.hp_damage  # 提前记录下伤害值，避免pop后被清空
    eagle_state_ex_execute_damage(user)
    if v > 0
      # 新增：对于按造成伤害次数来计数的状态，此处要减1
      user.update_state_turns_ex(3)
      # 新增：对于按受到伤害次数来计数的状态，此处要减1
      update_state_turns_ex(4)
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

#==============================================================================
# ■ 不再使用RGSS的状态
#==============================================================================
if FLAG_NO_RGSS3_STATE
class Game_Battler < Game_BattlerBase
  #--------------------------------------------------------------------------
  # ● 附加状态
  #--------------------------------------------------------------------------
  def add_state(state_id)
    add_state_ex(state_id)
  end
  #--------------------------------------------------------------------------
  # ● 解除状态
  #--------------------------------------------------------------------------
  def remove_state(state_id)
    remove_state_ex(state_id)
  end
end
end
