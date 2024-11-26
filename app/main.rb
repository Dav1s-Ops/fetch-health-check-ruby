require_relative "health_check"

if ARGV.empty?
  puts "Usage: ruby #{__FILE__} <config_path>"
  exit 1
end

config_file = ARGV[0]
health_check = HealthCheck.new(config_file)
health_check.run