class ApplicationMailer < ActionMailer::Base
  default from: "PostcardMailer.us <notifications@postcardmailer.us>"
  layout "email"
end
