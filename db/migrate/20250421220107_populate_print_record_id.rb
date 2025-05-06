class PopulatePrintRecordId < ActiveRecord::Migration[8.0]
  def up
    # Find all postcards with nil print_record_id but with a PrintRecord in response_data
    Postcard
      .where(print_record_id: nil)
      .find_each do |postcard|
        if postcard.response_data.is_a?(Hash) &&
             postcard.response_data["PrintRecord"].present?
          # Extract and save the print_record_id
          print_record_id = postcard.response_data["PrintRecord"]

          # Use update_columns to avoid callbacks
          postcard.update_columns(print_record_id: print_record_id)
          puts "Updated Postcard ID #{postcard.id} with print_record_id: #{print_record_id}"
        else
          puts "Skipping Postcard ID #{postcard.id}: No PrintRecord found in response_data"
        end
      end
  end

  def down
    # This migration is not reversible in a meaningful way
    # We could nullify all print_record_ids, but that would lose data
    raise ActiveRecord::IrreversibleMigration
  end
end
