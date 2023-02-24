($LOAD_PATH << '/bot/app/workers').uniq!

require 'remind_worker'
require 'remind_scheduler'
