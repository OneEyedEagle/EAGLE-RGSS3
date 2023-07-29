#==============================================================================
# ■ 按键扩展 by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
#==============================================================================
$imported ||= {}
$imported["EAGLE-InputEX"] = "2.0.0"
#=============================================================================
# - 2023.7.29.21 
#=============================================================================
# - 本插件新增了一系列按键判定方法（不修改默认Input模块）
#-----------------------------------------------------------------------------
# - 以下方法中， key 为自定义的按键标识符，可见 KEY_LIST 表中的键值
#
#  1. 指定按键是否从 未按下 到 按下
#
#      INPUT_EX.trigger?(key)  或  INPUT_EX.down?(key)
#
#  2. 指定按键是否从 按下 到 未按下
#
#      INPUT_EX.release?(key)  或  INPUT_EX.up?(key)
#
#  3. 指定按键是否上一帧和这一帧都为 按下 状态
#
#      INPUT_EX.press?(key)
#
#  4. 获取指定按键持续按下的帧数
#
#      INPUT_EX.count(key)
#
# - 示例：
#
#   INPUT_EX.trigger?(:SPACE) → 返回空格键是否在当前帧从未按下到按下状态
#
#=============================================================================
module INPUT_EX
  #--------------------------------------------------------------------------
  # ● 【常量】定义按键标识符
  #--------------------------------------------------------------------------
  KEY_LIST = {
    # 按键 => 十进制编码（查表获得）
    # 鼠标
    :ML => 1, :MR => 2, :MM => 4,
    # 键盘
    :TAB => 9, :SHIFT => 16, :CTRL => 17, :ALT => 18, :CAPS => 20,
    :ESC => 27, :SPACE => 32,
    :LEFT => 37, :UP => 38, :RIGHT => 39, :DOWN => 40,
    :A => 65,:B => 66,:C => 67,:D => 68,:E => 69,:F => 70,:G => 71,
    :H => 72,:I => 73,:J => 74,:K => 75,:L => 76,:M => 77,:N => 78,
    :O => 79,:P => 80,:Q => 81,:R => 82,:S => 83,:T => 84,
    :U => 85,:V => 86,:W => 87,:X => 88,:Y => 89,:Z => 90,
  }

  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def self.init
    @getKeyboardState = Win32API.new('user32', 'GetKeyboardState', 'p', 'i')
    @keys_state_str = "\0" * 256
    @keys_state = []
    @keys_last_state = [0] * 256
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def self.update
    init if @keys_state == nil
    @keys_state.each_with_index do |v, i|
      next @keys_last_state[i] = 0 if v <= 1
      @keys_last_state[i] += 1 if v > 1
    end
    @getKeyboardState.call(@keys_state_str)
    @keys_state = @keys_state_str.unpack('C*') # index to key_state
  end
  #--------------------------------------------------------------------------
  # ● 获取按键编码
  #--------------------------------------------------------------------------
  def self.get_keycode(key)
    key.is_a?(Symbol) ? KEY_LIST[key] : key
  end
  #--------------------------------------------------------------------------
  # ● 指定键从未按下到按下？
  #--------------------------------------------------------------------------
  def self.down?(key)
    keycode = get_keycode(key)
    return false if @keys_state[keycode] == nil
    @keys_last_state[keycode] == 0 && @keys_state[keycode] > 1
  end
  def self.trigger?(key)
    down?(key)
  end
  #--------------------------------------------------------------------------
  # ● 指定键从按下到未按下？
  #--------------------------------------------------------------------------
  def self.up?(key)
    keycode = get_keycode(key)
    return false if @keys_state[keycode] == nil
    @keys_last_state[keycode] > 0 && @keys_state[keycode] <= 1
  end
  def self.release?(key)
    up?(key)
  end
  #--------------------------------------------------------------------------
  # ● 指定键一直被按住？
  #--------------------------------------------------------------------------
  def self.press?(key)
    keycode = get_keycode(key)
    return false if @keys_state[keycode] == nil
    @keys_last_state[keycode] > 1 && @keys_state[keycode] > 1
  end
  #--------------------------------------------------------------------------
  # ● 获取按键被按住的帧数
  #--------------------------------------------------------------------------
  def self.count(key)
    keycode = get_keycode(key)
    @keys_last_state[keycode]
  end
end
class << Input
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  alias eagle_input_ex_update update
  def update
    eagle_input_ex_update
    INPUT_EX.update
  end
end
class << DataManager
  #--------------------------------------------------------------------------
  # ● 初始化模块
  #--------------------------------------------------------------------------
  alias eagle_input_ex_init init
  def init
    INPUT_EX.init
    eagle_input_ex_init
  end
end

=begin
------------键值表------------
常数名称	十六进制值	十进制值	对应按键
VK_LBUTTON	01	1	鼠标的左键
VK_RBUTTON	02	2	鼠标的右键
VK-CANCEL	03	3	Ctrl+Break(通常不需要处理)
VK_MBUTTON	04	4	鼠标的中键（三按键鼠标)
VK_BACK	08	8	Backspace键
VK_TAB	09	9	Tab键
VK_CLEAR	0C	12	Clear键（Num Lock关闭时的数字键盘5）
VK_RETURN	0D	13	Enter键
VK_SHIFT	10	16	Shift键
VK_CONTROL	11	17	Ctrl键
VK_MENU	12	18	Alt键
VK_PAUSE	13	19	Pause键
VK_CAPITAL	14	20	Caps Lock键
VK_ESCAPE	1B	27	Ese键
VK_SPACE	20	32	Spacebar键
VK_PRIOR	21	33	Page Up键
VK_NEXT	22	34	Page Domw键
VK_END	23	35	End键
VK_HOME	24	36	Home键
VK_LEFT	25	37	LEFT ARROW 键(←)
VK_UP	26	38	UP ARROW键(↑)
VK_RIGHT	27	39	RIGHT ARROW键(→)
VK_DOWN	28	40	DOWN ARROW键(↓)
VK_Select	29	41	Select键
VK_PRINT	2A	42
VK_EXECUTE	2B	43	EXECUTE键
VK_SNAPSHOT	2C	44	Print Screen键（抓屏）
VK_Insert	2D	45	Ins键(Num Lock关闭时的数字键盘0)
VK_Delete	2E	46	Del键(Num Lock关闭时的数字键盘.)
VK_HELP	2F	47	Help键
VK_0	30	48	0键
VK_1	31	49	1键
VK_2	32	50	2键
VK_3	33	51	3键
VK_4	34	52	4键
VK_5	35	53	5键
VK_6	36	54	6键
VK_7	37	55	7键
VK_8	38	56	8键
VK_9	39	57	9键
VK_A	41	65	A键
VK_B	42	66	B键
VK_C	43	67	C键
VK_D	44	68	D键
VK_E	45	69	E键
VK_F	46	70	F键
VK_G	47	71	G键
VK_H	48	72	H键
VK_I	49	73	I键
VK_J	4A	74	J键
VK_K	4B	75	K键
VK_L	4C	76	L键
VK_M	4D	77	M键
VK_N	4E	78	N键
VK_O	4F	79	O键
VK_P	50	80	P键
VK_Q	51	81	Q键
VK_R	52	82	R键
VK_S	53	83	S键
VK_T	54	84	T键
VK_U	55	85	U键
VK_V	56	86	V键
VK_W	57	87	W键
VK_X	58	88	X键
VK_Y	59	89	Y键
VK_Z	5A	90	Z键
VK_NUMPAD0	60	96	数字键0键
VK_NUMPAD1	61	97	数字键1键
VK_NUMPAD2	62	98	数字键2键
VK_NUMPAD3	62	99	数字键3键
VK_NUMPAD4	64	100	数字键4键
VK_NUMPAD5	65	101	数字键5键
VK_NUMPAD6	66	102	数字键6键
VK_NUMPAD7	67	103	数字键7键
VK_NUMPAD8	68	104	数字键8键
VK_NUMPAD9	69	105	数字键9键
VK_MULTIPLY	6A	106	数字键盘上的*键
VK_ADD	6B	107	数字键盘上的+键
VK_SEPARATOR	6C	108	Separator键
VK_SUBTRACT	6D	109	数字键盘上的-键
VK_DECIMAL	6E	110	数字键盘上的.键
VK_DIVIDE	6F	111	数字键盘上的/键
VK_F1	70	112	F1键
VK_F2	71	113	F2键
VK_F3	72	114	F3键
VK_F4	73	115	F4键
VK_F5	74	116	F5键
VK_F6	75	117	F6键
VK_F7	76	118	F7键
VK_F8	77	119	F8键
VK_F9	78	120	F9键
VK_F10	79	121	F10键
VK_F11	7A	122	F11键
VK_F12	7B	123	F12键
VK_NUMLOCK	90	144	Num Lock 键
VK_SCROLL	91	145	Scroll Lock键
上面没有提到的：（都在大键盘）
VK_LWIN		91	左win键
VK_RWIN		92	右win键
VK_APPS		93	右Ctrl左边键，点击相当于点击鼠标右键，会弹出快捷菜单
186	;(分号)
187	=键
188	,键(逗号)
189	-键(减号)
190	.键(句号)
191	/键
192	`键(Esc下面)
219	[键
220	\键
221	]键
222	‘键(引号)
=end
