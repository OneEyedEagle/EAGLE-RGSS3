#==============================================================================
# ■ 粒子模板预设 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【粒子系统V3 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-PT-PreSet"] = "3.1.0"
#==============================================================================
# - 2025.6.21.10 编写一些新范例
#==============================================================================

class << PARTICLE
  alias eagle_particle_init init
  def init
    eagle_particle_init
    
    # --------------------------------------------------------------------
    #  在此处编写你想要预设的模板
    #  之后直接按照你设定的名字进行调用就可以用啦！
    # --------------------------------------------------------------------
    
    # 模板 - 全屏随机显示红色的小方块
    f = PT_Emitter.new
    b = Bitmap.new(3, 3)
    b.fill_rect(b.rect, Color.new(255,0,0,255))
    f.params[:bitmaps].push(b)  # 可以传入多个，粒子会随机选一个
    f.params[:pos_rect] = Rect.new(0, 0, Graphics.width, Graphics.height)
    f.params[:theta] = VarValue.new(0, 360) # 初速度方向（角度）
    f.params[:speed] = VarValue.new(2, 1) # 初速度值（标量）
    f.params[:life] = VarValue.new(300, 120) # 存在时间
    setup("测试", f)  # 这个粒子模板的名称为 "测试"
    # 需要用时，使用全局脚本 PARTICLE.start("测试")
    
    
    # 能力待学习的特效
    f = PT_Moveto.new
    f.params[:total] = 40 
    f.params[:new_wait] = 10 
    b = Bitmap.new(6, 6)
    b.fill_rect(b.rect, Color.new(255,255,255,200))
    f.params[:bitmaps].push(b)
    f.params[:xys] = [ [Graphics.width/2, Graphics.height/2] ]
    f.params[:xys_type] = 10
    f.params[:zoom] = 0.5
    f.params[:opacity] = 0
    f.params[:move_type] = "easeOutExpo"
    setup("可学习", f)  # 这个粒子模板的名称为 "测试"
    
    # 能力完成学习的特效
    f = PT_Emitter.new
    f.flag_start_once = true
    f.params[:total] = 30 
    b = Bitmap.new(2, 2)
    b.fill_rect(b.rect, Color.new(255,255,255,255))
    f.params[:bitmaps].push(b) 
    #f.params[:pos_rect] = Rect.new(0, 0, Graphics.width, Graphics.height)
    f.params[:theta] = VarValue.new(0, 360) # 初速度方向（角度）
    f.params[:speed] = VarValue.new(2, 1) # 初速度值（标量）
    f.params[:life] = VarValue.new(60, 20) # 存在时间
    f.params[:z] = 100
    setup("能力学习完成", f) 

  end

  #--------------------------------------------------------------------------
  # ● （测试用）图片散开再聚拢
  #--------------------------------------------------------------------------
  def test_img_split
    # 导入 Graphics/System 下的图片，调用 组件-通用方法汇总 中的方法切割成n个矩形
    s = Sprite.new
    s.bitmap = Cache.system("face_eagle")
    s.x = (Graphics.width - s.width ) / 2
    s.y = (Graphics.height - s.height ) / 2
    ss, pos = EAGLE_COMMON.img2rects(s)
    s.dispose
    
    # 处理这些矩形的四散
    f = PT_Emitter.new
    f.flag_start_once = true
    f.params[:sprites] = ss.dup
    f.params[:total] = ss.size
    f.params[:pos_rect] = Rect.new(0, 0, Graphics.width, Graphics.height)
    f.params[:theta] = VarValue.new(0, 360) # 初速度方向（角度）
    f.params[:speed] = VarValue.new(2, 1) # 初速度值（标量）
    f.params[:life] = 50 # 存在时间
    f.params[:force] = Vector.new(0,1)
    setup("test-1", f) 
    start("test-1")
    
    # 事件脚本中使用，等待散开完成
    60.times { Fiber.yield } 
    
    # 处理这些矩形的归位（依靠之前存的 pos，让精灵按顺序移动回原位置）
    f = PT_Moveto.new
    f.flag_start_once = true
    f.params[:sprites] = ss 
    f.params[:total] = ss.size
    f.params[:xys] = pos
    f.params[:xys_type] = 1
    f.params[:life] = 120 # 存在时间
    f.params[:t] = 100
    # 因为之后没有这些精灵的事情了，而粒子系统里外部导入的精灵不会自动释放，
    #  所以在粒子生命结束时手动释放
    f.params[:eval2] = "cur.bitmap.dispose; cur.dispose"
    setup("test-2", f)
    start("test-2")
  end
  
end
