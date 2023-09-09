#==============================================================================
# ■ 组件-JSON解析
# From: https://github.com/RGSS3/SJSON
#==============================================================================
$imported ||= {}
$imported["JSONParser"] = "1.0.0"
#=============================================================================
# - 2020.6.29.11
#=============================================================================
# - 使用示例
=begin
text = '{ "programmers": [
    { "firstName": "Brett", "lastName":"McLaughlin", "age": 26, "email": "brett@newInstance.com" },
    { "firstName": "Jason", "lastName":"Hunter", "age": 24, "email": "jason@servlets.com" },
    { "firstName": "Elliotte", "lastName":"Harold", "age": 31, "email": "elharo@macfaq.com" }
   ] }'
s = JSONParser.new(text)
p hash_result = s.parse
=end
#=============================================================================

class JSONParser
    SyntaxError = Class.new(StandardError)
    def raise(a)
      utext = @text[0, @pos]
      lines = utext.count("\n") + 1
      cols = utext.sub(/^.*\n/, "").length
      super SyntaxError, "JSONParser: line #{lines} col #{@pos - cols}, #{a}"
    end

    def initialize(text)
      @text = text.gsub(/\r\n/, "\n")
      reset
    end

    def reset
      @pos = 0
    end

    def peek?(st)
      @text[@pos, 1] == st
    ensure
      $@.shift if $@
    end

    def peekany?(st)
      st.index(@text[@pos, 1])
    ensure
      $@.shift if $@
    end

    def match(st)
      raise "excepted #{st.inspect}, got #{@text[@pos, 1].inspect}" if @text[@pos, 1] != st
      getchar
    ensure
      $@.shift if $@
    end

    def matchany(st)
      raise "excepted any of #{st.inspect}, got #{@text[@pos, 1].inspect}" if !st.index(@text[@pos, 1])
      getchar
    ensure
      $@.shift if $@
    end

    def skipany(s)
      @pos += 1 while peekany?(s)
    ensure
      $@.shift if $@
    end

    def getchar
      @pos += 1
      @text[@pos - 1, 1]
    ensure
      $@.shift if $@
    end

    def ws
      skipany " \n\t"
      if peek?("#")
        @pos += 1 while @pos < @text.length && @text[@pos, 1] != "\n"
        @pos += 1 if @text[@pos, 1] == "\n"
      end
      skipany " \n\t"
    ensure
      $@.shift if $@
    end

    def object
      result = {}
      ws
      match "{"
      ws
      while 0
        ws
        break getchar if peek? "}"
        ws;      name = string
        ws;      match ":"
        ws;      val  = value
        result[name] = val
        ws
        case
        when peek?(",")
          match ","; raise "unexpected }" if peek?("}"); next
        when peek?("}")
          match "}"; break
        else
          raise "expected , or }, got #{getchar.inspect}"
        end
      end
      result
    ensure
      $@.shift if $@
    end

    def array
      result = []
      ws;  match '['
      ws;
      while 0
        ws
        break getchar if peek? "]"
        result.push value
        ws;
        case
        when peek?(",")
           match ","; raise "unexpected ]" if peek?("]"); next
        when peek?("]")
           match "]"; break
        else
          raise "expected , or ], got #{getchar.inspect}"
        end
      end
      result
    ensure
      $@.shift if $@
    end

    def value
      ws;
      case
      when peek?("\"")              then string
      when peekany?("-0123456789")  then number
      when peek?("[") then array
      when peek?("{") then object
      when peek?("t") then match("t"); match("r"); match("u"); match("e"); true
      when peek?("f") then match("f"); match("a"); match("l"); match("s"); match("e"); false
      when peek?("n") then match("n"); match("u"); match("l"); match("l"); ()
      end
    ensure
      $@.shift if $@
    end

    def string
      ws
      result = ""
      match "\""
      while 0
        break getchar if peek? "\""
        case
        when peek?("\\")
          match "\\"
          ch = getchar
          case ch
          when "\"" then result << "\""
          when "\\" then result << "\\"
          when "/"  then result << "/"
          when "b"  then result << "\b"
          when "f"  then result << "\f"
          when "n"  then result << "\n"
          when "r"  then result << "\r"
          when "t"  then result << "\t"
          when "x"  then result << (getchar << getchar).to_i(16).chr
          when "u"  then result << [(getchar << getchar << getchar << getchar).reverse].pack("h*")
          else
             raise "unexpected #{ch.inspect}"
          end
        when peek?("\"")
          match "\""; break
        else
          result << getchar
        end
     end
      result
    ensure
      $@.shift if $@
    end

    def number
      ws;
      r = @pos
      if peek?("-")
        match "-"
      end
      if peek?("0")
        getchar
      else
        matchany("0123456789")
        getchar while peekany?("0123456789")
        if peek?(".")
          getchar
          matchany("0123456789")
          getchar while peekany?("0123456789")
        end
        if peekany?("eE")
          getchar
          matchany("0123456789+-")
          getchar while peekany?("0123456789")
        end
      end
      Float(@text[r, @pos-r])
    ensure
      $@.shift if $@
    end

    def parse
      ws;
      case
      when peek?("[") then array
      when peek?("{") then object
      else raise "expected [ or {, got #{getchar.inspect}"
      end
    end
end
