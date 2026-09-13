require "rails_helper"

RSpec.describe Stats::CpuReader do
  it "parses cumulative jiffies from the aggregate cpu line, excluding guest time from the total" do
    stat_contents = <<~STAT
      cpu  1000 200 300 5000 50 10 5 0 7 3
      cpu0 500 100 150 2500 25 5 2 0 0 0
      intr 12345 0 0 0
    STAT
    allow(File).to receive(:readlines).with(described_class::PROC_STAT_PATH).and_return(stat_contents.lines)

    result = described_class.new.call

    # idle_all = idle(5000) + iowait(50) = 5050
    # total = user(1000) + nice(200) + system(300) + idle_all(5050) + irq(10) + softirq(5) + steal(0)
    expect(result.idle).to eq(5050)
    expect(result.total).to eq(6565)
  end
end
