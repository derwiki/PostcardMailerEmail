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

    # Find the postcard by searching the response_data JSON field
    # Note: This assumes PrintRecord from the creation response is stored at the top level of response_data
    # Adjust the query '.PrintRecord' if it's nested differently in your response_data structure
    postcard = Postcard.find_by("response_data ->> 'PrintRecord' = ?", print_record_id)

    if postcard
      Rails.logger.info "Found matching Postcard: #{postcard.id}"
      # TODO:
      # 1. Update Postcard status based on webhook_params[:Event] or data_element[:Status]
      # 2. Trigger lifecycle email using a new Mailer
    else
      Rails.logger.warn "Could not find Postcard with PrintRecord: #{print_record_id}"
      # Decide how to handle missing postcards - :not_found? :ok? Depends on the webhook provider's expectations.
    end
    head :ok
  end

  private

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