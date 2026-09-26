require "rails_helper"

RSpec.describe Stats::TemperatureReader do
  it "reads and converts millidegrees from the sysfs thermal zone" do
    allow(File).to receive(:exist?).with(described_class::THERMAL_ZONE_PATH).and_return(true)
    allow(File).to receive(:read).with(described_class::THERMAL_ZONE_PATH).and_return("68850\n")

    expect(described_class.new.call).to eq(68.85)
  end

  it "falls back to vcgencmd when the thermal zone file is absent" do
    allow(File).to receive(:exist?).with(described_class::THERMAL_ZONE_PATH).and_return(false)
    allow(Open3).to receive(:capture2).with("vcgencmd", "measure_temp")
      .and_return([ "temp=69.4'C\n", instance_double(Process::Status, success?: true) ])

    expect(described_class.new.call).to eq(69.4)
  end

  it "falls back to vcgencmd when the thermal zone reads zero" do
    allow(File).to receive(:exist?).with(described_class::THERMAL_ZONE_PATH).and_return(true)
    allow(File).to receive(:read).with(described_class::THERMAL_ZONE_PATH).and_return("0\n")
    allow(Open3).to receive(:capture2).with("vcgencmd", "measure_temp")
      .and_return([ "temp=42.0'C\n", instance_double(Process::Status, success?: true) ])

    expect(described_class.new.call).to eq(42.0)
  end
end
