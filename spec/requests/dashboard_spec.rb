require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  it "renders successfully with no data yet" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("No stats have been collected yet")
  end

  it "renders the tiles and charts once a snapshot exists" do
    Stats::SnapshotCollector.new(
      cpu_reader: instance_double(Stats::CpuReader, call: Stats::CpuReader::Result.new(total: 100, idle: 90)),
      memory_reader: instance_double(Stats::MemoryReader, call: Stats::MemoryReader::Result.new(total_kb: 1000, available_kb: 500)),
      disk_reader: instance_double(Stats::DiskReader, call: []),
      network_reader: instance_double(Stats::NetworkReader, call: []),
      temperature_reader: instance_double(Stats::TemperatureReader, call: 50.0)
    ).call

    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Raspberry Pi Dashboard")
    expect(response.body).to include("CPU usage")
  end

  it "accepts a range parameter" do
    get root_path(range: "1h")

    expect(response).to have_http_status(:ok)
  end
end
