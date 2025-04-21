require 'rails_helper'

RSpec.describe "Directmailer Webhooks", type: :request do
  let(:fixture_path) { Rails.root.join('test', 'fixtures', 'directmailer_webhook_payload.json') }
  let(:webhook_payload_hash) { JSON.parse(File.read(fixture_path)) }
  let(:print_record_id_from_fixture) { webhook_payload_hash.dig('Data', 0, 'PrintRecord') }

  # Create test data matching our schema
  let(:user) { User.create!(email: 'test@example.com') }
  let(:address) { 
    Address.create!(
      user: user,
      name: 'Test User',
      address1: '123 Main St',
      address2: 'Apt 4B',
      city: 'Anytown',
      state: 'CA',
      postal_code: '12345'
    )
  }

  # Memoize the payload to avoid modifying the original hash between tests
  let(:webhook_payload) { webhook_payload_hash.deep_dup }

  describe "POST /webhook" do
    context "when a matching Postcard exists" do
      before do
        Postcard.create!(
          user: user,
          address: address,
          image_url: 'http://example.com/image.jpg',
          message: 'Test message',
          response_data: {
            PrintRecord: print_record_id_from_fixture,
            OtherData: 'some info'
          }
        )
      end

      it "processes the webhook successfully" do
        matching_postcard = Postcard.where("response_data LIKE ?", "%#{print_record_id_from_fixture}%").first
        expect(matching_postcard).to be_present

        post '/webhook', params: webhook_payload, as: :json

        expect(response).to have_http_status(:ok)
      end
    end

    context "when a matching Postcard does not exist" do
      it "returns ok" do
        non_existent_id = 'non-existent-uuid-12345'
        webhook_payload['Data'][0]['PrintRecord'] = non_existent_id

        matching_postcard = Postcard.where("response_data LIKE ?", "%#{non_existent_id}%").first
        expect(matching_postcard).to be_nil

        post '/webhook', params: webhook_payload, as: :json

        expect(response).to have_http_status(:ok)
      end
    end

    context "when PrintRecord is missing in the payload" do
      it "returns ok" do
        webhook_payload['Data'][0].delete('PrintRecord')

        post '/webhook', params: webhook_payload, as: :json

        expect(response).to have_http_status(:ok)
      end
    end

    context "when the payload is malformed (e.g., Data is not an array)" do
      let(:malformed_payload) { { Event: "NewPrintObject", Object: "Postcard", Data: "not_an_array" } }

      it "handles the error gracefully and returns ok" do
        post '/webhook', params: malformed_payload, as: :json
        expect(response).to have_http_status(:ok)
      end
    end
  end
end 