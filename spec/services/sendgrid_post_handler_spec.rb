require 'rails_helper'

RSpec.describe SendgridPostHandler, type: :service do
  describe '#process' do
    let(:params) do
      {
        subject: 'Test Subject',
        from: 'test@example.com',
        text: 'Test body text',
        to: 'test@example.com',
        attachment1: 'test-image-data'
      }
    end

    context 'when address extraction fails' do
      before do
        allow(AddressExtractor).to receive(:extract).and_return(['Test Name', nil])
        allow(Rails.logger).to receive(:info)
      end

      it 'logs the bad address message and returns early' do
        handler = described_class.new(params)
        handler.process

        expect(Rails.logger).to have_received(:info).with("SendgridPostHandler bad address: #{nil}")
      end
    end

    context 'when address is valid but attachment is missing' do
      let(:mock_address) { double('Address', number: '123', street: 'Main', street_type: 'St', unit_prefix: '', unit: '', city: 'San Francisco', state: 'CA', postal_code: '94110') }
      
      before do
        allow(AddressExtractor).to receive(:extract).and_return(['Test Name', mock_address])
        allow(Rails.logger).to receive(:info)
      end

      it 'logs the missing attachment message and returns early' do
        handler = described_class.new(params.except(:attachment1))
        handler.process

        expect(Rails.logger).to have_received(:info).with("SendgridPostHandler missing attachment")
      end
    end

    context 'when everything is valid' do
      let(:mock_address) { double('Address', number: '123', street: 'Main', street_type: 'St', unit_prefix: '', unit: '', city: 'San Francisco', state: 'CA', postal_code: '94110') }
      let(:mock_create_postcard) { instance_double(CreatePostcard) }
      let(:mock_response) { double('Response', body: 'success') }
      let(:today) { Date.new(2025, 4, 16) }
      
      before do
        allow(AddressExtractor).to receive(:extract).and_return(['Test Name', mock_address])
        allow(Rails.logger).to receive(:info)
        allow(SecureRandom).to receive(:uuid).and_return('test-uuid')
        allow(EssThree).to receive(:upload).and_return(true)
        allow(CreatePostcard).to receive(:new).and_return(mock_create_postcard)
        allow(mock_create_postcard).to receive(:run).and_return(mock_response)
        allow(Date).to receive(:today).and_return(today)
      end

      it 'processes the postcard successfully' do
        handler = described_class.new(params)
        handler.process

        # Verify S3 upload
        expect(EssThree).to have_received(:upload).with('test-uuid.jpg', 'test-image-data')
        
        # Verify CreatePostcard was called with correct arguments
        expected_from_address = {
          name: "Postcardmailer.us",
          address1: "1198 S Van Ness Ave #80417",
          address2: nil,
          city: "San Francisco",
          state: "CA",
          postal_code: "94110"
        }
        expected_to_address = {
          name: 'Test Name',
          address1: '123 Main St ',
          address2: nil,
          city: 'San Francisco',
          state: 'CA',
          postal_code: '94110'
        }
        expect(CreatePostcard).to have_received(:new).with(
          expected_from_address,
          expected_to_address,
          'https://s3.amazonaws.com/postcardmailer.us/test-uuid.jpg',
          "Test Subject\n\nApril 16th, 2025",
          dryrun: false
        )
        
        # Verify the response was logged
        expect(Rails.logger).to have_received(:info).with("SendgridPostHandler DirectMail response: success")
      end
    end
  end
end 