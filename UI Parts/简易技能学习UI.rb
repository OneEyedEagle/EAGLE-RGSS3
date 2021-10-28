# 简易能力解锁系统
#  （仿霓虹深渊）

# TODO

module ABILITY_LEARN
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

=begin
ACTORS[角色ID] = {
  1 => {  # 该能力的唯一ID
    :skill => 1,  # 所绑定的技能ID（覆盖 :icon 与 :pic）
    :sp => 1,  # 解锁一次需要消耗的能力点数
    :pos => [1, 1],  # 在界面中的位置（格子坐标）
    :help => "",  # 追加的说明文本（显示在帮助窗口里）
    :level => 1, # 最大层数
    :params => "mhp=1",  # 附加的属性
    :pre => [1],  # 前置需求（能力的唯一ID，可重复，代表层数需求）
    :if => "" , # eval后返回true时，才显示该能力
    :icon => 1,  # 所显示的图标（覆盖 :pic）
    :pic => "", # 所显示的图片
    :eval_on => "",  # 解锁时执行的脚本
    :eval_off => "", # 重置时执行的脚本
  }
},
=end

  ACTORS[1] = {
    1 => {
      :skill => 1,
      :sp => 1,
      :pos => [5, 2],
    },
    2 => {
      :icon => 128,
      :sp => 1,
      :pos => [3, 4],
      :pre => [1],
      :params => "atk=1",
      :level => 10,
    },
    3 => {
      :icon => 139,
      :sp => 1,
      :pos => [7, 4],
      :pre => [1],
      :params => "def=1",
      :level => 10,
    },
    4 => {
      :skill => 10,
      :sp => 1,
      :pos => [5, 6],
      :pre => [2,2,2, 3,3,3],
      :help => "",
    },
  }

  # 所有角色共有的
  ALL_ACTORS = {
    "reset" => {
      :icon => 117,
      :pos => [1, 1],
      :help => "重置全部能力。",
      :eval_on => "ABILITY_LEARN.reset",
    },
  }

  #--------------------------------------------------------------------------
  # ○ 常量：基础属性与对应ID
  #--------------------------------------------------------------------------
  PARAMS_TO_ID = {
    :mhp => 0, :mmp => 1, :atk => 2, :def => 3,
    :mat => 4, :mdf => 5, :agi => 6, :luk => 7,
  }

  #--------------------------------------------------------------------------
  # ● 获取指定角色的全部数据
  #--------------------------------------------------------------------------
  def self.get_tokens(actor_id)
    ACTORS[actor_id]
  end
  def self.get_tokens_all
    ALL_ACTORS
  end
  #--------------------------------------------------------------------------
  # ● 获取指定角色的指定id的数据
  #--------------------------------------------------------------------------
  def self.get_token(actor_id, token_id)
    ACTORS[actor_id][token_id] || ALL_ACTORS[token_id]
  end
  #--------------------------------------------------------------------------
  # ● 获取指定id的对应技能
  #--------------------------------------------------------------------------
  def self.get_token_skill(actor_id, token_id)
    ps = get_token(actor_id, token_id)
    ps[:skill] || nil
  end
  #--------------------------------------------------------------------------
  # ● 获取指定id的属性值Hash（利用paras_params进行解析）
  #--------------------------------------------------------------------------
  def self.get_token_params(actor_id, token_id)
    ps = get_token(actor_id, token_id)
    str = ps[:params]
    if str
      hash = ABILITY_LEARN.parse_params(str)
      return hash
    end
    return {}
  end
  #--------------------------------------------------------------------------
  # ● 获取指定id的sp消耗量
  #--------------------------------------------------------------------------
  def self.get_token_sp(actor_id, token_id)
    ps = get_token(actor_id, token_id)
    ps[:sp] || 0
  end
  #--------------------------------------------------------------------------
  # ● 获取指定id的前置id们
  #--------------------------------------------------------------------------
  def self.get_token_pre(actor_id, token_id)
    ps = get_token(actor_id, token_id)
    ps[:pre] || []
  end
  #--------------------------------------------------------------------------
  # ● 获取指定id的对应图标/图片bitmap
  #--------------------------------------------------------------------------
  def self.get_token_icon(actor_id, token_id)
    ps = get_token(actor_id, token_id)
    ps[:icon] || nil
  end
  def self.get_token_pic(actor_id, token_id)
    ps = get_token(actor_id, token_id)
    b = Cache.system(ps[:pic]) rescue nil
    b
  end
  #--------------------------------------------------------------------------
  # ● 获取指定id的on/off时的触发脚本
  #--------------------------------------------------------------------------
  def self.get_token_eval_on(actor_id, token_id)
    ps = get_token(actor_id, token_id)
    ps[:eval_on] || nil
  end
  def self.get_token_eval_off(actor_id, token_id)
    ps = get_token(actor_id, token_id)
    ps[:eval_off] || nil
  end
  #--------------------------------------------------------------------------
  # ● 获取指定id是否可以再次解锁
  #--------------------------------------------------------------------------
  def self.get_token_level(actor_id, token_id)
    ps = get_token(actor_id, token_id)
    ps[:level] || 1
  end
  #--------------------------------------------------------------------------
  # ● 获取指定id的帮助文本
  #--------------------------------------------------------------------------
  def self.get_token_help(actor_id, token_id)
    data = $game_actors[@actor_id].eagle_ability_data
    t = ""

    skill_id = get_token_skill(actor_id, token_id)
    if skill_id
      skill = $data_skills[skill_id]
      t += "\\i[#{skill.icon_index}]#{skill.name}\n"
      t += "#{skill.description}\n"
    end

    params_hash = get_token_params(actor_id, token_id)
    if !params_hash.empty?
      params_hash.each do |sym, v|
        param_id = ABILITY_LEARN::PARAMS_TO_ID[sym]
        _v = v.to_i
        if param_id && _v != 0
          t += Vocab.param(param_id) + (_v > 0 ? "+#{_v}" : "-#{_v.abs}") + " "
        end
      end
      t += "\n"
    end

    ps = get_token(actor_id, token_id)
    t += ps[:help] + "\n" if ps[:help]

    v = get_token_sp(actor_id, token_id)
    if !unlock?(token_id)
      t += "<消耗 #{v} 点SP解锁>\n" if v > 0
    else
      level_max = get_token_level(actor_id, token_id)
      if level_max > 1 && data.level(token_id) < level_max
        t += "<消耗 #{v} 点SP继续解锁>\n"
      else
        t += "<已完全解锁>\n"
      end
    end

    return t
  end

  #--------------------------------------------------------------------------
  # ● 解析tags文本
  #--------------------------------------------------------------------------
  def self.parse_params(_t)
    # 处理等号左右的空格
    _t.gsub!( / *= */ ) { '=' }
    # tag 拆分
    _ts = _t.split(/ | /)
    # tag 解析
    _hash = {}
    _ts.each do |_tag|  # _tag = "xxx=xxx"
      _tags = _tag.split('=')
      _k = _tags[0].downcase
      _v = _tags[1]
      _hash[_k.to_sym] = _v
    end
    return _hash
  end
  #--------------------------------------------------------------------------
  # ● 绘制图标
  #--------------------------------------------------------------------------
  def self.draw_icon(bitmap, icon, x, y, w=24, h=24)
    _bitmap = Cache.system("Iconset")
    rect = Rect.new(icon % 16 * 24, icon / 16 * 24, 24, 24)
    bitmap.blt(x+w/2-12, y+h/2-12, _bitmap, rect, 255)
  end
  #--------------------------------------------------------------------------
  # ● 绘制人物行走图
  #  (x, y) 为行走图放置位置的底部中心点的位置
  #--------------------------------------------------------------------------
  def self.draw_character(bitmap, character_name, character_index, x, y)
    return unless character_name
    _bitmap = Cache.character(character_name)
    sign = character_name[/^[\!\$]./]
    if sign && sign.include?('$')
      cw = _bitmap.width / 3
      ch = _bitmap.height / 4
    else
      cw = _bitmap.width / 12
      ch = _bitmap.height / 8
    end
    n = character_index
    src_rect = Rect.new((n%4*3+1)*cw, (n/4*4)*ch, cw, ch)
    bitmap.blt(x - cw / 2, y - ch, _bitmap, src_rect)
    return cw, ch
  end
  #--------------------------------------------------------------------------
  # ● 重置解锁
  #--------------------------------------------------------------------------
  def self.reset
    actor = $game_actors[@actor_id]
    data = actor.eagle_ability_data
    data.reset
    reset_actor(@actor_id) if @flag_ui
  end
  #--------------------------------------------------------------------------
  # ● 指定id已经解锁？
  #--------------------------------------------------------------------------
  def self.unlock?(token_id)
    $game_actors[@actor_id].eagle_ability_data.unlock?(token_id)
  end
  #--------------------------------------------------------------------------
  # ● 指定id允许再次解锁？
  #--------------------------------------------------------------------------
  def self.repeat?(token_id)
    return false if !unlock?(token_id)
    f = get_token_level(@actor_id, token_id)
    return false if f <= 0
    return false if f <= level(token_id)
    return true
  end
  #--------------------------------------------------------------------------
  # ● 指定id的解锁层数
  #--------------------------------------------------------------------------
  def self.level(token_id)
    return $game_actors[@actor_id].eagle_ability_data.level(token_id)
  end
  #--------------------------------------------------------------------------
  # ● eval
  #--------------------------------------------------------------------------
  def self.eagle_eval(str, actor_id = 0)
    s = $game_switches
    v = $game_variables
    actor = $game_actors[actor_id] rescue nil
    begin
      eval(str)
    rescue
      p $!
    end
  end
end

#==============================================================================
# ■ UI
#==============================================================================
class << ABILITY_LEARN
  #--------------------------------------------------------------------------
  # ● UI-开启
  #--------------------------------------------------------------------------
  def call
    @flag_ui = true
    init_ui
    begin
      update_ui
    rescue
      p $!
    ensure
      dispose_ui
    end
    @flag_ui = false
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
    ABILITY_LEARN::GRID_W * ABILITY_LEARN::GRID_MAX_X
  end
  def ui_max_y
    ABILITY_LEARN::GRID_H * ABILITY_LEARN::GRID_MAX_Y
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
      _x += ABILITY_LEARN::GRID_W
      break if _x >= w
      @sprite_grid.bitmap.fill_rect(_x, 0, 1, h, c)
    end
    loop do
      _y += ABILITY_LEARN::GRID_H
      break if _y >= h
      @sprite_grid.bitmap.fill_rect(0, _y, w, 1, c)
    end

    # 背景连线
    @sprite_lines = Sprite.new(@viewport_bg)
    @sprite_lines.z = @sprite_grid.z + 10
    @sprite_lines.bitmap = Bitmap.new(ui_max_x, ui_max_y)

    # 光标
    @sprite_player = Sprite_AbilityLearn_Player.new(@viewport_bg)
    @sprite_player.z = @sprite_grid.z + 100
    @params_player = { :last_input => nil, :last_input_c => 0, :d => 1 }

    # 全部能力
    @sprites_token ||= {}

    # 角色信息文本
    @sprite_actor_info = Sprite_AbilityLearn_ActorInfo.new
    @sprite_actor_info.z = @sprite_hint.z + 1

    # 说明文本
    @sprite_help = Sprite_AbilityLearn_TokenHelp.new
    @sprite_help.z = @sprite_hint.z + 2

    # 重置当前角色
    @actor = $game_party.menu_actor
    reset_actor(@actor.id)
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
    sprite.bitmap.draw_text(0,0,sprite.width,64, "ABILITY", 0)
    sprite.angle = -90
    sprite.x = Graphics.width + 48
    sprite.y = 0
  end
  #--------------------------------------------------------------------------
  # ● 设置按键提示精灵
  #--------------------------------------------------------------------------
  def set_sprite_hint(sprite)
    sprite.bitmap = Bitmap.new(Graphics.width, 24)
    sprite.bitmap.font.size = ABILITY_LEARN::HINT_FONT_SIZE
    redraw_hint(sprite)
    sprite.oy = sprite.height
    sprite.y = Graphics.height
  end
  #--------------------------------------------------------------------------
  # ● 重绘按键提示
  #--------------------------------------------------------------------------
  def redraw_hint(sprite)
    t = "方向键 - 移动 | "
    if @selected_token
      if !ABILITY_LEARN.unlock?(@selected_token.id)
        t += "确定键 - 解锁 | "
      elsif ABILITY_LEARN.repeat?(@selected_token.id)
        t += "确定键 - 再次解锁 | "
      end
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
    @sprite_actor_info.set_actor(@actor_id)
    @viewport_bg.ox = 0
    @viewport_bg.oy = 0
  end
  #--------------------------------------------------------------------------
  # ● 重绘全部能力
  #--------------------------------------------------------------------------
  def redraw_tokens
    @selected_token = nil # 当前选中的能力token精灵
    @sprites_token.each { |id, s| s.dispose }
    @sprites_token.clear

    tokens = ABILITY_LEARN.get_tokens(@actor_id)
    tokens.merge(ABILITY_LEARN.get_tokens_all).each do |id, ps|
      next if ps[:if] && ABILITY_LEARN.eagle_eval(ps[:if], @actor_id) != true
      s = Sprite_AbilityLearn_Token.new(@viewport_bg, @actor_id, id, ps)
      s.z = @sprite_grid.z + 20
      @sprites_token[id] = s
    end
  end
  #--------------------------------------------------------------------------
  # ● 重绘背景连线
  #--------------------------------------------------------------------------
  def redraw_lines
    @sprite_lines.bitmap.clear
    @sprites_token.each do |id, s1|
      f = ABILITY_LEARN.unlock?(id)
      pres = ABILITY_LEARN.get_token_pre(@actor_id, id)
      pres.each do |id2|
        s2 = @sprites_token[id2]
        next if s2 == nil
        # 绘制从s1到s2的直线
        c = Color.new(255,255,255)
        c.alpha = 150
        t = f && ABILITY_LEARN.unlock?(id2) ? "1" : "0011"
        EAGLE.DDALine(@sprite_lines.bitmap, s1.x,s1.y, s2.x, s2.y, 1, t, c)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 重绘当前角色的信息
  #--------------------------------------------------------------------------
  def redraw_actor_info
    @sprite_actor_info.refresh
  end
  #--------------------------------------------------------------------------
  # ● UI-更新
  #--------------------------------------------------------------------------
  def update_ui
    loop do
      update_basic
      update_player
      update_unlock
      update_actors
      break if finish_ui?
      update_test if $TEST
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
      if @selected_token # 选中
        @sprite_help.redraw(@selected_token)
        redraw_hint(@sprite_hint)
      elsif @sprite_help.visible  # 从选中变成没有选中任何能力
        redraw_hint(@sprite_hint)
        @sprite_help.visible = false
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● UI-更新解锁
  #--------------------------------------------------------------------------
  def update_unlock
    if @selected_token && Input.trigger?(:C)
      data = $game_actors[@actor_id].eagle_ability_data
      id = @selected_token.id
      if data.can_unlock?(id)
        data.unlock(id)
        refresh
      else
        Sound.play_buzzer
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 解锁后重绘
  #--------------------------------------------------------------------------
  def refresh
    if @selected_token
      @selected_token.refresh
      @sprite_help.redraw(@selected_token)
    end
    redraw_lines
    redraw_actor_info
    redraw_hint(@sprite_hint)
  end
  #--------------------------------------------------------------------------
  # ● UI-更新角色切换
  #--------------------------------------------------------------------------
  def update_actors
    if Input.trigger?(:R)  # pagedown 下一个角色
      @actor = $game_party.menu_actor_next
      reset_actor(@actor.id)
    elsif Input.trigger?(:L)  # pageup 上一个角色
      @actor = $game_party.menu_actor_prev
      reset_actor(@actor.id)
    end
  end
  #--------------------------------------------------------------------------
  # ● UI-测试用
  #--------------------------------------------------------------------------
  def update_test
    data = $game_actors[@actor_id].eagle_ability_data
    if Input.trigger?(:A)
      data.add_sp(1)
      redraw_actor_info
    end
  end
end

#==============================================================================
# ■ 玩家光标精灵
#==============================================================================
class Sprite_AbilityLearn_Player < Sprite
  include ABILITY_LEARN
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
# ■ 角色信息精灵
#==============================================================================
class Sprite_AbilityLearn_ActorInfo < Sprite
  # 帮助文本的字体大小
  FONT_SIZE = 16

  include ABILITY_LEARN
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(vp = nil)
    super(vp)
    self.bitmap = Bitmap.new(200, 64)
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    self.bitmap.dispose
    super
  end
  #--------------------------------------------------------------------------
  # ● 设置角色
  #--------------------------------------------------------------------------
  def set_actor(actor_id)
    @actor_id = actor_id
    refresh
    reset_position
  end
  #--------------------------------------------------------------------------
  # ● 刷新
  #--------------------------------------------------------------------------
  def refresh
    self.bitmap.clear
    actor = $game_actors[@actor_id]
    data = actor.eagle_ability_data
    sp = data.sp
    sp_all = data.sp_all
    t = "#{actor.name}\nSP #{sp} / #{sp_all}"

    cw, ch = ABILITY_LEARN.draw_character(self.bitmap, actor.character_name,
      actor.character_index, 16, self.height - 2)

    ps = { :font_size => FONT_SIZE, :x0 => 32+10, :y0 => 0, :lhd => 2 }
    d = Process_DrawTextEX.new(t, ps, self.bitmap)
    d.run(false)
    ps[:y0] = self.height - d.height
    d.run(true)
  end
  #--------------------------------------------------------------------------
  # ● 重置位置
  #--------------------------------------------------------------------------
  def reset_position
    self.x = 10
    self.y = Graphics.height - 30 - self.height
  end
end

#==============================================================================
# ■ 能力精灵
#==============================================================================
class Sprite_AbilityLearn_Token < Sprite
  attr_reader :actor_id, :id
  include ABILITY_LEARN
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(vp, actor_id, token_id, ps)
    super(vp)
    @actor_id = actor_id
    @id = token_id
    refresh
    reset_position(ps[:pos][0], ps[:pos][1])
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    self.bitmap.dispose
    super
  end
  #--------------------------------------------------------------------------
  # ● 刷新（解锁后调用）
  #--------------------------------------------------------------------------
  def refresh
    reset_bitmap
    draw_level
    self.color = Color.new(0,0,0,0)
    if ABILITY_LEARN.get_token_sp(@actor_id, @id) > 0 && !ABILITY_LEARN.unlock?(@id)
      self.color = Color.new(0,0,0,120)
    end
  end
  #--------------------------------------------------------------------------
  # ● 重设位图
  #--------------------------------------------------------------------------
  def reset_bitmap
    skill_id = ABILITY_LEARN.get_token_skill(@actor_id, @id)
    return redraw($data_skills[skill_id].icon_index) if skill_id
    icon = ABILITY_LEARN.get_token_icon(@actor_id, @id)
    return redraw(icon) if icon
    pic_bitmap = ABILITY_LEARN.get_token_pic(@actor_id, @id)
    return redraw(nil, pic_bitmap) if pic_bitmap
    redraw(1)
  end
  #--------------------------------------------------------------------------
  # ● 重绘
  #--------------------------------------------------------------------------
  def redraw(icon = nil, pic_bitmap = nil)
    if icon
      if self.bitmap && (self.width != GRID_W || self.height != GRID_H)
        self.bitmap.dispose
        self.bitmap = nil
      end
      self.bitmap ||= Bitmap.new(GRID_W, GRID_H)
      self.bitmap.clear
      ABILITY_LEARN.draw_icon(self.bitmap, icon, 0, 0, self.width, self.height)
      return
    end
    if pic_bitmap
      self.bitmap.dispose if self.bitmap
      self.bitmap = pic_bitmap.dup
      return
    end
  end
  #--------------------------------------------------------------------------
  # ● 绘制层数
  #--------------------------------------------------------------------------
  def draw_level
    f = ABILITY_LEARN.get_token_level(@actor_id, @id)
    return if f <= 1
    level = ABILITY_LEARN.level(@id)
    return if level <= 0
    self.bitmap.font.size = 14
    self.bitmap.font.outline = true
    self.bitmap.font.color = Color.new(255,255,255,255)
    self.bitmap.draw_text(0,self.height-14,self.width,14, level, 1)
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
# ■ 能力帮助文本精灵
#==============================================================================
class Sprite_AbilityLearn_TokenHelp < Sprite
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

    text = ABILITY_LEARN.get_token_help(s.actor_id, s.id)
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
class Data_AbilityLearn
  attr_reader :sp, :sp_all
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(actor_id)
    @actor_id = actor_id
    @unlocks = [] # 已经解锁的token的id
    @sp = 0  # 当前能力点数目
    @sp_all = 0  # 全部能力点数目（用于重置）
    @skill_ids = []  # 已经解锁的技能的ID
    @param_plus = [0] * 8  # 8维属性的增量
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
    # 回复全部sp
    @sp = @sp_all
    # 清空已学技能
    @skill_ids.clear
    # 清空附加属性
    @param_plus = [0] * 8
    # 触发脚本
    @unlocks.each do |token_id|
      str = ABILITY_LEARN.get_token_eval_off(@actor_id, token_id)
      ABILITY_LEARN.eagle_eval(str, @actor_id) if str
    end
    # 清空已解锁
    @unlocks.clear
  end
  #--------------------------------------------------------------------------
  # ● 解锁指定id
  #--------------------------------------------------------------------------
  def unlock(token_id)
    @unlocks.push(token_id)
    # 扣除sp
    @sp -= ABILITY_LEARN.get_token_sp(@actor_id, token_id)
    # 习得技能
    skill_id = ABILITY_LEARN.get_token_skill(@actor_id, token_id)
    @skill_ids.push(skill_id) if skill_id
    # 增加属性
    hash = ABILITY_LEARN.get_token_params(@actor_id, token_id)
    hash.each do |sym, v|
      param_id = ABILITY_LEARN::PARAMS_TO_ID[sym]
      @param_plus[param_id] += v.to_i
    end
    # 触发脚本
    str = ABILITY_LEARN.get_token_eval_on(@actor_id, token_id)
    ABILITY_LEARN.eagle_eval(str, @actor_id) if str
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
    if !unlock?(token_id)
      pres_all = ABILITY_LEARN.get_token_pre(@actor_id, token_id)
      pres = pres_all | pres_all
      pres.each { |id|
        return false if !unlock?(id)
        return false if level(id) < pres_all.count(id)
      }
    else
      f = leven_max(token_id)
      return false if f <= 0 or f <= level(token_id)
    end
    @sp >= ABILITY_LEARN.get_token_sp(@actor_id, token_id)
  end
  #--------------------------------------------------------------------------
  # ● 指定ID能够重复解锁的次数
  #--------------------------------------------------------------------------
  def leven_max(token_id)
    return ABILITY_LEARN.get_token_level(@actor_id, token_id)
  end
  #--------------------------------------------------------------------------
  # ● 获取解锁次数
  #--------------------------------------------------------------------------
  def level(token_id)
    @unlocks.count(token_id)
  end
  #--------------------------------------------------------------------------
  # ● 获取已经解锁的技能
  #--------------------------------------------------------------------------
  def skills
    @skill_ids
  end
  #--------------------------------------------------------------------------
  # ● 获取已经解锁的附加属性
  #--------------------------------------------------------------------------
  def param_plus(param_id)
    @param_plus[param_id]
  end
end

#==============================================================================
# ■ Game_Actor
#==============================================================================
class Game_Actor
  attr_reader :eagle_ability_data
  #--------------------------------------------------------------------------
  # ● 初始化技能
  #--------------------------------------------------------------------------
  alias eagle_ability_learn_init_skills init_skills
  def init_skills
    eagle_ability_learn_init_skills
    @eagle_ability_data = Data_AbilityLearn.new(@actor_id)
  end
  #--------------------------------------------------------------------------
  # ● 获取添加的技能
  #--------------------------------------------------------------------------
  def added_skills
    super | @eagle_ability_data.skills
  end
  #--------------------------------------------------------------------------
  # ● 获取普通能力的附加值
  #--------------------------------------------------------------------------
  alias eagle_ability_learn_param_plus param_plus
  def param_plus(param_id)
    v = eagle_ability_learn_param_plus(param_id)
    v + @eagle_ability_data.param_plus(param_id)
  end
end


class Scene_Map
  #--------------------------------------------------------------------------
  # ● 监听取消键的按下。如果菜单可用且地图上没有事件在运行，则打开菜单界面。
  #--------------------------------------------------------------------------
  alias eagle_update_call_menu update_call_menu
  def update_call_menu
    eagle_update_call_menu
    ABILITY_LEARN.call if Input.trigger?(:A)
  end
end
