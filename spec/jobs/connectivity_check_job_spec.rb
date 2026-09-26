require "rails_helper"

RSpec.describe ConnectivityCheckJob do
  it "checks connectivity and caches the results" do
    results = [ Stats::ConnectivityReader::Result.new(host: "google.com", reachable: true, latency_ms: 40) ]
    reader = instance_double(Stats::ConnectivityReader, call: results)
    allow(Stats::ConnectivityReader).to receive(:new).and_return(reader)
    allow(Stats::ConnectivityReader).to receive(:write_cache)

    described_class.new.perform

    expect(reader).to have_received(:call)
    expect(Stats::ConnectivityReader).to have_received(:write_cache).with(results)
  end
end
