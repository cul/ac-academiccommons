#
# Helper rake tasks to ease the migration process.
#

namespace :migration_helpers do
  desc "Looks up User email and destroys record if email can't be found"
  task :require_email => :environment do
    # Attempt to update user information via ldap.
    User.where(email: nil) do |u|
      u = u.set_personal_info_via_ldap
      u.save!

    # Destroy all records that don't contain an email.
    User.where(email: nil).destroy_all
  end
end
