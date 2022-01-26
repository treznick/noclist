# frozen_string_literal: true

require 'digest'
require 'excon'
require_relative './retry'

class Client
  URL = "http://0.0.0.0:8888"
  AUTH_PATH = "/auth"
  USERS_PATH = "/users"
  TOKEN_HEADER_KEY = "Badsec-Authentication-Token"
  CHECKSUM_HEADER_KEY = "X-Request-Checksum"

  attr_reader :connection

  def initialize
    @connection = Excon.new(URL)
  end

  def run
    get_auth_token
    compute_checksum
    get_users_json
  end

  def self.run
    new.run
  end

  private

  attr_reader :token, :checksum

  def get_auth_token
    @token ||= execute_get_auth_request.headers[TOKEN_HEADER_KEY]
  end

  def compute_checksum
    @checksum ||= Digest::SHA256.hexdigest([token, USERS_PATH].join(''))
  end

  def execute_get_auth_request
    Retry.with_retries do
      connection.get(path: AUTH_PATH)
    end
  end

  def execute_users_request
    Retry.with_retries do
      connection.get(path: USERS_PATH, headers: { CHECKSUM_HEADER_KEY => checksum } )
    end
  end

  def get_users_json
    user_ids = execute_users_request.body.split("\n")
    JSON.dump(user_ids)
  end
end
