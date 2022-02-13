#==============================================================================
# ■ 能力学习系统 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【组件-通用方法汇总 by老鹰】与
#  【组件-位图绘制转义符文本 by老鹰】与
#  【组件-位图绘制窗口皮肤 by老鹰】与
#  【组件-形状绘制 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-AbilityLearn"] = "1.2.0"
#==============================================================================
# - 2022.2.12.10 新增调整帮助窗口位置
#==============================================================================
# - 本插件新增了每个角色的能力学习界面（仿霓虹深渊）
#------------------------------------------------------------------------------
# 【使用】
#
#    利用全局脚本 ABILITY_LEARN.call 呼叫能力学习界面。
#
#--------------------------------------------------------------------------
# 【设置】
#
# - 推荐在本插件的下一页脚本中，新增一个空白页，命名为“【角色能力设置】”，
#   并复制如下的内容，进行修改和扩写：
#
=begin
# --------复制以下的内容！--------

module ABILITY_LEARN
ACTORS ||= {}  # 确保常量存在，不要删除
PARAMS ||= {}  # 确保常量存在，不要删除

#--------------------------------------------------------------------------
# 首先确定是哪个角色的，把它的ID写在方括号里
#   此处写的是数据库中不存在的0号角色，防止出现冲突
ACTORS[0] = {  # 不要漏了花括号
#--------------------------------------------------------------------------
# 然后定义各个能力，把它的名称（建议数字或字符串，1 和 "1" 为不同名称）写在箭头前
#   不同能力的脚本中名称需要不同，比如这个能力的名称是 1
  1 => {
  #------------------------------------------------------------------------
  # 之后定义这个能力的各个属性
  #------------------------------------------------------------------------
  # -【必须】设置这个能力在UI界面中的位置
  #  （界面中格子的坐标，左上为0,0，往右为x正方向，往下为y正方向）
    :pos => [1, 1],
  #------------------------------------------------------------------------
  # -【可选】如果这个能力为一个技能，可以绑定它的ID
    :skill => 1,
  #------------------------------------------------------------------------
  # -【可选】如果这个能力等价一件武器或护甲，可以绑定它的ID
  #  （不影响平时的装备，只是把对应武器的基础能力和特性进行了提取）
    :weapon => 0,
    :armor => 0,
  #------------------------------------------------------------------------
  # -【可选】也可以直接设定一个图标ID进行显示
  #  （图标优先级为 :pic > :icon > :skill > :weapon > :armor）
    :icon => 0,
  #------------------------------------------------------------------------
  # -【可选】还可以指定为 Graphics\System 路径下的一张图片进行显示
  #  （只会显示在解锁界面，不会显示在帮助窗口里）
    :pic => "",
  #------------------------------------------------------------------------
  # -【可选】设置这个能力学习一次后，角色增加的基础属性值
  #  （编写 属性=数字 的字符串，用空格分隔不同属性，
  #    角色八维属性依次是 mhp mmp atk def mat mdf agi luk
  #    比如 "mhp=1" 为最大生命值增加1，
  #         "atk=1 mat=1"为物理攻击+1且魔法攻击+1）
  #  （如果该能力能够被反复学习，该属性也会反复增加多次）
    :params => "",
  #------------------------------------------------------------------------
  # -【可选】帮助窗口中这个能力的名称
  #  （名称优先级为 :name > :skill > :weapon > :armor > 脚本中的能力标识符）
    :name => "",
  #------------------------------------------------------------------------
  # -【可选】帮助窗口中追加显示的说明文本
  #  （显示在UI界面的能力帮助窗口中，显示在技能说明、属性说明的后面）
  #  （可以使用默认的扩展转义符，记得用 \\ 代替 \，比如 \\i[1] 显示1号图标）
    :help => "",
  #------------------------------------------------------------------------
  # -【可选】设置这个能力的最大层数，也就是可重复学习的最大次数
  #  （若不设置，默认为1）
    :level => 1,
  #------------------------------------------------------------------------
  # -【可选】学习一次这个能力，需要消耗的AP点数
  #  （如果不写或写0，则默认激活，:level固定1，:skill与:params与:eval_off无效）
    :ap => 1,
  #------------------------------------------------------------------------
  # -【可选】可以绑定一个开关，设置这个开关的ID
  #  （当能力解锁时，开关将赋值为 true，重置时，开关将赋值为 false）
  #  （只在能力解锁或重置时进行一次赋值，不会实时监控开关状态！请注意不要冲突了！）
    :sid => 1,
  #------------------------------------------------------------------------
  # -【可选】设置这个能力的学习前置要求
  #  （为一个数组，其中填写其他能力的脚本中名称，比如 [1,2,3] 或 [1,1, "1"]）
  #  （可以重复填写同一个能力的名称，此时为那个能力的层数需求）
  #  （但注意，对于设置了:ap为0的能力，是无法被学习的，也就无法被作为前置判定）
    :pre => [1],
  #------------------------------------------------------------------------
  # -【可选】设置这个能力的学习前置要求（扩展内容）
  #  （为一个数组，其中每一项依然为数组，数组内容依次为：
  #     [类型, 参数...] 或者为 [判定脚本, 学习时执行脚本, 说明文本]）
  #  （其中已经支持的类型如下：
  #     [:ap, name, v] → 脚本中名称为 name 的能力的等级不小于 v
  #                     （如果v为-1，则表示不可习得name能力）
  #                     （当v大于0时，效果与:pre一致，但不会绘制能力间连线）
  #     [:lv, v]   → 当前角色等级不小于v
  #     [:gold, v] → 消耗v金钱
  #     [:item, id, v] → 需要id号物品v个
  #   ）
  #  （注意：此处的学习消耗，在重置时并不会自动返还，
  #     但你可以在:eval_off中自己编写相应的返还，在:help中增加返还的说明文本）
  #  （脚本中可用缩写同 :if）
  #  （比如前置要求为 不可习得 "能力1号"，则可以写为
  #     [:ap, "能力1号", -1] ）
  #  （比如前置要求为 角色等级大于等于5，则可以写为
  #     [:lv, 5] 或者 ["actor.level>=5", "", "角色等级不小于5"] ）
  #  （比如前置要求为 消耗金钱x1000，则可以写为
  #     [:gold, 1000] 或者
  #     ["$game_party.gold>=1000","$game_party.lose_gold(1000)","消耗1000G"] ）
  #  （比如前置要求为 1号开关打开，则可以写为
  #     ["s[1]==true", "", "这里可以写一些说明文本，比如打败恶龙"] ）
    :pre_ex => [ [:lv, 5] ],
  #------------------------------------------------------------------------
  # -【可选】设置这个能力的出现条件
  #  （为一个字符串，当被 eval 后返回 true 时，才会显示这个能力）
  #  （可以用 s 代表 $game_switches，用 v 代表 $game_variables，
  #    用 actor 代表当前角色对象Game_Actor）
    :if => "" ,
  #------------------------------------------------------------------------
  # -【可选】学习后执行的脚本
  #  （每次学习，都会执行一次这个脚本）
  #  （可用缩写同 :if）
    :eval_on => "",
  #------------------------------------------------------------------------
  # -【可选】重置后执行的脚本
  #  （每次重置，都会执行一次这个脚本）
  #  （可用缩写同 :if）
    :eval_off => "", # 重置时执行的脚本
  #------------------------------------------------------------------------
  }, # 别忘了花括号，与能力 1 相对应；如果有多个能力，需要加个英语逗号进行分隔

  #------------------------------------------------------------------------
  #【便捷模板】绑定指定技能
  "模板-技能" => {  # 中文试试看
    :pos => [5, 5],  # 位置不可少
    :skill => 1,     # 技能要绑好
    :ap => 1,        # AP不要忘
    :pre => [1],     # 还可加前置
  },

  #------------------------------------------------------------------------
  #【便捷模板】绑定指定属性
  "模板-属性" => {
    :pos => [6, 7],  # 位置不可少
    :icon => 1,      # 显示啥图标
    :params => "atk=1", # 属性要列好
    :ap => 1,        # AP不要忘
    :level => 9,     # 等级也可有
  },

  #------------------------------------------------------------------------
  #【便捷模板】绑定指定开关
  # （学习后，对应开关打开，重置时关闭，也因此其它地方就别处理打开开关了）
  "模板-1号开关" => {
    :pos => [8, 5],  # 位置不可少
    :icon => 1,      # 显示啥图标
    :ap => 1,        # AP不要忘
    :eval_on => "s[1]=true",   # 开关应打开
    :eval_off => "s[1]=false", # 更记得要关
    # 或者只写 :sid => 1,  那就不需要写 :eval_on 与 :eval_off 了
  },

} # 与ACTORS[0]那一行所对应存在的花括号，不要漏了

# 此外，还可以在 PARAMS 哈希中设置一些针对单个角色的其它属性
# 当然不设置也完全没问题
PARAMS[0] = {  # 这里设置 0号角色 的一些参数
  #------------------------------------------------------------------------
  #【可选】需要显示的背景图片（默认 nil 无图片，可填入字符串）
  # （图片放置在 Graphics/System 目录下，比如0号角色背景图为 bg_ability_0.png，
  #   则此处填写后应该为 :bg => "bg_ability_0" ）
  # （图片的左上角与窗口左上角对齐）
  :bg => nil,
  #------------------------------------------------------------------------
  #【可选】是否显示网格背景（默认 true，若填 false 则不显示）
  # （该网格背景显示在 :bg 上方，显示在能力图标等的下方）
  :grid => true,
}

# 至此，0号角色设置完了

#--------------------------------------------------------------------------
# 推荐不要修改上面的样本，而是自己在下方编写新内容
#--------------------------------------------------------------------------

ACTORS[1] = {
  1 => { :pos => [4, 4], :skill => 1, :ap => 1 },
}

#--------------------------------------------------------------------------
end  # 必须的模块结尾，不要漏掉

# --------复制以上的内容！--------
=end
#
# - 如果没有设置角色的能力数据，那么在UI中就不会有任何能力。
#
#--------------------------------------------------------------------------
# 【高级】
#
# - 对于Game_Actor对象，用 $game_actors[1].add_ap(v) 为 1号角色增加 v 点AP
#
# - 利用全局脚本 $game_party.add_ap(v) 为队伍中的全部角色增加 v 点AP
#
#==============================================================================
module ABILITY_LEARN
  #--------------------------------------------------------------------------
  # ○【常量】能力点的名称
  #--------------------------------------------------------------------------
  AP_TEXT = "AP"
  #--------------------------------------------------------------------------
  # ○【常量】角色升一级时获得的AP点数
  #--------------------------------------------------------------------------
  AP_LEVEL_UP = 1
  #--------------------------------------------------------------------------
  # ○【常量】所有角色共有的能力数据
  #  注意：此处能力的唯一ID不要和其它的重复
  #--------------------------------------------------------------------------
  ALL_ACTORS = {
  # 这个能力用于重置全部能力
    "RESET" => {
      :pos => [1, 1],
      :icon => 280,
      :name => "重置",
      :help => "重置当前角色全部能力。\n仅返还#{AP_TEXT}，可能不会返还其它资源。",
      :eval_on => "ABILITY_LEARN.reset",
    },
    "TEST-add_ap" => {
      :pos => [1, 3],
      :icon => 184,
      :name => "测试-增加#{AP_TEXT}",
      :help => "队伍中全部角色增加 10 点#{AP_TEXT}。",
      :eval_on => "$game_party.add_ap(10); ABILITY_LEARN.redraw_actor_info",
      :if => "$TEST",
    },
  }
  #--------------------------------------------------------------------------
  # ○【常量】角色数据
  #--------------------------------------------------------------------------
  ACTORS ||= {}
  PARAMS ||= {}
  #--------------------------------------------------------------------------
  # ○【常量】格子的宽度/高度
  #--------------------------------------------------------------------------
  GRID_W = 32
  GRID_H = 32
  #--------------------------------------------------------------------------
  # ○【常量】最大的格子数（横、竖）
  #--------------------------------------------------------------------------
  GRID_MAX_X = 20
  GRID_MAX_Y = 20
  #--------------------------------------------------------------------------
  # ○【常量】能力图标中，等级数字的字体大小
  #--------------------------------------------------------------------------
  TOKEN_LEVEL_FONT_SIZE = 14
  #--------------------------------------------------------------------------
  # ○【常量】帮助窗口的皮肤文件
  #--------------------------------------------------------------------------
  HELP_TEXT_WINDOWSKIN = "Window"
  #--------------------------------------------------------------------------
  # ○【常量】帮助窗口中文本的字体大小
  #--------------------------------------------------------------------------
  HELP_TEXT_FONT_SIZE = 20
  #--------------------------------------------------------------------------
  # ○【常量】帮助窗口的空白边框宽度
  #--------------------------------------------------------------------------
  HELP_TEXT_BORDER_WIDTH = 12
  #--------------------------------------------------------------------------
  # ○【常量】帮助窗口中，满足条件的文本的前置符号
  #--------------------------------------------------------------------------
  HELP_TEXT_COND_OK = "○"
  #--------------------------------------------------------------------------
  # ○【常量】帮助窗口中，不满足条件的文本的前置符号
  #--------------------------------------------------------------------------
  HELP_TEXT_COND_NO = "×"
  #--------------------------------------------------------------------------
  # ○【常量】帮助窗口中，不满足条件的文本的颜色
  #--------------------------------------------------------------------------
  HELP_TEXT_COLOR_NOT = 10
  #--------------------------------------------------------------------------
  # ○【常量】帮助窗口的位置类型
  # 0 时代表随光标移动，1 代表使用固定值，-1~-9代表屏幕上的位置
  #  如 -1 代表屏幕左下角，-9 代表屏幕右上角
  #--------------------------------------------------------------------------
  HELP_TEXT_POS = 0
  #--------------------------------------------------------------------------
  # ○【常量】帮助窗口的显示位置
  #  HELP_TEXT_POS为 1 时生效，
  #  先设置显示原点（九宫格小键盘），如 5 代表中点，7 代表左上角，2 代表底部中点
  #  再设置屏幕坐标
  #--------------------------------------------------------------------------
  HELP_TEXT_POS1_O = 2
  HELP_TEXT_POS1_X = Graphics.width / 2
  HELP_TEXT_POS1_Y = Graphics.height - 30 - 64
  #--------------------------------------------------------------------------
  # ○【常量】帮助窗口的显示位置
  #  HELP_TEXT_POS为 -1~-9 时生效，
  #  设置显示原点（九宫格小键盘），再放到屏幕上对应位置
  #--------------------------------------------------------------------------
  HELP_TEXT_POS_1_O = 5
  #--------------------------------------------------------------------------
  # ○【常量】底部角色信息中文本的字体大小
  #--------------------------------------------------------------------------
  INFO_TEXT_FONT_SIZE = 20
  #--------------------------------------------------------------------------
  # ○【常量】底部角色信息的预设高度
  #--------------------------------------------------------------------------
  INFO_TEXT_HEIGHT = 64
  #--------------------------------------------------------------------------
  # ○【常量】底部按键提示文本的字体大小
  #--------------------------------------------------------------------------
  HINT_FONT_SIZE = 16
  #--------------------------------------------------------------------------
  # ○【常量】基础属性与对应ID
  #--------------------------------------------------------------------------
  PARAMS_TO_ID = {
    :mhp => 0, :mmp => 1, :atk => 2, :def => 3,
    :mat => 4, :mdf => 5, :agi => 6, :luk => 7,
  }

#==============================================================================
# ■ 数据读取
#==============================================================================
  #--------------------------------------------------------------------------
  # ● 获取指定角色的特别设置
  #--------------------------------------------------------------------------
  def self.get_params(actor_id)
    PARAMS[actor_id] || {}
  end
  #--------------------------------------------------------------------------
  # ● 获取指定角色的全部数据
  #--------------------------------------------------------------------------
  def self.get_tokens(actor_id)
    ACTORS[actor_id] || {}
  end
  def self.get_tokens_all
    ALL_ACTORS
  end
  #--------------------------------------------------------------------------
  # ● 获取指定角色的指定id的数据hash
  #--------------------------------------------------------------------------
  def self.get_token(actor_id, token_id)
    return ALL_ACTORS[token_id] if ALL_ACTORS[token_id]
    if ACTORS[actor_id]
      return ACTORS[actor_id][token_id] || {}
    end
    return {}
  end

  #--------------------------------------------------------------------------
  # ● 获取指定id的对应技能
  #--------------------------------------------------------------------------
  def self.get_token_skill(actor_id, token_id)
    ps = get_token(actor_id, token_id)
    ps[:skill] || nil
  end
  #--------------------------------------------------------------------------
  # ● 获取指定id的武器的数据
  #--------------------------------------------------------------------------
  def self.get_token_weapon(actor_id, token_id)
    ps = get_token(actor_id, token_id)
    return ps[:weapon] if ps[:weapon] && ps[:weapon] > 0
    return nil
  end
  #--------------------------------------------------------------------------
  # ● 获取指定id的护甲的数据
  #--------------------------------------------------------------------------
  def self.get_token_armor(actor_id, token_id)
    ps = get_token(actor_id, token_id)
    return ps[:armor] if ps[:armor] && ps[:armor] > 0
    return nil
  end
  #--------------------------------------------------------------------------
  # ● 获取指定id的绑定开关
  #--------------------------------------------------------------------------
  def self.get_token_sid(actor_id, token_id)
    ps = get_token(actor_id, token_id)
    ps[:sid] || nil
  end
  #--------------------------------------------------------------------------
  # ● 获取指定id的名称
  #--------------------------------------------------------------------------
  def self.get_token_name(actor_id, token_id)
    ps = get_token(actor_id, token_id)
    return ps[:name] if ps[:name] && ps[:name] != ""
    if ps[:skill] && ps[:skill] > 0
      return $data_skills[ps[:skill]].name
    end
    if ps[:weapon] && ps[:weapon] > 0
      return $data_weapons[ps[:weapon]].name
    end
    if ps[:armor] && ps[:armor] > 0
      return $data_armors[ps[:armor]].name
    end
    token_id.to_s
  end
  #--------------------------------------------------------------------------
  # ● 获取指定id的对应图标
  #--------------------------------------------------------------------------
  def self.get_token_icon(actor_id, token_id)
    ps = get_token(actor_id, token_id)
    return ps[:icon] if ps[:icon] && ps[:icon] > 0
    if ps[:skill] && ps[:skill] > 0
      return $data_skills[ps[:skill]].icon_index
    end
    if ps[:weapon] && ps[:weapon] > 0
      return $data_weapons[ps[:weapon]].icon_index
    end
    if ps[:armor] && ps[:armor] > 0
      return $data_armors[ps[:armor]].icon_index
    end
    return 0
  end
  #--------------------------------------------------------------------------
  # ● 获取指定id的对应图片bitmap
  #--------------------------------------------------------------------------
  def self.get_token_pic(actor_id, token_id)
    ps = get_token(actor_id, token_id)
    b = Cache.system(ps[:pic]) rescue nil
    b
  end
  #--------------------------------------------------------------------------
  # ● 获取指定id的属性值Hash（利用paras_params进行解析）
  #--------------------------------------------------------------------------
  def self.get_token_params(actor_id, token_id)
    ps = get_token(actor_id, token_id)
    str = ps[:params]
    if str
      hash = EAGLE_COMMON.parse_tags(str)
      return hash
    end
    return {}
  end
  #--------------------------------------------------------------------------
  # ● 获取指定id的ap消耗量
  #--------------------------------------------------------------------------
  def self.get_token_ap(actor_id, token_id)
    ps = get_token(actor_id, token_id)
    ps[:ap] || 0
  end
  #--------------------------------------------------------------------------
  # ● 获取指定id是否可以再次学习
  #--------------------------------------------------------------------------
  def self.get_token_level(actor_id, token_id)
    ps = get_token(actor_id, token_id)
    ps[:level] || 1
  end
  #--------------------------------------------------------------------------
  # ● 获取指定id的on/off时的触发脚本
  #--------------------------------------------------------------------------
  def self.get_token_eval_on(actor_id, token_id)
    ps = get_token(actor_id, token_id)
    ps[:eval_on] || nil
  end
  def self.get_token_eval_off(actor_id, token_id)
    ps = get_token(actor_id, token_id)
    ps[:eval_off] || nil
  end
  #--------------------------------------------------------------------------
  # ● 获取指定id的前置id们
  #--------------------------------------------------------------------------
  def self.get_token_pre(actor_id, token_id)
    ps = get_token(actor_id, token_id)
    ps[:pre] || []
  end
  #--------------------------------------------------------------------------
  # ● 获取指定id的扩展前置条件
  #--------------------------------------------------------------------------
  def self.get_token_pre_ex(actor_id, token_id)
    ps = get_token(actor_id, token_id)
    ps[:pre_ex] || []
  end
  def self.process_pre_ex(actor_id, token_id, ps, type=:cond)
    # ps = [sym, value...] or [cond_eval, run_eval, text]
    # type 为 :cond 代表为是否满足条件
    #      为 :run  代表解锁时需要执行的内容
    #      为 :text 代表显示的文本
    if ps[0].is_a?(Symbol)
      case ps[0]
      when :ap
        id2 = ps[1]
        v_cur = self.level(id2)
        v = ps[2].to_i
        if type == :cond
          return true if v == 0
          return false if v < 0 && v_cur > 0
          return v_cur >= v
        elsif type == :run
        elsif type == :text
          name = self.get_token_name(actor_id, id2)
          icon = self.get_token_icon(actor_id, id2)
          return "不可习得 \\i[#{icon}]#{name}" if v < 0
          return "\\i[#{icon}]#{name} lv.#{v}" if v > 0
        end
      when :lv
        if type == :cond
          return $game_actors[actor_id].level >= ps[1]
        elsif type == :run
        elsif type == :text
          return "角色#{Vocab.level}不小于#{ps[1]}"
        end
      when :gold
        if type == :cond
          return $game_party.gold >= ps[1]
        elsif type == :run
          $game_party.lose_gold(ps[1])
        elsif type == :text
          return "需要 #{ps[1]} #{Vocab.currency_unit}"
        end
      when :item
        item = $data_items[ps[1]]
        if type == :cond
          return $game_party.item_number(item) >= ps[2]
        elsif type == :run
          $game_party.lose_item(item, ps[2])
        elsif type == :text
          return "需要 \\i[#{item.icon_index}]#{item.name} x #{ps[2]}"
        end
      end
    else
      if type == :cond
        return eagle_eval(ps[0], actor_id) == true
      elsif type == :run
        eagle_eval(ps[1])
      elsif type == :text
        return ps[2]
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 获取指定id的帮助文本
  #--------------------------------------------------------------------------
  def self.get_token_help(actor_id, token_id)
    data = $game_actors[@actor_id].eagle_ability_data
    t = ""

    skill_id = get_token_skill(actor_id, token_id)
    weapon_id = get_token_weapon(actor_id, token_id)
    armor_id = get_token_armor(actor_id, token_id)
    icon = get_token_icon(actor_id, token_id)
    t += "\\i[#{icon}]" if icon > 0
    name = get_token_name(actor_id, token_id)
    t += "#{name} "
    if skill_id && skill_id > 0
      skill = $data_skills[skill_id]
      stype = $data_system.skill_types[skill.stype_id]
      t += "\\c[8]#{stype}\\c[0]\n"
      _t = " >> " + skill.description.gsub("\r\n") { "\n    " }
      t += _t
    elsif weapon_id && weapon_id > 0
      weapon = $data_weapons[weapon_id]
      t += "\n"
      _t = " >> " + weapon.description.gsub("\r\n") { "\n    " }
      t += _t
    elsif armor_id && armor_id > 0
      armor = $data_armors[armor_id]
      t += "\n"
      _t = " >> " + armor.description.gsub("\r\n") { "\n    " }
      t += _t
    else
    end
    t += "\\ln"

    params_hash = get_token_params(actor_id, token_id)
    if !params_hash.empty?
      params_hash.each do |sym, v|
        param_id = ABILITY_LEARN::PARAMS_TO_ID[sym]
        _v = v.to_i
        if param_id && _v != 0
          t += Vocab.param(param_id) + (_v > 0 ? "+#{_v}" : "-#{_v.abs}") + " "
        end
      end
      t += "\\ln"
    end

    ps = get_token(actor_id, token_id)
    if ps[:help] && ps[:help] != ""
      t += " >> " + ps[:help].gsub("\r\n") { "\n    " } + "\\ln"
    end

    if no_unlock?(token_id)
      t += " >> 无需学习\n"
    else
      v = get_token_ap(actor_id, token_id)
      if !unlock?(token_id)
        pres_all = ABILITY_LEARN.get_token_pre(actor_id, token_id)
        pres = pres_all | pres_all
        t += "要求：\n"
        # 处理前置需求
        pres.each do |id2|
          name = get_token_name(actor_id, id2)
          icon = get_token_icon(actor_id, id2)
          l = pres_all.count(id2)
          lv = level(id2)
          t += (lv >= l ? " #{HELP_TEXT_COND_OK} " : \
                "\\c[#{HELP_TEXT_COLOR_NOT}] #{HELP_TEXT_COND_NO} ")
          t += "\\i[#{icon}]#{name} lv.#{l}\\c[0]\n"
        end
        # 处理扩展的前置需求
        pres_ex = get_token_pre_ex(actor_id, token_id)
        pres_ex.each do |ps|
          f = process_pre_ex(actor_id, token_id, ps, :cond)
          t += (f ? " #{HELP_TEXT_COND_OK} " : \
                "\\c[#{HELP_TEXT_COLOR_NOT}] #{HELP_TEXT_COND_NO} ")
          t += "#{process_pre_ex(actor_id, token_id, ps, :text)}\\c[0]\n"
        end
        # 处理ap消耗
        t += "\\c[#{HELP_TEXT_COLOR_NOT}]" if data.ap < v # ap不足
        t += " - #{v} 点#{AP_TEXT}\\c[0]\n"
      else
        level = data.level(token_id)
        level_max = get_token_level(actor_id, token_id)
        if level_max > 1 && level < level_max
          t += "当前等级 #{level}（最大#{level_max}）\n"
          t += "\\c[#{HELP_TEXT_COLOR_NOT}]" if data.ap < v # ap不足
          t += " - #{v} 点#{AP_TEXT}提升等级\\c[0]\n"
        else
          t += " >> 已达最大等级 lv.#{level_max}\n"
        end
      end
    end

    return t
  end
#==============================================================================
# ■ 便捷使用（仅UI内）
#==============================================================================
  #--------------------------------------------------------------------------
  # ● 重置解锁
  #--------------------------------------------------------------------------
  def self.reset
    actor = $game_actors[@actor_id]
    data = actor.eagle_ability_data
    data.reset
    reset_actor(@actor_id) if @flag_ui
  end
  #--------------------------------------------------------------------------
  # ● 指定id已经解锁？
  #--------------------------------------------------------------------------
  def self.unlock?(token_id)
    $game_actors[@actor_id].eagle_ability_data.unlock?(token_id)
  end
  #--------------------------------------------------------------------------
  # ● 指定id不需要解锁？
  #--------------------------------------------------------------------------
  def self.no_unlock?(token_id)
    $game_actors[@actor_id].eagle_ability_data.no_unlock?(token_id)
  end
  #--------------------------------------------------------------------------
  # ● 指定id允许再次解锁？
  #--------------------------------------------------------------------------
  def self.repeat?(token_id)
    return false if !unlock?(token_id)
    f = get_token_level(@actor_id, token_id)
    return false if f <= 0
    return false if f <= level(token_id)
    return true
  end
  #--------------------------------------------------------------------------
  # ● 指定id的层数
  #--------------------------------------------------------------------------
  def self.level(token_id)
    return $game_actors[@actor_id].eagle_ability_data.level(token_id)
  end
  #--------------------------------------------------------------------------
  # ● eval
  #--------------------------------------------------------------------------
  def self.eagle_eval(str, actor_id = nil)
    actor_id ||= @actor_id
    actor = $game_actors[actor_id] rescue nil
    EAGLE_COMMON.eagle_eval(str)
  end
end

#==============================================================================
# ■ UI
#==============================================================================
class << ABILITY_LEARN
  #--------------------------------------------------------------------------
  # ● UI-开启
  #--------------------------------------------------------------------------
  def call
    @flag_ui = true
    begin
      init_ui
      update_ui
    rescue
      p $!
    ensure
      dispose_ui
    end
    @flag_ui = false
  end
  #--------------------------------------------------------------------------
  # ● UI-结束并释放
  #--------------------------------------------------------------------------
  def dispose_ui
    instance_variables.each do |varname|
      ivar = instance_variable_get(varname)
      if ivar.is_a?(Sprite)
        ivar.bitmap.dispose if ivar.bitmap
        ivar.dispose
      end
    end
    @sprites_token.each { |id, s| s.dispose }
    @viewport_bg.dispose
  end
  #--------------------------------------------------------------------------
  # ● UI-最大的横纵像素数
  #--------------------------------------------------------------------------
  def ui_max_x
    ABILITY_LEARN::GRID_W * ABILITY_LEARN::GRID_MAX_X
  end
  def ui_max_y
    ABILITY_LEARN::GRID_H * ABILITY_LEARN::GRID_MAX_Y
  end
  #--------------------------------------------------------------------------
  # ● UI-初始化
  #--------------------------------------------------------------------------
  def init_ui
    # 暗色背景
    @sprite_bg = Sprite.new
    @sprite_bg.z = 200
    set_sprite_bg(@sprite_bg)

    # 背景字
    @sprite_bg_info = Sprite.new
    @sprite_bg_info.z = @sprite_bg.z + 1
    set_sprite_info(@sprite_bg_info)

    # 底部按键提示
    @sprite_hint = Sprite.new
    @sprite_hint.z = @sprite_bg.z + 20
    set_sprite_hint(@sprite_hint)

    # 视图
    @viewport_bg = Viewport.new(0,0,Graphics.width,Graphics.height-24)
    @viewport_bg.z = @sprite_bg.z + 10

    # 网格背景
    @sprite_grid = Sprite.new(@viewport_bg)
    @sprite_grid.z = 10
    w = ui_max_x; h = ui_max_y
    @sprite_grid.bitmap = Bitmap.new(w, h)
    _x = 0; _y = 0; c = Color.new(255,255,255, 20)
    loop do
      _x += ABILITY_LEARN::GRID_W
      break if _x >= w
      @sprite_grid.bitmap.fill_rect(_x, 0, 1, h, c)
    end
    loop do
      _y += ABILITY_LEARN::GRID_H
      break if _y >= h
      @sprite_grid.bitmap.fill_rect(0, _y, w, 1, c)
    end

    # 背景连线
    @sprite_lines = Sprite.new(@viewport_bg)
    @sprite_lines.z = @sprite_grid.z + 10
    @sprite_lines.bitmap = Bitmap.new(ui_max_x, ui_max_y)

    # 光标
    @sprite_player = Sprite_AbilityLearn_Player.new(@viewport_bg)
    @sprite_player.z = @sprite_grid.z + 100
    @params_player = { :last_input => nil, :last_input_c => 0, :d => 1 }

    # 全部能力
    @sprites_token = {}

    # 角色信息文本
    @sprite_actor_info = Sprite_AbilityLearn_ActorInfo.new
    @sprite_actor_info.z = @sprite_hint.z + 1

    # 说明文本
    @sprite_help = Sprite_AbilityLearn_TokenHelp.new
    @sprite_help.z = @sprite_hint.z + 2

    # 角色背景图片
    @sprite_actor_bg = Sprite.new(@viewport_bg)
    @sprite_actor_bg.z = 1

    # 重置当前角色
    @actor = $game_party.menu_actor
    reset_actor(@actor.id)
  end
  #--------------------------------------------------------------------------
  # ● 设置背景精灵
  #--------------------------------------------------------------------------
  def set_sprite_bg(sprite)
    sprite.bitmap = Bitmap.new(Graphics.width, Graphics.height)
    sprite.bitmap.fill_rect(0, 0, sprite.width, sprite.height,
      Color.new(0,0,0,200))
  end
  #--------------------------------------------------------------------------
  # ● 设置LOG标题精灵
  #--------------------------------------------------------------------------
  def set_sprite_info(sprite)
    sprite.zoom_x = sprite.zoom_y = 3.0
    sprite.bitmap = Bitmap.new(Graphics.height, Graphics.height)
    sprite.bitmap.font.size = 48
    sprite.bitmap.font.color = Color.new(255,255,255,10)
    sprite.bitmap.draw_text(0,0,sprite.width,64, "ABILITY", 0)
    sprite.angle = -90
    sprite.x = Graphics.width + 48
    sprite.y = 0
  end
  #--------------------------------------------------------------------------
  # ● 设置按键提示精灵
  #--------------------------------------------------------------------------
  def set_sprite_hint(sprite)
    sprite.bitmap = Bitmap.new(Graphics.width, 24)
    sprite.bitmap.font.size = ABILITY_LEARN::HINT_FONT_SIZE
    redraw_hint(sprite)
    sprite.oy = sprite.height
    sprite.y = Graphics.height
  end
  #--------------------------------------------------------------------------
  # ● 重绘按键提示
  #--------------------------------------------------------------------------
  def redraw_hint(sprite)
    t = "方向键 - 移动 | "
    if @selected_token
      if ABILITY_LEARN.no_unlock?(@selected_token.id)
        t += "确定键 - 激活 | "
      elsif !ABILITY_LEARN.unlock?(@selected_token.id)
        t += "确定键 - 学习 | "
      elsif ABILITY_LEARN.repeat?(@selected_token.id)
        t += "确定键 - 再次学习 | "
      end
    end
    t += "取消键 - 退出"
    sprite.bitmap.clear
    sprite.bitmap.draw_text(0, 2, sprite.width, sprite.height, t, 1)
    sprite.bitmap.fill_rect(0, 0, sprite.width, 1,
      Color.new(255,255,255,120))
  end
  #--------------------------------------------------------------------------
  # ● 重置当前角色
  #--------------------------------------------------------------------------
  def reset_actor(actor_id)
    @actor_id = actor_id
    check_params
    redraw_tokens
    redraw_lines
    @sprite_actor_info.set_actor(@actor_id)
    @viewport_bg.ox = 0
    @viewport_bg.oy = 0
  end
  #--------------------------------------------------------------------------
  # ● 检查设置
  #--------------------------------------------------------------------------
  def check_params
    ps = ABILITY_LEARN.get_params(@actor_id)

    if ps[:bg]
      @sprite_actor_bg.bitmap = Cache.system(ps[:bg]) rescue Cache.empty_bitmap
      @sprite_actor_bg.visible = true
    else
      @sprite_actor_bg.visible = false
    end

    ps[:grid] ||= true
    @sprite_grid.visible = ps[:grid]
  end
  #--------------------------------------------------------------------------
  # ● 重绘全部能力
  #--------------------------------------------------------------------------
  def redraw_tokens
    @selected_token = nil # 当前选中的能力token精灵
    @sprites_token.each { |id, s| s.dispose }
    @sprites_token.clear

    tokens = ABILITY_LEARN.get_tokens(@actor_id)
    tokens.merge(ABILITY_LEARN.get_tokens_all).each do |id, ps|
      next if ps[:if] && ABILITY_LEARN.eagle_eval(ps[:if], @actor_id) != true
      s = Sprite_AbilityLearn_Token.new(@viewport_bg, @actor_id, id, ps)
      s.z = @sprite_grid.z + 20
      @sprites_token[id] = s
    end
  end
  #--------------------------------------------------------------------------
  # ● 重绘背景连线
  #--------------------------------------------------------------------------
  def redraw_lines
    @sprite_lines.bitmap.clear
    @sprites_token.each do |id, s1|
      f = ABILITY_LEARN.unlock?(id)
      pres_all = ABILITY_LEARN.get_token_pre(@actor_id, id)
      pres = pres_all | pres_all
      pres.each do |id2|
        s2 = @sprites_token[id2]
        next if s2 == nil
        c = Color.new(255,255,255, 150)
        if f
          t = "1"
        elsif ABILITY_LEARN.unlock?(id2)
          n = pres_all.count(id2)
          l = ABILITY_LEARN.level(id2)
          if l >= n
            t = "001111111"
          else
            t = "0011"
          end
        else
          t = "0011"
        end
        # 绘制从s1到s2的直线
        EAGLE.DDALine(@sprite_lines.bitmap, s1.x,s1.y, s2.x, s2.y, 1, t, c)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 重绘当前角色的信息
  #--------------------------------------------------------------------------
  def redraw_actor_info
    @sprite_actor_info.refresh
  end
  #--------------------------------------------------------------------------
  # ● UI-更新
  #--------------------------------------------------------------------------
  def update_ui
    loop do
      update_basic
      update_player
      update_unlock
      update_actors
      break if finish_ui?
    end
  end
  #--------------------------------------------------------------------------
  # ● UI-基础更新
  #--------------------------------------------------------------------------
  def update_basic
    Graphics.update
    Input.update
  end
  #--------------------------------------------------------------------------
  # ● UI-退出？
  #--------------------------------------------------------------------------
  def finish_ui?
    Input.trigger?(:B)
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

    # 检查显示区域
    vp = @viewport_bg
    if s.x - s.ox - vp.ox < 0
      vp.ox = s.x - s.ox
    elsif s.x - s.ox + s.width - vp.ox > vp.rect.width
      vp.ox = s.x - s.ox + s.width - vp.rect.width
    end
    if s.y - s.oy - vp.oy < 0
      vp.oy = s.y - s.oy
    elsif s.y - s.oy + s.height - vp.oy > vp.rect.height
      vp.oy = s.y - s.oy + s.height - vp.rect.height
    end

    # 更新是否有选中的token
    if @selected_token && @selected_token.overlap?(s)
      # 之前的还是被选中的状态
    else
      @selected_token = nil
      @sprites_token.each do |id, st|
        break @selected_token = st if st.overlap?(s)
      end
      if @selected_token # 选中
        Sound.play_cursor
        @sprite_help.redraw(@selected_token)
        redraw_hint(@sprite_hint)
      elsif @sprite_help.visible  # 从选中变成没有选中任何能力
        redraw_hint(@sprite_hint)
        @sprite_help.visible = false
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● UI-更新解锁
  #--------------------------------------------------------------------------
  def update_unlock
    if @selected_token && Input.trigger?(:C)
      data = $game_actors[@actor_id].eagle_ability_data
      id = @selected_token.id
      if data.can_unlock?(id)
        Sound.play_ok
        data.unlock(id)
        refresh
      else
        Sound.play_buzzer
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 解锁后重绘
  #--------------------------------------------------------------------------
  def refresh
    if @selected_token
      @selected_token.refresh
      @sprite_help.redraw(@selected_token)
    end
    redraw_lines
    redraw_actor_info
    redraw_hint(@sprite_hint)
  end
  #--------------------------------------------------------------------------
  # ● UI-更新角色切换
  #--------------------------------------------------------------------------
  def update_actors
    if Input.trigger?(:R)  # pagedown 下一个角色
      @actor = $game_party.menu_actor_next
      reset_actor(@actor.id)
    elsif Input.trigger?(:L)  # pageup 上一个角色
      @actor = $game_party.menu_actor_prev
      reset_actor(@actor.id)
    end
  end
end

#==============================================================================
# ■ 玩家光标精灵
#==============================================================================
class Sprite_AbilityLearn_Player < Sprite
  include ABILITY_LEARN
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(vp)
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
    self.bitmap = Bitmap.new(GRID_W, GRID_H)
    self.bitmap.fill_rect(0, 0, GRID_W, GRID_H, Color.new(255,255,255,200))
    self.bitmap.clear_rect(2, 2, GRID_W-4, GRID_H-4)
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

#==============================================================================
# ■ 角色信息精灵
#==============================================================================
class Sprite_AbilityLearn_ActorInfo < Sprite
  include ABILITY_LEARN
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(vp = nil)
    super(vp)
    self.bitmap = Bitmap.new(Graphics.width, INFO_TEXT_HEIGHT)
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    self.bitmap.dispose
    super
  end
  #--------------------------------------------------------------------------
  # ● 设置角色
  #--------------------------------------------------------------------------
  def set_actor(actor_id)
    @actor_id = actor_id
    refresh
    reset_position
  end
  #--------------------------------------------------------------------------
  # ● 刷新
  #--------------------------------------------------------------------------
  def refresh
    self.bitmap.clear
    actors = $game_party.members
    _x = 0
    _w_key = 32  # 按键提示的占位宽度
    _offset = 6  # 角色行走图与文本信息之间的间隔距离
    # 绘制L切换提示
    self.bitmap.font.size = INFO_TEXT_FONT_SIZE
    self.bitmap.font.color = Color.new(255,255,255,255)
    self.bitmap.draw_text(_x,0,_w_key,self.height,"Q",1)
    self.bitmap.draw_text(_x,self.height/2,_w_key,self.height/2,"<<",1)
    _x += _w_key
    actors.each do |actor|
      # 绘制行走图
      cw, ch = EAGLE_COMMON.draw_character(self.bitmap, actor.character_name,
        actor.character_index, _x, self.height - 2)
      _x += cw
      # 绘制信息
      if actor.id == @actor_id
        data = actor.eagle_ability_data
        t = "#{actor.name}\n#{AP_TEXT} #{data.ap} / #{data.ap_max}"
        ps = { :font_size => INFO_TEXT_FONT_SIZE,
          :font_color => self.bitmap.font.color,
          :x0 => _x+_offset, :y0 => 0, :lhd => 2 }
        d = Process_DrawTextEX.new(t, ps, self.bitmap)
        d.run(false)
        ps[:y0] = self.height - d.height
        d.run(true)
        _x += _offset + d.width + _offset
      end
    end
    # 绘制R切换提示
    self.bitmap.font.size = INFO_TEXT_FONT_SIZE
    self.bitmap.font.color = Color.new(255,255,255,255)
    self.bitmap.draw_text(_x,0,_w_key,self.height,"E",1)
    self.bitmap.draw_text(_x,self.height/2,_w_key,self.height/2,">>",1)
  end
  #--------------------------------------------------------------------------
  # ● 重置位置
  #--------------------------------------------------------------------------
  def reset_position
    self.x = 10
    self.y = Graphics.height - 30 - self.height
  end
end

#==============================================================================
# ■ 能力精灵
#==============================================================================
class Sprite_AbilityLearn_Token < Sprite
  attr_reader :actor_id, :id
  include ABILITY_LEARN
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(vp, actor_id, token_id, ps)
    super(vp)
    @actor_id = actor_id
    @id = token_id
    refresh
    pos = ps[:pos] || [0, 0]
    reset_position(pos[0], pos[1])
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    self.bitmap.dispose
    super
  end
  #--------------------------------------------------------------------------
  # ● 刷新（解锁后调用）
  #--------------------------------------------------------------------------
  def refresh
    reset_bitmap
    draw_level
    self.color = Color.new(0,0,0,0)
    if !ABILITY_LEARN.unlock?(@id)
      self.color = Color.new(0,0,0,120)
    end
  end
  #--------------------------------------------------------------------------
  # ● 重设位图
  #--------------------------------------------------------------------------
  def reset_bitmap
    pic_bitmap = ABILITY_LEARN.get_token_pic(@actor_id, @id)
    return redraw(nil, pic_bitmap) if pic_bitmap
    icon = ABILITY_LEARN.get_token_icon(@actor_id, @id)
    return redraw(icon) if icon && icon > 0
    redraw(1)
  end
  #--------------------------------------------------------------------------
  # ● 重绘
  #--------------------------------------------------------------------------
  def redraw(icon = nil, pic_bitmap = nil)
    if icon
      if self.bitmap && (self.width != GRID_W || self.height != GRID_H)
        self.bitmap.dispose
        self.bitmap = nil
      end
      self.bitmap ||= Bitmap.new(GRID_W, GRID_H)
      self.bitmap.clear
      EAGLE_COMMON.draw_icon(self.bitmap, icon, 0, 0, self.width, self.height)
      return
    end
    if pic_bitmap
      self.bitmap.dispose if self.bitmap
      self.bitmap = pic_bitmap.dup
      return
    end
  end
  #--------------------------------------------------------------------------
  # ● 绘制层数
  #--------------------------------------------------------------------------
  def draw_level
    f = ABILITY_LEARN.get_token_level(@actor_id, @id)
    return if f <= 1
    level = ABILITY_LEARN.level(@id)
    return if level <= 0
    s = TOKEN_LEVEL_FONT_SIZE
    self.bitmap.font.size = s
    self.bitmap.font.outline = true
    self.bitmap.font.color = Color.new(255,255,255,255)
    self.bitmap.draw_text(0,self.height-s,self.width,s, level, 1)
  end
  #--------------------------------------------------------------------------
  # ● 重置位置
  #--------------------------------------------------------------------------
  def reset_position(grid_x, grid_y)
    self.ox = self.width / 2
    self.oy = self.height / 2
    self.x = GRID_W * grid_x + self.ox
    self.y = GRID_H * grid_y + self.oy
  end
  #--------------------------------------------------------------------------
  # ● 指定sprite位于当前精灵上？
  #--------------------------------------------------------------------------
  def overlap?(sprite)
    pos_x = sprite.x - sprite.ox + sprite.width / 2
    pos_y = sprite.y - sprite.oy + sprite.height / 2
    return false if pos_x < self.x - self.ox
    return false if pos_y < self.y - self.oy
    return false if pos_x > self.x - self.ox + self.width
    return false if pos_y > self.y - self.oy + self.height
    return true
  end
end

#==============================================================================
# ■ 帮助文本精灵
#==============================================================================
class Sprite_AbilityLearn_TokenHelp < Sprite
  include ABILITY_LEARN
  #--------------------------------------------------------------------------
  # ● 重绘
  #--------------------------------------------------------------------------
  def redraw(s)
    self.bitmap.dispose if self.bitmap
    self.bitmap = nil

    text = ABILITY_LEARN.get_token_help(s.actor_id, s.id)
    return if text == ""

    ps = { :font_size => HELP_TEXT_FONT_SIZE, :x0 => 0, :y0 => 0, :lhd => 2 }
    d = Process_DrawTextEX.new(text, ps)
    d.run(false)

    w = d.width + HELP_TEXT_BORDER_WIDTH * 2
    h = d.height + HELP_TEXT_BORDER_WIDTH * 2
    self.bitmap = Bitmap.new(w, h)

    skin = HELP_TEXT_WINDOWSKIN
    EAGLE.draw_windowskin(skin, self.bitmap,
      Rect.new(0, 0, self.width, self.height))

    ps[:x0] = HELP_TEXT_BORDER_WIDTH
    ps[:y0] = HELP_TEXT_BORDER_WIDTH
    d.bind_bitmap(self.bitmap)
    d.run(true)

    # 设置位置
    self.visible = true
    case HELP_TEXT_POS
    when 0
      if s.x + s.width / 2 + self.width > Graphics.width
        # 显示在左侧
        self.x = s.x - s.width / 2 - self.width
      else
        # 显示在右侧
        self.x = s.x + s.width / 2
      end
      self.y = s.y - s.height / 2
      d = self.y + self.height - Graphics.height
      if d > 0
        self.y -= d
        self.y = [self.y, 0].max
      end
    when 1
      EAGLE_COMMON.reset_sprite_oxy(self, HELP_TEXT_POS1_O)
      self.x = HELP_TEXT_POS1_X
      self.y = HELP_TEXT_POS1_Y
    when -9..-1
      EAGLE_COMMON.reset_sprite_oxy(self, HELP_TEXT_POS_1_O)
      EAGLE_COMMON.reset_xy_dorigin(self, nil, HELP_TEXT_POS)
    end
  end
end

#==============================================================================
# ■ 数据类
#==============================================================================
class Data_AbilityLearn
  attr_reader :ap, :ap_max
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(actor_id)
    @actor_id = actor_id
    @unlocks = [] # 已经解锁的token的id
    @ap = 0  # 当前能力点数目
    @ap_max = 0  # 全部能力点数目（用于重置）
    @skill_ids = []  # 已经解锁的技能的ID
    @param_plus = [0] * 8  # 8维属性的增量
    @weapon_ids = []  # 等价的武器
    @armor_ids = []  # 等价的护甲
  end
  #--------------------------------------------------------------------------
  # ● 增加ap
  #--------------------------------------------------------------------------
  def add_ap(v)
    return if v <= 0
    @ap += v
    @ap_max += v
  end
  #--------------------------------------------------------------------------
  # ● 重置
  #--------------------------------------------------------------------------
  def reset
    # 回复全部ap
    @ap = @ap_max
    # 清空已学技能
    @skill_ids.clear
    # 清空附加属性
    @param_plus = [0] * 8
    # 清空武器护甲
    @weapon_ids = []
    @armor_ids = []
    # 对每个已解锁的，进行额外处理
    @unlocks.each do |token_id|
      # 绑定开关
      sid = ABILITY_LEARN.get_token_sid(@actor_id, token_id)
      $game_switches[sid] = false if sid
      # 触发脚本
      str = ABILITY_LEARN.get_token_eval_off(@actor_id, token_id)
      ABILITY_LEARN.eagle_eval(str, @actor_id) if str
    end
    # 清空已解锁的数组
    @unlocks.clear
  end
  #--------------------------------------------------------------------------
  # ● 解锁指定id
  #--------------------------------------------------------------------------
  def unlock(token_id)
    # 如果是不需要解锁的，则跳过这些处理
    if !no_unlock?(token_id)
      # 放入已解锁的数组
      @unlocks.push(token_id)
      # 处理扩展的前置需求
      pres_ex = ABILITY_LEARN.get_token_pre_ex(@actor_id, token_id)
      pres_ex.each { |ps|
        ABILITY_LEARN.process_pre_ex(@actor_id, token_id, ps, :run) }
      # 扣除ap
      @ap -= ABILITY_LEARN.get_token_ap(@actor_id, token_id)
      # 习得技能
      skill_id = ABILITY_LEARN.get_token_skill(@actor_id, token_id)
      @skill_ids.push(skill_id) if skill_id && skill_id > 0
      # 增加属性
      hash = ABILITY_LEARN.get_token_params(@actor_id, token_id)
      hash.each do |sym, v|
        param_id = ABILITY_LEARN::PARAMS_TO_ID[sym]
        @param_plus[param_id] += v.to_i
      end
      # 增加武器护甲
      wid = ABILITY_LEARN.get_token_weapon(@actor_id, token_id)
      @weapon_ids.push(wid) if wid && wid > 0
      aid = ABILITY_LEARN.get_token_armor(@actor_id, token_id)
      @armor_ids.push(aid) if aid && aid > 0
      # 绑定开关
      sid = ABILITY_LEARN.get_token_sid(@actor_id, token_id)
      $game_switches[sid] = true if sid
    end
    # 触发脚本
    str = ABILITY_LEARN.get_token_eval_on(@actor_id, token_id)
    ABILITY_LEARN.eagle_eval(str, @actor_id) if str
  end
  #--------------------------------------------------------------------------
  # ● 指定id已经解锁？
  #--------------------------------------------------------------------------
  def unlock?(token_id)
    return true if no_unlock?(token_id)
    @unlocks.include?(token_id)
  end
  #--------------------------------------------------------------------------
  # ● 指定id能够解锁？
  #--------------------------------------------------------------------------
  def can_unlock?(token_id)
    if !unlock?(token_id)
      pres_all = ABILITY_LEARN.get_token_pre(@actor_id, token_id)
      pres = pres_all | pres_all
      pres.each { |id|
        return false if !unlock?(id)
        return false if level(id) < pres_all.count(id)
      }
      pres_ex = ABILITY_LEARN.get_token_pre_ex(@actor_id, token_id)
      pres_ex.each do |ps|
        f = ABILITY_LEARN.process_pre_ex(@actor_id, token_id, ps, :cond)
        return false if f == false
      end
    else
      f = leven_max(token_id)
      return false if f <= 0 or f <= level(token_id)
    end
    @ap >= ABILITY_LEARN.get_token_ap(@actor_id, token_id)
  end
  #--------------------------------------------------------------------------
  # ● 指定ID不需要解锁？
  #--------------------------------------------------------------------------
  def no_unlock?(token_id)
    ABILITY_LEARN.get_token_ap(@actor_id, token_id) == 0
  end
  #--------------------------------------------------------------------------
  # ● 指定ID能够重复学习的次数
  #--------------------------------------------------------------------------
  def leven_max(token_id)
    return 1 if no_unlock?(token_id)
    return ABILITY_LEARN.get_token_level(@actor_id, token_id)
  end
  #--------------------------------------------------------------------------
  # ● 获取学习次数
  #--------------------------------------------------------------------------
  def level(token_id)
    @unlocks.count(token_id)
  end
  #--------------------------------------------------------------------------
  # ● 获取已经学习的技能（技能ID的数组）
  #--------------------------------------------------------------------------
  def skills
    @skill_ids
  end
  #--------------------------------------------------------------------------
  # ● 获取等价的武器/护甲（装备ID的数组）
  #--------------------------------------------------------------------------
  def weapons
    @weapon_ids.collect { |e| $data_weapons[e] }
  end
  def armors
    @armor_ids.collect { |e| $data_armors[e] }
  end
  def equips
    weapons + armors
  end
  #--------------------------------------------------------------------------
  # ● 获取已经学习的附加属性
  #--------------------------------------------------------------------------
  def param_plus(param_id)
    @param_plus[param_id]
  end
  #--------------------------------------------------------------------------
  # ● 以数组方式获取拥有特性所有实例
  #--------------------------------------------------------------------------
  def feature_objects
    weapons + armors
  end
end

#==============================================================================
# ■ Game_Actor
#==============================================================================
class Game_Actor
  attr_reader :eagle_ability_data
  #--------------------------------------------------------------------------
  # ● 以数组方式获取拥有特性所有实例
  #--------------------------------------------------------------------------
  alias eagle_ability_learn_feature_objects feature_objects
  def feature_objects
    eagle_ability_learn_feature_objects + @eagle_ability_data.feature_objects
  end
  #--------------------------------------------------------------------------
  # ● 增加AP
  #--------------------------------------------------------------------------
  def add_ap(v)
    @eagle_ability_data.add_ap(v)
  end
  #--------------------------------------------------------------------------
  # ● 初始化技能
  #--------------------------------------------------------------------------
  alias eagle_ability_learn_init_skills init_skills
  def init_skills
    eagle_ability_learn_init_skills
    @eagle_ability_data = Data_AbilityLearn.new(@actor_id)
  end
  #--------------------------------------------------------------------------
  # ● 获取添加的技能
  #--------------------------------------------------------------------------
  def added_skills
    super | @eagle_ability_data.skills
  end
  #--------------------------------------------------------------------------
  # ● 获取普通能力的附加值
  #--------------------------------------------------------------------------
  alias eagle_ability_learn_param_plus param_plus
  def param_plus(param_id)
    v = eagle_ability_learn_param_plus(param_id)
    v += @eagle_ability_data.param_plus(param_id)
    v += @eagle_ability_data.equips.compact.inject(0) { |r, item|
      r += item.params[param_id] }
    v
  end
  #--------------------------------------------------------------------------
  # ● 等级上升
  #--------------------------------------------------------------------------
  alias eagle_ability_learn_level_up level_up
  def level_up
    eagle_ability_learn_level_up
    add_ap(ABILITY_LEARN::AP_LEVEL_UP)
  end
end

#==============================================================================
# ■ Game_Party
#==============================================================================
class Game_Party < Game_Unit
  #--------------------------------------------------------------------------
  # ● 增加AP
  #--------------------------------------------------------------------------
  def add_ap(v)
    members.each { |a| a.eagle_ability_data.add_ap(v) }
  end
end
