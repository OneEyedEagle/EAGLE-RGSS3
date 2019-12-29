module EAGLE
class World
  # world coord
  #  +----- x
  #  |
  #  |
  #  y
  def initialize
    @camera = Camera.new(40)

    @points = {
      # index => [x, y, z, u, v]
      0 => Point.new(x, y, 0, 0.0, 0.0),
      1 => Point.new(x, y, 0, 1.0, 0.0),
      2 => Point.new(x, y, 0, 0.0, 1.0),
      3 => Point.new(x, y, 0, 1.0, 1.0),
    }
    @faces = [
      [0,1,2],
      [1,2,3]
    ]
    @mesh_image = Mesh.new(@points, @faces)
    @mesh_image.bitmap = Cache.system("")
  end
  def refresh
    @mesh_image.apply_camera(@camera)
  end
  def update
  end
  def dispose
    @mesh_image.dispose
  end
end
class Camera
  # perspective camera
  def initialize(f = 40)
    @R = [[1 0 0], [0 1 0], [0 0 1]]
    @T = [Graphics.width / 2, Graphics.height / 2, 0]
    @f = f
    @cx = Graphics.width / 2
    @cy = Graphics.height / 2
  end
  def project_world2image(point)
    point_ = Point.new
    point_.x = (point.x * @f + point.z * @cx) * 1.0 / point.z
    point_.y = (point.y * @f + point.z * @cy) * 1.0 / point.z
    point_.z = 1
    point_.u = point.u
    point_.v = point.v
    return point_
  end
end
class Mesh
  attr_accessor :bitmap, :points, :faces, :geometry
  def initialize(points, faces)
    @points = @points_ = points
    @faces = faces
    @bitmap = nil
    @geometry = Geometry.new
  end
  def apply_camera(camera)
    @points.each do |id, point|
      @points_[id] = camera.project_world2image(point)
    end
  end
  def refresh
    @geometry.bitmap = @bitmap
    @faces.each_with_index do |face, tri_i|
      face.each_with_index do |point_i, p_i|
        point = @points_[point_i]
        @geometry.set_point_position(tri_i, p_i, point.x, point.y, point.z)
        @geometry.set_point_texcoord(tri_i, p_i, point.u, point.v)
      end
    end
  end
  def dispose
    @geometry.dispose
  end
end
class Point
  attr_accessor :x, :y, :z, :u, :v
  def initialize(x = 0, y = 0, z = 0, u = 0.0, v = 0.0)
    @x = x; @y = y; @z = z; @u = u; @v = v
  end
end
end # end of EAGLE
