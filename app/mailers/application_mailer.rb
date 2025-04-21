class ApplicationMailer < ActionMailer::Base
  default from: "notifications@postcardmailer.us"
  layout "mailer"
end
