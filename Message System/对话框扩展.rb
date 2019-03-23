#=============================================================================
# ■ 对话框扩展 by 老鹰（http://oneeyedeagle.lofter.com/）
#=============================================================================
$imported ||= {}
$imported["EAGLE-MessageEX"] = true
#=============================================================================
# - 2019.3.24.0 统一格式
#=============================================================================
# - 对话框中对于 \code[param] 类型的转义符，传入param串、执行code相对应的指令
# - 指令名 code 解析：
#     下列指定的各类英文字符组合
# - 变量参数字符串 param 解析：
#     param 由 变量名（字母组合） + 参数值（正负数字/nil 用$符号代替） 重复构成
#    当传入 无 变量名 的 参数值 时，将存入其【默认】变量
#    而未被传入值的 变量 ，则默认读取上一次所设置的值
#   （其中带有【重置】的变量，每一次都会被默认值覆盖）
# - 示例：
#     \foo[1b-1tc0d$] 【默认】变量名称 a
#    → 调用 foo 所对应的指令，并给所有变量传入预设值
#       再给 a 变量传入值 1，b 变量传入值 -1，tc 变量传入值 0，d 变量传入值 nil
# - 注意：
#    ·转义符的全部内容（\code[param]）均不会被绘制
#    ·指令和变量参数字符串的大小写差异不会影响读取
#    ·转义符会在绘制到达时生效
#    ·转义符若有【预先】，则会在绘制开始前生效（中途绘制到时不会再次生效）
#    ·转义符若有【结尾】，则只在全部文字绘制完成后生效
#-----------------------------------------------------------------------------
# ● 转义符及其变量列表
#-----------------------------------------------------------------------------
# - 控制类
#    对于带有 是否 描述的bool变量，数字 0 代表 false，正数（推荐数字 1）代表 true
#    对于未说明 nil 时效果的变量，请尽量不要传入 nil/$
#
#  \new_line 与 \nl - 换行（同编辑器中的手动回车）
#
#  \font[param] - 对话框绘制单个字体的设置（默认Font模块的设置）
#    size - 【默认】字体大小
#    i - 更改是否斜体绘制
#    b - 更改是否加粗绘制
#    s - 更改是否加上阴影绘制
#    ca - 更改绘制颜色的不透明度（0~255）
#    o - 更改是否加上边框绘制
#    or/og/ob/oa - 更改边框颜色RGB与不透明度（0~255）
#    p - 设置底部花纹的类型（0不绘制，1边框，2实心方框）
#    pc - 设置底部花纹的颜色索引号
#    l - 更改是否绘制外发光
#    lc - 设置外发光的颜色索引号
#    d - 更改是否绘制删除线
#    dc - 设置删除线的颜色索引号（默认0）（具体查看Windowskin右下角部分）
#    u - 更改是否绘制下划线
#    uc - 设置下划线的颜色索引号（默认0）
#
#  \win[param] - 对话框的基本设置
#    o - 【默认】设置对话框的显示原点位置的类型（对应九宫格小键盘位置）（默认左上角7）
#    z - 设置对话框的z值（仅正整数有效）（默认同va设置200）
#    x/y - 设置对话框原点位置的x、y（默认nil，即按照va设置）
#    do - 相对于屏幕的九宫格位置类型（覆盖x/y设置）（-1~-9为有效值）
#    dx/dy - 指定x、y方向上的偏移量（默认0）
#    w - 设置对话框的固定宽度（默认0不设置）
#    dw - 设置对话框的宽度是否随着文字绘制而动态变更（默认false）
#    fw - 设置对话框的宽度是否直接指定为全部文字所需宽度值（dw为true时有效）
#    wmin/wmax - 设置对话框宽度的上下限（dw为true时生效）（默认0不设置）
#    h - 设置对话框的固定高度（默认为0代表不设置）（若值小于line_height方法返回值，则认定为行数）
#    dh - 设置对话框的高度是否随着文字绘制而动态变更（默认false）（不会自动翻页）
#    fh - 设置对话框的高度是否直接指定为全部文字所需高度值（dh为true时有效）
#    hmin/hmax - 设置对话框高度的上下限（dh为true时生效）（若值小于行高，则认定为行数）
#    ali - 设置文本的对齐方式（0左对齐，1居中对齐，2右对齐；默认0）
#    ck - 缩减的字符间距值（默认0）
#    lh - 增加的行间距值（默认0）（默认行间距为0）（默认行高修改为当前行最大字号）
#    cwait - 单个文字绘制完成后的等待帧数（默认1）
#    cfast - 是否允许按键快进（默认true）
#    se - 设置打字音类型index（默认0，按设置进行 index → 声效SE设置 映射）
#    skin - 对话框所用windowskin的index（按设置进行 index → skin名称 映射）
#
#  \pop[param] - pop类型对话框的设置
#    id - 【重置】【默认】所绑定的对象id
#       （【地图】0为执行当前对话的事件；正数为当前地图id号事件，不存在时取当前事件；
#                负数为队列中数据库id号角色，不存在时取队首）
#       （【战斗】正数为敌人index序号；负数为数据库id号我方角色；不存在时则无效）
#    do - 设置对话框相对于绑定对象的位置类型（对应九宫格小键盘）（默认事件顶部中间8）
#    d - 对话框显示原点与所绑定事件格子中心的x与y方向上远离偏移值（默认0）
#    dx/dy - 指定x、y方向上的偏移量（默认0）
#    w - 指定pop对话框的固定宽度（覆盖win中的w）（默认0不设置）
#    h - 指定pop对话框的固定高度（覆盖win中的h）（若值小于line_height方法返回值，则认定为行数）
#    dw - 设置pop对话框的宽度是否随着文字绘制而动态变更（默认false）
#    fw - 设置pop对话框的宽度是否直接指定为全部文字所需宽度值（dw为true时有效）
#    dh - 设置pop对话框的高度是否随着文字绘制而动态变更（默认false）（不会自动翻页）
#    fh - 设置pop对话框的高度是否直接指定为全部文字所需高度值（dw为true时有效）
#    skin - pop对话框所用皮肤的index（默认nil，随win参数）（按设置进行 index → skin名称 映射）
#
#  \popt[param] - 【预先】pop对话框的箭头设置（当对话框为pop类型时才显示）
#    tag - 【默认】设置tag的index（按设置进行 index → tag名称 映射）（默认0）
#    td - 设置与所绑定事件格子中心的距离的远离偏移值（默认0）
#
#  \face[param] - 脸图的动态设置
#    脸图文件名包含 _数字x数字 时，将指定该脸图文件规格为 行数x列数，默认 2行x4列
#    i - 【重置】【默认】更改为显示第index序号的脸图（默认与va对话框设置相同）
#    ls/le - 【重置】设置循环播放的开始index/结束index（负数时代表不循环）（默认-1）
#    lt - 设置循环播放时，每两帧之间的等待间隔帧数
#    lw - 设置循环播放时，每一次loop结束时的等待帧数
#
#  \facep[param] - 【预先】脸图的设置
#    dir - 【默认】脸图的显示位置（0左侧，正数右侧；默认0）
#    m - 设置脸图是否镜像显示（默认false）
#    it/iv/io - 脸图移入时所用帧数/每帧x的增量/每帧不透明度的增量
#    ot/ov/oo - 脸图移出时所用帧数/每帧x的增量/每帧不透明度的减量
#    dy - 脸图在y方向上的偏移增量（默认0）
#    dw - 脸图宽度的增量（默认0）
#
#  \name[param] - 【预先】姓名框的设置
#    param 中用 | 分隔姓名字符串（其中转义符用<>代替[]）与参数（若无参数可省略 |）
#    skin - 姓名框所用皮肤的index（默认nil，同对话框）（按设置进行 index → skin名称 映射）
#    o - 姓名框窗口的显示原点的位置类型（对应九宫格小键盘）（默认为左上角7）
#    do - 姓名框的显示原点居于对话框位置的类型（对应九宫格小键盘）（左上角对齐）（默认左上角7）
#    dx/dy - 姓名框的x、y相对偏移量
#    opa - 设置姓名框背景的不透明度（默认255）（文字的不透明度锁定为255）
#
#  \pause[param] - 设置pause等待按键时的帧动画
#    pause - 【默认】设置pause帧动画的源位图类型（默认0，按设置进行 index → 参数组 映射）
#    o - 帧动画的显示原点位置类型（九宫格小键盘）（默认7）
#    do - 相对于对话框的显示位置类型（对话框上的九宫格位置）（0代表显示到文末）（默认2）
#    dx/dy - xy方向上的偏移调整值（默认0）
#    t - 每两帧之间的等待帧数（默认10）
#    v - 控制是否显示pause动画（默认true）
#
#  \shake[param] - 对话框震动（与事件指令中的屏幕震动一致）并等待至结束
#    p - 设置震动的强度（默认5）
#    s - 设置震动的速度（默认5）
#    t - 【默认】设置震动的持续帧数（最后会补足平滑结束的帧数）（默认40）
#
#  \wait[param] - 等待（在快进状态下，默认的等待类型转义符与该转义符均会被跳过）
#    t - 【默认】设置等待帧数
#
#  \g[c1..] - 渐变描绘【需要前置Sion_GradientText插件】
#    参数字符串为按序排列的 c + Windowskin颜色索引号，无参数传入时代表取消渐变绘制
#    如：\g[c1c2c1] 则表示用1号2号1号颜色由上至下进行渐变绘制
#
#  \hold - 【结尾】保留当前对话框，直至没有该指令的对话框结束，关闭所有保留的对话框
#
#  \instant - 【预先】当前对话框立即显示完毕（先打开，再全部显示内容）
#
#-----------------------------------------------------------------------------
# - 文字特效类
#     以下 param 传入 任意非0非空字符（如 1） 代表以预设值开启特效
#     只传入 0 代表关闭该特效
#    （除非标注【叠加】，否则多特效同时执行可能会造成奇怪效果）
#
#  \cin[param] - 开启文字移入时的特效【独占】（移入完成时才进行其余特效更新）
#    t - 移入所用的帧数（即移动到最终位置的所用帧数）（不透明度从0平滑增加到255）
#    vxt/vx - 每vxt（最小值1）帧x偏移值增加vx像素的值
#    vyt/vy - 每vyt（最小值1）帧y偏移值增加vy像素的值
#    vzt/vz - 每zvt（最小值1）帧zoom放缩值增加vz的值（整数）
#    va - 每帧内angle的增值
#
#  \cout[param] - 开启文字移出时的特效【独占】（移出时关闭其余特效更新）
#    t - 移出所用的帧数（即移动到最终位置的所用帧数）（不透明度从255平滑减小到0）
#    vxt/vx - 每vxt（最小值1）帧x偏移值增加vx像素的值
#    vyt/vy - 每vyt（最小值1）帧y偏移值增加vy像素的值
#    vzt/vz - 每zvt（最小值1）帧zoom放缩值增加vz的值（整数）
#    va - 每帧内angle的增值
#
#  \csin[param] - 开启正弦波浪扭曲特效
#    a - 指定正弦波浪的幅度（像素数）
#    l - 指定正弦波浪的频度（像素数）
#    s - 指定正弦波浪的动画速度（默认360）
#    p - 指定正弦波浪的相位角度（最大360°）（一般不需要设置）
#
#  \cwave[param] - 开启上下浮动特效
#    h - 指定上下浮动的最大偏移像素值
#    t - 指定每隔t帧进行一次1像素的偏移
#    vy - 指定起始时的y方向移动速度（正数为向下）
#
#  \cshake[param] - 开启抖动特效
#    l/r/u/d - 设置 左右上下 四个方向的最大移动偏移值
#    vx/vy - 设置x、y方向上的初始移动速度（正数为向右、向下）（0为随机方向）
#    vxt/vyt - 设置x、y方向上的移动一次后的等待帧数
#
#  \cflash[param] - 开启闪烁特效【叠加】
#    r/g/b/a - 指定闪烁的颜色（红、绿、蓝、不透明度），默认255，如r50g50b100a200
#    d - 指定闪烁从开始到完成需要的帧数
#    t - 指定闪烁完成后的等待帧数
#
#  \cmirror[param] - 开启横轴镜像绘制（无设置参数）【叠加】
#
#  \cu[param] - 开启字符消散特效【叠加】【需要前置Unravel_Bitmap插件】
#    t - 每两次执行消散之间的间隔帧数（正整数）
#    n - 单次消散的粒子总数（估计）
#    d - 单个粒子的大小（直径/边长）
#    o - 单个粒子消失时的透明度变更最小值
#    dir - 整体消散方向类型（同九宫格小键盘）（1379-四角；5-四方向；46-左右向上）
#    s - 粒子形状类型（0-正方向；1-圆形；2-三角形）
#-----------------------------------------------------------------------------
# ● 文本预定
#-----------------------------------------------------------------------------
# - 利用该脚本设置预定文本，下次打开对话框时，将自动将全部预定文本插到对话文本开头
#
#        $game_message.add_escape(param_string)
#
# - param_string 解析： 【String】型常量
# - 示例：
#     $game_message.add_escape("\\win[ali1]")
#        → 在之后的对话框中 文本居中
#     $game_message.add_escape("\\pop[0]")
#        → 下一次的对话框为pop类型，在当前事件上
# - 注意：
#    ·由于解析问题，在 param_string 中请将 "\" 替换成 "\\"
#    ·当存在多条预定文本，将按照预定时间的先后顺序，依次放入下一次对话框的开头
#    ·预定的字符串只会被放入对话框一次
#    ·不会去除 param_string 中的非转义符文本
#-----------------------------------------------------------------------------
# ● 参数重置
#-----------------------------------------------------------------------------
# - 利用该脚本重置（用预设值覆盖）指定指令的指定变量
#
#        $game_message.reset_params(param_sym, code_string)
#
# - param_sym 解析： 【Symbol】型常量
#     :font - 重置关于字体的设置（取Font类的设置）
#     :win  - 重置关于对话框的设置
#     :pop  - 重置关于pop类型对话框与pop的tag类型的设置
#     :face - 重置关于脸图显示的设置
#     :name - 重置关于姓名框的设置
#     :pause- 重置关于pause等待按键的精灵的设置
#  【注意】若传入的param_sym为 nil，则将重置以上所有
# - code_string 解析： 【String】型常量
#     可利用 | 将多个指令参数名进行分割
#     若未传入该参数，则识别为全部参数重置
# - 示例：
#     $game_message.reset_params(:font, "i") - 重置字体里是否斜体的参数
#     $game_message.reset_params(:win, "x|y") - 重置对话框的位置（变回默认va设置）
#     $game_message.reset_params(:pop) - 清除全部关于pop的设置
#-----------------------------------------------------------------------------
# ● 参数保存与读取
#-----------------------------------------------------------------------------
# - 利用该脚本保存当前全部 param_sym 参数组的状态值（同时只能保存一个状态）
#
#         $game_message.save_params
#
# - 利用该脚本使 param_sym 所对应的变量组恢复到上一次的保存状态
#
#         $game_message.load_params(param_sym)
#
# - param_sym 解析：【Symbol】型常量
#      具体见 参数重置 中的解析
# - 示例：
#     $game_message.load_params(:font) - 恢复字体里的全部参数
#     $game_message.load_params(:pause) - 恢复pause精灵的全部参数
#-----------------------------------------------------------------------------
# ● 特别感谢
#-----------------------------------------------------------------------------
# - 葱兔（http://onira.lofter.com/）
#=============================================================================

#=============================================================================
# ○ 【设置部分】
#=============================================================================
module MESSAGE_EX
  #--------------------------------------------------------------------------
  # ● 【设置】定义转义符各参数的预设值
  # （对于bool型变量，0与false等价，1与true等价）
  #--------------------------------------------------------------------------
  FONT_PARAMS_INIT = {
  # \font[]
    :size => Font.default_size, # 字体大小
    :i => Font.default_italic, # 斜体绘制
    :b => Font.default_bold, # 加粗绘制
    :s => Font.default_shadow, # 阴影
    :ca => 255, # 不透明度
    :o => Font.default_outline, # 描边
    :or => Font.default_out_color.red,
    :og => Font.default_out_color.green,
    :ob => Font.default_out_color.blue,
    :oa => Font.default_out_color.alpha,
    :p => 0, # 底纹
    :pc => 0, # 底纹颜色index
    :l => 0, # 外发光
    :lc => 0, # 外发光颜色index
    :d => 0, # 删除线
    :dc => 0, # 删除线颜色index
    :u => 0, # 下划线
    :uc => 0, # 下划线颜色index
  }
  WIN_PARAMS_INIT = {
  # \win[]
    :o => 7, # 原点位置类型 未设置时为7左上角
    :z => 200,
    :x => nil, # 原点坐标xy
    :y => nil,
    :do => 0, # 相较于屏幕的九宫格位置（覆盖x/y的设置）
    :dx => 0, # 坐标偏移值xy
    :dy => 0,
    :w => 0,
    :h => 0,
    :dw => 0, # 若为1，则代表宽度会依据文字动态调整
    :fw => 1, # 若为1，则窗口打开时即为文字绘制完成时所需宽度值（当dw==1时生效）
    :wmin => 0, # 设置宽度的上下限（当dw==1时生效）
    :wmax => 0, # （有脸图时宽度会自动增加脸图宽度）
    :dh => 0, # 若为1，则代表高度会依据文字动态调整
    :fh => 1, # 若为1，则窗口打开时即为文字绘制完成时所需高度值（当dh==1时生效）
    :hmin => 0, # 设置高度的上下限（当dh==1时生效）
    :hmax => 0,
    :ali => 0, # 设置文本对齐方式
    :ck => 0, # 缩减的字符间距值
    :lh => 4, # 增加的行间距值
    :cwait => 2, # 单个文字绘制后的等待帧数（最小值0）
    :cfast => 1, # 是否允许快进
    :se => 1, # 打字音类型（默认0，无声效）
    :skin => 0, # 对话框所用windowskin的类型
  }
  POP_PARAMS_INIT = {
  # \pop[]
    :do => 8, # 对话框相对于绑定对象的位置（九宫格小键盘）
    :d => 0, # 指定原点距离事件格子中心的偏移量
    :dx => 0,  # 指定x、y方向上的偏移量
    :dy => 0,
    :w => 0, # 指定固定的宽度和高度（优先级高于win_params）
    :h => 0,
    :dw => 1, # 若为1，则代表宽度会依据文字动态调整
    :fw => 0, # 若为1，则窗口打开时将预绘制成文字区域最终大小（dw==1时有效）
    :dh => 1, # 若为1，则代表高度会依据文字动态调整
    :fh => 0, # 若为1，则窗口打开时将预绘制成文字区域最终大小（dh==1时有效）
    :skin => nil, # pop模式下所用skin类型
  # \popt[]
    :tag => 1, # tag所用文件名index（0时表示不启用）
    :td => 3, # 与绑定事件格子中心位置的偏移值
  }
  FACE_PARAMS_INIT = {
  # \face[]
    :lt => 30, # 循环时，每两帧之间的间隔
    :lw => 60, # 循环后，等待帧数
  # \facep[]
    :dir => 0, # 脸图显示方向 1为右侧
    :m => 0, # 脸图镜像显示
    :it => 10, # 脸图移入所需帧数
    :iv => 1, # 脸图移入每帧x增量
    :io => 26, # 脸图移入每帧不透明度增量
    :ot => 10, # 脸图移出所需帧数
    :ov => 1, # 脸图移出每帧x增量
    :oo => 26, # 脸图移出每帧不透明度减量
    :dy => 0, # 脸图y方向的偏移增量
    :dw => 8, # 脸图显示宽度的补足量
  }
  NAME_PARAMS_INIT = {
  # \name[]
    :o => 1, # 自身的显示原点位置
    :do => 7, # 相较于对话框的显示原点位置
    :dx => 0, # 位置的偏移增量
    :dy => 0,
    :opa => 255, # 背景不透明度
    :skin => nil, # 皮肤类型
  }
  PAUSE_PARAMS_INIT = {
  # \pause[]
    :pause => 0,  # 源位图index
    :o => 4,  # 自身的显示原点类型
    :do => 0,  # 相对于对话框的显示位置（九宫格小键盘）（0时为在文末）
    :dx => 0,  # xy偏移值
    :dy => 0,
    :t => 7, # 每两帧之间的等待帧数
    :v => 1,  # 是否显示
  }
  #--------------------------------------------------------------------------
  # ● 【设置】定义文字特效类转义符各参数的初始值
  #--------------------------------------------------------------------------
  CIN_PARAMS_INIT = {
  # \cin[]
    :t => 15, # 移入所用帧数
    :vx => 0,  # 每vxt帧x的增量
    :vxt => 1,
    :vy => 0,  # 每vyt帧y的增量
    :vyt => 1,
    :vz => -5,  # 每vzt帧zoom的增量
    :vzt => 1,
    :va => 0,  # 每帧角度增量
  }
  COUT_PARAMS_INIT = {
  # \cout[]
    :t => 15, # 移出所用帧数
    :vx => 0,  # 每vxt帧x的增量
    :vxt => 1,
    :vy => 0,  # 每vyt帧y的增量
    :vyt => 1,
    :vz => 5,  # 每vzt帧zoom的增量
    :vzt => 1,
    :va => 0,  # 每帧角度增量
  }
  CSIN_PARAMS_INIT = {
    :a => 6, # 幅度
    :l => 10, # 频度
    :s => 30, # 速度
    :p => 0, # 相位
  }
  CWAVE_PARAMS_INIT = {
  # \cwave[]
    :h  => 2,  # Y方向上的最大偏移值
    :t  => 4,  # 移动一像素所耗帧数
    :vy => -1, # 起始速度的Y方向分量（正数向下）
  }
  CSHAKE_PARAMS_INIT = {
  # \cshake[]
    :l => 3,  # 距离所在原点的最大偏移量（左右上下）
    :r => 3,
    :u => 3,
    :d => 3,
    :vx  => 0,  # x的初始移动方向（0为随机方向）
    :vxt => 3,  # x方向移动一像素所耗帧数
    :vy  => 0,  # y的初始移动方向（0为随机方向）
    :vyt => 3,  # y方向移动一像素所耗帧数
  }
  CFLASH_PARAMS_INIT = {
  # \cflash[]
    :r => 255, # 闪烁颜色RGBA
    :g => 255,
    :b => 255,
    :a => 255,
    :d => 60,  # 闪烁帧数
    :t => 60,  # 闪烁后的等待时间
  }
  CMIRROR_PARAMS_INIT = {}
  CU_PARAMS_INIT = {
  # \cu[]
    :t => 10, # 每两次消散之间的时间间隔
    :n => 20, # 消散的粒子总数
    :d =>  2, # 消散的粒子的大小（直径/边长）
    :o =>  1, # 透明度变更量的最小值
    :s =>  0, # 粒子的形状类型
    :dir => 4, # 消散方向类型
  }
  #--------------------------------------------------------------------------
  # ● 【设置】定义新游戏开始时对话框预定的转义字符串
  # （由于解析问题，字符串中请将 "\" 替换成 "\\"）
  #--------------------------------------------------------------------------
  ESCAPE_STRING_INIT = ""
  #--------------------------------------------------------------------------
  # ● 【设置】定义\conv[string]转义符与替换后的字符串
  # （由于解析问题，字符串中请将 "\" 替换成 "\\"）
  # （在添加了预定转义符字符串于文本开头后，将对全部文本检查替换）
  # （如果目标转义符是用 <> 代替 []，如姓名框中的内容，则将 "\" 替换成 "\e"）
  #--------------------------------------------------------------------------
  CONVERT_ESCAPE = {
  # String => String,
    "系统" => "\\win[ali1dw1dh1o5do-5dx0dy0]\\pause[do2o5]",
    "底部" => "\\win[ali0dw1dh1o2do-2dx0dy-60]\\pause[do0o4]",
    "顶部" => "\\win[ali0dw1dh1o8do-8dx0dy60]\\pause[do0o4]",
  }
  #--------------------------------------------------------------------------
  # ● 【设置】定义在所有姓名框的名字字符串的最前面增加的转义字符串
  # （具体见draw_text_ex所支持的转义符）
  # （由于解析问题，字符串中请将 "\" 替换成 "\e" ，并用 <> 代替 []）
  #--------------------------------------------------------------------------
  ESCAPE_STRING_NAME_PREFIX = "\ec<9>"
  #--------------------------------------------------------------------------
  # ● 【设置】定义 index → windowskin名称 的映射
  # （其中 index 必须为整数）
  # （图片存储于 Graphics/System 目录下）
  #--------------------------------------------------------------------------
  INDEX_TO_WINDOWSKIN = {
    0 => "Window", # 默认所用皮肤名称
    1 => "Window_Help",
  }
  #--------------------------------------------------------------------------
  # ● 【设置】定义 index → 打字音设置 的映射
  # （音效存储于 Audio/SE 目录下）
  #--------------------------------------------------------------------------
  INDEX_TO_SE = {
  #index => SE文件名, 音量, 音调
    0 => ["", 80, 100], # 默认设置，不推荐修改
    1 => ["Cursor1", 40, 150],
  }
  #--------------------------------------------------------------------------
  # ● 【设置】定义 index → tag名称 的映射
  # （其中 index 必须为正整数；为 0 时代表不启用tag）
  # （图片存储于 Graphics/System 目录下）
  # 【Tag图片解析】任意大小，3帧×3帧规格
  #    7 8 9
  #    4 5 6  ← pop对话框的原点位置类型 与 对应所用的tag位图区域
  #    1 2 3
  # （比如 pop对话框的原点类型为 2 时，tag显示在对话框底部中央，图像使用2号区域）
  # 【注意】tag的存在不会使pop对话框产生额外偏移，请利用pop参数d/dx/dy自行移动
  #--------------------------------------------------------------------------
  INDEX_TO_WINDOWTAG = {
    1 => "Window_Tag", # 默认所用tag名称
  }
  #--------------------------------------------------------------------------
  # ● 【设置】定义 index → pause箭头帧动画参数组 的映射
  # （其中 index 必须为整数）
  # （图片存储于 Graphics/System 目录下）
  # 【注意】帧动画统一从左上开始计为0号位置，并按行优先从左往右遍历
  #--------------------------------------------------------------------------
  INDEX_TO_PAUSE = {
  #         文件名 范围（nil则为整张图） 一行中的帧数 一列中的帧数
  #index=>[String, Rect, Integer, Integer]
   -1 => ["", nil, 1, 1], # 不显示
    0 => ["Window", Rect.new(96,64,32,32), 2, 2], # 默认 使用皮肤窗口里的箭头
  }
end

#=============================================================================
# ○ 读取设置
#=============================================================================
module MESSAGE_EX
  #--------------------------------------------------------------------------
  # ● 获取指定转义符的基础设置
  #--------------------------------------------------------------------------
  def self.get_default_params(param_sym)
    MESSAGE_EX.const_get("#{param_sym.to_s.upcase}_PARAMS_INIT".to_sym) rescue {}
  end
  #--------------------------------------------------------------------------
  # ● 获取\conv[string]的替换字符串
  #--------------------------------------------------------------------------
  def self.get_conv(s)
    CONVERT_ESCAPE[s] || ""
  end
  #--------------------------------------------------------------------------
  # ● 获取姓名框绘制内容的前缀
  #--------------------------------------------------------------------------
  def self.get_name_prefix
    ESCAPE_STRING_NAME_PREFIX
  end
  #--------------------------------------------------------------------------
  # ● 读取对应的 windowskin 位图
  #--------------------------------------------------------------------------
  def self.windowskin(index)
    begin
      return Cache.system(INDEX_TO_WINDOWSKIN[index])
    rescue
      return Cache.system(INDEX_TO_WINDOWSKIN[0])
    end
  end
  #--------------------------------------------------------------------------
  # ● 播放对应的SE
  #--------------------------------------------------------------------------
  def self.se(index)
    params = INDEX_TO_SE[index] || INDEX_TO_SE[0]
    return if params[0] == ""
    volume = params[1] || INDEX_TO_SE[0][1]
    pitch = params[2] || INDEX_TO_SE[0][2]
    Audio.se_play("Audio/SE/" + params[0], volume, pitch)
  end
  #--------------------------------------------------------------------------
  # ● 读取对应的 tag 位图
  #--------------------------------------------------------------------------
  def self.windowtag(index)
    begin
      return Cache.system(INDEX_TO_WINDOWTAG[index]).dup
    rescue
      return Cache.empty_bitmap
    end
  end
  #--------------------------------------------------------------------------
  # ● 依据pop对话框的o，重设对应tag
  # 【返回】true - 成功设置； false - 该方向上无tag显示
  #--------------------------------------------------------------------------
  def self.windowtag_o(window, sprite, tag_bitmap, o, redraw = true)
    if redraw
      sprite.bitmap.clear
      return false if o < 1 || o > 9
      w = sprite.width; h = sprite.height # 单个tag的宽度和高度
      rect = Rect.new( w*(2-(9-o)%3), h*((9-o)/3), w, h)
      sprite.bitmap.blt(0, 0, tag_bitmap, rect)
    end
    window.eagle_reset_xy_dorigin(sprite, window, o)
    window.eagle_reset_xy_origin(sprite, 10 - o)
    return true
  end
  #--------------------------------------------------------------------------
  # ● 读取 pause 按键等待精灵的信息组
  #--------------------------------------------------------------------------
  def self.pause_params(index)
    INDEX_TO_PAUSE[index] || INDEX_TO_PAUSE[0]
  end
#==============================================================================
# ○ 共享方法
#==============================================================================
  #--------------------------------------------------------------------------
  # ● 解析字符串参数
  #--------------------------------------------------------------------------
  def self.parse_param(param_hash, param_text, default_type = "default")
    param_text = param_text.downcase
    # 只有首位是省略名字的参数设置
    t = param_text.slice!(/^\-?\d+/)
    param_hash[default_type.to_sym] = t.to_i if t && t != ""
    while(param_text != "")
      t = param_text.slice!(/^[a-z]+/)
      if param_text[0] == "$"
        param_text.slice!(/^$/)
        next param_hash[t.to_sym] = nil
      end
      param_hash[t.to_sym] = (param_text.slice!(/^\-?\d+/)).to_i
    end
  end
  #--------------------------------------------------------------------------
  # ● 将指定值变更为布尔量
  #--------------------------------------------------------------------------
  def self.check_bool(v)
    return true if v == true
    return false if v.nil? || v == false || v == 0
    return true
  end
  #--------------------------------------------------------------------------
  # ● 重置指定对象的显示原点位置
  #--------------------------------------------------------------------------
  def self.reset_xy_origin(obj, o)
    case o  # 固定不动点的位置类型 以九宫格小键盘察看
    when 1
      obj.y = obj.y - obj.height
    when 2
      obj.x = obj.x - obj.width / 2
      obj.y = obj.y - obj.height
    when 3
      obj.x = obj.x - obj.width
      obj.y = obj.y - obj.height
    when 4
      obj.y = obj.y - obj.height / 2
    when 5
      obj.x = obj.x - obj.width / 2
      obj.y = obj.y - obj.height / 2
    when 6
      obj.x = obj.x - obj.width
      obj.y = obj.y - obj.height / 2
    when 7; return # 【默认】显示原点为左上角
    when 8
      obj.x = obj.x - obj.width / 2
    when 9
      obj.x = obj.x - obj.width
    end
  end
  #--------------------------------------------------------------------------
  # ● 重置指定对象依据另一对象小键盘位置的新位置
  #--------------------------------------------------------------------------
  def self.reset_xy_dorigin(obj, obj2, o) # 左上角和左上角对齐
    if o < 0 # o小于0时，将obj2重置为全屏
      obj2 = Rect.new(0,0,Graphics.width,Graphics.height)
      o = o.abs
    end
    case o
    when 1,4,7; obj.x = obj2.x
    when 2,5,8; obj.x = obj2.x + obj2.width / 2
    when 3,6,9; obj.x = obj2.x + obj2.width
    end
    case o
    when 1,2,3; obj.y = obj2.y + obj2.height
    when 4,5,6; obj.y = obj2.y + obj2.height / 2
    when 7,8,9; obj.y = obj2.y
    end
  end
#==============================================================================
# ○ 定义能够响应的文字特效
#==============================================================================
module CHARA_EFFECTS
  #--------------------------------------------------------------------------
  # ● 移入移出特效预定
  #--------------------------------------------------------------------------
  def eagle_chara_effect_cin(param = '')
  end
  def eagle_chara_effect_cout(param = '')
  end
  #--------------------------------------------------------------------------
  # ● 正弦扭曲特效预定
  #--------------------------------------------------------------------------
  def eagle_chara_effect_csin(param = '')
  end
  #--------------------------------------------------------------------------
  # ● 波浪特效预定
  #--------------------------------------------------------------------------
  def eagle_chara_effect_cwave(param = '')
  end
  #--------------------------------------------------------------------------
  # ● 抖动特效预定
  #--------------------------------------------------------------------------
  def eagle_chara_effect_cshake(param = '')
  end
  #--------------------------------------------------------------------------
  # ● 闪烁特效预定
  #--------------------------------------------------------------------------
  def eagle_chara_effect_cflash(param = '')
  end
  #--------------------------------------------------------------------------
  # ● 镜像特效预定
  #--------------------------------------------------------------------------
  def eagle_chara_effect_cmirror(param = '')
  end
  #--------------------------------------------------------------------------
  # ● 字符消散特效切换
  #--------------------------------------------------------------------------
  if defined?(Unravel_Bitmap)
  def eagle_chara_effect_cu(param = '')
  end
  end
end
end
#=============================================================================
# ○ Game_Message
#=============================================================================
class Game_Message
  include MESSAGE_EX::CHARA_EFFECTS
  attr_accessor :font_params, :win_params, :pop_params
  attr_accessor :face_params, :name_params, :pause_params
  attr_accessor :chara_params, :chara_grad_colors, :escape_strings
  attr_accessor :hold, :instant, :draw
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  alias eagle_message_ex_init initialize
  def initialize
    eagle_message_ex_init
    set_default_params
  end
  #--------------------------------------------------------------------------
  # ● 获取全部可保存params的符号的数组
  #--------------------------------------------------------------------------
  def eagle_params
    [:font, :win, :pop, :face, :name, :pause]
  end
  #--------------------------------------------------------------------------
  # ● 获取params的初始值
  #--------------------------------------------------------------------------
  def set_default_params
    @chara_params = {} # 存储预设的文字精灵效果 # code_symbol => param_string
    @chara_grad_colors = [] # 存储渐变绘制的颜色数组
    @escape_strings = [] # 存储等待执行的转义符字符串
    eagle_params.each do |sym|
      self.send((sym.to_s+"_params=").to_sym, MESSAGE_EX.get_default_params(sym).dup)
      add_escape("\\#{sym}") # 添加一次预定调用，用于应用初始值
    end
  end
  #--------------------------------------------------------------------------
  # ● 清除
  #--------------------------------------------------------------------------
  alias eagle_message_ex_clear clear
  def clear
    eagle_message_ex_clear
    @draw = true # 真实绘制？
    @hold = false # 当前对话框要保留显示？
    @instant = false # 当前对话框立即显示？
  end
  #--------------------------------------------------------------------------
  # ● 判定是否需要进入等待按键状态
  #--------------------------------------------------------------------------
  def input_pause?
    !(choice? || num_input? || item_choice?)
  end
  #--------------------------------------------------------------------------
  # ● 使用pop类型？
  #--------------------------------------------------------------------------
  def pop?
    @pop_params[:id] != nil
  end
  #--------------------------------------------------------------------------
  # ● 使用脸图？
  #--------------------------------------------------------------------------
  def face?
    @face_params[:name] != ""
  end
  #--------------------------------------------------------------------------
  # ● 使用姓名框？
  #--------------------------------------------------------------------------
  def name?
    @name_params[:name] != ""
  end
  #--------------------------------------------------------------------------
  # ● 重置指定参数
  #--------------------------------------------------------------------------
  def reset_params(param_sym, code_string = nil)
    return eagle_params.each{|sym| reset_params(sym)} if param_sym.nil?
    default_params = MESSAGE_EX.get_default_params(param_sym)
    if code_string.nil? # 直接清除全部参数
      new_params = default_params.dup
    else
      new_params = method( param_sym.to_s + "_params" ).call.dup # 获取旧的hash
      code_string.split("|").each { |c|
        new_params[c.to_sym] = default_params[c.to_sym]
      }
    end
    self.send((param_sym.to_s+"_params=").to_sym, new_params)
    add_escape("\\#{param_sym}") # 添加一次预定调用，用于应用结果
  end
  #--------------------------------------------------------------------------
  # ● 保存当前状态
  #--------------------------------------------------------------------------
  def save_params
    @last_save_game_message = clone
  end
  #--------------------------------------------------------------------------
  # ● 读取保存状态
  #--------------------------------------------------------------------------
  def load_params(param_sym)
    return false if @last_save_game_message.nil?
    return eagle_params.each{|sym| load_params(sym)} if param_sym.nil?
    m = param_sym.to_s + "_params"
    self.send( (m+"=").to_sym, @last_save_game_message.send(m.to_sym).clone )
    return true
  end
  #--------------------------------------------------------------------------
  # ● 参数拷贝
  #--------------------------------------------------------------------------
  def clone
    t = Game_Message.new
    t.visible = true
    eagle_params.each do |sym|
      m = "#{sym}_params"
      t.send("#{m}=".to_sym, method(m.to_sym).call.clone)
    end
    t
  end
  #--------------------------------------------------------------------------
  # ● 下一次对话时要解析的转义符
  # 【由于解析问题，字符串中请将 "\" 替换成 "\e" 】
  #--------------------------------------------------------------------------
  def add_escape(string)
    @escape_strings.push(string)
  end
end
#=============================================================================
# ○ Window_Message
#=============================================================================
class Window_Message
  attr_reader :eagle_charas_w, :eagle_charas_h
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  alias eagle_message_ex_init initialize
  def initialize
    eagle_message_ex_init
    eagle_message_init_assets
    eagle_message_init_params
  end
  #--------------------------------------------------------------------------
  # ● 初始化组件
  #--------------------------------------------------------------------------
  def eagle_message_init_assets
    @eagle_chara_sprites = [] # 存储全部的文字精灵
    @eagle_sprite_pop_tag = Sprite.new # 初始化pop状态下的tag精灵
    @eagle_sprite_face = Sprite.new # 初始化脸图精灵
    @eagle_window_name = Window_Base.new(0, 0, 1, 1) # 初始化姓名框窗口
    @eagle_sprite_pause = Sprite_EaglePauseTag.new(self) # 初始化等待按键的精灵
  end
  #--------------------------------------------------------------------------
  # ● 初始化参数
  #--------------------------------------------------------------------------
  def eagle_message_init_params
    self.arrows_visible = false # contents未完全显示时出现的箭头
    @in_battle = SceneManager.scene_is?(Scene_Battle) # 战斗场景中？
    @last_windowskin_index = nil # 上一次所绘制的窗口皮肤的index
    @windows_dup = [] # 存储全部拷贝的窗口
    eagle_reset_pop_tag_bitmap # 重置tag的位图
    eagle_message_reset
  end
  #--------------------------------------------------------------------------
  # ● 获取主参数
  #--------------------------------------------------------------------------
  def game_message
    $game_message
  end
  #--------------------------------------------------------------------------
  # ● 拷贝
  #--------------------------------------------------------------------------
  def clone
    t = Window_Message_Clone.new(game_message.clone)
    t.game_message.win_params[:z] = 0
    t.x = self.x; t.y = self.y; t.width = self.width; t.height = self.height
    t.z = self.z - 5
    # 拷贝文字组
    t.eagle_chara_sprites = @eagle_chara_sprites
    @eagle_chara_sprites.each { |s| s.bind_window(t) }
    # 拷贝pop的tag
    t.eagle_sprite_pop_tag.dispose
    t.eagle_sprite_pop_tag = @eagle_sprite_pop_tag
    # 拷贝脸图
    t.eagle_sprite_face.dispose
    t.eagle_sprite_face = @eagle_sprite_face
    # 拷贝姓名框
    t.eagle_window_name.dispose
    t.eagle_window_name = @eagle_window_name
    # 拷贝pause精灵
    t.eagle_sprite_pause.dispose
    t.eagle_sprite_pause = @eagle_sprite_pause
    t.eagle_sprite_pause.visible = true
    @eagle_sprite_pause.bind_window(t)
    # 集体更新z值
    t.eagle_reset_z
    # 自身初始化组件与重置
    eagle_message_init_assets
    eagle_message_reset
    eagle_reset_pop_tag_bitmap
    # 重置之前存储的窗口的z值（确保最近的显示在最上面）
    @windows_dup.each_with_index { |w, i| w.z = t.z - (i+1) * 5; w.eagle_reset_z }
    t
  end
  #--------------------------------------------------------------------------
  # ● 打开直至完成（当绘制完成时）
  #--------------------------------------------------------------------------
  def eagle_open_and_wait
    return if self.openness == 255
    self.openness = 0

    face_move_params = game_message.face_params[:params_move]
    game_message.face_params[:params_move] = nil
    @eagle_chara_sprites.each { |c| c.visible = false }
    f_tag = @eagle_sprite_pop_tag.visible
    @eagle_sprite_pop_tag.visible = false
    @eagle_sprite_pop_tag.opacity = 0

    open_and_wait

    game_message.face_params[:params_move] = face_move_params
    @eagle_chara_sprites.each { |c| c.visible = true }
    @eagle_sprite_pop_tag.visible = f_tag
    @eagle_sprite_pop_tag.opacity = 255
  end
  #--------------------------------------------------------------------------
  # ● 更新打开处理（覆盖）
  #--------------------------------------------------------------------------
  def update_open
    self.openness += 36
    @opening = false if open?
  end
  #--------------------------------------------------------------------------
  # ● 关闭
  #--------------------------------------------------------------------------
  alias eagle_message_ex_close close
  def close
    eagle_message_reset
    eagle_release_hold
    eagle_message_ex_close
  end
  #--------------------------------------------------------------------------
  # ● 关闭窗口并等待窗口关闭完成
  #--------------------------------------------------------------------------
  def close_and_wait
    close
    eagle_message_sprites_move_out
    Fiber.yield until (all_close? && eagle_message_sprites_all_out?)
    eagle_message_sprites_clear
  end
  #--------------------------------------------------------------------------
  # ● 移出全部文字精灵
  #--------------------------------------------------------------------------
  def eagle_message_sprites_move_out
    @eagle_chara_sprites.each { |c| c.move_out; c.update }
  end
  #--------------------------------------------------------------------------
  # ● 文字精灵全部移出？
  #--------------------------------------------------------------------------
  def eagle_message_sprites_all_out?
    @eagle_chara_sprites.all? { |c| c.finish? }
  end
  #--------------------------------------------------------------------------
  # ● 清除文字精灵
  #--------------------------------------------------------------------------
  def eagle_message_sprites_clear
    @eagle_chara_sprites.each { |s| s.dispose }
    @eagle_chara_sprites.clear
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  alias eagle_message_ex_dispose dispose
  def dispose
    eagle_message_ex_dispose
    eagle_message_sprites_clear
    @eagle_face_bitmap.dispose if @eagle_face_bitmap
    @eagle_sprite_face.bitmap.dispose if @eagle_sprite_face.bitmap
    @eagle_sprite_face.dispose
    @eagle_window_name.dispose
    @eagle_sprite_pop_tag.bitmap.dispose if @eagle_sprite_pop_tag.bitmap
    @eagle_sprite_pop_tag.dispose
    @eagle_pop_tag_bitmap.dispose if @eagle_pop_tag_bitmap
    @eagle_sprite_pause.dispose
  end
  #--------------------------------------------------------------------------
  # ● 重新生成背景位图
  #--------------------------------------------------------------------------
  def eagle_recreate_back_bitmap
    @back_bitmap.dispose if @back_bitmap
    @back_bitmap = Bitmap.new(width, height)
    rect1 = Rect.new(0, 0, width, 12)
    rect2 = Rect.new(0, 12, width, height - 24)
    rect3 = Rect.new(0, height - 12, width, 12)
    @back_bitmap.gradient_fill_rect(rect1, back_color2, back_color1, true)
    @back_bitmap.fill_rect(rect2, back_color1)
    @back_bitmap.gradient_fill_rect(rect3, back_color1, back_color2, true)
    @back_sprite.bitmap = @back_bitmap
    @back_sprite.x = self.x
    @back_sprite.y = self.y
  end
  #--------------------------------------------------------------------------
  # ● 重置单页对话框
  #--------------------------------------------------------------------------
  def eagle_message_reset
    # 重置下一个文字的绘制x（左对齐、不考虑换行）
    @eagle_next_chara_x = 0
    # 重置文字区域的宽度高度
    @eagle_charas_w = @eagle_charas_h = 0
    @eagle_charas_w_final = @eagle_charas_h_final = 0
    # 重置pop
    game_message.pop_params[:id] = nil
    # 重置pop的tag
    @eagle_sprite_pop_tag.visible = false # pop的箭头隐藏
    # 重置脸图
    eagle_face_move_out if @eagle_sprite_face.opacity > 0 # 上一次的初始化移出
    game_message.face_params[:name] = ""
    # 重置姓名框
    game_message.name_params[:name] = ""
    @eagle_window_name.close
    # 重置pause精灵
    @eagle_sprite_pause.bind_last_chara(nil) # 重置pause精灵的文末位置
    @eagle_sprite_pause.visible = false
    @eagle_sprite_pause_width_add = 0 # 因pause精灵而扩展的窗口宽度
    # 重置集体的z值
    eagle_reset_z
  end
  #--------------------------------------------------------------------------
  # ● 重设z值
  #--------------------------------------------------------------------------
  def eagle_reset_z
    self.z = game_message.win_params[:z] if game_message.win_params[:z] > 0
    @eagle_chara_sprites.each { |s| s.z = self.z + 1 }
    @eagle_sprite_pop_tag.z = self.z + 1
    @eagle_sprite_face.z = self.z + 2
    @eagle_window_name.z = self.z + 3
    @eagle_sprite_pause.z = self.z + 3
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  alias eagle_message_ex_update update
  def update
    eagle_message_ex_update
    eagle_message_update_while_open if self.openness > 0
    @eagle_chara_sprites.each { |s| s.update }
    eagle_face_update_move if game_message.face_params[:params_move]
    eagle_dup_windows_update
  end
  #--------------------------------------------------------------------------
  # ● 对话框打开后的更新
  #--------------------------------------------------------------------------
  def eagle_message_update_while_open
    eagle_pop_update if game_message.pop?
    eagle_face_update if game_message.face?
    @eagle_window_name.update
    @eagle_sprite_pause.update if @eagle_sprite_pause.visible
  end
  #--------------------------------------------------------------------------
  # ● 更新全部拷贝窗口
  #--------------------------------------------------------------------------
  def eagle_dup_windows_update
    @windows_dup.delete_if { |w| w.disposed? }
    @windows_dup.each { |w| w.update; w.dispose if w.openness <= 0 }
  end
  #--------------------------------------------------------------------------
  # ● 重置指定对象的显示原点位置
  #--------------------------------------------------------------------------
  def eagle_reset_xy_origin(obj, o)
    MESSAGE_EX.reset_xy_origin(obj, o)
  end
  #--------------------------------------------------------------------------
  # ● 重置指定对象依据另一对象小键盘位置的新位置
  #--------------------------------------------------------------------------
  def eagle_reset_xy_dorigin(obj, obj2, o)
    MESSAGE_EX.reset_xy_dorigin(obj, obj2, o)
  end
  #--------------------------------------------------------------------------
  # ● 更新win参数组（初始化/一页绘制完成时调用）
  #--------------------------------------------------------------------------
  def eagle_win_update
    eagle_change_windowskin
    self.width = eagle_window_width
    self.width += eagle_window_width_add(self.width)
    self.height = eagle_window_height
    self.height += eagle_window_height_add(self.height)
    self.x = game_message.win_params[:x] || 0
    self.y = game_message.win_params[:y] || (game_message.position * (Graphics.height - self.height) / 2)
    eagle_reset_xy_dorigin(self, nil, game_message.win_params[:do]) if game_message.win_params[:do] < 0
    eagle_reset_xy_origin(self, game_message.win_params[:o])
    self.x += game_message.win_params[:dx]
    self.y += game_message.win_params[:dy]
    eagle_recreate_back_bitmap if game_message.background == 1
    eagle_name_update if game_message.name?
  end
  #--------------------------------------------------------------------------
  # ● 变更窗口皮肤
  #--------------------------------------------------------------------------
  def eagle_change_windowskin(index = nil)
    index = game_message.win_params[:skin] if index.nil?
    return if @last_windowskin_index == index
    @last_windowskin_index = index
    self.windowskin = MESSAGE_EX.windowskin(index)
    change_color(text_color(0))
  end
  #--------------------------------------------------------------------------
  # ● 获取窗口宽度高度
  #--------------------------------------------------------------------------
  def eagle_window_width
    return game_message.pop_params[:w] if game_message.pop? && game_message.pop_params[:w] > 0
    return game_message.win_params[:w] if game_message.win_params[:w] > 0
    if eagle_dynamic_w?
      w = @eagle_charas_w
      w = @eagle_charas_w_final if eagle_dyn_fit_w?
      w += standard_padding * 2
      w = win_params[:wmin] if win_params[:wmin] > 0 && w < win_params[:wmin]
      w = win_params[:wmax] if win_params[:wmax] > 0 && w > win_params[:wmax]
      w += eagle_face_width
      return w
    end
    window_width
  end
  def eagle_window_height
    return game_message.pop_params[:h] if game_message.pop? && game_message.pop_params[:h] > 0
    return game_message.win_params[:h] if game_message.win_params[:h] > 0
    if eagle_dynamic_h?
      h = @eagle_charas_h
      h = @eagle_charas_h_final if eagle_dyn_fit_h?
      h += standard_padding * 2
      h = win_params[:hmin] if win_params[:hmin] > 0 && h < win_params[:hmin]
      h = win_params[:hmax] if win_params[:hmax] > 0 && h > win_params[:hmax]
      return h
    end
    window_height
  end
  #--------------------------------------------------------------------------
  # ● 动态调整宽度高度？
  #--------------------------------------------------------------------------
  def eagle_dynamic_w?
    game_message.win_params[:dw] || (game_message.pop? && game_message.pop_params[:dw])
  end
  def eagle_dynamic_h?
    game_message.win_params[:dh] || (game_message.pop? && game_message.pop_params[:dh])
  end
  #--------------------------------------------------------------------------
  # ● 动态调整宽度高度的前提下，预计算完整文字区域的宽度高度？
  #--------------------------------------------------------------------------
  def eagle_dyn_fit_w?
    game_message.win_params[:fw] || (game_message.pop? && game_message.pop_params[:fw])
  end
  def eagle_dyn_fit_h?
    game_message.win_params[:fh] || (game_message.pop? && game_message.pop_params[:fh])
  end
  #--------------------------------------------------------------------------
  # ● 额外增加的窗口宽度高度（右侧和下侧）
  #--------------------------------------------------------------------------
  def eagle_window_width_add(cur_width)
    v = 0
    v += @eagle_sprite_pause_width_add
    v
  end
  def eagle_window_height_add(cur_height)
    0
  end
  #--------------------------------------------------------------------------
  # ● 更新pop参数组
  #--------------------------------------------------------------------------
  def eagle_pop_update
    eagle_change_windowskin(game_message.pop_params[:skin])
    # 对话框左上角定位到绑定对象位图的对应o位置
    if !@in_battle # 定位到位图底部中心的屏幕位置
      game_message.pop_params[:chara_x] = @eagle_pop_chara.real_x
      game_message.pop_params[:chara_y] = @eagle_pop_chara.real_y
      self.x = (game_message.pop_params[:chara_x] - $game_map.display_x) * 32 + 16
      self.y = (game_message.pop_params[:chara_y] - $game_map.display_y + 1) * 32
    else
      game_message.pop_params[:chara_x] = @eagle_pop_chara.x
      game_message.pop_params[:chara_y] = @eagle_pop_chara.y
      self.x = game_message.pop_params[:chara_x]
      self.y = game_message.pop_params[:chara_y]
    end
    # 将对话框移动到绑定对象的对应方向上
    case game_message.pop_params[:do]
    when 1,4,7; self.x -= (game_message.pop_params[:chara_w] / 2)
    when 3,6,9; self.x += game_message.pop_params[:chara_w]
    when 2,8;
    end
    case game_message.pop_params[:do]
    when 1,2,3;
    when 7,8,9; self.y -= game_message.pop_params[:chara_h]
    when 4,6;   self.y -= (game_message.pop_params[:chara_h] / 2)
    end
    eagle_reset_xy_origin(self, 10 - game_message.pop_params[:do]) # 显示原点恰好相反
    # 距离绑定对象位图中心的偏移量
    case game_message.pop_params[:do]
    when 1,4,7; self.x -= game_message.pop_params[:d]
    when 3,6,9; self.x += game_message.pop_params[:d]
    end
    case game_message.pop_params[:do]
    when 1,2,3; self.y += game_message.pop_params[:d]
    when 7,8,9; self.y -= game_message.pop_params[:d]
    end
    # 坐标的补足偏移量
    self.x += game_message.pop_params[:dx]
    self.y += game_message.pop_params[:dy]
    eagle_pop_tag_update if game_message.pop_params[:tag] > 0
    eagle_name_update if game_message.name?
  end
  #--------------------------------------------------------------------------
  # ● 更新pop的tag
  #--------------------------------------------------------------------------
  def eagle_pop_tag_update
    o = 10 - game_message.pop_params[:do] # tag的o值恰好与pop对话框的do值相对
    @eagle_sprite_pop_tag.visible =
      MESSAGE_EX.windowtag_o(self, @eagle_sprite_pop_tag, @eagle_pop_tag_bitmap, o)
    # 坐标距离事件格子中心的偏移量
    case o
    when 1,4,7; @eagle_sprite_pop_tag.x -= game_message.pop_params[:td]
    when 3,6,9; @eagle_sprite_pop_tag.x += game_message.pop_params[:td]
    end
    case o
    when 1,2,3; @eagle_sprite_pop_tag.y -= game_message.pop_params[:td]
    when 7,8,9; @eagle_sprite_pop_tag.y += game_message.pop_params[:td]
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新face参数组
  #--------------------------------------------------------------------------
  def eagle_face_update
    # 更新脸图位置
    if game_message.face_params[:dir] # 脸图放置于右侧时
      @eagle_sprite_face.x = self.x + self.width - standard_padding - @eagle_sprite_face.ox
    else # 脸图放置于左侧时
      @eagle_sprite_face.x = self.x + standard_padding + @eagle_sprite_face.ox
    end
    @eagle_sprite_face.y = self.y + self.height - standard_padding + game_message.face_params[:dy]
    @eagle_sprite_face.mirror = game_message.face_params[:m]

    # 更新脸图循环播放
    if game_message.face_params[:flag_l]
      if game_message.face_params[:li_c] >= game_message.face_params[:le]
        # 每次loop之间的等待
        game_message.face_params[:lw_c] -= 1
        return if game_message.face_params[:lw_c] > 0
        game_message.face_params[:lw_c] = game_message.face_params[:lw]
        game_message.face_params[:li_c] = game_message.face_params[:ls]
      else
        # 每帧之间的等待
        game_message.face_params[:lt_c] -= 1
        return if game_message.face_params[:lt_c] > 0
        game_message.face_params[:lt_c] = game_message.face_params[:lt]
        game_message.face_params[:li_c] += 1
      end
      game_message.face_params[:i] = game_message.face_params[:li_c]
      eagle_face_apply
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新face参数组中的移动（用于滞后移出效果）
  #--------------------------------------------------------------------------
  def eagle_face_update_move
    if game_message.face_params[:params_move][0] > 0
      game_message.face_params[:params_move][0] -= 1
      game_message.face_params[:params_move][2] += game_message.face_params[:params_move][1]
      @eagle_sprite_face.x += game_message.face_params[:params_move][2]
      @eagle_sprite_face.opacity += game_message.face_params[:params_move][3]
    else
      game_message.face_params[:params_move] = nil
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新name参数组（随win/pop参数组更新）
  #--------------------------------------------------------------------------
  def eagle_name_update
    eagle_reset_xy_dorigin(@eagle_window_name, self, game_message.name_params[:do])
    @eagle_window_name.x += game_message.name_params[:dx]
    @eagle_window_name.y += game_message.name_params[:dy]
    eagle_reset_xy_origin(@eagle_window_name, game_message.name_params[:o])
  end

  #--------------------------------------------------------------------------
  # ● 获取即将绘制的所有文本内容
  #--------------------------------------------------------------------------
  def eagle_all_text
    text = game_message.all_text
    if !game_message.escape_strings.empty? # 如果存在待处理的转义符串，加到开头
      text = game_message.escape_strings.inject("") { |sum, s| sum = sum + s } + text
      game_message.escape_strings.clear
    end
    text = eagle_process_conv(text)
    text = convert_escape_characters(text) # 此处将 \\ 替换成了 \e
    text.gsub!(/\enew_line|\enl/i) { "\n" } # 替换换行转义符
    text
  end
  #--------------------------------------------------------------------------
  # ● 替换转义符（此时依旧是 \\ 开头的转义符）
  #--------------------------------------------------------------------------
  def eagle_process_conv(text)
    text.gsub!(/\\conv\[(.*?)\]/i) { MESSAGE_EX.get_conv($1) }
    text
  end
  #--------------------------------------------------------------------------
  # ● 处理所有文本内容（覆盖）
  #--------------------------------------------------------------------------
  def process_all_text
    text = eagle_all_text; pos = {}
    new_page(text, pos)
    calc_charas_wh(text, pos) if eagle_dyn_fit_w? || eagle_dyn_fit_h?
    process_character(text.slice!(0, 1), text, pos) until text.empty?
    eagle_process_draw_update if !@eagle_chara_sprites.empty?
  end
  #--------------------------------------------------------------------------
  # ● 翻页处理（覆盖）
  #--------------------------------------------------------------------------
  def new_page(text, pos)
    close_and_wait

    eagle_check_pre_settings(text)
    eagle_draw_face(game_message.face_name, game_message.face_index)
    eagle_draw_name(text)

    reset_font_settings
    pos[:x] = new_line_x
    pos[:y] = 0
    pos[:new_x] = new_line_x
    pos[:height] = calc_line_height(text)
    clear_flags
  end
  #--------------------------------------------------------------------------
  # ● 重置字体设置
  #--------------------------------------------------------------------------
  def reset_font_settings
    change_color(normal_color)
  end
  #--------------------------------------------------------------------------
  # ● 获取换行位置（覆盖）
  #--------------------------------------------------------------------------
  def new_line_x
    0
  end
  #--------------------------------------------------------------------------
  # ● 计算行高（覆盖）
  #--------------------------------------------------------------------------
  def calc_line_height(text, restore_font_size = true)
    contents.font.size
  end
  #--------------------------------------------------------------------------
  # ● 计算文字区域最终绘制完成时的宽度高度
  #--------------------------------------------------------------------------
  def calc_charas_wh(text, pos)
    text_ = text.clone; pos_ = pos.clone
    game_message.save_params
    game_message.draw = false
    process_character(text_.slice!(0, 1), text_, pos_) until text_.empty?
    # 记录最终的文字区域宽度高度
    @eagle_charas_w_final = @eagle_charas_w
    @eagle_charas_h_final = @eagle_charas_h
    before_input_pause # 此处追加对pause精灵占用宽度的处理
    # 复原
    @eagle_charas_w = @eagle_charas_h = 0
    game_message.load_params(nil)
    game_message.draw = true
  end
  #--------------------------------------------------------------------------
  # ● 文字区域的左上角位置（屏幕坐标系）
  #--------------------------------------------------------------------------
  def eagle_charas_x0
    self.x + standard_padding + eagle_face_left_width
  end
  def eagle_charas_y0
    self.y + standard_padding
  end
  #--------------------------------------------------------------------------
  # ● 普通文字的处理（覆盖）
  #--------------------------------------------------------------------------
  def process_normal_character(c, pos)
    c_rect = text_size(c); c_w = c_rect.width; c_h = c_rect.height
    if game_message.draw
      s = eagle_new_chara_sprite(c, pos[:x], pos[:y], c_w, c_h)
      eagle_draw_char(s.bitmap, 0, 0, c_w, c_h, c, 0)
    end
    eagle_process_draw_end(c_w, c_h, pos)
  end
  #--------------------------------------------------------------------------
  # ● 处理控制符指定的图标绘制（覆盖）
  #--------------------------------------------------------------------------
  def process_draw_icon(icon_index, pos)
    if game_message.draw
      s = eagle_new_chara_sprite(' ', pos[:x], pos[:y], 24, 24)
      _bitmap = Cache.system("Iconset")
      rect = Rect.new(icon_index % 16 * 24, icon_index / 16 * 24, 24, 24)
      eagle_draw_extra_background(s.bitmap, 0, 0, 24, 24, ' ', 0)
      s.bitmap.blt(0, 0, _bitmap, rect, 255)
      eagle_draw_extra_foreground(s.bitmap)
    end
    eagle_process_draw_end(24, 24, pos)
  end
  #--------------------------------------------------------------------------
  # ● （封装）生成一个新的文字精灵
  #--------------------------------------------------------------------------
  def eagle_new_chara_sprite(c, c_x, c_y, c_w, c_h)
    s = Sprite_EagleCharacter.new(self, c, c_x, c_y, c_w, c_h)
    s.start_effects(game_message.chara_params)
    @eagle_chara_sprites.push(s)
    s
  end
  #--------------------------------------------------------------------------
  # ● （封装）绘制文字
  #--------------------------------------------------------------------------
  def eagle_draw_char(bitmap, x, y, w, h, c, align = 0)
    eagle_draw_extra_background(bitmap, x, y, w, h, c, align)
    if game_message.chara_grad_colors.empty?
      bitmap.draw_text(x, y, w* 2, h, c, align)
    else
      Sion_GradientText.draw_text(bitmap,x,y,w*2,h,c,align,game_message.chara_grad_colors)
    end
    eagle_draw_extra_foreground(bitmap)
  end
  #--------------------------------------------------------------------------
  # ● 绘制背景额外内容
  #--------------------------------------------------------------------------
  def eagle_draw_extra_background(bitmap, x, y, w, h, c, align)
    if font_params[:p] > 0 # 底纹
      color = text_color(font_params[:pc])
      case game_message.font_params[:p]
      when 1 # 边框
        bitmap.fill_rect(x, y, w, h, color)
        bitmap.clear_rect(x+1, y+1, w-2, h-2)
      when 2 # 纯色方块
        bitmap.fill_rect(x, y, w, h, color)
      end
    end
    if font_params[:l] # 外发光
      color = bitmap.font.color.dup
      bitmap.font.color = text_color(font_params[:lc])
      bitmap.draw_text(x, y, w, h, c, align)
      bitmap.blur
      bitmap.font.color = color
    end
  end
  #--------------------------------------------------------------------------
  # ● 绘制前景额外内容
  #--------------------------------------------------------------------------
  def eagle_draw_extra_foreground(bitmap)
    if font_params[:d] # 绘制删除线
      c = text_color(font_params[:dc])
      bitmap.fill_rect(0, bitmap.height/2 - 1, bitmap.width, 1, c)
    end
    if font_params[:u] # 绘制下划线
      c = text_color(font_params[:uc])
      bitmap.fill_rect(0, bitmap.height - 1, bitmap.width, 1, c)
    end
  end
  #--------------------------------------------------------------------------
  # ● 绘制完成时的处理
  #--------------------------------------------------------------------------
  def eagle_process_draw_end(c_w, c_h, pos)
    # 处理下一次绘制的参数
    pos[:x] += (c_w - game_message.win_params[:ck])
    pos[:height] = [pos[:height], c_h].max
    # 记录下一个文字绘制位置x
    @eagle_next_chara_x = pos[:x]
    # 处理文字区域大小更改
    @eagle_charas_w = pos[:x] if @eagle_charas_w < pos[:x]
    @eagle_charas_h = pos[:y] + pos[:height] if @eagle_charas_h < pos[:y] + pos[:height]
    return if !game_message.draw
    return if show_fast? # 如果是立即显示，则不更新
    eagle_process_draw_update
    wait_for_one_character
  end
  #--------------------------------------------------------------------------
  # ● 绘制完成时的更新
  #--------------------------------------------------------------------------
  def eagle_process_draw_update
    eagle_charas_reset_alignment(game_message.win_params[:ali])
    eagle_win_update # 当绘制完一个文字时，更新一次win参数
    eagle_pop_update if game_message.pop? # 当使用pop时，再覆盖一次
    eagle_open_and_wait # 第一个文字绘制完成时窗口打开
    # pause精灵重置位置
    @eagle_sprite_pause.bind_last_chara(@eagle_chara_sprites[-1])
  end
  #--------------------------------------------------------------------------
  # ● 重排列全部文字精灵
  #--------------------------------------------------------------------------
  def eagle_charas_reset_alignment(align = 1)
    return if @eagle_chara_sprites.empty?
    charas = [] # 存储当前迭代行的全部文字精灵
    # 存储当前迭代行的y值（同y的为同一行）（未考虑列排文字）
    charas_y = @eagle_chara_sprites[0].origin_y  # 初始为第一行
    # 如果窗口宽度比文字区域的宽度大，则需要将文字整体移动
    d_w = (self.width - standard_padding * 2) - eagle_charas_w
    d_w -= eagle_face_width # 减去脸图占用的宽度
    d_w > 0 ? (dx1 = d_w / 2; dx2 = d_w) : (dx1 = dx2 = 0)
    @eagle_chara_sprites.each do |s|
      next charas.push(s) if s.origin_y == charas_y # 第一行的首字符会存入
      # 对同一行的字符重排
      eagle_charas_realign_line(charas, align, dx1, dx2)
      charas.clear
      # 将当前迭代的 下一行的首字符 存入
      charas.push(s)
      charas_y = s.origin_y
    end
    # 对最后一行进行重排列
    eagle_charas_realign_line(charas, align, dx1, dx2) if !charas.empty?
  end
  #--------------------------------------------------------------------------
  # ● 重排列同一行上的文字精灵
  #--------------------------------------------------------------------------
  def eagle_charas_realign_line(charas, align, dx1, dx2)
    w_line = charas[-1].origin_x - charas[0].origin_x + charas[-1].width
    h_line = charas.collect{ |c| c.height }.max
    charas.each do |c|
      case align
      when 0 # 左对齐（默认对齐方式）
        _x = c.origin_x
      when 1 # 居中排列
        _x = c.origin_x + (eagle_charas_w - w_line) / 2 + dx1
      when 2 # 右排列
        _x = c.origin_x + eagle_charas_w - w_line + dx2
      end
      _y = c.origin_y + h_line - c.height # 底部对齐
      c.reset_xy(_x, _y)
    end
  end
  #--------------------------------------------------------------------------
  # ● 输出一个字符后的等待
  #--------------------------------------------------------------------------
  def wait_for_one_character
    MESSAGE_EX.se(game_message.win_params[:se])
    game_message.win_params[:cwait].times do
      return if show_fast?
      update_show_fast if game_message.win_params[:cfast]
      Fiber.yield
    end
  end
  #--------------------------------------------------------------------------
  # ● 处理换行文字
  #--------------------------------------------------------------------------
  alias eagle_message_ex_process_new_line process_new_line
  def process_new_line(text, pos)
    pos[:height] += game_message.win_params[:lh]
    eagle_message_ex_process_new_line(text, pos)
  end
  #--------------------------------------------------------------------------
  # ● 判定是否需要翻页
  #--------------------------------------------------------------------------
  alias eagle_message_ex_need_new_page? need_new_page?
  def need_new_page?(text, pos)
    return false if eagle_dynamic_h?
    eagle_message_ex_need_new_page?(text, pos)
  end
  #--------------------------------------------------------------------------
  # ● 输入处理（此处为全部绘制完成后，判定接下来的输入类型）
  #--------------------------------------------------------------------------
  alias eagle_message_ex_process_input process_input
  def process_input
    eagle_message_ex_process_input
    eagle_process_hold
  end
  #--------------------------------------------------------------------------
  # ● 处理输入等待
  #--------------------------------------------------------------------------
  alias eagle_message_ex_input_pause input_pause
  def input_pause
    return if !game_message.draw
    before_input_pause
    eagle_process_draw_update # 统一更新一次
    @eagle_sprite_pause.show
    eagle_message_ex_input_pause
    @eagle_sprite_pause.hide
  end
  #--------------------------------------------------------------------------
  # ● 处理输入等待前的操作
  #--------------------------------------------------------------------------
  def before_input_pause
    # 当pause精灵位于句末且紧靠边界时
    # 增加对话框宽度保证它在对话框内部（不可占用padding）
    if game_message.pause_params[:v] != 0 && game_message.pause_params[:do] <= 0 &&
       game_message.input_pause? &&
       @eagle_charas_w - @eagle_next_chara_x < @eagle_sprite_pause.width
      @eagle_sprite_pause_width_add = @eagle_sprite_pause.width
    end
  end
  #--------------------------------------------------------------------------
  # ● 处于快进显示？
  #--------------------------------------------------------------------------
  def show_fast?
    game_message.instant || @show_fast || @line_show_fast
  end
  #--------------------------------------------------------------------------
  # ● 等待
  #--------------------------------------------------------------------------
  alias eagle_message_ex_wait wait
  def wait(duration)
    return if !game_message.draw
    return if show_fast?
    eagle_message_ex_wait(duration)
  end

  #--------------------------------------------------------------------------
  # ● 设置【预先】指令的参数
  #--------------------------------------------------------------------------
  def eagle_check_pre_settings(text)
    eagle_check_popt(text)
    eagle_check_facep(text)
    eagle_check_hold(text)
    eagle_check_instant(text)
  end
  #--------------------------------------------------------------------------
  # ● 分析【预先】转义符的全部参数（按出现顺序处理）
  #--------------------------------------------------------------------------
  def parse_pre_params(text, sym, hash, default_type = :default)
    params = []
    text.gsub!(/\e#{sym}\[(.*?)\]/i) { params.push($1); "" }
    params.push("") if params.empty?
    params.each { |param| parse_param(hash, param, default_type) }
  end
  #--------------------------------------------------------------------------
  # ● 设置popt指令的参数
  #--------------------------------------------------------------------------
  def eagle_check_popt(text)
    old_tag = game_message.pop_params[:tag]
    parse_pre_params(text, 'popt', game_message.pop_params, :tag)

    return if game_message.pop_params[:tag] <= 0
    return if old_tag == game_message.pop_params[:tag]
    eagle_reset_pop_tag_bitmap
  end
  #--------------------------------------------------------------------------
  # ● 重置tag的位图
  #--------------------------------------------------------------------------
  def eagle_reset_pop_tag_bitmap
    @eagle_pop_tag_bitmap.dispose if @eagle_pop_tag_bitmap
    @eagle_pop_tag_bitmap = MESSAGE_EX.windowtag(game_message.pop_params[:tag])
    w = @eagle_pop_tag_bitmap.width
    h = @eagle_pop_tag_bitmap.height
    @eagle_sprite_pop_tag.bitmap.dispose if @eagle_sprite_pop_tag.bitmap
    @eagle_sprite_pop_tag.bitmap = Bitmap.new(w/3, h/3)
  end
  #--------------------------------------------------------------------------
  # ● 设置facep指令的参数
  #--------------------------------------------------------------------------
  def eagle_check_facep(text)
    parse_pre_params(text, 'facep', game_message.face_params, :dir)

    game_message.face_params[:dir] = MESSAGE_EX.check_bool(game_message.face_params[:dir])
    game_message.face_params[:m] = MESSAGE_EX.check_bool(game_message.face_params[:m])
  end
  #--------------------------------------------------------------------------
  # ● 设置/执行hold指令
  #--------------------------------------------------------------------------
  def eagle_check_hold(text)
    text.gsub!(/\e(hold)/i) { "" }
    game_message.hold = $1 ? true : false
  end
  def eagle_process_hold
    game_message.hold ? @windows_dup.unshift( self.clone ) : eagle_release_hold
  end
  def eagle_release_hold # 所有暂存窗口关闭
    @windows_dup.each { |w| w.close }
  end
  #--------------------------------------------------------------------------
  # ● 设置instant指令
  #--------------------------------------------------------------------------
  def eagle_check_instant(text)
    text.gsub!(/\e(instant)/i) { game_message.instant = true if $1; "" }
  end

  #--------------------------------------------------------------------------
  # ● 初始化姓名框
  #--------------------------------------------------------------------------
  def eagle_draw_name(text)
    # 用 | 分隔需要绘制的name字符串（其中转义符用<>代替[]）和参数组
    text.gsub!(/\ename\[(.*?)\]/i) {
      t = $1.dup
      if t.include?('|')
        game_message.name_params[:name] = t.slice!(/.*?\|/).chop
        "\ename[#{t}]"
      else
        game_message.name_params[:name] = t
        ""
      end
    }
    parse_pre_params(text, 'name', game_message.name_params, :o)

    return if game_message.name_params[:name] == ""
    # 重设姓名窗口
    t = MESSAGE_EX.get_name_prefix + game_message.name_params[:name]
    t.gsub!(/<(.*?)>/) { "[" + $1 + "]" }
    w, h = eagle_calculate_text_wh(t)
    h = [h, @eagle_window_name.line_height].max
    w += standard_padding * 2; h += standard_padding * 2
    @eagle_window_name.move(0, 0, w, h)
    @eagle_window_name.create_contents
    @eagle_window_name.draw_text_ex(0, 0, t)
    skin = game_message.name_params[:skin]
    if game_message.pop? && !game_message.pop_params[:skin].nil?
      skin ||= game_message.pop_params[:skin]
    else
      skin ||= game_message.win_params[:skin]
    end
    @eagle_window_name.windowskin = MESSAGE_EX.windowskin(skin)
    @eagle_window_name.opacity = game_message.name_params[:opa]
    @eagle_window_name.back_opacity = @eagle_window_name.opacity
    @eagle_window_name.contents_opacity = 255
    @eagle_window_name.openness = 0
    @eagle_window_name.show.open
    eagle_name_update
  end
  #--------------------------------------------------------------------------
  # ● 计算指定文本块所占据的宽度和高度（未考虑转义符导致的字号变化）
  #   k - 字符间距  lh - 行间距
  #--------------------------------------------------------------------------
  def eagle_calculate_text_wh(text, k = 0, lh = 0)
    reset_font_settings
    text_clone, array_width, array_height = text.dup, [], []
    text_clone.each_line do |line|
      line = convert_escape_characters(line)
      line.gsub!(/\n/){ "" }; line.gsub!(/\e[\.\|\^\!\$<>\{|\}]/i){ "" }
      icon_count = 0; line.gsub!(/\ei\[\d+\]/i){ icon_count += 1; "" }
      line.gsub!(/\e\w+\[(\d|\w)+\]/i){ "" } # 清除掉全部的\w[wd]格式转义符
      r = text_size(line)
      w = r.width + icon_count * 24 + (line.length - 1 + icon_count) * k
      array_width.push(w)
      h = icon_count > 0 ? [r.height, 24].max : r.height
      array_height.push(h)
    end
    return [array_width.max, array_height.inject{|sum, v| sum = sum + v + lh}]
  end

  #--------------------------------------------------------------------------
  # ● 初始化脸图
  #--------------------------------------------------------------------------
  def eagle_draw_face(face_name, face_index)
    game_message.face_params[:name] = face_name
    game_message.face_params[:i] = face_index
    return if face_name == ""

    @eagle_face_bitmap.dispose if @eagle_face_bitmap
    @eagle_face_bitmap = Cache.face(face_name)
    face_name =~ /_(\d+)x(\d+)_?/i  # 从文件名获取行数和列数（默认为2行4列）
    game_message.face_params[:num_line] = $1 ? $1.to_i : 2
    game_message.face_params[:num_col] = $2 ? $2.to_i : 4
    game_message.face_params[:sole_w] = @eagle_face_bitmap.width / game_message.face_params[:num_col]
    game_message.face_params[:sole_h] = @eagle_face_bitmap.height / game_message.face_params[:num_line]
    # 脸图以底部中心为显示原点
    @eagle_sprite_face.bitmap = Bitmap.new(game_message.face_params[:sole_w],
      game_message.face_params[:sole_h])
    @eagle_sprite_face.ox = @eagle_sprite_face.width / 2
    @eagle_sprite_face.oy = @eagle_sprite_face.height
    @eagle_sprite_face.opacity = 0
    # 覆盖部分face参数
    eagle_text_control_face
    # 显示
    eagle_face_apply
    eagle_face_move_in
  end
  #--------------------------------------------------------------------------
  # ● 初始化脸图移入
  #--------------------------------------------------------------------------
  def eagle_face_move_in
    # 用于控制移入移出的参数组 [time, v_x, dx, v_opa]
    t = game_message.face_params[:it]
    v_x = game_message.face_params[:iv] * (game_message.face_params[:dir] ? -1 : 1)
    game_message.face_params[:params_move] = [t, v_x, v_x*t*-1,
      game_message.face_params[:io]]
  end
  #--------------------------------------------------------------------------
  # ● 初始化脸图移出
  #--------------------------------------------------------------------------
  def eagle_face_move_out
    t = game_message.face_params[:ot]
    v_x = game_message.face_params[:ov] * (game_message.face_params[:dir] ? 1 : -1)
    game_message.face_params[:params_move] = [t, v_x, 0,
      -1*game_message.face_params[:oo]]
  end
  #--------------------------------------------------------------------------
  # ● 应用设置的脸图
  # （根据设置好的参数，重新绘制脸图精灵的bitmap）
  #--------------------------------------------------------------------------
  def eagle_face_apply
    @eagle_sprite_face.bitmap.clear
    w = game_message.face_params[:sole_w]
    h = game_message.face_params[:sole_h]
    x = game_message.face_params[:i] % game_message.face_params[:num_col] * w
    y = game_message.face_params[:i] / game_message.face_params[:num_col] * h
    rect = Rect.new(x, y, w, h)
    @eagle_sprite_face.bitmap.blt(0,0, @eagle_face_bitmap,rect)
  end
  #--------------------------------------------------------------------------
  # ● 脸图占用的宽度
  #--------------------------------------------------------------------------
  def eagle_face_width
    return 0 if !game_message.face?
    @eagle_sprite_face.width + game_message.face_params[:dw]
  end
  #--------------------------------------------------------------------------
  # ● 脸图在左侧占用的宽度（用于调整文字区域的左侧起始位置）
  #--------------------------------------------------------------------------
  def eagle_face_left_width
    return 0 if !game_message.face?
    return 0 if game_message.face_params[:dir] # 显示在右侧时
    @eagle_sprite_face.width + game_message.face_params[:dw]
  end

  #--------------------------------------------------------------------------
  # ● 控制符的处理
  #     code : 控制符的实际形式（比如“\C[1]”是“C”）
  #     text : 绘制处理中的字符串缓存（字符串可能会被修改）
  #     pos  : 绘制位置 {:x, :y, :new_x, :height}
  #--------------------------------------------------------------------------
  alias eagle_message_ex_process_escape_character process_escape_character
  def process_escape_character(code, text, pos)
    temp_code = code.downcase
    m_c = ("eagle_text_control_" + temp_code).to_sym
    m_e = ("eagle_chara_effect_" + temp_code).to_sym
    if respond_to?(m_c)
      param = obtain_escape_param_string(text)
      method(m_c).call(param)
    elsif respond_to?(m_e)
      param = obtain_escape_param_string(text)
      # 当只传入 0 时，代表关闭该特效
      return eagle_chara_effect_clear(temp_code.to_sym) if param == '0'
      game_message.chara_params[temp_code.to_sym] = param
      method(m_e).call(param)
    else
      eagle_message_ex_process_escape_character(code, text, pos)
    end
  end

  #--------------------------------------------------------------------------
  # ● 清除暂存的指定文字特效
  #--------------------------------------------------------------------------
  def eagle_chara_effect_clear(code_sym)
    game_message.chara_params.delete(code_sym)
  end
  #--------------------------------------------------------------------------
  # ● 获取控制符的实际形式（这个方法会破坏原始数据）
  #--------------------------------------------------------------------------
  def obtain_escape_code(text)
    text.slice!(/^[\$\.\|\^!><\{\}\\]|^[A-Z]+/i)
  end
  #--------------------------------------------------------------------------
  # ● 获取控制符的参数（字符串形式）（这个方法会破坏原始数据）
  #--------------------------------------------------------------------------
  def obtain_escape_param_string(text)
    text.slice!(/^\[[\$\-\d\w]+\]/)[/[\$\-\d\w]+/] rescue ""
  end

  #--------------------------------------------------------------------------
  # ● 解析字符串参数
  #--------------------------------------------------------------------------
  def parse_param(param_hash, param_text, default_type = "default")
    MESSAGE_EX.parse_param(param_hash, param_text, default_type)
  end
  #--------------------------------------------------------------------------
  # ● 设置font参数
  #--------------------------------------------------------------------------
  def font_params; game_message.font_params; end
  def eagle_text_control_font(param = "")
    parse_param(game_message.font_params, param, :size)

    self.contents.font.size = game_message.font_params[:size]
    self.contents.font.italic = MESSAGE_EX.check_bool(game_message.font_params[:i])
    self.contents.font.bold = MESSAGE_EX.check_bool(game_message.font_params[:b])
    self.contents.font.shadow = MESSAGE_EX.check_bool(game_message.font_params[:s])
    self.contents.font.color.alpha = game_message.font_params[:ca]
    self.contents.font.outline = MESSAGE_EX.check_bool(game_message.font_params[:o])
    self.contents.font.out_color.set(game_message.font_params[:or],
      game_message.font_params[:og],game_message.font_params[:ob],
      game_message.font_params[:oa])
    game_message.font_params[:l] = MESSAGE_EX.check_bool(game_message.font_params[:l])
    game_message.font_params[:d] = MESSAGE_EX.check_bool(game_message.font_params[:d])
    game_message.font_params[:u] = MESSAGE_EX.check_bool(game_message.font_params[:u])
  end
  #--------------------------------------------------------------------------
  # ● 放大字体尺寸（覆盖）
  #--------------------------------------------------------------------------
  def make_font_bigger
    contents.font.size += 4 if contents.font.size <= 64
    game_message.font_params[:size] = contents.font.size
  end
  #--------------------------------------------------------------------------
  # ● 缩小字体尺寸（覆盖）
  #--------------------------------------------------------------------------
  def make_font_smaller
    contents.font.size -= 4 if contents.font.size >= 16
    game_message.font_params[:size] = contents.font.size
  end
  #--------------------------------------------------------------------------
  # ● 更改内容绘制颜色（覆盖）
  #     enabled : 有效的标志。false 的时候使用半透明效果绘制
  #--------------------------------------------------------------------------
  def change_color(color, enabled = true)
    super(color, enabled)
    game_message.font_params[:ca] = self.contents.font.color.alpha
  end
  #--------------------------------------------------------------------------
  # ● 检查高度参数
  #--------------------------------------------------------------------------
  def eagle_check_param_h(h)
    return 0 if h <= 0
    # 如果h小于行高，则判定其为行数
    return line_height * h + standard_padding * 2 if h < line_height
    return h
  end
  #--------------------------------------------------------------------------
  # ● 设置win参数
  #--------------------------------------------------------------------------
  def win_params; game_message.win_params; end
  def eagle_text_control_win(param = "")
    parse_param(game_message.win_params, param, :o)

    game_message.win_params[:h] = eagle_check_param_h(game_message.win_params[:h])
    game_message.win_params[:hmin] = eagle_check_param_h(game_message.win_params[:hmin])
    game_message.win_params[:hmax] = eagle_check_param_h(game_message.win_params[:hmax])
    game_message.win_params[:dw] = MESSAGE_EX.check_bool(game_message.win_params[:dw])
    game_message.win_params[:fw] = MESSAGE_EX.check_bool(game_message.win_params[:fw])
    game_message.win_params[:dh] = MESSAGE_EX.check_bool(game_message.win_params[:dh])
    game_message.win_params[:fh] = MESSAGE_EX.check_bool(game_message.win_params[:fh])
    game_message.win_params[:cwait] = 0 if game_message.win_params[:cwait] < 0
    game_message.win_params[:cfast] = MESSAGE_EX.check_bool(game_message.win_params[:cfast])
    eagle_reset_z
  end
  #--------------------------------------------------------------------------
  # ● 设置pop参数
  #--------------------------------------------------------------------------
  def eagle_text_control_pop(param = "")
    game_message.pop_params[:id] = nil # 所绑定的事件的id
    #（0代表当前事件，正数代表事件，负数代表队列中数据库id号角色，若不存在则取队首）
    parse_param(game_message.pop_params, param, :id)

    # 设置 Character 类的实例，方便直接调用其xy
    @eagle_pop_chara = eagle_pop_get_chara
    # 若设置了chara变量，则认定使用pop对话框
    return game_message.pop_params[:id] = nil if @eagle_pop_chara.nil?
    s = eagle_pop_get_sprite
    game_message.pop_params[:chara_w] = s.width
    game_message.pop_params[:chara_h] = s.height

    game_message.pop_params[:h] = eagle_check_param_h(game_message.pop_params[:h])
    game_message.pop_params[:dw] = MESSAGE_EX.check_bool(game_message.pop_params[:dw])
    game_message.pop_params[:fw] = MESSAGE_EX.check_bool(game_message.pop_params[:fw])
    game_message.pop_params[:dh] = MESSAGE_EX.check_bool(game_message.pop_params[:dh])
    game_message.pop_params[:fh] = MESSAGE_EX.check_bool(game_message.pop_params[:fh])
    # 存储设定的固定宽度高度，原变量改为存储动态值，方便设置
    game_message.pop_params[:w_fix] = (game_message.pop_params[:w] > 0 ? game_message.pop_params[:w] : nil)
    game_message.pop_params[:h_fix] = (game_message.pop_params[:h] > 0 ? game_message.pop_params[:h] : nil)
    # 每次pop更新后记录坐标 避免每帧更新
    game_message.pop_params[:chara_x] = nil
    game_message.pop_params[:chara_y] = nil
    eagle_pop_update
  end
  #--------------------------------------------------------------------------
  # ● 获取pop的弹出对象（需要有x、y方法）
  #--------------------------------------------------------------------------
  def eagle_pop_get_chara
    return nil if game_message.pop_params[:id].nil?
    return eagle_pop_get_chara_b if @in_battle
    id = game_message.pop_params[:id]
    if id == 0 # 当前事件
      return $game_map.events[$game_map.interpreter.event_id]
    elsif id > 0 # 第id号事件
      chara = $game_map.events[game_message.pop_params[:id]]
      chara ||= $game_map.events[$game_map.interpreter.event_id]
      return chara
    elsif id < 0 # 队伍中数据库id号角色（不存在则取队长）
      id = id.abs
      $game_player.followers.each { |f| return f.actor if f.actor && f.actor.actor.id == id }
      return $game_player
    end
    return nil
  end
  #--------------------------------------------------------------------------
  # ● 获取pop的对象（需要有x、y的方法）（战斗场景中）
  #--------------------------------------------------------------------------
  def eagle_pop_get_chara_b
    id = game_message.pop_params[:id]
    return nil if id.nil?
    if id > 0 # 敌人index
      SceneManager.scene.spriteset.battler_sprites.each do |s|
        return s if s.battler.enemy? && s.battler.index == id
      end
    elsif id < 0 # 我方数据库id
      id = id.abs
      SceneManager.scene.spriteset.battler_sprites.each do |s|
        return s if s.battler.actor? && s.battler.id == id
      end
    end
    return nil
  end
  #--------------------------------------------------------------------------
  # ● 获取pop的对象的精灵（用于计算坐标偏移值）
  #--------------------------------------------------------------------------
  def eagle_pop_get_sprite
    return @eagle_pop_chara if @in_battle
    SceneManager.scene.spriteset.character_sprites.each do |s|
      return s if s.character == @eagle_pop_chara
    end
    return nil
  end
  #--------------------------------------------------------------------------
  # ● 设置face参数
  #--------------------------------------------------------------------------
  def eagle_text_control_face(param = "")
    return if game_message.face_params[:name] == ""
    game_message.face_params[:ls] = -1 # 设置循环开始编号（+1直至le，再从ls循环）
    game_message.face_params[:le] = -1 # 设置循环结束编号
    parse_param(game_message.face_params, param, :i)

    # 判断是否需要循环的flag
    game_message.face_params[:flag_l] = (game_message.face_params[:ls] > -1 &&
      game_message.face_params[:le] > game_message.face_params[:ls])
    game_message.face_params[:li_c] = game_message.face_params[:ls] # 循环用index计数
    game_message.face_params[:lt_c] = game_message.face_params[:lt] # 循环用time计数
    game_message.face_params[:lw_c] = game_message.face_params[:lw] # 循环后wait计数
    eagle_face_apply
  end
  #--------------------------------------------------------------------------
  # ● 设置pause参数
  #--------------------------------------------------------------------------
  def pause_params; game_message.pause_params; end
  def eagle_text_control_pause(param = "")
    parse_param(game_message.pause_params, param, :pause)
    @eagle_sprite_pause.reset
  end
  #--------------------------------------------------------------------------
  # ● 设置wait参数
  #--------------------------------------------------------------------------
  def eagle_text_control_wait(param = '0')
    h = {}
    h[:t] = 0 # 等待帧数
    parse_param(h, param, :t)
    wait(h[:t])
  end
  #--------------------------------------------------------------------------
  # ● 设置shake参数
  #--------------------------------------------------------------------------
  def eagle_text_control_shake(param = '0')
    h = {}
    h[:p] = 5 # shake power
    h[:s] = 5 # shake speed
    h[:t] = 40 # shake duration
    parse_param(h, param, :t)
    # 等待震动至结束
    shake = 0 # 对话框的偏移值
    shake_direction = 1 # 下一次位移量
    while h[:t] > 0
      delta = (h[:p] * h[:s] * shake_direction) / 10.0
      shake += delta
      shake_direction = -1 if shake > h[:p] * 2
      shake_direction = 1 if shake < - h[:p] * 2
      h[:t] -= 1
      self.x += shake
      eagle_name_update if game_message.name? # 姓名框跟着移动
      Fiber.yield
    end
    shake = shake.to_i # 平滑移动回初始位置
    d = shake > 0 ? -1 : 1
    while shake != 0
      shake += d
      self.x += shake
      eagle_name_update if game_message.name? # 姓名框跟着移动
      Fiber.yield
    end
  end
  #--------------------------------------------------------------------------
  # ● 设置g参数 / 渐变绘制预定
  #--------------------------------------------------------------------------
  if defined?(Sion_GradientText)
  def eagle_text_control_g(param = '')
    game_message.chara_grad_colors.clear
    param = param.downcase
    while(param != "")
      param.slice!(/\D+/)
      game_message.chara_grad_colors.push((param.slice!(/\d+/)).to_i)
    end
  end
  end
end # end of class Window_Message
#==============================================================================
# ○ 对话框拷贝
#==============================================================================
class Window_Message_Clone < Window_Message
  attr_accessor :eagle_chara_sprites, :eagle_sprite_pop_tag
  attr_accessor :eagle_sprite_face, :eagle_window_name, :eagle_sprite_pause
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize(game_message)
    @game_message = game_message
    super()
    self.openness = 255
  end
  #--------------------------------------------------------------------------
  # ● 获取主参数
  #--------------------------------------------------------------------------
  def game_message
    @game_message
  end
  #--------------------------------------------------------------------------
  # ● 重置单页对话框
  #--------------------------------------------------------------------------
  def eagle_message_reset
  end
  #--------------------------------------------------------------------------
  # ● 更新纤程
  #--------------------------------------------------------------------------
  def update_fiber
  end
end
#==============================================================================
# ○ 单个文字的精灵
#==============================================================================
class Sprite_EagleCharacter < Sprite
  attr_reader :origin_x, :origin_y, :_x, :_y
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize(message_window, c, x, y, w, h)
    super(nil)
    bind_window(message_window)
    reset(x, y, w, h)
  end
  #--------------------------------------------------------------------------
  # ● 设置绑定的窗口
  #--------------------------------------------------------------------------
  def bind_window(message_window)
    @message_window = message_window
    self.z = @message_window.z + 1
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    self.bitmap.dispose
    super
  end
  #--------------------------------------------------------------------------
  # ● 重置
  #--------------------------------------------------------------------------
  def reset(x, y, w, h)
    self.bitmap.dispose if self.bitmap
    self.bitmap = Bitmap.new(w, h)
    self.bitmap.font = @message_window.contents.font.dup
    @origin_x = x; @origin_y = y # 存储左对齐时，文字的显示位置（作为标准位置）
    reset_xy(x, y)
    @dx = @dy = 0 # 移动的实时偏移值
    @effects = {} # effect_sym => param_string
    @params = {} # effect_sym => param_hash
    @flag_move = nil # 在移动中？
  end
  #--------------------------------------------------------------------------
  # ● 设置相对偏移值
  #--------------------------------------------------------------------------
  def reset_xy(x, y)
    @_x = x # 存储文字相对对话框左上角的显示位置
    @_y = y
  end
  #--------------------------------------------------------------------------
  # ● 结束使命？
  #--------------------------------------------------------------------------
  def finish?
    self.opacity == 0
  end
  #--------------------------------------------------------------------------
  # ● 开始特效（整合）
  #--------------------------------------------------------------------------
  def start_effects(effects)
    @effects = effects.dup # code_symbol => param_string
    @effects.each { |sym, param_s|
      m = ("start_effect_" + sym.to_s).to_sym
      init_effect_params(sym)
      method(m).call(@params[sym], param_s.dup) if respond_to?(m)
    }
  end
  #--------------------------------------------------------------------------
  # ● 初始化特效的默认参数
  #--------------------------------------------------------------------------
  def init_effect_params(sym)
    @params[sym] = MESSAGE_EX.get_default_params(sym).dup # 初始化
  end
  # def start_effect_code(param)  code - 转义符
  # end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
    update_position
    return move_update(:cin)  if @flag_move == :in
    return move_update(:cout) if @flag_move == :out
    update_effects if !@effects.empty?
  end
  #--------------------------------------------------------------------------
  # ● 更新位置
  #--------------------------------------------------------------------------
  def update_position
    self.x = @message_window.eagle_charas_x0 + @_x + @dx
    self.y = @message_window.eagle_charas_y0 + @_y + @dy
  end
  #--------------------------------------------------------------------------
  # ● 更新特效（整合）
  #--------------------------------------------------------------------------
  def update_effects
    @effects.each { |sym, param|
      m = ("update_effect_" + sym.to_s).to_sym
      method(m).call(@params[sym]) if respond_to?(m)
    }
  end
  # def update_effect_code(param)  code - 转义符
  # end
  #--------------------------------------------------------------------------
  # ● 解析参数
  #--------------------------------------------------------------------------
  def parse_param(params, param_s, default_type = "default")
    MESSAGE_EX.parse_param(params, param_s, default_type)
  end
  #--------------------------------------------------------------------------
  # ● 移入
  #--------------------------------------------------------------------------
  def start_effect_cin(params, param_s, flag_move_in = true)
    parse_param(params, param_s)
    params[:vxc] = 0; params[:vyc] = 0; params[:vzc] = 0 # 计数用
    params[:vxt] = 1 if params[:vxt] < 1
    params[:vyt] = 1 if params[:vyt] < 1
    params[:vzt] = 1 if params[:vzt] < 1
    params[:vo] = [255 / params[:t], 1].max # 移入时每帧不透明度增量
    move_in if flag_move_in
  end
  def move_in
    params = @params[:cin]
    @dx = -(params[:t]/params[:vxt]) * params[:vx]
    @dy = -(params[:t]/params[:vyt]) * params[:vy]
    @_zoom = -(params[:t]/params[:vzt]) * params[:vz]
    self.angle = -params[:t] * params[:va]
    self.opacity = 0
    self.ox = self.width / 2; self.oy = self.height / 2
    @dx += self.ox; @dy += self.oy
    self.zoom_x = self.zoom_y = 1.0 + @_zoom/100.0
    @flag_move = :in
  end
  #--------------------------------------------------------------------------
  # ● 更新移动
  #--------------------------------------------------------------------------
  def move_update(sym = :cin) # 只有移动结束时，才进行其他更新
    params = @params[sym]
    params[:t] -= 1
    (params[:vxc] = 0; @dx += params[:vx]) if (params[:vxc] += 1) == params[:vxt]
    (params[:vyc] = 0; @dy += params[:vy]) if (params[:vyc] += 1) == params[:vyt]
    (params[:vzc] = 0;@_zoom += params[:vz]) if (params[:vzc] += 1) == params[:vzt]
    self.zoom_x = self.zoom_y = 1.0 + @_zoom/100.0
    self.angle += params[:va]
    self.opacity += params[:vo]
    move_end(sym) if params[:t] == 0
  end
  def move_end(sym = :cin)
    @dx -= self.ox; @dy -= self.oy
    self.ox = 0; self.oy = 0
    if sym == :cin
      self.zoom_x = self.zoom_y = 1.0
      self.opacity = 255
    elsif sym == :cout
      self.opacity = 0
    end
    update_position
    @flag_move = nil
  end
  #--------------------------------------------------------------------------
  # ● 移出
  #--------------------------------------------------------------------------
  def start_effect_cout(params, param_s)
    start_effect_cin(params, param_s, false)
    params[:vo] *= -1
  end
  def move_out
    return self.opacity = 0 if !need_move_out?
    @dx = @dy = @_zoom = 0
    self.ox = self.width / 2; self.oy = self.height / 2
    @dx += self.ox; @dy += self.oy
    @flag_move = :out
  end
  def need_move_out?
    !(@params[:cout].nil? || @params[:cout].empty?)
  end
  #--------------------------------------------------------------------------
  # ● 正弦扭曲特效
  #--------------------------------------------------------------------------
  def start_effect_csin(params, param_s)
    parse_param(params, param_s)

    self.wave_amp    = params[:a]
    self.wave_length = params[:l]
    self.wave_speed  = params[:s]
    self.wave_phase  = params[:p]
  end
  #--------------------------------------------------------------------------
  # ● 波浪特效
  #--------------------------------------------------------------------------
  def start_effect_cwave(params, param_s)
    params[:tc] = 0  # 移动计数用初值（一次性）
    parse_param(params, param_s)
  end
  def update_effect_cwave(params)
    return if (params[:tc] += 1) < params[:t]
    params[:tc] = 0
    @dy += params[:vy]
    params[:vy] *= -1 if @dy < -params[:h] || @dy > params[:h]
  end
  #--------------------------------------------------------------------------
  # ● 抖动特效
  #--------------------------------------------------------------------------
  def start_effect_cshake(params, param_s)
    params[:vxc] = 0  # 移动计数用初值（一次性）
    params[:vyc] = 0  # 移动计数用初值（一次性）
    parse_param(params, param_s)
    params[:vx] = rand(2) * 2 - 1 if params[:vx] == 0
    params[:vy] = rand(2) * 2 - 1 if params[:vy] == 0
  end
  def update_effect_cshake(params)
    if (params[:vxc] += 1) > params[:vxt]
      params[:vxc] = 0
      @dx += params[:vx]
      params[:vx] *= -1 if @dx < -params[:l] || @dx > params[:r]
    end
    if (params[:vyc] += 1) > params[:vyt]
      params[:vyc] = 0
      @dy += params[:vy]
      params[:vy] *= -1 if @dy < -params[:u] || @dy > params[:d]
    end
  end
  #--------------------------------------------------------------------------
  # ● 闪烁特效
  #--------------------------------------------------------------------------
  def start_effect_cflash(params, param_s)
    parse_param(params, param_s)
    params[:tc] = 0  # 闪烁后的等待时间计数
    params[:color] = Color.new(params[:r], params[:g], params[:b], params[:a])
  end
  def update_effect_cflash(params)
    return if (params[:tc] -= 1) > 0
    params[:tc] = params[:t] + params[:d]
    self.flash(params[:color], params[:d])
  end
  #--------------------------------------------------------------------------
  # ● 镜像特效
  #--------------------------------------------------------------------------
  def start_effect_cmirror(params, param_s)
    params[:b]  = '0'
    parse_param(params, param_s, :b)
    self.mirror = (params[:b] == '0' ? false : true)
  end
  #--------------------------------------------------------------------------
  # ● 消散特效
  #--------------------------------------------------------------------------
  def start_effect_cu(params, param_s)
    parse_param(params, param_s)
    params[:t_c] = 0 # 间隔计数
    params[:dir] = (case params[:dir]
    when 1; :LD
    when 3; :RD
    when 5; :LRUD
    when 7; :LU
    when 9; :RU
    when 4,6; :LR
    end)
    params[:s] = (case params[:s]
    when 0; :S # 正方形
    when 1; :C # 圆形（最耗时）
    when 2; :T # 三角形
    end)
  end
  def update_effect_cu(params)
    return if (params[:t_c] += 1) < params[:t]
    params[:t_c] = 0
    Unravel_Bitmap.new(self.x, self.y, self.bitmap.clone, 0, 0, self.width,
      self.height, params[:n], params[:d], params[:o], params[:dir], params[:s])
  end
end
#==============================================================================
# ○ 等待按键的精灵
#==============================================================================
class Sprite_EaglePauseTag < Sprite
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize(message_window)
    super(nil)
    bind_window(message_window)
    @type_source = 0 # 记录当前源位图的类型（见module中对应【设置】）
    @type_pos = 0 # 记录当前相对于对话框的位置类型
    @last_chara = nil
    @last_pause_index = nil
    reset
    hide
  end
  #--------------------------------------------------------------------------
  # ● 绑定window
  #--------------------------------------------------------------------------
  def bind_window(message_window)
    @message_window = message_window
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    @s_bitmap.dispose
    self.bitmap.dispose
    super
  end
  #--------------------------------------------------------------------------
  # ● 获取参数组
  #--------------------------------------------------------------------------
  def params
    @message_window.pause_params
  end
  #--------------------------------------------------------------------------
  # ● 绑定文末精灵
  #--------------------------------------------------------------------------
  def bind_last_chara(sprite_chara)
    @last_chara = sprite_chara
    reset_position
  end
  #--------------------------------------------------------------------------
  # ● 重置
  #--------------------------------------------------------------------------
  def reset
    reset_source if @last_pause_index != params[:pause]
    reset_bitmap
  end
  #--------------------------------------------------------------------------
  # ● 重置源位图
  #--------------------------------------------------------------------------
  def reset_source
    @s_bitmap.dispose if @s_bitmap
    @last_pause_index = params[:pause]
    _params = MESSAGE_EX.pause_params(@last_pause_index)
    _bitmap = Cache.system(_params[0])
    _rect = _params[1].nil? ? _bitmap.rect : _params[1]
    @s_bitmap_row = _params[2] # 源位图中一行中帧数目
    @s_bitmap_col = _params[3] # 源位图中一列中帧数目
    @s_bitmap_n = @s_bitmap_row * @s_bitmap_col # 总帧数

    @s_bitmap = Bitmap.new(_rect.width, _rect.height)
    @s_bitmap.blt(0, 0, _bitmap, _rect)
    @s_rect = Rect.new(0, 0, @s_bitmap.width / @s_bitmap_row,
      @s_bitmap.height / @s_bitmap_col)

    self.bitmap.dispose if self.bitmap
    self.bitmap = Bitmap.new(@s_rect.width, @s_rect.height)
    @index = 0 # 当前index
  end
  #--------------------------------------------------------------------------
  # ● 重绘位图
  #--------------------------------------------------------------------------
  def reset_bitmap
    self.bitmap.clear
    @s_rect.x = (@index % @s_bitmap_row) * @s_rect.width
    @s_rect.y = (@index / @s_bitmap_col) * @s_rect.height
    self.bitmap.blt(0, 0, @s_bitmap, @s_rect)
    @count = 0
  end
  #--------------------------------------------------------------------------
  # ● 更新位置
  #--------------------------------------------------------------------------
  def reset_position
    if params[:do] > 0
      MESSAGE_EX.reset_xy_dorigin(self, @message_window, params[:do])
    elsif @last_chara
      self.x = @message_window.eagle_charas_x0 + @last_chara._x + @last_chara.width
      self.y = @message_window.eagle_charas_y0 + @last_chara._y + @last_chara.height/2
    else
      self.x = @message_window.eagle_charas_x0 + 0
      self.y = @message_window.eagle_charas_y0 + 0
    end
    self.x += params[:dx]
    self.y += params[:dy]
    MESSAGE_EX.reset_xy_origin(self, params[:o])
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
    update_index
  end
  #--------------------------------------------------------------------------
  # ● 更新帧动画
  #--------------------------------------------------------------------------
  def update_index
    return if (@count += 1) < params[:t]
    @index = (@index + 1) % @s_bitmap_n
    reset_bitmap
  end
  #--------------------------------------------------------------------------
  # ● 显示
  #--------------------------------------------------------------------------
  def show
    return if params[:v] == 0
    reset_position
    self.visible = true
    self
  end
  #--------------------------------------------------------------------------
  # ● 隐藏
  #--------------------------------------------------------------------------
  def hide
    self.visible = false
    self
  end
end

#==============================================================================
# ○ 其余整合
#==============================================================================
class << DataManager
  #--------------------------------------------------------------------------
  # ● 设置新游戏
  #--------------------------------------------------------------------------
  alias eagle_message_ex_setup_new_game setup_new_game
  def setup_new_game
    eagle_message_ex_setup_new_game
    $game_message.add_escape(MESSAGE_EX::ESCAPE_STRING_INIT)
  end
end
class Spriteset_Map; attr_reader :character_sprites; end
class Scene_Map; attr_reader :spriteset; end
class Scene_Battle; attr_reader :spriteset; end
