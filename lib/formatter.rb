# frozen_string_literal: true

require 'json'

class Formatter
  def self.format(result)
    new.format(result)
  end

  def initialize(output: $stdout)
    @output = output
  end

  def format(result)
    @output.puts(JSON.dump(result))
  end
end
