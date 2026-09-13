class DashboardController < ApplicationController
  RANGES = { "1h" => 1.hour, "24h" => 24.hours, "7d" => 7.days }.freeze
  DEFAULT_RANGE = "24h"

  def show
    @range_key = RANGES.key?(params[:range]) ? params[:range] : DEFAULT_RANGE
    @query = Stats::DashboardQuery.new(since: RANGES.fetch(@range_key).ago)
    @system_info = Stats::SystemInfoReader.new.call
    @top_cpu_processes = Stats::TopProcessesReader.new.call(sort_by: :cpu)
    @top_memory_processes = Stats::TopProcessesReader.new.call(sort_by: :memory)
  end
end
