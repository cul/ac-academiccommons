require 'item_class'
module AcademicCommons
  module NotifyDepositors
    def self.of_new_embargoed_items(pids)
      depositors = get_depositors_to_notify(pids)

      Rails.logger.info "====== Notifying Depositors of New Embargoed Item ======"

      depositors.each do |depositor|
        Rails.logger.info "=== Notifying #{depositor.name}(#{depositor.uni}) at #{depositor.email} ==="

        depositor.items_list.each do |item|
          Rails.logger.info "\tFor #{item.title}, PID: #{item.pid}, Persistent URL: #{item.handle}"
        end

        Notifier.depositor_embargoed_notification(depositor).deliver_now
      end
    end

    # Notifies depositors when deposited items are available. Sends email to each
    # depositor listing the new titles available.
    #
    # @param [Array<String>] pids list of new item pids
    def self.of_new_items(pids)
      depositors = get_depositors_to_notify(pids)

      Rails.logger.info "====== Notifing Depositors of New Item ======"

      # Loops through each depositor and notifies them for each new item now available.
      depositors.each do |depositor|
        Rails.logger.info "=== Notifying #{depositor.name}(#{depositor.uni}) at #{depositor.email} ==="

        depositor.items_list.each do |item|
          Rails.logger.info "\tFor #{item.title}, PID: #{item.pid}, Persistent URL: #{item.handle}"
        end

        Notifier.depositor_first_time_indexed_notification(depositor).deliver_now
      end
    end

    private

    def self.get_depositors_to_notify(pids)
      depositors_to_notify = Hash.new

      pids.each do |pid|
        Rails.logger.debug "=== Processing Depositors for Record: #{pid}"

        item = get_item(pid)

        Rails.logger.debug "=== item created for pid: #{pid}"
        Rails.logger.debug "title: #{item.title}, handle: #{item.handle}, num of authors: #{item.authors_uni.size}"

        item.authors_uni.each do | uni |
          Rails.logger.info "=== process uni: #{uni} depositor for pid: #{pid}"

          if(!depositors_to_notify.key?(uni))
            depositor = AcademicCommons::LDAP.find_by_uni(uni)
            depositor.items_list = []
            depositors_to_notify.store(uni, depositor)
          end

          depositor = depositors_to_notify[uni]
          depositor.items_list << item

          Rails.logger.info "=== process uni: #{uni} depositor for pid: #{pid} === finished"
        end
      end

      Rails.logger.info "====== depositors_to_notify.size: #{depositors_to_notify.size}"

      depositors_to_notify.values
    end

    def self.get_item(pid)
      # Can probably just use the object returned by blacklight, solr document struct of some sort.
      result = Blacklight.default_index.search(:fl => 'author_uni,id,handle,title_display,free_to_read_start_date', :fq => "pid:\"#{pid}\"")["response"]["docs"]

      item = Item.new
      item.pid = result.first[:id]
      item.title = result.first[:title_display]
      item.handle = result.first[:handle]
      item.free_to_read_start_date = result.first[:free_to_read_start_date]

      item.authors_uni = []

      if(result.first[:author_uni] != nil)
        item.authors_uni = clean_authors_array(result.first[:author_uni])
      end

      item
    end

    def self.clean_authors_array(authors_uni)
      authors_uni.map { |uni_str| uni_str.split(', ') }.flatten
    end
  end
end
