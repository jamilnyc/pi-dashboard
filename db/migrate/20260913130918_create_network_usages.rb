class CreateNetworkUsages < ActiveRecord::Migration[8.1]
  def change
    create_table :network_usages do |t|
      t.references :stat_snapshot, null: false, foreign_key: { on_delete: :cascade }
      t.string  :interface,        null: false
      t.bigint  :rx_bytes_total,   null: false   # raw cumulative kernel counter at poll time
      t.bigint  :tx_bytes_total,   null: false
      t.float   :rx_bytes_per_sec                 # nil if there was no prior sample for this interface
      t.float   :tx_bytes_per_sec

      t.timestamps
    end
    add_index :network_usages, [ :stat_snapshot_id, :interface ]
  end
end
