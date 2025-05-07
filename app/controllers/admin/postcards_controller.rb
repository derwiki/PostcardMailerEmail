class Admin::PostcardsController < ApplicationController
  before_action :authenticate_admin

  def index
    @postcards = Postcard.order(created_at: :desc).page(params[:page]).per(10)
  end

  private

  def authenticate_admin
    redirect_to root_path unless params[:secret] == ENV["ADMIN_SECRET"]
  end
end
