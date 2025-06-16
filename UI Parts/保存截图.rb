#==============================================================================
# ■ 保存截图 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# 【此插件兼容VX和VX Ace】
# ※ 本插件需要放置在【组件-位图Marshal化（VX/VA）】之下
#==============================================================================
$imported ||= {}
$imported["EAGLE-SaveScreenshot"] = "1.0.6"
#==============================================================================
# - 2025.6.16.21 新增全部存档通用的截图
#==============================================================================
# - 本插件新增了截图的保存，并且可以利用事件指令-显示图片来调用这些截图
#--------------------------------------------------------------------------
# ○ 保存截图（各存档独立）
#--------------------------------------------------------------------------
# - 利用事件脚本 save_screenshot(name) 保存当前屏幕的截图
#    其中 name 为任意字符串，将作为截图的名称，请确保唯一性
#
# - 注意：
#
#    1. 在进行存档时，才会同步存储全部截图，读档时将同步读取。
#    2. 不同存档之间的截图互相独立。
#
# - 示例：
#
#     事件脚本调用 save_screenshot("第一次见面")
#
#--------------------------------------------------------------------------
# ○ 保存截图（各存档通用）
#--------------------------------------------------------------------------
# - 利用事件脚本 save_screenshot_global(name) 保存当前屏幕的截图
#    其中 name 为任意字符串，将作为截图的名称，请确保唯一性
#
# - 注意：
#
#    1. 在调用事件脚本时，便会同步存储到文件，新游戏及读档时将同步读取。
#    2. 全部存档通用该处的截图。
#
# - 示例：
#
#     事件脚本调用 save_screenshot_global("第一次新游戏")
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
# - 注意：
#
#    1. 优先读取存档对应的截图，若未找到，则读取全局的截图，
#       若未找到，则返回默认设置的图片/空图片
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

  #--------------------------------------------------------------------------
  # 【常量】依据存档序号，获得截图保存文件的名称
  #--------------------------------------------------------------------------
  def self.screenshot_filename(index)
    v = FLAG_VX ? "%d" : "%02d"
    t = FLAG_VX ? ".rvdata" : ".rvdata2"
    if index == -1
      # 全部存档文件通用的截图文件
      return sprintf(SAVE_SCREEN_DIR + "Memory" + t)
    else
      # 一个存档文件对应一个截图文件
      return sprintf(SAVE_SCREEN_DIR + "Save"+v+"_memory" + t, index + 1)
    end
  end
  #--------------------------------------------------------------------------
  # 【常量】未找到对应截图时，显示的图片
  #--------------------------------------------------------------------------
  def self.no_screenshot
    # 自定义无截图时显示的图片
    #return Cache.picture("")
    # 显示空白图片
    return Cache.empty_bitmap
  end

  #--------------------------------------------------------------------------
  # ● 写入文件
  #--------------------------------------------------------------------------
  def self.save(index)
    if index == -1
      File.open(SAVE_MEMORY.screenshot_filename(-1), "wb") do |file|
        Marshal.dump(SAVE_MEMORY.data_global, file)
      end
    else 
      File.open(SAVE_MEMORY.screenshot_filename(index), "wb") do |file|
        Marshal.dump(SAVE_MEMORY.data, file)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 读取文件
  #--------------------------------------------------------------------------
  def self.load(index)
    if index == -1
      begin
        File.open(SAVE_MEMORY.screenshot_filename(-1), "rb") do |file|
          SAVE_MEMORY.data_global = Marshal.load(file)
        end
      rescue
        SAVE_MEMORY.data_global = {}
      end
    else
      begin
        File.open(SAVE_MEMORY.screenshot_filename(index), "rb") do |file|
          SAVE_MEMORY.data = Marshal.load(file)
        end
      rescue
        SAVE_MEMORY.data = {}
        p $!
      end
    end
  end
end

if FLAG_VX
module Cache
  #--------------------------------------------------------------------------
  # ● 生成空位图
  #--------------------------------------------------------------------------
  def self.empty_bitmap
    Bitmap.new(32, 32)
  end
end
class Scene_File
  #--------------------------------------------------------------------------
  # ● 生成文件名称
  #     file_index : 存档位置（0～3）
  #--------------------------------------------------------------------------
  def make_filename_memory(file_index)
  end
  #--------------------------------------------------------------------------
  # ● 执行存档
  #--------------------------------------------------------------------------
  alias eagle_save_screenshot_do_save do_save
  def do_save
    SAVE_MEMORY.save(@index)
    eagle_save_screenshot_do_save
  end
  #--------------------------------------------------------------------------
  # ● 执行读档
  #--------------------------------------------------------------------------
  alias eagle_save_screenshot_do_load do_load
  def do_load
    SAVE_MEMORY.load(-1)
    SAVE_MEMORY.load(@index)
    eagle_save_screenshot_do_load
  end
end
class Scene_Title
  #--------------------------------------------------------------------------
  # ● 命令：新游戏
  #--------------------------------------------------------------------------
  alias eagle_save_screenshot_command_new_game command_new_game
  def command_new_game
    SAVE_MEMORY.load(-1)
    eagle_save_screenshot_command_new_game
  end
end
else  # if FLAG_VX
class << DataManager
  #--------------------------------------------------------------------------
  # ● 执行存档（没有错误处理）
  #--------------------------------------------------------------------------
  alias eagle_save_screenshot_save_game_without_rescue save_game_without_rescue
  def save_game_without_rescue(index)
    eagle_save_screenshot_save_game_without_rescue(index)
    SAVE_MEMORY.save(index)
    return true
  end
  #--------------------------------------------------------------------------
  # ● 执行读档（没有错误处理）
  #--------------------------------------------------------------------------
  alias eagle_save_screenshot_load_game_without_rescue load_game_without_rescue
  def load_game_without_rescue(index)
    eagle_save_screenshot_load_game_without_rescue(index)
    SAVE_MEMORY.load(-1)
    SAVE_MEMORY.load(index)
    return true
  end
  #--------------------------------------------------------------------------
  # ● 设置新游戏
  #--------------------------------------------------------------------------
  alias eagle_save_screenshot_setup_new_game setup_new_game
  def setup_new_game
    SAVE_MEMORY.load(-1)
    eagle_save_screenshot_setup_new_game
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
    PARTICLE.templates.each { |k, v| v.hide } if $imported["EAGLE-Particle"]
  end
  #--------------------------------------------------------------------------
  # ● 在截图后
  #--------------------------------------------------------------------------
  def self.after_screenshot
    TODOLIST.show if $imported["EAGLE-TODOList"]
    MESSAGE_HINT.show if $imported["EAGLE-MessageHint"]
    PARTICLE.templates.each { |k, v| v.show } if $imported["EAGLE-Particle"]
  end
  #--------------------------------------------------------------------------
  # ● 数据
  #--------------------------------------------------------------------------
  @data = {}  # name => bitmap
  @data_global = {} # name => bitmap
  class << self; attr_accessor :data, :data_global; end
  #--------------------------------------------------------------------------
  # ● 保存截图
  #--------------------------------------------------------------------------
  def self.save_screenshot(name)
    @data[name] = get_screenshot
  end
  def self.save_screenshot_global(name)
    @data_global[name] = get_screenshot
  end
  #--------------------------------------------------------------------------
  # ● 读取截图
  #--------------------------------------------------------------------------
  def self.load_screenshot(name)
    @data[name] || @data_global[name] || SAVE_MEMORY.no_screenshot 
  end
end

class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 保存截图（全存档通用）
  #--------------------------------------------------------------------------
  def save_screenshot_global(name)
    SAVE_MEMORY.save_screenshot_global(name)
    SAVE_MEMORY.save(-1)
  end
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
  #--------------------------------------------------------------------------
  # ● 消除图片
  #--------------------------------------------------------------------------
  alias eagle_save_screenshot_erase erase
  def erase
    @dir = :erase
    eagle_save_screenshot_erase
  end
end

class Sprite_Picture < Sprite
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  alias eagle_save_screenshot_dispose dispose
  def dispose
    self.bitmap = nil if @picture.dir == :save_screenshot
    eagle_save_screenshot_dispose
  end
if FLAG_VX
  #--------------------------------------------------------------------------
  # ● 更新画面
  #--------------------------------------------------------------------------
  alias eagle_save_screenshot_update update
  def update
    if @picture.dir == :erase
      @picture.set_dir_type(nil)
      self.bitmap = nil
    end
    if @picture.dir == :save_screenshot
      @picture_name = @picture.name
      self.bitmap = SAVE_MEMORY.load_screenshot(@picture_name)
    end
    eagle_save_screenshot_update
  end
else
  #--------------------------------------------------------------------------
  # ● 更新源位图（Source Bitmap）
  #--------------------------------------------------------------------------
  alias eagle_save_screenshot_update_bitmap update_bitmap
  def update_bitmap
    if @picture.dir == :erase
      @picture.set_dir_type(nil)
      self.bitmap = nil
    end
    if @picture.dir == :save_screenshot
      self.bitmap = SAVE_MEMORY.load_screenshot(@picture.name)
    else
      eagle_save_screenshot_update_bitmap
    end
  end
end
end
