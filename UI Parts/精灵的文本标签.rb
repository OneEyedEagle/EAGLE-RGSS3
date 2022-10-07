#==============================================================================
# ■ 精灵的文本标签 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【组件-通用方法汇总 by老鹰】与
#  【组件-位图绘制转义符文本 by老鹰】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-SpriteTextTag"] = "1.0.1"
#==============================================================================
# - 2022.10.5.10
#==============================================================================
# - 本插件新增了一个与精灵绑定的显示文本的标签系统
#-----------------------------------------------------------------------------
# 【使用】
#
# 1. 利用全局脚本为指定精灵初始化标签组（仅需调用一次）
#
#     TAG.new_sprite(id, s, ps={}) → 为精灵 s 初始化标签组，该标签组名称为 id
#
#     TAG.new_map(id, x, y, ps={}) → 为地图格子(x,y)初始化标签组，名称为 id
#
#     TAG.new_map_chara(id, ps={}) → 为地图id号事件初始化标签组，名称为 id
#
#     TAG.new_pic(id, ps={})  → 为第id号显示图片初始化，注意其名称为 "pic-id"
#                                比如为 5 号图片初始化，则它的名称为 "pic-5"
#
#    其中 ps 为扩展参数：
#
#      :dx => 数字,  # 在精灵的xy基础上的坐标偏移值，可用于把标签组显示在精灵内部
#      :dy => 数字,
#      :vp => 视图,  # 所显示的视图，默认取精灵的视图
# 
# ※ 注意：id 需要保证唯一性
#         由于绑定到地图事件上的标签的id必定是数字，因此其它类型推荐使用字符串id
#
#----------------------------------------------------------------
# 2.1 利用全局脚本为指定id的标签组增加标签
#
#     TAG.add(id, tid, t, ps={}) → 为名称为id的标签组，增加一个名称为tid的标签
#
#    其中 id 为在 1 中预设的标签组的名称，与对应精灵、地图事件等都无关了
#    其中 tid 为该标签的名称，之后删除标签时使用该名称
#    其中 t 为该标签的文本内容，为字符串
#    其中 ps 为扩展的参数：
#
#        :draw => {},  # 传入【组件-位图绘制转义符文本】中的参数组
#
# ※ 注意：对于同一标签组，增加多个标签时，将把最新加入的放到底下，旧的往上移动
#
#----------------------------------------------------------------
# 2.2 利用全局脚本为指定id的标签组删除标签
#
#     TAG.delete(id, tid=nil) → 为名称为id的标签组，删去一个名称为tid的标签
#                               如果不传入tid，或tid为nil，则删去组内的全部标签
#
#----------------------------------------------------------------
# 3. 当不需要使用后，利用全局脚本释放指定id的标签组
#
#     TAG.dispose(id) 
#
# ※ 注意：
#
#   (1) 当所绑定的精灵被释放后，标签组将停止更新（但不会自动释放，请手动调用该释放）
#
#   (2) 绑定于地图事件的标签组，在地图切换时，将会自动释放
#
#   (3) 在释放后，需要重新初始化标签组！
#
#-----------------------------------------------------------------------------
# 【示例】
#
# - 为当前地图上的 2 号事件显示一句 "有新任务"
=begin

TAG.new_map_chara(2)
TAG.add(2, "任务", "有新任务")

=end
#
#==============================================================================

module TAG 
  #--------------------------------------------------------------------------
  # ● 为精灵增加文本标签
  #--------------------------------------------------------------------------
  def self.new_sprite(sid, s, ps={})
    return if @spritesets[sid] != nil 
    ps[:sprite] = s
    ps[:dx] ||= 0
    ps[:dy] ||= 0
    ps[:vp] ||= ps[:sprite].viewport
    @spritesets[sid] = Spriteset_EagleTag.new(sid, ps)
  end
  #--------------------------------------------------------------------------
  # ● 为地图格子增加文本标签
  #--------------------------------------------------------------------------
  def self.new_map(mid, x, y, ps={})
    return if @spritesets[mid] != nil 
    ps[:map] = true
    ps[:map_x] = x
    ps[:map_y] = y
    ps[:map_z] ||= 100
    ps[:dx] ||= 16
    ps[:dy] ||= 16
    ps[:vp] ||= nil
    @spritesets[mid] = Spriteset_EagleTag.new(mid, ps)
  end
  #--------------------------------------------------------------------------
  # ● 为地图事件增加文本标签
  #--------------------------------------------------------------------------
  def self.new_map_chara(eid, ps={})
    return if @spritesets[eid] != nil 
    ps[:map_chara] = true
    ps[:chara] = eid
    ps[:sprite] = EAGLE_COMMON.get_chara_sprite(eid)
    ps[:dx] ||= 0
    ps[:dy] ||= -ps[:sprite].height
    ps[:vp] ||= ps[:sprite].viewport
    @spritesets[eid] = Spriteset_EagleTag.new(eid, ps)
  end
  #--------------------------------------------------------------------------
  # ● 为显示图片增加文本标签
  # 该类型的名称为 "pic-id" 字符串，其中id替换为显示图片的序号
  #--------------------------------------------------------------------------
  def self.new_pic(pid, ps={})
    id = "pic-#{pid}"
    return if @spritesets[id] != nil 
    s = EAGLE_COMMON.get_pic_sprite(pid)
    new_sprite(id, s, ps)
  end
  
  #--------------------------------------------------------------------------
  # ● 增加一个名称为 tid，显示内容为 t 的文本标签
  #--------------------------------------------------------------------------
  def self.add(id, tid, t, ps={})
    return if @spritesets[id] == nil 
    @spritesets[id].add(tid, t, ps)
  end
  #--------------------------------------------------------------------------
  # ● 删去名称为 tid 的文本标签
  #--------------------------------------------------------------------------
  def self.delete(id, tid=nil)
    return if @spritesets[id] == nil 
    @spritesets[id].delete(tid)
  end
  #--------------------------------------------------------------------------
  # ● 释放名称为 id 的标签组
  #--------------------------------------------------------------------------
  def self.dispose(id)
    return if @spritesets[id] == nil 
    @spritesets[id].dispose
    @spritesets.delete(id)
  end

  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def self.init 
    @spritesets = {}
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def self.update 
    @spritesets.delete_if { |id, s| s.finish? }
    @spritesets.each { |id, s| s.update }
  end
  #--------------------------------------------------------------------------
  # ● 地图切换时自动释放绑定于事件行走图的
  #--------------------------------------------------------------------------
  def self.dispose_when_map_change
    ids = @spritesets.select { |id, s| s.dispose_when_change_map? }
    ids.each { |id| dispose(id) }
  end
end 
class << DataManager
  #--------------------------------------------------------------------------
  # ● 初始化模块
  #--------------------------------------------------------------------------
  alias eagle_tag_init init 
  def init
    TAG.init
    eagle_tag_init
  end
end
class Scene_Base 
  #--------------------------------------------------------------------------
  # ● 基础更新
  #--------------------------------------------------------------------------
  alias eagle_tag_update_basic update_basic 
  def update_basic
    eagle_tag_update_basic
    TAG.update
  end
end
class Scene_Map
  #--------------------------------------------------------------------------
  # ● 场所移动后的处理
  #--------------------------------------------------------------------------
  alias eagle_tag_post_transfer post_transfer 
  def post_transfer
    eagle_tag_post_transfer
    TAG.dispose_when_map_change
  end
end

class Spriteset_EagleTag
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(id, ps = {})
    @id = id
    @sprites = []  # [ [id, sprite] ]
    @ps = ps
    @finish = false
  end
  #--------------------------------------------------------------------------
  # ● 获取指定名称的文本标签的精灵
  #--------------------------------------------------------------------------
  def get_sprite(tid)
    @sprites.each do |data|
      return data[1] if data[0] == tid
    end
    return nil
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    @sprites.each { |data| data[1].dispose }
    @sprites.clear
    @finish = true
  end 
  #--------------------------------------------------------------------------
  # ● 地图切换时自动释放？
  #--------------------------------------------------------------------------
  def dispose_when_change_map?
    @ps[:map_chara] == true
  end
  #--------------------------------------------------------------------------
  # ● 完成？
  #--------------------------------------------------------------------------
  def finish?
    @finish == true
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update 
    if @ps[:chara] && SceneManager.scene_is?(Scene_Map) && 
       @ps[:sprite].disposed?
      @ps[:sprite] = EAGLE_COMMON.get_chara_sprite(@ps[:chara])
      return if @ps[:sprite].disposed?
      @ps[:vp] = @ps[:sprite].viewport
      @sprites.each { |data| data[1].viewport = @ps[:vp] }
      return
    end
    return if @ps[:sprite] && @ps[:sprite].disposed?
    @sprites.each { |data| data[1].update }
    update_position
  end
  #--------------------------------------------------------------------------
  # ● 更新位置
  #--------------------------------------------------------------------------
  def update_position
    @sprites.each do |data|
      if @ps[:sprite]
        data[1].x = @ps[:sprite].x + @ps[:dx] + data[1].dx
        data[1].y = @ps[:sprite].y + @ps[:dy] + data[1].dy
        data[1].z = @ps[:sprite].z + 1
      elsif @ps[:map]
        data[1].x = (@ps[:map_x] - $game_map.display_x) * 32 + \
                    @ps[:dx]  + data[1].dx
        data[1].y = (@ps[:map_y] - $game_map.display_y) * 32 + \
                    @ps[:dy]  + data[1].dy
        data[1].z = @ps[:map_y] + 1
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 新增一个文本标签
  #--------------------------------------------------------------------------
  def add(tid, t, ps={})
    s = get_sprite(tid)
    if s
      return if s.redraw(t) == false
    else 
      s = Sprite_EagleTag.new(self, @ps[:vp], t, ps)
      @sprites.unshift([tid, s])
    end
    update_base_position
  end
  #--------------------------------------------------------------------------
  # ● 删去指定文本标签
  #--------------------------------------------------------------------------
  def delete(tid)
    if tid 
      index = -1
      @sprites.each_with_index do |data, i|
        break index = i if data[0] == tid
      end
      if index >= 0
        @sprites[index][1].dispose 
        @sprites.delete_at(index)
        update_base_position
        return true 
      end
      return false
    end
    dispose
    return true
  end
  #--------------------------------------------------------------------------
  # ● 更新基础排序位置
  #--------------------------------------------------------------------------
  def update_base_position
    h = 0
    @sprites.each_with_index do |data, i|
      data[1].dy = -h
      h = h - 8 + data[1].height
    end
  end
end

class Sprite_EagleTag < Sprite 
  attr_accessor  :dx, :dy
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(set, vp = nil, t="", ps={})
    super(vp)
    @set = set
    @ps = ps
    @dx = 0
    @dy = 0
    redraw(t)
  end 
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose 
    self.bitmap.dispose if self.bitmap 
    super 
  end
  #--------------------------------------------------------------------------
  # ● 绘制
  #--------------------------------------------------------------------------
  def redraw(t)
    return false if t == nil || t == "" || @ps[:t] == t
    @ps[:t] = t
    if self.bitmap
      self.bitmap.dispose
      self.bitmap = nil
    end
    
    return if $imported["EAGLE-DrawTextEX"] == nil
    # 预绘制文字
    @ps[:draw] ||= {}
    @ps[:draw][:ali] = 1
    @ps[:draw][:lhd] = 4
    d = Process_DrawTextEX.new(t, @ps[:draw])
    # 新建一个位图
    tag_h = 5
    c = Color.new(0,0,0,150)
    b = Bitmap.new(d.width + 4 *2, d.height + 2 * 2 + tag_h)
    b.fill_rect(0,0,b.width,b.height-tag_h, c)
    # 绘制文字
    d.bind_bitmap(b)
    @ps[:draw][:x0] = 4
    @ps[:draw][:y0] = 2
    d.run
    # 绘制箭头
    [ [-4,0],[-3,0],[-2,0],[-1,0],[0,0],[1,0],[2,0],[3,0],[4,0],
      [-3,1],[-2,1],[-1,1],[0,1],[1,1],[2,1],[3,1],
      [-2,2],[-1,2],[0,2],[1,2],[2,2],
      [-1,3],[0,3],[1,3],
      [0,4] ].each do |xy|
      b.set_pixel(b.width / 2 + xy[0], b.height - 5 + xy[1], c)
    end

    self.bitmap = b
    self.ox = self.width / 2
    self.oy = self.height
    return true
  end
end
