FactoryBot.define do
  factory :address do
    user
    nickname { 'test' }
    name { 'Test User' }
    address1 { '123 Test St' }
    address2 { nil }
    city { 'Test City' }
    state { 'CA' }
    postal_code { '94110' }
  end
end 