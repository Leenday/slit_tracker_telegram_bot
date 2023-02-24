# frozen_string_literal: true

require 'active_record'
require './app/models/reception_record'
require './db/connection'
require 'csv'
require 'rubyXL'
require 'rubyXL/convenience_methods/cell'
require 'rubyXL/convenience_methods/workbook'
require 'rubyXL/convenience_methods/worksheet'

class ExportReceptionRecords
  DatabaseConnection.connect
  def self.export(month, chat_id)
    # csv.open('./tmp/receipt_records/test.xlsx', 'wb') do |csv|
    #   csv << ['дата', 'прием асит', 'дозировка', 'количество нажатий', 'побочки']
    #   get_reception_records(month, chat_id).each do |rr|
    #     csv << [rr.created_at.strftime('%v'),
    #             rr.daily_status_reception,
    #             rr.potion_characteristics,
    #             rr.potion_pressing_count,
    #             rr.potion_side_effects]
    #   end
    # end
    workbook = RubyXL::Workbook.new
    worksheet = workbook[0]
    worksheet.sheet_name = 'История приемов АСИТ'
    get_reception_records(month, chat_id).each_with_index do |rr, index|
      worksheet.add_cell(index, 0, rr.created_at.strftime('%v'))
      worksheet.add_cell(index, 1, rr.daily_status_reception)
      worksheet.add_cell(index, 2, rr.potion_characteristics)
      worksheet.add_cell(index, 3, rr.potion_pressing_count)
      worksheet.add_cell(index, 4, rr.potion_side_effects)
    end
    worksheet.insert_row(0)
    worksheet.add_cell(0, 0, 'Дата')
    worksheet.add_cell(0, 1, 'Прием АСИТ')
    worksheet.add_cell(0, 2, 'Дозировка')
    worksheet.add_cell(0, 3, 'Количество нажатий')
    worksheet.add_cell(0, 4, 'Побочные эффекты')
    worksheet.change_column_width(0, 15)
    worksheet.change_column_width(1, 15)
    worksheet.change_column_width(2, 40)
    worksheet.change_column_width(3, 20)
    worksheet.change_column_width(4, 18)
    workbook.write('./tmp/receipt_records/slit_history.xlsx')
    bot = Telegram::Bot::Client.new(TOKEN)
    # bot.api.senddocument(chat_id: chat_id,
    #                      document: faraday::uploadio.new('./tmp/receipt_records/test.csv',
    #                                                      'multipart/form-data'))
    # puts file.convert
    bot.api.sendDocument(chat_id: chat_id,
                         document: Faraday::UploadIO.new('./tmp/receipt_records/slit_history.xlsx',
                                                         'multipart/form-data'))
  end

  def self.get_reception_records(year, chat_id)
    ReceptionRecord.where('extract(year from created_at) = ?', year).where(chat_id: chat_id)
  end
end
