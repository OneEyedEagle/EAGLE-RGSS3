#encoding:utf-8
#==============================================================================
# 字符串编码转换 by 灼眼的夏娜
# 来源：http://rpg.blue/thread-222831-1-1.html
#==============================================================================

#==============================================================================
# ■ String
#------------------------------------------------------------------------------
# 　String 类追加定义。
#==============================================================================

class String
  #----------------------------------------------------------------------------
  # ● API
  #----------------------------------------------------------------------------
  @@MultiByteToWideChar  = Win32API.new('kernel32', 'MultiByteToWideChar', 'ilpipi', 'i')
  @@WideCharToMultiByte  = Win32API.new('kernel32', 'WideCharToMultiByte', 'ilpipipp', 'i')
  #----------------------------------------------------------------------------
  # ● UTF-8 转 Unicode
  #----------------------------------------------------------------------------
  def u2w
    i = @@MultiByteToWideChar.call(65001, 0 , self, -1, nil,0)
    buffer = "\0" * (i*2)
    @@MultiByteToWideChar.call(65001, 0 , self, -1, buffer, i)
    buffer.chop!
    return buffer
  end
  #----------------------------------------------------------------------------
  # ● UTF-8 转系统编码
  #----------------------------------------------------------------------------
  def u2s
    i = @@MultiByteToWideChar.call(65001, 0 , self, -1, nil,0)
    buffer = "\0" * (i*2)
    @@MultiByteToWideChar.call(65001, 0 , self, -1, buffer, i)
    i = @@WideCharToMultiByte.call(0, 0, buffer, -1, nil, 0, nil, nil)
    result = "\0" * i
    @@WideCharToMultiByte.call(0, 0, buffer, -1, result, i, nil, nil)
    result.chop!
    return result
  end
  #----------------------------------------------------------------------------
  # ● 系统编码转 UTF-8
  #----------------------------------------------------------------------------
  def s2u
    i = @@MultiByteToWideChar.call(0, 0, self, -1, nil, 0)
    buffer = "\0" * (i*2)
    @@MultiByteToWideChar.call(0, 0, self, -1, buffer, buffer.size / 2)
    i = @@WideCharToMultiByte.call(65001, 0, buffer, -1, nil, 0, nil, nil)
    result = "\0" * i
    @@WideCharToMultiByte.call(65001, 0, buffer, -1, result, result.size, nil, nil)
    result.chop!
    return result
  end
end

#==============================================================================
# ○ 来自黄鸡（http://rpg.blue/home.php?mod=space&uid=65553）
#==============================================================================
module FUX2
  #--------------------------------------------------------------------------
  # ● 读取加密档案中的TXT文本（不破坏原有load_data方法）
  #--------------------------------------------------------------------------
  def self.read_data(name)
    x = Marshal.method(:load)
    y = class << Marshal; self; end
    y.send(:define_method, :load){|f,*args| f.respond_to?(:read) ? f.read : f.to_s}
    ret = load_data(name)
    y.send(:define_method, :load, x)
    ret.s2u
  end
end
