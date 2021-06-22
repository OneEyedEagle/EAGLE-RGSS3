# 新增脸图名称定义姓名

module MESSAGE_EX

  FACE_TO_NAME = {

  }

  def self.check_face_to_name(face_name)
    return nil # 查找失败
  end
end

class Window_EagleMessage
  alias eagle_face2name_draw_name process_draw_name
  def process_draw_name
    if name_params[:name] == ""
      n = MESSAGE_EX.check_face_to_name(game_message.face_name)
      name_params[:name] = n if n
    end
    eagle_face2name_draw_name
  end
end
