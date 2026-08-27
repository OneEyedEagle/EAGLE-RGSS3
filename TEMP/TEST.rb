# 角色选择框

class Window_EagleActorList < Window_Selectable
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize(x, y, width, height)
    super
    @data = []
  end

  # 获取列数
  def col_max
    return 1
  end

  #--------------------------------------------------------------------------
  # ● 设置属性
  #--------------------------------------------------------------------------
  def set(params={})
    
    refresh
  end

  # 刷新
  def refresh
    self.oy = 0
    make_item_list
    create_contents
    draw_all_items
  end

  #--------------------------------------------------------------------------
  # ● 生成物品列表
  #--------------------------------------------------------------------------
  def make_item_list
    @data = database.select {|actor| include?(actor) }
    @data.push(nil) if include?(nil)
  end

  # 全部角色
  def database
    $game_party.members
  end

  # 查询列表中是否含有此角色
  def include?(actor)
    true
  end

  # 获取项目数
  def item_max
    @data ? @data.size : 1
  end

  # 获取当前角色
  def item
    @data && index >= 0 ? @data[index] : nil
  end

  # 查询此物品是否可用
  def enable?(item)
    true
  end

  # 获取选择项目的有效状态
  def current_item_enabled?
    true
  end

  #--------------------------------------------------------------------------
  # ● 绘制项目
  #--------------------------------------------------------------------------
  def draw_item(index)
    actor = @data[index]
    if item
      rect = item_rect(index)
      rect.width -= 4
      draw_text(rect.x, rect.y, rect.width, line_height, actor.name)
    end
  end

  #--------------------------------------------------------------------------
  # ● 更新帮助内容
  #--------------------------------------------------------------------------
  def update_help
    @help_window.set_item(item)
  end
end
