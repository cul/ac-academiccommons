class EmailPreference < ActiveRecord::Base
  attr_accessible :author, :monthly_opt_out, :email
end
