require_relative '../services/address_extractor'
require_relative '../services/create_postcard'

class SendgridController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    Rails.logger.info "SendgridController params: #{params}"
    Rails.logger.info "SendgridController params.keys: #{params.keys}"
    subject = params[:subject]
    Rails.logger.info "SendgridController subject: #{subject}"
    from = params[:from]
    Rails.logger.info "SendgridController from: #{from}"
    # Rails.logger.info "SendgridController sending_user: #{sending_user}"

    # if !sending_user
    #   Rails.logger.info "SendgridController no valid sending user for #{from}"
    #   InboundMailer.failure(from, subject, "No user found for #{from}").deliver
    #   return head :ok
    # end

    bodytext = params[:text]
    # TODO(derwiki) if you use the share menu on ios to send the image, the body text shows up as an attachment:
    # "attachments"=>"2", "attachment2"=>#<ActionDispatch::Http::UploadedFile:0x00007f1410791a50 @tempfile=#<Tempfile:/tmp/RackMultipart20230317-2-6g2qyj.txt>, @original_filename="msg-6752-20.txt", @content_type="text/plain", @headers="Content-Disposition: form-data; name=\"attachment2\"; filename=\"msg-6752-20.txt\"\r\nContent-Type: text/plain\r\n">, "dkim"=>"{@gmail.com : pass}", "subject"=>"Elodie and Dada in the Outer Sunset on a sunny Friday", "to"=>"in@postcardmailer.us", "attachment-info"=>"{\"attachment2\":{\"charset\":\"us-ascii\",\"type\":\"text/plain\"},\"attachment1\":{\"filename\":\"FullSizeRender.JPEG\",\"name\":\"FullSizeRender.JPEG\",\"type\":\"image/jpeg\"}}", "from"=>"Adam Derewecki <derewecki@gmail.com>", "text"=>"\r\n\n", "sender_ip"=>"209.85.216.41", "attachment1"=>#<ActionDispatch::Http::UploadedFile:0x00007f14107918c0 @tempfile=#<Tempfile:/tmp/RackMultipart20230317-2-1a5j1wg.JPEG>, @original_filename="FullSizeRender.JPEG", @content_type="image/jpeg", @headers="Content-Disposition: form-data; name=\"attachment1\"; filename=\"FullSizeRender.JPEG\"\r\nContent-Type: image/jpeg\r\n">, "envelope"=>"{\"to\":[\"in@postcardmailer.us\"],\"from\":\"derewecki@gmail.com\"}", "charsets"=>"{\"to\":\"UTF-8\",\"filename\":\"UTF-8\",\"subject\":\"UTF-8\",\"from\":\"UTF-8\",\"text\":\"us-ascii\"}", "SPF"=>"pass", "controller"=>"sendgrid", "action"=>"create"}
    if !bodytext
      Rails.logger.info "SendgridController empty body: #{address}"
      # InboundMailer.failure(from, subject, "Message body was empty").deliver
      return head :ok
    end

    body_text = params[:text]
    if params[:to].include?("adam@postcardmailer.us")
      Rails.logger.info "SendgridController found to: adam@postcardmailer.us; adding address"
      body_text += "\n\nAdam Derewecki, 210 Holladay Ave, San Francisco, CA 94110"
    end
    Rails.logger.info "SendgridController bodytext: #{bodytext}"
    name, address = AddressExtractor.extract(body_text)
    Rails.logger.info "SendgridController name: #{name}"
    if !address
      Rails.logger.info "SendgridController bad address: #{address}"
      # InboundMailer.failure(from, subject, "Couldn't extract address from message body: #{bodytext}").deliver
      return head :ok
    end
    if !params[:attachment1]
      Rails.logger.info "SendgridController missing attachment"
      # InboundMailer.failure(from, subject, "No image was attached").deliver
      return head :ok
    end

    Rails.logger.info "SendgridController address: #{address}"
    to_address = {
      name: name,
      address1: "#{address.number} #{address.street} #{address.street_type} #{address.unit_prefix}#{address.unit}",
      address2: nil,
      city: address.city,
      state: address.state,
      postal_code: address.postal_code
    }
    Rails.logger.info "SendgridController extracted_address to_address: #{to_address.inspect}"

    from_address = {
      name: "Postcardmailer.us",
      address1: "1198 S Van Ness Ave #80417",
      address2: nil,
      city: "San Francisco",
      state: "CA",
      postal_code: "94110"
    }

    key = "#{SecureRandom.uuid}.jpg"
    image = EssThree.upload(key, params[:attachment1])
    image_url = "https://s3.amazonaws.com/postcardmailer.us/#{key}"

    dryrun = ENV.get("DRYRUN", "true") == "true"
    Rails.logger.info "SendgridController dryrun: #{dryrun}"
    resp = CreatePostcard.new(from_address, to_address, image_url, subject, dryrun: ).run
    Rails.logger.info("SendgridController DirectMail response: #{resp.body}")

    # InboundMailer.success(from, subject, JSON[resp.body]).deliver
    head :ok
  end

  private

    # def sending_user
    #   if email = params[:from].match(/<([^<>]+)>/).try(:[], 1)
    #     email = 'pc@derwiki.net' if email == 'derewecki@gmail.com'  # special case for me
    #     email = 'pc@derwiki.net' if email == 'ashkan.pk@gmail.com'  # special case for ashkan
    #     User.find_by(email: email)
    #   end
    # end
end
