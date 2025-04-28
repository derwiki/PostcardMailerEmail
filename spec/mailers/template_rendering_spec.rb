require 'rails_helper'

RSpec.describe "Email Template Rendering", type: :view do
  describe 'PostcardLifecycleMailer template rendering' do
    # Create objects directly without factories
    let(:user) {
      double("User",
        email: 'test@example.com',
        addresses: [],
        postcards: double("Postcards", count: 1)
      )
    }
    
    let(:address) do
      double("Address", 
        name: "John Doe",
        address1: "123 Main St",
        address2: nil,
        city: "San Francisco",
        state: "CA",
        postal_code: "94103",
        nickname: "home"
      )
    end
    
    let(:postcard) do
      double("Postcard",
        id: 123,
        user: user,
        address: address,
        message: "Test message",
        image_url: "https://example.com/test.jpg",
        directmailers_events: [
          {
            'timestamp' => Time.current.iso8601,
            'event_type' => 'PostcardStatusUpdate',
            'data' => {
              'Data' => [
                {
                  'Status' => 'Mailed',
                  'Description' => 'Your postcard has been mailed.'
                }
              ]
            }
          }
        ],
        response_data: {
          'TrackingEvents' => [
            {
              'Status' => 'Created',
              'Description' => 'Postcard created',
              'Timestamp' => Time.current.iso8601
            }
          ]
        },
        status: 'Mailed'
      )
    end

    it 'creates a status update mail without template errors' do
      # This test simply creates a mail object and tries to render it
      mailer = PostcardLifecycleMailer.status_update(postcard)
      expect { mailer.body }.not_to raise_error
      expect { mailer.subject }.not_to raise_error
      expect { mailer.html_part.body.to_s }.not_to raise_error
      expect { mailer.text_part.body.to_s }.not_to raise_error
    end
    
    context 'with a lot of webhook events' do
      let(:postcard_with_many_events) do
        # Create a postcard with many webhook events
        # This helps test if the commented section for webhook events causes any issues
        events = 10.times.map do |i|
          {
            'timestamp' => (Time.current - i.hours).iso8601,
            'event_type' => "Event#{i}",
            'data' => { 'test' => "data#{i}" }
          }
        end
        
        double("Postcard",
          id: 456,
          user: user,
          address: address,
          message: "Test message with many events",
          image_url: "https://example.com/test2.jpg",
          directmailers_events: events,
          response_data: {
            'TrackingEvents' => [
              {
                'Status' => 'Created',
                'Description' => 'Postcard created',
                'Timestamp' => Time.current.iso8601
              }
            ]
          },
          status: 'Mailed'
        )
      end
      
      it 'renders the template with many webhook events without errors' do
        mailer = PostcardLifecycleMailer.status_update(postcard_with_many_events)
        expect { mailer.html_part.body.to_s }.not_to raise_error
        expect { mailer.text_part.body.to_s }.not_to raise_error
      end
    end
  end
end 