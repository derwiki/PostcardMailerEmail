require "rails_helper"

RSpec.describe CreatePostcard, type: :service do
  describe "#run" do
    let(:from_address) do
      {
        name: "From Name",
        address1: "123 From St",
        address2: nil,
        city: "From City",
        state: "CA",
        postal_code: "94110"
      }
    end

    let(:to_address) do
      {
        name: "To Name",
        address1: "456 To St",
        address2: nil,
        city: "To City",
        state: "CA",
        postal_code: "94111"
      }
    end

    let(:image_url) { "https://example.com/image.jpg" }
    let(:message) { "Test message" }
    let(:mock_response) { double("Response", body: "success") }
    let(:mock_http) { instance_double(Net::HTTP) }
    let(:mock_request) { instance_double(Net::HTTP::Post) }
    let(:target_uri) { URI("https://print.directmailers.com/api/v1/postcard/") }

    before do
      allow(Net::HTTP).to receive(:new).and_return(mock_http)
      allow(mock_http).to receive(:use_ssl=)
      allow(Net::HTTP::Post).to receive(:new).and_return(mock_request)
      allow(mock_request).to receive(:body=)
      allow(mock_http).to receive(:request).with(mock_request).and_return(
        mock_response
      )
      allow(Time).to receive(:now).and_return(Time.new(2025, 4, 16, 12, 0, 0))

      # Allow the request to receive header assignments
      allow(mock_request).to receive(:[]=).with(
        "Content-Type",
        "application/json"
      )
      allow(mock_request).to receive(:[]=).with("Accept", "application/json")
      allow(mock_request).to receive(:[]=).with(
        "Authorization",
        "Basic #{ENV["DIRECT_MAIL_KEY"]}"
      )
    end

    it "sends a properly formatted request to the Direct Mail API" do
      postcard =
        described_class.new(
          from_address,
          to_address,
          image_url,
          message,
          dryrun: true
        )
      response = postcard.run

      # Verify HTTP setup
      expect(Net::HTTP).to have_received(:new).with(
        "print.directmailers.com",
        443
      )
      expect(mock_http).to have_received(:use_ssl=).with(true)

      # Verify request headers
      expect(Net::HTTP::Post).to have_received(:new).with(target_uri)
      expect(mock_request).to have_received(:body=) do |json_body|
        parsed_body = JSON.parse(json_body)

        # Verify basic structure
        expect(parsed_body["Description"]).to match(
          /2025-04-16 12:00:00.*From Name => To Name/
        )
        expect(parsed_body["Size"]).to eq("4.25x6")
        expect(parsed_body["DryRun"]).to be true
        expect(parsed_body["WaitForRender"]).to be true

        # Verify To address
        expect(parsed_body["To"]).to eq(
          {
            "Name" => "To Name",
            "AddressLine1" => "456 To St",
            "AddressLine2" => nil,
            "City" => "To City",
            "State" => "CA",
            "Zip" => "94111"
          }
        )

        # Verify From address
        expect(parsed_body["From"]).to eq(
          {
            "Name" => "From Name",
            "AddressLine1" => "123 From St",
            "AddressLine2" => nil,
            "City" => "From City",
            "State" => "CA",
            "Zip" => "94110"
          }
        )

        # Verify Back HTML
        expect(parsed_body["Back"]).to include("background: url(#{image_url})")

        # Verify Front HTML contains message and default text
        expect(parsed_body["Front"]).to include("Test message")
        expect(parsed_body["Front"]).to include(
          "Brighten someone's day, send a free postcard at postcardmailer.us"
        )
      end

      # Verify response
      expect(response).to eq(mock_response)
    end
  end
end
