class PostcardLifecycleMailer < ApplicationMailer
  layout "email"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.postcard_lifecycle_mailer.status_update.subject
  #
  def status_update(postcard)
    @postcard = postcard
    @user = postcard.user

    # Get the most recent event from directmailers_events (first item in the array)
    latest_event = @postcard.directmailers_events.first

    # Extract status information from the latest event
    if latest_event.present?
      event_data = latest_event["data"]
      @event_type = latest_event["event_type"]

      # Get the first Data element if it exists
      data_element =
        event_data&.dig(:Data)&.first || event_data&.dig("Data")&.first || {}

      # Determine status from the event data
      @status =
        data_element&.dig(:Status) || data_element&.dig("Status") ||
          @event_type || "unknown"

      # Get timestamp
      @timestamp = latest_event["timestamp"]
    else
      # Fallback if no events exist
      @status = postcard.status || "unknown"
      @event_type = nil
      @timestamp = nil
    end

    # Check for tracking events in response_data
    @tracking_events = postcard.response_data&.dig("TrackingEvents") || []
    @directmailers_events = postcard.directmailers_events || []

    # Calculate total cost and cards sent
    @total_cards_sent = @user.postcards.count
    @total_cost = @total_cards_sent * 0.68

    # Use the nickname in the from email address
    nickname =
      (
        if postcard.address.nickname.present?
          postcard.address.nickname
        else
          "notifications"
        end
      )
    from_email = "#{nickname}@postcardmailer.us"

    mail(to: @user.email, from: from_email, subject: "Re: #{@postcard.message}")
  end

  private

  def status_subject(status)
    case status.to_s.downcase
    when "printed"
      "has been printed"
    when "mailed", "in_transit"
      "is on its way"
    when "delivered"
      "has been delivered!"
    when "returned"
      "was returned to sender"
    when "error"
      "could not be processed"
    else
      "status has been updated"
    end
  end
end
