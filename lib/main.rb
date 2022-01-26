# frozen_string_literal: true

require_relative './client'
require_relative './formatter'

class Main
  def self.run
    new.run
  end

  attr_reader :formatter

  def initialize(formatter: Formatter.new)
    @formatter = formatter
  end

  def run
    formatter.format(Client.run)
  end
end
