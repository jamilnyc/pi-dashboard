require "open3"

module Stats
  # Shells out to `df` for usage of every real mounted filesystem, excluding
  # pseudo filesystems (tmpfs, devtmpfs, etc.) that don't represent physical
  # storage the user cares about.
  class DiskReader
    Disk = Struct.new(:device, :fs_type, :mount_point, :total_bytes, :used_bytes, :available_bytes, keyword_init: true)

    EXCLUDED_FS_TYPES = %w[tmpfs devtmpfs squashfs overlay].freeze

    def call
      out, status = Open3.capture2(*df_command)
      return [] unless status.success?

      out.lines.drop(1).filter_map do |line|
        source, fstype, size, used, avail, target = line.split(/\s+/, 6)
        next if source.nil? || target.nil?

        Disk.new(
          device: source,
          fs_type: fstype,
          mount_point: target.strip,
          total_bytes: size.to_i,
          used_bytes: used.to_i,
          available_bytes: avail.to_i
        )
      end
    end

    private

    def df_command
      cmd = [ "df", "--output=source,fstype,size,used,avail,target", "-B1" ]
      EXCLUDED_FS_TYPES.each { |type| cmd += [ "-x", type ] }
      cmd
    end
  end
end
