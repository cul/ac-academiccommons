class EmailPreference < ApplicationRecord
  validates :author, presence: true

  def self.for(uni)
    find_by(author: uni)
  end

  # Returns map of UNI to prefered email; any unis that are unsubscribed from
  # emails are removed.
  #
  # @param [String] array of unis
  def self.prefered_emails(unis)
    map = {}
    unis = unis.flatten.compact.uniq - EmailPreference.where(monthly_opt_out: true).map(&:author)

    unis.each { |uni| map[uni] = "#{uni}@columbia.edu" }

    EmailPreference.where('email is NOT NULL and monthly_opt_out = 0').find_each do |e|
      map[e.author] = e.email
    end

    map
  end
end
