# frozen_string_literal: true

class DataFeed < ApplicationRecord
  validates :key, uniqueness: true
  serialize :search_fields, type: Hash, coder: JSON

  # Get the array of search_field key-value pairs
  def search_fields_attributes
    self.search_fields.map do |key, value|
      { key: key, value: value }
    end
  end

  # Set search fields from the array of key-value pairs submitted
  # by the data feed form
  def search_fields_attributes=(pairs)
    pairs_array = pairs.is_a? Array ? paris : pairs.to_h.values
    self.search_fields = pairs_array.each_with_object({}) do |pair, object|
      # TODO: skip empty rows, sanitize input (whitespaces)
      object[pair['key']] = pair['value']
    end
  end
end
