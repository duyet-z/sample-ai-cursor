# frozen_string_literal: true

module Redmine
  # Service to fetch data from Redmine API
  # Usage: Redmine::FetchData.new(endpoint).perform
  class FetchData
    def initialize(endpoint)
      @endpoint = endpoint
    end

    # Fetch data from Redmine API
    # @return [Hash] parsed JSON response
    # @raise [Faraday::Error] if HTTP request fails
    def perform
      response = connection.get(@endpoint)
      JSON.parse(response.body)
    end

    private

    # Build Faraday connection with authentication
    def connection
      @connection ||= Faraday.new(url: Settings.redmine.url) do |faraday|
        # Basic authentication
        faraday.request :authorization, :basic,
                        Settings.redmine.basic_auth.username,
                        Settings.redmine.basic_auth.password

        # Set headers
        faraday.headers["X-Redmine-API-Key"] = Settings.redmine.api_key
        faraday.headers["Content-Type"] = "application/json"

        # Use default adapter
        faraday.adapter Faraday.default_adapter
      end
    end
  end
end

