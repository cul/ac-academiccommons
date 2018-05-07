class User < ApplicationRecord
 # Connects this user object to Blacklights Bookmarks and Folders.
 include Blacklight::User
 include Cul::Omniauth::Users

  before_create :set_personal_info_via_ldap
  after_initialize :set_personal_info_via_ldap

  def self.admins
    where(admin: true)
  end

  def admin?
    admin == 1
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

  def set_personal_info_via_ldap
    if uid
      person = AcademicCommons::LDAP.find_by_uni(uid)
      self.email = person.email
      self.first_name = person.first_name
      self.last_name = person.last_name
    end

    self
  end
end
