# frozen_string_literal: true

module Redmine
  # Service to fetch data from Redmine API
  # Usage: Redmine::FetchData.new(endpoint).perform
  class FetchData
    attr_reader :endpoint

    def initialize(endpoint)
      @endpoint = endpoint
    end

    # Fetch data from Redmine API
    # Returns parsed JSON response or raises error
    def perform
      response = connection.get(endpoint) do |request|
        # Add API key to request header
        request.headers["X-Redmine-API-Key"] = Settings.redmine.api_key
      end

      handle_response(response)
    end

    private

    # Create Faraday connection with basic auth
    def connection
      @connection ||= Faraday.new(
        url: Settings.redmine.url,
        headers: { "Content-Type" => "application/json" }
      ) do |faraday|
        # Basic authentication
        faraday.request :authorization, :basic,
                        Settings.redmine.basic_auth.username,
                        Settings.redmine.basic_auth.password

        faraday.adapter Faraday.default_adapter
      end
    end

    # Handle HTTP response
    def handle_response(response)
      case response.status
      when 200..299
        JSON.parse(response.body)
      when 401
        raise "Unauthorized: Invalid API key or credentials"
      when 404
        raise "Not Found: Endpoint #{endpoint} does not exist"
      else
        raise "HTTP Error #{response.status}: #{response.body}"
      end
    end
  end
end
