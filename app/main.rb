require 'yaml'
require 'faraday'

class HealthCheck
  def initialize(config_path)
    @endpoints = YAML.load_file(config_path)
  end
end

def run
  config_path = ARGV[0]
  unless config_path && File.exist?(config_path)
    puts "Usage: #{__FILE__} <name>"
    exit 1
  end

  config = HealthCheck.new(config_path)
  puts "File loaded: #{config.inspect}"

  loop do
    puts "Hello world!"
    sleep 15
  end
end

run