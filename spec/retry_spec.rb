# frozen_string_literal: true

require 'spec_helper'

require_relative '../lib/retry'
require 'excon'

RSpec.describe Retry do
  let(:good_response) { Excon::Response.new({ status: 200 }) }
  let(:return_good_response) { -> { good_response } }

  class AlwaysBad
    class << self
      def calls
        @calls
      end

      def setup
        @calls = 0
      end

      def call
        increment_call_count
        Excon::Response.new({ status: 500 })
      end

      def increment_call_count
        @calls += 1
      end
    end
  end

  class AlwaysExceptional
    class << self
      def setup
        @calls = 0
      end

      def calls
        @calls
      end

      def call
        increment_call_count
        raise "boom"
      end

      def increment_call_count
        @calls += 1
      end
    end
  end

  class SometimesBad
    class << self
      def setup
        @calls = 0
        @good_responses = 0
        @bad_responses = 0
      end

      def calls
        @calls
      end

      def good_responses
        @good_responses
      end

      def bad_responses
        @bad_responses
      end

      def call
        increment_call_count
        if @calls < 3
          @bad_responses += 1
          Excon::Response.new({ status: 500 })
        else
          @good_responses += 1
          Excon::Response.new({ status: 200 })
        end
      end

      def increment_call_count
        @calls += 1
      end
    end
  end

  class SometimesExceptional
    class << self
      def setup
        @calls = 0
        @good_responses = 0
        @exceptional_responses = 0
      end

      def calls
        @calls
      end

      def good_responses
        @good_responses
      end

      def exceptional_responses
        @exceptional_responses
      end

      def call
        increment_call_count
        if @calls < 3
          @exceptional_responses += 1
          raise "boom"
        else
          @good_responses += 1
          Excon::Response.new({ status: 200 })
        end
      end

      def increment_call_count
        @calls += 1
      end
    end
  end

  describe '.with_retries' do
    context "given a good response" do
      it "returns the good response" do
        expect(described_class.with_retries(&return_good_response)).to eq(good_response)
      end
    end

    context "given always bad calls" do
      around do |example|
        AlwaysBad.setup
        example.run
        AlwaysBad.setup
      end

      let(:always_bad) { -> { AlwaysBad.call } }

      it "exits" do
        expect {
          described_class.with_retries(&always_bad)
        }.to raise_error(SystemExit)

        expect(AlwaysBad.calls).to eq(3)
      end
    end

    context "given sometimes bad calls" do
      around do |example|
        SometimesBad.setup
        example.run
        SometimesBad.setup
      end

      let(:sometimes_bad) { -> { SometimesBad.call } }

      it "returns" do
        expect(described_class.with_retries(&sometimes_bad).status).to eq(200)

        expect(SometimesBad.good_responses).to eq(1)
        expect(SometimesBad.bad_responses).to eq(2)
      end
    end

    context "given always exceptional calls" do
      around do |example|
        AlwaysExceptional.setup
        example.run
        AlwaysExceptional.setup
      end

      let(:always_exceptional) { -> { AlwaysExceptional.call } }

      it "exits" do
        expect {
          described_class.with_retries(&always_exceptional)
        }.to raise_error(SystemExit)

        expect(AlwaysExceptional.calls).to eq(3)
      end
    end

    context "given sometimes exceptional calls" do
      around do |example|
        SometimesExceptional.setup
        example.run
        SometimesExceptional.setup
      end

      let(:sometimes_exceptional) { -> { SometimesExceptional.call } }

      it "returns" do
        expect(described_class.with_retries(&sometimes_exceptional).status).to eq(200)

        expect(SometimesExceptional.good_responses).to eq(1)
        expect(SometimesExceptional.exceptional_responses).to eq(2)
      end
    end
  end
end
