import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "pi-dashboard:full-width"

// Lets the user expand the charts to the full width of the browser window
// instead of the page's default centered, max-width layout. Persisted in
// localStorage (per-browser only, never sent to the server) so the choice
// survives reloads -- including the refresh controller's own periodic
// Turbo.visit reloads, which re-render this element from scratch every
// time and would otherwise silently reset it back to the default width.
export default class extends Controller {
  static targets = ["button"]

  connect() {
    this.apply(this.stored())
  }

  toggle() {
    this.apply(!this.stored())
  }

  stored() {
    try {
      return localStorage.getItem(STORAGE_KEY) === "true"
    } catch {
      return false
    }
  }

  apply(fullWidth) {
    this.element.classList.toggle("full-width", fullWidth)
    this.buttonTarget.setAttribute("aria-pressed", String(fullWidth))
    this.buttonTarget.textContent = fullWidth ? "Default width" : "Full width"
    try {
      localStorage.setItem(STORAGE_KEY, String(fullWidth))
    } catch {
      // private browsing / storage disabled -- toggle still works for this page view
    }
  }
}
