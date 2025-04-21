class CreatePostcards < ActiveRecord::Migration[8.0]
  def change
    create_table :postcards do |t|
      t.references :user, null: false, foreign_key: true
      t.references :address, null: false, foreign_key: true
      t.string :status
      t.jsonb :response_data
      t.string :image_url
      t.string :message
      t.boolean :dryrun
      t.timestamps
    end
  end
end 