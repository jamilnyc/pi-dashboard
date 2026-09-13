module Stats
  # Parses /proc/meminfo for total and available memory.
  class MemoryReader
    Result = Struct.new(:total_kb, :available_kb, keyword_init: true)

    PROC_MEMINFO_PATH = "/proc/meminfo"

    def call
      values = {}
      File.foreach(PROC_MEMINFO_PATH) do |line|
        if line =~ /^(\w+):\s+(\d+)/
          values[$1] = $2.to_i
        end
      end

      total = values.fetch("MemTotal")
      # MemAvailable (kernel >= 3.14) already accounts for reclaimable caches;
      # fall back to the older approximation if it's missing.
      available = values["MemAvailable"] || (values.fetch("MemFree") + values.fetch("Buffers", 0) + values.fetch("Cached", 0))

      Result.new(total_kb: total, available_kb: available)
    end
  end
end
