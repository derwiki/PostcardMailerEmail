require 'rails_helper'

RSpec.describe SendgridPostHandler do
  include FactoryBot::Syntax::Methods

  let(:user) { create(:user, email: 'test@example.com') }
  let(:address) { create(:address, user: user, nickname: 'test') }
  let(:params) do
    {
      from: 'Test User <test@example.com>',
      to: 'test@postcardmailer.us',
      text: 'Test body text',
      subject: 'Test Subject',
      attachment1: 'test-image-data'
    }
  end
  let(:handler) { described_class.new(params) }

  before do
    allow(Rails.logger).to receive(:info)
    allow(SecureRandom).to receive(:uuid).and_return('test-uuid')
    allow(EssThree).to receive(:upload)
    allow(CreatePostcard).to receive(:new).and_return(double(run: double(body: 'success')))
  end

  describe '#process' do
    context 'when user and address exist' do
      before do
        user
        address
      end

      it 'processes the postcard successfully' do
        handler.process

        expect(Rails.logger).to have_received(:info).with("SendgridPostHandler params: #{params}")
        expect(Rails.logger).to have_received(:info).with("SendgridPostHandler params.keys: #{params.keys}")
        expect(Rails.logger).to have_received(:info).with("SendgridPostHandler subject: Test Subject\n\nApril 16th, 2025")
        expect(Rails.logger).to have_received(:info).with("SendgridPostHandler found address for nickname: test")
        expect(EssThree).to have_received(:upload).with('test-uuid.jpg', 'test-image-data')
        expect(CreatePostcard).to have_received(:new).with(
          {
            name: "Postcardmailer.us",
            address1: "1198 S Van Ness Ave #80417",
            address2: nil,
            city: "San Francisco",
            state: "CA",
            postal_code: "94110"
          },
          {
            name: address.name,
            address1: address.address1,
            address2: address.address2,
            city: address.city,
            state: address.state,
            postal_code: address.postal_code
          },
          "https://s3.amazonaws.com/postcardmailer.us/test-uuid.jpg",
          "Test Subject\n\nApril 16th, 2025",
          dryrun: false
        )
      end
    end

    context 'when user does not exist' do
      it 'logs the user not found message and returns early' do
        handler.process

        expect(Rails.logger).to have_received(:info).with("SendgridPostHandler user not found for email: test@example.com")
        expect(EssThree).not_to have_received(:upload)
      end
    end

    context 'when user exists but address does not' do
      before do
        user
      end

      it 'logs the address not found message and returns early' do
        handler.process

        expect(Rails.logger).to have_received(:info).with("SendgridPostHandler address not found for nickname: test")
        expect(EssThree).not_to have_received(:upload)
      end
    end

    context 'when attachment is missing' do
      let(:params) do
        {
          from: 'Test User <test@example.com>',
          to: 'test@postcardmailer.us',
          text: 'Test body text',
          subject: 'Test Subject'
        }
      end

      before do
        user
        address
      end

      it 'logs the missing attachment message and returns early' do
        handler.process

        expect(Rails.logger).to have_received(:info).with("SendgridPostHandler missing attachment")
        expect(EssThree).not_to have_received(:upload)
      end
    end
  end

  describe '#lookup_user_and_address' do
    context 'when user and address exist' do
      before do
        user
        address
      end

      it 'returns the user and address' do
        found_user, found_address = handler.send(:lookup_user_and_address)
        expect(found_user).to eq(user)
        expect(found_address).to eq(address)
      end
    end

    context 'when user does not exist' do
      it 'returns nil for both' do
        found_user, found_address = handler.send(:lookup_user_and_address)
        expect(found_user).to be_nil
        expect(found_address).to be_nil
      end
    end

    context 'when user exists but address does not' do
      before do
        user
      end

      it 'returns nil for both' do
        found_user, found_address = handler.send(:lookup_user_and_address)
        expect(found_user).to be_nil
        expect(found_address).to be_nil
      end
    end
  end
end 