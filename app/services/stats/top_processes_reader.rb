require "open3"

module Stats
  # Reads the top N processes by CPU or memory usage via `ps`, for display
  # alongside the aggregate stats. Read fresh on each request, like
  # SystemInfoReader -- this is inherently a snapshot, not something that
  # benefits from historical tracking or a poll interval.
  class TopProcessesReader
    ProcessInfo = Struct.new(:pid, :command, :rss_kb, :cpu_percent, :mem_percent, keyword_init: true)

    DEFAULT_LIMIT = 5
    SORT_FLAGS = { cpu: "-pcpu", memory: "-rss" }.freeze

    def call(sort_by: :memory, limit: DEFAULT_LIMIT)
      sort_flag = SORT_FLAGS.fetch(sort_by)
      out, status = Open3.capture2("ps", "-eo", "pid,comm,rss,pcpu,pmem", "--sort=#{sort_flag}", "--no-headers")
      return [] unless status.success?

      out.lines.first(limit).filter_map do |line|
        pid, command, rss, pcpu, pmem = line.strip.split(/\s+/, 5)
        next if pid.nil?

        ProcessInfo.new(pid: pid.to_i, command: command, rss_kb: rss.to_i, cpu_percent: pcpu.to_f, mem_percent: pmem.to_f)
      end
    rescue Errno::ENOENT
      []
    end
  end
end
