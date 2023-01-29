# frozen_string_literal: true

require './lib/daily_inquirer'
require './app/models/reception_record'
require './db/connection'
require '/bot/app/workers/remind_scheduler'

require 'rufus-scheduler'
require 'dotenv'
require 'telegram/bot'

class Scheduler
  TOKEN = Dotenv.load['TOKEN']
  def initialize(chat_id, time, bot)
    @chat_id = chat_id
    @time = time
    @bot = bot
  end

  scheduler = Rufus::Scheduler.new
  scheduler.cron '0 0 * * *' do
    RemindScheduler.run
  end
end
