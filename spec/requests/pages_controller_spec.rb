require "rails_helper"

RSpec.describe "PagesController", type: :request do
  describe "GET /landing_page" do
    it "returns http success" do
      get "/pages/landing_page"
      expect(response).to have_http_status(:success)
    end

    it "renders the landing_page template" do
      get "/pages/landing_page"
      expect(response).to render_template(:landing_page)
    end
  end
end
