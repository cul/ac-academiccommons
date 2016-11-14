class User < ActiveRecord::Base
 # Connects this user object to Blacklights Bookmarks and Folders.
 include Blacklight::User
 include Cul::Omniauth::Users

  before_create :set_personal_info_via_ldap
  after_initialize :set_personal_info_via_ldap

  def admins
    where(:admin => true)
  end

  def to_s
    full_name # TODO: or uni?
  end

  # Password methods required by Devise.
  def password
    Devise.friendly_token[0,20]
  end

  def password=(*val)
    # NOOP
  end

  #TODO: What to do if lDAP doesn't return?
  def set_personal_info_via_ldap
    if uid
      entry = Net::LDAP.new({:host => "ldap.columbia.edu", :port => 389}).search(:base => "o=Columbia University, c=US", :filter => Net::LDAP::Filter.eq("uid", uid)) || []
      entry = entry.first

      if entry
        entry[:mail].kind_of?(Array) ? self.email = entry[:mail].first.to_s : self.email = entry[:mail].to_s
        entry[:sn].kind_of?(Array) ? self.last_name = entry[:sn].first.to_s : self.last_name = entry[:sn].to_s
        entry[:givenname].kind_of?(Array) ? self.first_name = entry[:givenname].first.to_s : self.first_name = entry[:givenname].to_s

        # Setting email if missing from lDAP
        self.email = "#{uid}@columbia.edu" if self.email.blank?

        logger.info "Retriving/updating user information via LDAP for #{first_name} #{last_name} (#{uid})"
      end
    end

    return self
  end
end
