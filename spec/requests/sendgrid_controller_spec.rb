require "rails_helper"

RSpec.describe "SendgridController", type: :request do
  include FactoryBot::Syntax::Methods

  let(:user) do
    create(:user, email: "test@example.com", verified_at: Time.current)
  end
  let(:address) { create(:address, user: user, nickname: "test") }
  let(:valid_params) do
    {
      from: "Test User <test@example.com>",
      to: "test@postcardmailer.us",
      text: "Test body text",
      subject: "Test caption",
      attachment1: "test-image-data",
      SPF: "pass",
      dkim: "{example.com : pass}"
    }
  end

  let(:mail_double) { double("Mail", deliver_now: true, bcc: nil) }

  before do
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:warn)
    allow(SecureRandom).to receive(:uuid).and_return("test-uuid")
    allow(EssThree).to receive(:upload)
    allow(CreatePostcard).to receive(:new).and_return(
      double(run: double(body: '{"Success": true}'))
    )
    allow(AddressExtractor).to receive(:extract).and_return(
      [
        "Sarah Johnson",
        double(
          number: "1234",
          street: "Maple",
          street_type: "Avenue",
          unit: "Apt 5B",
          city: "San Francisco",
          state: "CA",
          postal_code: "94110"
        )
      ]
    )
    allow(Date).to receive(:today).and_return(Date.new(2025, 4, 16))
    allow(CommandMailer).to receive(:help).and_return(mail_double)
    allow(CommandMailer).to receive(:error).and_return(mail_double)
  end

  it "processes a normal postcard request" do
    user
    address
    post "/sendgrid", params: valid_params
    expect(response).to have_http_status(:ok)
    expect(EssThree).to have_received(:upload)
    expect(CreatePostcard).to have_received(:new)
  end

  it "handles help requests" do
    post "/sendgrid", params: valid_params.merge(to: "help@postcardmailer.us")
    expect(response).to have_http_status(:ok)
    expect(CommandMailer).to have_received(:help)
  end

  it "handles signup requests" do
    post "/sendgrid",
         params:
           valid_params.merge(
             to: "signup@postcardmailer.us",
             from: "New User <new@example.com>",
             subject: "Sarah Johnson"
           )
    expect(response).to have_http_status(:ok)
    # User and address should be created
    expect(User.find_by(email: "new@example.com")).to be_present
    expect(Address.find_by(nickname: "sarah")).to be_present
  end

  it "handles adduser requests" do
    user.update(verified_at: Time.current)
    post "/sendgrid", params: valid_params.merge(subject: "adduser")
    expect(response).to have_http_status(:ok)
    # Should call CreatePostcard or similar logic
  end

  it "handles approve requests from authorized sender" do
    post "/sendgrid",
         params:
           valid_params.merge(
             to: "approve@postcardmailer.us",
             from: "Derek <derewecki@gmail.com>"
           )
    expect(response).to have_http_status(:ok)
    # Should process approve logic
  end

  it "handles cancel requests" do
    user
    post "/sendgrid", params: valid_params.merge(to: "cancel@postcardmailer.us")
    expect(response).to have_http_status(:ok)
    # Should process cancel logic
  end

  it "handles authentication failure" do
    post "/sendgrid", params: valid_params.merge(SPF: "fail", dkim: "fail")
    expect(response).to have_http_status(:ok)
    expect(CommandMailer).to have_received(:error)
  end
end
