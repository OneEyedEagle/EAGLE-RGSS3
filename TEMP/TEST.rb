module Chapter
  CHAPTERS = {
  #"name" => { # 章节标识符，与事件名称一致
  #  :type => :sym, # 类型符号 :main :explore :doc :battle :
  #  :title => "", # 章节名
  #  :info  => "", # 简介
  #  :actors => [], # 入队角色
  #  :pre => [], # 解锁所需的前置章节的标识符
  #  :conds => { "eval_string" => "info" }, # 附加的解锁条件
  #},
  }
  def self.info(sym, sym_info)
    return nil if !CHAPTERS.has_key?(sym)
    hash_ = CHAPTERS[sym]
    return hash_[sym_info] if hash_[sym_info]
    case sym_info
    when :type; return :main
    when :title, :info; return ""
    when :actors, :pre; return []
    when :conds; return {}
  end

  def self.fin(sym)
    return if fin?(sym)
    @chapters_finish.push(sym)
    @flags_temp.each do |s, t|
      if flag?(s)
      else
        @flags.push(s)
      end
    end
    save
  end
  def self.fin?(sym)
    @chapters_finish.include?(sym)
  end
  def self.add_flag(flag_sym, text_unlock = "")
    @flags_temp[flag_sym] = text_unlock
  end
  def self.flag?(flag_sym) # 指定flag已经解锁？
    @flags[flag_sym]
  end
#=============================================================================
# ○ 文件管理
#=============================================================================
  #--------------------------------------------------------------------------
  # ○ 初始化
  #--------------------------------------------------------------------------
  def self.init
    @chapters_finish = []
    @flags = {}
  end
  #--------------------------------------------------------------------------
  # ○ 获取文件名称
  #--------------------------------------------------------------------------
  def self.get_filename(index)
    sprintf(FILE_NAME, index+1)
  end
  #--------------------------------------------------------------------------
  # ○ 存储
  #--------------------------------------------------------------------------
  def self.save(index)
    File.open(get_filename(index), "wb") do |file|
      Marshal.dump(@chapters_finish, file)
      Marshal.dump(@flags, file)
    end
  end
  #--------------------------------------------------------------------------
  # ○ 读取
  #--------------------------------------------------------------------------
  def self.load(index)
    File.open(get_exs_filename(index), "rb") do |file|
      @chapters_finish = Marshal.load(file)
      @flags = Marshal.load(file)
    end rescue init
    @flags_temp = {} # 存储临时用数据
  end
end

# 在事件解释器中新增方法，用于处理地图上按键开启章节选择UI
class Game_Event
  attr_reader :event
end
class Game_Interpreter
  def call_chapter_ui
    sym = $game_map.events[@event_id].event.name
    # 生成信息窗口
    if Chapter.info(sym, :name) != nil
    end
    # 利用公共事件生成选项（进入、返回、读档）

  end
end
