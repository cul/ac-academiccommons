module AcademicCommons
  module LDAP
    # LDAP lookup based on UNI. If record can not be found, derives email from
    # uni and leaves the rest of fields blank.
    #
    # @param [String] uni
    # @return [OpenStruc] containing person's uni, email, last name, first name, and full name
    def self.find_by_uni(uni)
      # Returns [] if there are no valid entries.
      entries = Net::LDAP.new({:host => "ldap.columbia.edu", :port => 389})
                  .search(:base => "o=Columbia University, c=US", :filter => Net::LDAP::Filter.eq("uid", uni))

      Rails.logger.warn("LDAP record for #{uni} NOT found.") if entries.blank?

      p = OpenStruct.new(
        uni: uni,
        email: nil,
        name: nil,
        last_name: nil,
        first_name: nil,
      )

      if entry = entries.first
        p.email = (entry[:mail].kind_of?(Array) ? entry[:mail].first : entry[:mail]).to_s
        p.last_name = (entry[:sn].kind_of?(Array) ? entry[:sn].first : entry[:sn]).to_s
        p.first_name = (entry[:givenname].kind_of?(Array) ? entry[:givenname].first : entry[:givenname]).to_s

        Rails.logger.info "Retriving user information via LDAP for #{p.first_name} #{p.last_name} (#{p.uid})"
      end

      # Augment information if necessary.
      p.email = "#{uni}@columbia.edu" if p.email.blank?
      p.name = "#{p.first_name} #{p.last_name}" unless p.first_name.blank? || p.last_name.blank?
      p
    end
  end
end
