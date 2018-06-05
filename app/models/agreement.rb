class Agreement < ApplicationRecord
  LATEST_AGREEMENT_VERSION = '1.1'.freeze
  AGREEMENT_VERSIONS = ['1.1'].freeze
  # TODO: These should also be required in schema.db
  validates :name, :email, :agreement_version, presence: true

  belongs_to :user

  def self.to_csv
    CSV.generate do |csv|
      csv << column_names
      all.each do |agreement|
        csv << agreement.attributes.values_at(*column_names)
      end
    end
  end
end
