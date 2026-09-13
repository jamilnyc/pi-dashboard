class StatsPollJob < ApplicationJob
  queue_as :default

  def perform
    Stats::SnapshotCollector.new.call
  end
end
