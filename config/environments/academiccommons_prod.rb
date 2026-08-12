require Rails.root.join('config/environments/deployed')

Rails.application.configure do
  config.hosts << 'academiccommons.columbia.edu'
end
