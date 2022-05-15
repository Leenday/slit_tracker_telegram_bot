# frozen_string_literal: true

class Reminder < ActiveRecord::Base
  validates :chat_id, uniqueness: true
end
