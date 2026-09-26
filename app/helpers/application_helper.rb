module ApplicationHelper
  # Geometry for the semicircle tile gauges (see dashboard/_gauge.html.erb).
  # The dial is a fixed 120x68 viewBox; every angle below is derived from a
  # 0.0..1.0 "fraction" of the gauge's min..max range so the same math draws
  # the colored zone arcs (each a slice between two fractions) and points the
  # needle (a single fraction) with no per-metric special-casing.
  GAUGE_CENTER = 60
  GAUGE_RADIUS = 46

  def gauge_fraction(value, min, max)
    return nil if value.nil?

    ((value - min) / (max - min).to_f).clamp(0.0, 1.0)
  end

  def gauge_arc_path(from_fraction, to_fraction)
    x0, y0 = gauge_point(from_fraction)
    x1, y1 = gauge_point(to_fraction)
    "M#{x0} #{y0} A#{GAUGE_RADIUS} #{GAUGE_RADIUS} 0 0 1 #{x1} #{y1}"
  end

  # -90 (needle pointing left, fraction 0) to +90 (pointing right, fraction
  # 1), passing through 0 (straight up) at fraction 0.5.
  def gauge_needle_rotation(fraction)
    (fraction * 180) - 90
  end

  # wifi_status is the Hash from Stats::WifiStatusReader (interface name =>
  # connected boolean). An interface absent from it isn't Wi-Fi at all
  # (e.g. eth0), so it's never considered "disconnected" by this check.
  def wifi_disconnected?(interface, wifi_status)
    wifi_status.key?(interface) && !wifi_status.fetch(interface)
  end

  private

  # fraction 0 -> leftmost point of the arc, 0.5 -> topmost, 1 -> rightmost --
  # i.e. swept clockwise over the top, the same direction the needle points.
  def gauge_point(fraction)
    theta = (180 - (fraction * 180)) * Math::PI / 180
    x = GAUGE_CENTER + (GAUGE_RADIUS * Math.cos(theta))
    y = GAUGE_CENTER - (GAUGE_RADIUS * Math.sin(theta))
    [ x.round(2), y.round(2) ]
  end
end
