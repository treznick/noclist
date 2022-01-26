# frozen_string_literal: true

require 'spec_helper'
require 'securerandom'

require_relative '../lib/client'

RSpec.describe Client do
  after do
    WebMock.reset!
  end

  let(:token) { SecureRandom.uuid.upcase }
  let(:checksum) { Digest::SHA256.hexdigest([token, Client::USERS_PATH].join('')) }
  let(:output_json) {
    %w(
      7692335473348482352
      6944230214351225668
      3628386513825310392
      8189326092454270383
    )
  }
  let(:user_ids) { output_json.join("\n") }

  context "happy path" do
    it "works" do
      auth_stub = stub_request(:get, [Client::URL, Client::AUTH_PATH].join('')).to_return(body: "foo", headers: { Client::TOKEN_HEADER_KEY => token })

      users_stub = stub_request(:get, [Client::URL, Client::USERS_PATH].join('')).with(headers: { Client::CHECKSUM_HEADER_KEY => checksum }).to_return(body: user_ids)

      expect(Client.run).to eq(JSON.dump(output_json))

      expect(auth_stub).to have_been_requested
      expect(users_stub).to have_been_requested
    end
  end

  context "sad path" do
    before do
      stub_request(:get, [Client::URL, Client::AUTH_PATH].join('')).to_return(body: "foo", status: 500)
    end

    it "exits" do
      expect {
        Client.run
      }.to raise_error(SystemExit)
    end
  end
end
