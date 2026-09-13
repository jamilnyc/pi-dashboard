require "rails_helper"

RSpec.describe StatsPollJob do
  it "delegates to Stats::SnapshotCollector" do
    collector = instance_double(Stats::SnapshotCollector, call: nil)
    allow(Stats::SnapshotCollector).to receive(:new).and_return(collector)

    described_class.new.perform

    expect(collector).to have_received(:call)
  end
end
