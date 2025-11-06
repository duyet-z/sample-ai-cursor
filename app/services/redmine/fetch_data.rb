# frozen_string_literal: true

module Redmine
  # Service to fetch data from Redmine API
  # Usage: Redmine::FetchData.new(endpoint).perform
  class FetchData
    def initialize(endpoint)
      @endpoint = endpoint
    end

    # Performs the API request and returns parsed JSON response
    def perform
      response = connection.get(@endpoint)
      handle_response(response)
    end

    private

    # Creates Faraday connection with authentication headers
    def connection
      @connection ||= Faraday.new(url: base_url) do |conn|
        conn.request :authorization, :basic, basic_auth_username, basic_auth_password
        conn.headers["X-Redmine-API-Key"] = api_key
        conn.headers["Content-Type"] = "application/json"
        conn.response :json, content_type: /\bjson$/
        conn.adapter Faraday.default_adapter
      end
    end

    # Handles API response and raises error if unsuccessful
    def handle_response(response)
      if response.success?
        response.body
      else
        raise "Redmine API Error: #{response.status} - #{response.body}"
      end
    end

    # Configuration getters from Settings
    def base_url
      Settings.redmine.base_url
    end

    def api_key
      Settings.redmine.api_key
    end

    def basic_auth_username
      Settings.redmine.basic_auth.username
    end

    def basic_auth_password
      Settings.redmine.basic_auth.password
    end
  end
end

