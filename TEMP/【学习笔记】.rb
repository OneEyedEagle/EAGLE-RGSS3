#=============================================================================
# Win32API
# http://www.rubytips.org/2008/05/13/accessing-windows-api-from-ruby-using-win32api-library/
#=============================================================================
require "Win32API"
# Returns current logged in Windows user name
def getUserName
  name = " " * 128
  size = "128"
  Win32API.new('advapi32','GetUserName', ['P','P'],'I').call(name,size)
  return name.unpack("A*")
end
p getUserName

#=============================================================================
# 单件方法 - 重定义指定实例中的方法
#=============================================================================
class A
  def a; p 1; end
end

_a = A.new
_a.a # => 1
def _a.a # 单件方法
  A.instance_method(:a).bind(self).call
  p 2
end
_a.a # => 1\n2

_b = A.new
_b.a # => 1
