# frozen_string_literal: true

require 'dotenv'
require 'yaml'
require 'active_record'
require 'erb'

module DatabaseConnection
  class << self
    def load_env
      ENV['ENVIRONMENT'] ||= 'development'
      Dotenv.load(".env.#{ENV.fetch('ENVIRONMENT')}.local", ".env.#{ENV.fetch('ENVIRONMENT')}", '.env')
    end

    def db_configuration
      db_configuration_file_path = File.join(File.expand_path('..', __dir__), 'db', 'config.yml')
      db_configuration_result = ERB.new(File.read(db_configuration_file_path)).result
      YAML.safe_load(db_configuration_result, aliases: true)
    end

    def connect
      load_env
      db_configuration
      ActiveRecord::Base.establish_connection(db_configuration[ENV['ENVIRONMENT']])
    end
  end
end
