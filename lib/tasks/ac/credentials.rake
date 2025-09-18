# frozen_string_literal: true

require 'rails/generators/rails/credentials/credentials_generator'
require 'rails/generators/rails/encryption_key_file/encryption_key_file_generator'

namespace :ac do
  namespace :templated_credentials do
    desc 'create encrypted credentials from template file for a specified environment'
    task :add, [:env_name] do |_task, args|
      if args.env_name.nil?
        puts 'Creating credentials from template (not environment specific):'
        credentials_path = 'config/credentials.yml.enc'
        key_path = 'config/master.key'
        template_path = 'config/credentials_template.yml'
      else
        puts "Creating #{args.env_name} credentials from template:"
        credentials_path = "config/credentials/#{args.env_name}.yml.enc"
        key_path = "config/credentials/#{args.env_name}.key"
        template_path = "config/#{args.env_name}_credentials_template.yml"
      end

      create_a_new_encryption_key_file(key_path)
      create_a_new_credentials_file(credentials_path, key_path)
      ignore_file(credentials_path)
      ignore_file(key_path)

      enc_config = ActiveSupport::EncryptedConfiguration.new(
        config_path: credentials_path,
        key_path: key_path,
        env_key: 'RAILS_MASTER_KEY',
        raise_if_missing_key: true
      )

      # Write the template data to credentials file
      enc_config.change do |tmp_path|
        puts "writing content from #{template_path} to #{credentials_path}..."
        IO.binwrite(tmp_path, IO.binread(Rails.root.join(template_path)))
      end
    end

    desc 'Create credentials for local development and test environments from template files'
    task add_all: :environment do
      Rake::Task['ac:templated_credentials:add'].invoke('development')
      Rake::Task['ac:templated_credentials:add'].reenable
      Rake::Task['ac:templated_credentials:add'].invoke('test')
      puts Rainbow('Created credentials for local development and test environments.').cyan
    end

    desc 'Create credentials from template file (not environment specific)'
    task add_credentials: :environment do
      # Simply call :add task without arguments
      Rake::Task['ac:templated_credentials:add'].invoke
      puts Rainbow('Created credentials.').cyan
    end

    # Use a Rails generator to create a credentials file, if it does not exist.
    # Encrypts the file with the given key.
    def create_a_new_credentials_file(credentials_path, key_path)
      return if File.exist? Rails.root.join credentials_path

      Rails::Generators::CredentialsGenerator.new(
        [credentials_path, key_path],
        skip_secret_key_base: true,
        quiet: true
      ).invoke_all
      puts "Created encrypted credentials file: #{Rainbow(credentials_path).green}"
    end

    # Use a Rails generator to make a key file, if it does not exist.
    def create_a_new_encryption_key_file(key_path)
      return if File.exist? Rails.root.join(key_path)

      Rails::Generators::EncryptionKeyFileGenerator.new.add_key_file(key_path)
      puts "Created encryption key file: #{Rainbow(key_path).green}"
    end

    # Add a file path to the project .gitignore file, unless it is already there
    def ignore_file(file_path)
      return unless File.exist? '.gitignore'

      if File.read('.gitignore').include? "/#{file_path}\n"
        puts "#{Rainbow(file_path).yellow} already added to .gitignore."
        return
      end
      puts "Ignoring #{Rainbow(file_path).green} so it won't end up in Git history."
      File.write('.gitignore', "\n/#{file_path}\n", mode: 'a')
    end
  end
end
