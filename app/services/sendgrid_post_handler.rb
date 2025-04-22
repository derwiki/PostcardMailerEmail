require_relative 'create_postcard'
require_relative 'address_extractor'
require_relative '../models/concerns/email_helper'

class SendgridPostHandler
  include EmailHelper

  def initialize(params)
    @params = params
  end

  def process
    Rails.logger.info "SendgridPostHandler params: #{@params}"
    Rails.logger.info "SendgridPostHandler params.keys: #{@params.keys}"

    bodytext = @params[:text]
    from_email = extract_email_from_sendgrid_from(@params[:from])

    if !bodytext
      Rails.logger.info "SendgridPostHandler empty body"
      # Extract from email to send an error notification
      CommandMailer.error(
        from_email,
        "Empty Email Body",
        "Your email did not contain any text content. Please include the necessary information in your email body.",
        @params[:to] || "help@postcardmailer.us"
      ).deliver_now
      Rails.logger.info "SendgridPostHandler sent 'empty body' error email to: #{from_email}"
      return
    end

    # Check if this is a signup request
    if @params[:to] == "signup@postcardmailer.us"
      handle_signup_request
      return
    end

    # Check if this is an adduser request
    if @params[:to] == "adduser@postcardmailer.us"
      handle_adduser_request
      return
    end

    # For all other requests, check if user is verified
    user = User.find_by(email: from_email)

    unless user
      Rails.logger.info "SendgridPostHandler user not found for email: #{from_email}"
      CommandMailer.error(
        from_email,
        @params[:subject],
        "We couldn't find an account with your email address. Please sign up first by sending an email to signup@postcardmailer.us.",
        @params[:to] || "help@postcardmailer.us"
      ).deliver_now
      Rails.logger.info "SendgridPostHandler sent 'user not found' error email to: #{from_email}"
      return
    end
    
    unless user.verified?
      Rails.logger.info "SendgridPostHandler user not verified: #{from_email}"
      CommandMailer.error(
        from_email,
        @params[:subject], 
        "Your account is pending verification. We'll notify you once your account has been verified and you can start sending postcards.", 
        @params[:to]
      ).deliver_now
      Rails.logger.info "SendgridPostHandler sent 'not verified' error email to: #{from_email}"
      return
    end

    handle_mail_postcard_request
  end

  private

  def handle_signup_request
    # Extract email from from field
    from_email = extract_email_from_sendgrid_from(@params[:from])
    
    # Check if user already exists
    if User.exists?(email: from_email)
      Rails.logger.info "SendgridPostHandler user already exists: #{from_email}"
      CommandMailer.error(
        from_email,
        @params[:subject], 
        "An account with this email already exists. If you've forgotten your password, please use the password reset option on the website.", 
        @params[:to]
      ).deliver_now
      Rails.logger.info "SendgridPostHandler sent 'user already exists' error email to: #{from_email}"
      return
    end

    # Extract name from subject line
    name = @params[:subject].strip
    if name.empty?
      Rails.logger.info "SendgridPostHandler empty name in subject"
      CommandMailer.error(
        from_email,
        "Signup Error",
        "Please include your full name in the subject line when signing up.",
        @params[:to]
      ).deliver_now
      Rails.logger.info "SendgridPostHandler sent 'empty name' error email to: #{from_email}"
      return
    end

    # Prepend name to body text for address extraction
    body_with_name = "#{name}\n#{@params[:text]}"

    # Extract address from body
    extracted_name, address = AddressExtractor.extract(body_with_name)
    unless address
      Rails.logger.info "SendgridPostHandler could not parse address from body"
      CommandMailer.error(
        from_email,
        @params[:subject],
        "We couldn't parse a valid address from your email. Please include your complete mailing address (street, city, state, and ZIP code) in the email body.",
        @params[:to]
      ).deliver_now
      Rails.logger.info "SendgridPostHandler sent 'invalid address' error email to: #{from_email}"
      return
    end

    # Create user and their first address
    user = User.create!(email: from_email)
    new_address = user.addresses.create!(
      nickname: name.split.first.downcase,
      name: name,
      address1: address.street,
      address2: address.unit,
      city: address.city,
      state: address.state,
      postal_code: address.postal_code
    )

    Rails.logger.info "SendgridPostHandler created new user and address: #{new_address.inspect}"
    
    # Send signup confirmation email with original subject for threading
    # Use the original 'to' email as the from address for proper threading
    CommandMailer.signup(user, @params[:subject], @params[:to]).deliver_now
    Rails.logger.info "SendgridPostHandler sent signup confirmation email to: #{user.email}"
  end

  def handle_mail_postcard_request
    # Use the original subject as the message without adding date
    message = @params[:subject]
    Rails.logger.info "SendgridPostHandler message: #{message}"

    user, address = lookup_user_and_address
    return unless user && address

    if !@params[:attachment1]
      Rails.logger.info "SendgridPostHandler missing attachment"
      CommandMailer.error(
        user.email,
        @params[:subject], 
        "Your email is missing an image attachment. Please attach an image to your email to create a postcard.", 
        @params[:to]
      ).deliver_now
      Rails.logger.info "SendgridPostHandler sent 'missing attachment' error email to: #{user.email}"
      return
    end

    to_address = {
      name: address.name,
      address1: address.address1,
      address2: address.address2,
      city: address.city,
      state: address.state,
      postal_code: address.postal_code
    }
    Rails.logger.info "SendgridPostHandler to_address: #{to_address.inspect}"

    from_address = {
      name: "Postcardmailer.us",
      address1: "1198 S Van Ness Ave #80417",
      address2: nil,
      city: "San Francisco",
      state: "CA",
      postal_code: "94110"
    }

    # Upload the image to S3 and store the URL
    key = "#{SecureRandom.uuid}.jpg"
    image = EssThree.upload(key, @params[:attachment1])
    image_url = "https://s3.amazonaws.com/postcardmailer.us/#{key}"
    Rails.logger.info "SendgridPostHandler uploaded image: #{image_url}"

    dryrun = ENV["DRYRUN"] == "true"
    Rails.logger.info "SendgridPostHandler dryrun: #{dryrun}"

    # Create the postcard with the image_url and message
    resp = CreatePostcard.new(
      from_address,
      to_address,
      image_url,
      message,
      dryrun: dryrun,
      user: user,
      address: address
    ).run
    Rails.logger.info("SendgridPostHandler DirectMail response: #{resp.body}")
  end

  def handle_adduser_request
    # Extract email from from field and find user
    from_email = extract_email_from_sendgrid_from(@params[:from])
    user = User.find_by(email: from_email)
    
    unless user
      Rails.logger.info "SendgridPostHandler user not found for email: #{from_email}"
      CommandMailer.error(
        from_email,
        @params[:subject],
        "We couldn't find an account with your email address. Please sign up first by sending an email to signup@postcardmailer.us.",
        @params[:to]
      ).deliver_now
      Rails.logger.info "SendgridPostHandler sent 'user not found' error email to: #{from_email}"
      return
    end

    # Extract nickname from subject line
    nickname = @params[:subject].strip
    if nickname.empty?
      Rails.logger.info "SendgridPostHandler empty nickname in subject"
      CommandMailer.error(
        from_email,
        "Add New Address", 
        "Please provide a nickname for this address in the subject line of your email.", 
        @params[:to]
      ).deliver_now
      Rails.logger.info "SendgridPostHandler sent 'empty nickname' error email to: #{user.email}"
      return
    end

    # Check if nickname already exists for this user
    if user.addresses.exists?(nickname: nickname)
      Rails.logger.info "SendgridPostHandler nickname already exists for user: #{nickname}"
      CommandMailer.error(
        from_email,
        @params[:subject], 
        "You already have an address with the nickname '#{nickname}'. Please choose a different nickname.", 
        @params[:to]
      ).deliver_now
      Rails.logger.info "SendgridPostHandler sent 'nickname exists' error email to: #{user.email}"
      return
    end

    # Extract address from body
    name, address = AddressExtractor.extract(@params[:text])
    unless address
      Rails.logger.info "SendgridPostHandler could not parse address from body"
      # Send error message with original subject and to email for threading
      CommandMailer.error(
        from_email,
        @params[:subject], 
        "Could not parse a valid address from your email. Please include a complete mailing address with street, city, state, and ZIP code.", 
        @params[:to]
      ).deliver_now
      Rails.logger.info "SendgridPostHandler sent error email to: #{user.email}"
      return
    end

    # Create new address
    new_address = user.addresses.create!(
      nickname: nickname,
      name: name,
      address1: address.street,
      address2: address.unit,
      city: address.city,
      state: address.state,
      postal_code: address.postal_code
    )

    Rails.logger.info "SendgridPostHandler created new address: #{new_address.inspect}"
    
    # Send adduser confirmation email with original subject for threading
    # Use the original 'to' email as the from address for proper threading
    CommandMailer.adduser(user, from_email, @params[:subject], @params[:to]).deliver_now
    Rails.logger.info "SendgridPostHandler sent adduser confirmation email to: #{from_email}"
  end

  def lookup_user_and_address
    # Extract email from from field and find user
    from_email = extract_email_from_sendgrid_from(@params[:from])
    Rails.logger.info "SendgridPostHandler looking up user with email: #{from_email}"
    user = User.find_by(email: from_email)
    
    unless user
      Rails.logger.info "SendgridPostHandler user not found for email: #{from_email}"
      return [nil, nil]
    end
    
    # Extract nickname from to address and find address
    nickname = @params[:to].split("@").first
    Rails.logger.info "SendgridPostHandler looking up address with nickname: #{nickname}"
    address = user.addresses.find_by(nickname: nickname)
    
    unless address
      Rails.logger.info "SendgridPostHandler address not found for nickname: #{nickname}"
      # Send error message with original subject and to email for threading
      if user.verified?
        CommandMailer.error(
          from_email,
          @params[:subject], 
          "Address not found for nickname: #{nickname}. Please make sure you're using a valid nickname from your address book.", 
          @params[:to]
        ).deliver_now
        Rails.logger.info "SendgridPostHandler sent error email to: #{user.email}"
      end
      return [nil, nil]
    end
    
    Rails.logger.info "SendgridPostHandler found address for nickname: #{nickname}"
    [user, address]
  end
end