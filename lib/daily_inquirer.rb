# frozen_string_literal: true

class DailyInquirer
  def initialize(bot, message)
    @bot = bot
    @message = message
  end

  def times_pushed_question
    text = 'Сколько нажатий на дозатор сделали?'
    answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w[1 2 3 4 5]], one_time_keyboard: true, resize_keyboard: true)
    @bot.api.send_message(chat_id: @message.chat.id, text: text, reply_markup: answers)
  end

  def side_effects_question
    text = 'Заметили ли вы побочные реакции?'
    yes = 'Да'
    no = 'Нет'
    answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [[yes, no]], one_time_keyboard: true, resize_keyboard: true)
    @bot.api.send_message(chat_id: @message.chat.id, text: text, reply_markup: answers)
  end

  def potion_color_question
    text = 'Флакон какой дозировки использовали?'
    blue = '10 ИР/мл (флакон с голубой крышкой)'
    violet = '300 ИР/мл (флакон с фиолетовой крышкой)'
    answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [[blue, violet]], one_time_keyboard: true, resize_keyboard: true)
    @bot.api.send_message(chat_id: @message.chat.id, text: text, reply_markup: answers)
  end

  def run
    answers = {}
    ask_questions(answers)
    answers
    # ReceptionRecord.create(
    #   chat_id: @message.chat.id,
    #   daily_status_reception: answers[:initial],
    #   potion_characteristics: answers[:potion_color],
    #   potion_pressing_count: answers[:times_pushed].to_i,
    #   potion_side_effects: answers[:side_effects]
    # )
  end
end

def ask_questions(answers)
  initial_question
  fetch_answer(bot, :initial, answers)
  if answers[:initial] == 'Нет'
    bot.api.send_message(chat_id: message.chat.id, text: answers.to_s)
    return answers
  end
  potion_color_question
  fetch_answer(:potion_color, answers)
  times_pushed_question
  fetch_answer(:times_pushed, answers)
  side_effects_question
  fetch_answer(:side_effects, answers)
  @bot.api.send_message(chat_id: @message.chat.id, text: answers.to_s)
end

def fetch_answer(key, answers = {})
  @bot.listen do |answer|
    answers[key] = answer.text
    break
  end
end
