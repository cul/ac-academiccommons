require "person_class"

module InfoHelper
  delegate :repository, :to => :controller
end
