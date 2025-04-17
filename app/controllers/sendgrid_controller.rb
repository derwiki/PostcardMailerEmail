require_relative '../services/address_extractor'
require_relative '../services/create_postcard'
require_relative '../services/sendgrid_post_handler'

class SendgridController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    SendgridPostHandler.new(params).process
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
