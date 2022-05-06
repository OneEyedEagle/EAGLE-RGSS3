#==============================================================================
# ■ Add-On 兼容ULDS by 老鹰（https://github.com/OneEyedEagle/EAGLE-RGSS3）
# ※ 本插件需要放置在【无限图层显示系统 by Taroxd】与【像素级移动 by老鹰】之下
#==============================================================================
# - 2022.5.6.23
#=============================================================================
# - 本插件将 ULDS 中的默认最小单位修改为了 像素级移动 中的最小单位，
#   保证了 ULDS 的远景图能够正常移动
#=============================================================================

module Taroxd::ULDS
  class << self
    private
    # 只计算一次的初始化代码
    def init_attr_code
      "#{set_attr_code 'z', DEFAULT_Z}
      #{set_attr_code 'scroll_x', PIXEL_MOVE::PIXEL_PER_UNIT}
      #{set_attr_code 'scroll_y', PIXEL_MOVE::PIXEL_PER_UNIT}
      #{set_attr_code 'blend_type'}
      #{set_attr_code 'color'}
      #{set_attr_code 'tone'}"
    end
  end
end
