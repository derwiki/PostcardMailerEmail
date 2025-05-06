class CommandMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.command_mailer.adduser.subject
  #
  def adduser(user, recipient_email, original_subject, from_email, new_address)
    @user = user
    @recipient_email = recipient_email
    @new_address = new_address

    mail(
      to: recipient_email,
      from: from_email,
      subject: "Re: #{original_subject}",
      bcc: "postcardmailer@kgk.host"
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
      subject: "Re: #{original_subject}",
      bcc: "postcardmailer@kgk.host"
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
      subject: "Re: Your PostcardMailer.us Account",
      bcc: "postcardmailer@kgk.host"
    )
  end

  # Send error notification when a command fails or has issues
  def error(
    to_address,
    original_subject,
    error_message,
    from_email,
    bcc_email = nil
  )
    @error_message = error_message
    @message = error_message
    @email = to_address

    mail(
      to: to_address,
      from: from_email,
      subject: "Re: #{original_subject}",
      bcc: bcc_email || "postcardmailer@kgk.host"
    )
  end

  # Send help instructions for using the service
  def help(to_address, original_subject, from_email)
    @email = to_address

    mail(to: to_address, from: from_email, subject: "Re: #{original_subject}")
  end

  def cancellation_success(from_email, postcard_print_record_guid, to_email)
    @from_email = from_email
    @subject = subject
    mail(
      to: to_email,
      bcc: bcc_email,
      subject: "re: #{postcard_print_record_guid}"
    )
  end

  private

  # ... existing code ...
end
