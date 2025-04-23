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
    Rails.logger.info "SendgridPostHandler headers: #{@params[:headers]}"
    Rails.logger.info "SendgridPostHandler SPF: #{@params[:SPF]}"
    Rails.logger.info "SendgridPostHandler DKIM: #{@params[:dkim]}"
    
    # Verify email authentication
    unless spf_passes? && dkim_passes?
      @from_email = extract_email_from_sendgrid_from(@params[:from])
      Rails.logger.warn "Email authentication failed for #{@from_email}. SPF: #{@params[:SPF]}, DKIM: #{@params[:dkim]}"
      
      CommandMailer.error(
        @from_email,
        "Email Authentication Failed",
        "We couldn't verify the authenticity of your email. This may indicate spoofing or unauthorized use of the email address.",
        "help@postcardmailer.us",
        "postcardmailer@kgk.host"
      ).deliver_now
      
      Rails.logger.info "SendgridPostHandler sent error email about authentication failure to: #{@from_email}"
      return
    end

    bodytext = @params[:text]
    @from_email = extract_email_from_sendgrid_from(@params[:from])

    if !bodytext
      Rails.logger.info "SendgridPostHandler empty body"
      send_error_email(
        "Empty Email Body",
        "Your email did not contain any text content. Please include the necessary information in your email body."
      )
      return
    end

    # Check if this is a signup request
    if @params[:to] == "signup@postcardmailer.us"
      handle_signup_request
      return
    end

    # Check if this is an adduser request
    if @params[:subject].strip.downcase == 'adduser'
      handle_adduser_request
      return
    end

    # Check if this is a help request
    if @params[:to] == "help@postcardmailer.us"
      handle_help_request
      return
    end

    handle_mail_postcard_request
  end

  private

  def spf_passes?
    return true if Rails.env.test? && !@params.key?(:SPF)
    @params[:SPF] == "pass"
  end

  def dkim_passes?
    return true if Rails.env.test? && !@params.key?(:dkim)
    # DKIM format is typically something like "{@gmail.com : pass}"
    return false unless @params[:dkim].present?
    @params[:dkim].include?("pass")
  end

  def send_error_email(subject, message, to_email = nil, bcc_email = nil)
    to_email ||= @params[:to] || "help@postcardmailer.us"
    @from_email ||= extract_email_from_sendgrid_from(@params[:from])
    
    CommandMailer.error(
      @from_email,
      subject.presence || @params[:subject],
      message,
      to_email,
      bcc_email
    ).deliver_now
    
    Rails.logger.info "SendgridPostHandler sent '#{message.truncate(30)}' error email to: #{@from_email}"
  end

  def authenticate_user
    user = User.find_by(email: @from_email)

    unless user
      Rails.logger.info "SendgridPostHandler user not found for email: #{@from_email}"
      send_error_email(
        @params[:subject],
        "We couldn't find an account with your email address. Please sign up first by sending an email to signup@postcardmailer.us."
      )
      return nil
    end
    
    unless user.verified?
      Rails.logger.info "SendgridPostHandler user not verified: #{@from_email}"
      send_error_email(
        @params[:subject],
        "Your account is pending verification. We'll notify you once your account has been verified and you can start sending postcards."
      )
      return nil
    end

    user
  end

  def extract_address_from_body(body_text, name_prefix = nil)
    text_to_parse = name_prefix ? "#{name_prefix}\n#{body_text}" : body_text
    name, address = AddressExtractor.extract(text_to_parse)

    unless address
      Rails.logger.info "SendgridPostHandler could not parse address from body"
      send_error_email(
        @params[:subject],
        "We couldn't parse a valid address from your email. Please include your complete mailing address (street, city, state, and ZIP code) in the email body."
      )
      return nil, nil
    end

    [name, address]
  end

  def create_address(user, nickname, name, address)
    user.addresses.create!(
      nickname: nickname,
      name: name,
      address1: address.street,
      address2: address.unit,
      city: address.city,
      state: address.state,
      postal_code: address.postal_code
    )
  end

  def handle_help_request
    Rails.logger.info "SendgridPostHandler processing help request from: #{@from_email}"
    CommandMailer.help(@from_email, @params[:subject], @params[:to]).deliver_now
    Rails.logger.info "SendgridPostHandler sent help email to: #{@from_email}"
  end

  def handle_signup_request
    # Check if user already exists
    if User.exists?(email: @from_email)
      Rails.logger.info "SendgridPostHandler user already exists: #{@from_email}"
      send_error_email(
        @params[:subject],
        "An account with this email already exists. If you've forgotten your password, please use the password reset option on the website."
      )
      return
    end

    # Extract name from subject line
    name = @params[:subject].strip
    if name.empty?
      Rails.logger.info "SendgridPostHandler empty name in subject"
      send_error_email(
        "Signup Error",
        "Please include your full name in the subject line when signing up."
      )
      return
    end

    # Extract address from body
    extracted_name, address = extract_address_from_body(@params[:text], name)
    return unless address

    # Create user and their first address
    user = User.create!(email: @from_email)
    new_address = create_address(
      user,
      name.split.first.downcase,
      name,
      address
    )

    Rails.logger.info "SendgridPostHandler created new user and address: #{new_address.inspect}"
    
    # Send signup confirmation email with original subject for threading
    CommandMailer.signup(user, @params[:subject], @params[:to]).deliver_now
    Rails.logger.info "SendgridPostHandler sent signup confirmation email to: #{user.email}"
  end

  def handle_mail_postcard_request
    user = authenticate_user
    return unless user
    
    # Extract nickname from the "to" email address (format: nickname@postcardmailer.us)
    nickname = @params[:to].split('@').first
    Rails.logger.info "SendgridPostHandler looking up address with nickname: #{nickname}"
    address = user.addresses.find_by(nickname: nickname)
    
    unless address
      Rails.logger.info "SendgridPostHandler address not found for nickname: #{nickname}"
      send_error_email(
        @params[:subject],
        "Address not found for nickname: #{nickname}. Please make sure you're using a valid nickname from your address book."
      )
      return
    end

    if !@params[:attachment1]
      Rails.logger.info "SendgridPostHandler missing attachment"
      send_error_email(
        @params[:subject],
        "Your email is missing an image attachment. Please attach an image to your email to create a postcard."
      )
      return
    end

    # Use the original subject as the message without adding date
    message = @params[:subject]
    Rails.logger.info "SendgridPostHandler message: #{message}"

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
    user = authenticate_user
    return unless user

    # Verify this is an adduser command
    unless @params[:subject].strip.downcase == 'adduser'
      Rails.logger.info "SendgridPostHandler invalid adduser command"
      send_error_email(
        "Invalid Command",
        "To add a new address, use 'adduser' as the subject line and include the nickname in the email address (e.g., home@postcardmailer.us)."
      )
      return
    end

    # Extract nickname from the "to" email address
    nickname = @params[:to].split('@').first
    if nickname.empty?
      Rails.logger.info "SendgridPostHandler empty nickname in email address"
      send_error_email(
        "Add New Address",
        "Please provide a nickname in the email address (e.g., home@postcardmailer.us)."
      )
      return
    end

    # Check if nickname already exists for this user
    if user.addresses.exists?(nickname: nickname)
      Rails.logger.info "SendgridPostHandler nickname already exists for user: #{nickname}"
      send_error_email(
        @params[:subject],
        "You already have an address with the nickname '#{nickname}'. Please choose a different nickname."
      )
      return
    end

    # Extract address from body
    name, address = extract_address_from_body(@params[:text])
    return unless address

    # Create new address
    new_address = create_address(user, nickname, name, address)

    Rails.logger.info "SendgridPostHandler created new address: #{new_address.inspect}"
    
    # Send adduser confirmation email with original subject for threading
    CommandMailer.adduser(user, @from_email, @params[:subject], @params[:to], new_address).deliver_now
    Rails.logger.info "SendgridPostHandler sent adduser confirmation email to: #{@from_email}"
  end

  # Maintained for test compatibility
  def lookup_user_and_address
    from_email = extract_email_from_sendgrid_from(@params[:from])
    Rails.logger.info "SendgridPostHandler looking up user with email: #{from_email}"
    user = User.find_by(email: from_email)

    unless user
      Rails.logger.info "SendgridPostHandler user not found for email: #{from_email}"
      return [nil, nil]
    end

    # Extract nickname from the "to" email address (format: nickname@postcardmailer.us)
    nickname = @params[:to].split('@').first
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