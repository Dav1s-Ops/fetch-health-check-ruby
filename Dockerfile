FROM ruby:3.2-slim

WORKDIR /app

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

ARG ENDPOINTS_PATH
RUN test -n "$ENDPOINTS_PATH" || (echo "ENDPOINTS_PATH argument is required" && exit 1)

ENV ENDPOINTS_PATH=${ENDPOINTS_PATH}

CMD ["ruby", "app/main.rb", "${ENDPOINTS_PATH}"]
