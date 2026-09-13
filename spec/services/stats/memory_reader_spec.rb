require "rails_helper"

RSpec.describe Stats::MemoryReader do
  it "parses MemTotal and MemAvailable from /proc/meminfo" do
    meminfo_contents = <<~MEMINFO
      MemTotal:        8256528 kB
      MemFree:         2000000 kB
      MemAvailable:    6308752 kB
      Buffers:          100000 kB
      Cached:          3000000 kB
    MEMINFO
    allow(File).to receive(:foreach).with(described_class::PROC_MEMINFO_PATH).and_yield(meminfo_contents.lines[0])
      .and_yield(meminfo_contents.lines[1]).and_yield(meminfo_contents.lines[2])
      .and_yield(meminfo_contents.lines[3]).and_yield(meminfo_contents.lines[4])

    result = described_class.new.call

    expect(result.total_kb).to eq(8256528)
    expect(result.available_kb).to eq(6308752)
  end

  it "falls back to MemFree + Buffers + Cached when MemAvailable is missing" do
    meminfo_contents = <<~MEMINFO
      MemTotal:        8256528 kB
      MemFree:         2000000 kB
      Buffers:          100000 kB
      Cached:          3000000 kB
    MEMINFO
    lines = meminfo_contents.lines
    allow(File).to receive(:foreach).with(described_class::PROC_MEMINFO_PATH)
      .and_yield(lines[0]).and_yield(lines[1]).and_yield(lines[2]).and_yield(lines[3])

    result = described_class.new.call

    expect(result.available_kb).to eq(2_000_000 + 100_000 + 3_000_000)
  end
end
