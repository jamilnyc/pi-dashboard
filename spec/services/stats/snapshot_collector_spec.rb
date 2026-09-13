require "rails_helper"

RSpec.describe Stats::SnapshotCollector do
  let(:cpu_reader) { instance_double(Stats::CpuReader) }
  let(:memory_reader) { instance_double(Stats::MemoryReader) }
  let(:disk_reader) { instance_double(Stats::DiskReader) }
  let(:network_reader) { instance_double(Stats::NetworkReader) }
  let(:temperature_reader) { instance_double(Stats::TemperatureReader) }

  subject(:collector) do
    described_class.new(
      cpu_reader: cpu_reader,
      memory_reader: memory_reader,
      disk_reader: disk_reader,
      network_reader: network_reader,
      temperature_reader: temperature_reader
    )
  end

  def stub_readers(cpu_total:, cpu_idle:, rx_bytes:, tx_bytes:)
    allow(cpu_reader).to receive(:call).and_return(Stats::CpuReader::Result.new(total: cpu_total, idle: cpu_idle))
    allow(memory_reader).to receive(:call).and_return(Stats::MemoryReader::Result.new(total_kb: 8_000_000, available_kb: 6_000_000))
    allow(temperature_reader).to receive(:call).and_return(55.0)
    allow(disk_reader).to receive(:call).and_return([
      Stats::DiskReader::Disk.new(device: "/dev/sda1", fs_type: "ext4", mount_point: "/", total_bytes: 1000, used_bytes: 100, available_bytes: 900)
    ])
    allow(network_reader).to receive(:call).and_return([
      Stats::NetworkReader::Interface.new(name: "eth0", rx_bytes: rx_bytes, tx_bytes: tx_bytes)
    ])
  end

  it "on the very first poll ever, stores raw counters but leaves rate fields nil" do
    stub_readers(cpu_total: 6565, cpu_idle: 5050, rx_bytes: 1000, tx_bytes: 2000)

    snapshot = collector.call

    expect(snapshot.interval_seconds).to be_nil
    expect(snapshot.cpu_percent).to be_nil
    expect(snapshot.cpu_raw_total).to eq(6565)
    expect(snapshot.cpu_raw_idle).to eq(5050)
    expect(snapshot.network_usages.first.rx_bytes_per_sec).to be_nil
    expect(snapshot.network_usages.first.tx_bytes_per_sec).to be_nil
    expect(snapshot.network_usages.first.rx_bytes_total).to eq(1000)
  end

  it "computes cpu% and network rates from the delta against the previous snapshot" do
    stub_readers(cpu_total: 6565, cpu_idle: 5050, rx_bytes: 1000, tx_bytes: 2000)
    first = collector.call
    first.update!(recorded_at: 60.seconds.ago)

    stub_readers(cpu_total: 7028, cpu_idle: 5360, rx_bytes: 61_000, tx_bytes: 122_000)
    second = collector.call

    # total_delta = 463, idle_delta = 310, busy = 153 -> 153/463*100 = 33.0
    expect(second.cpu_percent).to eq(33.0)
    expect(second.interval_seconds).to be_within(1).of(60)

    net = second.network_usages.first
    # rx_delta = 60_000 over ~60s => ~1000 bytes/sec
    expect(net.rx_bytes_per_sec).to be_within(50).of(1000)
    expect(net.tx_bytes_per_sec).to be_within(100).of(2000)
  end

  it "returns nil rates when a counter goes backwards (reset or replugged interface)" do
    stub_readers(cpu_total: 6565, cpu_idle: 5050, rx_bytes: 50_000, tx_bytes: 90_000)
    first = collector.call
    first.update!(recorded_at: 60.seconds.ago)

    # rx counter dropped below its previous value (e.g. interface replugged)
    stub_readers(cpu_total: 7028, cpu_idle: 5360, rx_bytes: 100, tx_bytes: 91_000)
    second = collector.call

    net = second.network_usages.first
    expect(net.rx_bytes_per_sec).to be_nil
    expect(net.tx_bytes_per_sec).to be_nil
  end

  it "persists one disk_usage and network_usage row per reported disk/interface" do
    stub_readers(cpu_total: 6565, cpu_idle: 5050, rx_bytes: 1000, tx_bytes: 2000)

    snapshot = collector.call

    expect(snapshot.disk_usages.count).to eq(1)
    expect(snapshot.disk_usages.first.use_percent).to eq(10.0)
    expect(snapshot.network_usages.count).to eq(1)
  end
end
