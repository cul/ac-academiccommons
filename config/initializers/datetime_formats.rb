[Time, Date].map do |klass|
  klass::DATE_FORMATS[:datepicker] = lambda { |t| t.strftime("%m/%d/%Y") }
  klass::DATE_FORMATS[:chart_year] = lambda { |t| t.strftime("%Y") }
  klass::DATE_FORMATS[:chart_month] = lambda { |t| t.strftime("%b '%y") }
  klass::DATE_FORMATS[:chart_week] = lambda { |t| t.strftime("%m/%d") }
end
