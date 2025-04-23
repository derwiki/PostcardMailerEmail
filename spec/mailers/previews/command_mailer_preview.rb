# Preview all emails at http://localhost:3000/rails/mailers/command_mailer
class CommandMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/command_mailer/adduser
  def adduser
    # Create or find a user for the preview
    user = User.first || User.create!(email: "preview@example.com", verified: true)
    
    # Call the mailer with appropriate test data
    CommandMailer.adduser(
      user, 
      "new_user@example.com", 
      "Adding New Address", 
      "adduser@postcardmailer.us"
    )
  end

  # Preview this email at http://localhost:3000/rails/mailers/command_mailer/signup
  def signup
    # Create or find a user for the preview
    user = User.first || User.create!(email: "preview@example.com", verified: false)
    
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
    user = User.first || User.create!(email: "preview@example.com", verified: true)
    
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
      "preview@example.com", 
      "Error Processing Request", 
      "We couldn't process your request due to an error. Please try again.",
      "help@postcardmailer.us"
    )
  end
  
  # Preview this email at http://localhost:3000/rails/mailers/command_mailer/help
  def help
    # Call the mailer with appropriate test data
    CommandMailer.help(
      "preview@example.com",
      "Help Request",
      "help@postcardmailer.us"
    )
  end
end
