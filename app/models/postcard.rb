class Postcard < ApplicationRecord
  belongs_to :user
  belongs_to :address

  validates :user, presence: true
  validates :address, presence: true
  validates :image_url, presence: true
  validates :message, presence: true
end 