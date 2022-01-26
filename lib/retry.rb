# frozen_string_literal: true

class Retry
  class RetryError < StandardError; end

  def self.with_retries
    attempts = 0
    begin
      attempts += 1
      response = yield
      if response.status == 200
        response
      elsif attempts > 2
        exit 1
      else
        raise RetryError
      end
    rescue RetryError
      retry
    rescue StandardError => e
      if attempts > 2
        exit 1
      else
        retry
      end
    end
  end
end
