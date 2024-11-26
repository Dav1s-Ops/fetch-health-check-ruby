FROM ruby:3.2-slim

WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

CMD ["ruby", "app/main.rb", "config/sample-endpoints.yaml"]