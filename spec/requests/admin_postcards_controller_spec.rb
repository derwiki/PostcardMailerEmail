require "rails_helper"

RSpec.describe "Admin::PostcardsController", type: :request do
  include FactoryBot::Syntax::Methods
  let(:admin_secret) { "supersecret" }
  let!(:postcards) { create_list(:postcard, 3) }

  before do
    stub_const("ENV", ENV.to_hash.merge("ADMIN_SECRET" => admin_secret))
  end

  it "redirects to root if secret is missing" do
    get "/admin/postcards"
    expect(response).to redirect_to(root_path)
  end

  it "redirects to root if secret is incorrect" do
    get "/admin/postcards", params: { secret: "wrong" }
    expect(response).to redirect_to(root_path)
  end

  it "renders index and assigns postcards if secret is correct" do
    get "/admin/postcards", params: { secret: admin_secret }
    expect(response).to have_http_status(:success)
    expect(response).to render_template(:index)
    # Optionally, check that the postcards are present in the response body
    postcards.each do |postcard|
      expect(response.body).to include(postcard.message)
    end
  end

  it "paginates postcards" do
    create_list(:postcard, 15) # more than 10 per page
    get "/admin/postcards", params: { secret: admin_secret, page: 2 }
    expect(response).to have_http_status(:success)
    expect(response).to render_template(:index)
  end
end
