=begin
\cin[vz5]这一切都来自于那场\cwave[1]奇怪的梦\cwave[0]：
被我\cshake[l2d3u2r3]一剑刺穿\cshake[0]的他，
\pos[l4]脸上却只有\font[p1]释然\font[p0]。
但\font[l1]现在\font[l0]的我呢？
嫉<para>\pos[dc1dl1]不甘、</para>妒、狞<para>\pos[dc1dl1]傲慢</para>笑\pos[dx40dy12]归于茫然
\pos[c7]\csin[1]丑陋\csin[0]的我接受着众人的\cflash[r255g80b80d90]仰慕\cflash[0]，直至发生了\cmirror[1]梦\cmirror[0]中的事。
肯定，我也会\font[u1]和\font[p2]他\font[p0]一样\font[u0]，
<para>\pos[dc2]释然地受着刺穿的剑。</para>嘲讽地看着面前的人；
\pos[l4dc3]永恒地\font[d1]在梦中\font[d0]循环。
=end

text = "\\key[测]"
text.gsub!(/\\key\[(.*?)\]/i) {
  c1 = $1[0]; c2 = $1[1..-1]; "#{c1}\\key[#{$1}]#{c2}" }
p text
