# Health Check App 📈

Here is a simple Health Check application for monitoring the availability and latency of specified endpoints! The application reads a configuration YAML file, makes HTTP requests to each endpoint, and logs their availability.

## Table of Contents 📚

- [Health Check App](#health-check-app)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Prerequisites](#prerequisites)
    - [Configuration File Format](#configuration-file-format)
  - [How to Run](#how-to-run)
    - [1. Clone the repository](#1-clone-the-repository)
    - [2. Running with Docker Compose](#2-running-with-docker-compose)
      - [Run with Default](#run-with-default)
      - [Run with your own YAML](#run-with-your-own-yaml)
    - [3. Running Locally](#3-running-locally)
      - [Run with Default](#run-with-default-1)
      - [Run with your own YAML](#run-with-your-own-yaml-1)
  - [Logging](#logging)
  - [Stopping the Application](#stopping-the-application)
  - [Development Notes](#development-notes)
  - [Troubleshooting](#troubleshooting)
  - [What's Next?](#whats-next)

## Overview 🌎

The application consists of a Ruby script (`health_check.rb`) that checks the availability of given endpoints on a configurable interval and logs their status as a percentage. It is designed to run in a loop, continuously checking endpoints by default every 15 seconds.

The main components of the application are:
- `health_check.rb`: The main logic for checking the health of endpoints and logging availability.
- `main.rb`: Entry point for running the health check script.
- `docker-compose.yml` and `Dockerfile`: Docker configurations to containerize the application and run it using Docker Compose.
- `run_healthcheck.sh`: A convenience script to run the application using Docker Compose.
#### Example of a successful build/run
![Health Check Fetch](https://github.com/user-attachments/assets/c387ee4b-cd65-43ff-ad45-3d9a9fbb3e87)

## Prerequisites 🪝

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Ruby](https://www.ruby-lang.org/en/documentation/installation/#rbenv) (if running locally without Docker I recommended using `rbenv` for version management)
- Configuration file (YAML format) that specifies the endpoints to monitor if not using the default file

### ⚠️ Note ⚠️ 
_**Docker Desktop must be installed and running**_

### Configuration File Format
The configuration file should be a YAML file that contains an array of endpoints to be monitored. It should follow the schema layout below.

```yaml
- headers:
    user-agent: fetch-synthetic-monitor
  method: GET
  name: fetch index page
  url: https://fetch.com/
- headers:
    user-agent: fetch-synthetic-monitor
  method: GET
  name: fetch careers page
  url: https://fetch.com/careers
- body: '{"foo":"bar"}'
  headers:
    content-type: application/json
    user-agent: fetch-synthetic-monitor
  method: POST
  name: fetch some fake post endpoint
  url: https://fetch.com/some/post/endpoint
- name: fetch rewards index page
  url: https://www.fetchrewards.com/
```
- **`url`**: The URL of the endpoint to check.
- **`method`**: The HTTP method to use (e.g., GET, POST).
- **`headers`**: Optional headers to be included in the request.
- **`body`**: Optional body to be included in the request (for POST, PUT, etc.).

## How to Run 🎬

### 1. Clone the repository
```bash
git clone git@github.com:Dav1s-Ops/fetch-health-check-ruby.git
cd fetch-health-check-ruby
```

### 2. Running with Docker Compose
To run the application with Docker Compose, use the provided script `run_healthcheck.sh`:

#### Run with Default
The default YAML is located in the `config` directory: `config/sample-endpoints.yaml`
```bash
./run_healthcheck.sh config/sample-endpoints.yaml
```

#### Run with your own YAML
This script will set up the appropriate environment variable (`ENDPOINTS_PATH`) and start Docker Compose with the provided configuration.
- **`ENDPOINTS_PATH`**: Path to the YAML file that contains the list of endpoints to be monitored. This path is **required** and needs to be provided during build time or set before running the container.
```bash
./run_healthcheck.sh <path_to_your_endpoints.yaml>
```


### 3. Running Locally
To run the application without Docker, you need Ruby and the required dependencies:

1. Install dependencies:

```bash
gem install bundler
bundle install
```

2. Run the health check script:
#### Run with Default
The default YAML is located in the `config` directory: `config/sample-endpoints.yaml`
```bash
ruby main.rb config/sample-endpoints.yaml
```

#### Run with your own YAML
This script will set up the appropriate environment variable (`ENDPOINTS_PATH`) and start Docker Compose with the provided configuration.
- **`ENDPOINTS_PATH`**: Path to the YAML file that contains the list of endpoints to be monitored. This path is **required** and needs to be provided during build time or set before running the container.
```bash
ruby main.rb <path_to_your_endpoints.yml>
```

## Logging 📝

The application logs the availability of each domain after every cycle to STDOUT. It displays the percentage of successful checks and prints the results to the console.

Example Output:
```
Checked: 2024-11-25 10:20:00 -0700
Timeout/Interval: 15s
example.com has 95% availability
another-example.com has 100% availability
```

## Stopping the Application 🛑
The application runs in a continuous loop, checking endpoints every 15 seconds by default. To stop the Docker container, press `CTRL+C` in the terminal where the container is running.

## Development Notes 🪡
- This application uses the `Faraday` gem for making HTTP requests.
- Latency is measured, and endpoints are considered healthy if the response status is between `200-299` and the response latency is less than `500ms`. This does not account for `3XX` as specified by the guidelines.

## Troubleshooting 🔦

If you encounter issues while running the application, here are some troubleshooting steps you can take:

### ⚙️ Check Configuration File: 
Ensure that the YAML configuration file is properly formatted and contains all required fields (url, method, etc.).

### ⚙️ Docker Errors: 
If Docker containers fail to start, ensure Docker and Docker Compose are installed and running. You can also try rebuilding the Docker image without the bash script by using:

```bash
ENDPOINTS_PATH=config/sample-endpoints.yaml docker compose up --build
```

### ⚙️ Network Issues: 
If endpoints are not reachable, check your network connection or ensure that the URLs specified are correct and accessible.

### ⚙️ Dependency Issues: 
If running locally, make sure all dependencies are installed. Run bundle install to ensure all gems are available. The project was built with `Ruby 3.2.2`

```bash
ruby -v
ruby 3.2.2 (2023-03-30 revision e51014f9c0) [arm64-darwin21]
```

### ⚙️ Environment Variables: 
Ensure that `ENDPOINTS_PATH` is set correctly, either in the Docker environment or when running locally. The application requires this to locate the configuration file.

## What's Next?
- Configurable sleep interval between checks passed as an additional argument with ARGV.
- More sophisticated logging (e.g., file-based logging) with Logger.
- Notification support (e.g., send an alert when availability drops below a threshold).
