# frozen_string_literal: true

require 'active_support/core_ext/time'

# Poller for remind user about taking a shot

class Poller
  attr_accessor :time

  def initialize(time, chat_id)
    @time = time
    @chat_id = chat_id
  end

  def remind_at_time(time)
    loop do
      Time.use_zone('Moscow') do
        if Time.current.strftime("%H:%M:%S") == time.strftime("%H:%M:%S")
          puts 'BINGO'
        end
      end
      sleep 1
    end
  end
end
