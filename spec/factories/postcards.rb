FactoryBot.define do
  factory :postcard do
    user
    address
    status { "created" }
    image_url { "https://example.com/test.jpg" }
    message { "Test message" }
    dryrun { false }
    response_data { { "PrintRecord" => "pm-test-123" } }
    print_record_id { "pm-test-123" }
    directmailers_events { [] }
  end
end
