module AcademicCommons
  class Indexer
    # rubocop:disable Style/FormatStringToken
    TIMESTAMP = '%Y%m%d-%H%M%S'.freeze
    # rubocop:enable Style/FormatStringToken

    attr_reader :indexing_logger, :error, :success, :start, :verbose

    # Creates object that reindex all records currently in the solr core or
    # individual items.
    #
    # @param [User|String] executed_by person running this index
    # @param [Time] start time indexing was started, defaults to Time.new
    def initialize(executed_by: nil, start: nil, verbose: false) # eventually will have to add flag for full text indexing
      @start = start || Time.current
      @indexing_logger = setup_logger(start_timestamp)
      @error, @success = [], []
      @verbose = verbose
      log_info "This re-index executed by: #{(executed_by || 'n/a').to_s}"
      log_info 'START REINDEX'
    end

    # Reindexes all items that are currently in the solr core.
    def all_items
      log_info 'Indexing all items and assets currently in the solr core...'

      # Solr query to retrieve all aggregators in solr core.
      solr_params = {
        q: nil, fl: 'fedora3_pid_ssi', rows: 100_000,
        fq: ["has_model_ssim:\"#{ContentAggregator.to_class_uri}\""]
      }
      response = rsolr.get('select', params: solr_params)
      pids = response['response']['docs'].map{ |doc| doc['fedora3_pid_ssi'] }
      items(*pids)
    end

    # Index items given. This method does not check that the pids given are
    # already in solr. This check is left up to the user and allows us to index
    # items that aren't in the solr core already for testing purposes.
    #
    # @param [Array<String>] items list of pids
    # @param [Boolean] only_in_solr only indexes resources (assets) already in solr
    def items(*items, only_in_solr: true)
      log_info "Preparing to index #{items.size} item(s):"

      items.each do |pid|
        log_info "Processing aggregator  #{pid}"

        begin
          i = ActiveFedora::Base.find(pid)
          i.update_index
          i.list_members.each do |resource|
            next if only_in_solr && !solr_id_exists?(resource.id)
            log_info("           child asset #{resource.id}")
            resource.update_index
          end
          success.append(pid)
        rescue Exception => e
          log_error e.message
          log_error e.backtrace.join("\n ")
          error.append(pid)
          next
        end
      end
    end

    # Indexes pids given regardless of whether or not they are already in solr.
    # This method does not index associated assets. Item and asset pids have
    # to be listed.
    def by_pids(pids)
      log_info "Preparing to index #{pids.size} item/assets"

      pids.each do |pid|
        log_info "Processing #{pid}"

        begin
          i = ActiveFedora::Base.find(pid)
          i.update_index
          success.append(pid)
        rescue Exception => e
          log_error e.message
          log_error e.backtrace.join("\n ")
          error.append(pid)
          next
        end
      end
    end

    def close
      # commit to solr RSolr.commit if doing autoCommit
      seconds = Time.current - start
      readable_time_spent = format('%02d hours %02d minutes %02d seconds', seconds / 3_600, (seconds / 60) % 60, seconds % 60)

      log_info 'FINISH REINDEX '
      log_info "Time spent: #{readable_time_spent}"
      log_info "Successfully indexed #{success.count} item(s)."
      log_info "The following #{error.count} item(s) returned errors #{error.join(", ")}" unless error.count.zero?
      indexing_logger.close

      Rails.cache.delete('repository_statistics') # Invalidating stats on homepage.
    end

    def start_timestamp
      start.strftime(TIMESTAMP)
    end

    private

    # Writes errors to logger and stdout.
    def log_error(string)
      indexing_logger.error(string)
      puts(Rainbow(string).red) if verbose
    end

    # Writes information to logger and stdout.
    def log_info(string)
      indexing_logger.info(string)
      puts(string) if verbose
    end

    # Helper to determain whether or not the fedora id exists in solr core.
    def solr_id_exists?(id)
      response = rsolr.get('select', params: { q: "{!raw f=fedora3_pid_ssi}#{id}", rows: 0 })
      response['response']['numFound'].to_i == 1
    end

    def rsolr
      @rsolr ||= AcademicCommons::Utils.rsolr
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
