class ApplicationMailer < ActionMailer::Base
  default from: "PostcardMailer.us <notifications@postcardmailer.us>"
  layout "email"

  before_action :set_content_type

  private

  def set_content_type(*args)
    headers["Content-Type"] = "text/html; charset=UTF-8"
  end
end
