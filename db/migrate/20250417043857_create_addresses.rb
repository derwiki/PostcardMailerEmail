class CreateAddresses < ActiveRecord::Migration[8.0]
  def change
    create_table :addresses do |t|
      t.references :user, null: false, foreign_key: true
      t.string :nickname
      t.string :name
      t.string :address1
      t.string :address2
      t.string :city
      t.string :state
      t.string :postal_code

      t.timestamps
    end
  end
end
