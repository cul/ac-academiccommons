require Rails.root.join('config/environments/deployed')

# WIP: Options that differed from default config (from fast mcp branch)

# TODO: These were commented out (proabbly do not need, based on comments in default config)
config.assets.js_compressor = Uglifier.new(harmony: true)
config.assets.css_compressor = :sass

# TODO: Likely keep
config.hosts << 'academiccommons.columbia.edu'
