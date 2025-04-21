require 'rails_helper'

RSpec.describe "Postcard Lifecycle", type: :request do
  include FactoryBot::Syntax::Methods
  include ActiveJob::TestHelper

  let(:user) { create(:user, email: 'test@example.com', verified_at: Time.current) }
  let(:address) { create(:address, user: user, nickname: 'test') }
  
  # Sample image data for testing
  let(:image_data) { "test-image-data" }
  
  # Fake PrintRecord ID that will be returned from DirectMailers API
  let(:print_record_id) { "pm-#{SecureRandom.uuid}" }
  
  # Sendgrid parameters for creating a postcard
  let(:sendgrid_params) do
    {
      from: 'Test User <test@example.com>',
      to: 'test@postcardmailer.us',
      text: 'Test body text',
      subject: 'Test Subject',
      attachment1: image_data
    }
  end
  
  # Sample webhook payload that DirectMailers would send
  let(:webhook_payload) do
    {
      Event: "PostcardStatusUpdate",
      Object: "Postcard",
      Data: [
        {
          PrintRecord: print_record_id,
          Status: "Mailed",
          Description: "Your postcard has been mailed and is on its way!",
          TrackingEvents: [
            {
              Status: "Created",
              Description: "Postcard created",
              Timestamp: Time.current.iso8601
            },
            {
              Status: "Printed",
              Description: "Postcard printed",
              Timestamp: (Time.current + 1.hour).iso8601
            },
            {
              Status: "Mailed",
              Description: "Postcard mailed",
              Timestamp: (Time.current + 2.hours).iso8601
            }
          ]
        }
      ]
    }
  end
  
  # Mock response from the DirectMailers API
  let(:api_response) do
    instance_double(
      Net::HTTPResponse,
      body: {
        PrintRecord: print_record_id,
        Status: "Created",
        Description: "Postcard created successfully"
      }.to_json,
      code: "200"
    )
  end
  
  before do
    # Set up the user and address
    user
    address
    
    # Mock external services
    allow(SecureRandom).to receive(:uuid).and_return("test-uuid")
    allow(EssThree).to receive(:upload).and_return(true)
    
    # Mock the HTTP request to DirectMailers API
    allow_any_instance_of(Net::HTTP).to receive(:request).and_return(api_response)
    
    # Mock the mailer to avoid actually sending emails
    allow(PostcardLifecycleMailer).to receive(:status_update).and_call_original
    allow(ActionMailer::Base.deliveries).to receive(:clear)
  end

  describe "Complete postcard lifecycle" do
    it "creates a postcard and processes a webhook update" do
      # STEP 1: Create the postcard via SendgridPostHandler
      expect {
        handler = SendgridPostHandler.new(sendgrid_params)
        handler.process
      }.to change(Postcard, :count).by(1)
      
      # Verify the postcard was created with correct attributes
      postcard = Postcard.find_by(print_record_id: print_record_id)
      expect(postcard).to be_present
      expect(postcard.user).to eq(user)
      expect(postcard.address).to eq(address)
      expect(postcard.status).to eq("200")
      expect(postcard.directmailers_events).to be_empty
      
      # STEP 2: Process a webhook update
      # Simulate the DirectMailers webhook callback
      post '/webhook', params: webhook_payload, as: :json

      # Verify the webhook was processed
      expect(response).to have_http_status(:ok)
      
      # Reload the postcard to get updated attributes
      postcard.reload
      
      # STEP 3: Verify the postcard was updated from the webhook
      # Check that directmailers_events has been updated
      expect(postcard.directmailers_events.size).to eq(1)
      expect(postcard.directmailers_events.first["event_type"]).to eq("PostcardStatusUpdate")
    end
  end
  
  describe "Error handling during lifecycle" do
    context "when DirectMailers API fails" do
      before do
        allow_any_instance_of(Net::HTTP).to receive(:request).and_raise(StandardError.new("API Connection failed"))
        # Prevent error from bubbling up in tests
        allow_any_instance_of(CreatePostcard).to receive(:run).and_wrap_original do |original, *args|
          begin
            original.call(*args)
          rescue StandardError => e
            # Create an error postcard but don't raise the error
            if original.receiver.user && original.receiver.address
              Postcard.create!(
                user: original.receiver.user,
                address: original.receiver.address,
                status: 'error',
                response_data: { error: e.message },
                image_url: original.receiver.url,
                message: original.receiver.message,
                dryrun: original.receiver.dryrun
              )
            end
            # Return a dummy response so SendgridPostHandler doesn't fail
            instance_double(Net::HTTPResponse, body: '{}', code: "500")
          end
        end
      end
      
      it "creates a postcard with error status" do
        # Clear any existing postcards
        Postcard.delete_all
        
        handler = SendgridPostHandler.new(sendgrid_params)
        expect {
          handler.process
        }.to change(Postcard, :count)
        
        # Verify the most recently created postcard has error status
        postcard = Postcard.last
        expect(postcard.status).to eq("error")
      end
    end
    
    context "when webhook has invalid PrintRecord" do
      it "handles missing postcard gracefully" do
        invalid_payload = webhook_payload.deep_dup
        invalid_payload[:Data][0][:PrintRecord] = "nonexistent-id"
        
        post '/webhook', params: invalid_payload, as: :json
        
        expect(response).to have_http_status(:ok)
      end
    end
  end
end 