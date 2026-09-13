module Stats
  # Parses the aggregate CPU line from /proc/stat into cumulative jiffy counters.
  # These are totals since boot -- a single reading is meaningless on its own;
  # CPU% must be computed as a delta between two readings (see SnapshotCollector).
  class CpuReader
    Result = Struct.new(:total, :idle, keyword_init: true)

    PROC_STAT_PATH = "/proc/stat"

    def call
      line = File.readlines(PROC_STAT_PATH).first
      # "cpu  user nice system idle iowait irq softirq steal guest guest_nice"
      user, nice, system, idle, iowait, irq, softirq, steal, = line.split[1..].map(&:to_i)

      # guest/guest_nice are deliberately excluded from the total: on modern
      # kernels guest time is already folded into `user`, so adding it again
      # would double-count it. This matches the convention top/htop use.
      idle_all = idle + iowait
      total = user + nice + system + idle_all + irq + softirq + steal

      Result.new(total: total, idle: idle_all)
    end
  end
end
