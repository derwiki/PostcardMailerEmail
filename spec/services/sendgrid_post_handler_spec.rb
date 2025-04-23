require 'rails_helper'

RSpec.describe SendgridPostHandler do
  include FactoryBot::Syntax::Methods

  let(:user) { create(:user, email: 'test@example.com', verified_at: Time.current) }
  let(:address) { create(:address, user: user, nickname: 'test') }
  let(:params) do
    {
      from: 'Test User <test@example.com>',
      to: 'test@postcardmailer.us',
      text: 'Test body text',
      subject: 'Test caption',
      attachment1: 'test-image-data'
    }
  end
  let(:handler) { described_class.new(params) }

  let(:valid_params) do
    {
      from: "User <user@example.com>",
      to: "help@postcardmailer.us",
      subject: "Help Request",
      text: "This is a test message",
      SPF: "pass",
      dkim: "{@example.com : pass}"
    }
  end
  
  let(:mail_double) { 
    double("Mail", 
      deliver_now: true, 
      bcc: nil
    ).tap do |mail|
      allow(mail).to receive(:bcc=)
    end
  }

  before do
    allow(Rails.logger).to receive(:info)
    allow(SecureRandom).to receive(:uuid).and_return('test-uuid')
    allow(EssThree).to receive(:upload)
    allow(CreatePostcard).to receive(:new).and_return(double(run: double(body: 'success')))
    allow(AddressExtractor).to receive(:extract).and_return(['Sarah Johnson', double(
      street: '1234 Maple Avenue',
      unit: 'Apt 5B',
      city: 'San Francisco',
      state: 'CA',
      postal_code: '94110'
    )])
    allow(Date).to receive(:today).and_return(Date.new(2025, 4, 16))
    allow(CommandMailer).to receive(:help).and_return(mail_double)
    allow(CommandMailer).to receive(:error).and_return(mail_double)
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
          "Test caption",
          dryrun: false,
          user: user,
          address: address
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
          subject: 'Test caption'
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
          text: 'Sarah Johnson\n1234 Maple Avenue Apt 5B\nSan Francisco, CA 94110',
          subject: 'Sarah Johnson'
        }
      end

      it 'creates a new user and address' do
        expect { handler.process }.to change(User, :count).by(1)
          .and change(Address, :count).by(1)

        new_user = User.last
        new_address = Address.last

        expect(new_user.email).to eq('new@example.com')
        expect(new_address.nickname).to eq('sarah')
        expect(new_address.name).to eq('Sarah Johnson')
        expect(new_address.address1).to eq('1234 Maple Avenue')
        expect(new_address.address2).to eq('Apt 5B')
        expect(new_address.city).to eq('San Francisco')
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
          to: 'home@postcardmailer.us',
          subject: 'adduser',
          text: 'Sarah Johnson\n1234 Maple Avenue Apt 5B\nSan Francisco, CA 94110'
        }
      end

      before do
        user
        allow(AddressExtractor).to receive(:extract).and_return(['Sarah Johnson', double(
          street: '1234 Maple Avenue',
          unit: 'Apt 5B',
          city: 'San Francisco',
          state: 'CA',
          postal_code: '94110'
        )])
      end

      it 'creates a new address for existing user' do
        expect { handler.process }.to change(Address, :count).by(1)

        new_address = Address.last
        expect(new_address.user).to eq(user)
        expect(new_address.nickname).to eq('home')
        expect(new_address.name).to eq('Sarah Johnson')
        expect(new_address.address1).to eq('1234 Maple Avenue')
        expect(new_address.address2).to eq('Apt 5B')
        expect(new_address.city).to eq('San Francisco')
        expect(new_address.state).to eq('CA')
        expect(new_address.postal_code).to eq('94110')
      end

      context 'when user does not exist' do
        let(:params) do
          {
            from: 'Unknown User <unknown@example.com>',
            to: 'home@postcardmailer.us',
            text: 'Test body text',
            subject: 'adduser'
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

      context 'when subject is not adduser' do
        let(:params) do
          {
            from: 'Test User <test@example.com>',
            to: 'home@postcardmailer.us',
            text: 'Test body text',
            subject: 'not adduser'
          }
        end

        it 'does not create a new address' do
          expect { handler.process }.to change(Address, :count).by(0)
        end
      end
    end

    context 'when handling help request' do
      let(:params) do
        {
          from: 'Test User <test@example.com>',
          to: 'help@postcardmailer.us',
          text: 'How do I use this service?',
          subject: 'Help Request'
        }
      end

      it 'sends a help email to the sender' do
        handler.process
        
        expect(CommandMailer).to have_received(:help).with(
          'test@example.com',
          'Help Request',
          'help@postcardmailer.us'
        )
      end
    end

    context 'when authentication passes' do
      it 'processes the help request' do
        params_with_auth = {
          from: "Test User <test@example.com>",
          to: "help@postcardmailer.us",
          text: "Test body text",
          subject: "Help Request",
          SPF: "pass",
          dkim: "{@example.com : pass}"
        }
        handler = described_class.new(params_with_auth)
        
        expect(handler).to receive(:handle_help_request)
        handler.process
      end
    end

    context 'when SPF fails' do
      it 'sends an error email and returns early' do
        params_with_failed_spf = valid_params.merge(SPF: "fail")
        handler = described_class.new(params_with_failed_spf)
        
        expect(handler).not_to receive(:handle_help_request)
        expect(CommandMailer).to receive(:error).with(
          "user@example.com",
          "Email Authentication Failed",
          "We couldn't verify the authenticity of your email. This may indicate spoofing or unauthorized use of the email address.",
          "help@postcardmailer.us",
          "postcardmailer@kgk.host"
        ).and_return(mail_double)
        
        handler.process
      end
    end

    context 'when DKIM fails' do
      it 'sends an error email and returns early' do
        params_with_failed_dkim = valid_params.merge(dkim: "{@example.com : fail}")
        handler = described_class.new(params_with_failed_dkim)
        
        expect(handler).not_to receive(:handle_help_request)
        expect(CommandMailer).to receive(:error).with(
          "user@example.com",
          "Email Authentication Failed",
          "We couldn't verify the authenticity of your email. This may indicate spoofing or unauthorized use of the email address.",
          "help@postcardmailer.us",
          "postcardmailer@kgk.host"
        ).and_return(mail_double)
        
        handler.process
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

  describe '#spf_passes?' do
    it 'returns true when SPF is "pass"' do
      handler = described_class.new(SPF: "pass")
      expect(handler.send(:spf_passes?)).to be true
    end

    it 'returns false when SPF is not "pass"' do
      handler = described_class.new(SPF: "fail")
      expect(handler.send(:spf_passes?)).to be false
    end

    it 'returns false when SPF is nil' do
      handler = described_class.new(SPF: nil)
      expect(handler.send(:spf_passes?)).to be false
    end
  end

  describe '#dkim_passes?' do
    it 'returns true when dkim contains "pass"' do
      handler = described_class.new(dkim: "{@example.com : pass}")
      expect(handler.send(:dkim_passes?)).to be true
    end

    it 'returns false when dkim does not contain "pass"' do
      handler = described_class.new(dkim: "{@example.com : fail}")
      expect(handler.send(:dkim_passes?)).to be false
    end

    it 'returns false when dkim is nil' do
      handler = described_class.new(dkim: nil)
      expect(handler.send(:dkim_passes?)).to be false
    end
  end
end 