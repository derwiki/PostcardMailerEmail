class Postcard < ApplicationRecord
  belongs_to :user
  belongs_to :address

  validates :user, presence: true
  validates :address, presence: true
  validates :image_url, presence: true
  validates :message, presence: true
  validates :print_record_id, uniqueness: true, allow_nil: true

  # Extract print_record_id from response_data before saving
  before_save :extract_print_record_id_from_response_data

  private

  def extract_print_record_id_from_response_data
    # Only extract if print_record_id is nil and response_data contains PrintRecord
    if print_record_id.blank? && response_data.present? && response_data.is_a?(Hash)
      self.print_record_id = response_data['PrintRecord']
    end
  end
end 