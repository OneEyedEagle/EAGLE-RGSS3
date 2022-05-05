#==============================================================================
# ■ 保存截图 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# 【此插件兼容VX和VX Ace】
# ※ 本插件需要放置在【组件-位图Marshal化（VX/VA）】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-SaveScreenshot"] = "1.0.0"
#==============================================================================
# - 2022.5.4.23
#==============================================================================
# - 本插件新增了截图的保存，并且可以利用事件指令-显示图片来调用这些截图
#--------------------------------------------------------------------------
# ○ 保存截图
#--------------------------------------------------------------------------
# - 利用事件脚本 save_screenshot(name) 来将当前屏幕的截图进行保存
#    其中 name 为任意字符串，将作为截图的名称，请确保唯一性
#
# - 注意：
#
#    1. 在进行存档时，将同步存储全部截图，读档时也将同步读取。
#    2. 不同存档之间的数据互相独立。
#
# - 示例：
#
#     事件脚本调用 save_screenshot("第一次见面")
#
#--------------------------------------------------------------------------
# ○ 读取截图
#--------------------------------------------------------------------------
# - 利用事件脚本 load_screenshot(name, pid) 来读取之前保存的截图
#    其中 name 为对应截图的文件名的字符串，不需要包含后缀 png
#    其中 pid 为要把该截图读取到显示图片的序号
#
# - 之后使用 事件指令-显示图片，序号设置为 pid，图片名称无效，就可以显示对应截图了
#   事件指令-移动图片 等都可以使用
#
# - 示例：
#
#    1. 事件脚本调用 load_screenshot("第一次见面", 1)
#    2. 事件指令-显示图片-原点中点、位置、不透明度150 等自由设置，就能显示这张截图了
#    3. 事件指令-移动图片，也可以正常移动
#
#==============================================================================
FLAG_VX = RUBY_VERSION[0..2] == "1.8"  # 兼容VX用
module SAVE_MEMORY
  #--------------------------------------------------------------------------
  # 【常量】定义存储位置
  #--------------------------------------------------------------------------
  # 这个目录位置需要在最后加上一个 / 符号
  SAVE_SCREEN_DIR = "./Saves/"

  # 确保路径存在
  Dir.mkdir(SAVE_SCREEN_DIR) if !File.exist?(SAVE_SCREEN_DIR)
end

if FLAG_VX
class Scene_File
  #--------------------------------------------------------------------------
  # ● 生成文件名称
  #     file_index : 存档位置（0～3）
  #--------------------------------------------------------------------------
  def make_filename_memory(file_index)
    return SAVE_MEMORY::SAVE_SCREEN_DIR + "Save#{file_index + 1}_memory.rvdata"
  end
  #--------------------------------------------------------------------------
  # ● 执行存档
  #--------------------------------------------------------------------------
  alias eagle_save_screenshot_do_save do_save
  def do_save
    File.open(make_filename_memory(@index), "wb") do |file|
      Marshal.dump(SAVE_MEMORY.data, file)
    end
    eagle_save_screenshot_do_save
  end
  #--------------------------------------------------------------------------
  # ● 执行读档
  #--------------------------------------------------------------------------
  alias eagle_save_screenshot_do_load do_load
  def do_load
    File.open(make_filename_memory(@index), "rb") do |file|
      SAVE_MEMORY.data = Marshal.load(file)
    end
    eagle_save_screenshot_do_load
  end
end
else  # if FLAG_VX
class << DataManager
  #--------------------------------------------------------------------------
  # ● 生成文件名
  #     index : 文件索引
  #--------------------------------------------------------------------------
  def make_filename_memory(index)
    sprintf(SAVE_MEMORY::SAVE_SCREEN_DIR + "Save%02d_memory.rvdata2", index + 1)
  end
  #--------------------------------------------------------------------------
  # ● 执行存档（没有错误处理）
  #--------------------------------------------------------------------------
  alias eagle_save_screenshot_save_game_without_rescue save_game_without_rescue
  def save_game_without_rescue(index)
    eagle_save_screenshot_save_game_without_rescue(index)
    File.open(make_filename_memory(index), "wb") do |file|
      Marshal.dump(SAVE_MEMORY.data, file)
    end
    return true
  end
  #--------------------------------------------------------------------------
  # ● 执行读档（没有错误处理）
  #--------------------------------------------------------------------------
  alias eagle_save_screenshot_load_game_without_rescue load_game_without_rescue
  def load_game_without_rescue(index)
    eagle_save_screenshot_load_game_without_rescue(load)
    File.open(make_filename_memory(index), "rb") do |file|
      SAVE_MEMORY.data = Marshal.load(file)
    end
    return true
  end
end
end  # if FLAG_VX

module SAVE_MEMORY
  #--------------------------------------------------------------------------
  # ● 获取截图
  #--------------------------------------------------------------------------
  def self.get_screenshot
    before_screenshot
    b = Graphics.snap_to_bitmap
    after_screenshot
    return b
  end
  #--------------------------------------------------------------------------
  # ● 在截图前
  #--------------------------------------------------------------------------
  def self.before_screenshot
    TODOLIST.hide if $imported["EAGLE-TODOList"]
    MESSAGE_HINT.hide if $imported["EAGLE-MessageHint"]
    PARTICLE.emitters.each { |k, v| v.hide } if $imported["EAGLE-Particle"]
  end
  #--------------------------------------------------------------------------
  # ● 在截图后
  #--------------------------------------------------------------------------
  def self.after_screenshot
    TODOLIST.show if $imported["EAGLE-TODOList"]
    MESSAGE_HINT.show if $imported["EAGLE-MessageHint"]
    PARTICLE.emitters.each { |k, v| v.show } if $imported["EAGLE-Particle"]
  end
  #--------------------------------------------------------------------------
  # ● 数据
  #--------------------------------------------------------------------------
  @data = {}  # name => bitmap
  class << self; attr_accessor :data; end
  #--------------------------------------------------------------------------
  # ● 保存截图
  #--------------------------------------------------------------------------
  def self.save_screenshot(name)
    @data[name] = get_screenshot
  end
  #--------------------------------------------------------------------------
  # ● 读取截图
  #--------------------------------------------------------------------------
  def self.load_screenshot(name)
    @data[name] || Cache.empty_bitmap
  end
end

class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 保存截图
  #--------------------------------------------------------------------------
  def save_screenshot(name)
    SAVE_MEMORY.save_screenshot(name)
  end
  #--------------------------------------------------------------------------
  # ● 读取截图
  #--------------------------------------------------------------------------
  def load_screenshot(name, pid)
    @eagle_show_screenshot = [pid, name]
  end
  #--------------------------------------------------------------------------
  # ● 显示图片
  #--------------------------------------------------------------------------
  alias eagle_save_screenshot_command_231 command_231
  def command_231
    eagle_save_screenshot_command_231
    if @eagle_show_screenshot && @eagle_show_screenshot[0] == @params[0]
      if @params[3] == 0    # 直接指定
        x = @params[4]
        y = @params[5]
      else                  # 变量指定
        x = $game_variables[@params[4]]
        y = $game_variables[@params[5]]
      end
      n = @eagle_show_screenshot[1]
      screen.pictures[@params[0]].show(n, @params[2],
        x, y, @params[6], @params[7], @params[8], @params[9])
      screen.pictures[@params[0]].set_dir_type(:save_screenshot)
      @eagle_show_screenshot = nil
    end
  end
end

class Game_Picture
  attr_reader   :dir
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  alias eagle_save_screenshot_init initialize
  def initialize(number)
    eagle_save_screenshot_init(number)
    @dir = nil
  end
  #--------------------------------------------------------------------------
  # ● 设置目录位置
  #--------------------------------------------------------------------------
  def set_dir_type(t)
    @dir = t
  end
end

class Sprite_Picture < Sprite
if FLAG_VX
  #--------------------------------------------------------------------------
  # ● 更新画面
  #--------------------------------------------------------------------------
  alias eagle_save_screenshot_update update
  def update
    if @picture_name != @picture.name
      @picture_name = @picture.name
      if @picture_name != "" && @picture.dir == :save_screenshot
        self.bitmap = SAVE_MEMORY.load_screenshot(@picture.name)
      else
        self.bitmap = Cache.picture(@picture_name)
      end
    end
    eagle_save_screenshot_update
  end
else
  #--------------------------------------------------------------------------
  # ● 更新源位图（Source Bitmap）
  #--------------------------------------------------------------------------
  alias eagle_save_screenshot_update_bitmap update_bitmap
  def update_bitmap
    if @picture.dir == :save_screenshot
      self.bitmap = SAVE_MEMORY.load_screenshot(@picture.name)
    else
      eagle_save_screenshot_update_bitmap
    end
  end
end
end
