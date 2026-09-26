import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "pi-dashboard:theme"

// Lets the user override the light/dark theme the browser would otherwise
// pick via `prefers-color-scheme` (see the :root[data-theme] rules in
// application.css). The override is persisted in localStorage (per-browser
// only, never sent to the server) so it survives reloads -- including the
// refresh controller's own periodic Turbo.visit reloads, same as the
// full-width toggle above.
//
// With nothing stored yet, this defaults to whatever the OS/browser
// currently prefers, recomputed fresh on every connect -- so it still
// tracks a live OS change across the auto-refresh reloads, just not
// instantly within a single 60s window. A brief flash of the wrong theme is
// possible on first paint when an explicit override differs from the
// current OS setting, since the pre-JS HTML has no way to know it yet;
// same trade-off already accepted by the full-width toggle.
export default class extends Controller {
  static targets = ["button"]

  connect() {
    const stored = this.stored()
    this.apply(stored === null ? this.systemPrefersDark() : stored)
  }

  toggle() {
    const dark = !this.isDark()
    this.apply(dark)
    try {
      localStorage.setItem(STORAGE_KEY, dark ? "dark" : "light")
    } catch {
      // private browsing / storage disabled -- toggle still works for this page view
    }
  }

  stored() {
    let value
    try {
      value = localStorage.getItem(STORAGE_KEY)
    } catch {
      return null
    }
    if (value === "dark") return true
    if (value === "light") return false
    return null
  }

  systemPrefersDark() {
    return window.matchMedia("(prefers-color-scheme: dark)").matches
  }

  isDark() {
    return document.documentElement.dataset.theme === "dark"
  }

  apply(dark) {
    document.documentElement.dataset.theme = dark ? "dark" : "light"
    this.buttonTarget.setAttribute("aria-pressed", String(dark))
    this.buttonTarget.textContent = dark ? "Light mode" : "Dark mode"
  }
}
