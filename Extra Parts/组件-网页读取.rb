#==============================================================================
# ■ 组件-网页读取
#==============================================================================
=begin
===============================================================================
 EFE's Request Script
 Version: RGSS & RGSS2 & RGSS3
 Special thanks : Ryex, Gustavo Bicalho, Kubiwa Taicho
===============================================================================
 This script will allow to request to some servers WITHOUT posting. (Only GET)
--------------------------------------------------------------------------------
Used WINAPI functions:
WinHTTPOpen
WinnHTTLConnect
WinHTTPOpenRequest
WinHTTPSendRequest
WinHTTPReceiveResponse
WinHttpQueryDataAvailable
WinHttpReadData
Call:
EFE.request(host, path, buf, post, port)
host : "www.rpgmakervxace.net" (without http:// prefix)
path : "/forum/login.php" ( the directory path of your php file )
buf  : 9999 ( the size of the buffer string)
post : "username=kfdsfdsl&password=24324234"
port : 80 is default.
=end

# require "Win32API"

module EFE
  WinHttpOpen = Win32API.new('winhttp','WinHttpOpen',"PIPPI",'I')
  WinHttpConnect = Win32API.new('winhttp','WinHttpConnect',"IPII",'I')
  WinHttpOpenRequest = Win32API.new('winhttp','WinHttpOpenRequest',"IPPPPII",'I')
  WinHttpSendRequest = Win32API.new('winhttp','WinHttpSendRequest',"IIIIIII",'I')
  WinHttpReceiveResponse = Win32API.new('winhttp','WinHttpReceiveResponse',"IP",'I')
  WinHttpQueryDataAvailable = Win32API.new('winhttp', 'WinHttpQueryDataAvailable', "II", "I")
  WinHttpReadData = Win32API.new('winhttp','WinHttpReadData',"IPIP",'I')

  # I took this method from Gustavo Bicalho's WebKit script. Special thanks him.
  def self.to_ws(str)
    str = str.to_s();
    wstr = "";
    for i in 0..str.size
      wstr += str[i,1]+"\0";
    end
    wstr += "\0";
    return wstr;
  end

  def self.request(host, path, buf, post="",port=80)
    p = path
    if(post != "")
      p = p + "?" + post
    end
    p = p.to_s
    pwszUserAgent = ''
    pwszProxyName = ''
    pwszProxyBypass = ''
    httpOpen = WinHttpOpen.call(pwszUserAgent, 0, pwszProxyName, pwszProxyBypass, 0)
    if httpOpen
      httpConnect = WinHttpConnect.call(httpOpen, to_ws(host), port, 0)
      if httpConnect
        httpOpenR = WinHttpOpenRequest.call(httpConnect, nil, to_ws(p), "", '',0,0)
        if httpOpenR
          httpSendR = WinHttpSendRequest.call(httpOpenR, 0, 0 , 0, 0,0,0)
          if httpSendR
            httpReceiveR = WinHttpReceiveResponse.call(httpOpenR, nil)
            if httpReceiveR
              received = 0
              httpAvailable = WinHttpQueryDataAvailable.call(httpOpenR, received)
              if httpAvailable
                ali = ' ' * buf
                n = 0
                httpRead = WinHttpReadData.call(httpOpenR, ali, buf, o=[n].pack('i!'))
                n=o.unpack('i!')[0]
                return ali[0, n]
              else
                p("Error about query data available")
              end
            else
              p("Error when receiving response")
            end
          else
            p("Error when sending request")
          end
        else
          p("Error when opening request")
        end
      else
        p("Error when connecting to the host")
      end
    else
      p("Error when opening connection")
    end
  end
end

## Encoding

MultiByteToWideChar = Win32API.new('kernel32', 'MultiByteToWideChar', 'llplpl', 'l')
WideCharToMultiByte = Win32API.new('kernel32', 'WideCharToMultiByte', 'llplplpp', 'l')

def s2u(text)
  len = MultiByteToWideChar.call(0, 0, text, -1, nil, 0)
  buf = '\0' * (len*2)
  MultiByteToWideChar.call(0, 0, text, -1, buf, buf.size/2)
  len = WideCharToMultiByte.call(65001, 0, buf, -1, nil, 0, nil, nil)
  ret = '\0' * len
  WideCharToMultiByte.call(65001, 0, buf, -1, ret, ret.size, nil, nil)
  return ret.delete("\0")
end
#-------------------------------------------------------------------------------
#===============================================================================

# TESTING
# req = s2u(EFE.request("github.com", "/jubin-park/rgss/blob/master/windows/mouse_sensitivity.rb", 9999))
# print(req)
