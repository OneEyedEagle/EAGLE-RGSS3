#==============================================================================
# ■ ROLL点 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
# - 2020.8.3.14
#==============================================================================
$imported ||= {}
$imported["EAGLE-Roll"] = true
#==============================================================================
# - 本插件新增了在事件中ROLL点的简易方法
#------------------------------------------------------------------------------
# 【使用】
#
#    在事件脚本中，利用 ROLL.run("formula", {params}) 来调用roll点方案，
#    并且该方法将返回roll点结果是数字。
#
# ○ 其中 formula 为roll点公式字符串：
#
#    用 {string} 的方式写入将会被 eval(string) 替换的字符串（最先进行）
#    用 ndm 的方式代表投掷 n 个 m面骰，同时也可以利用四则运算等脚本
#
#    可用 s 代表开关组，v 代表变量组，pl 代表 $game_player
#    可用 a 代表 $game_actors，m 代表 $game_party.members
#
#    如： "1d{v[1]+1}" 代表投 1 个 1号变量值+1 面骰
#    如： "1d100 + 10" 代表投 1 个100面骰，再+10作为结果
#    如： "2d8 + 1d{a[1].atk}" 代表投 2 个8面骰，再投 1 个1号角色攻击面骰
#
# ○ 其中 params 为参数设置的Hash（可省略）：
#
#    :rule → 直接调用指定预设规则
#          （首先用 :def 的预设，然后用 :rule所指定的预设覆盖，
#            最后用当前 params 中的设置覆盖）
#    :msg  → 是否开启对话框来显示投掷结果
#    :vid  → 将结果类型的符号存储到 :vid 所对应数字的变量中（仅存储）
#    :k    → 绑定一个值，用于进行 :r1 等的判定（首先会进行 eval）
#    :r1   → 指定 :r1 结果类型的判定字符串（具体见 RESULT_TYPE 中的key值）
#
#    如：{ :rule => 0 } 代表调用预设的 0 号规则
#    如：{ :k => "(a[1].atk+a[1].mat)/2" } 代表利用默认规则，
#                       基于 1 号角色的攻击与魔法攻击的均值进行结果判定
#
# ○ 调用示例
#
# - 投 1 个80面骰，再+5作为结果，其中结果类型存入了 V_ID 号变量
#
#    事件脚本：ROLL.run( "1d80 + 5" )
#    选项：（大成功），（成功），（失败）（大失败）
#
#   若结果为 大成功（:r1的条件返回true），则执行选项 （大成功） 中的内容
#   若结果为 失败（:r3的条件返回true），则执行选项 （失败）（大失败） 中的内容
#
# - 投 1 个100面骰，与1号角色的luk比较，并获得结果，其中结果类型存入了 V_ID 号变量
#   同时还将投掷结果的数字存入了 1 号变量
#
#    事件脚本：$game_variables[1] = ROLL.run( "1d100", {:k => "a[1].luk"} )
#    选项：（大成功）（成功），（失败）（大失败）
#
#   若结果为 成功（:r2的条件返回true），则执行选项 （大成功）（成功） 中的内容
#   若结果为 失败（:r3的条件返回true），则执行选项 （失败）（大失败） 中的内容
#
#------------------------------------------------------------------------------
# 【选项分歧】
#
# - 当 V_ID 号变量的值为结果符号时，下一次调用的选项，将首先被作为roll点结果分歧
#
# - 按照 RESULT_TYPE 中预设的 结果符号 到 选项内容 的映射，依次检索各个选项，
#
#   比如 roll 点结果为 :r2 时，将会在选项中检索包含 RESULT_TYPE[:r2] 字符串的选项
#    即检索包含 （成功） 字样的选项，并跳过选择处理，直接触发该选项内容
#
# - 若未找到，则依然按照一般选项进行处理
#
# - 无论检索成功失败，都会将 V_ID 号变量的值重置为 0，确保之后的选项能正确执行
#
#==============================================================================
module ROLL
  #--------------------------------------------------------------------------
  # ● 【常量】存储ROLL点结果符号的变量的ID
  #  若该ID号变量的值为 Symbol 符号，就会将下一个选项指令替换成ROLL点结果判定
  #--------------------------------------------------------------------------
  V_ID = 10
  #--------------------------------------------------------------------------
  # ● 【常量】定义ROLL点的结果类型，及其对应的在选项文本中的字符串
  #--------------------------------------------------------------------------
  RESULT_TYPE = {
    :r1 => "（大成功）",
    :r2 => "（成功）",
    :r3 => "（失败）",
    :r4 => "（大失败）",
    :out_of_range => "（超出范围！）",
  }
  #--------------------------------------------------------------------------
  # ● 【常量】定义结果判定规则
  #  其中 k 为额外引入的一个值，r 为roll点结果的数字
  #--------------------------------------------------------------------------
  RULES = {}
  # 设置默认规则
  RULES[:def] = {
    # 是否开启对话框以显示结果
    :msg => true,
    # 额外绑定的数值公式
    :k => 50,
    # 额外的存储结果类型的变量的ID
    :vid => 10,
    # 各个结果的判定公式
    :r1 => "r > 0 && r <= 5",
    :r2 => "r > 5 && r <= k",
    :r3 => "r > k && r <= 95",
    :r4 => "r > 95 && r <= 100",
  }

  # 设置自定义规则
  RULES[0] = {
    :r1 => "r == 1",
    :r2 => "r > 1 && r <= k",
    :r3 => "r > k && r <= 99",
    :r4 => "r == 100",
  }

  #--------------------------------------------------------------------------
  # ● 执行roll点
  #--------------------------------------------------------------------------
  def self.run(text = "", params = {})
    params = init_rule(params)
    parse_params(text, params)
    $game_variables[V_ID] = check_result(params)
    $game_variables[params[:vid]] = $game_variables[V_ID] if params[:vid]
    call_msg(params) if params[:msg] == true
    params[:sum]
  end

  #--------------------------------------------------------------------------
  # ● 呼叫对话框显示roll点结果
  #--------------------------------------------------------------------------
  def self.call_msg(params)
    f = SceneManager.scene.message_window rescue nil
    return if f.nil?
    wait_for_message
    $game_message.face_name = ""
    $game_message.background = 0
    $game_message.position = 2

    t = ""
    if $imported["EAGLE-MessageEX"]
      t += "\\win[fw1fh1o2do-2dy-120]\\temp"
    end
    t += params[:t2]
    $game_message.add(t)

    t = ""
    if $imported["EAGLE-MessageEX"]
      i = -1
      t = " = " + params[:t4].gsub(/(\d{1,})/) {
        i += 1
        maxv = params[:v][i][0] # max v string
        rv = params[:v][i][2]
        if params[:v][i][1]
          rv_str = sprintf("%0#{maxv.size}d", rv)
          "\\set[1]\\ctog[i1t4]" + rv_str + "\\ctog[0]\\set[0]"
        else
          "#{rv}"
        end
      }
      t += "\\|\\setm[1|ctog|0]"
    else
      t = " = " + params[:t4].gsub(/(\d{1,})/) { "\\.\\c[1]" + $1 + "\\c[0]" }
    end
    $game_message.add(t)

    t = " = " + "\\c[17]" + params[:sum].to_s + "\\c[0]"
    t = t + " \\c[1][" + params[:kv].to_s + "]\\c[0]"
    t = t + "\\c[17]" + RESULT_TYPE[$game_variables[V_ID]] + "\\c[0]"
    $game_message.add(t)

    wait_for_message
  end
  #--------------------------------------------------------------------------
  # ● 基础更新
  #--------------------------------------------------------------------------
  def self.wait_for_message
    while $game_message.busy?
      SceneManager.scene.update_basic
    end
  end

#===============================================================================
# ○ 处理
#===============================================================================
class << self
  #--------------------------------------------------------------------------
  # ● 初始化规则
  #--------------------------------------------------------------------------
  def init_rule(params)
    h = RULES[params[:rule]] rescue nil
    h ||= {}
    h = RULES[:def].merge(h)
    return h.merge(params)
  end
  #--------------------------------------------------------------------------
  # ● 分析公式
  #--------------------------------------------------------------------------
  def parse_params(text, tmp = {})
    # 原始文本
    tmp[:t1] = text
    # 替换了 {} 后的文本
    tmp[:t2] = tmp[:t1].dup
    tmp[:t2].gsub!( /\{(.*?)\}/ ) { eval_str($1) }
    # 拆分了 nd数字 中的 n 后的文本
    tmp[:t3] = tmp[:t2].dup
    tmp[:t3].gsub!( /(\d+)[d\D](\d+)/ ) {
      t_ = []
      $1.to_i.times { t_.push( "d" + $2 ) }
      t_.inject { |s, t__| s = s + " + " + t__ }
    }
    # 将 d数字 替换成了实际数字
    tmp[:v] = []
    tmp[:t4] = tmp[:t3].dup
    tmp[:t4].gsub!( /(d?)(\d+)/ ) {
      vroll = $1 == "d" ? true : false
      vmax = $2
      vresult = 0
      if vroll
        vresult = rand( vmax.to_i ) + 1
      else
        vresult = vmax.to_i
      end
      # 按顺序存入数字 [最大值, 是否为roll值, 最终结果]
      tmp[:v].push( [vmax, vroll, vresult] )
      vresult.to_s
    }
    # 计算实际结果
    tmp[:sum] = eval( tmp[:t4] )
  end
  #--------------------------------------------------------------------------
  # ● 执行字符串
  #--------------------------------------------------------------------------
  def eval_str(str)
    s = $game_switches; v = $game_variables
    pl = $game_player; a = $game_actors; m = $game_party.members
    eval(str)
  end
  #--------------------------------------------------------------------------
  # ● 判定结果
  #--------------------------------------------------------------------------
  def check_result(params)
    r = nil
    RESULT_TYPE.each do |sym, text|
      next if params[sym] == nil
      break r = sym if eval_str_result(params[sym], params) == true
    end
    r ||= :out_of_range
    params[:r] = r
    params[:r]
  end
  #--------------------------------------------------------------------------
  # ● 执行字符串
  #--------------------------------------------------------------------------
  def eval_str_result(str, params)
    s = $game_switches; v = $game_variables
    pl = $game_player; a = $game_actors; m = $game_party.members
    r = params[:sum]; k = eval(params[:k].to_s).to_i
    params[:kv] = k
    eval(str)
  end
end # end of class
end # end of module
#===============================================================================
# ○ Game_Interpreter
#===============================================================================
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 显示选项
  #--------------------------------------------------------------------------
  alias eagle_roll_command_102 command_102
  def command_102
    return if $game_variables[ROLL::V_ID].is_a?(Symbol) && command_102_roll
    eagle_roll_command_102
  end
  #--------------------------------------------------------------------------
  # ● 处理roll点结果
  #--------------------------------------------------------------------------
  def command_102_roll
    t = $game_variables[ROLL::V_ID]
    r = ROLL::RESULT_TYPE[t]
    r_i = -1
    @params[0].each_with_index {|s, i|
      break r_i = i if s =~ /#{r}/
    }
    if r_i >= 0
      @branch[@indent] = r_i
      $game_variables[ROLL::V_ID] = 0
      return true
    end
    return false
  end
end
