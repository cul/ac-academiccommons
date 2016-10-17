require "person_class"

module InfoHelper

  delegate :blacklight_solr, :to => :controller

  def get_person_info(uni)

    #logger.debug "==== start getting person info by ldap for uni: " + uni

      entry = Net::LDAP.new({:host => "ldap.columbia.edu", :port => 389}).search(:base => "o=Columbia University, c=US", :filter => Net::LDAP::Filter.eq("uid", uni)) || []
      entry = entry.first

      email = nil
      last_name = nil
      first_name = nil

      if entry
        entry[:mail].kind_of?(Array) ? email = entry[:mail].first.to_s : email = entry[:mail].to_s
        entry[:sn].kind_of?(Array) ? last_name = entry[:sn].first.to_s : last_name = entry[:sn].to_s
        entry[:givenname].kind_of?(Array) ? first_name = entry[:givenname].first.to_s : first_name = entry[:givenname].to_s
      end

      person = Person.new

      person.uni = uni
      person.email = email
      person.last_name = last_name
      person.first_name = first_name

      return person
  end

  def getReadableTimeSpent(start_time)
    return timeReadableFormat(getSecondsSpent(start_time))
  end

  def timeReadableFormat(seconds)
    return Time.at(seconds).utc.strftime("%H hours, %M minutes, %S seconds")
  end

  def getSecondsSpent(start_time)
    finish_time = Time.new
    seconds_spent = finish_time - start_time
    return seconds_spent
  end

end # ==================================================== #
