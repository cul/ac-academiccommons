class User < ApplicationRecord
 # Connects this user object to Blacklights Bookmarks and Folders.
 include Blacklight::User
 include Cul::Omniauth::Users

  before_create :set_personal_info_via_ldap
  after_initialize :set_personal_info_via_ldap

  ADMIN = 'admin'.freeze
  ROLES = [ADMIN].freeze

  has_many :agreements, dependent: :destroy
  has_many :deposits,   dependent: :nullify # Keep deposits even if the user has been removed.

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

  def signed_latest_agreement?
    agreements.map(&:agreement_version).include?(Agreement::LATEST_AGREEMENT_VERSION)
  end
end
