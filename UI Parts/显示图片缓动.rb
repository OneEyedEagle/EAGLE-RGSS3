#==============================================================================
# ■ 显示图片缓动 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# 【此插件兼容VX和VX Ace】
#==============================================================================
$imported ||= {}
$imported["EAGLE-PictureMoveEase"] = "1.0.0"
#==============================================================================
# - 2025.7.31.22 图片消除时，将同步清除缓动设置
#==============================================================================
# - 本插件新增了显示图片的缓动移动。
#
# - 对于地图上的显示图片：
#
#   1. 调用该方法启用1号图片的缓动移动：
#
#        $game_map.screen.pictures[1].ease = 1
#
#       ease 值所对应的缓动函数请自行在 picture_move_ease 方法中设置。
#
#   2. 调用该方法取消1号图片的缓动处理，使用默认的直线移动：
#
#        $game_map.screen.pictures[1].ease = nil
#
#   3. 若执行了事件指令-消除图片，则该缓动处理将同步清除。
#
#==============================================================================

#-----------------------------------------------------------------------------
# 【兼容VX】
#-----------------------------------------------------------------------------
MODE_VX = RUBY_VERSION[0..2] == "1.8"

module EAGLE 
  #--------------------------------------------------------------------------
  # ● 函数：图片移动使用的缓动函数
  #  x 为 当前移动计时 ÷ 总移动时间 的小数（0~1）
  #  返回为该时刻的 移动距离/总距离 的比值
  #  若直接返回 x，则为直线移动
  #-------------------------------------------------------------------------
  def self.picture_move_ease(type, x)
    # 自己编写 ease 值所对应的缓动函数
    case type
    when 0; return x  # 直线运动
    when 1; return x * x
    end
    # 利用【组件-缓动函数 by老鹰】
    if $imported["EAGLE-EasingFunction"]
      begin
        return EasingFuction.call(type, x)
      rescue
      end
    end
    # 如果都找不到，则用这个函数
    return 1 - 2**(-10 * x)
  end
end

class Game_Picture
  attr_accessor  :ease
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  alias eagle_ease_pic_initialize initialize
  def initialize(number)
    eagle_ease_pic_initialize(number)
    @ease = nil
    @ease_params = {}
  end
  #--------------------------------------------------------------------------
  # ● 移动图片
  #--------------------------------------------------------------------------
  alias eagle_ease_pic_move move
  def move(origin, x, y, zoom_x, zoom_y, opacity, blend_type, duration)
    eagle_ease_pic_move(origin, x, y, zoom_x, zoom_y, opacity, blend_type, duration)
    @ease_params[:x0] = @x; @ease_params[:dx] = x - @x
    @ease_params[:y0] = @y; @ease_params[:dy] = y - @y
    @ease_params[:zoom_x0] = @zoom_x; @ease_params[:dzoom_x] = zoom_x - @zoom_x
    @ease_params[:zoom_y0] = @zoom_y; @ease_params[:dzoom_y] = zoom_y - @zoom_y
    @ease_params[:opacity0] = @opacity; @ease_params[:dopacity] = opacity - @opacity
    @ease_params[:t] = duration
  end

if MODE_VX
  #--------------------------------------------------------------------------
  # ● 刷新画面
  #--------------------------------------------------------------------------
  def update
    update_move
    update_tone_change
    update_rotate
  end 
  #--------------------------------------------------------------------------
  # ● 更新图片移动
  #--------------------------------------------------------------------------
  def update_move
    if @duration >= 1
      d = @duration
      @x = (@x * (d - 1) + @target_x) / d
      @y = (@y * (d - 1) + @target_y) / d
      @zoom_x = (@zoom_x * (d - 1) + @target_zoom_x) / d
      @zoom_y = (@zoom_y * (d - 1) + @target_zoom_y) / d
      @opacity = (@opacity * (d - 1) + @target_opacity) / d
      @duration -= 1
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新色调更改
  #--------------------------------------------------------------------------
  def update_tone_change
    if @tone_duration >= 1
      d = @tone_duration
      @tone.red = (@tone.red * (d - 1) + @tone_target.red) / d
      @tone.green = (@tone.green * (d - 1) + @tone_target.green) / d
      @tone.blue = (@tone.blue * (d - 1) + @tone_target.blue) / d
      @tone.gray = (@tone.gray * (d - 1) + @tone_target.gray) / d
      @tone_duration -= 1
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新旋转
  #--------------------------------------------------------------------------
  def update_rotate
    if @rotate_speed != 0
      @angle += @rotate_speed / 2.0
      while @angle < 0
        @angle += 360
      end
      @angle %= 360
    end
  end
end

  #--------------------------------------------------------------------------
  # ● 更新图片移动
  #--------------------------------------------------------------------------
  alias eagle_ease_pic_update_move update_move
  def update_move
    return eagle_ease_pic_update_move if @ease == nil
    return if @duration == 0
    @duration -= 1
    per = (@ease_params[:t] - @duration) * 1.0 / @ease_params[:t]
    v = EAGLE.picture_move_ease(@ease, per)
    v = 1 if @duration == 0
    @x       = @ease_params[:x0] + @ease_params[:dx] * v
    @y       = @ease_params[:y0] + @ease_params[:dy] * v
    @zoom_x  = @ease_params[:zoom_x0] + @ease_params[:dzoom_x] * v
    @zoom_y  = @ease_params[:zoom_y0] + @ease_params[:dzoom_y] * v
    @opacity = @ease_params[:opacity0] + @ease_params[:dopacity] * v
  end
  #--------------------------------------------------------------------------
  # ● 消除图片
  #--------------------------------------------------------------------------
  alias eagle_ease_pic_erase erase
  def erase
    eagle_ease_pic_erase
    @ease = nil
    @ease_params = {}
  end
end
