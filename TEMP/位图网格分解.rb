# TODO 位图网格化分解

=begin
s = Sprite.new
s.bitmap = Cache.system("BattleStatus_1_normal")
bs = []; xys = []
EAGLE.bitmap_crop_square(s, bs, xys)
f = ParticleManager.emitters[:charas_out].template
f.total = bs.size
f.bitmaps = bs
f.xys = xys
ParticleManager.start(:charas_out)
=end

module EAGLE
  def self.bitmap_crop_square(sprite, bitmaps, xys, sw = 5, sh = 5)
    bitmap = sprite.bitmap
    colors = []
    i = 0
    while i < bitmap.height
      j = 0
      while j < bitmap.width
        colors.clear
        flag_all_transparent = true
        sh.times do |s_i|
          sw.times do |s_j|
            c = bitmap.get_pixel(j + s_j, i + s_i)
            colors.push(c)
            flag_all_transparent = false if c.alpha > 0
          end
        end
        j += sw
        next if flag_all_transparent
        b = Bitmap.new(sw, sh)
        colors.each_with_index do |c, i_c|
          b.set_pixel(i_c % sw, i_c / sh, c)
        end
        bitmaps.push(b)
        xys.push(Vector.new(j + sprite.x, i + sprite.y))
      end
      i += sh
    end
  end
end
