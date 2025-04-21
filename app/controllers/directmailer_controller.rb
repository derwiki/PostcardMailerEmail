class DirectmailerController < ApplicationController
  # TODO: Add authentication/authorization if needed
  skip_before_action :verify_authenticity_token # Usually needed for webhooks

  def webhook
    webhook_params = directmailer_webhook_params
    Rails.logger.info "Webhook received: #{webhook_params.inspect}"

    # Access the first element of the Data array
    data_element = webhook_params[:Data]&.first

    print_record_id = data_element&.dig(:PrintRecord)

    if print_record_id.blank?
      Rails.logger.warn "Webhook missing PrintRecord ID: #{webhook_params.inspect}"
      return head :ok
    end

    # Find the postcard by print_record_id
    postcard = Postcard.find_by(print_record_id: print_record_id)
    unless postcard
      Rails.logger.warn "Could not find Postcard with PrintRecord: #{print_record_id}"
      return head :ok
    end

    Rails.logger.info "Found matching Postcard: #{postcard.id}"

    # Record the webhook event
    record_webhook_event(postcard, webhook_params)

    # Send notification email with updated status information
    send_status_notification(postcard)

    head :ok
  end

  private

  def record_webhook_event(postcard, webhook_params)
    # Create a timestamped event record
    event = {
      timestamp: Time.current,
      event_type: webhook_params[:Event],
      data: webhook_params
    }

    # Initialize directmailers_events if nil (shouldn't happen with default [], but just in case)
    postcard.directmailers_events ||= []

    # Prepend the new event to the array
    postcard.directmailers_events = [event] + postcard.directmailers_events

    # Save without callbacks or validations to avoid any side effects
    if postcard.save(validate: false)
      Rails.logger.info "Recorded webhook event for Postcard: #{postcard.id}"
    else
      Rails.logger.error "Failed to record webhook event: #{postcard.errors.full_messages.join(', ')}"
    end
  end

  def send_status_notification(postcard)
    PostcardLifecycleMailer.status_update(postcard).deliver_later

    Rails.logger.info "Status update email queued for Postcard: #{postcard.id}"
  end

  def directmailer_webhook_params
    params.permit(
      :Event,
      :Object,
      Data: [
        :PrintRecord,
        :Created,
        :Canceled,
        :Status,
        :Description,
        :Medium,
        :Size,
        :MailingDate,
        :Front,
        :Back,
        :VariablePayload,
        :PdfPages,
        :PrintPages,
        :Duplex,
        :BlankFirstPage,
        :Cost,
        :DryRun,
        :RenderedPdf,
        :PostalCarrier,
        :PostalClass,
        { To: [:Name, :AddressLine1, :AddressLine2, :City, :State, :Zip] },
        { From: [:Name, :AddressLine1, :AddressLine2, :City, :State, :Zip] },
        { FrontThumbnails: [:Small, :Medium, :Large] },
        { BackThumbnails: [:Small, :Medium, :Large] },
        { TrackingEvents: [] },
        :EstimatedDeliveryDate,
        :ActualDeliveryDate
      ]
    )
  end
end 