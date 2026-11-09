# frozen_string_literal: true

class APIClient < ApplicationRecord
  has_many :tokens, as: :authorizable, dependent: :destroy

  def to_s
    name.presence || contact_email.presence || 'API Client'
  end
end
