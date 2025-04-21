# frozen_string_literal: true

require 'net/http'
require 'benchmark'
require 'json'

DIRECT_MAIL_KEY = ENV['DIRECT_MAIL_KEY'] unless defined?(DIRECT_MAIL_KEY)

class MailAPIException < StandardError
  attr_accessor :code, :details
  def initialize(code, details, msg = 'We had a problem sending your request to our print shop.')
    self.code = code
    self.details = details
    super(msg)
  end
end

class CreatePostcard
  include ActionView::Helpers::TextHelper

  attr_accessor :from_address
  attr_accessor :to_address
  attr_accessor :url
  attr_accessor :message
  attr_accessor :dryrun
  attr_accessor :font_size
  attr_accessor :user
  attr_accessor :address

  TARGET_URI = URI('https://print.directmailers.com/api/v1/postcard/')

  def initialize(from_address, to_address, url, message, dryrun: true, font_size: nil, user: nil, address: nil)
    self.from_address = from_address
    self.to_address = to_address
    self.url = url
    self.message = message # soft limit 666 chars
    self.dryrun = dryrun
    self.font_size = font_size || "0.18in"
    self.user = user
    self.address = address
  end

  def run
    http = Net::HTTP.new(TARGET_URI.host, TARGET_URI.port)
    http.use_ssl = true

    req = Net::HTTP::Post.new(TARGET_URI)
    req.body = JSON.generate(json_template)
    headers.each { |k, v| req[k] = v }

    response = http.request(req)

    if user && address
      postcard = Postcard.create!(
        user: user,
        address: address,
        status: response.code,
        response_data: JSON.parse(response.body),
        image_url: url,
        message: message,
        dryrun: dryrun
      )
    end

    response
  rescue StandardError => e
    error_data = {
      exception: "#{e.class}: #{e.message}",
      template: json_template,
      headers: headers
    }

    # Store error in database if user and address are provided
    if user && address
      Postcard.create!(
        user: user,
        address: address,
        status: 'error',
        response_data: error_data,
        image_url: url,
        message: message,
        dryrun: dryrun
      )
    end

    raise error_data.to_s
  end

  def headers
    req = {}
    req['Content-Type'] = 'application/json'
    req['Accept'] = 'application/json'
    req['Authorization'] = "Basic #{DIRECT_MAIL_KEY}"
    req
  end

  def json_template
    {
      'Description' => "#{Time.now} #{from_address[:name]} => #{to_address[:name]}",
      'Size' => '4.25x6',
      'DryRun' => dryrun,
      'WaitForRender' => true,
      'To' => {
        'Name' => to_address[:name],
        'AddressLine1' => to_address[:address1],
        'AddressLine2' => to_address[:address2],
        'City' => to_address[:city],
        'State' => to_address[:state],
        'Zip' => to_address[:postal_code]
      },
      'From' => {
        'Name' => from_address[:name],
        'AddressLine1' => from_address[:address1],
        'AddressLine2' => from_address[:address2],
        'City' => from_address[:city],
        'State' => from_address[:state],
        'Zip' => from_address[:postal_code]
      },
      'Back' => "<html><body style='width: 1875px; height: 1350px; background: url(#{url}); background-size: cover' /></html>",
      'Front' => <<~HTML
        <html>

        <head>
            <meta charset='UTF-8'>
            <link href='https://fonts.googleapis.com/css?family=Quicksand' rel='stylesheet'>
            <style>
                *, *:before, *:after {
                  -webkit-box-sizing: border-box;
                  -moz-box-sizing: border-box;
                  box-sizing: border-box;
                }
                body {
                  width: 6.25in;
                  height: 4.5in;
                  margin: 0;
                  padding: 0;
                }
                #safe-area {
                  position: absolute;
                  width: 5.875in;
                  height: 3.875in;
                  left: 0.1875in;
                  top: 0.1875in;
                }
                #present {
                  background-image: url();
                  background-size: 6.25in 1.5in;
                  width:6.25in;
                  height:1.5in;
                }
                #message-to-customer {
                  position: absolute;
                  width: 2.0in;
                  font-family: sans-serif;
                  font-size: #{ self.font_size };
                }
                #message {
                  position: absolute;
                  left: 2.5in;
                  top: 1.5in;
                  font-family: sans-serif;
                  font-size: 0.12in;
                }
                #border {
                  position: absolute;
                  left: 2.25in;
                  top: 1.875in;
                  width: 4.25in;
                  height: 2.5in;
                  border: 1px black dashed;
                  font-family: sans-serif;
                  font-size: 0.12in;
                }


            </style>
        </head>

        <body>
            <div id='present'> </div>
            <div id='safe-area'>
                <div id='message-to-customer'>#{simple_format(message)}</div>
                <div id='message'>Brighten someone's day, send a free postcard at postcardmailer.us</div>
                <div id='border'>&nbsp;</div>
            </div>
        </body>

        </html>
      HTML
    }
  end
end
