#==============================================================================
# ■ 角色头顶显示图标 by 老鹰 (EAGLE-RGSS3)
#   兼容 RGSS2 (VX) 与 RGSS3 (VX Ace)
#==============================================================================
<<<<<<< Updated upstream
# 版本：1.3.0
# 更新：2026.2.11 利用DeepSeek优化代码
=======
# 【版本】1.3.0
# 【更新】2026.2.11 利用DeepSeek优化代码
>>>>>>> Stashed changes
#==============================================================================
# 功能：
#   为地图上的角色（玩家、事件）添加头顶图标显示功能，支持多种动画与位置设置。
#
# 原理：
#   在 Game_Character 类中增加 @pop_icon 与 @pop_icon_params 变量。
#   通过 Sprite_Character 的精灵扩展来绘制图标动画。
#
# 使用方法：
#   1. 设置图标： $game_player.pop_icon = 图标ID
#   2. 设置参数： $game_player.pop_icon_params[:pos] = 0（位置）
#   3. 预设参数： 在 POP_ICON::DEFAULT 中定义，通过 :def 键引用
#   4. 立即消除： $game_player.pop_icon = 0
#
# 参数说明（pop_icon_params 哈希键）：
#   :def  - 字符串，引用 DEFAULT 中的预设组名
#   :pos  - 0:头顶(默认) 1:脚下 2:中心
#   :type - 1:浮动(默认) 2:震动 3:弹跳
#   :dir  - type=1时有效，2:下→上 4:左→右 6:右→左 8:上→下(默认)
#   :l    - type=2时有效，震动幅度
#   :opa  - 0:无显隐(默认) 1:渐隐渐现
#   :dx, :dy - 坐标额外偏移
#==============================================================================

$imported ||= {}
$imported["EAGLE-EventPopIcon"] = "1.3.0"

#==============================================================================
# ■ 模块 POP_ICON
#   存放所有常量、预设及核心绘图逻辑
#==============================================================================
module POP_ICON
  #--------------------------------------------------------------------------
  # ● 常量：图标显示相关
  #--------------------------------------------------------------------------
  # 图标尺寸（原版RGSS图标集为24x24）
  ICON_SIZE = 24
  # 图标不启用时的透明度（120为半透明）
  ICON_OPACITY_DISABLED = 120
  # 当该序号开关开启时，强制不显示任何图标（0表示不启用此功能）
  SWITCH_NO_POP = 0
  # 图标自动消失的帧数（nil表示永不消失）
  MAX_SHOW_FRAME = 10
  # 完整动画循环的总帧数（用于周期运动）
  MAX_LOOP_FRAME = 60

  #--------------------------------------------------------------------------
  # ● 预设参数组
  #   格式： "名称" => { 键 => 值, ... }
  #   通过 pop_icon_params[:def] = "名称" 来应用
  #--------------------------------------------------------------------------
  DEFAULT = {
    "默认" => {
      :icon => 0, :pos => 0, :dx => 0, :dy => 0,
      :type => 1, :dir => 8, :l => 2, :opa => 0
    },
    'look' => {
      :icon => 16, :type => 1, :dy => 30, :pos => 0, :opa => 0
    },
    # 可在此继续添加更多预设...
  }

  #--------------------------------------------------------------------------
  # ● 应用预设
  #   将命名预设中的参数合并到当前参数哈希中，并返回
  #--------------------------------------------------------------------------
  def self.apply_default(preset_name, params)
    preset = DEFAULT[preset_name]
    return params if preset.nil?
    params.merge(preset)
  end

  #--------------------------------------------------------------------------
  # ● 绘制图标到精灵
  #   从系统图标集（Iconset）中截取对应图标
  #--------------------------------------------------------------------------
  def self.draw_icon(bitmap, icon_index, x, y, enabled = true)
    iconset = Cache.system("Iconset")
    rect = Rect.new(
      icon_index % 16 * ICON_SIZE,
      icon_index / 16 * ICON_SIZE,
      ICON_SIZE,
      ICON_SIZE
    )
    opacity = enabled ? 255 : ICON_OPACITY_DISABLED
    bitmap.blt(x, y, iconset, rect, opacity)
  end

  #--------------------------------------------------------------------------
  # ● 更新图标精灵的每帧状态
  #   根据当前帧序号 frame 和参数 ps 计算位置、透明度等
  #--------------------------------------------------------------------------
  def self.update_icon_sprite(char_sprite, icon_sprite, icon_id, frame, params)
    # 第一帧初始化位图与原点
    if frame == 0
      icon_sprite.visible = true
      icon_sprite.bitmap ||= Bitmap.new(ICON_SIZE, ICON_SIZE)
      icon_sprite.bitmap.clear
      draw_icon(icon_sprite.bitmap, icon_id, 0, 0)
      icon_sprite.opacity = 255

      # 根据位置类型设定原点（ox, oy）
      case params[:pos]
      when 0 # 头顶 -> 原点为底部中点
        icon_sprite.ox = icon_sprite.width / 2
        icon_sprite.oy = icon_sprite.height
      when 1 # 脚下 -> 原点为顶部中点
        icon_sprite.ox = icon_sprite.width / 2
        icon_sprite.oy = 0
      when 2 # 中心 -> 原点为图片中心
        icon_sprite.ox = icon_sprite.width / 2
        icon_sprite.oy = icon_sprite.height / 2
      end
    end

    # 基础位置：角色精灵的位置，并依据位置类型调整 y 坐标
    icon_sprite.x = char_sprite.x
    icon_sprite.y = char_sprite.y
    icon_sprite.z = char_sprite.z + 200

    case params[:pos]
    when 0
      icon_sprite.y -= char_sprite.height
    when 1
      # 脚下：无需额外调整（已在原点设置中处理）
    when 2
      icon_sprite.y -= char_sprite.height / 2
    end

    # 应用动画效果（偏移计算）
    offset_x = 0
    offset_y = 0

    case params[:type]
    when 1 # 浮动动画
      offset_x, offset_y = _offset_type1(frame, params[:dir])
    when 2 # 震动动画
      offset_x, offset_y = _offset_type2(params[:l])
    when 3 # 弹跳动画
      offset_x, offset_y = _offset_type3(frame)
    when 4 # 放缩动画
      offset_x, offset_y = _offset_type4(frame, icon_sprite)
    end

    icon_sprite.x += offset_x
    icon_sprite.y += offset_y

    # 透明度渐变效果
    if params[:opa].to_i == 1
      case frame
      when 1..29  then icon_sprite.opacity -= 6
      when 30..59 then icon_sprite.opacity += 6
      end
    end

    # 额外偏移修正
    icon_sprite.x += params[:dx].to_i if params[:dx]
    icon_sprite.y += params[:dy].to_i if params[:dy]
  end

  #--------------------------------------------------------------------------
  # ● 私有：浮动动画偏移计算
  #   dir : 2下 4左 6右 8上（默认）
  #--------------------------------------------------------------------------
  def self._offset_type1(frame, dir)
    dx = 0; dy = 0
    case dir
    when 2  # 先下后上
      case frame
      when 1..29  then dy =  (frame / 4)
      when 30..59 then dy =  ((29 - (frame - 29)) / 4)
      end
    when 4  # 先左后右
      case frame
      when 1..29  then dx = -(frame / 4)
      when 30..59 then dx = -((29 - (frame - 29)) / 4)
      end
    when 6  # 先右后左
      case frame
      when 1..29  then dx =  (frame / 4)
      when 30..59 then dx =  ((29 - (frame - 29)) / 4)
      end
    when 8  # 先上后下（默认）
      case frame
      when 1..29  then dy = -(frame / 4)
      when 30..59 then dy = -((29 - (frame - 29)) / 4)
      end
    end
    return dx, dy
  end

  #--------------------------------------------------------------------------
  # ● 私有：震动动画偏移计算
  #   l : 震动幅度
  #--------------------------------------------------------------------------
  def self._offset_type2(l)
    dx = (-1.0 + l * rand()) * 2
    dy = (-1.0 + l * rand()) * 2
    return dx, dy
  end

  #--------------------------------------------------------------------------
  # ● 私有：弹跳动画偏移计算
  #--------------------------------------------------------------------------
  def self._offset_type3(frame)
    dy = 0
    case frame
    when 1..40
      dy = 12 - (frame - 20) ** 2 * 0.03
      dy = -dy  # 向上弹起
    end
    return 0, dy
  end
  
  #--------------------------------------------------------------------------
  # ● 私有：放缩动画偏移计算
  #--------------------------------------------------------------------------
  def self._offset_type4(frame, icon_sprite)
    dzoom = 0.4  # 放大的最大值（1.0 为 100%）
    case frame
    when 1..29
      t = frame * 1.0 / 30
      v = EasingFuction.call("easeOutBack", t)
      icon_sprite.zoom_x = icon_sprite.zoom_y = 1.0 + dzoom * v
    when 30..59
      t = (frame - 29) * 1.0 / 30
      v = EasingFuction.call("easeInOutQuint", t)
      icon_sprite.zoom_x = icon_sprite.zoom_y = 1.0 + dzoom - dzoom * v
    end
    return 0, 0
  end
  
  private_class_method :_offset_type1, :_offset_type2
  private_class_method :_offset_type3, :_offset_type4
end

#==============================================================================
# ■ 兼容性：VX (RGSS2) 中的 Game_Character 没有 init_public_members 方法
#==============================================================================
if RUBY_VERSION[0..2] == "1.8"
  class Game_Character
    alias eagle_popicon_init initialize
    def initialize
      reset_popicon_params
      eagle_popicon_init
    end
    # VX 需要模拟该方法
    def init_public_members
    end
  end
end

#==============================================================================
# ■ Game_Character
#   添加头顶图标所需的变量与方法
#==============================================================================
class Game_Character
  #--------------------------------------------------------------------------
  # ● 公有实例变量
  #   @pop_icon        - 当前要显示的图标ID（0 表示不显示）
  #   @pop_icon_params - 图标显示参数哈希
  #--------------------------------------------------------------------------
  attr_accessor :pop_icon, :pop_icon_params

  #--------------------------------------------------------------------------
  # ● 初始化公有成员（RGSS3）
  #   在 init_public_members 中重置参数
  #--------------------------------------------------------------------------
  alias eagle_popicon_init_public_members init_public_members
  def init_public_members
    reset_popicon_params
    eagle_popicon_init_public_members
  end

  #--------------------------------------------------------------------------
  # ● 重置图标参数为默认值
  #--------------------------------------------------------------------------
  def reset_popicon_params
    @pop_icon = 0
    @pop_icon_params = {
      :pos  => 0,
      :dx   => 0,
      :dy   => 0,
      :type => 1,
      :dir  => 8,
      :l    => 2,
      :opa  => 0
    }
  end

  #--------------------------------------------------------------------------
  # ● 获取并规范化参数
  #   确保所有必要键存在且为整数类型
  #--------------------------------------------------------------------------
  def normalized_popicon_params
    @pop_icon_params[:pos]  = @pop_icon_params[:pos].to_i
    @pop_icon_params[:type] = @pop_icon_params[:type].to_i
    @pop_icon_params[:dir]  = @pop_icon_params[:dir].to_i
    @pop_icon_params[:l]    = @pop_icon_params[:l].to_i
    @pop_icon_params
  end
end

#==============================================================================
# ■ Sprite_Character
#   扩展角色精灵，管理头顶图标的显示与动画
#==============================================================================
class Sprite_Character < Sprite_Base
  #--------------------------------------------------------------------------
  # ● 释放
  #   同时释放图标精灵及其位图
  #--------------------------------------------------------------------------
  alias eagle_popicon_dispose dispose
  def dispose
    eagle_popicon_dispose
    if @popicon_sprite
      @popicon_sprite.bitmap.dispose if @popicon_sprite.bitmap
      @popicon_sprite.dispose
      @popicon_sprite = nil
    end
  end

  #--------------------------------------------------------------------------
  # ● 更新画面
  #   调用原有更新后处理头顶图标
  #--------------------------------------------------------------------------
  alias eagle_popicon_update update
  def update
    eagle_popicon_update
    update_popicon
  end

  #--------------------------------------------------------------------------
  # ● 更新头顶图标（主逻辑）
  #--------------------------------------------------------------------------
  def update_popicon
    # 开关控制：若指定开关开启，强制消除图标
    if $game_switches[POP_ICON::SWITCH_NO_POP]
      end_popicon if @pop_icon != 0
      return
    end

    # 第一次使用时创建图标精灵
    reset_popicon if @popicon_sprite.nil?

    # 处理角色传来的新图标请求
    handle_new_icon_request

    # 如果当前没有激活的图标，退出
    return if @pop_icon <= 0

    # 自动消失计时检查
    if @popicon_count - @popicon_last_activate > POP_ICON::MAX_SHOW_FRAME
      end_popicon
      return
    end

    # 计算当前动画帧
    frame = @popicon_count % POP_ICON::MAX_LOOP_FRAME
    params = @character.normalized_popicon_params

    # 应用预设（如果指定了 :def 键）
    if params[:def]
      params = POP_ICON.apply_default(params[:def], params)
      @character.pop_icon_params = params
      # 若预设中指定了新的图标ID，则更新当前图标
      if params[:icon].to_i > 0
        @character.pop_icon = @pop_icon = params[:icon].to_i
      end
      # 清除 :def 键，防止后续重复应用
      params.delete(:def)
      @character.pop_icon_params.delete(:def)
    end

    # 调用模块方法更新图标精灵
    POP_ICON.update_icon_sprite(self, @popicon_sprite, @pop_icon, frame, params)
    @popicon_sprite.update
    @popicon_count += 1
  end

  #--------------------------------------------------------------------------
  # ● 处理角色的新图标请求
  #--------------------------------------------------------------------------
  def handle_new_icon_request
    return if @character.pop_icon <= 0

    if @character.pop_icon == @pop_icon
      # 图标ID与当前相同：重置计时器
      @popicon_last_activate = @popicon_count
      @character.pop_icon = -1   # 标记已处理
    else
      # 新图标：完全重置
      reset_popicon
    end
  end

  #--------------------------------------------------------------------------
  # ● 重置图标精灵，准备显示新图标
  #--------------------------------------------------------------------------
  def reset_popicon
    @pop_icon = @character.pop_icon
    @character.pop_icon = -1               # 标记已激活
    @popicon_sprite ||= Sprite.new(viewport)
    @popicon_count = 0
    @popicon_last_activate = 0
  end

  #--------------------------------------------------------------------------
  # ● 结束图标显示
  #   隐藏精灵并清零相关变量
  #--------------------------------------------------------------------------
  def end_popicon
    @popicon_sprite.visible = false if @popicon_sprite
    @pop_icon = 0
    @character.pop_icon = 0
  end
end
