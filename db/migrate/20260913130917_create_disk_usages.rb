class CreateDiskUsages < ActiveRecord::Migration[8.1]
  def change
    create_table :disk_usages do |t|
      t.references :stat_snapshot, null: false, foreign_key: { on_delete: :cascade }
      t.string  :device,           null: false
      t.string  :mount_point,      null: false
      t.string  :fs_type,          null: false
      t.bigint  :total_bytes,      null: false
      t.bigint  :used_bytes,       null: false
      t.bigint  :available_bytes,  null: false
      t.float   :use_percent,      null: false

      t.timestamps
    end
    add_index :disk_usages, [ :stat_snapshot_id, :mount_point ]
  end
end
