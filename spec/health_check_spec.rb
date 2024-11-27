require 'spec_helper'

RSpec.describe HealthCheck do
  let(:timeout) { 15 }
  let(:config_path) { SAMPLE_ENDPOINTS_FILE }
  let(:health_check) { HealthCheck.new(config_path, timeout: timeout) }

  before do
    allow(Logger).to receive(:new).and_return(Logger.new('/dev/null'))
  end

  describe "#initialize" do
  it 'loads YAML correctly and initializes endpoints' do
    expect(health_check.instance_variable_get(:@endpoints)).to eq(YAML.load_file(config_path))
  end

    it 'sets up a Faraday connection with the given timeout' do
      conn = health_check.instance_variable_get(:@conn)
      expect(conn.options.timeout).to eq(timeout)
    end

    it 'initializes availability tracking for endpoints' do
      availability = health_check.instance_variable_get(:@availability)
      expect(availability).to be_a(Hash)
    end
  end

  describe '#run' do
    it 'calls check_endpoints and logs availability in a loop' do
      allow(health_check).to receive(:check_endpoints)
      allow(health_check).to receive(:log_availability)
      allow(health_check).to receive(:sleep)

      expect { Timeout.timeout(0.1) { health_check.run } }.to raise_error(Timeout::Error)

      expect(health_check).to have_received(:check_endpoints).at_least(:once)
      expect(health_check).to have_received(:log_availability).at_least(:once)
    end
  end

  describe '#check_endpoints' do
    it 'updates the availability hash based on endpoint responses' do
      VCR.use_cassette('check_endpoints') do
        health_check.send(:check_endpoints)

        availability = health_check.instance_variable_get(:@availability)
        expect(availability).to be_a(Hash)

        availability.each do |domain, stats|
          expect(stats[:up]).to be >= 0
          expect(stats[:total]).to be > 0
        end
      end
    end

    it 'handles timeout errors gracefully' do
      allow(health_check).to receive(:fetch_response_with_latency).and_raise(Faraday::TimeoutError)
      
      expect { health_check.send(:check_endpoints) }.to_not raise_error
    end
  end

  describe '#fetch_response_with_latency' do
    let(:endpoint) { { "url" => "https://jsonplaceholder.typicode.com/posts", "method" => "GET" } }

    it 'fetches a response and calculates latency' do
      VCR.use_cassette('fetch_response_with_latency') do
        response, latency = health_check.send(:fetch_response_with_latency, endpoint)

        expect(response).to be_a(Faraday::Response)
        expect(response.status).to eq(200)
        expect(latency).to be_a(Float)
        expect(latency).to be >= 0
      end
    end

    it 'raises an error if the request times out' do
      allow(health_check).to receive(:fetch_response).and_raise(Faraday::TimeoutError)

      expect { health_check.send(:fetch_response_with_latency, endpoint) }.to raise_error(Faraday::TimeoutError)
    end
  end

  describe '#fetch_response' do
    let(:endpoint) do
      {
        "url" => "https://jsonplaceholder.typicode.com/posts",
        "method" => "GET",
        "headers" => { "Content-Type" => "application/json" }
      }
    end

    it 'makes a successful HTTP request using Faraday' do
      VCR.use_cassette('fetch_response') do
        response = health_check.send(:fetch_response, endpoint)

        expect(response).to be_a(Faraday::Response)
        expect(response.status).to eq(200)
      end
    end

    it 'uses the correct HTTP method, headers, and body' do
      endpoint_with_body = endpoint.merge("method" => "POST", "body" => { "key" => "value" }.to_json)

      VCR.use_cassette('fetch_response_with_body') do
        response = health_check.send(:fetch_response, endpoint_with_body)

        expect(response).to be_a(Faraday::Response)
        expect(response.status).to eq(201)
      end
    end
  end

  describe '#log_availability' do
    before do
      health_check.instance_variable_set(:@availability, {
        "example.com" => { up: 3, total: 5 },
        "example.org" => { up: 4, total: 4 }
      })
    end

    it 'logs the availability of each domain' do
      expect { health_check.send(:log_availability, Time.now) }
        .to output(/example\.com has 60% availability\nexample\.org has 100% availability/).to_stdout
    end
  end
end
