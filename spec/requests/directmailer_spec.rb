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
      let!(:postcard) do
        Postcard.create!(
          user: user,
          address: address,
          image_url: 'http://example.com/image.jpg',
          message: 'Test message',
          response_data: {
            PrintRecord: print_record_id_from_fixture,
            OtherData: 'some info'
          },
          print_record_id: print_record_id_from_fixture,
          directmailers_events: []
        )
      end

      before do
        # Mock the mailer to avoid actual email sending in tests
        allow(PostcardLifecycleMailer).to receive_message_chain(:status_update, :deliver_later)
      end

      it "processes the webhook successfully" do
        matching_postcard = Postcard.find_by(print_record_id: print_record_id_from_fixture)
        expect(matching_postcard).to be_present

        post '/webhook', params: webhook_payload, as: :json

        expect(response).to have_http_status(:ok)
      end

      it "records the webhook event in directmailers_events" do
        expect {
          post '/webhook', params: webhook_payload, as: :json
        }.to change {
          postcard.reload.directmailers_events.size
        }.by(1)

        # Verify the event was prepended (is first in the array)
        first_event = postcard.reload.directmailers_events.first
        expect(first_event['event_type']).to eq(webhook_payload['Event'])
      end

      it "properly handles multiple webhook events" do
        # First webhook
        post '/webhook', params: webhook_payload, as: :json

        # Modified second webhook
        modified_payload = webhook_payload.deep_dup
        modified_payload['Event'] = 'UpdatedPrintObject'
        post '/webhook', params: modified_payload, as: :json

        # Check that we have two events, newest first
        events = postcard.reload.directmailers_events
        expect(events.size).to eq(2)
        expect(events[0]['event_type']).to eq('UpdatedPrintObject')
        expect(events[1]['event_type']).to eq(webhook_payload['Event'])
      end

      it "sends a status update email" do
        expect(PostcardLifecycleMailer).to receive_message_chain(:status_update, :deliver_later)

        post '/webhook', params: webhook_payload, as: :json
      end
    end

    context "when a matching Postcard does not exist" do
      it "returns ok" do
        non_existent_id = 'non-existent-uuid-12345'
        webhook_payload['Data'][0]['PrintRecord'] = non_existent_id

        matching_postcard = Postcard.find_by(print_record_id: non_existent_id)
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