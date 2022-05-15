# frozen_string_literal: true

require './lib/daily_inquirer'
require './app/models/reception_record'
require './db/connection'

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

  def repeat_daily
    parsed_time = @time.match(/(\d{2}):(\d{2})/)
    min = parsed_time[2]
    hrs = parsed_time[1]
    scheduler = Rufus::Scheduler.new
    scheduler.repeat "#{min} #{hrs} * * *" do
      # TODO: rework inquirer outside main.rb
      # @bot.listen do |message|
      #   daily_inquirer = DailyInquirer.new(@bot, message)
      #   answers = daily_inquirer.run
      #   DatabaseConnection.connect
      #   ReceptionRecord.create(
      #     chat_id: @message.chat.id,
      #     daily_status_reception: answers[:initial],
      #     potion_characteristics: answers[:potion_color],
      #     potion_pressing_count: answers[:times_pushed].to_i,
      #     potion_side_effects: answers[:side_effects]
      #   )
      # end

      answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [['/да', '/нет']], one_time_keyboard: true, resize_keyboard: true)
      @bot.api.send_message(chat_id: @chat_id, text: 'Привет, это я. Вы принимали сегодня АСИТ? Введите: /да или /нет', reply_markup: answers)
    end
  end
end
