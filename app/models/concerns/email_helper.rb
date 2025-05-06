module EmailHelper
  extend ActiveSupport::Concern

  class MissingEmailError < StandardError
  end

  def extract_email_from_sendgrid_from(from_field)
    raise MissingEmailError, "from_field cannot be nil" if from_field.nil?
    raise MissingEmailError, "from_field cannot be empty" if from_field.empty?

    # Look for the last occurrence of <email> in the string
    # This handles cases like: "John <Dev> Doe <john@example.com>"
    if match = from_field.match(/<([^<>@\s]+@[^<>@\s]+)>/)
      return match.captures.last
    end

    # If no angle brackets with email, check if the string itself is an email address
    return from_field.strip if from_field =~ /\A[^@\s]+@[^@\s]+\z/

    # If we get here, we couldn't extract a valid email address
    raise MissingEmailError,
          "Could not extract email address from: #{from_field}"
  end
end
