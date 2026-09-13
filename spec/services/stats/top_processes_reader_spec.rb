require "rails_helper"

RSpec.describe Stats::TopProcessesReader do
  it "parses and returns the top processes by memory usage" do
    ps_output = <<~PS
       173318 claude          485424  5.8
       237691 chromium        293664  3.5
       172898 MainThread      258576  3.1
       237861 chromium        242528  2.9
       237775 chromium        241072  2.9
       173057 MainThread      195824  2.3
    PS
    allow(Open3).to receive(:capture2)
      .with("ps", "-eo", "pid,comm,rss,pmem", "--sort=-rss", "--no-headers")
      .and_return([ps_output, instance_double(Process::Status, success?: true)])

    result = described_class.new.call

    expect(result.length).to eq(5)
    expect(result.first).to have_attributes(pid: 173318, command: "claude", rss_kb: 485424, percent: 5.8)
    expect(result.last).to have_attributes(pid: 237775, command: "chromium", rss_kb: 241072, percent: 2.9)
  end

  it "respects a custom limit" do
    ps_output = "1 a 100 1.0\n2 b 90 0.9\n3 c 80 0.8\n"
    allow(Open3).to receive(:capture2)
      .with("ps", "-eo", "pid,comm,rss,pmem", "--sort=-rss", "--no-headers")
      .and_return([ps_output, instance_double(Process::Status, success?: true)])

    expect(described_class.new.call(limit: 2).length).to eq(2)
  end

  it "returns an empty array when ps fails" do
    allow(Open3).to receive(:capture2)
      .with("ps", "-eo", "pid,comm,rss,pmem", "--sort=-rss", "--no-headers")
      .and_return(["", instance_double(Process::Status, success?: false)])

    expect(described_class.new.call).to eq([])
  end
end
