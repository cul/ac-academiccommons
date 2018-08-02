class User < ApplicationRecord
 # Connects this user object to Blacklights Bookmarks and Folders.
 include Blacklight::User
 include Cul::Omniauth::Users

  # User information is updated before every save. Every time a user logs in
  # their user model is saved by devise. Have to explicitly make these two calls
  # or else object is not updated when a user logs in.
  before_validation :set_personal_info_via_ldap, on: :create
  before_save       :set_personal_info_via_ldap

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
    return if uid.blank?

    begin
      ldap = Cul::LDAP.new
      person = ldap.find_by_uni(uid)

      if person
        # Don't override with nil
        self.email      = person.email || email
        self.first_name = person.first_name || first_name
        self.last_name  = person.last_name || last_name

        Rails.logger.info "Retrived user information via LDAP for #{full_name} (#{uid})"
      else
        Rails.logger.warn "LDAP record for #{uid} NOT found."
      end
    rescue StandardError => e
      raise e if new_record?
    end

    true
  end

  def signed_latest_agreement?
    agreements.map(&:agreement_version).include?(Agreement::LATEST_AGREEMENT_VERSION)
  end
end
