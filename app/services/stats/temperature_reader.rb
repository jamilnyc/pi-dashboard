require "open3"

module Stats
  # Reads the SoC temperature. Prefers the sysfs thermal zone (no subprocess,
  # always present on Linux) and falls back to `vcgencmd` if that file is
  # missing or reports zero (e.g. running under an unusual kernel config).
  class TemperatureReader
    THERMAL_ZONE_PATH = "/sys/class/thermal/thermal_zone0/temp"

    def call
      from_thermal_zone || from_vcgencmd
    end

    private

    def from_thermal_zone
      return nil unless File.exist?(THERMAL_ZONE_PATH)

      millidegrees = File.read(THERMAL_ZONE_PATH).to_i
      return nil unless millidegrees.positive?

      millidegrees / 1000.0
    rescue Errno::ENOENT, Errno::EACCES
      nil
    end

    def from_vcgencmd
      out, status = Open3.capture2("vcgencmd", "measure_temp")
      return nil unless status.success?

      out[/temp=([\d.]+)/, 1]&.to_f
    rescue Errno::ENOENT
      nil
    end
  end
end
