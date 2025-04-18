require_relative 'create_postcard'
require_relative 'address_extractor'

class SendgridPostHandler
  def initialize(params)
    @params = params
  end

  def process
    Rails.logger.info "SendgridPostHandler params: #{@params}"
    Rails.logger.info "SendgridPostHandler params.keys: #{@params.keys}"

    bodytext = @params[:text]
    if !bodytext
      Rails.logger.info "SendgridPostHandler empty body"
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

    handle_mail_postcard_request
  end

  private

  def handle_signup_request
    # Extract email from from field
    from_email = @params[:from].match(/<([^<>]+)>/)&.captures&.first
    
    # Check if user already exists
    if User.exists?(email: from_email)
      Rails.logger.info "SendgridPostHandler user already exists: #{from_email}"
      return
    end

    # Extract name from subject line
    name = @params[:subject].strip
    if name.empty?
      Rails.logger.info "SendgridPostHandler empty name in subject"
      return
    end

    # Extract address from body
    _, address = AddressExtractor.extract(@params[:text])
    unless address
      Rails.logger.info "SendgridPostHandler could not parse address from body"
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
  end

  def handle_mail_postcard_request
    subject = @params[:subject]
    today = Date.today
    formatted_date = today.strftime("%B #{today.day.ordinalize}, %Y")
    subject += "\n\n#{formatted_date}"
    Rails.logger.info "SendgridPostHandler subject: #{subject}"

    user, address = lookup_user_and_address
    return unless user && address

    if !@params[:attachment1]
      Rails.logger.info "SendgridPostHandler missing attachment"
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

    key = "#{SecureRandom.uuid}.jpg"
    image = EssThree.upload(key, @params[:attachment1])
    image_url = "https://s3.amazonaws.com/postcardmailer.us/#{key}"

    dryrun = ENV["DRYRUN"] == "true"
    Rails.logger.info "SendgridPostHandler dryrun: #{dryrun}"
    resp = CreatePostcard.new(from_address, to_address, image_url, subject, dryrun: dryrun).run
    Rails.logger.info("SendgridPostHandler DirectMail response: #{resp.body}")
  end

  def handle_adduser_request
    # Extract email from from field and find user
    from_email = @params[:from].match(/<([^<>]+)>/)&.captures&.first
    user = User.find_by(email: from_email)
    
    unless user
      Rails.logger.info "SendgridPostHandler user not found for email: #{from_email}"
      return
    end

    # Extract address from subject line
    name, address = AddressExtractor.extract(@params[:subject])
    unless address
      Rails.logger.info "SendgridPostHandler could not parse address from subject"
      return
    end

    # Create new address
    new_address = user.addresses.create!(
      nickname: name.split.first.downcase,
      name: name,
      address1: address.street,
      address2: address.unit,
      city: address.city,
      state: address.state,
      postal_code: address.postal_code
    )

    Rails.logger.info "SendgridPostHandler created new address: #{new_address.inspect}"
  end

  def lookup_user_and_address
    # Extract email from from field and find user
    from_email = @params[:from].match(/<([^<>]+)>/)&.captures&.first
    user = User.find_by(email: from_email)
    
    unless user
      Rails.logger.info "SendgridPostHandler user not found for email: #{from_email}"
      return [nil, nil]
    end
    
    # Extract nickname from to address and find address
    nickname = @params[:to].split("@").first
    address = user.addresses.find_by(nickname: nickname)
    
    unless address
      Rails.logger.info "SendgridPostHandler address not found for nickname: #{nickname}"
      return [nil, nil]
    end
    
    Rails.logger.info "SendgridPostHandler found address for nickname: #{nickname}"
    [user, address]
  end
end