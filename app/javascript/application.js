// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Chart.js is vendored as its self-contained UMD build (see config/importmap.rb),
// which auto-registers all components and sets window.Chart itself -- just
// need to load it (for its side effect) before Chartkick, which auto-detects
// Chart.js via that global.
import "chart.js"
import "chartkick"
