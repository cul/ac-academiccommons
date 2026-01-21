class User < ApplicationRecord
  # Connects this user object to Blacklights Bookmarks and Folders.
  include Blacklight::User

  # User information is updated before every save and before validation when an
  # object is created. We have to explicitly make the two calls because on
  # create validation will fail if email, etc are not present. Every time a user
  # logs in and logs out their user model is saved by devise. Therefore, ldap
  # information is updated at user log in and log out.
  before_validation :set_personal_info_via_ldap, on: :create
  before_save       :set_personal_info_via_ldap

  # Configure devise for our User model
  devise :rememberable, :trackable, :omniauthable, omniauth_providers: Devise.omniauth_configs.keys

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
    full_name
  end

  # Use uni as full_name in case an ldap entry can't be found and thus no
  # first name or last name can be retrieved.
  def full_name
    first_name.present? && last_name.present? ? "#{first_name} #{last_name}" : uid
  end

  def set_personal_info_via_ldap
    return if uid.blank?

    # Set email, in case ldap query fails or there isn't an ldap record for this user.
    self.email = "#{uid}@columbia.edu" if email.blank?

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
  end

  def signed_latest_agreement?
    agreements.map(&:agreement_version).include?(Agreement::LATEST_AGREEMENT_VERSION)
  end

  def email_preference
    @email_preference ||= EmailPreference.for(uid)
    @email_preference ||= EmailPreference.create(uni: uid, email: email, unsubscribe: false)
    @email_preference
  end
end
