require "rails_helper"

describe AddressExtractor do
  let(:text_body) do
    "John Smith at 123 Main Street Apt 4B, Boston Massachusetts"
  end
  let(:completion_response) do
    {
      "choices" => [
        {
          "message" => {
            "content" => "John Smith\n123 Main Street Apt 4B\nBoston, MA 02108"
          }
        }
      ]
    }
  end
  let(:address_obj) do
    double(
      number: "123",
      street: "Main Street",
      street_type: nil,
      unit: "Apt 4B",
      city: "Boston",
      state: "MA",
      postal_code: "02108"
    )
  end

  before do
    allow(Net::HTTP).to receive(:post).and_return(
      double(body: completion_response.to_json)
    )
    allow(JSON).to receive(:parse).and_call_original
    allow(JSON).to receive(:parse).with(completion_response.to_json).and_return(
      completion_response
    )
    allow(Rails.logger).to receive(:info)
    allow(StreetAddress::US).to receive(:parse).and_return(address_obj)
    allow_any_instance_of(AddressExtractor).to receive(:puts)
    allow(AddressExtractor).to receive(:puts)
  end

  describe ".generate_address_completion" do
    it "returns formatted address completions from OpenAI" do
      completions = described_class.generate_address_completion(text_body)
      expect(completions).to eq(
        ["John Smith\n123 Main Street Apt 4B\nBoston, MA 02108"]
      )
    end

    it "raises if OpenAI returns an error" do
      error_response = { "error" => { "message" => "API error" } }
      allow(Net::HTTP).to receive(:post).and_return(
        double(body: error_response.to_json)
      )
      allow(JSON).to receive(:parse).with(error_response.to_json).and_return(
        error_response
      )
      expect {
        described_class.generate_address_completion(text_body)
      }.to raise_error(/OpenAI API Error/)
    end

    it "raises if no completions returned" do
      empty_response = { "choices" => [] }
      allow(Net::HTTP).to receive(:post).and_return(
        double(body: empty_response.to_json)
      )
      allow(JSON).to receive(:parse).with(empty_response.to_json).and_return(
        empty_response
      )
      expect {
        described_class.generate_address_completion(text_body)
      }.to raise_error(/No completion returned/)
    end
  end

  describe ".extract" do
    it "returns name and parsed address" do
      expect(described_class).to receive(:generate_address_completion).with(
        text_body,
        "gpt-3.5-turbo"
      ).and_return(["John Smith\n123 Main Street Apt 4B\nBoston, MA 02108"])
      expect(StreetAddress::US).to receive(:parse).with(
        "123 Main Street Apt 4B, Boston, MA 02108"
      ).and_return(address_obj)
      name, address = described_class.extract(text_body)
      expect(name).to eq("John Smith")
      expect(address).to eq(address_obj)
    end
  end
end
