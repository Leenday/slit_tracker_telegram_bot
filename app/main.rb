# frozen_string_literal: true

require './poller'
require './validator'
require './app/models/reminder'
require './app/models/reception_record'
require './db/connection'
require './scheduler'

require 'telegram/bot'
require 'faraday'
require 'logger'
require 'pg'
require 'active_record'
require 'dotenv'
require 'yaml'
require 'erb'
require 'rufus-scheduler'

DatabaseConnection.connect

TOKEN = Dotenv.load['TOKEN']

def fetch_answer(bot, key, answers = {})
  bot.listen do |answer|
    answers[key] = answer.text
    break
  end
end

# TODO: take these methods in module
# def initial_question(bot, message)
#   text = 'Привет, это я. Вы сегодня принимали АСИТ?'
#   yes = 'Да'
#   no = 'Нет'
#   answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [[yes, no]], one_time_keyboard: true, resize_keyboard: true)
#   bot.api.send_message(chat_id: message.chat.id, text: text, reply_markup: answers)
# end

def times_pushed_question(bot, message)
  text = 'Сколько нажатий на дозатор сделали?'
  answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w[1 2 3 4 5]], one_time_keyboard: true, resize_keyboard: true)
  bot.api.send_message(chat_id: message.chat.id, text: text, reply_markup: answers)
end

def side_effects_question(bot, message)
  text = 'Заметили ли вы побочные реакции?'
  yes = 'Да'
  no = 'Нет'
  answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [[yes, no]], one_time_keyboard: true, resize_keyboard: true)
  bot.api.send_message(chat_id: message.chat.id, text: text, reply_markup: answers)
end

def potion_color_question(bot, message)
  text = 'Флакон какой дозировки использовали?'
  blue = '10 ИР/мл (флакон с голубой крышкой)'
  violet = '300 ИР/мл (флакон с фиолетовой крышкой)'
  answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [[blue, violet]], one_time_keyboard: true, resize_keyboard: true)
  bot.api.send_message(chat_id: message.chat.id, text: text, reply_markup: answers)
end

Telegram::Bot::Client.run(TOKEN) do |bot|
  bot.listen do |message|
    case message.text
    when '/start', 'start'
      bot.api.send_message(chat_id: message.chat.id, text: "Привет, #{message.from.first_name}, я дневник АСИТ!
      Помогаю отслеживать, когда и в какой дозировке вы принимали препарат для АСИТ.
      Благодаря мне ваш доктор определит эффективность терапии.
      Нажимайте «Выбрать язык» или введите \"старт\" чтобы узнать, как я устроен.
")
    when '/commands', 'commands'
      bot.api.send_message(chat_id: message.chat.id, text: "Available commands, 'ada', 'start', 'commands'!")
    when '/remind'
      bot.api.send_message(
        chat_id: message.chat.id,
        text: 'Введите время в формате ЧЧ:ММ по Москве.',
        reply_markup: Telegram::Bot::Types::ForceReply.new(
          force_reply: true
        )
      )
    when '/да', '/Да'
      answers = { initial: 'Да' }

      potion_color_question(bot, message)
      fetch_answer(bot, :potion_color, answers)
      times_pushed_question(bot, message)
      fetch_answer(bot, :times_pushed, answers)
      side_effects_question(bot, message)
      fetch_answer(bot, :side_effects, answers)
      ReceptionRecord.create(
        chat_id: message.chat.id,
        daily_status_reception: answers[:initial],
        potion_characteristics: answers[:potion_color],
        potion_pressing_count: answers[:times_pushed].to_i,
        potion_side_effects: answers[:side_effects]
      )
      bot.api.send_message(
        chat_id: message.chat.id,
        text: 'Спасибо! Ваш ответ записан',
        reply_markup: Telegram::Bot::Types::ReplyKeyboardRemove.new(
          remove_keyboard: true
        )
      )
    when '/нет', '/Нет'
      bot.api.send_message(
        chat_id: message.chat.id,
        text: 'Тогда до завтра)',
        reply_markup: Telegram::Bot::Types::ReplyKeyboardRemove.new(
          remove_keyboard: true
        )
      )
    else
      if message.reply_to_message.present?
        case message.reply_to_message.text
        when 'Введите время в формате ЧЧ:ММ по Москве.'
          if Validator.valid_time_format?(message.text)
            scheduler = Scheduler.new(message.chat.id, message.text, bot)
            Reminder.create(chat_id: message.chat.id, remind_at: message.text, worker_id: scheduler.repeat_daily.id)
            bot.api.send_message(chat_id: message.chat.id, text: "Отлично, буду напоминать в #{message.text} каждый день")
          else
            bot.api.send_message(chat_id: message.chat.id, text: 'Неверный формат')
          end
        end
      else
        bot.api.send_message(chat_id: message.chat.id, text: 'test!')
      end
    end
  end
end
