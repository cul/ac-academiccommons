class User < ApplicationRecord
 # Connects this user object to Blacklights Bookmarks and Folders.
 include Blacklight::User
 include Cul::Omniauth::Users

  before_create :set_personal_info_via_ldap
  after_initialize :set_personal_info_via_ldap

  ADMIN = 'admin'.freeze
  ROLES = [ADMIN].freeze

  def self.admins
    where(role: ADMIN)
  end

  def admin?
    role == ADMIN
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
      # Don't override with nil
      self.email      = person.email || email
      self.first_name = person.first_name || first_name
      self.last_name  = person.last_name || last_name
    end

    self
  end
end
