# 事件触发器

class Game_Event
  def msg_trigger_init
    @eagle_msg_labels = []
    @interpreter_eagle = Game_Interpreter.new
  end

  def msg_trigger(msg_label)
    @eagle_msg_labels.push( msg_label.upcase )
  end

  def get_msg_list(msg_label)
    list_start = false
    eagle_list = []
    @event.pages.size.times do |p_i|
      page = @event.pages[i]
      page.list.size.times do |i|
        if page.list[i].code == 118
          label = page.list[i].parameters[0]
          if list_start
            break if label == "END"
          else
            next list_start = true if label == msg_label
          end
        end
        eagle_list.push(page.list[i]) if list_start
      end
      break if list_start
    end
    return eagle_list
  end

  alias eagle_event_msg_trigger_update update
  def update
    eagle_event_msg_trigger_update
    if !@eagle_msg_labels.empty? && !@interpreter_eagle.running?
      sym = @eagle_msg_labels.shift
      @interpreter_eagle.setup(get_msg_list(sym), @event.id)
    end
    @interpreter_eagle.update
  end
end
