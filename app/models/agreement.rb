class Agreement < ActiveRecord::Base
  attr_accessible :agreement_version, :email, :name, :uni


 def self.to_csv
    CSV.generate do |csv|
      csv << column_names
      all.each do |agreement|
        csv << agreement.attributes.values_at(*column_names)
      end
    end
  end

end
