# frozen_string_literal: true

require './poller'
require './validator'
require './app/models/reminder'
require './app/models/reception_record'
require './db/connection'
require './scheduler'
require './app/services/export_reception_records'
require './app/workers/remind_worker'

require 'telegram/bot'
require 'faraday'
require 'logger'
require 'pg'
require 'active_record'
require 'dotenv'
require 'yaml'
require 'erb'
require 'rufus-scheduler'
require 'sidekiq/api'

DatabaseConnection.connect

TOKEN = Dotenv.load['TOKEN']

def fetch_answer(bot, key, answers = {})
  bot.listen do |answer|
    case answer
    when Telegram::Bot::Types::CallbackQuery
      answers[key] = answer.data
    when Telegram::Bot::Types::Message
      answers[key] = answer.text
    end
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
  answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w[1 2 3 4 5]], one_time_keyboard: true,
                                                          resize_keyboard: true)
  bot.api.send_message(chat_id: message.chat.id, text: text, reply_markup: answers)
end

def side_effects_question(bot, message)
  text = 'Заметили ли вы побочные реакции?'
  yes = 'Да'
  no = 'Нет'
  answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [[yes, no]], one_time_keyboard: true,
                                                          resize_keyboard: true)
  bot.api.send_message(chat_id: message.chat.id, text: text, reply_markup: answers)
end

def potion_color_question(bot, message)
  text = 'Флакон какой дозировки использовали?'
  blue = '10 ИР/мл (флакон с голубой крышкой)'
  violet = '300 ИР/мл (флакон с фиолетовой крышкой)'
  answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [[blue, violet]], one_time_keyboard: true,
                                                          resize_keyboard: true)
  bot.api.send_message(chat_id: message.chat.id, text: text, reply_markup: answers)
end

def year_question(bot, message)
  text = 'За какой год выгрузить записи?'
  unique_years = ReceptionRecord.where(chat_id: message.chat.id).pluck(:created_at).map(&:year).uniq
  year_callbacks = unique_years.map do |year|
    Telegram::Bot::Types::InlineKeyboardButton.new(text: year, callback_data: year)
  end
  markup_retry = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: year_callbacks)
  bot.api.send_message(chat_id: message.chat.id, text: text, reply_markup: markup_retry, one_time_keyboard: true)
end

def email_question(bot, message)
  text = 'Введите почту на которую отправить записи.'
  # TODO: validation for email
  bot.api.send_message(chat_id: message.chat.id, text: text)
end

Telegram::Bot::Client.run(TOKEN) do |bot|
  bot.listen do |message|
    case message
    when Telegram::Bot::Types::CallbackQuery
      next
    when Telegram::Bot::Types::Message
      puts ('#' * 100).to_s
      puts message.chat.id
      puts ('#' * 100).to_s
      case message.text
      when '/start', 'start'
        bot.api.send_message(chat_id: message.chat.id, text: "Привет, #{message.from.first_name}, я дневник АСИТ!
      Помогаю отслеживать, когда и в какой дозировке вы принимали препарат для АСИТ.
      Благодаря мне ваш доктор определит эффективность терапии.
      Введите /help, /h или /commands для списка команд")
      when '/commands', 'commands'
        text = <<~DOC
          /remind - настроить оповещения
          /remind_off - отключить оповещения
          /выгрузить - выгрузить вашу история принятия АСИТ
        DOC
        bot.api.send_message(chat_id: message.chat.id, text: text)
      when '/remind'
        bot.api.send_message(
          chat_id: message.chat.id,
          text: 'Введите время в формате ЧЧ:ММ по Москве.',
          reply_markup: Telegram::Bot::Types::ForceReply.new(
            force_reply: true
          )
        )
      when '/remind_off'
        bot.api.send_message(
          chat_id: message.chat.id,
          text: 'Оповещения отключены'
        )
        reminder = Reminder.find_by(chat_id: message.chat.id)
        Sidekiq::ScheduledSet.new.find_job(reminder.worker_id)&.delete
        reminder.update_attribute(:charged, false)
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
      when '/выгрузить'
        answers = {}

        year_question(bot, message)
        fetch_answer(bot, :year, answers)
        ExportReceptionRecords.export(answers[:year], message.chat.id)
      else
        if message.reply_to_message.present?
          case message.reply_to_message.text
          when 'Введите время в формате ЧЧ:ММ по Москве.'
            if Validator.valid_time_format?(message.text)
              Reminder
                .find_or_initialize_by(chat_id: message.chat.id)
                .update_attributes(remind_at: message.text)
              bot.api.send_message(
                chat_id: message.chat.id,
                text: "Отлично, буду напоминать в #{message.text} каждый день",
                reply_markup: Telegram::Bot::Types::ReplyKeyboardRemove.new(
                  remove_keyboard: true
                )
              )
              reminder = Reminder.find_by(chat_id: message.chat.id)
              job_id = RemindWorker.perform_at(
                DateTime.now.change({ hour: reminder.remind_at.hour, min: reminder.remind_at.min,
                                      sec: 0 }).to_i, reminder.chat_id
              )
              reminder.update_attribute(:worker_id, job_id)
            else
              bot.api.send_message(chat_id: message.chat.id, text: 'Неверный формат')
            end
          end
        else
          bot.api.send_message(chat_id: message.chat.id,
                               text: 'Я такого пока не знаю, но, возможно, разработавший меня кожаный мешок добавит это в будущем.')
        end
      end
    end
  rescue Telegram::Bot::Exceptions::ResponseError
    sleep(30)
  rescue Faraday::ConnectionFailed
    sleep(30)
  end
end
