require 'rails_helper'

RSpec.describe SendgridPostHandler, type: :service do
  describe '#process' do
    let(:params) do
      {
        subject: 'Test Subject',
        from: 'test@example.com',
        text: 'Test body text',
        to: 'test@example.com'
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
  end
end 