require 'sinatra'

get '/delayed' do
  delay = (params[:delay] || '0.3').to_f
  sleep(delay)
  content_type :json
  { status: "Delayed for #{delay} seconds" }.to_json
end
