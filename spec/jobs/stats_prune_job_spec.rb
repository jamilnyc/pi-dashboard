require "rails_helper"

RSpec.describe StatsPruneJob do
  def create_snapshot(recorded_at:)
    snapshot = StatSnapshot.create!(
      recorded_at: recorded_at,
      cpu_raw_total: 1, cpu_raw_idle: 1,
      mem_total_kb: 1000, mem_available_kb: 500, mem_used_kb: 500, mem_percent: 50.0
    )
    snapshot.disk_usages.create!(device: "/dev/sda1", fs_type: "ext4", mount_point: "/", total_bytes: 100, used_bytes: 10, available_bytes: 90, use_percent: 10.0)
    snapshot.network_usages.create!(interface: "eth0", rx_bytes_total: 100, tx_bytes_total: 100)
    snapshot
  end

  it "deletes snapshots (and their children) older than the retention window, keeping newer ones" do
    old_snapshot = create_snapshot(recorded_at: 8.days.ago)
    recent_snapshot = create_snapshot(recorded_at: 1.day.ago)

    described_class.new.perform

    expect(StatSnapshot.exists?(old_snapshot.id)).to be false
    expect(DiskUsage.where(stat_snapshot_id: old_snapshot.id)).to be_empty
    expect(NetworkUsage.where(stat_snapshot_id: old_snapshot.id)).to be_empty

    expect(StatSnapshot.exists?(recent_snapshot.id)).to be true
  end
end
