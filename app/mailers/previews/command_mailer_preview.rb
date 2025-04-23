def adduser
  # Create or find a user for the preview
  user = User.first || User.create!(email: "preview@example.com", verified: true)
  
  # Create a sample address for the preview
  new_address = Address.new(
    name: "Jane Smith",
    nickname: "mom",
    address1: "123 Main St",
    city: "San Francisco",
    state: "CA",
    postal_code: "94110"
  )
  
  # Call the mailer with appropriate test data
  CommandMailer.adduser(
    user, 
    "new_user@example.com", 
    "Adding New Address", 
    "adduser@postcardmailer.us",
    new_address
  )
end 