# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
AcademicCommons::Application.config.secret_token =
  if Rails.env.development? || Rails.env.test?
    'f86a56f38ffc7b8f92c12a3cc93bffa05bdeae89df2cbd1a6d014be60a94ee514d9a0b78ad50c40d276e476d67493ea9074b3f4daf0fa95fdce9a62183ad55d3'
  else
    ENV['SECRET_TOKEN']
  end

AcademicCommons::Application.config.secret_key_base =
  if Rails.env.development? || Rails.env.test?
    'f86a56f38ffc7b8f92c12a3cc93bffa05bdeae89df2cbd1a6d014be60a94ee514d9a0b78ad50c40d276e476d67493ea9074b3f4daf0fa95fdce9a62183ad55d3'
  else
    ENV['SECRET_KEY_BASE']
  end
