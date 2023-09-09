#==============================================================================
# ■ 地图震动扩展 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# 【此插件兼容VX和VX Ace】
#==============================================================================
$imported ||= {}
$imported["EAGLE-MapShakeEX"] = "1.0.2"
#==============================================================================
# - 2022.6.8.19 
#==============================================================================
# - 在事件指令-地图震动中，只会进行左右晃动，本插件新增了扩展的地图震动指令
#--------------------------------------------------------------------------
# 【开关控制：地图震动】
#
# - 当设置的开关被开启时（默认设置 S_ID_SHAKE_Y = 1，即 1号开关），
#   默认的 事件指令-地图震动 将被更改为上下震动
#
#--------------------------------------------------------------------------
# 【事件脚本：地图震动】
#
# - 在事件脚本中，编写 map_shake(lx, ly, t, w, wait = false) 进行调用
#
#   其中 lx 为震动幅度（正整数），表示最大的左右方向向外移动的距离
#   其中 ly 为震动幅度（正整数），表示最大的上下方向向外移动的距离
#   其中 w 为每次震动后的等待帧数，可用于降低震动频率
#   其中 t 为震动持续帧数（正整数）
#   其中 wait 为是否等待震动结束，默认不等待
#
# - 示例：
#
#     map_shake(2, 2, 40)  → 震动幅度为 2，持续 40 帧，不等待结束
#
#     map_shake(1, 1, 30, 0, true)  → 震动幅度为 1，每次震动后不中断，
#                                     持续 30 帧，并直至结束才继续执行之后的指令
#
#==============================================================================

#=============================================================================
# ■ 常量
#=============================================================================
module EAGLE
  #--------------------------------------------------------------------------
  # ●【常量】该序号的开关开启时，将默认的震动由x方向更改为y方向
  #--------------------------------------------------------------------------
  S_ID_SHAKE_Y = 1
end
#--------------------------------------------------------------------------
# ●【常量】兼容
#--------------------------------------------------------------------------
MODE_VX = RUBY_VERSION[0..2] == "1.8"
MODE_VA = RUBY_VERSION[0..2] == "1.9"
#=============================================================================
# ■ Game_Map
#=============================================================================
class Game_Map
  attr_reader  :eagle_shake
  #--------------------------------------------------------------------------
  # ● 设置
  #--------------------------------------------------------------------------
  alias eagle_event_methods_ex_setup setup
  def setup(map_id)
    eagle_event_methods_ex_setup(map_id)
    @eagle_shake = {}
  end
  #--------------------------------------------------------------------------
  # ● 更新远景图
  #--------------------------------------------------------------------------
  alias eagle_event_methods_ex_update_parallax update_parallax
  def update_parallax
    eagle_event_methods_ex_update_parallax
    update_shake_ex
  end
  #--------------------------------------------------------------------------
  # ● 开启震动
  #--------------------------------------------------------------------------
  def start_shake_ex(lx, ly, t, w = 0)
    @eagle_shake[:lx] = lx.to_i  # 震动幅度
    @eagle_shake[:ly] = ly.to_i  # 震动幅度
    @eagle_shake[:t] = t.to_i  # 持续时间
    @eagle_shake[:w] = w.to_i  # 震动后的等待时间
    @eagle_shake[:delta] = 0.005   # 震动幅度修正参数（乘法）
    @eagle_shake[:active] = true
    @eagle_shake[:tc] = 0
    @eagle_shake[:wc] = 0
    @eagle_shake[:x] = @eagle_shake[:y] = 0
  end
  #--------------------------------------------------------------------------
  # ● 震动中？
  #--------------------------------------------------------------------------
  def shake_ex?
    @eagle_shake && @eagle_shake[:active] == true
  end
  #--------------------------------------------------------------------------
  # ● 更新震动
  #--------------------------------------------------------------------------
  def update_shake_ex
    return if !shake_ex?
    @eagle_shake[:tc] += 1
    if @eagle_shake[:wc] > 0
      @eagle_shake[:wc] -= 1
      return
    end
    if @eagle_shake[:lx] != 0
      _x = @eagle_shake[:delta] * (-1.0 + @eagle_shake[:lx] * rand())
      @eagle_shake[:x] = _x * Graphics.width
    end
    if @eagle_shake[:ly] != 0
      _y = @eagle_shake[:delta] * (-1.0 + @eagle_shake[:ly] * rand())
      @eagle_shake[:y] = _y * Graphics.height
    end
    @eagle_shake[:wc] = @eagle_shake[:w]
    @eagle_shake[:active] = false if @eagle_shake[:tc] > @eagle_shake[:t]
  end
end

#=============================================================================
# ■ Spriteset_Map
#=============================================================================
class Spriteset_Map
  #--------------------------------------------------------------------------
  # ● 更新显示端口
  #--------------------------------------------------------------------------
  alias eagle_event_methods_ex_update_viewports update_viewports
  def update_viewports
    eagle_event_methods_ex_update_viewports
    if $game_map.shake_ex?
      @viewport1.ox = $game_map.eagle_shake[:x]
      @viewport1.oy = $game_map.eagle_shake[:y]
      return
    end
    if $game_switches[EAGLE::S_ID_SHAKE_Y]
      @viewport1.ox = 0
      @viewport1.oy = $game_map.screen.shake
    else
      @viewport1.ox = $game_map.screen.shake
      @viewport1.oy = 0
    end
  end
end

#=============================================================================
# ■ Game_Interpreter
#=============================================================================
class Game_Interpreter
  def map_shake(lx, ly, t, w = 0, flag_wait = false)
    $game_map.start_shake_ex(lx, ly, t, w)
    if MODE_VX
      @wait_count = t if flag_wait
      return true
    end
    if MODE_VA
      Fiber.yield while $game_map.shake_ex? if flag_wait
    end
  end
end
