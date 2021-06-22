# 简化转义符
# 新增脸图名称定义姓名

module MESSAGE_EX

  def self.check_face_to_name(face_name)
  end
end

class Window_EagleMessage
  alias eagle_face2name_draw_name process_draw_name
  def process_draw_name
    MESSAGE_EX.check_face_to_name(game_message.face_name)
    eagle_face2name_draw_name
  end
end
