module EAGLE
class World
  # world coord
  #  +----- x
  #  |
  #  |
  #  y
  def initialize
    @camera = Camera.new(500)

    points = {
      # index => [x, y, z, u, v]
      0 => Point.new(-0.2, -0.2, 0.5, 0.0, 0.0), # lu
      1 => Point.new(0.2, -0.2, 0.5, 1.0, 0.0), # ru
      2 => Point.new(-0.2, 0.2, 0.5, 0.0, 1.0), # ld
      3 => Point.new(0.2, 0.2, 0.5, 1.0, 1.0), # rd
    }
    faces = [
      [0,1,2],
      [1,2,3]
    ]
    @mesh_image = Mesh.new(points, faces)
    @mesh_image.bitmap = Cache.face("ph_n_1x1")

    @angle = 0
    @angle_v = 1

    refresh
  end

  def refresh
    @mesh_image.apply_camera(@camera)
  end

  def update
      @angle += @angle_v
      @camera.rotate_origin2des(nil, @angle, nil)
      refresh
      @angle_v = -1 if @angle == 60
      @angle_v = 1 if @angle == -60
  end

  def dispose
    @mesh_image.dispose
  end
end

class Camera
  # 向右为 x 正方向，向下为 y 正方向，向内为 z 正方向
  # 依据右手螺旋定则获得旋转的正方向
  # perspective camera
  #  lookat: Vec(0,0,1)
  #  up: Vec(0,1,0)
  def initialize(f, cx = Graphics.width / 2, cy = Graphics.height / 2)
    # intrinsic
    @f = f # pixel number per meter
    @cx = cx
    @cy = cy
    # extrisic
    #  from world to camera
    @angle_x = @angle_y = @angle_z = 0
    @R = [[1,0,0], [0,1,0], [0,0,1]]
    @T = [0,0,0]
    translate_origin2des(0,0,-1)
  end

  def sin(angle); EAGLE.sin(angle); end
  def cos(angle); EAGLE.cos(angle); end
  def rotate_origin2des(ax = nil, ay = nil, az = nil)
    ax ||= @angle_x
    ay ||= @angle_y
    az ||= @angle_z
    @R[0][0] = cos(az)*cos(ay)
    @R[0][1] = -sin(az)*cos(ay)
    @R[0][2] = sin(ay)
    @R[1][0] = cos(az)*sin(ax)*sin(ay)+sin(az)*cos(ax)
    @R[1][1] = cos(az)*cos(ax)-sin(az)*sin(ax)*sin(ay)
    @R[1][2] = -sin(ax)*cos(ay)
    @R[2][0] = sin(az)*sin(ax)-cos(az)*cos(ax)*sin(ay)
    @R[2][1] = sin(az)*cos(ax)*sin(ay)+cos(az)*sin(ax)
    @R[2][2] = cos(ax)*cos(ay)
    @angle_x = ax
    @angle_y = ay
    @angle_z = az
  end
  def rotate(dx = 0, dy = 0, dz = 0)
    rotate_origin2des(@angle_x + dx, @angle_y + dy, @angle_z + dz)
  end
  def translate_origin2des(dx = nil, dy = nil, dz = nil)
    @T[0] = dx if dx
    @T[1] = dy if dy
    @T[2] = dz if dz
  end
  def translate(dx = 0, dy = 0, dz = 0)
    @T[0] += dx
    @T[1] += dy
    @T[2] += dz
  end

  def project_world2image(point)
    point_ = Point.new(0,0,0,point.u,point.v)
    point_.x = @R[0][0] * point.x + @R[0][1] * point.y + @R[0][2] * point.z - @T[0]
    point_.y = @R[1][0] * point.x + @R[1][1] * point.y + @R[1][2] * point.z - @T[1]
    point_.z = @R[2][0] * point.x + @R[2][1] * point.y + @R[2][2] * point.z - @T[2]

    point_.x = point_.x * @f + point_.z * @cx
    point_.y = point_.y * @f + point_.z * @cy
    if point_.z != 0
      point_.x = point_.x * 1.0 / point_.z
      point_.y = point_.y * 1.0 / point_.z
    end
    return point_
  end
end

class Point
  attr_accessor :x, :y, :z, :u, :v
  def initialize(x = 0, y = 0, z = 0, u = 0.0, v = 0.0)
    @x = x; @y = y; @z = z; @u = u; @v = v
  end
end
class Mesh
  attr_accessor :bitmap, :points, :faces, :geometry
  def initialize(points, faces)
    @points = points
    @points_ = {}
    @faces = faces
    @bitmap = nil
    @geometry = Geometry.new
  end
  def apply_camera(camera)
    @points.each do |id, point|
      @points_[id] = camera.project_world2image(point)
    end
    refresh
  end
  def refresh
    @geometry.bitmap = @bitmap
    @geometry.triangles = @faces.size
    @faces.each_with_index do |face, i|
      face.each_with_index do |point_i, p_i|
        point = @points_[point_i]
        @geometry.set_point_position(i, p_i, point.x, point.y)
        @geometry.set_point_texcoord(i, p_i, point.u, point.v)
      end
    end
  end
  def dispose
    @geometry.dispose
  end
end

class Mesh_Picture << Mesh
  def initialize(bitmap)
    super()
  end
end
end # end of EAGLE
