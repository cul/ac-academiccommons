# frozen_string_literal: true
class FeaturedSearchValue < ActiveRecord::Base
  belongs_to :featured_search
  validates :value, presence: true
end
