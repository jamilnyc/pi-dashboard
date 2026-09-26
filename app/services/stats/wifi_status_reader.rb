module Stats
  # Reports whether each Wi-Fi interface currently has a live connection.
  # Unlike NetworkReader's byte counters -- which still show up (frozen at
  # zero) for an interface that's administratively down or rfkill-blocked --
  # /sys/class/net/<iface>/operstate distinguishes "up" (associated to an
  # access point, carrier present) from everything else, so the dashboard
  # can tell "connected but idle" apart from "not connected at all".
  #
  # Wi-Fi interfaces are identified by systemd's predictable network
  # interface naming convention ("wl*" -- wlan0, wlp2s0, etc.), which covers
  # both classic and modern Linux naming schemes. Like NetworkReader,
  # interfaces are re-detected on every read rather than assumed fixed.
  class WifiStatusReader
    SYS_CLASS_NET_PATH = "/sys/class/net"

    def call
      interfaces.to_h { |name| [ name, connected?(name) ] }
    end

    private

    def interfaces
      Dir.children(SYS_CLASS_NET_PATH).select { |name| name.start_with?("wl") }
    rescue Errno::ENOENT
      []
    end

    def connected?(name)
      File.read(File.join(SYS_CLASS_NET_PATH, name, "operstate")).strip == "up"
    rescue Errno::ENOENT, Errno::EACCES
      false
    end
  end
end
