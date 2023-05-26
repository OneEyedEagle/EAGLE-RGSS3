#==============================================================================
# ■ Add-On 地图切换特效 by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【粒子模板-归位类 by老鹰】与【组件-通用方法汇总 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-Particle-MapTransfer"] = "3.0.1"
#==============================================================================
# - 2023.5.13.21 适配 粒子系统 3.0.0版本
#==============================================================================
# - 本插件新增了基于粒子的地图切换特效
#----------------------------------------------------------------------------
# 【使用方法】
#
# - 当 事件指令-场所移动 中，淡入淡出效果选择“无”，
#    且V_ID_MAP_TRANSFER序号变量的值不为0时，
#    将开启粒子散开与聚合的地图切换特效
#
# - 如果想自定义，请依据脚本中的注释修改各项参数
#
#==============================================================================

module PARTICLE
  #--------------------------------------------------------------------------
  # 利用一个全局变量来控制该效果的开关：
  #
  #  1. 当该序号的变量的值为 0 时，代表关闭该地图切换特效
  #  
  #  2. 当该序号的变量的值为 1 时，代表仅开启地图移出时的特效
  #
  #  3. 当该序号的变量的值为 2 时，代表仅开启地图移入时的特效
  #
  #  4. 当该序号的变量的值为 3 时，代表开启地图移入移出时的特效
  #
  #--------------------------------------------------------------------------
  V_ID_MAP_TRANSFER = 18
  
end

class Spriteset_Map
  attr_reader :viewport1
end

class Scene_Map
  #--------------------------------------------------------------------------
  # ● 场所移动前的处理
  #--------------------------------------------------------------------------
  alias eagle_partical_maptransfer_pre_transfer pre_transfer
  def pre_transfer
    eagle_partical_maptransfer_pre_transfer
    return if $game_temp.fade_type != 2
    v = $game_variables[PARTICLE::V_ID_MAP_TRANSFER]
    return if v & 1 == 0
    
    # 将当前地图的元素截图
    b = EAGLE_COMMON.snapshot_custom([@spriteset.viewport1])
    # 此处修改场所移出时，截图拆分的参数
    ps = { 
      # 横向拆分为 :nx 块，纵向拆分为 :ny 块
      :nx => 20, 
      :ny => 15,
      # 拆分后，每个小块的显示原点为中心处
      :ox => 0.5, 
      :oy => 0.5, 
    }
    # 将截图进行拆分
    ss, pos = EAGLE_COMMON.img2rects(b, ps)
    
    # 粒子移出所耗帧数
    t = 30  # 注意，由于存在update_wait=2，因为是每隔1帧更新一次
    # 采用 单点斥力场 模板
    f = PT_Emitter_Single_Repulsion.new
    # 一次性生成全部粒子
    f.flag_start_once = true
    # 斥力点的位置
    f.params[:center] = Vector.new(Graphics.width/2,Graphics.height/2)
    # 斥力大小
    f.params[:gravity] = 3
    # 导入之前拆分的精灵数组
    f.params[:sprites] = ss
    f.params[:total] = ss.size
    # 单个精灵的存在时间
    f.params[:life] = t
    # 由于外部导入的精灵，粒子系统不会释放，因此手动在粒子生命结束时释放
    f.params[:eval2] = "cur.bitmap.dispose; cur.dispose"
    # 开始处理
    PARTICLE.setup("eagle-map-transfer-out", f) 
    PARTICLE.start("eagle-map-transfer-out")
    # 等待一半时间，防止切换过快而卡顿
    (t / 2).times { update_basic }
  end
  #--------------------------------------------------------------------------
  # ● 场所移动后的处理
  #--------------------------------------------------------------------------
  alias eagle_partical_maptransfer_post_transfer post_transfer
  def post_transfer
    eagle_partical_maptransfer_post_transfer
    return if $game_temp.fade_type != 2
    v = $game_variables[PARTICLE::V_ID_MAP_TRANSFER]
    return if v & 2 == 0
    
    # 等待1帧，确保切换到了新地图
    1.times { update }
    # 新地图截图
    b = EAGLE_COMMON.snapshot_custom([@spriteset.viewport1])
    # 增加一个黑色块盖住地图
    s = Sprite.new(@spriteset.viewport1)
    s.bitmap = Bitmap.new(1,1)
    s.bitmap.fill_rect(0,0,s.width,s.height, Color.new(0,0,0))
    s.zoom_x = Graphics.width
    s.zoom_y = Graphics.height
    s.z = 200
    
    # 此处修改场所移出时，截图拆分的参数
    ps = { 
      # 横向拆分为 :nx 块，纵向拆分为 :ny 块
      :nx => 20, 
      :ny => 15,
      # 拆分后，每个小块的显示原点为中心处
      :ox => 0.5, 
      :oy => 0.5, 
    }
    # 将截图进行拆分
    ss, pos = EAGLE_COMMON.img2rects(b, ps)
    # 为每个块设置初始位置
    ss.each { |s| 
      # 以屏幕中点为基准，向四方向扩散
      s.x = Graphics.width / 2 + (s.x - Graphics.width / 2) * (5)
      s.y = Graphics.height / 2 + (s.y - Graphics.height / 2) * (5)
      s.z = 500  # z值大于之前盖住地图的黑色块
      s.opacity = 0
    }

    # 粒子移入所耗帧数
    t = 25  # 注意，由于存在update_wait=2，因为是每隔1帧更新一次
    # 采用 归位类模板
    f = PT_Moveto.new(@spriteset.viewport1)
    # 一次性生成全部粒子
    f.flag_start_once = true
    # 导入之前拆分的精灵数组
    f.params[:sprites] = ss 
    f.params[:total] = ss.size
    # 导入拆分时每个块精灵的初始位置，作为它移动后的停留位置
    f.params[:xys] = pos
    # 按顺序取出，确保拆分位置与精灵顺序一一对应
    f.params[:xys_type] = 1
    # 移动后的不透明度
    f.params[:opacity] = 255
    # 移动所耗帧数
    f.params[:t] = t
    # 单个精灵的存在时间
    f.params[:life] = t*2-1 # 存在时间
    # 所使用的移动缓动函数
    f.params[:move_type] = "easeOutCirc"
    # 移动结束时的处理，直接指定不透明度为0，防止因未及时移出导致玩家移动出现凝滞感
    f.params[:eval_pt] = "cur.opacity = 0"
    # 由于外部导入的精灵，粒子系统不会释放，因此手动在粒子生命结束时释放
    f.params[:eval2] = "cur.bitmap.dispose; cur.dispose"
    # 开始处理
    PARTICLE.setup("eagle-map-transfer-in", f)
    PARTICLE.start("eagle-map-transfer-in")
    # 等待结束
    (2*t).times { update_basic }
    # 将盖住地图的黑色块释放
    s.bitmap.dispose
    s.dispose
  end
end
