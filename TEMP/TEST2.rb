# 玩家头顶显示调查提示
# 玩家面前的事件，当前事件页首行为注释，且填入了特定内容
# 将识别为玩家头顶显示的图标
# 当事件正在执行时，图标隐藏

module POP_HINT

end

# 对话框新增 env[sym] 转义符
#  【预先】若不存在 sym 的环境，则按照当前环境新建；否则读取并覆盖当前环境（当前环境存入 '0' 号环境）
