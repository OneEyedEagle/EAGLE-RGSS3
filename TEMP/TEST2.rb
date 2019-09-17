module QTE
  def self.run(sym, params)
    # params[:data] = { frame => [key_sym] }
    @qte_lists[sym] = Spriteset_QTE.new(params)
    @result = nil # true代表成功，false代表失败
  end

  def self.init
    @qte_lists = {} # sym => spriteset
    @buttons = {} # sym => bool
  end
  def self.update
    return if finish?
    update_buttons
    result_flag = true
    @qte_lists.each do |sym, s|
      s.update(@buttons)
      break @result = false if s.finish?(:fail)
      result_flag = false if !s.finish?(:success)
    end
    @result = true if @result.nil? && result_flag
    finish if @result
  end
  BUTTONS = [:UP,:DOWN,:LEFT,:RIGHT]
  def self.update_buttons
    BUTTONS.each do |sym|
      @buttons[sym] = Input.trigger?(sym)
    end
  end

  def self.finish?
    @qte_lists.empty?
  end
  def self.finish
    @qte_lists.each { |sym, s| s.dispose }
    @qte_lists.clear
  end
end

class Spriteset_QTE
  def initialize(params)
    @qtes = [] # 按顺序存储要判定的qte精灵
    @frame = -1 # 当前帧计数
    @result = nil

    @datas = params[:data]
  end
  def update(buttons)
    @frame += 1
    new_qte
    @qtes.each { |s| s.update }
    check_qte(buttons)
  end
  def new_qte
    # frame => [sym]
    return if @datas[@frame].nil?
    s = Sprite_QTE.new(nil, @datas[@frame])
    @qtes.push(s)
  end
  def check_qte(buttons)
    return if @qtes[0].nil?
    result = @qtes[0].check(buttons)
    # 此处处理按键结果
    @qtes.shift.dispose if @qtes[0].finish?
  end

  def finish?(result = nil)
    return @result != nil if result == nil
    return @result == result
  end
  def finish(result)
    @result = result
  end
  def dispose
    @qtes.each { |s| s.dispose }
  end
end

class Sprite_QTE < Sprite
  def initialize(viewport, params)
    super(viewport)
    @key = params[0]
  end
  def udpate
    super
  end
  def check(buttons) # 检查按键判定，返回成功or失败
    result = buttons[@key]
  end
  def finish? # 成功结束？
  end
  def dispose
    super
  end
end
