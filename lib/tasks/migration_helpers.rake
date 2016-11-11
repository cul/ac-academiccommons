#
# Helper rake tasks to ease the migration process.
#

namespace :migration_helpers do
  desc "Looks up User email and destroys record if email can't be found"
  task :require_email => :environment do
    # Attempt to update user information via ldap.
    User.where(email: nil).each do |u|
      u = u.set_personal_info_via_ldap
      u.save! if u.changed?
    end

    # Destroy all records that don't contain an email.
    User.where(email: nil).destroy_all
  end

  desc "Removes records with duplicate emails"
  task :delete_duplicate_emails => :environment do
    dup_emails = User.select(:email).group(:email).having("count(*) > 1").count.keys

    dup_emails.each do |e|
      logger.info "Deleting extra record for #{e}."
      User.find_by(email: e).destroy
    end
  end
end
