# frozen_string_literal: true

class DataFeed < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validate :search_fields_attributes_valid
  serialize :search_fields, type: Hash, coder: JSON

  # Get the array of search_field key-value pairs
  def search_fields_attributes
    @search_fields_attributes ||= self.search_fields.map do |key, value|
      { key: key, value: value }
    end
  end

  # Set search fields from the array of key-value pairs submitted
  # by the data feed form
  def search_fields_attributes=(pairs)
    pairs_array = pairs.is_a?(Array) ? pairs : pairs.to_h.values

    @search_fields_attributes = pairs_array.map do |pair|
      {
        key: pair['key'].strip,
        value: pair['value'].strip
      }
    end

    self.search_fields = search_fields_for_db
  end

  def search_fields_for_db
    search_fields_attributes.each_with_object({}) do |pair, object|
      value = pair[:value].to_s.strip
      object[pair[:key].to_s.strip] = value
    end
  end

  def search_fields_attributes_valid
    search_fields_attributes.each do |row|
      errors.add(:search_fields, 'you must provide both a key and value.') if row[:key].blank? || row[:value].blank?
    end
  end
end
