module ::API_List

	DragAcceptFiles 	= Win32API.new('shell32','DragAcceptFiles','ll','v')
	DragQueryFile 		= Win32API.new('shell32','DragQueryFile','llpl','i')
	DragFinish 			= Win32API.new('shell32','DragFinish','l','v')

	CloseHandle 		= Win32API.new('kernel32','CloseHandle','l','l')
	CreateFile 			= Win32API.new('kernel32','CreateFile','pllplll','l')
	CreateFileMapping 	= Win32API.new('kernel32','CreateFileMapping','lplllp','l')
	MapViewOfFile 		= Win32API.new('kernel32','MapViewOfFile','lllll','l')
	UnmapViewOfFile 	= Win32API.new('kernel32','UnmapViewOfFile','l','l')
	RtlMoveMemoryPL 	= Win32API.new('kernel32','RtlMoveMemory','pll','l')
	RtlMoveMemoryLP 	= Win32API.new('kernel32','RtlMoveMemory','lpl','l')
	RtlMoveMemoryPP 	= Win32API.new('kernel32','RtlMoveMemory','ppl','l')
	GetModuleHandle		= Win32API.new('kernel32','GetModuleHandle','p','i')
	GetProcAddress		= Win32API.new('kernel32','GetProcAddress','ip','l')
	MultiByteToWideChar	= Win32API.new('kernel32', 'MultiByteToWideChar', 'ilpipi', 'i')
	WideCharToMultiByte	= Win32API.new('kernel32', 'WideCharToMultiByte', 'ilpipipp', 'i')

	GetWindowLong		= Win32API.new('user32','GetWindowLong','ii','i')
	SetWindowLong		= Win32API.new('user32','SetWindowLong','iii','i')

	Malloc				= Win32API.new('msvcrt','malloc','i','i')
	Memcpy				= Win32API.new('msvcrt','memcpy','ipi','v')

end


# by 晴兰
# 乱改 by fux2
module ::WndProc

  include API_List

  module_function
  def getwndproc
    @wndproc
  end
  def setwndproc(obj)
    @wndproc = obj
  end
  def hwnd
    return @hwnd
  end
  def findProc(l, n)
    lib = GetModuleHandle.call(l)
    ret = GetProcAddress.call(lib, n)
    return ret
  end
  def enable
    @hwnd = INPUT_EX.get_cur_window  # $win_handle
    sprintf     = findProc("msvcrt","sprintf")
    rgsseval    = findProc("RGSS300","RGSSGetInt")
    defv        = findProc("user32","CallWindowProcA")
    old         = GetWindowLong.call(@hwnd, -4)
    buf         = Malloc.call(1024)  
    fmt         = Malloc.call(2048)
    sprintfvar  = Malloc.call(8)
    rgssevalvar = Malloc.call(8)
    oldvar      = Malloc.call(8)
    fmtvar      = Malloc.call(8)
    bufvar      = Malloc.call(8)
    defvar      = Malloc.call(8)
    magic_str   = "WndProc.getwndproc.call(%d,%d,%d,%d)"
    RtlMoveMemoryPP.call(fmt,magic_str,magic_str.size)
    Memcpy.call(sprintfvar, [sprintf].pack("i"),  4)
    Memcpy.call(rgssevalvar,[rgsseval].pack("i"), 4)
    Memcpy.call(oldvar,     [old].pack("i"),      4)
    Memcpy.call(fmtvar,     [fmt].pack("i"),      4)
    Memcpy.call(bufvar,     [buf].pack("i"),      4)
    Memcpy.call(defvar,     [defv].pack("i"),     4)
    @code =  [0x55,0x89,0xE5,0x8B,0x45,0x0C,0xFF,0x75,0x14,0xFF,0x75,0x10,0xFF,0x75,0x0c,0xFF,0x75,0x08].pack("C*")
    @code << [0x3D,0x0A,0x02,0x00,0x00,0x75,0x1D].pack("C*")
    @code << [0xFF,0x35].pack('C*')  << [fmtvar].pack('l')
    @code << [0xFF,0x35].pack('C*') << [bufvar].pack('l') 
    @code << [0xFF,0x15].pack('C*') << [sprintfvar].pack("l")
    @code << [0xFF,0x15].pack('C*') << [rgssevalvar].pack("l")
    @code << [0x83,0xC4,0x18,0xEB,0x0F].pack('C*')
    @code << [0xFF,0x35].pack('C*') << [oldvar].pack("l")
    @code << [0xFF,0x15].pack('C*') << [defvar].pack("l")
    @code << [0x83,0xC4,0x10].pack("C*")
    @code << [0xC9,0xC2,0x10,0x00].pack('C*')
    @shellcode  = Malloc.call(2048)
    Memcpy.call(@shellcode, @code, @code.size)
    @@oHandle   = SetWindowLong.call(@hwnd, -4, @shellcode)
  end

  def init
    enable unless $hacked
    setwndproc (
        lambda {|hwnd, msg, wp, lp| 
            p wp  # 返回鼠标滚轮状态
        }
    )
  end
end

class << DataManager
  #--------------------------------------------------------------------------
  # ● 初始化模块
  #--------------------------------------------------------------------------
  alias eagle_input_msg_ex_init init
  def init
    eagle_input_msg_ex_init
    WndProc.init
  end
end
