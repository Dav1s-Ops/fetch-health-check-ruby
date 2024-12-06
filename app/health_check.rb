require 'yaml'
require 'faraday'
require 'logger'
require 'parallel'

class HealthCheck
  attr_accessor :timeout

  def initialize(config_path, timeout: 15)
    @endpoints = YAML.load_file(config_path)
    @availability = Hash.new { |hash, key| hash[key] = { up: 0, total: 0 } }
    @conn = Faraday.new do |f|
      f.options.timeout = timeout
    end
    @timeout = timeout
    @logger = Logger.new($stdout)
    @logger.level = Logger::INFO
  end

  def run
    loop do
      start_time = Time.now
      check_endpoints
      log_availability(start_time)
      end_time = Time.now
      drift_time = @timeout - (end_time - start_time).abs
      puts "Runtime: #{end_time - start_time}"
      puts "Driftin': #{drift_time}"
      sleep drift_time
    end
  end

  private

  def check_endpoints
    thread_process = Parallel.map(@endpoints) do |endpoint|

      domain = URI(endpoint["url"]).host
      begin
        response, latency = fetch_response_with_latency(endpoint)
  
        if response.success? && latency < 0.5
          @availability[domain][:up] += 1
        end
        @availability[domain][:total] += 1
      
      rescue Faraday::ConnectionFailed => error
        @logger.warn error.message
      rescue Faraday::TimeoutError => error
        @logger.warn error.message
      end
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
    puts "Timeout/Interval: #{@timeout}s"
    @availability.each do |domain, stats|
      availability_percentage = (100.0 * stats[:up] / stats[:total]).round
      puts "#{domain} has #{availability_percentage}% availability"
    end
    puts "\n"
  end
end