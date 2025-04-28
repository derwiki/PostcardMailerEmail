class ApplicationMailer < ActionMailer::Base
  default from: "PostcardMailer.us <notifications@postcardmailer.us>"
  layout "email"

  private

  def set_content_type
    headers["Content-Type"] = "text/html; charset=UTF-8"
  end
end
