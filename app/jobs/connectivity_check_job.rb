class ConnectivityCheckJob < ApplicationJob
  queue_as :default

  def perform
    Stats::ConnectivityReader.write_cache(Stats::ConnectivityReader.new.call)
  end
end
