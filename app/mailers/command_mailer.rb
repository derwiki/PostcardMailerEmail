class CommandMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.command_mailer.adduser.subject
  #
  def adduser(user, recipient_email, original_subject)
    @user = user
    @recipient_email = recipient_email

    mail(
      to: @user.email,
      from: "adduser@postcardmailer.us",
      subject: "Re: #{original_subject}"
    )
  end

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.command_mailer.signup.subject
  #
  def signup(user, original_subject)
    @user = user

    mail(
      to: @user.email,
      from: "signup@postcardmailer.us",
      subject: "Re: #{original_subject}"
    )
  end

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.command_mailer.verified.subject
  #
  def verified(user)
    @user = user

    mail(
      to: @user.email,
      from: "verified@postcardmailer.us",
      subject: "Re: Your PostcardMailer.us Account"
    )
  end
end
