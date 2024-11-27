require_relative '../app/health_check.rb'
require 'spec_helper'

RSpec.describe HealthCheck do
  let(:config_path) { SAMPLE_ENDPOINTS_FILE }
  let(:health_check) { HealthCheck.new(config_path) }

  it 'exists' do
    expect(health_check).to be_instance_of(HealthCheck)
  end
end
