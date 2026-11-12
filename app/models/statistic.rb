class Statistic < ApplicationRecord
  YEAR_BEG = 2011 # first year we have statistics for.

  VIEW = 'View'.freeze
  DOWNLOAD = 'Download'.freeze
  STREAM = 'Streaming'.freeze

  EVENTS = [VIEW, DOWNLOAD, STREAM].freeze

  # Normalized identifier used as the summary key. Rows that MySQL's collation
  # considers the same identifier must end up under the same key, otherwise
  # the rollup and the summaries table disagree. In order:
  #   - remove hidden characters (the same set IdSanitizable strips from
  #     incoming ids: zero-width and other default-ignorable characters, NBSP,
  #     line/paragraph separators), which MySQL collations largely ignore
  #   - NFKC-normalize, mapping compatibility characters to their plain forms
  #     (e.g. an ellipsis to '...', fullwidth punctuation to ASCII)
  #   - downcase, and remove all whitespace (MySQL's PAD SPACE collation treats
  #     'abc' and 'abc ' as equal; interior whitespace never belongs in an id).
  #     Done after NFKC, which can itself produce spaces.
  # Invalid UTF-8 is scrubbed first so normalization can't raise.
  def self.summary_identifier(identifier)
    normalized = IdSanitizable.remove_hidden_characters(identifier.scrub)
                              .unicode_normalize(:nfkc)
                              .downcase
    IdSanitizable.remove_whitespace(normalized)
  end

  scope :rollup_eligible, lambda {
    where.not(identifier: [nil, ''])
         .where.not(event: [nil, ''])
         .where.not(at_time: nil)
  }

  # Calculate the number of times the event given has occurred for all the given
  # ids using the monthly summary table. If start and end date are given, the
  # query is limited to that time period (inclusive of the months they fall in).
  # When querying with dates, timestamps are ignored — only the month/year matters,
  # since StatisticsSummary aggregates at month granularity.
  #
  # @note When querying for downloads asset ids must be used, not aggregator ids.
  #
  # @param [Array<String>|String] ids
  # @param [String] event
  # @param [Date|Time] start_date
  # @param [Date|Time] end_date
  # @return [Hash<String,Integer>] keys are ids and the value is the number of times said event occurred
  def self.event_count(ids, event, start_date: nil, end_date: nil)
    # Check parameters.
    ids = [ids] if ids.is_a? String
    raise 'ids must be an Array or String' unless ids.is_a? Array
    raise "event must be one of #{EVENTS}" unless valid_event?(event)

    ids = ids.map { |id| id.downcase if id.is_a? String } # Summarized statistics are always normalized to downcase during rollup

    scope = StatisticsSummary.for_event(event)

    if start_date || end_date
      raise 'start_date and end_date must respond to :to_time' unless start_date.respond_to?(:to_time) && end_date.respond_to?(:to_time)

      scope = scope.for_period(start_date.to_time, end_date.to_time)
    end

    ids.each_slice(5000).each_with_object({}) do |identifiers, hash|
      hash.merge!(scope.where(identifier: identifiers).group(:identifier).sum(:count))
    end
  end

  # Calculate the number of times the event given has occurred for all the given
  # ids. If start and end date are given, the query is limited to that time period.
  # When querying with dates, timestamps are ignored.
  #
  # @note When querying for downloads asset ids must be used, not aggregator ids.
  #
  # @param [Array<String>|String] ids
  # @param [String] event
  # @param [Date|Time] start_date
  # @param [Date|Time] end_date
  # @return [Hash<String,Integer>] keys are ids and the value is the number of times said event occurred
  def self.raw_event_count(ids, event, start_date: nil, end_date: nil)
    # Check parameters.
    ids = [ids] if ids.is_a? String

    raise 'ids must be an Array or String' unless ids.is_a? Array
    raise "event must be one of #{EVENTS}" unless valid_event?(event)

    # TEMPORARY: legacy raw-table query, normalized to downcased keys to match
    # summarized_event_count. Remove once the summary backfill is complete and
    # summarized_event_count is renamed back to event_count.
    # or if renaming to legacy_event_count, note that this method matches case-insensitively; returns downcased keys;     # and does not use the identifier index.
    ids = ids.map { |id| id.downcase if id.is_a? String }
    scope = where(event: event)

    if start_date || end_date
      raise 'start_date and end_date must respond to :to_time' unless start_date.respond_to?(:to_time) && end_date.respond_to?(:to_time)

      scope = scope.where(at_time: start_date.to_time.beginning_of_day..end_date.to_time.end_of_day)
    end

    ids.each_slice(5000).each_with_object({}) do |identifiers, hash|
      hash.merge!(scope.where('LOWER(identifier) IN (?)', identifiers).group('LOWER(identifier)').count)
    end
  end

  def self.valid_event?(e)
    EVENTS.include?(e)
  end

  def self.merge_stats(pid, duplicate_pid)
     stats = Statistic.where(identifier: duplicate_pid)
     stats.each { |stat| stat.update!(identifier: pid) }
  end

  def self.reset_downloads
    Statistic.where(event: 'Download').each { |e| e.delete }

    fedora_download_match = /^([\d\.]+).+\[([^\]]+)\].+download\/fedora_content\/\w+\/([^\/]+)/
    startdate = DateTime.parse('5/1/2011')

    File.open(File.join('tmp', 'access.log')).each_with_index do |line, i|

      if (match = fedora_download_match.match(line))
        pid = match[3].gsub('%3A', ':')
        datetime = DateTime.parse(match[2].sub(':', ' '))
        ip = match[1]

        if pid.include?('ac')
          Statistic.create!(event: 'Download', ip_address: ip, identifier: pid, at_time: datetime)
        end
      end
    end
  end

  def rollup_eligible?
    identifier.present? &&
      event.present? &&
      at_time.present?
  end
end
