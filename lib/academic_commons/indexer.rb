module AcademicCommons
  class Indexer
    TIMESTAMP = '%Y%m%d-%H%M%S'
    attr_reader :indexing_logger, :error, :success, :start

    #
    #
    # @param [User|String] executed_by person running this index
    # @param [Time] start time indexing was started, defaults to Time.new
    def initialize(executed_by: nil, start: nil) # eventually will have to add flag for full text indexing
      @start = start || Time.new
      @indexing_logger = setup_logger(start_timestamp)
      @error, @success = [], []
      @indexing_logger.info "This re-index executed by: #{(executed_by || 'n/a').to_s}"
    end

    # Reindexes all items that are currently in the solr core.
    def all_items
      indexing_logger.info "This re-index executed by: #{executed_by}"
      indexing_logger.info "Indexing all items (aggregators) currently in the solr core..."

      # Solr query to retrieve all aggregators in solr core.
      solr_params = {
        q: nil, fl: 'id', rows: 100000,
        fq: ["has_model_ssim:\"#{ContentAggregator.to_class_uri}\""]
      }
      response = rsolr.get('select', params: solr_params)
      pids = response['response']['docs'].map{ |doc| doc['id'] }
      items(*pids)
    end

    # Index items given. This method does not check that the pids given are
    # already in solr. This check is left up to the user and allows us to index
    # items that aren't in the solr core already for testing purposes.
    #
    # @param [Array<String>] items list of pids
    # @param [Boolean] only_in_solr only indexes resources (assets) already in solr
    def items(*items, only_in_solr: true)
      indexing_logger.info "Preparing to index #{items.size} items..."

      items.each do |pid|
        indexing_logger.info "Indexing #{pid}..."

        begin
          i = ActiveFedora::Base.find(pid)
          i.update_index # Could leverage autoCommit here.
          i.list_members.each do |resource|
            next if only_in_solr && !solr_id_exists?(resource.id)
            indexing_logger.info("indexing resource: ")
            indexing_logger.info(resource.to_solr)
            resource.update_index
          end
          success.append(pid)
        rescue Exception => e
          indexing_logger.error e.message
          error.append(pid)
          next
        end
      end
    end

    def close
      # commit to solr RSolr.commit if doing autoCommit
      seconds_spent = Time.new - start
      readable_time_spent = Time.at(seconds_spent).utc.strftime("%H hours, %M minutes, %S seconds")

      indexing_logger.info "FINISHED INDEXING"
      indexing_logger.info "Time spent: #{readable_time_spent}"
      indexing_logger.info "Successfully indexed #{success.count} item(s)."
      indexing_logger.info "The following #{error.count} item(s) returned errors #{error.join(", ")}" unless error.count.zero?
      indexing_logger.close
    end

    def start_timestamp
      start.strftime(TIMESTAMP)
    end

    private

    # Helper to determain whether or not id exists in solr core.
    def solr_id_exists?(id)
      response = rsolr.get('select', { q: "{!raw f=id}#{id}", rows: 0 })
      response['response']['numFound'].to_i == 1
    end

    def rsolr
      @rsolr ||= begin
        url = Rails.application.config_for(:solr)['url']
        RSolr.connect(url: url)
      end
    end

    def setup_logger(time_id)
      filepath = File.join(Rails.root, 'log', 'ac-indexing', "#{time_id}.log")
      log = ActiveSupport::Logger.new(filepath)
      log.level = Logger::INFO
      log.formatter = Rails.application.config.log_formatter
      log
    end
  end
end
