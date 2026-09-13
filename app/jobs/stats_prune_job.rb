class StatsPruneJob < ApplicationJob
  queue_as :default

  RETENTION = 7.days

  def perform
    # in_batches avoids one giant transaction/lock; dependent: :delete_all on
    # StatSnapshot's associations means each parent delete also bulk-deletes
    # its disk_usages/network_usages without instantiating them.
    StatSnapshot.where(recorded_at: ...RETENTION.ago).in_batches(of: 500).delete_all
  end
end
