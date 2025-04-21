require 'rails_helper'

RSpec.describe EmailHelper do
  let(:test_class) { Class.new { include EmailHelper } }
  let(:instance) { test_class.new }

  describe '#extract_email_from_sendgrid_from' do
    subject { instance.extract_email_from_sendgrid_from(from_field) }

    context 'with standard format' do
      let(:from_field) { 'John Doe <john@example.com>' }
      it { is_expected.to eq 'john@example.com' }
    end

    context 'with no display name' do
      let(:from_field) { '<jane@example.com>' }
      it { is_expected.to eq 'jane@example.com' }
    end

    context 'with complex display name' do
      let(:from_field) { 'Dr. John Q. Doe, Jr. <john.q.doe@example.com>' }
      it { is_expected.to eq 'john.q.doe@example.com' }
    end

    context 'with special characters in display name' do
      let(:from_field) { '"Doe, John (Sales)" <john.doe@example.com>' }
      it { is_expected.to eq 'john.doe@example.com' }
    end

    context 'with email containing plus addressing' do
      let(:from_field) { 'John Doe <john+test@example.com>' }
      it { is_expected.to eq 'john+test@example.com' }
    end

    context 'with multiple angle brackets' do
      let(:from_field) { 'John <Dev> Doe <john@example.com>' }
      it { is_expected.to eq 'john@example.com' }
    end

    context 'with invalid formats' do
      context 'when missing angle brackets' do
        let(:from_field) { 'john@example.com' }
        it { is_expected.to be_nil }
      end

      context 'when empty angle brackets' do
        let(:from_field) { 'John Doe <>' }
        it { is_expected.to be_nil }
      end

      context 'when nil input' do
        let(:from_field) { nil }
        it { is_expected.to be_nil }
      end

      context 'when empty string' do
        let(:from_field) { '' }
        it { is_expected.to be_nil }
      end

      context 'when unmatched brackets' do
        let(:from_field) { 'John Doe <john@example.com' }
        it { is_expected.to be_nil }
      end
    end
  end
end 