# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_13_130918) do
  create_table "disk_usages", force: :cascade do |t|
    t.bigint "available_bytes", null: false
    t.datetime "created_at", null: false
    t.string "device", null: false
    t.string "fs_type", null: false
    t.string "mount_point", null: false
    t.integer "stat_snapshot_id", null: false
    t.bigint "total_bytes", null: false
    t.datetime "updated_at", null: false
    t.float "use_percent", null: false
    t.bigint "used_bytes", null: false
    t.index ["stat_snapshot_id", "mount_point"], name: "index_disk_usages_on_stat_snapshot_id_and_mount_point"
    t.index ["stat_snapshot_id"], name: "index_disk_usages_on_stat_snapshot_id"
  end

  create_table "network_usages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "interface", null: false
    t.float "rx_bytes_per_sec"
    t.bigint "rx_bytes_total", null: false
    t.integer "stat_snapshot_id", null: false
    t.float "tx_bytes_per_sec"
    t.bigint "tx_bytes_total", null: false
    t.datetime "updated_at", null: false
    t.index ["stat_snapshot_id", "interface"], name: "index_network_usages_on_stat_snapshot_id_and_interface"
    t.index ["stat_snapshot_id"], name: "index_network_usages_on_stat_snapshot_id"
  end

  create_table "stat_snapshots", force: :cascade do |t|
    t.float "cpu_percent"
    t.bigint "cpu_raw_idle", null: false
    t.bigint "cpu_raw_total", null: false
    t.float "cpu_temp_celsius"
    t.datetime "created_at", null: false
    t.float "interval_seconds"
    t.bigint "mem_available_kb", null: false
    t.float "mem_percent", null: false
    t.bigint "mem_total_kb", null: false
    t.bigint "mem_used_kb", null: false
    t.datetime "recorded_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recorded_at"], name: "index_stat_snapshots_on_recorded_at"
  end

  add_foreign_key "disk_usages", "stat_snapshots", on_delete: :cascade
  add_foreign_key "network_usages", "stat_snapshots", on_delete: :cascade
end
