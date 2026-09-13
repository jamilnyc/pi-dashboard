// Registers a Chart.js plugin that draws a vertical line on a chart when
// asked to, via a chart.$crosshairIndex property this file manages itself
// (Chart.js has no built-in concept of a cross-chart crosshair). The
// crosshair Stimulus controller drives it: on hover it looks up the
// hovered data-point index and sets $crosshairIndex on every chart on the
// page, so a spike lining up across two unrelated-looking metrics (e.g.
// CPU and network) becomes visible at a glance.
//
// Registered globally at module load (once Chart.js's UMD build has set
// window.Chart -- see application.js's import order), so it applies to
// every chart Chartkick creates afterwards, including ones (re)created by
// the auto-refresh controller's periodic Turbo visits.
function drawCrosshair(chart) {
  const index = chart.$crosshairIndex
  if (index == null) return

  const xScale = chart.scales?.x
  if (!xScale) return

  // getPixelForTick(i) indexes into the scale's *currently rendered* tick
  // array -- i.e. AFTER autoSkip has thinned it down to maxTicksLimit (8,
  // see time_axis in the view), not the full per-poll data array. Passing
  // our raw data-point index into it looks plausible for small indices but
  // is really "the pixel for the i-th SURVIVING tick", which for index 7
  // might already be data point ~49 -- exactly why the line raced ahead of
  // the mouse and went off-screen a handful of points in. getPixelForValue
  // treats a numeric argument as a raw category value (our actual data
  // index) against the scale's full range, unaffected by which ticks
  // autoSkip chose to label.
  const x = xScale.getPixelForValue(index)
  if (x == null || Number.isNaN(x)) return

  const { top, bottom } = chart.chartArea
  const ctx = chart.ctx

  ctx.save()
  ctx.beginPath()
  ctx.moveTo(x, top)
  ctx.lineTo(x, bottom)
  ctx.lineWidth = 1
  ctx.setLineDash([4, 4])
  ctx.strokeStyle = "rgba(128, 128, 128, 0.85)"
  ctx.stroke()
  ctx.restore()
}

if (window.Chart) {
  window.Chart.register({ id: "syncedCrosshair", afterDraw: drawCrosshair })
}
