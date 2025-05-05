# Preview all emails at http://localhost:3000/rails/mailers/postcard_lifecycle_mailer
class PostcardLifecycleMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/postcard_lifecycle_mailer/status_update
  def status_update
    # Find an existing postcard, or create a mock one for preview
    postcard = find_or_create_sample_postcard('Mailed')
    PostcardLifecycleMailer.status_update(postcard)
  end

  # Preview with 'Delivered' status
  # Preview this at http://localhost:3000/rails/mailers/postcard_lifecycle_mailer/status_update_delivered
  def status_update_delivered
    postcard = find_or_create_sample_postcard('Delivered')
    PostcardLifecycleMailer.status_update(postcard)
  end

  # Preview with 'Printed' status
  # Preview this at http://localhost:3000/rails/mailers/postcard_lifecycle_mailer/status_update_printed
  def status_update_printed
    postcard = find_or_create_sample_postcard('Printed')
    PostcardLifecycleMailer.status_update(postcard)
  end

  # Preview with 'Error' status
  # Preview this at http://localhost:3000/rails/mailers/postcard_lifecycle_mailer/status_update_error
  def status_update_error
    postcard = find_or_create_sample_postcard('Error', 'There was a problem processing your postcard')
    PostcardLifecycleMailer.status_update(postcard)
  end

  private

  def find_or_create_sample_postcard(status = 'Mailed', description = nil)
    description ||= "Your postcard has been #{status.downcase}"

    # Create models with realistic sample data
    user = User.new(
      id: 9999,
      email: 'sarah.johnson@example.com'
    )
    user.instance_variable_set(:@new_record, false)

    address = Address.new(
      id: 9999,
      user: user,
      nickname: 'grandma',
      name: 'Margaret Williams',
      address1: '742 Evergreen Terrace',
      city: 'Springfield',
      state: 'IL',
      postal_code: '62701'
    )
    address.instance_variable_set(:@new_record, false)

    # Create a transient postcard object for preview purposes
    # We use new instead of create to avoid saving to the database during preview
    postcard = Postcard.new(
      id: 9999,  # Dummy ID for preview
      user: user,
      address: address,
      status: status,
      image_url: 'https://placecats.com/millie_neo/300/200',
      message: 'Grandma, thinking of you during my vacation in California. The weather is beautiful! Miss you lots.',
      print_record_id: "pm-test-#{Time.current.to_i}",
      response_data: {
        'TrackingEvents' => [
          {
            'Status' => 'Created',
            'Description' => 'Postcard created',
            'Timestamp' => (Time.current - 2.days).iso8601
          },
          {
            'Status' => status,
            'Description' => description,
            'Timestamp' => Time.current.iso8601
          }
        ],
        'EstimatedDeliveryDate' => (Time.current + 3.days).iso8601,
        'ActualDeliveryDate' => status == 'Delivered' ? Time.current.iso8601 : nil
      },
      directmailers_events: [
        {
          'timestamp' => Time.current.iso8601,
          'event_type' => 'PostcardStatusUpdate',
          'data' => {
            'Data' => [
              {
                'Status' => status,
                'Description' => description
              }
            ]
          }
        }
      ]
    )

    # Allow the model to have an ID without saving to database
    postcard.instance_variable_set(:@new_record, false) if postcard.id

    postcard
  end
end
