namespace :ac do
  def with_temporarily_disabled_embedding_service
    # Store original embedding service enabled setting
    embedding_service_enabled = Rails.application.config.embedding_service[:enabled]

    # Disable embedding service
    Rails.application.config.embedding_service[:enabled] = false

    yield

    # Restore original embedding service enabled setting
    Rails.application.config.embedding_service[:enabled] = embedding_service_enabled
  end

  def run_indexer(*pids)
    index = AcademicCommons::Indexer.new
    index.items(*pids, only_in_solr: false)
    index.close
  end

  desc "Adds item and collection to the repository."
  task :populate_solr => :environment do
    Rake::Task["load:fixtures"].invoke unless ActiveFedora::Base.exists?('actest:1')

    item = ActiveFedora::Base.find('actest:1')
    tries = 0

    while(item.list_members(true).length < 3 && tries < 50) do
      puts "(actest:1).list_members was less than 3, waiting for buffer to flush"
      sleep(1)
      tries += 1
    end
    raise "Never found item members, check Solr" if (tries > 50)

    if ENV['skip_vector_embeddings_during_populate_solr'] == 'true'
      with_temporarily_disabled_embedding_service do
        run_indexer('actest:1')
      end
    else
      run_indexer('actest:1')
    end
  end

  desc "Returns list of author emails. Removes authors that have opted out and uses preferred email if one is present."
  task author_emails: :environment do
    if (output = ENV['output'])
      if File.exist?(output)
        puts Rainbow('File exists. Please re-run with new filepath.').red
      else
        # Retrieve all authors.
        ids = AcademicCommons.all_author_unis
        puts Rainbow("Found #{ids.count} unique author UNIs.").cyan

        # Filter out any emails and used preferred email if present.
        emails = EmailPreference.preferred_emails(ids)

        # Format Output into CSV.
        puts Rainbow("Writing out CSV to #{output}").cyan
        CSV.open(output, "wb") do |csv|
          csv << ['UNI', 'Email']
          emails.each do |uni, email|
            csv << [uni, email]
          end
        end
      end
    else
      puts Rainbow('Incorrect arguments. Pass output=/path/to/file').red
    end
  end

  task delete_stale_pending_works: :environment do
    log = Rails.logger
    users = User.all
    users.each do |current_user|
      deposits = current_user.deposits.where('created_at < ?', 6.months.ago)
      identifiers = deposits.map(&:hyacinth_identifier).compact
      if identifiers.present?
        results = AcademicCommons.search do |params|
          identifiers = identifiers.map { |i| "\"#{i}\"" }.join(' OR ')
                                   .prepend('(').concat(')')
          params.filter('fedora3_pid_ssi', identifiers)
          params.aggregators_only
          params.field_list('fedora3_pid_ssi')
        end

        hyacinth_ids_in_ac = results.documents.map { |d| d[:fedora3_pid_ssi] }
      else
        hyacinth_ids_in_ac = []
      end

      pending_works = deposits.to_a.keep_if do |deposit|
        hyacinth_id = deposit.hyacinth_identifier
        hyacinth_id.blank? || !hyacinth_ids_in_ac.include?(hyacinth_id)
      end

      log.info "===Deleting #{pending_works.count} stale pending work(s)===" unless pending_works.empty?

      pending_works.each do |pending_work|
        log.info pending_work.inspect
        pending_work.destroy
      end
    end
  end
end
