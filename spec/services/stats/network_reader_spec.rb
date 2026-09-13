require "rails_helper"

RSpec.describe Stats::NetworkReader do
  it "parses per-interface rx/tx byte counters and excludes loopback" do
    net_dev_contents = <<~NETDEV
      Inter-|   Receive                                                |  Transmit
       face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
          lo:  123456     100    0    0    0     0          0         0   123456     100    0    0    0     0       0          0
        eth0: 5211883972 4000000    0    0    0     0          0     50000 1530620103 3000000    0    0    0     0       0          0
        wlan0:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
    NETDEV
    allow(File).to receive(:readlines).with(described_class::PROC_NET_DEV_PATH).and_return(net_dev_contents.lines)

    interfaces = described_class.new.call

    expect(interfaces.map(&:name)).to contain_exactly("eth0", "wlan0")

    eth0 = interfaces.find { |i| i.name == "eth0" }
    expect(eth0.rx_bytes).to eq(5_211_883_972)
    expect(eth0.tx_bytes).to eq(1_530_620_103)
  end
end
