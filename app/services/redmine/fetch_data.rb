# frozen_string_literal: true

module Redmine
  # Service to fetch data from Redmine API
  # Usage: Redmine::FetchData.new(endpoint).perform
  class FetchData
    require "net/http"
    require "uri"
    require "json"

    def initialize(endpoint)
      @endpoint = endpoint
    end

    # Execute API request to Redmine
    # Returns parsed JSON response or raises error
    def perform
      uri = build_uri
      request = build_request(uri)
      execute_request(uri, request)
    end

    private

    attr_reader :endpoint

    # Build full URI from base URL and endpoint
    def build_uri
      base_url = Settings.redmine.base_url
      raise ArgumentError, "REDMINE_BASE_URL not configured" if base_url.blank?

      URI.join(base_url, endpoint)
    end

    # Build HTTP GET request with authentication headers
    def build_request(uri)
      request = Net::HTTP::Get.new(uri)

      # Add API key header
      api_key = Settings.redmine.api_key
      raise ArgumentError, "REDMINE_API_KEY not configured" if api_key.blank?
      request["X-Redmine-API-Key"] = api_key

      # Add Basic Authentication
      username = Settings.redmine.basic_auth.username
      password = Settings.redmine.basic_auth.password
      request.basic_auth(username, password) if username.present? && password.present?

      request
    end

    # Execute HTTP request and parse response
    def execute_request(uri, request)
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end

      handle_response(response)
    end

    # Handle HTTP response and parse JSON
    def handle_response(response)
      case response.code.to_i
      when 200..299
        JSON.parse(response.body)
      when 401
        raise StandardError, "Unauthorized: Check API key and basic auth credentials"
      when 404
        raise StandardError, "Not Found: #{endpoint}"
      else
        raise StandardError, "Request failed with status #{response.code}: #{response.message}"
      end
    end
  end
end

