import { Controller } from "@hotwired/stimulus"

// Synchronizes a vertical crosshair line across every chart on the page
// when hovering any one of them, so it's easy to spot two metrics
// spiking at the same moment (e.g. CPU and network). All charts in a
// given time range share the same x-axis category positions (one per
// poll), so what gets broadcast to the rest is the hovered chart's
// data-point *index* -- not a timestamp -- since that's what every
// chart's category scale already keys off internally. The actual line
// is drawn by the syncedCrosshair Chart.js plugin (chart_crosshair.js);
// this controller only tracks the hovered index and tells every chart to
// redraw with it.
export default class extends Controller {
  connect() {
    this.pendingEvent = null
    this.frame = null
    this.onMove = this.onMove.bind(this)
    this.onLeave = this.onLeave.bind(this)
    this.element.addEventListener("mousemove", this.onMove)
    this.element.addEventListener("mouseleave", this.onLeave)
  }

  disconnect() {
    this.element.removeEventListener("mousemove", this.onMove)
    this.element.removeEventListener("mouseleave", this.onLeave)
    if (this.frame) cancelAnimationFrame(this.frame)
  }

  onMove(event) {
    // Coalesce into at most one redraw pass per animation frame, since
    // mousemove can fire far more often than the screen repaints and we
    // redraw every chart on the page each time.
    this.pendingEvent = event
    if (this.frame) return

    this.frame = requestAnimationFrame(() => {
      this.frame = null
      this.handleMove(this.pendingEvent)
    })
  }

  onLeave() {
    if (this.frame) {
      cancelAnimationFrame(this.frame)
      this.frame = null
    }
    this.broadcast(null)
  }

  handleMove(event) {
    const canvas = event.target.closest("canvas")
    if (!canvas) return

    const wrapper = canvas.closest("[id^='chart-']")
    const chart = this.chartObjectFor(wrapper?.id)
    if (!chart) return

    const elements = chart.getElementsAtEventForMode(event, "index", { intersect: false }, false)
    if (!elements.length) return

    this.broadcast(elements[0].index)
  }

  chartObjectFor(elementId) {
    if (!elementId || !window.Chartkick) return null

    const chartkickChart = Chartkick.charts[elementId]
    return chartkickChart?.getChartObject ? chartkickChart.getChartObject() : null
  }

  broadcast(index) {
    if (!window.Chartkick) return

    Chartkick.eachChart((chartkickChart) => {
      const chart = chartkickChart.getChartObject ? chartkickChart.getChartObject() : null
      if (!chart || chart.$crosshairIndex === index) return

      chart.$crosshairIndex = index
      chart.draw()
    })
  }
}
