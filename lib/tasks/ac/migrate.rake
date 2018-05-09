namespace :ac do
  namespace :migrate do
    desc 'Migrate to roles'
    task to_roles: :environment do
      # If role column has '1' should be converted to admin, otherwise it will
      # be set to null.
      User.in_batches.each do |user|
        user.update(role: 'admin') if user.admin == true || user.admin == '1' || user.admin == 1
      end
    end
  end
end
