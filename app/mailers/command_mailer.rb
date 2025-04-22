class CommandMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.command_mailer.adduser.subject
  #
  def adduser(user, recipient_email, original_subject, from_email)
    @user = user
    @recipient_email = recipient_email

    mail(
      to: @user.email,
      from: from_email,
      subject: "Re: #{original_subject}"
    )
  end

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.command_mailer.signup.subject
  #
  def signup(user, original_subject, from_email)
    @user = user

    mail(
      to: @user.email,
      from: from_email,
      subject: "Re: #{original_subject}"
    )
  end

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.command_mailer.verified.subject
  #
  def verified(user, from_email)
    @user = user

    mail(
      to: @user.email,
      from: from_email,
      subject: "Re: Your PostcardMailer.us Account"
    )
  end

  # Send error notification when a command fails or has issues
  def error(to_address, original_subject, error_message, from_email)
    @error_message = error_message
    @email = to_address

    mail(
      to: to_address,
      from: from_email,
      subject: "Re: #{original_subject}"
    )
  end
  
  # Send help instructions for using the service
  def help(to_address, original_subject, from_email)
    @email = to_address

    mail(
      to: to_address,
      from: from_email,
      subject: "PostcardMailer.us - How to Use Our Service"
    )
  end
end
