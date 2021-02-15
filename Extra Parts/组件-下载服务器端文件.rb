#==============================================================================
# ■ 组件-下载服务器端文件 by 老鹰（http://oneeyedeagle.lofter.com/）
#==============================================================================
$imported ||= {}
$imported["EAGLE-DownloadFromServer"] = true
#==============================================================================
# - 2021.2.15.23
#==============================================================================
# - 本插件定义了能够存储服务器端文件到本地的方法：
#
#      EAGLE.download_from_url(file_server, file_save)
#
#   其中 file_server 为位于服务器上的文件的完整路径（含后缀名）
#   其中 file_save 为保存到本地的文件（含后缀名）
#
# - 示例：
=begin
# 定义位于服务器端的文件地址
file1 = "https://raw.githubusercontent.com/OneEyedEagle/EAGLE-CATALOG/master/versions/%E5%BC%B1%E6%B0%B4%E6%84%BF.txt"
# 定义本地存储的文件
file2 = "./version.txt"
# 将把在github上的版本文件下载到 exe 同级目录下，并存储为 version.txt 文件
EAGLE.download_from_url(file1, file2)
# 之后可以在本地打开文件并进行处理
# 比如：按行读取txt，并输出
File.open(file2, "r") do |file|
  file.each_line do |line|
    puts line
  end
end
=end
#
# - 本质为调用Win32API，利用Windows的 urlmon.lib 库进行文件的下载
#==============================================================================

# require "Win32API"

#==============================================================================
# ○ 【读取部分】
#==============================================================================
module EAGLE

  @@URLDownloadToFile = Win32API.new('urlmon','URLDownloadToFile',"IPPIP",'I')

  def self.download_from_url(file1, file2)
    @@URLDownloadToFile.call(0, file1, file2, 0, 0)
  end

end
