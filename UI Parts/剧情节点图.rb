#==============================================================================
# ■ 剧情节点图 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【组件-通用方法汇总 by老鹰】与
#  【组件-位图绘制转义符文本 by老鹰】与【组件-位图绘制窗口皮肤 by老鹰】与
#  【组件-形状绘制 by老鹰】与【按键扩展 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-StroyMap"] = "0.5.1"
#==============================================================================
# - 2025.8.30.23
#==============================================================================
# - 本插件新增了能够查看剧情节点的系统（仿【死月妖花】）
#------------------------------------------------------------------------------
# 【脚本使用】
#
#    SceneManager.call(Scene_StroyMap)
#
#      → 打开剧情节点图。
#
#    Scene_StroyMap.set_init_node(name)
#
#      → 设置初始时将名称为 name 的节点居中显示。
#        如果该节点不存在/未显示，改为脚本中的第一个节点居中显示
#
#    $game_system.story_node_unlock(name, save=false) 
#
#      → 解锁脚本名称为 name 的节点，
#        若传入save=true，则同时存储一个名称为 name 的存档。
#
#    $game_system.story_node_unlock?(name) 
#
#      → 脚本名称为 name 的节点是否已经解锁？
#
#------------------------------------------------------------------------------
# 【兼容】
#
#    本插件已兼容【鼠标扩展 by老鹰】，可以使用鼠标进行操作，请置于其下。
#
#--------------------------------------------------------------------------
# 【设置】
#
#   推荐在本插件的下一页脚本中，新增一个空白页，命名为“【剧情节点图预设】”，
#   并复制如下的内容，进行修改和扩写：
#
# --------复制以下的内容！--------
module STORY_MAP
  #--------------------------------------------------------------------------
  # ● 常量：设置每行的名称
  #--------------------------------------------------------------------------
  NAME_LINES = { 
    # 行名称的数组
    :data => ["新历121年","新历122年","新历123年"], 
    # 行名称的高度 
    :h => 60,
  }
  #--------------------------------------------------------------------------
  # ● 常量：设置每列的名称
  #--------------------------------------------------------------------------
  NAME_COLS  = { 
    # 列名称的数组
    :data => ["守城方","反叛军","第三方势力"],
    # 列名称的宽度
    :w => 160,
  }
  #--------------------------------------------------------------------------
  # ● 常量：设置每个剧情节点
  #--------------------------------------------------------------------------
  NODES = {
  #------------------------------------------------------------------------
  # 【必须】该节点在脚本中的名称，需要保证唯一性
    "1-1" => { 
      #------------------------------------------------------------------------
      # 【必须】该节点的横轴所在位置
      #  （若设置为数字，则为直接的坐标）
      #  （若设置为字符串，则为所在列，将与对应列的位置对齐）
      :x => "守城方",
      #------------------------------------------------------------------------
      # 【必须】该节点的纵轴所在位置
      #  （若设置为数字，则为直接的坐标）
      #  （若设置为字符串，则为所在列，将与对应列的位置对齐）
      :y => "新历121年", 
      #------------------------------------------------------------------------
      # 【必须】该节点的显示名称
      :name => "测试用",
      #------------------------------------------------------------------------
      # 【可选】该节点的宽度
      #  （若未设置，则取显示名称的宽度）
      #:w => 100,
      #------------------------------------------------------------------------
      # 【可选】该节点的背景图
      #  （设置为数字时，0=窗口皮肤背景，1=暗色背景，2=透明）
      #  （设置为字符串时，为Graphics/System目录下的对应名称的图片）
      :bg => "node_bg",
      #------------------------------------------------------------------------
      # 【可选】该节点的出现条件
      #  （数组，其中均为字符串，将逐个eval并判定返回值是否为true）
      #  （若其中有一个结果不为true，则隐藏该节点）
      #  （如果该节点已经解锁，则不再判定）
      # :if => [""],
      #------------------------------------------------------------------------
      # 【可选】该节点未解锁时，鼠标/键盘点击后的提示文本
      :hint => "完成<主线：一切的开始>后解锁",
      #------------------------------------------------------------------------
      # 【可选】该节点解锁后，鼠标/键盘点击时能否查看详细信息
      #  （若不填写，默认 true，可以点击放大查看详细信息）
      # :no_click => true,
      #------------------------------------------------------------------------
      # 【可选】该节点解锁后，鼠标/键盘点击后的显示位置和缩放倍率
      #  （数字，若不填写或为nil，则取 NODE_X2 、NODE_Y2 、NODE_ZOOM2 ）
      #  （该位置为 节点中心点 的屏幕上坐标）
      :x2 => nil, 
      :y2 => nil,
      :zoom2 => 1.0,
      #------------------------------------------------------------------------
      # 【可选】该节点解锁后，鼠标/键盘点击后显示的详细信息
      #  （数组，其中每一项均为显示的精灵）
      :info => [ 
        #【插入文本】
        # [:text, "需要显示的字符串", 
        #   [显示原点类型, x坐标, y坐标, z值],
        #   [点击效果类型, 相关参数]
        # ]
        #【插入图片】
        # [:pic, "需要显示的图片的名称", 
        #   [显示原点类型, x坐标, y坐标, z值],
        #   [点击效果类型, 相关参数]
        # ]

        # 其中，[点击效果类型, 相关参数]为：
        # 【类型一：场所移动】
        #   [:move, 目的地地图ID，目的地地图x，目的地地图y]
        # 【类型二：读档】
        #  （只有当解锁时同步存了档才有效）
        #   [:load]
        # 【类型三：执行脚本】
        #   [:ruby, "字符串"]
        # 【类型四：呼叫指定事件】
        # （必须使用【呼叫指定事件 by 老鹰】）
        #   [:event, 事件所在地图ID, 事件ID, 事件页ID]
        [:text, "这是一句测试用语句\n点击后将执行1号地图的5号事件。", 
          [7, 100,300,1], [:event, 1,5,0] ],
        [:text, "这是另一句测试用语句\n点击后将退出当前UI并将玩家直接移动到2号地图(10,10)位置。", 
          [7, 300,500,1], [:move, 2,10,10] ],
        [:text, "点击后将读取与该节点脚本名称一致的存档。", 
          [7, 200,700,1], [:load] ],
      ],
    },

    "1-2" => { :x => "守城方", :y => "新历122年", :name => "测试用2", :bg=>0,
      :hint => "完成<主线：一切的开始>后解锁", # 如果没有解锁，点击时弹出的提示文本
    },
    "1-3" => { :x => "守城方", :y => "新历123年", :pic => "node_bg", },
    "1-4" => { :x => "反叛军", :y => "新历123年", :name => "测试用", :bg=>1 },
  }
  #--------------------------------------------------------------------------
  # ● 常量：设置节点之间的连线
  #--------------------------------------------------------------------------
  LINES = [
    # 第一项为连线参数，之后两项为一组，并按该参数连线
    [{},"1-1","1-2", "1-2","1-3"], 
    [],
  ]
#--------------------------------------------------------------------------
end  # 必须的模块结尾，不要漏掉
# --------复制以上的内容！--------
#
#==============================================================================

module STORY_MAP
  #--------------------------------------------------------------------------
  # ● 常量：设置显示UI的视图区域
  #--------------------------------------------------------------------------
  VIEWPORT_RECT = Rect.new(0,0,Graphics.width,Graphics.height)
  #--------------------------------------------------------------------------
  # ● 常量：视图移动时，上下左右的最小显示宽度/高度的增加值
  # 如VIEWPORT_U数字越大，则最底下的节点往上移动时，可到达的y越大。
  # 如VIEWPORT_R数字越大，则最左边的节点往右移动时，可到达的x越小。
  #--------------------------------------------------------------------------
  VIEWPORT_U = 0
  VIEWPORT_D = 0
  VIEWPORT_L = 0
  VIEWPORT_R = 0

  #--------------------------------------------------------------------------
  # ● 常量：节点未解锁时，节点名称显示为该字符串
  #--------------------------------------------------------------------------
  TEXT_LOCK = "<?>"
  #--------------------------------------------------------------------------
  # ● 常量：解锁节点时若选择了保存，则存档文件所在路径
  #--------------------------------------------------------------------------
  SAVEFILE_DIR = "Saves_StoryMap/"
  #--------------------------------------------------------------------------
  # ● 默认值：节点被点击后，移动的新位置及缩放倍率
  #--------------------------------------------------------------------------
  NODE_X2 = VIEWPORT_RECT.width / 2
  NODE_Y2 = VIEWPORT_RECT.height / 4
  NODE_ZOOM2 = 2.0
  #--------------------------------------------------------------------------
  # ● 常量：节点被点击后，移动及缩放的时间
  #--------------------------------------------------------------------------
  NODE_T = 20

  #--------------------------------------------------------------------------
  # ● 函数：光标移动使用的缓动函数
  #  x 为 当前移动计时 ÷ 总移动时间 的小数（0~1）
  #  返回为该时刻的 移动距离/总距离 的比值
  #  若直接返回 x，则为直线移动
  #-------------------------------------------------------------------------
  def self.ease(type, x)
    if $imported["EAGLE-EasingFunction"]
      case type 
      when :node_focus  # 节点点击放大时
        return EasingFuction.call("easeInExpo", x) 
      when :hint_opa    # 节点未解锁，点击显示的提示文本渐隐时
        return EasingFuction.call("easeInExpo", x) 
      end
    end
    x * x
  end

  #--------------------------------------------------------------------------
  # ● 计算最小包围盒
  #--------------------------------------------------------------------------
  def self.get_smallest_box(rects)
    return Rect.new if rects.empty?
    r = rects.pop
    rects.each do |r2|
      r.width = [r.x + r.width, r2.x + r2.width].max - [r.x, r2.x].min
      r.height = [r.y + r.height, r2.y + r2.height].max - [r.y, r2.y].min
      r.x = r2.x if r2.x < r.x  # 新矩形在现有矩形的左外侧，更新x位置
      r.y = r2.y if r2.y < r.y  # 新矩形在现有矩形的上外侧，更新y位置
    end
    return r
  end
  #--------------------------------------------------------------------------
  # ● eval
  #--------------------------------------------------------------------------
  def self.eagle_eval(str)
    as = $game_actors; gp = $game_player; es = $game_map.events
    s = $game_switches; v = $game_variables; ss = $game_self_switches
    begin
      eval(str.to_s)
    rescue
      p $!
    end
  end
  #--------------------------------------------------------------------------
  # ● 处理指定id的出现条件
  #--------------------------------------------------------------------------
  def self.process_token_if(data)
    # data = [ "", ... ] 或 ""
    data = [data] if data.is_a?(String)
    data.each do |ps|
      return false if ps.is_a?(String) && STORY_MAP.eagle_eval(ps) != true
    end
    return true
  end
  #--------------------------------------------------------------------------
  # ● 重置指定精灵的显示原点
  #--------------------------------------------------------------------------
  def self.reset_sprite_oxy(obj, o)
    case o # 固定不动点的位置类型 以九宫格小键盘察看 默认7左上角
    when 1; obj.ox = 0;             obj.oy = obj.height
    when 2; obj.ox = obj.width / 2; obj.oy = obj.height
    when 3; obj.ox = obj.width;     obj.oy = obj.height
    when 4; obj.ox = 0;             obj.oy = obj.height / 2
    when 5; obj.ox = obj.width / 2; obj.oy = obj.height / 2
    when 6; obj.ox = obj.width;     obj.oy = obj.height / 2
    when 7; obj.ox = 0;             obj.oy = 0
    when 8; obj.ox = obj.width / 2; obj.oy = 0
    when 9; obj.ox = obj.width;     obj.oy = 0
    end
  end
end

#=============================================================================
# ○ DataManager
#=============================================================================
class << DataManager
  attr_accessor :flag_story_map
  #--------------------------------------------------------------------------
  # ● 生成文件名
  #     index : 文件索引
  #--------------------------------------------------------------------------
  alias eagle_story_map_make_filename make_filename
  def make_filename(index)
    return make_filename_story_map(index) if @flag_story_map
    eagle_story_map_make_filename(index)
  end
  #--------------------------------------------------------------------------
  # ● 生成文件名
  #--------------------------------------------------------------------------
  Dir.mkdir(STORY_MAP::SAVEFILE_DIR) unless File.exists?(STORY_MAP::SAVEFILE_DIR)
  def make_filename_story_map(index)
    sprintf(STORY_MAP::SAVEFILE_DIR + "Save_#{@flag_story_map}.rvdata2")
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
  def story_node_unlock(name, save=false)
    @eagle_story_nodes ||= []
    if !story_node_unlock?(name)
      @eagle_story_nodes.push(name)
    end
    if save
      DataManager.flag_story_map = name
      DataManager.save_game(0)
      DataManager.flag_story_map = nil
    end
  end
end

#=============================================================================
# ○ StoryNode_DrawTextEX
#=============================================================================
class StoryNode_DrawTextEX < Process_DrawTextEX
end

#=============================================================================
# ○ Sprite_StoryNode_Name
#=============================================================================
class Sprite_StoryNode_Name < Sprite
  attr_accessor  :name
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(viewport, name)
    super(viewport)
    @name = name
    reset_bitmap
    reset_oxy(false)
  end
  #--------------------------------------------------------------------------
  # ● 初始化位置
  #--------------------------------------------------------------------------
  def reset_init_xyz(x, y, z)
    @x0 = x
    @y0 = y
    self.z = z
  end
  #--------------------------------------------------------------------------
  # ● 重置位图
  #--------------------------------------------------------------------------
  def reset_bitmap
    self.bitmap.dispose if self.bitmap
    
    t = @name
    ps = { :ali => 1 }
    d = StoryNode_DrawTextEX.new(t, ps)
    d.run(false)
    
    self.bitmap = Bitmap.new(d.width, d.height)
    d.bind_bitmap(self.bitmap, true)
    d.run
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
  end
  #--------------------------------------------------------------------------
  # ● 重置显示位置（视图移动后调用，抵消视图oxoy）
  #--------------------------------------------------------------------------
  def reset_position(x, y)
    self.x = x + @x0
    self.y = y + @y0
    self.z = 1
  end
end

#=============================================================================
# ○ Sprite_StoryNode
#=============================================================================
class Sprite_StoryNode < Sprite 
  attr_reader  :name, :params
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(viewport, name, params={})
    super(viewport)
    @name = name
    @params = params
    @sprites = {}
    reset_position
    reset_bitmap
    reset_oxy(false)
  end
  #--------------------------------------------------------------------------
  # ● 该节点已经解锁？
  #--------------------------------------------------------------------------
  def unlock?
    $game_system.story_node_unlock?(@name)
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
  def reset_position(x=0, y=0)
    self.x = x
    self.y = y
  end
  #--------------------------------------------------------------------------
  # ● 重置位图
  #--------------------------------------------------------------------------
  def reset_bitmap
    reset_bitmap_text 
    reset_bitmap_bg   if @params[:bg]
    reset_bitmap_pic  if @params[:pic]
    update_child
  end 
  #--------------------------------------------------------------------------
  # ● 设置位图：背景
  #--------------------------------------------------------------------------
  def reset_bitmap_bg
    @sprites[:bg] ||= Sprite.new(self.viewport)
    case @params[:bg]
    when 0
      @sprites[:bg].bitmap = Bitmap.new(self.width+24,self.height+24)
      EAGLE.draw_windowskin("Window", @sprites[:bg].bitmap)
    when 1
      @sprites[:bg].bitmap = Bitmap.new(self.width+16,self.height+12)
      @sprites[:bg].bitmap.fill_rect(0,0,@sprites[:bg].width,@sprites[:bg].height,Color.new(0,0,0,120))
    when 2
    else 
      @sprites[:bg].bitmap = Cache.system(@params[:bg]) rescue Cache.empty_bitmap
    end
    @sprites[:bg].z = self.z - 1
  end
  #--------------------------------------------------------------------------
  # ● 设置位图：文字
  #--------------------------------------------------------------------------
  def reset_bitmap_text 
    self.bitmap.dispose if self.bitmap
    
    t = @params[:name] || ""
    t = STORY_MAP::TEXT_LOCK if !unlock?
    return if t == ""
    
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
    @sprites[:pic].z = self.z + 1
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
    self.ox = _ox + self.width / 2  # 增加一半宽度改为中心点为原点
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
  # ● 设置z值
  #--------------------------------------------------------------------------
  def set_z(v)
    self.z = v
    update_child
  end

  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
    update_child
  end
  #--------------------------------------------------------------------------
  # ● 更新关联精灵的位置及缩放
  #--------------------------------------------------------------------------
  def update_child
    @sprites.each do |n, s|
      s.x = self.x; s.y = self.y
      s.z = self.z
      s.z = self.z - 1 if n == :bg
      s.z = self.z + 1 if n == :pic
      s.zoom_x = self.zoom_x; s.zoom_y = self.zoom_y
    end
  end
  #--------------------------------------------------------------------------
  # ● 能否响应点击？
  #--------------------------------------------------------------------------
  def clickable?
    return false if @params[:no_click] == true
    return true
  end
  #--------------------------------------------------------------------------
  # ● 被选中？（鼠标用）
  #--------------------------------------------------------------------------
  def selected_mouse?
    r = get_rect
    r.x = r.x + self.viewport.rect.x - self.viewport.ox
    r.y = r.y + self.viewport.rect.y - self.viewport.oy
    return true if MOUSE_EX.in?(r)
    #return true if mouse_in?(true, false)
    return false
  end
  #--------------------------------------------------------------------------
  # ● 被选中？（键盘用）
  #--------------------------------------------------------------------------
  def selected_keyboard?(px, py)
    r = get_rect
    return false if r.x > px or px > r.x + r.width
    return false if r.y > py or py > r.y + r.height
    return true
  end
  #--------------------------------------------------------------------------
  # ● 获取当前精灵（含前景、背景）的范围矩形
  #--------------------------------------------------------------------------
  def get_rect
    rects = [Rect.new(x-ox, y-oy, width, height)]
    if @sprites[:bg]
      r = Rect.new(@sprites[:bg].x-@sprites[:bg].ox, @sprites[:bg].y-@sprites[:bg].oy,
        @sprites[:bg].width,@sprites[:bg].height)
      rects.push(r)
    end
    if @sprites[:pic]
      r = Rect.new(@sprites[:pic].x-@sprites[:pic].ox, @sprites[:pic].y-@sprites[:pic].oy,
        @sprites[:pic].width,@sprites[:pic].height)
      rects.push(r)
    end
    return STORY_MAP.get_smallest_box(rects)
  end
end

#=============================================================================
# ○ Sprite_StoryNode_Line
#=============================================================================
class Sprite_StoryNode_Line < Sprite
  attr_accessor :node1, :node2
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(viewport, node1, node2, params={})
    super(viewport)
    @node1 = node1; @node2 = node2
    @params = params
    reset_position
    reset_bitmap
    reset_oxy(false)
  end
  #--------------------------------------------------------------------------
  # ● 重置显示位置
  #--------------------------------------------------------------------------
  def reset_position
    self.x = (@node1.x + @node2.x) / 2
    self.y = (@node1.y + @node2.y) / 2
    self.z = [@node1.z, @node2.z].min - 5
  end
  #--------------------------------------------------------------------------
  # ● 重置位图
  #--------------------------------------------------------------------------
  def reset_bitmap
    self.bitmap.dispose if self.bitmap
    offset = 5
    w = (@node1.x - @node2.x).abs + offset * 2
    h = (@node1.y - @node2.y).abs + offset * 2
    self.bitmap = Bitmap.new(w, h)
    # 绘制从node1到node2的直线
    _x1 = @node1.x - (self.x - w / 2)
    _x2 = @node2.x - (self.x - w / 2)
    _y1 = @node1.y - (self.y - h / 2)
    _y2 = @node2.y - (self.y - h / 2)
    c = Color.new(255,255,255, 150)
    EAGLE.DDALine(self.bitmap, _x1,_y1, _x2, _y2, 1, "1", c)
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
  end
  #--------------------------------------------------------------------------
  # ● 设置整体放大时的新oxy
  #--------------------------------------------------------------------------
  def set_oxy(_ox, _oy, change_xy=true)
    old_ox = self.ox
    old_oy = self.oy
    self.ox = _ox + self.width / 2
    self.oy = _oy + self.height / 2
    if change_xy
      self.x = self.x - old_ox + self.ox
      self.y = self.y - old_oy + self.oy
    end
  end
end

#=============================================================================
# ○ Sprite_StoryNode_Hint
#=============================================================================
class Sprite_StoryNode_Hint < Sprite
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(viewport)
    super(viewport)
    @params = {}
  end
  #--------------------------------------------------------------------------
  # ● 重置
  #--------------------------------------------------------------------------
  def reset(node = nil)
    if node == nil or node.params[:hint] == nil or node.params[:hint] == "" or node.unlock?
      self.opacity = 0
      @params[:opa_c] = nil
      return 
    end
    @node = node
    reset_bitmap
    reset_oxy(false)
    reset_opa(255)
    update
  end
  #--------------------------------------------------------------------------
  # ● 重置位图
  #--------------------------------------------------------------------------
  def reset_bitmap
    t = @node.params[:hint]
    return if t == @text
    @text = t
    
    ps = { :ali => 1 }
    d = StoryNode_DrawTextEX.new(t, ps)
    d.run(false)
    
    self.bitmap.dispose if self.bitmap
    self.bitmap = Bitmap.new(d.width+8, d.height+6)
    
    self.bitmap.fill_rect(0,0,self.width,self.height,Color.new(0,0,0,255))
    
    ps[:x0] = 4; ps[:y0] = 3
    d.bind_bitmap(self.bitmap, true)
    d.run
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
  end
  #--------------------------------------------------------------------------
  # ● 重置不透明度
  #--------------------------------------------------------------------------
  def reset_opa(init_opa)
    @params[:opa0] = init_opa
    @params[:opa1] = 0
    @params[:dopa] = @params[:opa1] - @params[:opa0]
    @params[:opa_c] = 0
    @params[:opa_t] = 120
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    if @node
      self.x = @node.x
      self.y = @node.y 
      self.z = @node.z + 10
    end
    if @params[:opa_c]
      t = @params[:opa_c] * 1.0 / @params[:opa_t]
      self.opacity = @params[:opa0] + STORY_MAP.ease(:hint_opa, t) * @params[:dopa]
      @params[:opa_c] += 1
      @params[:opa_c] = nil if @params[:opa_c] > @params[:opa_t]
    end
  end
end

#=============================================================================
# ○ Sprite_StoryNode_Info
#=============================================================================
class Sprite_StoryNode_Info < Sprite
  attr_reader  :data_click
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(viewport, type, data, click)
    super(viewport)
    @type = type
    @data = data
    @data_click = click
    self.opacity = 0
    reset_bitmap
  end
  #--------------------------------------------------------------------------
  # ● 重置位图
  #--------------------------------------------------------------------------
  def reset_bitmap
    case @type 
    when :text
      t = @data 

      ps = { :ali => 1 }
      d = StoryNode_DrawTextEX.new(t, ps)
      d.run(false)
    
      self.bitmap.dispose if self.bitmap
      self.bitmap = Bitmap.new(d.width+8, d.height+6)
    
      self.bitmap.fill_rect(0,0,self.width,self.height,Color.new(0,0,0,255))
    
      ps[:x0] = 4; ps[:y0] = 3
      d.bind_bitmap(self.bitmap, true)
      d.run
    when :pic 
      pic_name = @data
      self.bitmap = Cache.system(pic_name) rescue Cache.empty_bitmap
    end
  end
  #--------------------------------------------------------------------------
  # ● 设置位置
  #--------------------------------------------------------------------------
  def set_xy(x, y)
    @x0 = x
    @y0 = y
  end
  #--------------------------------------------------------------------------
  # ● 更新位置（抵消掉位图oxy，确保显示位置为屏幕坐标）
  #--------------------------------------------------------------------------
  def update_position
    self.x = self.viewport.ox + @x0
    self.y = self.viewport.oy + @y0
  end
  #--------------------------------------------------------------------------
  # ● 被选中？（键盘用）
  #--------------------------------------------------------------------------
  def selected_keyboard?(px, py)
    r = get_rect
    return false if r.x > px or px > r.x + r.width
    return false if r.y > py or py > r.y + r.height
    return true
  end
  #--------------------------------------------------------------------------
  # ● 获取当前精灵（含前景、背景）的范围矩形
  #--------------------------------------------------------------------------
  def get_rect
    Rect.new(x-ox, y-oy, width, height)
  end
end

#=============================================================================
# ○ Scene_StoryMap
#=============================================================================
class Scene_StoryMap < Scene_MenuBase
  #--------------------------------------------------------------------------
  # ● 设置初始时居中显示的节点的名称
  #--------------------------------------------------------------------------
  def self.set_init_node(name)
    @@init_node = name 
  end
  #--------------------------------------------------------------------------
  # ● 开始
  #--------------------------------------------------------------------------
  def start 
    @@init_node ||= nil
    super
    init_ui 
    # 是否已经选中某个节点并放大处理
    @flag_current_select = false 
    # 键盘按键用
    @key_move_x = 0
    @key_move_y = 0
    @key_move_c = 0
    # 初始化视图显示位置
    init_viewport_oxy
    # 更新全部ui
    update_other_ui_xy
  end 
  #--------------------------------------------------------------------------
  # ● 初始化UI
  #--------------------------------------------------------------------------
  def init_ui 
    # 背景LOGO
    @sprite_bg_info = Sprite.new
    @sprite_bg_info.z = 100
    @sprite_bg_info.zoom_x = @sprite_bg_info.zoom_y = 3.0
    @sprite_bg_info.bitmap = Bitmap.new(Graphics.height, Graphics.height)
    @sprite_bg_info.bitmap.font.size = 48
    @sprite_bg_info.bitmap.font.color = Color.new(255,255,255,10)
    @sprite_bg_info.bitmap.draw_text(0,0,@sprite_bg_info.width,64, "STORY MAP", 0)
    @sprite_bg_info.angle = -90
    @sprite_bg_info.x = Graphics.width + 48
    @sprite_bg_info.y = 0

    # 显示视图
    @viewport = Viewport.new(STORY_MAP::VIEWPORT_RECT)
    @viewport.z = 200
    # 视图的最大移动边界
    #  最左边精灵的xy 最右边精灵的xy
    @limit_rect = Rect.new(@viewport.rect.width, @viewport.rect.height,0,0)

    # 位于中心点的光标
    @sprite_cursor = Sprite.new(@viewport)
    @sprite_cursor.z = 20
    _w = 20; _h = 20
    @sprite_cursor.bitmap = Bitmap.new(_w, _h)
    @sprite_cursor.bitmap.fill_rect(0, _h/2, _w, 1, Color.new(255,255,255,255))
    @sprite_cursor.bitmap.fill_rect(_w/2, 0, 1, _h, Color.new(255,255,255,255))
    @sprite_cursor.ox = @sprite_cursor.width / 2
    @sprite_cursor.oy = @sprite_cursor.height / 2

    # 生成行列名称的精灵
    @name_lines = {}
    ps = STORY_MAP::NAME_LINES
    ps[:data].each_with_index do |name, i|
      s = Sprite_StoryNode_Name.new(@viewport, name)
      x = s.ox
      y = s.oy + i * ps[:h]
      s.reset_init_xyz(x,y,1)
      @name_lines[name] = s
    end
    @name_cols = {}
    ps = STORY_MAP::NAME_COLS
    ps[:data].each_with_index do |name, i|
      s = Sprite_StoryNode_Name.new(@viewport, name)
      x = s.ox + i * ps[:w]
      y = s.oy
      s.reset_init_xyz(x,y,1)
      @name_cols[name] = s
    end
    
    # 未解锁时提示文本的精灵
    @sprite_hint = Sprite_StoryNode_Hint.new(@viewport)
        
    # 点开节点后的暗色遮挡层
    @sprite_layer = Sprite.new(@viewport)
    @sprite_layer.opacity = 0
    @sprite_layer.z = 50
    @sprite_layer.bitmap = Bitmap.new(Graphics.width, Graphics.height)
    @sprite_layer.bitmap.fill_rect(0, 0, @sprite_layer.width, @sprite_layer.height,
      Color.new(0,0,0,150))
      
    # 点开节点后的信息精灵
    @info_sprites = []
    
    # 点开节点后的键盘用光标精灵
    @sprite_cursor2 = Sprite.new(@viewport)
    @sprite_cursor2.visible = false
    @sprite_cursor2.z = 200
    _w = 20; _h = 20
    @sprite_cursor2.bitmap = Bitmap.new(_w, _h)
    @sprite_cursor2.bitmap.fill_rect(0, _h/2, _w, 1, Color.new(255,255,255,255))
    @sprite_cursor2.bitmap.fill_rect(_w/2, 0, 1, _h, Color.new(255,255,255,255))
    @sprite_cursor2.ox = @sprite_cursor.width / 2
    @sprite_cursor2.oy = @sprite_cursor.height / 2

    # 确保行列ui的xy已经更新，因为节点需要行列ui的xy
    update_other_ui_xy

    # 生成全部节点
    @nodes = {}
    STORY_MAP::NODES.each do |name, ps|
      # 如果已经解锁则不再判定条件
      if $game_system.story_node_unlock?(name)
      else
        next if ps[:if] && STORY_MAP.process_token_if(ps[:if]) != true
      end
      s = Sprite_StoryNode.new(@viewport, name, ps)
      x = ps[:x].is_a?(Integer) ? ps[:x] : (@name_cols[ps[:x]].x rescue 0)
      y = ps[:y].is_a?(Integer) ? ps[:y] : (@name_lines[ps[:y]].y rescue 0)
      s.reset_position(x, y)
      s.set_z(10)
      @nodes[name] = s
      # 更新视图移动边界
      @limit_rect.x = s.x+s.ox if s.x+s.ox < @limit_rect.x
      @limit_rect.y = s.y+s.oy if s.y+s.oy < @limit_rect.y
      @limit_rect.width = s.x-s.ox if s.x-s.ox > @limit_rect.width
      @limit_rect.height = s.y-s.oy if s.y-s.oy > @limit_rect.height
    end 
    
    # 绘制节点间的连线
    @lines = []
    STORY_MAP::LINES.each do |v|
      ps = v[0]
      c = (v.size - 1) / 2
      c.times do |i|
        n1 = v[1 + i * 2]
        n2 = v[2 + i * 2]
        next if !@nodes.include?(n1) || !@nodes.include?(n2)
        l = Sprite_StoryNode_Line.new(@viewport, @nodes[n1], @nodes[n2], ps)
        @lines.push(l)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 初始化显示位置
  #--------------------------------------------------------------------------
  def init_viewport_oxy
    name = @@init_node
    name = @nodes.keys[0] if @nodes[name] == nil
    set_node_center(@nodes[name])
  end
  #--------------------------------------------------------------------------
  # ● 将指定node居中
  #--------------------------------------------------------------------------
  def set_node_center(node)
    @viewport.ox = node.x - @viewport.rect.width/2
    @viewport.oy = node.y - @viewport.rect.height/2
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
    @lines.each { |l| l.dispose }
    @lines.clear
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update 
    super 
    return update_current if @flag_current_select
    update_return
    update_nodes 
    update_move
    update_key
  end
  #--------------------------------------------------------------------------
  # ● 更新退出
  #--------------------------------------------------------------------------
  def update_return
    if Input.trigger?(:B) || MOUSE_EX.up?(:MR)
      return_scene
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新节点
  #--------------------------------------------------------------------------
  def update_nodes
    @current_keyboard = @current_mouse = nil
    @nodes.each do |k, s|
      s.update
      if @current_keyboard == nil
        @current_keyboard = s if s.selected_keyboard?(@sprite_cursor.x, @sprite_cursor.y)
      end
      if @current_mouse == nil 
        @current_mouse = s if s.selected_mouse?
      end
    end
    @lines.each { |l| l.update }
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
    update_key_move
    @viewport.ox += @key_move_x
    @viewport.oy += @key_move_y
    # 不能移出边界
    # 最右边精灵的x-ox > 0  最左边精灵的x-ox < @viewport.rect.width
    v = @limit_rect.width-STORY_MAP::VIEWPORT_L
    @viewport.ox = v if @viewport.ox > v
    v = @limit_rect.x-@viewport.rect.width+STORY_MAP::VIEWPORT_R
    @viewport.ox = v if @viewport.ox < v
    v = @limit_rect.height - STORY_MAP::VIEWPORT_U
    @viewport.oy = v if @viewport.oy > v
    v = @limit_rect.y-@viewport.rect.height+STORY_MAP::VIEWPORT_D
    @viewport.oy = v if @viewport.oy < v
    # 更新其它在视图里的UI
    update_other_ui_xy
  end
  #--------------------------------------------------------------------------
  # ● 更新键盘按键移动
  #--------------------------------------------------------------------------
  def update_key_move
    @key_move_x += get_key_move_value(@key_move_x) if INPUT_EX.press?(:LEFT)
    @key_move_x -= get_key_move_value(@key_move_x) if INPUT_EX.press?(:RIGHT)
    @key_move_y += get_key_move_value(@key_move_y) if INPUT_EX.press?(:UP)
    @key_move_y -= get_key_move_value(@key_move_y) if INPUT_EX.press?(:DOWN)
    if (@key_move_c += 1) > 2
      @key_move_c = 0
      @key_move_x += -@key_move_x / @key_move_x.abs if @key_move_x != 0
      @key_move_y += -@key_move_y / @key_move_y.abs if @key_move_y != 0
    end
  end
  def get_key_move_value(cur)
    return 0 if cur.abs > 10
    return 4 if cur.abs < 2
    return 2 if cur.abs < 5
    return 1
  end
  #--------------------------------------------------------------------------
  # ● 更新视图中的其它UI
  #--------------------------------------------------------------------------
  def update_other_ui_xy
    # 显示行列名称的精灵
    @name_lines.each do |name, s|
      s.reset_position(@viewport.ox, 0)
    end
    @name_cols.each do |name, s|
      s.reset_position(0, @viewport.oy)
    end
    
    # 位于视图显示中心的光标
    r = @viewport.rect
    @sprite_cursor.x = @viewport.ox + r.width / 2
    @sprite_cursor.y = @viewport.oy + r.height / 2
    
    # 未解锁提示精灵
    @sprite_hint.update
    
    # 点开后的暗色遮挡层
    @sprite_layer.x = @viewport.ox
    @sprite_layer.y = @viewport.oy
    
    # 点开后的显示具体信息info的精灵组
    @info_sprites.each { |s| s.update_position }
  end
  
  #--------------------------------------------------------------------------
  # ● 更新按键
  #--------------------------------------------------------------------------
  def update_key 
    @current = nil
    if @current_keyboard && @current_keyboard.clickable? && Input.trigger?(:C)
      @current = @current_keyboard
    end
    if @current_mouse && @current_mouse.clickable? && MOUSE_EX.up?(:ML)
      @current = @current_mouse
    end
    @cur_last_ox = @viewport.ox
    @cur_last_oy = @viewport.oy
    if @current
      if @current.unlock?
        process_current_zoomin
      else
        @sprite_hint.reset(@current) # 如果还未解锁，显示提示文本
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 选中的节点移至指定处并放大
  #--------------------------------------------------------------------------
  def process_current_zoomin
    @flag_current_select = true
    # 去除未解锁提示
    @sprite_hint.reset(nil)
    # 生成当前节点的详细信息精灵组
    reset_info_sprites(@current) 
    # 更改当前节点的z值，准备放大
    @current.set_z(100)
    # 以当前节点的xy，放大全部节点和连线
    ox = @current.x - (@current.params[:x2] || STORY_MAP::NODE_X2)
    oy = @current.y - (@current.params[:y2] || STORY_MAP::NODE_Y2) 
    @nodes.each do |k, s|
      next if s == @current 
      s.set_oxy(@current.x - s.x, @current.y - s.y)
    end
    @lines.each do |l|
      l.set_oxy(@current.x - l.x, @current.y - l.y)
    end
    # 处理放大
    z = @current.params[:zoom2] || STORY_MAP::NODE_ZOOM2
    t = STORY_MAP::NODE_T
    d_opa1 = 255 / t + 1
    d_opa2 = d_opa1 * 2
    update_nodes_zoom_until_end(z, z, ox, oy, t) { 
      # 遮挡层、当前节点的详细信息精灵组 渐显
      @sprite_layer.opacity += d_opa1
      @info_sprites.each { |s| s.opacity += d_opa1 }
      # 中心光标、行列精灵 渐隐
      @sprite_cursor.opacity -= d_opa2
      @name_lines.each { |name, s| s.opacity -= d_opa2 }
      @name_cols.each { |name, s| s.opacity -= d_opa2 }
    }
    
    # 显示键盘用的光标
    @sprite_cursor2.x = @viewport.ox + @viewport.rect.width/2
    @sprite_cursor2.y = @viewport.oy + @viewport.rect.height/2
    @sprite_cursor2.visible = true
    @key_move_x = @key_move_y = 0
  end 
  #--------------------------------------------------------------------------
  # ● 选中的节点缩小回原样
  #--------------------------------------------------------------------------
  def process_current_zoomout(ox = nil, oy = nil)
    # 隐藏键盘用的光标
    @sprite_cursor2.visible = false
    @key_move_x = @key_move_y = 0
    # 处理缩小
    ox ||= @viewport.ox; oy ||= @viewport.oy
    t = STORY_MAP::NODE_T
    d_opa1 = 255 / t + 1
    d_opa2 = d_opa1 * 2
    update_nodes_zoom_until_end(1.0, 1.0, ox, oy, t) { 
      # 遮挡层、当前节点的详细信息精灵组 渐隐
      @sprite_layer.opacity -= d_opa1
      @info_sprites.each { |s| s.opacity -= d_opa1 }
      # 中心光标、行列精灵 渐显
      @sprite_cursor.opacity += d_opa2
      @name_lines.each { |name, s| s.opacity += d_opa2 }
      @name_cols.each { |name, s| s.opacity += d_opa2 }
    }
    # 重置其它节点和连线的位置
    @nodes.each do |k, s|
      next if s == @current
      s.reset_oxy
    end
    @lines.each do |l|
      l.reset_oxy
    end
    # 重置当前节点的z值
    @current.set_z(10)
    @flag_current_select = false
    @current = nil
    # 清除当前节点具体信息的精灵
    @info_sprites.each { |s| s.bitmap.dispose; s.dispose }
    @info_sprites.clear
  end 
  #--------------------------------------------------------------------------
  # ● 处理整体缓动移动并结束
  #--------------------------------------------------------------------------
  def update_nodes_zoom_until_end(zx, zy, ox, oy, t=20)  # block
    zx1 = @current.zoom_x; zx2 = zx; dzx = zx2- zx1
    zy1 = @current.zoom_y; zy2 = zy; dzy = zy2- zy1
    ox1 = @viewport.ox; ox2 = ox; dox = ox2 - ox1
    oy1 = @viewport.oy; oy2 = oy; doy = oy2 - oy1
    t.times do |i|
      update_basic
      if i == t-1
        zx = zx2
        zy = zy2
        @viewport.ox = ox2
        @viewport.oy = oy2
      else
        v = i * 1.0 / t
        v = STORY_MAP.ease(:node_focus, v)
        zx = zx1 + v * dzx
        zy = zy1 + v * dzy
        @viewport.ox = ox1 + v * dox
        @viewport.oy = oy1 + v * doy
      end
      @nodes.each { |k, s| s.zoom_x = zx; s.zoom_y = zy; s.update }
      @lines.each { |l| l.zoom_x = zx; l.zoom_y = zy; l.update }
      yield if block_given?
      update_other_ui_xy
    end
  end
  
  #--------------------------------------------------------------------------
  # ● 生成展示info信息的精灵们
  #--------------------------------------------------------------------------
  def reset_info_sprites(node)
    array = node.params[:info] || []
    array.each do |ps|
      # [:text, "文本", [o, x, y, z], [] ] 
      # [:pic, "图片名", ...]
      type = ps[0]
      t = ps[1]
      pos = ps[2]
      data_click = ps[3] || nil
      s = Sprite_StoryNode_Info.new(@viewport, type, t, data_click)
      STORY_MAP.reset_sprite_oxy(s, pos[0])
      s.set_xy(pos[1], pos[2])
      s.z = 100 + pos[3]
      @info_sprites.push(s)
    end
  end
  #--------------------------------------------------------------------------
  # ● 如果已经放大了一个节点，则需要更新它
  #--------------------------------------------------------------------------
  def update_current 
    # 更新键盘光标
    @sprite_cursor2.x -= 5 if INPUT_EX.press?(:LEFT)
    @sprite_cursor2.x += 5 if INPUT_EX.press?(:RIGHT)
    @sprite_cursor2.y -= 5 if INPUT_EX.press?(:UP)
    @sprite_cursor2.y += 5 if INPUT_EX.press?(:DOWN)
    @sprite_cursor2.x = [[@sprite_cursor2.x, @viewport.ox].max, @viewport.ox+@viewport.rect.width].min
    @sprite_cursor2.y = [[@sprite_cursor2.y, @viewport.oy].max, @viewport.oy+@viewport.rect.height].min
    # 更新退出当前节点
    if MOUSE_EX.up?(:MR) || Input.trigger?(:B) 
      return process_current_zoomout(@cur_last_ox, @cur_last_oy)
    end
    # 更新当前节点的信息精灵组
    @info_sprites.each do |s| 
      next if s.data_click == nil 
      # 处理点击后触发的效果
      if (s.mouse_in? and MOUSE_EX.up?(:ML)) or 
         (s.selected_keyboard?(@sprite_cursor2.x, @sprite_cursor2.y) and Input.trigger?(:C))
        case s.data_click[0]
        when :event
          EAGLE.call_event(s.data_click[1], s.data_click[2], s.data_click[3])
        when :move
          $game_player.reserve_transfer(s.data_click[1], s.data_click[2], s.data_click[3])
          fadeout_all
          $game_player.perform_transfer
          SceneManager.goto(Scene_Map)
        when :load
          DataManager.flag_story_map = @current.name
          if DataManager.load_game(0)
            Sound.play_load
            fadeout_all
            $game_system.on_after_load
            SceneManager.goto(Scene_Map)
          end
          DataManager.flag_story_map = nil
        when :ruby
          STORY_MAP.eagle_eval(s.data_click[1])
        end
        return
      end
    end
  end
end
