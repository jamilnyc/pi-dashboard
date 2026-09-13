require "rails_helper"

RSpec.describe Stats::DashboardQuery do
  def create_snapshot(recorded_at:, cpu_percent:, mem_percent: 50.0, cpu_temp_celsius: 50.0)
    snapshot = StatSnapshot.create!(
      recorded_at: recorded_at,
      cpu_raw_total: 1, cpu_raw_idle: 1, cpu_percent: cpu_percent, cpu_temp_celsius: cpu_temp_celsius,
      mem_total_kb: 1000, mem_available_kb: 500, mem_used_kb: 500, mem_percent: mem_percent
    )
    snapshot.disk_usages.create!(device: "/dev/sda1", fs_type: "ext4", mount_point: "/", total_bytes: 100, used_bytes: 10, available_bytes: 90, use_percent: 10.0)
    snapshot.network_usages.create!(interface: "eth0", rx_bytes_total: 100, tx_bytes_total: 100, rx_bytes_per_sec: 5.0, tx_bytes_per_sec: 2.0)
    snapshot
  end

  # Chartkick silently misinterprets a Hash like { "CPU %" => pairs } -- it
  # looks reasonable but isn't a format it recognizes, and gets flattened
  # into a single bogus data point (see the comment in dashboard_query.rb).
  # These specs pin the *_series methods to the format it actually expects:
  # an Array of { name:, data: } Hashes, ready to pass straight to
  # line_chart, with every real data point intact.
  describe "#cpu_series" do
    it "returns an array of one named series with every point, ready for line_chart" do
      create_snapshot(recorded_at: 2.minutes.ago, cpu_percent: 1.5)
      create_snapshot(recorded_at: 1.minute.ago, cpu_percent: 2.5)

      series = described_class.new(since: 1.hour.ago).cpu_series

      expect(series).to be_an(Array)
      expect(series.length).to eq(1)
      expect(series.first[:name]).to eq("CPU %")
      expect(series.first[:data].length).to eq(2)
      expect(series.first[:data].map(&:last)).to eq([1.5, 2.5])
    end
  end

  describe "#memory_series" do
    it "returns an array of one named series" do
      create_snapshot(recorded_at: 1.minute.ago, cpu_percent: 1.0, mem_percent: 42.0)

      series = described_class.new(since: 1.hour.ago).memory_series

      expect(series).to eq([{ name: "Memory %", data: series.first[:data] }])
      expect(series.first[:data].map(&:last)).to eq([42.0])
    end
  end

  describe "#disk_series_by_mount_point" do
    it "returns each mount point already mapped to a chart-ready series array" do
      create_snapshot(recorded_at: 1.minute.ago, cpu_percent: 1.0)

      result = described_class.new(since: 1.hour.ago).disk_series_by_mount_point

      expect(result.keys).to eq([ "/" ])
      expect(result["/"]).to be_an(Array)
      expect(result["/"].first[:name]).to eq("Used %")
      expect(result["/"].first[:data].map(&:last)).to eq([ 10.0 ])
    end
  end

  describe "#network_series_by_interface" do
    it "returns each interface already mapped to a two-series (rx/tx) chart-ready array" do
      create_snapshot(recorded_at: 1.minute.ago, cpu_percent: 1.0)

      result = described_class.new(since: 1.hour.ago).network_series_by_interface

      expect(result.keys).to eq([ "eth0" ])
      names = result["eth0"].map { |s| s[:name] }
      expect(names).to eq([ "Download (↓)", "Upload (↑)" ])
      expect(result["eth0"][0][:data].map(&:last)).to eq([ 5.0 ])
      expect(result["eth0"][1][:data].map(&:last)).to eq([ 2.0 ])
    end
  end
end
