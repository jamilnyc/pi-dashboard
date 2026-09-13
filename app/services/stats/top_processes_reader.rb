require "open3"

module Stats
  # Reads the top N processes by resident memory usage via `ps`, for display
  # alongside the aggregate memory stats. Read fresh on each request, like
  # SystemInfoReader -- this is inherently a snapshot, not something that
  # benefits from historical tracking or a poll interval.
  class TopProcessesReader
    ProcessInfo = Struct.new(:pid, :command, :rss_kb, :percent, keyword_init: true)

    DEFAULT_LIMIT = 5

    def call(limit: DEFAULT_LIMIT)
      out, status = Open3.capture2("ps", "-eo", "pid,comm,rss,pmem", "--sort=-rss", "--no-headers")
      return [] unless status.success?

      out.lines.first(limit).filter_map do |line|
        pid, command, rss, pmem = line.strip.split(/\s+/, 4)
        next if pid.nil?

        ProcessInfo.new(pid: pid.to_i, command: command, rss_kb: rss.to_i, percent: pmem.to_f)
      end
    rescue Errno::ENOENT
      []
    end
  end
end
