#encoding:utf-8
#==============================================================================
# ■ 组件-位图存储PNG（VX/VA）
# 来源：https://rpg.blue/forum.php?mod=viewthread&tid=382258
#==============================================================================
$imported ||= {}
$imported["SaveBitmapToPNG"] = true
#=============================================================================
# - 2022.5.4.20
#=============================================================================

class Bitmap
  #-------------------------------------------------------------------#
  #借鉴dant所成
  #当然 我也努力了 —_—||
  #不 是很努力呢                         -By SixRC
  #-------------------------------------------------------------------#
  #用法为  bitmap.ToPng(filename)
  #假如很追求速度的话 下面的第34行改成
  #data2 = Zlib::Deflate.deflate(@bit_data，1)
  #这样压缩速度会提高(约快一倍) 虽然文件会变大 那个数值可以是1-9 0是不压缩 但不骗你 很慢 因为 写入慢了
  #-------------------------------------------------------------------#
  #--------------------------获取数据头地址---------------
  CWP = Win32API.new('user32.dll','CallWindowProc','ppiii','i')
  GetAddr=[139,116,36,8,139,54,139,118,8,139,118,16,139,124,36,4,137,55,194,16,0].pack("C*")
  def addr
    s="\0"*4
    CWP.call(GetAddr,s,object_id*2+16,0,0)
    s.unpack("L")[0]
  end
  #--------------------------保存为png--------------------
  D1="\x89\x50\x4e\x47\x0d\x0a\x1a\x0a\x0\x0\x0\xdIHDR"
  D2="\x8\x6\x0\x0\x0"
  D3="\x00\x00\x00\x00\x49\x45\x4E\x44\xAE\x42\x60\x82"
  GetData=[85,137,229,139,125,8,49,210,139,101,20,137,227,68,139,69,16,137,198,193,230,3,193,224,2,15,175,224,139,69,12,1,196,139,77,16,66,41,244,88,15,200,193,200,8,137,4,23,141,82,4,73,117,241,75,117,232,137,236,93,194,16,0].pack("C*")
  def ToPng(pl)
    unless @kg
      @addr=addr
      @kg=[width].pack("N")+[height].pack("N")
      c1="IHDR"+@kg+D2
      @crc1=[Zlib.crc32(c1)].pack("N")
      @bit_data="\0"*height*(width*4+1)
    end
    CWP.call(GetData,@bit_data,@addr,width,height)
    data2 = Zlib::Deflate.deflate(@bit_data)
    crc2=[Zlib.crc32("IDAT"+data2)].pack("N")
    sod=[data2.length].pack("N")
    File.open(pl, "wb") { |i| i << D1 << @kg << D2 << @crc1 << sod << 'IDAT' << data2 << crc2 << D3}
  end
end
