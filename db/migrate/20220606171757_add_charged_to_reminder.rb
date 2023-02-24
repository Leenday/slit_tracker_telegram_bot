# frozen_string_literal: true

class AddChargedToReminder < ActiveRecord::Migration[5.2]
  def change
    add_column :reminders, :charged, :boolean, default: false
  end
end
