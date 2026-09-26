require "rails_helper"

RSpec.describe Stats::ConnectivityReader do
  describe "#call" do
    it "reports every configured host as reachable when the HTTP request succeeds" do
      allow(Net::HTTP).to receive(:start).and_yield(instance_double(Net::HTTP, head: instance_double(Net::HTTPResponse)))

      results = described_class.new.call

      expect(results.map(&:host)).to eq(described_class::HOSTS)
      expect(results).to all(have_attributes(reachable: true))
      results.each { |result| expect(result.latency_ms).to be_a(Integer) }
    end

    it "reports a host as unreachable when the connection fails" do
      allow(Net::HTTP).to receive(:start).and_raise(SocketError, "getaddrinfo: Name or service not known")

      results = described_class.new.call

      expect(results).to all(have_attributes(reachable: false, latency_ms: nil))
    end

    it "reports a host as unreachable on timeout" do
      allow(Net::HTTP).to receive(:start).and_raise(Net::OpenTimeout)

      results = described_class.new.call

      expect(results).to all(have_attributes(reachable: false, latency_ms: nil))
    end

    it "treats an HTTP error status as reachable, since the network path itself worked" do
      allow(Net::HTTP).to receive(:start).and_yield(instance_double(Net::HTTP, head: instance_double(Net::HTTPResponse)))

      results = described_class.new.call

      expect(results).to all(have_attributes(reachable: true))
    end
  end

  describe ".cached" do
    it "returns the cached results" do
      results = [ described_class::Result.new(host: "google.com", reachable: true, latency_ms: 40) ]
      allow(Rails.cache).to receive(:read).with(described_class::CACHE_KEY).and_return(results)

      expect(described_class.cached).to eq(results)
    end

    it "returns an empty array when nothing has been cached yet" do
      allow(Rails.cache).to receive(:read).with(described_class::CACHE_KEY).and_return(nil)

      expect(described_class.cached).to eq([])
    end
  end

  describe ".write_cache" do
    it "writes the results to the cache with an expiry" do
      results = [ described_class::Result.new(host: "google.com", reachable: true, latency_ms: 40) ]

      expect(Rails.cache).to receive(:write).with(described_class::CACHE_KEY, results, expires_in: described_class::CACHE_EXPIRY)

      described_class.write_cache(results)
    end
  end
end
