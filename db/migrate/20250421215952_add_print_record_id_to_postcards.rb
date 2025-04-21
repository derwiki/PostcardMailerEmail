class AddPrintRecordIdToPostcards < ActiveRecord::Migration[8.0]
  def change
    add_column :postcards, :print_record_id, :string
    add_index :postcards, :print_record_id, unique: true
  end
end
