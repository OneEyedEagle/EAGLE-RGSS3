
# 剧情节点图

module STORY_MAP
  DATA = {
    "1" => { :x => 100, :y => 100, :bg => "node_bg", :t => "测试用", :w => 100, 
      :help => "" },
    "2" => { :x => 150, :y => 150, :t => "测试用2" },
    "3" => { :x => 180, :y => 180, :pic => "node_bg", :no_click => true }
  }

  LINES = [
    [{},"1","2"], []
  ]

  VIEWPORT = Viewport.new(20,20,Graphics.width-40,Graphics.height-40)
  
  #--------------------------------------------------------------------------
  # ● 函数：光标移动使用的缓动函数
  #  x 为 当前移动计时 ÷ 总移动时间 的小数（0~1）
  #  返回为该时刻的 移动距离/总距离 的比值
  #  若直接返回 x，则为直线移动
  #-------------------------------------------------------------------------
  def self.ease(x)
    x * x
  end
end

#=============================================================================
# ○ Game_System
#=============================================================================
class Game_System
  attr_accessor  :eagle_story_nodes  # 已经解锁的剧情节点的名称的数组
  #--------------------------------------------------------------------------
  # ● 指定剧情节点是否已经解锁？
  #--------------------------------------------------------------------------
  def story_node_unlock?(name)
    @eagle_story_nodes ||= []
    return @eagle_story_nodes.include?(name)
  end
  #--------------------------------------------------------------------------
  # ● 保存已经解锁的剧情节点的名称
  #--------------------------------------------------------------------------
  def story_node_unlock(name)
    @eagle_story_nodes ||= []
    return if story_node_unlock?(name)
    return @eagle_story_nodes.push(name)
  end
end

#=============================================================================
# ○ StoryNode_DrawTextEX
#=============================================================================
class StoryNode_DrawTextEX < Process_DrawTextEX
end

#=============================================================================
# ○ Sprite_StoryNode
#=============================================================================
class Sprite_StoryNode < Sprite 
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(viewport, params={})
    super(viewport)
    @params = params
    @sprites = {}
    reset_position
    reset_bitmap
    reset_oxy(false)
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose 
    @sprites.each do |n, s|
      s.bitmap.dispose if s.bitmap
      s.dispose
    end
    @sprites.clear
    self.bitmap.dispose if self.bitmap
    super 
  end
  
  #--------------------------------------------------------------------------
  # ● 重置显示位置
  #--------------------------------------------------------------------------
  def reset_position
    self.x = @params[:x]
    self.y = @params[:y]
  end
  #--------------------------------------------------------------------------
  # ● 重置位图
  #--------------------------------------------------------------------------
  def reset_bitmap
    reset_bitmap_bg   if @params[:bg]
    reset_bitmap_text if @params[:t]
    reset_bitmap_pic  if @params[:pic]
  end 
  #--------------------------------------------------------------------------
  # ● 设置位图：背景
  #--------------------------------------------------------------------------
  def reset_bitmap_bg
    @sprites[:bg] ||= Sprite.new(self.viewport)
    @sprites[:bg].bitmap = Cache.system(@params[:bg]) rescue Cache.empty_bitmap
    update_child_sprite(:bg, @sprites[:bg])
  end
  #--------------------------------------------------------------------------
  # ● 设置位图：文字
  #--------------------------------------------------------------------------
  def reset_bitmap_text 
    self.bitmap.dispose if self.bitmap
    
    t = @params[:t]
    ps = { :ali => 1, :w => @params[:w] }
    d = StoryNode_DrawTextEX.new(t, ps)
    d.run(false)
    
    w = [@params[:w] || 0, d.width].max
    self.bitmap = Bitmap.new(w, d.height)
    d.bind_bitmap(self.bitmap, true)
    d.run
  end
  #--------------------------------------------------------------------------
  # ● 设置位图：前景图
  #--------------------------------------------------------------------------
  def reset_bitmap_pic
    @sprites[:pic] ||= Sprite.new(self.viewport)
    @sprites[:pic].bitmap = Cache.system(@params[:pic]) rescue Cache.empty_bitmap
    update_child_sprite(:pic, @sprites[:pic])
  end
  #--------------------------------------------------------------------------
  # ● 重置oxy
  #--------------------------------------------------------------------------
  def reset_oxy(change_xy=true)
    old_ox = self.ox
    old_oy = self.oy
    self.ox = self.width / 2
    self.oy = self.height / 2
    if change_xy
      self.x = self.x - old_ox + self.ox
      self.y = self.y - old_oy + self.oy
    end
    @sprites.each do |n, s|
      old_ox = s.ox
      old_oy = s.oy
      s.ox = s.width / 2
      s.oy = s.height / 2
      if change_xy
        s.x = s.x - old_ox + s.ox
        s.y = s.y - old_oy + s.oy
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 设置整体放大时的新oxy
  #--------------------------------------------------------------------------
  def set_oxy(_ox, _oy, change_xy=true)
    old_ox = self.ox
    old_oy = self.oy
    self.ox = _ox + self.width / 2  # 默认0为原点，增加一般宽度改为中心点为原点
    self.oy = _oy + self.height / 2
    if change_xy
      self.x = self.x - old_ox + self.ox
      self.y = self.y - old_oy + self.oy
    end
    @sprites.each do |n, s|
      old_ox = s.ox
      old_oy = s.oy
      s.ox = _ox + s.width / 2
      s.oy = _oy + s.height / 2
      if change_xy
        s.x = s.x - old_ox + s.ox
        s.y = s.y - old_oy + s.oy
      end
    end
  end

  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
    @sprites.each do |n, s|
      update_child_sprite(n, s)
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新关联精灵的位置及缩放
  #--------------------------------------------------------------------------
  def update_child_sprite(n, s)
    s.x = self.x; s.y = self.y
    s.z = self.z
    s.z = self.z - 1 if n == :bg
    s.z = self.z + 1 if n == :pic
    s.zoom_x = self.zoom_x; s.zoom_y = self.zoom_y
  end
  #--------------------------------------------------------------------------
  # ● 能否响应点击？
  #--------------------------------------------------------------------------
  def clickable?
    return false if @params[:no_click] == true
    return true
  end
end

#=============================================================================
# ○ Scene_StoryMap
#=============================================================================
class Scene_StoryMap < Scene_Base
  #--------------------------------------------------------------------------
  # ● 开始
  #--------------------------------------------------------------------------
  def start 
    super
    init_ui 
  end 
  #--------------------------------------------------------------------------
  # ● 初始化UI
  #--------------------------------------------------------------------------
  def init_ui 
    @viewport = STORY_MAP::VIEWPORT
    @viewport.z = 200

    @nodes = {}

    STORY_MAP::DATA.each do |name, param|
      s = Sprite_StoryNode.new(@viewport, param)
      @nodes[name] = s
    end 

    # TODO 绘制连线

    @flag_current = false 
  end
  #--------------------------------------------------------------------------
  # ● 结束
  #--------------------------------------------------------------------------
  def terminate
    dispose_ui
    super 
  end
  #--------------------------------------------------------------------------
  # ● 释放UI
  #--------------------------------------------------------------------------
  def dispose_ui
    @nodes.each { |k, s| s.dispose }
    @nodes.clear
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update 
    super 
    return update_current if @flag_current
    update_nodes 
    update_move
    update_key
  end
  #--------------------------------------------------------------------------
  # ● 更新节点
  #--------------------------------------------------------------------------
  def update_nodes
    @current = nil
    @nodes.each do |k, s|
      s.update
      @current = s if s.mouse_in?(true, false)
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新整体移动
  #--------------------------------------------------------------------------
  def update_move 
    if MOUSE_EX.drag?
      dx, dy = MOUSE_EX.drag_dxy
      @viewport.ox -= dx
      @viewport.oy -= dy
      Input.update
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新按键
  #--------------------------------------------------------------------------
  def update_key 
    if @current && @current.clickable? && MOUSE_EX.up?(:ML)
      process_current_zoomin
      return 
    end
  end
  #--------------------------------------------------------------------------
  # ● 如果已经有选中的节点，更新它
  #--------------------------------------------------------------------------
  def update_current 
    return process_current_zoomout if MOUSE_EX.up?(:MR)
  end
  #--------------------------------------------------------------------------
  # ● 处理选中节点的移至中心处并放大
  #--------------------------------------------------------------------------
  def process_current_zoomin
    @flag_current = true
    ox = @current.x - (@viewport.rect.width/2)
    oy = @current.y - (@viewport.rect.height/2) 
    @nodes.each do |k, s|
      next if s == @current 
      s.set_oxy(@current.x - s.x, @current.y - s.y)
    end
    update_nodes_zoom_until_end(3.0, 3.0, ox, oy)
  end 
  #--------------------------------------------------------------------------
  # ● 处理选中节点的缩小回原样
  #--------------------------------------------------------------------------
  def process_current_zoomout
    update_nodes_zoom_until_end(1.0, 1.0, @viewport.ox, @viewport.oy)
    @nodes.each do |k, s|
      next if s == @current
      s.reset_oxy
    end
    @flag_current = false
  end 
  #--------------------------------------------------------------------------
  # ● 处理整体缓动移动并结束
  #--------------------------------------------------------------------------
  def update_nodes_zoom_until_end(zx, zy, ox, oy)  # block
    zx1 = @current.zoom_x; zx2 = zx; dzx = zx2- zx1
    zy1 = @current.zoom_y; zy2 = zy; dzy = zy2- zy1
    ox1 = @viewport.ox; ox2 = ox; dox = ox2 - ox1
    oy1 = @viewport.oy; oy2 = oy; doy = oy2 - oy1
    t = 20
    t.times do |i|
      yield if block_given?
      if i == t-1
        zx = zx2
        zy = zy2
        @viewport.ox = ox2
        @viewport.oy = oy2
      else
        v = i * 1.0 / t
        v = STORY_MAP.ease(v)
        zx = zx1 + v * dzx
        zy = zy1 + v * dzy
        @viewport.ox = ox1 + v * dox
        @viewport.oy = oy1 + v * doy
      end
      @nodes.each do |k, s|
        s.zoom_x = zx 
        s.zoom_y = zy
        s.update
      end
      update_basic
    end
  end
end
