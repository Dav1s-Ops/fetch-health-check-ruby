require 'yaml'
require 'faraday'

class HealthCheck
  def initialize(config_path, timeout: 15)
    @endpoints = YAML.load_file(config_path)
    @availability = Hash.new { |hash, key| hash[key] = { up: 0, total: 0 } }
    @conn = Faraday.new do |f|
      f.options.timeout = timeout
    end
    @timeout = timeout
  end

  def run
    loop do
      start_time = Time.now
      check_endpoints
      log_availability(start_time)
      sleep @timeout
    end
  end

  private

  def check_endpoints
    @endpoints.each do |endpoint|
      domain = URI(endpoint["url"]).host
      response, latency = fetch_response_with_latency(endpoint)

      if response.success? && latency < 0.5
        @availability[domain][:up] += 1
      end
      @availability[domain][:total] += 1
    end
  end

  def fetch_response_with_latency(endpoint)
    start_time = Time.now
    response = fetch_response(endpoint)
    end_time = Time.now
    latency = (end_time - start_time)

    [response, latency]
  end

  def fetch_response(endpoint)
    @conn.send(endpoint["method"]&.downcase || "get", endpoint["url"]) do |req|
      req.headers = endpoint["headers"] || {}
      req.body = endpoint["body"] if endpoint["body"]
    end
  end

  def log_availability(start_time)
    puts "Checked: #{start_time}"
    puts "Timeout: #{@timeout}s"
    @availability.each do |domain, stats|
      availability_percentage = (100.0 * stats[:up] / stats[:total]).round
      puts "#{domain} has #{availability_percentage}% availability"
    end
    puts "\n"
  end
end