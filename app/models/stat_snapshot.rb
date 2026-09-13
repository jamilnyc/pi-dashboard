class StatSnapshot < ApplicationRecord
  has_many :disk_usages, dependent: :delete_all
  has_many :network_usages, dependent: :delete_all
end
