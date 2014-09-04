class StudentAgreement < ActiveRecord::Base
  attr_accessible :years_embargo, :name, :email, :uni, :thesis_advisor, :department


 def self.to_csv
    CSV.generate do |csv|
      csv << column_names
      all.each do |agreement|
        csv << agreement.attributes.values_at(*column_names)
      end
    end
  end

end