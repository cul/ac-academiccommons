module AcademicCommons
  module NewItemNotification
    include Embargoes
    # Notifies depositors when deposited items are available. Sends email to each
    # depositor listing the new titles available. Two emails are sent if there
    # are both embargoed items and unembargoed items.
    #
    # @param [Array<String>] pids list of new item pids
    def notify_authors_of_new_items(pids)
      depositors = get_depositors_to_notify(pids)

      Rails.logger.info "====== Notifing Depositors of New Items ======"

      # Loops through each depositor and sends an email notifying of each new item now available.
      depositors.each do |info|
        Rails.logger.info "=== Notifying #{info.person.name}(#{info.person.uni}) at #{info.person.email} ==="

        Notifier.depositor_first_time_indexed_notification(info.person, info.new_items, info.embargoed_items).deliver_now
      end
    end

    def get_depositors_to_notify(pids)
      depositors_to_notify = Hash.new

      pids.each do |pid|
        Rails.logger.info "=== Processing Depositors for Record: #{pid}"

        item = get_item(pid)

        item.authors_uni.each do |uni|
          unless depositors_to_notify.key?(uni)
            depositors_to_notify[uni] = OpenStruct.new(
              person: AcademicCommons::LDAP.find_by_uni(uni),
              new_items: [],
              embargoed_items: []
            )
          end

          if item[:free_to_read_start_date] && available_today?(item[:free_to_read_start_date])
            depositors_to_notify[uni].new_items << item
          else
            depositors_to_notify[uni].embargoed_items << item
          end
        end
      end

      depositors_to_notify.values
    end

    def get_item(pid)
      extra_params = { fl: 'author_uni,id,handle,title_display,free_to_read_start_date' }
      result = Blacklight.default_index.find(pid, extra_params).docs.first

      date = result[:free_to_read_start_date] || nil
      date = Date.strptime(date, '%Y-%m-%d') if date

      item = OpenStruct.new(
        pid: result[:id],
        title: result[:title_display],
        handle: result[:handle],
        free_to_read_start_date: date,
        authors_uni: clean_authors_array(result[:author_uni])
      )
    end

    def clean_authors_array(authors_uni)
      return nil if authors_uni.blank?
      authors_uni.map { |uni_str| uni_str.split(', ') }.flatten
    end
  end
end
