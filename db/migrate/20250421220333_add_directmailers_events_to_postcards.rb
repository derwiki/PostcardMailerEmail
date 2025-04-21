class AddDirectmailersEventsToPostcards < ActiveRecord::Migration[8.0]
  def change
    add_column :postcards, :directmailers_events, :json, default: []
  end
end
