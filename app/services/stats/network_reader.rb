module Stats
  # Parses /proc/net/dev for per-interface cumulative byte counters, skipping
  # the loopback interface. Interfaces are re-detected on every read rather
  # than assumed fixed, so plugging/unplugging Wi-Fi or Ethernet just works.
  class NetworkReader
    Interface = Struct.new(:name, :rx_bytes, :tx_bytes, keyword_init: true)

    PROC_NET_DEV_PATH = "/proc/net/dev"
    IGNORED_INTERFACES = %w[lo].freeze

    def call
      lines = File.readlines(PROC_NET_DEV_PATH)
      # First two lines are headers ("Inter-|   Receive ..." / "face |bytes packets ...")
      lines.drop(2).filter_map do |line|
        name, rest = line.split(":", 2)
        next if name.nil? || rest.nil?

        name = name.strip
        next if IGNORED_INTERFACES.include?(name)

        cols = rest.split
        # Receive block is 8 fields (bytes packets errs drop fifo frame compressed multicast),
        # then the Transmit block starts at index 8 with bytes first.
        Interface.new(name: name, rx_bytes: cols[0].to_i, tx_bytes: cols[8].to_i)
      end
    end
  end
end
