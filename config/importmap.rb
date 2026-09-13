# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
# Vendored by hand from the UMD build (dist/chart.umd.js), not `bin/importmap
# pin chart.js`: Chart.js's ESM entry point (dist/chart.js) splits into
# sibling chunk files via relative imports (e.g. "./chunks/helpers.dataset.js"),
# which 404 once fingerprinted and served from a single flat vendor path. The
# UMD build is a single self-contained file with no external imports, and it
# auto-registers everything and sets window.Chart itself.
pin "chart.js" # @4.5.1 (UMD build)
pin "chartkick" # @5.0.1
