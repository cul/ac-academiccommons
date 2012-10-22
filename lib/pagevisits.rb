require "garb"

class Pagevisits
  extend Garb::Model
  metrics :visits
  metrics :visitors
end