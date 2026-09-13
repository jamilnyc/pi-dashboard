class CreateStatSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :stat_snapshots do |t|
      t.datetime :recorded_at,       null: false
      t.float    :interval_seconds                # seconds since previous snapshot; nil on the very first poll
      t.float    :cpu_percent                     # nil on the very first poll (no prior delta to compute from)
      t.bigint   :cpu_raw_total,     null: false   # cumulative jiffies (user+nice+system+idle+iowait+irq+softirq+steal)
      t.bigint   :cpu_raw_idle,      null: false   # cumulative jiffies (idle+iowait)
      t.float    :cpu_temp_celsius
      t.bigint   :mem_total_kb,      null: false
      t.bigint   :mem_available_kb,  null: false
      t.bigint   :mem_used_kb,       null: false
      t.float    :mem_percent,       null: false

      t.timestamps
    end
    add_index :stat_snapshots, :recorded_at
  end
end
