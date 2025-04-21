module EmailHelper
  extend ActiveSupport::Concern

  def extract_email_from_sendgrid_from(from_field)
    return nil if from_field.nil?
    # Match the last occurrence of an email address in angle brackets
    from_field.match(/<([^<>]+)>(?!.*<)/)&.captures&.first
  end
end 