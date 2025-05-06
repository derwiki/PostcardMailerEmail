class Admin::PostcardsController < ApplicationController
  before_action :authenticate_admin

  def index
    @postcards = Postcard.order(created_at: :desc).page(params[:page]).per(10)
  end

  private

  def authenticate_admin
    unless params[:secret] == ENV["ADMIN_SECRET"]
      render plain: "Unauthorized", status: :unauthorized
    end
  end
end
