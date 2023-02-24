# frozen_string_literal: true

require 'sidekiq'

require './db/connection'
require './app/models/reminder'
require 'active_record'
require 'telegram/bot'

class RemindWorker
  include Sidekiq::Worker

  TOKEN = Dotenv.load['TOKEN']
  def perform(chat_id)
    # puts chat_id
    bot = Telegram::Bot::Client.new(TOKEN)
    answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [['/да', '/нет']], one_time_keyboard: true,
                                                            resize_keyboard: true)
    bot.api.send_message(chat_id: chat_id, text: 'Привет, это я. Вы принимали сегодня АСИТ? Введите: /да или /нет',
                         reply_markup: answers)
    DatabaseConnection.connect
    Reminder.find_by_chat_id(chat_id).update_attribute(:charged, false)
  end
end
