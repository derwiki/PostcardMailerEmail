# Preview all emails at http://localhost:3000/rails/mailers/command_mailer
class CommandMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/command_mailer/adduser
  def adduser
    # Create or find a user for the preview
    user = User.new(email: "ned.flanders@springfield.com", verified_at: Time.zone.now)

    # Create a sample address for the preview
    new_address = Address.new(
      name: "Homer Simpson",
      nickname: "homer",
      address1: "742 Evergreen Terrace",
      city: "Springfield",
      state: "IL",
      postal_code: "62702"
    )

    # Call the mailer with appropriate test data
    CommandMailer.adduser(
      user,
      "ned.flanders@springfield.com",
      "Adding New Address",
      "adduser@postcardmailer.us",
      new_address
    )
  end

  # Preview this email at http://localhost:3000/rails/mailers/command_mailer/signup
  def signup
    # Create or find a user for the preview
    user = User.new(email: "ned.flanders@springfield.com", verified_at: nil)

    # Call the mailer with appropriate test data
    CommandMailer.signup(
      user,
      "New User Signup",
      "signup@postcardmailer.us"
    )
  end

  # Preview this email at http://localhost:3000/rails/mailers/command_mailer/verified
  def verified
    # Create or find a user for the preview
    user = User.new(email: "ned.flanders@springfield.com", verified_at: Time.zone.now)

    # Call the mailer with appropriate test data
    CommandMailer.verified(
      user,
      "verified@postcardmailer.us"
    )
  end
  
  # Preview this email at http://localhost:3000/rails/mailers/command_mailer/error
  def error
    # Call the mailer with appropriate test data
    CommandMailer.error(
      "ned.flanders@springfield.com",
      "Error Processing Request",
      "We couldn't process your request due to an error. Please try again.",
      "help@postcardmailer.us"
    )
  end
  
  # Preview this email at http://localhost:3000/rails/mailers/command_mailer/help
  def help
    # Call the mailer with appropriate test data
    CommandMailer.help(
      "ned.flanders@springfield.com",
      "Help Request",
      "help@postcardmailer.us"
    )
  end
end 