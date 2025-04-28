class User < ApplicationRecord
  has_many :addresses, dependent: :destroy
  has_many :postcards, dependent: :destroy

  def verified?
    verified_at.present?
  end
end
