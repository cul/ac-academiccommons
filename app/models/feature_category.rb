# frozen_string_literal: true
class FeatureCategory < ActiveRecord::Base
  THRESHOLD_CACHE_KEY = :"FeatureCategory::THRESHOLD_CACHE_KEY"
  has_many :featured_searches, dependent: :destroy
  after_update :delete_threshold_cache
  after_destroy :delete_threshold_cache

  def delete_threshold_cache
    Rails.cache.delete(THRESHOLD_CACHE_KEY)
  end
end
