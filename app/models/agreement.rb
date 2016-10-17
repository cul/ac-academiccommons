class Agreement < ActiveRecord::Base

 def self.to_csv
    CSV.generate do |csv|
      csv << column_names
      all.each do |agreement|
        csv << agreement.attributes.values_at(*column_names)
      end
    end
  end

end
