require "rails_helper"

RSpec.describe Stats::DiskReader do
  it "parses df output into disk usage structs" do
    df_output = <<~DF
      source           fstype        1B-blocks       used       avail target
      /dev/mmcblk0p2   ext4        125242245120 9780723712 109078794240 /
      /dev/mmcblk0p1   vfat           534763520   82335744    452427776 /boot/firmware
    DF
    allow(Open3).to receive(:capture2).and_return([ df_output, instance_double(Process::Status, success?: true) ])

    disks = described_class.new.call

    expect(disks.size).to eq(2)
    root = disks.find { |d| d.mount_point == "/" }
    expect(root.device).to eq("/dev/mmcblk0p2")
    expect(root.fs_type).to eq("ext4")
    expect(root.total_bytes).to eq(125_242_245_120)
    expect(root.used_bytes).to eq(9_780_723_712)
    expect(root.available_bytes).to eq(109_078_794_240)
  end

  it "excludes pseudo filesystem types via df's -x flag" do
    described_class.new

    expect(Stats::DiskReader::EXCLUDED_FS_TYPES).to include("tmpfs", "devtmpfs", "squashfs", "overlay")
  end

  it "returns an empty array when df fails" do
    allow(Open3).to receive(:capture2).and_return([ "", instance_double(Process::Status, success?: false) ])

    expect(described_class.new.call).to eq([])
  end
end
