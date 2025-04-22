# Preview all emails at http://localhost:3000/rails/mailers/command_mailer
class CommandMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/command_mailer/adduser
  def adduser
    # Create or find a user for the preview
    user = User.first || User.create!(email: "preview@example.com", verified: true)
    
    # Call the mailer with appropriate test data
    CommandMailer.adduser(user, "new_user@example.com", "Adding Mom to Address Book")
  end

  # Preview this email at http://localhost:3000/rails/mailers/command_mailer/signup
  def signup
    # Create or find a user for the preview
    user = User.first || User.create!(email: "preview@example.com", verified: false)
    
    # Call the mailer with appropriate test data
    CommandMailer.signup(user, "John Smith")
  end

  # Preview this email at http://localhost:3000/rails/mailers/command_mailer/verified
  def verified
    # Create or find a user for the preview
    user = User.first || User.create!(email: "preview@example.com", verified: true)
    
    # Call the mailer with appropriate test data
    CommandMailer.verified(user)
  end
end 