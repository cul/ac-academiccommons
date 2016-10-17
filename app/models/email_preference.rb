class EmailPreference < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
end
