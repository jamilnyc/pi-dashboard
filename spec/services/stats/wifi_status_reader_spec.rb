require "rails_helper"

RSpec.describe Stats::WifiStatusReader do
  it "reports a wifi interface as connected when its operstate is up" do
    allow(Dir).to receive(:children).with(described_class::SYS_CLASS_NET_PATH).and_return(%w[lo eth0 wlan0])
    allow(File).to receive(:read).with("/sys/class/net/wlan0/operstate").and_return("up\n")

    expect(described_class.new.call).to eq("wlan0" => true)
  end

  it "reports a wifi interface as disconnected when its operstate is down" do
    allow(Dir).to receive(:children).with(described_class::SYS_CLASS_NET_PATH).and_return(%w[lo eth0 wlan0])
    allow(File).to receive(:read).with("/sys/class/net/wlan0/operstate").and_return("down\n")

    expect(described_class.new.call).to eq("wlan0" => false)
  end

  it "ignores interfaces that aren't Wi-Fi" do
    allow(Dir).to receive(:children).with(described_class::SYS_CLASS_NET_PATH).and_return(%w[lo eth0])

    expect(described_class.new.call).to eq({})
  end

  it "treats a missing operstate file as disconnected" do
    allow(Dir).to receive(:children).with(described_class::SYS_CLASS_NET_PATH).and_return(%w[wlan0])
    allow(File).to receive(:read).with("/sys/class/net/wlan0/operstate").and_raise(Errno::ENOENT)

    expect(described_class.new.call).to eq("wlan0" => false)
  end

  it "returns no interfaces when /sys/class/net can't be read" do
    allow(Dir).to receive(:children).with(described_class::SYS_CLASS_NET_PATH).and_raise(Errno::ENOENT)

    expect(described_class.new.call).to eq({})
  end
end
