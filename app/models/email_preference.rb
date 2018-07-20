class EmailPreference < ApplicationRecord
  validates :author, presence: true
end
