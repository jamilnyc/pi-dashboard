require "rails_helper"

RSpec.describe Stats::TopProcessesReader do
  it "sorts by memory (rss) by default and parses cpu/mem/pid/command" do
    ps_output = <<~PS
       173318 claude          485424   6.9  5.8
       237691 chromium        293664   4.8  3.5
       172898 MainThread      258576   0.3  3.1
       237861 chromium        242528   2.0  2.9
       237775 chromium        241072   0.1  2.9
    PS
    allow(Open3).to receive(:capture2)
      .with("ps", "-eo", "pid,comm,rss,pcpu,pmem", "--sort=-rss", "--no-headers")
      .and_return([ ps_output, instance_double(Process::Status, success?: true) ])

    result = described_class.new.call

    expect(result.length).to eq(5)
    expect(result.first).to have_attributes(pid: 173318, command: "claude", rss_kb: 485424, cpu_percent: 6.9, mem_percent: 5.8)
  end

  it "sorts by cpu when requested" do
    ps_output = "173318 claude 485424 6.9 5.8\n237691 chromium 293664 4.8 3.5\n"
    allow(Open3).to receive(:capture2)
      .with("ps", "-eo", "pid,comm,rss,pcpu,pmem", "--sort=-pcpu", "--no-headers")
      .and_return([ ps_output, instance_double(Process::Status, success?: true) ])

    result = described_class.new.call(sort_by: :cpu)

    expect(result.first).to have_attributes(pid: 173318, cpu_percent: 6.9)
  end

  it "respects a custom limit" do
    ps_output = "1 a 100 1.0 1.0\n2 b 90 0.9 0.9\n3 c 80 0.8 0.8\n"
    allow(Open3).to receive(:capture2)
      .with("ps", "-eo", "pid,comm,rss,pcpu,pmem", "--sort=-rss", "--no-headers")
      .and_return([ ps_output, instance_double(Process::Status, success?: true) ])

    expect(described_class.new.call(limit: 2).length).to eq(2)
  end

  it "returns an empty array when ps fails" do
    allow(Open3).to receive(:capture2)
      .with("ps", "-eo", "pid,comm,rss,pcpu,pmem", "--sort=-rss", "--no-headers")
      .and_return([ "", instance_double(Process::Status, success?: false) ])

    expect(described_class.new.call).to eq([])
  end
end
