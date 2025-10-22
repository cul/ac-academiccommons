# frozen_string_literal: true

class APIClient < ApplicationRecord
  has_many :tokens, as: :authorizable, dependent: :destroy
end
