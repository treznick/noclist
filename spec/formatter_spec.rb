# frozen_string_literal: true

require 'spec_helper'

require_relative '../lib/formatter'
require 'json'

RSpec.describe Formatter do
  let(:output) { StringIO.new }
  let(:formatter) { described_class.new(output: output) }
  let(:input) {
    %w(
      7692335473348482352
      6944230214351225668
      3628386513825310392
      8189326092454270383
    )
  }

  it "JSON dumps" do
    formatter.format(input)
    expect(output.string.chomp).to eq(JSON.dump(input))
  end
end
