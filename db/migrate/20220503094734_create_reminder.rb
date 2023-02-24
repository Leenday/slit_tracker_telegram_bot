# frozen_string_literal: true

class CreateReminder < ActiveRecord::Migration[5.2]
  def change
    create_table :reminders do |t|
      t.integer :chat_id, unique: true
      t.time :remind_at
      t.text :worker_id

      t.timestamps
    end
  end
end
