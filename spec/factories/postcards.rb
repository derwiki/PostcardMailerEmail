FactoryBot.define do
  factory :postcard do
    user
    address
    status { "created" }
    image_url { "https://example.com/test.jpg" }
    message { "Test message" }
    dryrun { false }
    response_data { { "PrintRecord" => "pm-test-#{SecureRandom.uuid}" } }
    sequence(:print_record_id) { |n| "pm-test-#{n}-#{SecureRandom.uuid}" }
    directmailers_events { [] }
  end
end
