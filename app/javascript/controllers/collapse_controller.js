import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY_PREFIX = "pi-dashboard:section-open:"

// Persists a <details> chart section's open/closed state in localStorage
// (per-browser only, never sent to the server), keyed by the section's
// stable id (data-collapse-id-value) rather than its label text, so a
// future copy edit to the <summary> doesn't silently drop everyone's saved
// state. This survives reloads -- including the refresh controller's own
// periodic Turbo.visit reloads, which re-render every <details> from
// scratch and would otherwise reset each section back to its "open"
// default every time -- same rationale as the theme and full-width toggles.
export default class extends Controller {
  static values = { id: String }

  connect() {
    const stored = this.stored()
    if (stored !== null) {
      this.element.open = stored
    }
  }

  toggle() {
    try {
      localStorage.setItem(this.storageKey(), String(this.element.open))
    } catch {
      // private browsing / storage disabled -- toggle still works for this page view
    }
  }

  stored() {
    let value
    try {
      value = localStorage.getItem(this.storageKey())
    } catch {
      return null
    }
    if (value === "true") return true
    if (value === "false") return false
    return null
  }

  storageKey() {
    return `${STORAGE_KEY_PREFIX}${this.idValue}`
  }
}
