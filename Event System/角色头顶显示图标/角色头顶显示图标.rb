#==============================================================================
# ■ 角色头顶显示图标 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# 【此插件兼容VX和VX Ace】
#==============================================================================
$imported ||= {}
$imported["EAGLE-EventPopIcon"] = "1.3.0"
#==============================================================================
# - 2023.11.27.231 新增脚本内预设
#==============================================================================
# - 本插件新增了在地图上角色头顶显示指定图标的功能（仿气泡）
#--------------------------------------------------------------------------
# - 在 RGSS3 中，可以给 Game_CharacterBase类的 @balloon_id 变量赋值，
#   用于在地图角色的头顶显示动态气泡
#
# - 类似的，本插件为 Game_Character类新增了 @pop_icon 变量，
#     为其赋值能在一段时间内，在角色头顶显示图标
#
# - 同时，也新增了 @pop_icon_params 的Hash类型变量，用来存储参数
#
#   有效参数一览：
#
#     :def => 文本 → 应用脚本中预设的参数组，然后再用当前设置自定义。
#
#     :pos => 数字 → 数字为 0 时（默认值），图标显示在行走图上方
#                     数字为 1 时，图标显示在行走图下方
#                     数字为 2 时，图标显示在行走图中央
#
#     :type => 数字 → 设置移动的类型
#                     当数字为 1 时（默认值），将浮动显示，依据 :dir 决定运动方向
#                     当数字为 2 时，将震动显示，震动幅度为 :l 的值
#                     当数字为 3 时，将弹跳显示
#
#     :dir => 数字 → （:type 值为 1 时生效）数字为 2 时，图标先下移，再上移
#                     数字为 4 时，图标先左移，再右移
#                     数字为 6 时，图标先右移，再左移
#                     数字为 8 时（默认值），图标先上移，再下移
#
#     :l => 数字 → （:type 值为 2 时生效）该项用于设置震动幅度
#                    数字越大，则震动越强烈，越偏移初始位置
#
#     :opa => 数字 → 数字为 0 时（默认值），关闭显隐特效；为 1 时，开启显隐
#
#     :dx => 数字, :dy => 数字  → 坐标的增加偏移值
#
# - 示例：
#    $game_player.pop_icon = 1
#      → 在玩家头顶显示 1 号图标，持续 MAX_POP_FRAME 帧
#    $game_player.pop_icon_params[:pos] = 1
#      → 将显示的图标位置修改为玩家下方
#
# - 若 @pop_icon 设置为 0，则会立即消除图标
#
#==============================================================================
module POP_ICON
  #--------------------------------------------------------------------------
  # ●【常量】预设的设置组
  #--------------------------------------------------------------------------
  DEFAULT = {
    "默认" => { :icon => 0, :pos => 0, :dx => 0, :dy => 0,
      :type => 1, :dir => 8, :l => 2, :opa => 0 },
    # 编写 def=调查 就会应用这里的设置，再改为额外写的新设置 
    "调查" => { :icon => 4, :type => 1, :dir => 8 },
  }
end
module POP_ICON
  #--------------------------------------------------------------------------
  # ● 【常量】当该序号的开关开启时，不显示图标
  #--------------------------------------------------------------------------
  S_ID_NO_POP = 0
  #--------------------------------------------------------------------------
  # ● 【常量】一次激活后，最长的显示帧数
  #  若设置为 nil，则图标不会自动消失
  #--------------------------------------------------------------------------
  MAX_SHOW_FRAME = 10
  #--------------------------------------------------------------------------
  # ● 【常量】在 draw_pop_icon 方法中的最大循环帧数
  #  用于设置完整的移动流程，可以大于 MAX_SHOW_FRAME，来制作更完备的动态效果
  #--------------------------------------------------------------------------
  MAX_LOOP_FRAME = 60
  #--------------------------------------------------------------------------
  # ● 按照当前循环的帧序号进行重绘（每帧调用该方法）
  #  frame 的取值为 0 ~ MAX_LOOP_FRAME-1
  #--------------------------------------------------------------------------
  def self.draw_pop_icon(sprite_chara, sprite_icon, icon_id, frame, ps)
    # 在第一帧，新建位图并绘制图标
    if frame == 0
      sprite_icon.visible = true
      sprite_icon.bitmap ||= Bitmap.new(24, 24)
      sprite_icon.bitmap.clear
      draw_icon(sprite_icon.bitmap, icon_id, 0, 0)
      sprite_icon.opacity = 255

      # 依据放置位置，设置原点
      case ps[:pos]
      when 0 # （默认）放置于事件头顶，显示原点为图标的顶部中点
        sprite_icon.ox = sprite_icon.width / 2
        sprite_icon.oy = sprite_icon.height
      when 1 # 放置于事件脚底，显示原点为图标的底部中点
        sprite_icon.ox = sprite_icon.width / 2
        sprite_icon.oy = 0
      when 2 # 放置于事件中心
        sprite_icon.ox = sprite_icon.width / 2
        sprite_icon.oy = sprite_icon.height / 2
      end
    end

    # 定下基础位置，之后根据帧数计算出xy的偏移值
    sprite_icon.x = sprite_chara.x
    sprite_icon.y = sprite_chara.y - sprite_chara.height
    sprite_icon.z = sprite_chara.z + 200
    # 变更基础位置
    case ps[:pos]
    when 0
    when 1
      sprite_icon.y = sprite_chara.y
    when 2
      sprite_icon.y = sprite_chara.y - sprite_icon.height / 2
    end

    if ps[:type] == 1
    case ps[:dir]
    when 2 # 先下移，再上移
      case frame
      when 1..29
        sprite_icon.y += (frame/4)
      when 30..59
        sprite_icon.y += ((29-(frame-29))/4)
      end
    when 4 # 先左移，再右移
      case frame
      when 1..29
        sprite_icon.x -= (frame/4)
      when 30..59
        sprite_icon.x -= ((29-(frame-29))/4)
      end
    when 6 # 先右移，再左移
      case frame
      when 1..29
        sprite_icon.x += (frame/4)
      when 30..59
        sprite_icon.x += ((29-(frame-29))/4)
      end
    when 8 # 先上移，再下移
      case frame
      when 1..29
        sprite_icon.y -= (frame/4)
      when 30..59
        sprite_icon.y -= ((29-(frame-29))/4)
      end
    end

    elsif ps[:type] == 2
      sprite_icon.x += (-1.0 + ps[:l] * rand()) * 2
      sprite_icon.y += (-1.0 + ps[:l] * rand()) * 2

    elsif ps[:type] == 3
      case frame
      when 1..40
        dy = 12 - (frame - 20) ** 2 * 0.03
        sprite_icon.y -= dy
      when 41..59
      end
    end

    if ps[:opa].to_i == 1
      case frame  # 显隐切换
      when 1..29
        sprite_icon.opacity -= 6
      when 30..59
        sprite_icon.opacity += 6
      end
    end

    # 最后，再增加偏移
    sprite_icon.x += ps[:dx].to_i if ps[:dx]
    sprite_icon.y += ps[:dy].to_i if ps[:dy]
  end
  #--------------------------------------------------------------------------
  # ● 绘制图标
  #     enabled : 有效的标志。false 的时候使用半透明效果绘制
  #--------------------------------------------------------------------------
  def self.draw_icon(bitmap, icon_index, x, y, enabled = true)
    bitmap_ = Cache.system("Iconset")
    rect = Rect.new(icon_index % 16 * 24, icon_index / 16 * 24, 24, 24)
    bitmap.blt(x, y, bitmap_, rect, enabled ? 255 : 120)
  end
  #--------------------------------------------------------------------------
  # ● 应用预设
  #--------------------------------------------------------------------------
  def self.apply_default(id, ps)
    ps_ = DEFAULT[id]
    return ps if ps_ == nil
    return ps_.merge(ps)
  end
end

#==============================================================================
# ■ 兼容VX
#==============================================================================
if RUBY_VERSION[0..2] == "1.8"
#=============================================================================
# ○ Game_Character
#=============================================================================
class Game_Character
  #--------------------------------------------------------------------------
  # ● 初始化对像
  #--------------------------------------------------------------------------
  alias eagle_popicon_init initialize
  def initialize
    reset_popicon_params
    eagle_popicon_init
  end
  def init_public_members
  end
end
end

#=============================================================================
# ○ Game_Character
#=============================================================================
class Game_Character
  attr_accessor :pop_icon, :pop_icon_params
  #--------------------------------------------------------------------------
  # ● 初始化公有成员变量
  #--------------------------------------------------------------------------
  alias eagle_popicon_init_public_members init_public_members
  def init_public_members
    reset_popicon_params
    eagle_popicon_init_public_members
  end
  #--------------------------------------------------------------------------
  # ● 重置参数
  #--------------------------------------------------------------------------
  def reset_popicon_params
    @pop_icon = 0
    @pop_icon_params = { :pos => 0, :dx => 0, :dy => 0,
      :type => 1, :dir => 8, :l => 2, :opa => 0 }
  end
  #--------------------------------------------------------------------------
  # ● 处理参数，确保参数存在，类型正确
  #--------------------------------------------------------------------------
  def get_popicon_params
    @pop_icon_params[:pos] = @pop_icon_params[:pos].to_i
    @pop_icon_params[:type] = @pop_icon_params[:type].to_i
    @pop_icon_params[:dir] = @pop_icon_params[:dir].to_i
    @pop_icon_params[:l] = @pop_icon_params[:l].to_i
    return @pop_icon_params
  end
end
#=============================================================================
# ○ Sprite_Character
#=============================================================================
class Sprite_Character < Sprite_Base
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  alias eagle_popicon_dispose dispose
  def dispose
    eagle_popicon_dispose
    if @popicon_sprite
      @popicon_sprite.bitmap.dispose if @popicon_sprite.bitmap
      @popicon_sprite.dispose
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新画面
  #--------------------------------------------------------------------------
  alias eagle_popicon_update update
  def update
    eagle_popicon_update
    update_popicon
  end
  #--------------------------------------------------------------------------
  # ● 更新图标pop
  #--------------------------------------------------------------------------
  def update_popicon
    if $game_switches[POP_ICON::S_ID_NO_POP]
      end_popicon if @pop_icon != 0
      return
    end
    reset_popicon if @popicon_sprite.nil?
    if @character.pop_icon > 0
      if @character.pop_icon == @pop_icon # 若与当前显示一致，则继续显示
        @popicon_count = @popicon_count % POP_ICON::MAX_LOOP_FRAME
        @popicon_last_activate = @popicon_count
        @character.pop_icon = -1
      else
        reset_popicon
      end
    else
      return end_popicon if @character.pop_icon == 0
    end
    if @pop_icon > 0
      if @popicon_count - @popicon_last_activate > POP_ICON::MAX_SHOW_FRAME
        return end_popicon
      end
      c = @popicon_count % POP_ICON::MAX_LOOP_FRAME
      ps = @character.get_popicon_params
      # 应用预设
      ps = POP_ICON.apply_default(ps[:def], ps) if ps[:def]
      @character.pop_icon = @pop_icon = ps[:icon].to_i if ps[:icon].to_i > 0
      ps[:icon] = 0  # 应用后，要把icon置零，防止一直重复刷新和显示
      POP_ICON.draw_pop_icon(self, @popicon_sprite, @pop_icon, c, ps)
      @popicon_sprite.update
      @popicon_count += 1
    end
  end
  #--------------------------------------------------------------------------
  # ● 重置图标pop
  #--------------------------------------------------------------------------
  def reset_popicon
    @pop_icon = @character.pop_icon 
    @character.pop_icon = -1 # 在显示中，置为-1
    @popicon_sprite ||= Sprite.new(viewport)
    @popicon_count = 0
    @popicon_last_activate = 0  # 上一次激活icon时的计数帧
  end
  #--------------------------------------------------------------------------
  # ● 释放图标pop
  #--------------------------------------------------------------------------
  def end_popicon
    @popicon_sprite.visible = false if @popicon_sprite
    @pop_icon = 0
    @character.pop_icon = 0
  end
end
