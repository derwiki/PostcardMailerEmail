require "rails_helper"

RSpec.describe CommandMailer, type: :mailer do
  let(:user) { double("User", email: "user@example.com", verified?: true, addresses: []) }
  
  describe "adduser" do
    let(:recipient_email) { "recipient@example.com" }
    let(:original_subject) { "Add New Contact" }
    let(:from_email) { "adduser@postcardmailer.us" }
    let(:new_address) do
      double("Address",
        name: "John Smith",
        nickname: "john",
        address1: "123 Main St",
        address2: nil,
        city: "San Francisco",
        state: "CA",
        postal_code: "94110"
      )
    end
    let(:mail) { CommandMailer.adduser(user, recipient_email, original_subject, from_email, new_address) }

    it "renders the headers" do
      expect(mail.subject).to eq("Re: Add New Contact")
      expect(mail.to).to eq(["recipient@example.com"])
      expect(mail.from).to eq(["adduser@postcardmailer.us"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Recipient Address Added")
      expect(mail.body.encoded).to match("John Smith")
      expect(mail.body.encoded).to match("123 Main St")
      expect(mail.body.encoded).to match("San Francisco, CA 94110")
    end
  end

  describe "signup" do
    let(:original_subject) { "New Signup" }
    let(:from_email) { "signup@postcardmailer.us" }
    let(:mail) { CommandMailer.signup(user, original_subject, from_email) }

    it "renders the headers" do
      expect(mail.subject).to eq("Re: New Signup")
      expect(mail.to).to eq(["user@example.com"])
      expect(mail.from).to eq(["signup@postcardmailer.us"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Your account is pending verification")
      expect(mail.body.encoded).to match("GETTING STARTED")
      expect(mail.body.encoded).to match("ADD AN ADDRESS")
      expect(mail.body.encoded).to match("SEND A POSTCARD")
      expect(mail.body.encoded).to match("GET HELP")
    end
  end

  describe "verified" do
    let(:from_email) { "verified@postcardmailer.us" }
    let(:mail) { CommandMailer.verified(user, from_email) }

    it "renders the headers" do
      expect(mail.subject).to eq("Re: Your PostcardMailer.us Account")
      expect(mail.to).to eq(["user@example.com"])
      expect(mail.from).to eq(["verified@postcardmailer.us"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Great news!")
    end
  end
  
  describe "error" do
    let(:to_address) { "user@example.com" }
    let(:original_subject) { "Failed Command" }
    let(:error_message) { "Address could not be parsed from your email" }
    let(:from_email) { "help@postcardmailer.us" }
    let(:bcc_email) { "custom-bcc@example.com" }
    let(:mail) { CommandMailer.error(to_address, original_subject, error_message, from_email, bcc_email) }

    it "renders the headers" do
      expect(mail.subject).to eq("Re: Failed Command")
      expect(mail.to).to eq(["user@example.com"])
      expect(mail.from).to eq(["help@postcardmailer.us"])
      expect(mail.bcc).to eq(["custom-bcc@example.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Error")
      expect(mail.body.encoded).to match("Address could not be parsed from your email")
    end
    
    it "defaults to postcardmailer@kgk.host when bcc not specified" do
      mail_without_bcc = CommandMailer.error(to_address, original_subject, error_message, from_email)
      expect(mail_without_bcc.bcc).to eq(["postcardmailer@kgk.host"])
    end
  end

  describe "help" do
    let(:mail) { CommandMailer.help("user@example.com", "Help request", "help@postcardmailer.us") }

    it "renders the headers" do
      expect(mail.subject).to eq("Re: Help request")
      expect(mail.to).to eq(["user@example.com"])
      expect(mail.from).to eq(["help@postcardmailer.us"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("WELCOME TO POSTCARDMAILER.US")
      expect(mail.body.encoded).to match("Available Commands")
      expect(mail.body.encoded).to match("SIGN UP")
      expect(mail.body.encoded).to match("ADD AN ADDRESS")
      expect(mail.body.encoded).to match("SEND A POSTCARD")
      expect(mail.body.encoded).to match("GET HELP")
    end
  end
end
