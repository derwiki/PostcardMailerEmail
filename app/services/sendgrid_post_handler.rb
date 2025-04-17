require_relative 'address_extractor'
require_relative 'create_postcard'

class SendgridPostHandler
  def initialize(params)
    @params = params
  end

  def process
    Rails.logger.info "SendgridPostHandler params: #{@params}"
    Rails.logger.info "SendgridPostHandler params.keys: #{@params.keys}"
    
    subject = @params[:subject]
    today = Date.today
    formatted_date = today.strftime("%B #{today.day.ordinalize}, %Y")
    subject += "\n\n#{formatted_date}"
    Rails.logger.info "SendgridPostHandler subject: #{subject}"
    from = @params[:from]
    Rails.logger.info "SendgridPostHandler from: #{from}"

    bodytext = @params[:text]
    if !bodytext
      Rails.logger.info "SendgridPostHandler empty body"
      return
    end

    body_text = @params[:text]
    if @params[:to].include?("adam@postcardmailer.us")
      Rails.logger.info "SendgridPostHandler found to: adam@postcardmailer.us; adding address"
      body_text += "\n\nAdam Derewecki, 210 Holladay Ave, San Francisco, CA 94110"
    else
      # Check if sender exists in our user table
      from_email = @params[:from].split("<").last.gsub(">", "").strip
      user = User.find_by(email: from_email)

      if user
        # Extract nickname from to address
        nickname = @params[:to].split("@").first
        address = user.addresses.find_by(nickname: nickname)

        if address
          Rails.logger.info "SendgridPostHandler found address for nickname: #{nickname}"
          body_text += "\n\n#{address.name}, #{address.address1}#{address.address2 ? ", #{address.address2}" : ""}, #{address.city}, #{address.state} #{address.postal_code}"
        end
      end
    end
    Rails.logger.info "SendgridPostHandler bodytext: #{bodytext}"
    
    name, address = AddressExtractor.extract(body_text)
    Rails.logger.info "SendgridPostHandler name: #{name}"
    if !address
      Rails.logger.info "SendgridPostHandler bad address: #{address}"
      return
    end
    
    if !@params[:attachment1]
      Rails.logger.info "SendgridPostHandler missing attachment"
      return
    end

    Rails.logger.info "SendgridPostHandler address: #{address}"
    to_address = {
      name: name,
      address1: "#{address.number} #{address.street} #{address.street_type} #{address.unit_prefix}#{address.unit}",
      address2: nil,
      city: address.city,
      state: address.state,
      postal_code: address.postal_code
    }
    Rails.logger.info "SendgridPostHandler extracted_address to_address: #{to_address.inspect}"

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
end 