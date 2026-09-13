module Stats
  # The single place that reads stat data for display. Kept separate from
  # DashboardController so a future Api::V1::StatsController can reuse it
  # verbatim (e.g. render json: instead of render :show) without duplicating
  # any query logic.
  class DashboardQuery
    def initialize(since: 24.hours.ago)
      @since = since
    end

    def latest_snapshot
      StatSnapshot.order(recorded_at: :desc).first
    end

    def latest_disk_usages
      latest_snapshot&.disk_usages || []
    end

    def latest_network_usages
      latest_snapshot&.network_usages || []
    end

    def cpu_series
      { "CPU %" => snapshots_scope.pluck(:recorded_at, :cpu_percent).map { |t, v| [label(t), v] } }
    end

    def memory_series
      { "Memory %" => snapshots_scope.pluck(:recorded_at, :mem_percent).map { |t, v| [label(t), v] } }
    end

    def temperature_series
      { "Temperature (°C)" => snapshots_scope.pluck(:recorded_at, :cpu_temp_celsius).map { |t, v| [label(t), v] } }
    end

    # => { "/" => [[time_label, pct], ...], "/boot/firmware" => [...] }
    def disk_series_by_mount_point
      DiskUsage
        .joins(:stat_snapshot)
        .merge(snapshots_scope)
        .order("stat_snapshots.recorded_at")
        .pluck(:mount_point, "stat_snapshots.recorded_at", :use_percent)
        .group_by { |mount_point, _, _| mount_point }
        .transform_values { |rows| rows.map { |_, time, pct| [label(time), pct] } }
    end

    # => { "eth0" => { rx: [[time_label, bytes/sec], ...], tx: [...] }, "wlan0" => {...} }
    def network_series_by_interface
      NetworkUsage
        .joins(:stat_snapshot)
        .merge(snapshots_scope)
        .order("stat_snapshots.recorded_at")
        .pluck(:interface, "stat_snapshots.recorded_at", :rx_bytes_per_sec, :tx_bytes_per_sec)
        .group_by { |iface, _, _, _| iface }
        .transform_values do |rows|
          {
            rx: rows.map { |_, time, rx, _| [label(time), rx] },
            tx: rows.map { |_, time, _, tx| [label(time), tx] }
          }
        end
    end

    private

    def snapshots_scope
      StatSnapshot.where(recorded_at: @since..)
    end

    # Chartkick is used with xtype: "string" (a plain category axis) rather
    # than its default time axis, which needs a Chart.js date-adapter package
    # we'd otherwise have to vendor. Formatting timestamps ourselves keeps the
    # stack to just Chart.js + Chartkick with no extra JS dependency.
    def label(time)
      time.strftime("%m/%d %H:%M:%S")
    end
  end
end
