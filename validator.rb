class Validator
  def self.valid_time_format?(time)
    time_digits = time.match(/(\d{2}):(\d{2})/)
    if time_digits.respond_to?(:[])
      valid_length?(time, 5) && valid_amount?('hrs', time_digits[1]) && valid_amount?('min', time_digits[2])
    else
      false
    end
  end

  private_class_method def self.valid_amount?(units, amount)
    case units
    when 'min', :min
      amount.to_i.between?(0, 59)
    when 'hrs', :hrs
      amount.to_i.between?(0, 23)
    end
  end
  private_class_method def self.valid_length?(obj, amount)
    return false unless obj.respond_to?(:length)

    obj.length == amount
  end
end
