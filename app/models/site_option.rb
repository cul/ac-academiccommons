class SiteOption < ApplicationRecord

    validates_presence_of :name
    validates :value, inclusion: { in: [ true, false ] }

    def self.deposits_enabled
        find_by(name: 'deposits_enabled')&.value
    end

end
  