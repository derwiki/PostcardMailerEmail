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
    allow(AddressExtractor).to receive(:extract).and_return(['Test User', double(
      street: '123 Test St',
      unit: nil,
      city: 'Test City',
      state: 'CA',
      postal_code: '94110'
    )])
    allow(Date).to receive(:today).and_return(Date.new(2025, 4, 16))
  end

  describe '#process' do
    context 'when user and address exist' do
      before do
        user
        address
      end

      it 'processes the postcard successfully' do
        handler.process

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
      it 'returns early without processing postcard' do
        handler.process

        expect(EssThree).not_to have_received(:upload)
        expect(CreatePostcard).not_to have_received(:new)
      end
    end

    context 'when user exists but address does not' do
      before do
        user
      end

      it 'returns early without processing postcard' do
        handler.process

        expect(EssThree).not_to have_received(:upload)
        expect(CreatePostcard).not_to have_received(:new)
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

      it 'returns early without processing postcard' do
        handler.process

        expect(EssThree).not_to have_received(:upload)
        expect(CreatePostcard).not_to have_received(:new)
      end
    end

    context 'when handling signup request' do
      let(:params) do
        {
          from: 'New User <new@example.com>',
          to: 'signup@postcardmailer.us',
          text: '123 Test St, Test City, CA 94110',
          subject: 'New User'
        }
      end

      it 'creates a new user and address' do
        expect { handler.process }.to change(User, :count).by(1)
          .and change(Address, :count).by(1)

        new_user = User.last
        new_address = Address.last

        expect(new_user.email).to eq('new@example.com')
        expect(new_address.nickname).to eq('new')
        expect(new_address.name).to eq('New User')
        expect(new_address.address1).to eq('123 Test St')
        expect(new_address.city).to eq('Test City')
        expect(new_address.state).to eq('CA')
        expect(new_address.postal_code).to eq('94110')
      end

      context 'when user already exists' do
        before do
          create(:user, email: 'new@example.com')
        end

        it 'does not create a new user or address' do
          expect { handler.process }.to change(User, :count).by(0)
            .and change(Address, :count).by(0)
        end
      end

      context 'when address cannot be parsed' do
        before do
          allow(AddressExtractor).to receive(:extract).and_return([nil, nil])
        end

        it 'does not create a new user or address' do
          expect { handler.process }.to change(User, :count).by(0)
            .and change(Address, :count).by(0)
        end
      end
    end

    context 'when handling adduser request' do
      let(:params) do
        {
          from: 'Test User <test@example.com>',
          to: 'adduser@postcardmailer.us',
          text: 'Test body text',
          subject: 'New Address User'
        }
      end

      before do
        user
        allow(AddressExtractor).to receive(:extract).and_return(['New Address User', double(
          street: '123 Test St',
          unit: nil,
          city: 'Test City',
          state: 'CA',
          postal_code: '94110'
        )])
      end

      it 'creates a new address for existing user' do
        expect { handler.process }.to change(Address, :count).by(1)

        new_address = Address.last
        expect(new_address.user).to eq(user)
        expect(new_address.nickname).to eq('new')
        expect(new_address.name).to eq('New Address User')
        expect(new_address.address1).to eq('123 Test St')
        expect(new_address.city).to eq('Test City')
        expect(new_address.state).to eq('CA')
        expect(new_address.postal_code).to eq('94110')
      end

      context 'when user does not exist' do
        let(:params) do
          {
            from: 'Unknown User <unknown@example.com>',
            to: 'adduser@postcardmailer.us',
            text: 'Test body text',
            subject: 'New Address User'
          }
        end

        it 'does not create a new address' do
          expect { handler.process }.to change(Address, :count).by(0)
        end
      end

      context 'when address cannot be parsed' do
        before do
          allow(AddressExtractor).to receive(:extract).and_return([nil, nil])
        end

        it 'does not create a new address' do
          expect { handler.process }.to change(Address, :count).by(0)
        end
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