require "net/http"

module Stats
  # Checks whether a handful of well-known sites are reachable, as a general
  # "does this box have working internet access" signal -- complementary to
  # WifiStatusReader, which only reports the local interface's own state (a
  # box can have a fully "up" Wi-Fi or Ethernet link and still have no route
  # to the internet, e.g. a misconfigured gateway or DNS).
  #
  # A HEAD request is used (not GET) to keep each check to a response-header
  # round-trip with no body. Any completed HTTP response -- even an error
  # status like 403 or 500 -- counts as reachable: that means DNS resolved
  # and a TCP+TLS connection to the site completed, which is what "is my
  # network okay" is actually asking, as distinct from "is their site
  # healthy". Only a hard failure (DNS, connection refused, TLS, timeout)
  # counts as unreachable.
  #
  # This class only performs the checks; it doesn't run them on a schedule
  # or cache the result itself -- see ConnectivityCheckJob and .cached/
  # .write_cache below for that, so a slow/unreachable site's timeout never
  # adds latency to a dashboard page load.
  class ConnectivityReader
    Result = Struct.new(:host, :reachable, :latency_ms, keyword_init: true)

    HOSTS = %w[google.com cloudflare.com arstechnica.com github.com].freeze
    OPEN_TIMEOUT = 2
    READ_TIMEOUT = 3

    CACHE_KEY = "stats/connectivity_status"
    CACHE_EXPIRY = 10.minutes

    def call
      HOSTS.map { |host| check(host) }
    end

    def self.cached
      Rails.cache.read(CACHE_KEY) || []
    end

    def self.write_cache(results)
      Rails.cache.write(CACHE_KEY, results, expires_in: CACHE_EXPIRY)
    end

    private

    def check(host)
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      Net::HTTP.start(host, 443, use_ssl: true, open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT) do |http|
        http.head("/")
      end
      elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round
      Result.new(host: host, reachable: true, latency_ms: elapsed_ms)
    rescue StandardError
      Result.new(host: host, reachable: false, latency_ms: nil)
    end
  end
end
