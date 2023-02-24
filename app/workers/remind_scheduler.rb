# frozen_string_literal: true

require './app/workers/remind_worker'
require './app/models/reminder'

# for work with time
require 'active_support/time'
require './db/connection'

class RemindScheduler
  class << self
    def run
      DatabaseConnection.connect
      Reminder.where(charged: false).each do |reminder|
        hour = DateTime.parse(reminder.remind_at.strftime('%H:%M')).hour
        minute = DateTime.parse(reminder.remind_at.strftime('%H:%M')).minute
        job_id = RemindWorker.perform_at(DateTime.now.change({ hour: hour, min: minute, sec: 0 }).to_i,
                                         reminder.chat_id)
        reminder.update_attributes(charged: true, worker_id: job_id)
      end
    end
  end
end
