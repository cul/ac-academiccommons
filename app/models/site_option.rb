class SiteOption < ApplicationRecord

    def self.deposits_enabled
        find_by(name: 'deposits_enabled')&.value || false
    end

end
  