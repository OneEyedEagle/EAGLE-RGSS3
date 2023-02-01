#==============================================================================
# ■ Add-On 地图灰尘飘散 by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【粒子发射器V2 by老鹰】之下
#==============================================================================
# - 2021.11.4.22
#==============================================================================
# - 本插件新增了在地图上指定位置进行飘散的粒子模板
#----------------------------------------------------------------------------
# 【使用方法】
#
# - 在 地图右键-属性-备注 中填写：
#
#     <dust>
#       ...
#     </dust>
#
#     其中 ... 替换为 属性名:属性值 的设置项，每个设置项占一行
#
# - 设置项一览：
#
#     pos: x,y,w,h  →【必须】设置灰尘生成的位置（地图编辑器中的格子坐标与个数）
#                      比如 pos: 2,3, 4,5 就是从地图(2,3)处到地图(5,7)处的矩形
#
#     size: v   →【可选】灰尘粒子的大小为vxv（默认1x1）
#
#     rgba: r,g,b,a →【可选】灰尘粒子的颜色为 Color.new(r,g,b,a)
#
#     angle: v1, v2 →【可选】灰尘的移动方位在 v1角度 到 v2角度 之间
#                      （水平向右为 0°，顺时针方向为正角，默认为 0~360°）
#
#     v: v1, v2 →【可选】灰尘的移动速度（v1到v2之间的一个随机数）
#
#     t: v1, v2 →【可选】单个灰尘粒子的存在时间（v1到v2之间的一个随机数）
#
#     n: v1, v2 →【可选】每次生成的灰尘粒子数目
#
#     all: v    →【可选】灰尘粒子的总数（当前灰尘区域中的灰尘不会超过这个数目）
#
#     z: v      →【可选】灰尘粒子的z值（默认1，位于地图图块上，玩家下方）
#
# - 示例：
#
#    从地图的 (9,17) 为左上角，横向2格，纵向1格的区域里，随机生成灰尘粒子，
#      且它们的存在时间为 60~90 帧；
#    从地图的 (19,17) 为左上角，横向1格，纵向1格的区域里，随机生成灰尘粒子。
#
=begin
<dust>
pos: 9,17, 2,1
t: 60,90
</dust>
<dust>
pos: 19,17, 1,1
</dust>
=end
#
#==============================================================================

module PARTICLE
  #--------------------------------------------------------------------------
  # ● 解析数字字符串
  #--------------------------------------------------------------------------
  def self.parse_number_string(s, flag_float=false)
    # s = "v, v,v..."
    s = (s.gsub(/ /){ "" }).split(/,/)
    s.collect { |v| flag_float ? v.to_f : v.to_i }
  end
end

class ParticleTemplate_DustOnMap < ParticleTemplate_OnMap
  def init_others
    super
    @particle.blend_type = 1
  end
end

class Spriteset_Map
  #--------------------------------------------------------------------------
  # ● 读取图块地图
  #--------------------------------------------------------------------------
  alias eagle_particle_mapdust_create_tilemap create_tilemap
  def create_tilemap
    eagle_particle_mapdust_create_tilemap
    create_dusts
    start_dusts
  end
  #--------------------------------------------------------------------------
  # ● 创建灰尘组
  #--------------------------------------------------------------------------
  def create_dusts
    @eagle_dusts = []
    i = 0
    $game_map.note.scan(/<dust>(.*?)<\/dust>/im).each do |ts|
      tags = ts[0].split(/\r|\n/)
      tags_hash = {}
      tags.each do |tag|
        next if tag.empty?
        vs = (tag.gsub(/ /){ "" }).split(/:/)
        tags_hash[ vs[0].to_sym ] = vs[1]
      end
      n = create_dust(tags_hash, i)
      next if n == nil
      @eagle_dusts.push(n)
      i += 1
    end
  end
  #--------------------------------------------------------------------------
  # ● 创建粒子发射器
  #--------------------------------------------------------------------------
  def create_dust(tags, i)
    n = "EAGLE-MAPDUST-#{i}"

    f = ParticleTemplate_DustOnMap.new

    # tags[:pos] = "x,y,w,h"
    arr = PARTICLE.parse_number_string(tags[:pos])
    return nil if arr.size != 4
    f.params[:pos_map] = Rect.new(arr[0], arr[1], arr[2], arr[3])

    # tags[:size] = "v"
    arr = PARTICLE.parse_number_string(tags[:size]) rescue []
    if arr.size == 1
      b = Bitmap.new(arr[0], arr[0])
    else
      b = Bitmap.new(1, 1)
    end

    # tags[:rgba] = "r,g,b,a"
    arr = PARTICLE.parse_number_string(tags[:rgba]) rescue []
    if arr.size == 3
      b.fill_rect(b.rect, Color.new(arr[0],arr[1],arr[2]))
    elsif arr.size == 4
      b.fill_rect(b.rect, Color.new(arr[0],arr[1],arr[2],arr[3]))
    else
      b.fill_rect(b.rect, Color.new(150,150,150,255))
    end
    f.params[:bitmaps].push(b)

    # tags[:angle] = "v1, v2"
    arr = PARTICLE.parse_number_string(tags[:angle]) rescue []
    if arr.size == 2
      f.params[:theta] = RangeValue.new(arr[0], arr[1]) # 初速度方向（角度）
    else
      f.params[:theta] = RangeValue.new(0, 360) # 初速度方向（角度）
    end

    # tags[:v] = "v1, v2"
    arr = PARTICLE.parse_number_string(tags[:v]) rescue []
    if arr.size == 2
      f.params[:speed] = RangeValue.new(arr[0], arr[1]) # 初速度值（标量）
    else
      f.params[:speed] = RangeValue.new(0, 1) # 初速度值（标量）
    end

    # tags[:t] = "v1, v2"
    arr = PARTICLE.parse_number_string(tags[:t]) rescue []
    if arr.size == 2
      f.params[:life] = RangeValue.new(arr[0], arr[1]) # 存在时间
    else
      f.params[:life] = VarValue.new(90, 30) # 存在时间
    end

    # tags[:n] = "v1, v2"
    arr = PARTICLE.parse_number_string(tags[:n]) rescue []
    if arr.size == 2
      f.params[:new_per_wave] = RangeValue.new(arr[0],arr[1])
    else
      f.params[:new_per_wave] = VarValue.new(3,2)
    end

    # tags[:all] = "v"
    arr = PARTICLE.parse_number_string(tags[:all]) rescue []
    if arr.size == 1
      f.params[:total] = arr[0]
    else
      f.params[:total] = 30
    end

    # tags[:z] = "v"
    arr = PARTICLE.parse_number_string(tags[:z]) rescue []
    if arr.size == 1
      f.params[:z] = arr[0]
    else
      f.params[:z] = 1
    end

    PARTICLE.setup(n, f, @viewport1)
    return n
  end
  #--------------------------------------------------------------------------
  # ● 启动灰尘组
  #--------------------------------------------------------------------------
  def start_dusts
    @eagle_dusts.each { |n| PARTICLE.start(n) }
  end
  #--------------------------------------------------------------------------
  # ● 释放地图图块
  #--------------------------------------------------------------------------
  alias eagle_particle_mapdust_dispose_tilemap dispose_tilemap
  def dispose_tilemap
    eagle_particle_mapdust_dispose_tilemap
    @eagle_dusts.each { |n| PARTICLE.dispose(n) }
    @eagle_dusts.clear
  end
end

class Game_Map
  #--------------------------------------------------------------------------
  # ● 获取备注
  #--------------------------------------------------------------------------
  def note
    @map.note
  end
end
