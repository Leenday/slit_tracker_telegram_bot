class CreateReceptionRecord < ActiveRecord::Migration[5.2]
  def change
    create_table :reception_records do |t|
      t.integer :chat_id
      t.string :daily_status_reception
      t.string :potion_characteristics
      t.integer :potion_pressing_count
      t.string :potion_side_effects

      t.timestamps
    end
  end
end
