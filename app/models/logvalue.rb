class Logvalue < ActiveRecord::Base
   
    attr_accessible :id, :eventlog_id, :param_name, :value
    belongs_to :eventlog

end
