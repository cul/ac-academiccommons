#
# Helper rake tasks to ease the migration process.
#

namespace :migration_helpers do
  desc "Looks up User email and destroys record if email can't be found"
  task :require_email => :environment do
    # Attempt to update user information via ldap.
    User.where(email: nil) do |u|
      u = u.set_personal_info_via_ldap
      if u.changed?
        puts "Saving info found via ldap for #{u.uid}"
        u.save!
      end
    end

    # Destroy all records that don't contain an email.
    User.where(email: nil).destroy_all
  end

  desc "Add provider for each User."
  task :add_provider => :environment do
    # Add :saml as the provider for each row.
    User.find_each do |u|
      u.update!(provider: 'saml')
    end
  end
end
