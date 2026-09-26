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

    # Every *_series method below returns data already shaped for Chartkick's
    # documented multi-series format -- an ARRAY of { name:, data: } hashes --
    # so it can be passed straight to line_chart with no further wrapping.
    #
    # This matters because Chartkick silently misinterprets anything else. A
    # single-key Hash like { "CPU %" => pairs } looks reasonable but isn't a
    # format it recognizes: Chartkick.js's series-format check
    # (`!isArray(series) || !isPlainObject(series[0])`) sees the JSON Ruby's
    # Hash#chart_json produces for that -- [["CPU %", pairs]] -- and since
    # series[0] is an Array, not a plain object, it decides this must be a
    # single UNNAMED series and wraps the whole array-of-tuples as that
    # series' "data". It then reads that data's first (and only) "pair" as
    # x = "CPU %", y = pairs, and coerces y with parseFloat(pairs) -- which
    # stringifies the nested array and parses its leading digits, e.g.
    # parseFloat("09/13 13:27:00,...") == 9. That's what produced a single
    # bogus ~9% / ~9C point on every chart instead of the real history.
    # Passing [{ name:, data: }] avoids the misdetection entirely: JSON
    # objects parse to plain JS objects, so singleSeriesFormat comes back
    # false and each series' real [x, y] pairs are used as-is.
    def cpu_series
      [ { name: "CPU %", data: pairs_for(:cpu_percent) } ]
    end

    def memory_series
      [ { name: "Memory %", data: pairs_for(:mem_percent) } ]
    end

    def temperature_series
      [ { name: "Temperature (°C)", data: pairs_for(:cpu_temp_celsius) } ]
    end

    # => { "/" => [{ name: "Used %", data: [[time_label, pct], ...] }], ... }
    def disk_series_by_mount_point
      DiskUsage
        .joins(:stat_snapshot)
        .merge(snapshots_scope)
        .order("stat_snapshots.recorded_at")
        .pluck(:mount_point, "stat_snapshots.recorded_at", :use_percent)
        .group_by { |mount_point, _, _| mount_point }
        .transform_values do |rows|
          [ { name: "Used %", data: rows.map { |_, time, pct| [ label(time), pct ] } } ]
        end
    end

    # => { "eth0" => [{ name: "Download", data: [...] }, { name: "Upload", data: [...] }], ... }
    # Values are in KB/s (raw storage is bytes/sec) to keep the chart's
    # y-axis in a human-friendly range instead of the low thousands.
    def network_series_by_interface
      NetworkUsage
        .joins(:stat_snapshot)
        .merge(snapshots_scope)
        .order("stat_snapshots.recorded_at")
        .pluck(:interface, "stat_snapshots.recorded_at", :rx_bytes_per_sec, :tx_bytes_per_sec)
        .group_by { |iface, _, _, _| iface }
        .transform_values do |rows|
          [
            { name: "Download (↓)", data: rows.map { |_, time, rx, _| [ label(time), kb_per_sec(rx) ] } },
            { name: "Upload (↑)", data: rows.map { |_, time, _, tx| [ label(time), kb_per_sec(tx) ] } }
          ]
        end
    end

    private

    def pairs_for(column)
      snapshots_scope.pluck(:recorded_at, column).map { |t, v| [ label(t), v ] }
    end

    def kb_per_sec(bytes_per_sec)
      bytes_per_sec && bytes_per_sec / 1024.0
    end

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
