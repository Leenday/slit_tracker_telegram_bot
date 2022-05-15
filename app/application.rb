# frozen_string_literal: true

# run the application in different environments

ENV['ENVIRONMENT'] ||= 'development'

# To use the added gems, we need to load them using the Kernel#require method,
# which loads the file or library passed as a parameter

require 'pg'
require 'active_record'
require 'dotenv'
require 'yaml'
require 'erb'
require './app/runner'

require './app/main'

# adding models
require './app/models/reminder'

# By default Dotenv.load for loading environment variables reaches out
# to the `.env` file, so if we want to use other environments it is worth
# extending this to the method below, which will first for a set development
# environment look for a file ending in `.env.development.local`,
# then `.env.development` and finally `.env`.

Dotenv.load(".env.#{ENV.fetch('ENVIRONMENT')}.local", ".env.#{ENV.fetch('ENVIRONMENT')}", '.env')

# Method needed for loading database settings
def db_configuration
  # The method below returns the path to the file with our configuration
  db_configuration_file_path = File.join(File.expand_path('..', __dir__), 'db', 'config.yml')

  # Having the path to the file, we can read its values. Because the config.yml
  # file contains environment variables and, as you may have noticed,
  # the erb <%= %> syntax, we also need to use the erb gem. Without this,
  # the values of the variables will not be read correctly and activerecord
  # will not be able to connect to postgres.The following method will return
  # the configuration as a string

  db_configuration_result = ERB.new(File.read(db_configuration_file_path)).result

  # Using the previously added `yaml` gem, we can safely load our configuration

  YAML.safe_load(db_configuration_result, aliases: true)
end

# Finally, we need to create a connection between activerecord and postgres
# using the `establish_connection` method
# ActiveRecord::Base.establish_connection(db_configuration[ENV['ENVIRONMENT']])

Dotenv.load(".env.#{ENV.fetch('ENVIRONMENT')}.local", ".env.#{ENV.fetch('ENVIRONMENT')}", '.env')

module Application
  class Error < StandardError; end
  # Your code goes here...
end
