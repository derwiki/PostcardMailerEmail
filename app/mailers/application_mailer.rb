class ApplicationMailer < ActionMailer::Base
  default from: "PostcardMailer.us <notifications@postcardmailer.us>"
  layout "mailer"
end
