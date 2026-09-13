require "open3"
require "socket"

module Stats
  # Reads static host/OS/hardware info for display in the dashboard footer.
  # Unlike the other readers, none of this varies between polls, so it's read
  # fresh on each request rather than persisted alongside the stat snapshots.
  class SystemInfoReader
    Info = Struct.new(:hostname, :model, :os_version, :kernel_version, :cpu_cores, keyword_init: true)

    OS_RELEASE_PATH = "/etc/os-release"
    DEVICE_TREE_MODEL_PATH = "/proc/device-tree/model"
    CPUINFO_PATH = "/proc/cpuinfo"

    def call
      Info.new(
        hostname: Socket.gethostname,
        model: cpu_model,
        os_version: os_version,
        kernel_version: kernel_version,
        cpu_cores: cpu_cores
      )
    end

    private

    def os_version
      return nil unless File.exist?(OS_RELEASE_PATH)

      File.read(OS_RELEASE_PATH)[/^PRETTY_NAME="?(.*?)"?$/, 1]
    rescue Errno::ENOENT, Errno::EACCES
      nil
    end

    def kernel_version
      out, status = Open3.capture2("uname", "-r")
      status.success? ? out.strip : nil
    rescue Errno::ENOENT
      nil
    end

    # Raspberry Pi (like most ARM boards) leaves /proc/cpuinfo's "model name"
    # field blank -- the board model instead lives in the device tree. Fall
    # back to /proc/cpuinfo for x86 hosts, where the device tree doesn't exist.
    def cpu_model
      from_device_tree || from_cpuinfo
    end

    def from_device_tree
      return nil unless File.exist?(DEVICE_TREE_MODEL_PATH)

      File.read(DEVICE_TREE_MODEL_PATH).delete("\0").strip.presence
    rescue Errno::ENOENT, Errno::EACCES
      nil
    end

    def from_cpuinfo
      return nil unless File.exist?(CPUINFO_PATH)

      File.read(CPUINFO_PATH)[/^model name\s*:\s*(.+)$/, 1]&.strip
    rescue Errno::ENOENT, Errno::EACCES
      nil
    end

    def cpu_cores
      return nil unless File.exist?(CPUINFO_PATH)

      count = File.read(CPUINFO_PATH).scan(/^processor\s*:/).count
      count.positive? ? count : nil
    rescue Errno::ENOENT, Errno::EACCES
      nil
    end
  end
end
