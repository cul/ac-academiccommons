class User < ActiveRecord::Base
# Connects this user object to Blacklights Bookmarks and Folders. 
 include Blacklight::User

  before_create :set_personal_info_via_ldap
  after_initialize :set_personal_info_via_ldap

  acts_as_authentic do |c|
    c.validate_password_field = false
  end

  def admins
    where(:admin => true)
  end

  def to_s
    if first_name
      first_name.to_s + ' ' + last_name.to_s
    else
      login
    end
  end

  def set_personal_info_via_ldap
    if wind_login
      entry = Net::LDAP.new({:host => "ldap.columbia.edu", :port => 389}).search(:base => "o=Columbia University, c=US", :filter => Net::LDAP::Filter.eq("uid", wind_login)) || []
      entry = entry.first

      if entry
        self.email = entry[:mail].to_s
        self.last_name = entry[:sn].to_s
        self.first_name = entry[:givenname].to_s
      end
    end

    return self
  end
  
end