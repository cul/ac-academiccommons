# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

User.create(email: 'admin@example.com', provider: :developer, first_name: 'Test', last_name: 'Admin', role: 'admin', uid: 'ta123')
User.create(email: 'user@example.com', provider: :developer, first_name: 'Test', last_name: 'User', uid: 'tu123')
FeatureCategory.create(field_name: 'department_ssim', label: 'partner', thumbnail_url: 'featured/partner.png')
FeatureCategory.create(field_name: 'series_ssim', label: 'series', thumbnail_url: 'featured/series.png')
FeatureCategory.create(field_name: 'partner_journal_ssi', label: 'journal', thumbnail_url: 'featured/journal.png')