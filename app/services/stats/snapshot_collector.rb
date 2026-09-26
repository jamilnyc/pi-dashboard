module Stats
  # Reads current system stats and persists them as a new StatSnapshot
  # (plus its DiskUsage/NetworkUsage children), computing CPU% and network
  # throughput as deltas against the most recent previous snapshot.
  #
  # CPU and network kernel counters are cumulative since boot, so a single
  # reading is meaningless on its own -- rates only make sense as a delta
  # between two readings over a known time interval. Rather than sleeping
  # inside the job to take two readings, this relies on the delta between
  # consecutive scheduled polls: every snapshot stores its own raw counters,
  # so "the previous reading" is simply the latest database row. That means
  # it survives process restarts, and the only cost is that the very first
  # poll ever has no prior row to diff against, leaving cpu_percent and the
  # network rates nil for exactly that one row.
  class SnapshotCollector
    def initialize(
      cpu_reader: CpuReader.new,
      memory_reader: MemoryReader.new,
      disk_reader: DiskReader.new,
      network_reader: NetworkReader.new,
      temperature_reader: TemperatureReader.new
    )
      @cpu_reader = cpu_reader
      @memory_reader = memory_reader
      @disk_reader = disk_reader
      @network_reader = network_reader
      @temperature_reader = temperature_reader
    end

    def call
      now = Time.current
      previous = StatSnapshot.order(recorded_at: :desc).first

      cpu = @cpu_reader.call
      mem = @memory_reader.call
      temp = @temperature_reader.call
      disks = @disk_reader.call
      interfaces = @network_reader.call

      interval = previous ? (now - previous.recorded_at) : nil
      mem_used_kb = mem.total_kb - mem.available_kb

      ActiveRecord::Base.transaction do
        snapshot = StatSnapshot.create!(
          recorded_at: now,
          interval_seconds: interval,
          cpu_percent: compute_cpu_percent(previous, cpu),
          cpu_raw_total: cpu.total,
          cpu_raw_idle: cpu.idle,
          cpu_temp_celsius: temp,
          mem_total_kb: mem.total_kb,
          mem_available_kb: mem.available_kb,
          mem_used_kb: mem_used_kb,
          mem_percent: (mem_used_kb.to_f / mem.total_kb * 100)
        )

        disks.each do |disk|
          snapshot.disk_usages.create!(
            device: disk.device,
            fs_type: disk.fs_type,
            mount_point: disk.mount_point,
            total_bytes: disk.total_bytes,
            used_bytes: disk.used_bytes,
            available_bytes: disk.available_bytes,
            use_percent: disk.total_bytes.zero? ? 0.0 : (disk.used_bytes.to_f / disk.total_bytes * 100)
          )
        end

        interfaces.each do |iface|
          previous_iface = previous&.network_usages&.find_by(interface: iface.name)
          rx_rate, tx_rate = compute_network_rates(previous_iface, iface, interval)

          snapshot.network_usages.create!(
            interface: iface.name,
            rx_bytes_total: iface.rx_bytes,
            tx_bytes_total: iface.tx_bytes,
            rx_bytes_per_sec: rx_rate,
            tx_bytes_per_sec: tx_rate
          )
        end

        snapshot
      end
    end

    private

    def compute_cpu_percent(previous, cpu)
      return nil unless previous

      total_delta = cpu.total - previous.cpu_raw_total
      idle_delta = cpu.idle - previous.cpu_raw_idle
      return nil if total_delta <= 0 # counter anomaly, e.g. a reboot between polls

      ((total_delta - idle_delta).to_f / total_delta * 100).round(1)
    end

    def compute_network_rates(previous_iface, iface, interval)
      return [ nil, nil ] if previous_iface.nil? || interval.nil? || interval <= 0

      rx_delta = iface.rx_bytes - previous_iface.rx_bytes_total
      tx_delta = iface.tx_bytes - previous_iface.tx_bytes_total
      return [ nil, nil ] if rx_delta.negative? || tx_delta.negative? # counter reset / interface replugged

      [ (rx_delta / interval).round(1), (tx_delta / interval).round(1) ]
    end
  end
end
