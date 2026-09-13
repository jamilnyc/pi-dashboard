// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Chart.js is vendored as its modular ESM build, so components must be
// registered explicitly, and Chartkick auto-detects Chart.js via a
// `window.Chart` global -- it must be set before "chartkick" is imported.
import { Chart, registerables } from "chart.js"
Chart.register(...registerables)
window.Chart = Chart

import "chartkick"
