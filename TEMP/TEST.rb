text = "\\key[测]"
text.gsub!(/\\key\[(.*?)\]/i) {
  c1 = $1[0]; c2 = $1[1..-1]; "#{c1}\\key[#{$1}]#{c2}" }
p text
