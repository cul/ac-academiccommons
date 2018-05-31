# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

User.create(email: 'admin@example.com', provider: :developer, first_name: 'Test', last_name: 'Admin', role: 'admin', uid: 'ta123')
User.create(email: 'user@example.com', provider: :developer, first_name: 'Test', last_name: 'User', uid: 'tu123')
