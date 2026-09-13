import { Controller } from "@hotwired/stimulus"

// Reloads the page on a fixed interval so the dashboard stays current
// without the user needing to manually refresh.
//
// This uses Turbo.visit rather than a <meta http-equiv="refresh"> tag
// because Turbo Drive intercepts the range-selector links as client-side
// visits that patch the DOM instead of performing a real browser
// navigation. A meta-refresh tag delivered that way is inserted via script,
// not parsed as part of an actual page load, so the browser's native
// refresh timer never gets (re-)armed -- auto-refresh would silently stop
// working the moment someone clicked a range link. A Stimulus controller's
// connect() callback, on the other hand, fires after every Turbo visit as
// well as every hard load, so the timer always restarts.
export default class extends Controller {
  static values = { interval: Number }

  connect() {
    this.timeout = setTimeout(() => {
      Turbo.visit(window.location.href, { action: "replace" })
    }, this.intervalValue * 1000)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
