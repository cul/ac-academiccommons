# frozen_string_literal: true
class FeatureCategory < ActiveRecord::Base
  has_many :featured_searches, dependent: :destroy
end
