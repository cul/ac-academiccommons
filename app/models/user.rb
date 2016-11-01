class User < ActiveRecord::Base
 # Connects this user object to Blacklights Bookmarks and Folders.
 include Blacklight::User
 include Cul::Omniauth::Users

  before_create :set_personal_info_via_ldap
  after_initialize :set_personal_info_via_ldap

  # acts_as_authentic do |c|
  #   c.validate_password_field = false
  # end

  def admins
    where(:admin => true)
  end

  def to_s
    full_name # TODO: or uni?
  end

  def password
    Devise.friendly_token[0,20]
  end

  def password=(*val)
    # NOOP
  end

  # Overriding method from Cul::Omniauth::Users, to use same record if there isn't a
  # provider, but the uid matches.
  def self.find_for_provider(token, provider)
      return nil unless token['uid']
      props = {:uid => token['uid'].downcase, provider: provider.downcase}
      user = find_by(props)

      # Check if there's a user with the same uid without a provider.
      unless user
        user = find_by(props.slice(:uid))
        user.update!(props.slice(:provider))
      end

      # create new user if one could not be found
      unless user
        user = create!(whitelist(props))
      end
      user
  end


  def set_personal_info_via_ldap
    logger.info "============== /// ======="

    if uid
      entry = Net::LDAP.new({:host => "ldap.columbia.edu", :port => 389}).search(:base => "o=Columbia University, c=US", :filter => Net::LDAP::Filter.eq("uid", uid)) || []
      entry = entry.first

      if entry
        # self.email = entry[:mail].class.to_s
        # self.last_name = entry[:sn].to_s
        # self.first_name = entry[:givenname].to_s

        entry[:mail].kind_of?(Array) ? self.email = entry[:mail].first.to_s : self.email = entry[:mail].to_s
        entry[:sn].kind_of?(Array) ? self.last_name = entry[:sn].first.to_s : self.last_name = entry[:sn].to_s
        entry[:givenname].kind_of?(Array) ? self.first_name = entry[:givenname].first.to_s : self.first_name = entry[:givenname].to_s

        logger.info "uid: " + uid
        logger.info "email: " + email
        logger.info "last_name: " + last_name
        logger.info "first_name: " + first_name
        logger.info "============== end ======="
      end
    end

    return self
  end

end
