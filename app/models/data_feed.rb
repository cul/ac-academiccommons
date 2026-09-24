# frozen_string_literal: true

class DataFeed < ApplicationRecord
  validates :key, uniqueness: true
  serialize :search_fields, type: Hash, coder: JSON
end
