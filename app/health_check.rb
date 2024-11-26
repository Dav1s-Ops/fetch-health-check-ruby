require 'yaml'
require 'faraday'

class HealthCheck
  def initialize(config_path)
    @endpoints = YAML.load_file(config_path)
    @availability = Hash.new { |hash, key| hash[key] = { up: 0, total: 0 } }
    @responses = {}
  end

  def run
    loop do
      check_endpoints
      log_availability
      sleep 15
    end
  end

  private

  def check_endpoints
    @endpoints.each do |endpoint|
      domain = URI(endpoint["url"]).host
      response = fetch_response(endpoint)
      latency = calculate_latency(endpoint)

      if response && response.status.between?(200, 299) && latency < 500
        @availability[domain][:up] += 1
      end
      @availability[domain][:total] += 1
    end
  end

  def fetch_response(endpoint)
    Faraday.send(endpoint["method"]&.downcase || "get", endpoint["url"]) do |req|
      req.headers = endpoint["headers"] || {}
      req.body = endpoint["body"] if endpoint["body"]
    end
  end

  def calculate_latency(endpoint)
    start_time = Time.now
    fetch_response(endpoint)
    (Time.now - start_time) * 1000
  end

  def log_availability
    @availability.each do |domain, stats|
      availability_percentage = (100.0 * stats[:up] / stats[:total]).round
      puts "#{domain} has #{availability_percentage}% availability"
    end
  end
end