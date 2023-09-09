#encoding:utf-8
#==============================================================================
# ■ 组件-位图Marshal化（VX/VA）
# 来源：https://rpg.blue/thread-87968-1-1.html
#==============================================================================
$imported ||= {}
$imported["BitmapMarshal"] = "1.0.0"
#=============================================================================
# - 2022.5.4.22
#=============================================================================

class Font
  def marshal_dump;end
  def marshal_load(obj);end
end

class Bitmap
  # 传送到内存的API函数
  RtlMoveMemory_pi = Win32API.new('kernel32', 'RtlMoveMemory', 'pii', 'i')
  RtlMoveMemory_ip = Win32API.new('kernel32', 'RtlMoveMemory', 'ipi', 'i')

  def _dump(limit)
    data = "rgba" * width * height
    RtlMoveMemory_pi.call(data, address, data.length)
    [width, height, Zlib::Deflate.deflate(data)].pack("LLa*") # 压缩
  end

  def self._load(str)
    w, h, zdata = str.unpack("LLa*"); b = new(w, h)
    RtlMoveMemory_ip.call(b.address, Zlib::Inflate.inflate(zdata), w * h * 4); b
  end

  # [[[bitmap.object_id * 2 + 16] + 8] + 16] == 数据的开头
  #
  def address
    buffer, ad = "xxxx", object_id * 2 + 16
    RtlMoveMemory_pi.call(buffer, ad, 4); ad = buffer.unpack("L")[0] + 8
    RtlMoveMemory_pi.call(buffer, ad, 4); ad = buffer.unpack("L")[0] + 16
    RtlMoveMemory_pi.call(buffer, ad, 4); return buffer.unpack("L")[0]
  end
end
