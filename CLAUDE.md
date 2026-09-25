# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A self-hosted Rails dashboard for monitoring a Raspberry Pi (or any Linux box):
current + historical CPU, memory, disk, network, and temperature stats, with
interactive charts, backed by SQLite. Single Puma process, no external
services (Solid Queue's supervisor runs embedded in Puma, no Redis/Sidekiq).
See `README.md` for the full feature list and deployment instructions.

## Commands

```sh
bundle install
bin/rails db:prepare        # create/migrate all 4 SQLite DBs (primary/cache/queue/cable)
bin/rails server             # dev server, port 3000
bundle exec rspec            # full test suite
bundle exec rspec spec/services/stats/cpu_reader_spec.rb   # single file
bundle exec rspec spec/services/stats/cpu_reader_spec.rb:42 # single example by line
bin/rubocop                  # lint (rubocop-rails-omakase house style)
bin/brakeman                 # static security scan
bin/bundler-audit            # gem vulnerability audit (config/bundler-audit.yml)
bin/importmap audit          # importmap/JS vulnerability audit
bin/ci                       # runs rubocop + the 3 security scans (config/ci.rb) — does NOT run rspec, run that separately
bin/setup_server             # interactive one-command production deploy (see README)
bin/uninstall_server         # reverses bin/setup_server (stop/disable/remove the systemd unit, offer to clean up DB/credentials)
```

Production deploy is systemd-based, not containerized — there is deliberately
no Docker/Kamal path, since this app reads the *host's* `/proc`, `/sys`, `df`,
and `ps` to report on the machine it's running on, which containers isolate
you from.

## Architecture

**Data flow:** a recurring Solid Queue job (`StatsPollJob`, scheduled in
`config/recurring.yml`, every 60s) calls `Stats::SnapshotCollector`, which
orchestrates the reader services in `app/services/stats/` (`CpuReader`,
`MemoryReader`, `DiskReader`, `NetworkReader`, `TemperatureReader`) and
persists one `StatSnapshot` row plus its `DiskUsage`/`NetworkUsage` children.
A second recurring job (`StatsPruneJob`) deletes snapshots older than 7 days.

**Why deltas, not a blocking sleep:** `/proc/stat` and `/proc/net/dev`
counters are cumulative since boot, so a single read can't yield a
percent/rate — it needs a diff between two reads over a known interval.
Rather than sleeping inside the job, every `StatSnapshot` stores its own raw
counters (`cpu_raw_total`, `cpu_raw_idle`, `rx_bytes_total`, `tx_bytes_total`),
so "the previous reading" is just the latest DB row — this survives process
restarts and avoids duplicated parse logic. Consequence: the first poll ever
has no prior row, so `cpu_percent` and network rate columns are `nil` for
exactly that one row (handled explicitly in `SnapshotCollector`, and
Chartkick/Chart.js render sparse/null points fine). A negative delta (counter
reset, interface replug, reboot between polls) also yields `nil` rather than
a garbage negative rate — see `SnapshotCollector#compute_cpu_percent` /
`#compute_network_rates`.

**Read path:** `Stats::DashboardQuery` (`app/queries/stats/`) is the *only*
place that reads `StatSnapshot`/`DiskUsage`/`NetworkUsage` back out for
display, kept separate from `DashboardController` specifically so a future
JSON API controller could reuse it without duplicating query logic. Its
`*_series` methods return data pre-shaped for Chartkick's multi-series format
(an array of `{ name:, data: }` hashes) — see the comment on
`Stats::DashboardQuery#cpu_series` for a detailed explanation of a subtle
Chartkick misdetection bug (`{ "CPU %" => pairs }`-style single-hash input
gets silently misread as one unnamed series) that this shape avoids. Charts
use `xtype: "string"` with manually formatted timestamp labels rather than
Chart.js's time axis, to avoid vendoring an extra date-adapter dependency.

`DashboardController#show` takes a `?range=1h|24h|7d` param
(`DashboardController::RANGES`) controlling the query's time window — this is
the only "explore history" interaction; there is no chart zoom/pan.

**Process readers vs. system readers:** `Stats::TopProcessesReader` (top 5 by
CPU/by memory, via `ps`) and `Stats::SystemInfoReader` (board model, OS,
kernel, hostname for the footer) are separate from the five pollable metric
readers above — they're read live on every request in the controller, not
polled/persisted to `StatSnapshot`.

**Temperature reading has a fallback chain:**
`/sys/class/thermal/thermal_zone0/temp` first, falling back to `vcgencmd
measure_temp` (Raspberry Pi OS specific) if the sysfs path is missing/zero —
this is what makes the app portable to non-Pi Linux hosts.

**Testing:** reader specs stub `/proc`, `df`, and `ps` output (fixtures live
inline in specs, not as separate fixture files) so they run identically on
any machine, independent of the host they happen to run on. Run the full
suite before committing changes to any reader, `SnapshotCollector`, or
`DashboardQuery` — the delta math (first-poll-ever and counter-reset edge
cases) is the most fragile part of this codebase.

**Deployment templating:** `deploy/pi-dashboard.service.example` is a
`{{PLACEHOLDER}}`-templated systemd unit, filled in and installed by
`bin/setup_server` (or by hand — see README). `bin/setup_server` locates the
correct `bundle` executable via rbenv's shim (`$RBENV_ROOT/shims/bundle`)
rather than `RbConfig::CONFIG["bindir"]` or a `PATH` scan — both of the latter
resolve to a specific Ruby version's raw `bin/` directory with no
gemset/version selection around it, which fails under systemd's minimal
environment (`bundler: command not found: puma`). See the comment above
`bundle_path` in that script before changing this logic.
