#==============================================================================
# ■ Add-On 事件页自动播放BGS by 老鹰（http://oneeyedeagle.lofter.com/）
# ※ 本插件需要放置在【事件警报机制 by老鹰】之下
# 【此插件兼容VX和VX Ace】
#==============================================================================
$imported ||= {}
$imported["EAGLE-EventAutoBGS"] = true
#==============================================================================
# - 2021.9.25.18
#==============================================================================
# - 本插件新增事件页的自动播放BGS机制，同时按照与角色的距离减小音量
# - 本插件调用了【事件警报机制 by老鹰】中的方法
#--------------------------------------------------------------------------
# ○ 事件页设置
#--------------------------------------------------------------------------
# - 当事件页的第一个指令为 注释 时，在其中按下述格式填写，以设置自动播放
#
#    <bgs name distance>
#
#   其中 bgs 为固定的识别文字，不要修改
#
#   其中 name 为在常量DATA中预设的键值，自由设置，字符串
#
#   其中 distance 为BGS播放的最大距离（玩家与事件之间的格子数）（可省略）
#     当玩家与事件之间的格子数大于该值时，将不再播放
#
# - 示例：
#
#     <bgs clock 5>  → 在距离5格内，播放Clock音效，且距离越小，音量越大
#
# - 注意：
#
#   ·当首次超出设置的最大距离时，将调用一次BGS暂停播放
#
#==============================================================================
module EAGLE
  #--------------------------------------------------------------------------
  # ○【常量】预设可以播放的BGS
  #--------------------------------------------------------------------------
  DATA = {
    #name => [filename, volume, pitch, pri],
    # 写在备注中的名称 => [文件名, 初始音量, 音调, 优先级],
    #  其中 优先级 为数字，但填写 nil 时代表优先级最高。
    #
    #  若同时有两个BGS播放请求，则优先级高的播放，
    #   若它们具有相同优先级，则事件ID大的播放

    "clock" => ["Clock", 80, 100, 0],
    "wind" => ["Wind", 80, 100, 0],

  }
  #--------------------------------------------------------------------------
  # ○【常量】距离每增加1，BGS的音量的减少量
  #--------------------------------------------------------------------------
  DOWN_PER_DISTANCE = 5
  #--------------------------------------------------------------------------
  # ○【常量】默认的最大距离
  #--------------------------------------------------------------------------
  DEFAULT_DISTANCE = 3

  #--------------------------------------------------------------------------
  # ● 读取BGS数据
  #--------------------------------------------------------------------------
  def self.bgs_data(name)
    DATA[name] || ["", 80, 100, 0]
  end
  #--------------------------------------------------------------------------
  # ● 播放指定BGS
  #--------------------------------------------------------------------------
  @last_bgs = nil  # [event_id, name, pri]
  def self.bgs_play(name, d, event_id)
    name = name.downcase
    if @last_bgs
      return if @last_bgs[-1] == nil
      data = bgs_data(name)
      if data[1] != name && data[-1] != nil
        return if data[-1] < @last_bgs[-1]
        if @last_bgs[-1] == data[-1] # 如果优先级相同，按事件ID
          return if event_id < @last_bgs[0]
        end
      end
    end
    data = bgs_data(name)
    filename = data[0]
    volume = data[1] - d * DOWN_PER_DISTANCE
    return bgs_stop(name) if volume <= 0
    pitch = data[2]
    pri = data[3] || 0
    Audio.bgs_play('Audio/BGS/' + filename, volume, pitch)
    @last_bgs = [event_id, name, pri]
  end
  #--------------------------------------------------------------------------
  # ● 指定BGS暂停播放
  #--------------------------------------------------------------------------
  def self.bgs_stop(name = nil)
    return if @last_bgs == nil
    if name == nil || name == @last_bgs[1]
      RPG::BGS.fade(10)
      @last_bgs = nil
    end
  end
  #--------------------------------------------------------------------------
  # ● 直接设置当前已经在播放的BGS
  #--------------------------------------------------------------------------
  def self.bgs_set(event_id, name, pri)
    @last_bgs = [event_id, name, pri]
  end
  #--------------------------------------------------------------------------
  # ● 重置已经在播放的BGS
  #--------------------------------------------------------------------------
  def self.bgs_reset
    @last_bgs = nil
  end
end

class << EVENT_ALERT
  #--------------------------------------------------------------------------
  # ● 解析
  #--------------------------------------------------------------------------
  alias eagle_bgs_parse_note parse_note
  def parse_note(str)
    _array = eagle_bgs_parse_note(str)
    str.scan( /<bgs (.*?) ?(\d+)?>/m ).each do |params|
      _hash = { :t_id => 0 }
      _hash[:repeat] = true
      _hash[:cond] = "dx+dy <= #{$2 ? $2.to_i : EAGLE::DEFAULT_DISTANCE}"
      _hash[:eval] = "EAGLE.bgs_play('#{$1}', dx + dy, a.id)"
      _hash[:evaln] = "EAGLE.bgs_stop('#{$1}')"
      _array.push(_hash)
    end
    _array
  end
end

class Scene_Map
  #--------------------------------------------------------------------------
  # ● 场所移动后的处理
  #--------------------------------------------------------------------------
  alias eagle_bgs_post_transfer post_transfer
  def post_transfer
    eagle_bgs_post_transfer
    EAGLE.bgs_stop
  end
end

class RPG::BGS < RPG::AudioFile
  #--------------------------------------------------------------------------
  # ● 覆盖，用于保证事件中的播放BGS指令也能加入判定
  #--------------------------------------------------------------------------
  alias eagle_bgs_play play
if RUBY_VERSION[0..2] == "1.8"  # 兼容VX
  def play
    eagle_bgs_play
    eagle_play
  end
else
  def play(pos = 0)
    eagle_bgs_play(pos)
    eagle_play
  end
end
  def eagle_play 
    if @name.empty?
      EAGLE.bgs_reset
    else
      EAGLE.bgs_set(0, @name, nil)  # 播放优先级nil最高，事件ID取0
    end
  end

  def self.stop
    Audio.bgs_stop
    @@last = RPG::BGS.new
    EAGLE.bgs_reset
  end
  def self.fade(time)
    Audio.bgs_fade(time)
    @@last = RPG::BGS.new
    EAGLE.bgs_reset
  end
end
