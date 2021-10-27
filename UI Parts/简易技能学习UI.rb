# 简易技能解锁UI
#  （仿霓虹深渊）

# 32x32大小的格子组成棋盘
# 格子中心为显示原点

# 角色光标为像素移动，以角色中心点为判定点

module SKILL_LEARN
  #--------------------------------------------------------------------------
  # ○【常量】格子的宽度/高度
  #--------------------------------------------------------------------------
  GRID_W = 32
  GRID_H = 32
  #--------------------------------------------------------------------------
  # ○【常量】最大的格子数（横、竖）
  #--------------------------------------------------------------------------
  GRID_MAX_X = 20
  GRID_MAX_Y = 20

  #--------------------------------------------------------------------------
  # ○【常量】提示文本的字体大小
  #--------------------------------------------------------------------------
  HINT_FONT_SIZE = 14

  #--------------------------------------------------------------------------
  # ○【常量】角色数据
  #--------------------------------------------------------------------------
  ACTORS = {}

  ACTORS[1] = {
    1 => {
      :skill => 1,
      :pos => [2, 2],
      :help => "测试用的文本",
      #:sp => 1,
      #:pre => [1],
      #:if => "true",  # "eval(str) == true",
      #:pic => nil, #"图标id 或 图片名称",
      #:eval_
    },
    2 => {
      :skill => 3,
      :pos => [3, 6],
      :help => "",
      :pre => [1],
    },
    3 => {
      :skill => 4,
      :pos => [3, 10],
      :help => "",
      :pre => [2],
    },
    4 => {
      :skill => 10,
      :pos => [3, 15],
      :help => "",
      :pre => [3],
    },
  }

  #--------------------------------------------------------------------------
  # ● 获取指定角色的全部数据
  #--------------------------------------------------------------------------
  def self.get_tokens(actor_id)
    ACTORS[actor_id]
  end
  #--------------------------------------------------------------------------
  # ● 获取指定角色的指定id的数据
  #--------------------------------------------------------------------------
  def self.get_token(actor_id, token_id)
    ACTORS[actor_id][token_id]
  end
  #--------------------------------------------------------------------------
  # ● 获取指定id的对应技能
  #--------------------------------------------------------------------------
  def self.get_token_skill(actor_id, token_id)
    ps = get_token(actor_id, token_id)
    ps[:skill] || nil
  end
  #--------------------------------------------------------------------------
  # ● 获取指定id的sp消耗量
  #--------------------------------------------------------------------------
  def self.get_token_sp(actor_id, token_id)
    ps = get_token(actor_id, token_id)
    ps[:sp] || 1
  end
  #--------------------------------------------------------------------------
  # ● 获取指定id的前置id们
  #--------------------------------------------------------------------------
  def self.get_token_pre(actor_id, token_id)
    ps = get_token(actor_id, token_id)
    ps[:pre] || []
  end
  #--------------------------------------------------------------------------
  # ● 获取指定id的帮助文本
  #--------------------------------------------------------------------------
  def self.get_token_help(actor_id, token_id)
    skill_id = get_token_skill(actor_id, token_id)
    t = ""
    if skill_id
      skill = $data_skills[skill_id]
      t += "\\i[#{skill.icon_index}]#{skill.name}\n"
      t += "#{skill.description}\n"
    end
    ps = get_token(actor_id, token_id)
    if ps[:help]
      t += ps[:help] + "\n"
    end
    if !unlock?(token_id)
      t += "<消耗 #{get_token_sp(actor_id, token_id)} 点SP解锁>\n"
    end
    t
  end
  #--------------------------------------------------------------------------
  # ● 指定id已经解锁？
  #--------------------------------------------------------------------------
  def self.unlock?(token_id)
    $game_actors[@actor_id].eagle_skill_learn.unlock?(token_id)
  end
  #--------------------------------------------------------------------------
  # ● eval
  #--------------------------------------------------------------------------
  def self.eagle_eval(str)
    s = $game_switches
    v = $game_variables
    eval(str)
  end
  #--------------------------------------------------------------------------
  # ● 绘制图标
  #--------------------------------------------------------------------------
  def self.draw_icon(bitmap, icon, x, y, w=24, h=24)
    _bitmap = Cache.system("Iconset")
    rect = Rect.new(icon % 16 * 24, icon / 16 * 24, 24, 24)
    bitmap.blt(x+w/2-12, y+h/2-12, _bitmap, rect, 255)
  end
end

#==============================================================================
# ■ UI
#==============================================================================
class << SKILL_LEARN
  #--------------------------------------------------------------------------
  # ● UI-开启
  #--------------------------------------------------------------------------
  def call
    init_ui
    begin
      update_ui
    rescue
   	  p $!
   	ensure
   	  dispose_ui
   	end
  end
  #--------------------------------------------------------------------------
  # ● UI-结束并释放
  #--------------------------------------------------------------------------
  def dispose_ui
    instance_variables.each do |varname|
      ivar = instance_variable_get(varname)
      if ivar.is_a?(Sprite)
        ivar.bitmap.dispose if ivar.bitmap
        ivar.dispose
      end
    end
  	@sprites_token.each { |id, s| s.dispose }
  	@viewport_bg.dispose
  end
  #--------------------------------------------------------------------------
  # ● UI-最大的横纵像素数
  #--------------------------------------------------------------------------
  def ui_max_x
    SKILL_LEARN::GRID_W * SKILL_LEARN::GRID_MAX_X
  end
  def ui_max_y
    SKILL_LEARN::GRID_H * SKILL_LEARN::GRID_MAX_Y
  end
  #--------------------------------------------------------------------------
  # ● UI-初始化
  #--------------------------------------------------------------------------
  def init_ui
    # 暗色背景
    @sprite_bg = Sprite.new
    @sprite_bg.z = 200
    set_sprite_bg(@sprite_bg)

    # 背景字
    @sprite_bg_info = Sprite.new
    @sprite_bg_info.z = @sprite_bg.z + 1
    set_sprite_info(@sprite_bg_info)

    # 底部按键提示
    @sprite_hint = Sprite.new
    @sprite_hint.z = @sprite_bg.z + 20
    set_sprite_hint(@sprite_hint)

    # 视图
    @viewport_bg = Viewport.new(0,0,Graphics.width,Graphics.height-24)
    @viewport_bg.z = @sprite_bg.z + 10

    # 网格背景
    @sprite_grid = Sprite.new(@viewport_bg)
    @sprite_grid.z = 1
    w = ui_max_x; h = ui_max_y
    @sprite_grid.bitmap = Bitmap.new(w, h)
    _x = 0; _y = 0; c = Color.new(255,255,255, 20)
    loop do
      _x += SKILL_LEARN::GRID_W
      break if _x >= w
      @sprite_grid.bitmap.fill_rect(_x, 0, 1, h, c)
    end
    loop do
      _y += SKILL_LEARN::GRID_H
      break if _y >= h
      @sprite_grid.bitmap.fill_rect(0, _y, w, 1, c)
    end

    # 背景连线
    @sprite_lines = Sprite.new(@viewport_bg)
    @sprite_lines.z = @sprite_grid.z + 10

    # 光标
    @sprite_player = Sprite_SkillLearn_Player.new(@viewport_bg)
    @sprite_player.z = @sprite_grid.z + 100
    @params_player = { :last_input => nil, :last_input_c => 0, :d => 1 }

    # 重置当前角色的全部技能
    actor_id = 1
    reset_actor(actor_id)

    # 说明文本
    @sprite_help = Sprite_SkillLearn_TokenHelp.new
    @sprite_help.z = @sprite_hint.z + 1

    # sp数
    @sprite_sp = Sprite.new
    @sprite_sp.z = @sprite_hint.z
    @sprite_sp.bitmap = Bitmap.new(100, 24)
    redraw_sp
  end
  #--------------------------------------------------------------------------
  # ● 设置背景精灵
  #--------------------------------------------------------------------------
  def set_sprite_bg(sprite)
    sprite.bitmap = Bitmap.new(Graphics.width, Graphics.height)
    sprite.bitmap.fill_rect(0, 0, sprite.width, sprite.height,
      Color.new(0,0,0,200))
  end
  #--------------------------------------------------------------------------
  # ● 设置LOG标题精灵
  #--------------------------------------------------------------------------
  def set_sprite_info(sprite)
    sprite.zoom_x = sprite.zoom_y = 3.0
    sprite.bitmap = Bitmap.new(Graphics.height, Graphics.height)
    sprite.bitmap.font.size = 48
    sprite.bitmap.font.color = Color.new(255,255,255,10)
    sprite.bitmap.draw_text(0,0,sprite.width,64, "SKILLS", 0)
    sprite.angle = -90
    sprite.x = Graphics.width + 48
    sprite.y = 0
  end
  #--------------------------------------------------------------------------
  # ● 设置按键提示精灵
  #--------------------------------------------------------------------------
  def set_sprite_hint(sprite)
    sprite.bitmap = Bitmap.new(Graphics.width, 24)
    sprite.bitmap.font.size = SKILL_LEARN::HINT_FONT_SIZE
    redraw_hint(sprite)
    sprite.oy = sprite.height
    sprite.y = Graphics.height
  end
  #--------------------------------------------------------------------------
  # ● 重绘按键提示
  #--------------------------------------------------------------------------
  def redraw_hint(sprite)
	  t = "方向键 - 移动 | "
    if @selected_token && !SKILL_LEARN.unlock?(@selected_token.id)
      t += "确定键 - 解锁 | "
    end
    t += "取消键 - 退出"
    sprite.bitmap.clear
    sprite.bitmap.draw_text(0, 2, sprite.width, sprite.height, t, 1)
    sprite.bitmap.fill_rect(0, 0, sprite.width, 1,
      Color.new(255,255,255,120))
  end
  #--------------------------------------------------------------------------
  # ● 重置当前角色
  #--------------------------------------------------------------------------
  def reset_actor(actor_id)
    @actor_id = actor_id
	  redraw_tokens
	  redraw_lines
	  @viewport_bg.ox = 0
	  @viewport_bg.oy = 0
  end
  #--------------------------------------------------------------------------
  # ● 重绘全部技能技能
  #--------------------------------------------------------------------------
  def redraw_tokens
    @selected_token = nil # 当前选中的技能token精灵
	  @sprites_token ||= {}
   	@sprites_token.each { |id, s| s.dispose }
	  @sprites_token.clear

	  tokens = SKILL_LEARN.get_tokens(@actor_id)
	  tokens.each do |id, ps|
	    next if ps[:if] && SKILL_LEARN.eagle_eval(ps[:if]) != true
	    s = Sprite_SkillLearn_Token.new(@viewport_bg, @actor_id, id, ps)
      s.z = @sprite_grid.z + 20
      @sprites_token[id] = s
	  end
  end
  #--------------------------------------------------------------------------
  # ● 重绘背景连线
  #--------------------------------------------------------------------------
  def redraw_lines
	  @sprite_lines.bitmap = Bitmap.new(ui_max_x, ui_max_y)
    @sprite_lines.bitmap.clear
	  @sprites_token.each do |id, s1|
      pres = SKILL_LEARN.get_token_pre(@actor_id, id)
      pres.each do |id2|
        s2 = @sprites_token[id2]
        next if s2 == nil
        # 绘制从s1到s2的直线
        c = Color.new(255,255,255)
        c.alpha = 150
        t = SKILL_LEARN.unlock?(id2) ? "1" : "0011"
        EAGLE.DDALine(@sprite_lines.bitmap, s1.x,s1.y, s2.x, s2.y, 1, t, c)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 重绘SP
  #--------------------------------------------------------------------------
  def redraw_sp
    data = $game_actors[@actor_id].eagle_skill_learn
    sp = data.sp
    sp_all = data.sp_all
    @sprite_sp.bitmap.clear
    @sprite_sp.bitmap.draw_text(0,0,@sprite_sp.width,@sprite_sp.height,
      "SP: #{sp} / #{sp_all}", 0)
  end
  #--------------------------------------------------------------------------
  # ● UI-更新
  #--------------------------------------------------------------------------
  def update_ui
    loop do
  	  update_basic
      update_player
  	  update_key
  	  break if finish_ui?
  	end
  end
  #--------------------------------------------------------------------------
  # ● UI-基础更新
  #--------------------------------------------------------------------------
  def update_basic
    Graphics.update
    Input.update
  end
  #--------------------------------------------------------------------------
  # ● UI-退出？
  #--------------------------------------------------------------------------
  def finish_ui?
    Input.trigger?(:B)
  end
  #--------------------------------------------------------------------------
  # ● UI-更新光标
  #--------------------------------------------------------------------------
  def update_player
    # 更新移动
    s = @sprite_player
    if @params_player[:last_input] == Input.dir4
      @params_player[:last_input_c] += 1
      @params_player[:d] += 1 if @params_player[:last_input_c] % 5 == 0
    else
      @params_player[:d] = 1
      @params_player[:last_input] = Input.dir4
      @params_player[:last_input_c] = 0
    end
    d = @params_player[:d]
    if Input.press?(:UP)
      s.y -= d
      s.y = s.oy if s.y - s.oy < 0
    elsif Input.press?(:DOWN)
      s.y += d
      s.y = ui_max_y - s.height + s.oy if s.y - s.oy + s.height > ui_max_y
    elsif Input.press?(:LEFT)
      s.x -= d
      s.x = s.ox if s.x - s.ox < 0
    elsif Input.press?(:RIGHT)
      s.x += d
      s.x = ui_max_x - s.width + s.ox if s.x - s.ox + s.width > ui_max_x
    end

    # 检查显示区域
    vp = @viewport_bg
    if s.x - s.ox - vp.ox < 0
      vp.ox = s.x - s.ox
    elsif s.x - s.ox + s.width - vp.ox > vp.rect.width
      vp.ox = s.x - s.ox + s.width - vp.rect.width
    end
    if s.y - s.oy - vp.oy < 0
      vp.oy = s.y - s.oy
    elsif s.y - s.oy + s.height - vp.oy > vp.rect.height
      vp.oy = s.y - s.oy + s.height - vp.rect.height
    end

    # 更新是否有选中的token
    if @selected_token && @selected_token.overlap?(s)
      # 之前的还是被选中的状态
    else
      @selected_token = nil
      @sprites_token.each do |id, st|
        break @selected_token = st if st.overlap?(s)
      end
      if @selected_token
        @sprite_help.redraw(@selected_token)
        redraw_hint(@sprite_hint)
      else
        redraw_hint(@sprite_hint) if @sprite_help.visible
        @sprite_help.visible = false
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● UI-更新解锁
  #--------------------------------------------------------------------------
  def update_key
    if @selected_token && Input.trigger?(:C)
      data = $game_actors[@actor_id].eagle_skill_learn
      id = @selected_token.id
	    if !data.unlock?(id)
        if data.can_unlock?(id)
          data.unlock(id)
        else
          Sound.play_buzzer
        end
      end
      refresh
    end

    # 测试用
    data = $game_actors[@actor_id].eagle_skill_learn
    if Input.trigger?(:A)
      data.add_sp(1)
      redraw_sp
    end
  end
  #--------------------------------------------------------------------------
  # ● 解锁后重绘
  #--------------------------------------------------------------------------
  def refresh
    @selected_token.refresh
    redraw_lines
    redraw_sp
    redraw_hint(@sprite_hint)
    @sprite_help.redraw(@selected_token)
  end
end

#==============================================================================
# ■ 玩家光标精灵
#==============================================================================
class Sprite_SkillLearn_Player < Sprite
  include SKILL_LEARN
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(vp)
    super(vp)
  	reset_bitmap
  	reset_position
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    self.bitmap.dispose
    super
  end
  #--------------------------------------------------------------------------
  # ● 重绘位图
  #--------------------------------------------------------------------------
  def reset_bitmap
    self.bitmap = Bitmap.new(GRID_W, GRID_H)
	  self.bitmap.fill_rect(0, 0, GRID_W, GRID_H, Color.new(255,255,255,200))
    self.bitmap.clear_rect(2, 2, GRID_W-4, GRID_H-4)
  end
  #--------------------------------------------------------------------------
  # ● 重置位置
  #--------------------------------------------------------------------------
  def reset_position
	  self.ox = self.width / 2
    self.oy = self.height / 2
  	self.x = Graphics.width / 2 + self.ox
  	self.y = Graphics.height / 2 + self.oy
  end
end

#==============================================================================
# ■ 技能精灵
#==============================================================================
class Sprite_SkillLearn_Token < Sprite
  attr_reader :actor_id, :id
  include SKILL_LEARN
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(vp, actor_id, token_id, ps)
    super(vp)
    @actor_id = actor_id
    @id = token_id
  	reset_bitmap
  	reset_position(ps[:pos][0], ps[:pos][1])
    refresh
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    self.bitmap.dispose
    super
  end
  #--------------------------------------------------------------------------
  # ● 重绘
  #--------------------------------------------------------------------------
  def reset_bitmap
    skill_id = SKILL_LEARN.get_token_skill(@actor_id, @id)
    if skill_id
      self.bitmap = Bitmap.new(GRID_W, GRID_H)
	    icon = $data_skills[skill_id].icon_index
	    SKILL_LEARN.draw_icon(self.bitmap, icon, 0, 0, self.width, self.height)
	  end
  end
  #--------------------------------------------------------------------------
  # ● 重置位置
  #--------------------------------------------------------------------------
  def reset_position(grid_x, grid_y)
    self.ox = self.width / 2
    self.oy = self.height / 2
    self.x = GRID_W * grid_x + self.ox
    self.y = GRID_H * grid_y + self.oy
  end
  #--------------------------------------------------------------------------
  # ● 刷新（解锁后调用）
  #--------------------------------------------------------------------------
  def refresh
    self.color = Color.new(0,0,0,0)
    if !SKILL_LEARN.unlock?(@id)
	    self.color = Color.new(0,0,0,120)
    end
  end
  #--------------------------------------------------------------------------
  # ● 指定sprite位于当前精灵上？
  #--------------------------------------------------------------------------
  def overlap?(sprite)
    pos_x = sprite.x - sprite.ox + sprite.width / 2
    pos_y = sprite.y - sprite.oy + sprite.height / 2
    return false if pos_x < self.x - self.ox
    return false if pos_y < self.y - self.oy
    return false if pos_x > self.x - self.ox + self.width
	  return false if pos_y > self.y - self.oy + self.height
	  return true
  end
end

#==============================================================================
# ■ 技能帮助文本精灵
#==============================================================================
class Sprite_SkillLearn_TokenHelp < Sprite
  # 帮助文本的字体大小
  FONT_SIZE = 16
  # 帮助窗口的空白边框宽度
  TEXT_BORDER_WIDTH = 12
  #--------------------------------------------------------------------------
  # ● 重绘
  #--------------------------------------------------------------------------
  def redraw(s)
    self.bitmap.dispose if self.bitmap
    self.bitmap = nil

    text = SKILL_LEARN.get_token_help(s.actor_id, s.id)
    return if text == ""

    ps = { :font_size => FONT_SIZE, :x0 => 0, :y0 => 0, :lhd => 2 }
    d = Process_DrawTextEX.new(text, ps)
    d.run(false)

    w = d.width + TEXT_BORDER_WIDTH * 2
    h = d.height + TEXT_BORDER_WIDTH * 2
    self.bitmap = Bitmap.new(w, h)

    skin = "Window"
    EAGLE.draw_windowskin(skin, self.bitmap,
      Rect.new(0, 0, self.width, self.height))

    ps[:x0] = TEXT_BORDER_WIDTH
    ps[:y0] = TEXT_BORDER_WIDTH
    d.bind_bitmap(self.bitmap)
    d.run(true)

    self.visible = true
    self.ox = self.width / 2
    self.x = Graphics.width / 2
    if s.y - s.viewport.oy > Graphics.height / 2
      self.oy = 0
      self.y = 30
    else
      self.oy = self.height
      self.y = Graphics.height - 30
    end
  end
end

#==============================================================================
# ■ 数据类
#==============================================================================
class Data_SkillLearn
  attr_reader :sp, :sp_all
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(actor_id)
    @actor_id = actor_id
    @unlocks = [] # 已经解锁的token的id
    @sp = 0  # 当前技能点数目
	  @sp_all = 0  # 全部技能点数目（用于重置）
	  @skill_ids = []  # 已经解锁的技能的ID
  end
  #--------------------------------------------------------------------------
  # ● 增加sp
  #--------------------------------------------------------------------------
  def add_sp(v)
    @sp += v
    @sp_all += v
  end
  #--------------------------------------------------------------------------
  # ● 重置
  #--------------------------------------------------------------------------
  def reset
    @unlocks.clear
    @sp = @sp_all
	  @skill_ids.clear
  end
  #--------------------------------------------------------------------------
  # ● 解锁指定id
  #--------------------------------------------------------------------------
  def unlock(token_id)
    @unlocks.push(token_id)
    @sp -= SKILL_LEARN.get_token_sp(@actor_id, token_id)
    skill_id = SKILL_LEARN.get_token_skill(@actor_id, token_id)
    @skill_ids.push(skill_id)
  end
  #--------------------------------------------------------------------------
  # ● 指定id已经解锁？
  #--------------------------------------------------------------------------
  def unlock?(token_id)
    @unlocks.include?(token_id)
  end
  #--------------------------------------------------------------------------
  # ● 指定id能够解锁？
  #--------------------------------------------------------------------------
  def can_unlock?(token_id)
    pres = SKILL_LEARN.get_token_pre(@actor_id, token_id)
    pres.each do |id|
      return false if !unlock?(id)
    end
    @sp >= SKILL_LEARN.get_token_sp(@actor_id, token_id)
  end
  #--------------------------------------------------------------------------
  # ● 获取已经解锁的技能
  #--------------------------------------------------------------------------
  def skills
    @skill_ids
  end
end

#==============================================================================
# ■ Game_Actor
#==============================================================================
class Game_Actor
  attr_reader :eagle_skill_learn
  #--------------------------------------------------------------------------
  # ● 初始化技能
  #--------------------------------------------------------------------------
  alias eagle_skilllearn_init_skills init_skills
  def init_skills
    eagle_skilllearn_init_skills
    @eagle_skill_learn = Data_SkillLearn.new(@actor_id)
  end
  #--------------------------------------------------------------------------
  # ● 获取添加的技能
  #--------------------------------------------------------------------------
  def added_skills
    super | @eagle_skill_learn.skills
  end
end


class Scene_Map
  #--------------------------------------------------------------------------
  # ● 监听取消键的按下。如果菜单可用且地图上没有事件在运行，则打开菜单界面。
  #--------------------------------------------------------------------------
  alias eagle_update_call_menu update_call_menu
  def update_call_menu
    eagle_update_call_menu
    SKILL_LEARN.call if Input.trigger?(:A)
  end
end
