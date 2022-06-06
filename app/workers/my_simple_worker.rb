require 'sidekiq'

# require 'active_support/time'
# for work with time

class MySimpleWorker
  include Sidekiq::Worker

  def perform(text)
    puts text
  end
end
