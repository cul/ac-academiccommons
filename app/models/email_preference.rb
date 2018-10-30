class EmailPreference < ApplicationRecord
  validates :uni, presence: true, uniqueness: true

  def self.for(uni)
    find_by(uni: uni)
  end

  # Returns map of UNI to preferred email; any unis that are unsubscribed from
  # emails are removed.
  #
  # @param [String] array of unis
  def self.preferred_emails(unis)
    map = {}
    unis = unis.flatten.compact.uniq - EmailPreference.where(unsubscribe: true).map(&:uni)

    unis.each { |uni| map[uni] = "#{uni}@columbia.edu" }

    EmailPreference.where('email is NOT NULL and unsubscribe = 0').find_each do |e|
      map[e.uni] = e.email if map[e.uni]
    end

    map
  end
end
