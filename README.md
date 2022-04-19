# 老鹰的脚本小巢 - RGSS3

![](LOGO.png)

*LOGO绘制by[葱兔](http://onira.lofter.com/)*

## 基本信息

这里放置的是老鹰平时所写的用于RPG Maker VX Ace的RGSS3类型扩展插件，一般无法用于其他版本。

### 文件夹说明

- Message System → 对默认对话框的扩展 或 与文本显示相关的插件
- Event System → 对事件的扩展 或 地图上可用的扩展
- Battle System → 战斗相关插件 或 对VA数据库的扩展
- UI Parts → 功能系统 或 UI类的插件
- Extra Parts → 额外扩展组件，用于实现一些基础功能
- Demos → 一些特定插件的范例工程，具体见各个子文件夹下的README文件
- TEMP → （不推荐使用）仍在设计中的或修改中的未完成品

### 插件版本

- 在插件头部注释中，有一行会以 年份.月份.日期.序号[.序号] 的格式记录当前插件的更新版本/修改信息，请按照时间最新、序号最大的方式进行新旧版本号的比较。

- 在新版本的插件中，头部的 _$imported["插件名称"] = "1.2.3"_ 将直接写明该插件的版本号，比如此处的 _"1.2.3"_，其中第一个数字 _1_ 代表大版本，当该数字不同时，代表插件出现了较大的变动，且使用方法也会发生较大变化，可能完全无法直接进行替换，其中第二个数字 _2_ 代表功能更新，一般新增或删除了部分功能，请注意核查注释，尤其是替换掉对被删除功能的调用，其中第三个数字 _3_ 为BUG修复，可以直接复制并覆盖旧版本


### 下载方式

- 【推荐】在当前页的文件列表的右上处，有绿色的“Clone or download”字样按钮，点击后在弹出的框中选择“Download ZIP”，即可打包下载整个仓库，.rb的文件可以用文本文档打开

- 点击进入脚本文件的预览页面后，右上有“Raw”字样的按钮，点击进入只含有文件内容的页面，可利用Ctrl+A进行全选，再复制黏贴到你的工程中的空白脚本页内

- 【借助第三方工具】若你已经登录了GitHub，可以通过设置GitHub Key后利用第三方工具（如[这个](https://download-directory.github.io/)）下载仓库中的独立文件夹：点击your GitHub token后跳转到你自己账户下的key生成界面，拖至最底部点击绿色按键生成key，然后复制key的字符串（注意：该字符串以后无法再找到，请保存好）到原网页中的输入框；此时可以通过在浏览器地址栏输入比如 https://download-directory.github.io?url=https://github.com/OneEyedEagle/EAGLE-RGSS3/tree/master/Demos/DEMO_EagleMessageEX 下载本仓库的Demos/DEMO_EagleMessageEX整个文件夹

### 更多示例

- 针对 Message System 里的[【对话框扩展】](https://github.com/OneEyedEagle/EAGLE-RGSS3/tree/master/Message%20System/%E5%AF%B9%E8%AF%9D%E6%A1%86%E6%89%A9%E5%B1%95)，欢迎到Project1论坛中的[对话框扩展发布页](https://rpg.blue/thread-476586-1-1.html)查看更多使用范例，其中也有⑨姐姐帮忙创建的Q群，希望我的对话框扩展能帮到你吧~

- 针对 Event System 里的[【事件消息机制】](https://github.com/OneEyedEagle/EAGLE-RGSS3/blob/master/Event%20System/%E4%BA%8B%E4%BB%B6%E6%B6%88%E6%81%AF%E6%9C%BA%E5%88%B6.rb)，可以查看论坛中的[帖子](https://rpg.blue/thread-479571-1-1.html)

- 针对 UI Parts 里的[【简易合成分解系统】](https://github.com/OneEyedEagle/EAGLE-RGSS3/blob/master/UI%20Parts/%E7%AE%80%E6%98%93%E5%90%88%E6%88%90%E5%88%86%E8%A7%A3%E7%B3%BB%E7%BB%9F.rb)，可以查看论坛中的[帖子](https://rpg.blue/thread-479599-1-1.html)

- 针对 Message System 里的[【对话日志】](https://github.com/OneEyedEagle/EAGLE-RGSS3/blob/master/Message%20System/%E5%AF%B9%E8%AF%9D%E6%97%A5%E5%BF%97.rb)，可以查看论坛中的[帖子](https://rpg.blue/thread-482638-1-1.html)

- 针对 Message System 里的【AddOn-Live2D扩展】，可以查看论坛中的[帖子](https://rpg.blue/thread-483306-1-1.html)

- 针对 Event System 里的[【事件互动扩展】](https://github.com/OneEyedEagle/EAGLE-RGSS3/tree/master/Event%20System/%E4%BA%8B%E4%BB%B6%E4%BA%92%E5%8A%A8%E6%89%A9%E5%B1%95)，可以查看论坛中的[帖子](https://rpg.blue/thread-485177-1-1.html)

- 针对 UI Parts 里的[【能力学习系统】](https://github.com/OneEyedEagle/EAGLE-RGSS3/blob/master/UI%20Parts/%E8%83%BD%E5%8A%9B%E5%AD%A6%E4%B9%A0%E7%B3%BB%E7%BB%9F.rb)，可以查看论坛中的[帖子](https://rpg.blue/thread-487653-1-1.html)

- 针对 Message System 里的[【通知队列】](https://github.com/OneEyedEagle/EAGLE-RGSS3/tree/master/Message%20System/%E9%80%9A%E7%9F%A5%E9%98%9F%E5%88%97)，可以查看论坛中的[帖子](https://rpg.blue/thread-488207-1-1.html)

- 针对 Event System 里的[【角色头顶显示图标】](https://github.com/OneEyedEagle/EAGLE-RGSS3/tree/master/Event%20System/%E8%A7%92%E8%89%B2%E5%A4%B4%E9%A1%B6%E6%98%BE%E7%A4%BA%E5%9B%BE%E6%A0%87)，可以查看论坛中的[帖子](https://rpg.blue/thread-489304-1-1.html)


## 利用规约

![GitHub](https://img.shields.io/github/license/OneEyedEagle/EAGLE-RGSS3.svg?style=flat-square)

本repo下的代码基本遵循MIT开源协议

（部分插件的头部可能会有特殊的使用说明）

- 自由地用于任何工程内（不可违反当地法律法规）

- 需要署名（老鹰 / 独眼老鹰）

- 不强制报告（可发邮件至 eagle_zhou@foxmail.com 以表达感谢、使用报告、赠予试玩版hhh）

- 允许修改、扩展、二次上传（二次发布需遵循MIT协议），但应注明修改内容并保留原作者信息

## 特别声明

由于本人精力有限，此处分享的脚本不会对其余脚本进行特别的兼容与整合（除非我自己在用）。

如果需要付费将某些脚本与指定脚本进行兼容，请在[Project1论坛](https://rpg.blue/home.php?mod=space&uid=287268)私信联系我，或微博[@独眼老鹰](https://www.weibo.com/oneeyedeagle)短消息联系我。
