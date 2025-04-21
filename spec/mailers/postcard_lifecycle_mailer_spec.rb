require 'rails_helper'

RSpec.describe PostcardLifecycleMailer, type: :mailer do
  include FactoryBot::Syntax::Methods
  
  describe 'status_update' do
    let(:user) { create(:user, email: 'test@example.com') }
    let(:address) { create(:address, user: user) }
    let(:timestamp) { Time.current.iso8601 }
    
    let(:postcard) do
      create(:postcard, 
        user: user,
        address: address,
        message: 'Test message',
        directmailers_events: [
          {
            'timestamp' => timestamp,
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
              'Timestamp' => (Time.current - 2.days).iso8601
            },
            {
              'Status' => 'Mailed',
              'Description' => 'Postcard mailed',
              'Timestamp' => (Time.current - 1.day).iso8601
            }
          ]
        }
      )
    end

    let(:mail) { PostcardLifecycleMailer.status_update(postcard) }

    it 'renders the email headers' do
      expect(mail.subject).to eq('Re: Test message')
      expect(mail.to).to eq([user.email])
    end

    it 'successfully renders the html template without errors' do
      expect { mail.html_part.body.to_s }.not_to raise_error
    end

    it 'successfully renders the text template without errors' do
      expect { mail.text_part.body.to_s }.not_to raise_error
    end

    it 'includes the status in the html body' do
      expect(mail.html_part.body.to_s).to include('Mailed')
    end

    it 'includes the status in the text body' do
      expect(mail.text_part.body.to_s).to include('Mailed')
    end

    it 'includes tracking events in the html body' do
      expect(mail.html_part.body.to_s).to include('Tracking History')
    end

    it 'includes tracking events in the text body' do
      expect(mail.text_part.body.to_s).to include('TRACKING HISTORY')
    end

    context 'with direct mailers events' do
      it 'includes webhook events in the html body' do
        expect(mail.html_part.body.to_s).to include('Webhook Event History')
      end
    end

    context 'with empty direct mailers events' do
      let(:postcard) do
        create(:postcard, 
          user: user,
          address: address,
          message: 'Empty events test',
          directmailers_events: [],
          response_data: {}
        )
      end

      it 'still renders the template without errors' do
        expect { mail.html_part.body.to_s }.not_to raise_error
        expect { mail.text_part.body.to_s }.not_to raise_error
      end
    end
  end
end 